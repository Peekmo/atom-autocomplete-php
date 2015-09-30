fs = require 'fs'
namespace = require './services/namespace.coffee'

module.exports =

    config: {}

    ###*
     * Get plugin configuration
    ###
    getConfig: () ->
        # See also https://secure.php.net/urlhowto.php .
        @config['php_function_documentation_base_url'] = 'https://secure.php.net/function.';
        @config['composer'] = atom.config.get('atom-autocomplete-php.binComposer')
        @config['php'] = atom.config.get('atom-autocomplete-php.binPhp')
        @config['autoload'] = atom.config.get('atom-autocomplete-php.autoloadPaths')
        @config['classmap'] = atom.config.get('atom-autocomplete-php.classMapFiles')
        @config['packagePath'] = atom.packages.resolvePackagePath('atom-autocomplete-php')

    ###*
     * Writes configuration in "php lib" folder
    ###
    writeConfig: () ->
        @getConfig()

        files = ""
        for file in @config.autoload
            files += "'#{file}',"

        classmaps = ""
        for classmap in @config.classmap
            classmaps += "'#{classmap}',"

        text = "<?php
          $config = array(
            'composer' => '#{@config.composer}',
            'php' => '#{@config.php}',
            'autoload' => array(#{files}),
            'classmap' => array(#{classmaps})
          );
        "

        fs.writeFileSync(@config.packagePath + '/php/tmp.php', text)

    ###*
     * Tests the user's PHP and Composer configuration.
     * @return {bool}
    ###
    testConfig: (interactive) ->
        @getConfig()

        exec = require "child_process"
        testResult = exec.spawnSync(@config.php, ["-v"])

        errorTitle = 'atom-autocomplete-php - Incorrect setup!'
        errorMessage = 'Either PHP or Composer is not correctly set up and as a result PHP autocompletion will not work. ' +
          'Please visit the settings screen to correct this error. If you are not specifying an absolute path for PHP or ' +
          'Composer, make sure they are in your PATH.'

        if testResult.status = null or testResult.status != 0
            atom.notifications.addError(errorTitle, {'detail': errorMessage})
            return false

        # Test Composer.
        testResult = exec.spawnSync(@config.composer, ["--version"])

        if testResult.status = null or testResult.status != 0
            atom.notifications.addError(errorTitle, {'detail': errorMessage})
            return false
        else if interactive
            atom.notifications.addSuccess('atom-autocomplete-php - Success', {'detail': 'Configuration OK !'})
            return false

        return true

    ###*
     * Init function called on package activation
     * Register config events and write the first config
    ###
    init: () ->
        # Command for namespaces
        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:namespace': =>
            namespace.createNamespace(atom.workspace.getActivePaneItem())

        # Command to test configuration
        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:configuration': =>
            @testConfig(true)

        @writeConfig()

        atom.config.onDidChange 'atom-autocomplete-php.binPhp', () =>
            @writeConfig()

        atom.config.onDidChange 'atom-autocomplete-php.binComposer', () =>
            @writeConfig()

        atom.config.onDidChange 'atom-autocomplete-php.autoloadPaths', () =>
            @writeConfig()

        atom.config.onDidChange 'atom-autocomplete-php.classMapFiles', () =>
            @writeConfig()
