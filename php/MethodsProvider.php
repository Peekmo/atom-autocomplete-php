<?php

class MethodsProvider extends Tools implements ProviderInterface
{
    /**
     * Execute the command
     * @param  array  $args Arguments gived to the command
     * @return array Response
     */
    public function execute($args = array())
    {
        $class = $args[0];
        $data = array(
            'class'  => $class,
            'names'  => array(),
            'values' => array()
        );

        try {
            $reflection = new ReflectionClass($class);
        } catch (Exception $e) {
            return $data;
        }

        $methods    = $reflection->getMethods();
        $attributes = $reflection->getProperties();

        // Methods
        foreach ($methods as $method) {
            $data['names'][] = $method->getName();

            $args = $method->getParameters();
            array_walk($args, function(&$value, $key) {
                $value = '$' . $value->getName();
            });

            $data['values'][$method->getName()] = array(
                array(
                    'isMethod' => true,
                    'isPublic' => $method->isPublic(),
                    'args'     => $args
                )
            );
        }

        // Properties
        foreach ($attributes as $attribute) {
            if (!in_array($attribute->getName(), $data['names'])) {
                $data['names'][] = $attribute->getName();
                $data['values'][$attribute->getName()] = array();
            }

            $data['values'][$attribute->getName()][] = array(
                'isMethod' => false,
                'isPublic' => $attribute->isPublic()
            );
        }

        return $data;
    }
}
