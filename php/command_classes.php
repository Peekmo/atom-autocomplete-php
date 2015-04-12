<?php

require_once(__DIR__ . '/classes_parser.php');

/**
 * Get classes from composer & internals
 * @return array
 */
function getClasses() {
    $classNames = get_declared_classes();
    $classes = array('names' => array(), 'functions' => array());
    foreach ($classNames as $class) {
        try {
            $reflection = new ReflectionClass($class);
        } catch (Exception $e) {
            continue;
        }

        $ctor = $reflection->getConstructor();

        $args = array();
        if (!is_null($ctor)) {
            $args = $ctor->getParameters();
            array_walk($args, function(&$value, $key) {
                $value = '$' . $value->getName();
            });
        }

        $classes['names'][] = $class;
        $classes['methods'][$class] = array(
            'constructor' => array(
                'has'  => !is_null($ctor),
                'args' => $args
            )
        );

    }

    return $classes;
}

?>
