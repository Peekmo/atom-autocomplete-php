<?php

class StaticsProvider extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $class = $args[0];

        $statics = array(
            'class'  => $class,
            'names'  => array(),
            'values' => array()
        );

        try {
            $reflection = new ReflectionClass($class);
        } catch (Exception $e) {
            return $statics;
        }

        $methods    = $reflection->getMethods(ReflectionMethod::IS_STATIC);
        $constants  = $reflection->getConstants();
        $attributes = $reflection->getProperties(ReflectionProperty::IS_STATIC);

        // Methods
        foreach ($methods as $method) {
            $statics['names'][] = $method->getName();

            $args = $this->getMethodArguments($method, $class); 

            $statics['values'][$method->getName()] = array(
                array(
                    'isMethod' => true,
                    'isPublic' => $method->isPublic(),
                    'args'     => $args
                )
            );
        }

        // Constants
        foreach ($constants as $constant => $value) {
            if (!in_array($constant, $statics['names'])) {
                $statics['names'][] = $constant;
                $statics['values'][$constant] = array();
            }

            $statics['values'][$constant][] = array(
                'isMethod' => false,
                'isPublic' => true
            );
        }

        // Properties
        foreach ($attributes as $attribute) {
            if (!in_array($attribute->getName(), $statics['names'])) {
                $statics['names'][] = $attribute->getName();
                $statics['values'][$attribute->getName()] = array();
            }

            $statics['values'][$attribute->getName()][] = array(
                'isMethod' => false,
                'isPublic' => $attribute->isPublic()
            );
        }

        return $statics;
    }
}
