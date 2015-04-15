<?php

/**
 * @author Axel Anceau <Peekmo>
 *
 * This script returns all functions, classes & methods in the given directory.
 * Internals and user's one
 **/
require_once(__DIR__ . '/Config.php');
require_once(__DIR__ . '/services/Tools.php');
require_once(__DIR__ . '/services/DocParser.php');
require_once(__DIR__ . '/providers/ProviderInterface.php');
require_once(__DIR__ . '/providers/StaticsProvider.php');
require_once(__DIR__ . '/providers/MethodsProvider.php');
require_once(__DIR__ . '/providers/ClassesProvider.php');
require_once(__DIR__ . '/providers/FunctionsProvider.php');

$commands = array(
    '--classes'   => 'ClassesProvider',
    '--statics'   => 'StaticsProvider',
    '--methods'   => 'MethodsProvider',
    '--functions' => 'FunctionsProvider'
);

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

$project = $argv[1];
$command = $argv[2];

if (!isset($commands[$command])) {
    show_error(sprintf('Command %s not found', $command));
}

require_once($project . '/vendor/autoload.php');
Config::set('classmap_file', $project . '/vendor/composer/autoload_classmap.php');

$new = new $commands[$command]();
$data = $new->execute(array_slice($argv, 3));

if (false === $encoded = json_encode($data)) {
    echo json_encode(array());
} else {
    echo $encoded;
}
