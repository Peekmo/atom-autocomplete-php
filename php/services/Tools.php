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
                exec(Config::get('composer') . ' -d=' . Config::get('projectPath') .' dump-autoload --optimize');
            }

            if (Config::get('classmap_file')) {
                $this->classMap = require(Config::get('classmap_file'));
            }
        }

        return $this->classMap;
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
