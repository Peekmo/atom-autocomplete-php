<?php

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

        $classMap = $this->getClassMap();
        $data = $this->getClassMetadata($class);
        if (!isset($data['values'][$name]) || !isset($classMap[$class])) {
            return array(
                'class'  => $className,
                'names'  => array(),
                'values' => array()
            );
        }

        $returnValue = $data['values'][$name]['args']['return'];
        if (ucfirst($returnValue) === $returnValue) {
            $parser = new FileParser($classMap[$class]);
            $className = $parser->getCompleteNamespace($returnValue);

            return $this->getClassMetadata($className);
        }
    }
}
