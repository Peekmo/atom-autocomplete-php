<?php

namespace Peekmo\AtomAutocompletePhp;

class AutocompleteProvider extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $class = $args[0];
        $name  = $args[1];
        $isMethod = false;
        if (strpos($class, '\\') === 0) {
            $class = substr($class, 1);
        }
        if (strpos($name, '()') > -1) {
            $isMethod = true;
            $name = str_replace('()', '', $name);
        }

        $classMap = $this->getClassMap();
        $data = $this->getClassMetadata($class);
        if (!isset($data['values'][$name]) || !isset($classMap[$class])) {
            return array(
                'class'  => null,
                'names'  => array(),
                'values' => array()
            );
        }
        $values = $data['values'][$name];
        if (!isset($data['values'][$name]['isMethod'])) {
            foreach ($data['values'][$name] as $value) {
                if ($value['isMethod'] && $isMethod) {
                    $values = $value;
                } elseif (!$value['isMethod'] && !$isMethod) {
                    $values = $value;
                }
            }
        }

        $returnValue = $values['args']['return'];
        if ($returnValue == '$this' || $returnValue == 'static') {
            return $data;
        } elseif ($returnValue === 'self') {
            // Is the method returning self declared in the class itself or in a parent class? Self refers to the class
            // declaring the method and will not point to child classes on inheritance, unless they redefine the method
            // and its docblock.
            if ($values['declaringClass'] === $class) {
                return $data;
            } else {
                return $this->getClassMetadata($values['declaringClass']);
            }
        } elseif (ucfirst($returnValue) === $returnValue) {
            // At this point, this could either be a class name relative to the current namespace or a full class
            // name without a leading slash. For example, Foo\Bar could also be relative (e.g. My\Foo\Bar), in which
            // case its absolute path is determined by the namespace and use statements of the file containing it.
            $className = $returnValue;

            if (!empty($className) && $returnValue[0] !== "\\" && isset($classMap[$values['declaringClass']])) {
                $parser = new FileParser($classMap[$values['declaringClass']]);

                $useStatementFound = false;
                $competedClassName = $parser->getCompleteNamespace($returnValue, $useStatementFound);

                if (!$useStatementFound) {
                    $isRelativeClass = true;

                    // Try instantiating the class, e.g. My\Foo\Bar.
                    try {
                        $reflection = new \ReflectionClass($competedClassName);

                        $className = $competedClassName;
                    } catch (\Exception $e) {
                        // The class, e.g. My\Foo\Bar, didn't exist. We can only assume its an absolute path, using a
                        // namespace set up in composer.json, without a leading slash.
                    }
                }
            }

            return $this->getClassMetadata($className);
        }
    }
}
