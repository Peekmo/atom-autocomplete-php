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
     require_once($dir . '/vendor/autoload.php');
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
