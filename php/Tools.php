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
        if (empty($classMap) || $force) {
            if (!file_exists(Config::get('classmap_file')) || $force) {
                exec('composer dump-autoload --optimize');
            }

            $this->classMap = require(Config::get('classmap_file'));
        }

        return $this->classMap;
    }

    /**
     * Returns names from all classes registered
     * @param bool $force Force fetching from composer command
     * @return array
     */
    protected function getClassNames($force = false)
    {
        $map = $this->getClassMap($force);

        return array_merge(array_keys($map), get_declared_classes());
    }

    /**
     * Format parameters for the autocomplete plugin
     * @param ReflectionMethod $method Method to get arguments from
     * @return array
     */
    protected function getMethodArguments($method)
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

        return array(
            'parameters' => $parameters,
            'optionals' => $optionals
        );
    }
}

?>
