<?php

/**
 * @author Axel Anceau <Peekmo>
 *
 * This script returns all functions, classes & methods in the given directory.
 * Internals and user's one
 **/

 /**
  * Require all PHP files who are in the given $dir
  * @param string $dir Root directory for the script
  **/
 function require_php_files($dir) {
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
                 require_php_files($path);
             } else {
                 if (false !== strpos($file, '.php')) {
                     @require_once $path;
                 }
             }
         }
     }
 }

 /**
  * Generates the mapping from all files required before
  * @return array
  **/
 function generate_mapping() {
     $functions = get_defined_functions();
     die(var_dump($functions));
 }

 set_error_handler(function($errno, $errstr, $errfile, $errline) {
     echo 'Error : ' . $errfile . PHP_EOL;
     return true;
 });

 if (count($argv) != 2) {
     die('Usage : php parser.php <dirname>');
 }

 require_php_files($argv[1]);
 $mapping = generate_mapping();

 // Returns json for the JS
 echo json_encode($mapping);
