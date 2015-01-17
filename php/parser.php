<?php

require_once(__DIR__ . '/command_classes.php');

/**
 * @author Axel Anceau <Peekmo>
 *
 * This script returns all functions, classes & methods in the given directory.
 * Internals and user's one
 **/

 /**
  * Function called when a fatal occured
  */
 function fatal_handler() {
     $error = error_get_last();

     if ($error !== NULL) {
         echo json_encode(array('error' => $error));
     }
 }

 function show_error($message) {
     die(json_encode(array('error' => array('message' => $message))));
 }

 if (count($argv) < 2) {
     die('Usage : php parser.php <command> <args>');
 }

 register_shutdown_function('fatal_handler');

 $command = $argv[1];

 switch($command) {
     case '--classes':
        if (count($argv) !== 3) {
            show_error(sprintf('Command %s, not enough arguments', $command));
        }

        getClasses($argv[2]);
        break;
    default:
        show_error(sprintf('Unknown command %s', $command));
 }
