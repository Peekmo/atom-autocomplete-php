<?php

/**
* Get all methods/attributes from the given class
* @return array
*/
function getMethods($class) {
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

?>
