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
     * Fetches information about the specified method or function, such as its parameters, a description from the
     * docblock (if available), the return type, ...
     *
     * @param ReflectionFunctionAbstract $function The function or method to analyze.
     *
     * @return array
     */
    protected function getMethodArguments(ReflectionFunctionAbstract $function)
    {
        $args = $function->getParameters();

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

        // For variadic methods, append three dots to the last argument (if any) to indicate this to the user. This
        // requires PHP >= 5.6.
        if (!empty($args) && method_exists($function, 'isVariadic') && $function->isVariadic()) {
            $lastArgument = $args[count($args) - 1];

            if ($lastArgument->isOptional()) {
                $optionals[count($optionals) - 1] .= '...';
            } else {
                $parameters[count($parameters) - 1] .= '...';
            }
        }

        $parser = new DocParser();
        $docComment = $function->getDocComment() ?: '';

        $docParseResult = $parser->parse($docComment, array(
            DocParser::THROWS,
            DocParser::DEPRECATED,
            DocParser::DESCRIPTION,
            DocParser::RETURN_VALUE
        ));

        $docblockInheritsLongDescription = false;

        if (strpos($docParseResult['descriptions']['long'], DocParser::INHERITDOC) !== false) {
            // The parent docblock is embedded, which we'll need to parse. Note that according to phpDocumentor this
            // only works for the long description (not the so-called 'summary' or short description).
            $docblockInheritsLongDescription = true;
        }

        // No immediate docblock available or we need to scan the parent docblock?
        if ((!$docComment || $docblockInheritsLongDescription) && $function instanceof ReflectionMethod) {
            $classIterator = new ReflectionClass($function->class);
            $classIterator = $classIterator->getParentClass();

            // Walk up base classes to see if any of them have additional info about this method.
            while ($classIterator) {
                if ($classIterator->hasMethod($function->getName())) {
                    $baseClassMethod = $classIterator->getMethod($function->getName());

                    if ($baseClassMethod->getDocComment()) {
                        $baseClassMethodArgs = $this->getMethodArguments($baseClassMethod);

                        if (!$docComment) {
                            return $baseClassMethodArgs; // Fall back to parent docblock.
                        } elseif ($docblockInheritsLongDescription) {

                            $docParseResult['descriptions']['long'] = str_replace(
                                DocParser::INHERITDOC,
                                $baseClassMethodArgs['descriptions']['long'],
                                $docParseResult['descriptions']['long']
                            );
                        }

                        break;
                    }
                }

                $classIterator = $classIterator->getParentClass();
            }
        }

        return array(
            'parameters'   => $parameters,
            'optionals'    => $optionals,
            'throws'       => $docParseResult['throws'],
            'return'       => $docParseResult['return'],
            'descriptions' => $docParseResult['descriptions'],
            'deprecated'   => $docParseResult['deprecated']
        );
    }

     /**
      * Fetches information about the specified class property, such as its type, description, ...
      *
      * @param ReflectionProperty $property The property to analyze.
      *
      * @return array
      */
    protected function getPropertyArguments(ReflectionProperty $property)
    {
        $parser = new DocParser();
        $docComment = $property->getDocComment() ?: '';

        $docParseResult = $parser->parse($docComment, array(
            DocParser::VAR_TYPE,
            DocParser::DEPRECATED,
            DocParser::DESCRIPTION
        ));

        if (!$docComment) {
            $classIterator = new ReflectionClass($property->class);
            $classIterator = $classIterator->getParentClass();

            // Walk up base classes to see if any of them have additional info about this property.
            while ($classIterator) {
                if ($classIterator->hasProperty($property->getName())) {
                    $baseClassProperty = $classIterator->getProperty($property->getName());

                    if ($baseClassProperty->getDocComment()) {
                        $baseClassPropertyArgs = $this->getPropertyArguments($baseClassProperty);

                        return $baseClassPropertyArgs; // Fall back to parent docblock.
                    }
                }

                $classIterator = $classIterator->getParentClass();
            }
        }

        return array(
           'return'       => $docParseResult['var'],
           'descriptions' => $docParseResult['descriptions'],
           'deprecated'   => $docParseResult['deprecated']
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
        $traits     = $reflection->getTraits();
        foreach ($traits as $trait) {
            $methods = array_merge($methods, $trait->getMethods());
        }

        // Methods
        foreach ($methods as $method) {
            $data['names'][] = $method->getName();

            $data['values'][$method->getName()] = array(
                'isMethod'       => true,
                'isPublic'       => $method->isPublic(),
                'isProtected'    => $method->isProtected(),
                'args'           => $this->getMethodArguments($method),
                'declaringClass' => $method->getDeclaringClass()->name,
                'startLine'      => $method->getStartLine()
            );
        }

        // Properties
        foreach ($attributes as $attribute) {
            if (!in_array($attribute->getName(), $data['names'])) {
                $data['names'][] = $attribute->getName();
                $data['values'][$attribute->getName()] = null;
            }

            $attributesValues = array(
                'isMethod'       => false,
                'isPublic'       => $attribute->isPublic(),
                'isProtected'    => $attribute->isProtected(),
                'declaringClass' => $attribute->class,
                'args'           => $this->getPropertyArguments($attribute)
            );

            if (is_array($data['values'][$attribute->getName()])) {
                $attributesValues = array(
                    $attributesValues,
                    $data['values'][$attribute->getName()]
                );
            }

            $data['values'][$attribute->getName()] = $attributesValues;
        }

        return $data;
    }
}

?>
