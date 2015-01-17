<?php

require_once(__DIR__ . '/classes_parser.php');

/**
* Get functions and classes declared in the given directory
* @param string $dir Root directory for the script
**/
function get_functions_and_classes($dir) {
    if (!is_dir($dir)) {
        die(sprintf('Fatal error : %s is not a directory', $dir));
    }

    $current = explode('/', $dir);
    $files = scandir($dir);

    foreach ($files as $file) {
        // OSX & linux users
        if ('.' !== $file && '..' !== $file) {
            $path = $dir . '/' . $file;
            if (is_dir($path)) {
                get_functions_and_classes($path);
            } else {
                if (in_array(pathinfo($path, PATHINFO_EXTENSION), array('php'))) {
                    if (strpos($path, 'vendor/autoload.php') !== false) {
                        require_once($path);
                    }
                }
            }
        }
    }
}

/**
 * Get classes from composer & internals
 * @return array
 */
function getClasses($dirname) {
    $mapping = get_functions_and_classes($dirname);

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

    echo json_encode($classes);
}

?>
