<?php

require_once(__DIR__ . '/command_classes.php');
require_once(__DIR__ . '/command_statics.php');

/**
 * @author Axel Anceau <Peekmo>
 *
 * This script returns all functions, classes & methods in the given directory.
 * Internals and user's one
 **/

 /**
 * Get functions and classes declared in the given directory
 * @param string $dir Root directory for the script
 **/
 function require_composer_autoloader($dir) {
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
                 require_composer_autoloader($path);
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
  * Function called when a fatal occured
  */
 function fatal_handler() {
     $error = error_get_last();

     if ($error !== NULL) {
         die(json_encode(array('error' => $error)));
     }
 }

 /**
  * Print an error
  * @param string $message
  */
 function show_error($message) {
     die(json_encode(array('error' => array('message' => $message))));
 }

 if (count($argv) < 3) {
     die('Usage : php parser.php <dirname> <command> <args>');
 }

 register_shutdown_function('fatal_handler');

 require_composer_autoloader($argv[1]);
 $command = $argv[2];

 switch($command) {
    case '--classes':
        getClasses();
        break;
    case '--statics':
        getStatics($argv[3]);
        break;
    default:
        show_error(sprintf('Unknown command %s', $command));
 }
