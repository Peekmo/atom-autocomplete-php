<?php

abstract class Tools
{
    /**
     * Contains classmap from composer
     * @var array
     */
    private $classMap = array();

    /**
     * Returns the classMap from composer.
     * Fetch it from the command dump-autoload if needed
     * @param bool $force Force to fetch it from the command
     * @return array
     */
    protected function getClassMap($force = false)
    {
        if (empty($this->classMap) || $force) {
            if (Config::get('classmap_file') && !file_exists(Config::get('classmap_file')) || $force) {
                // Check if composer is executable or not
                if (is_executable(Config::get('composer'))) {
                    exec(sprintf('%s dump-autoload --optimize --quiet --no-interaction --working-dir=%s 2>&1',
                        escapeshellarg(Config::get('composer')),
                        escapeshellarg(Config::get('projectPath'))
                    ));
                } else {
                    exec(sprintf('%s %s dump-autoload --optimize --quiet --no-interaction --working-dir=%s 2>&1',
                        escapeshellarg(Config::get('php')),
                        escapeshellarg(Config::get('composer')),
                        escapeshellarg(Config::get('projectPath'))
                    ));
                }
            }

            if (Config::get('classmap_file')) {
                $this->classMap = require(Config::get('classmap_file'));
            }
        }

        return $this->classMap;
    }

    /**
     * Format parameters for the autocomplete plugin
     * @param ReflectionMethod $method    Method to get arguments from
     * @param string           $className Class name to use (optional for the moment)
     * @return array
     */
    protected function getMethodArguments($method, $className = null)
    {
        $args = $method->getParameters();
        $optionals = array();
        $parameters = array();

        foreach ($args as $argument) {
            $value = '$' . $argument->getName();

            if ($argument->isPassedByReference()) {
                $value = '&' . $value;
            }

            if ($argument->isOptional()) {
                $optionals[] = $value;
            } else {
                $parameters[] = $value;
            }
        }

        if ($className) {
            $parser = new DocParser();
            $return = $parser->get($className, 'method', $method->getName(), array(DocParser::RETURN_VALUE));
        }

        return array(
            'parameters' => $parameters,
            'optionals' => $optionals,
            'return'    => ($className && !empty($return)) ? $return['return'] : ''
        );
    }

    /**
     * Returns methods and properties of the given className
     * @param string $className Full namespace of the parsed class
     */
    protected function getClassMetadata($className)
    {
        $data = array(
            'class'  => $className,
            'names'  => array(),
            'values' => array()
        );

        try {
            $reflection = new ReflectionClass($className);
        } catch (Exception $e) {
            return $data;
        }

        $methods    = $reflection->getMethods();
        $attributes = $reflection->getProperties();

        // Methods
        foreach ($methods as $method) {
            $data['names'][] = $method->getName();

            $args = $this->getMethodArguments($method, $className);

            $data['values'][$method->getName()] = array(
                'isMethod' => true,
                'isPublic' => $method->isPublic(),
                'args'     => $args
            );
        }

        // Properties
        foreach ($attributes as $attribute) {
            if (!in_array($attribute->getName(), $data['names'])) {
                $data['names'][] = $attribute->getName();
                $data['values'][$attribute->getName()] = array();
            }

            $parser = new DocParser();
            $return = $parser->get($className, 'property', $attribute->getName(), array(DocParser::VAR_TYPE));

            $data['values'][$attribute->getName()] = array(
                'isMethod' => false,
                'isPublic' => $attribute->isPublic(),
                'args'     => array('return' => !empty($return) ? $return['var'] : '')
            );
        }

        return $data;
    }
}

?>
