<?php

/**
 * @author Axel Anceau <Peekmo>
 *
 * This script returns all functions, classes & methods in the given directory.
 * Internals and user's one
 **/
require_once(__DIR__ . '/ErrorHandler.php');
ErrorHandler::register();

require_once(__DIR__ . '/tmp.php');
require_once(__DIR__ . '/Config.php');
require_once(__DIR__ . '/services/Tools.php');
require_once(__DIR__ . '/services/DocParser.php');
require_once(__DIR__ . '/services/FileParser.php');
require_once(__DIR__ . '/providers/ProviderInterface.php');
require_once(__DIR__ . '/providers/StaticsProvider.php');
require_once(__DIR__ . '/providers/AutocompleteProvider.php');
require_once(__DIR__ . '/providers/MethodsProvider.php');
require_once(__DIR__ . '/providers/ClassesProvider.php');
require_once(__DIR__ . '/providers/ClassProvider.php');
require_once(__DIR__ . '/providers/FunctionsProvider.php');
require_once(__DIR__ . '/providers/ClassMapRefresh.php');
require_once(__DIR__ . '/providers/ParentProvider.php');

$commands = array(
    '--classes'      => 'ClassesProvider',
    '--class'        => 'ClassProvider',
    '--statics'      => 'StaticsProvider',
    '--methods'      => 'MethodsProvider',
    '--functions'    => 'FunctionsProvider',
    '--refresh'      => 'ClassMapRefresh',
    '--autocomplete' => 'AutocompleteProvider',
    '--parent'       => 'ParentProvider'
);

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

$project = $argv[1];
$command = $argv[2];

if (!isset($commands[$command])) {
    show_error(sprintf('Command %s not found', $command));
}

// Config
Config::set('composer', $config['composer']);
Config::set('php', $config['php']);
Config::set('projectPath', $project);

// To see if it fix #19
chdir(Config::get('projectPath'));
$indexDir =  __DIR__ . '/../indexes/' . md5($project);
if (!is_dir($indexDir)) {
    if (false === mkdir($indexDir, 0777, true)) {
        show_error('Unable to create directory ' . $indexDir);
    }
}

Config::set('indexClasses', $indexDir . '/index.classes.json');

foreach ($config['autoload'] as $conf) {
    $path = sprintf('%s/%s', $project, trim($conf, '/'));
    if (file_exists($path)) {
        require_once($path);
        break;
    }
}

foreach ($config['classmap'] as $conf) {
    $path = sprintf('%s/%s', $project, trim($conf, '/'));
    if (file_exists($path)) {
        Config::set('classmap_file', $path);
        break;
    }
}

$new = new $commands[$command]();
$data = $new->execute(array_slice($argv, 3));

if (false === $encoded = json_encode($data)) {
    echo json_encode(array());
} else {
    echo $encoded;
}
