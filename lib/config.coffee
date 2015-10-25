fs = require 'fs'
namespace = require './services/namespace.coffee'
StatusInProgress = require "./services/status-in-progress.coffee"

module.exports =

    config: {}
    statusInProgress: null

    ###*
     * Get plugin configuration
    ###
    getConfig: () ->
        # See also https://secure.php.net/urlhowto.php .
        @config['php_documentation_base_url'] = {
            functions: 'https://secure.php.net/function.'
        }

        @config['composer'] = atom.config.get('atom-autocomplete-php.binComposer')
        @config['php'] = atom.config.get('atom-autocomplete-php.binPhp')
        @config['autoload'] = atom.config.get('atom-autocomplete-php.autoloadPaths')
        @config['classmap'] = atom.config.get('atom-autocomplete-php.classMapFiles')
        @config['packagePath'] = atom.packages.resolvePackagePath('atom-autocomplete-php')
        @config['verboseErrors'] = atom.config.get('atom-autocomplete-php.verboseErrors')
        @config['insertNewlinesForUseStatements'] = atom.config.get('atom-autocomplete-php.insertNewlinesForUseStatements')

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
          'Composer, make sure they are in your PATH.
          Feel free to look package\'s README for configuration examples'

        if testResult.status = null or testResult.status != 0
            atom.notifications.addError(errorTitle, {'detail': errorMessage})
            return false

        # Test Composer.
        testResult = exec.spawnSync(@config.php, [@config.composer, "--version"])

        if testResult.status = null or testResult.status != 0
            testResult = exec.spawnSync(@config.composer, ["--version"])

            # Try executing Composer directly.
            if testResult.status = null or testResult.status != 0
                atom.notifications.addError(errorTitle, {'detail': errorMessage})
                return false

        if interactive
            atom.notifications.addSuccess('atom-autocomplete-php - Success', {'detail': 'Configuration OK !'})

        return true

    ###*
     * Init function called on package activation
     * Register config events and write the first config
    ###
    init: () ->
        @statusInProgress = new StatusInProgress
        @statusInProgress.hide()

        # Command for namespaces
        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:namespace': =>
            namespace.createNamespace(atom.workspace.getActivePaneItem())

        # Command to test configuration
        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:configuration': =>
            @testConfig(true)

        @writeConfig()

        atom.config.onDidChange 'atom-autocomplete-php.binPhp', () =>
            @writeConfig()
            @testConfig(true)

        atom.config.onDidChange 'atom-autocomplete-php.binComposer', () =>
            @writeConfig()
            @testConfig(true)

        atom.config.onDidChange 'atom-autocomplete-php.autoloadPaths', () =>
            @writeConfig()

        atom.config.onDidChange 'atom-autocomplete-php.classMapFiles', () =>
            @writeConfig()

        atom.config.onDidChange 'atom-autocomplete-php.verboseErrors', () =>
            @writeConfig()

        atom.config.onDidChange 'atom-autocomplete-php.insertNewlinesForUseStatements', () =>
            @writeConfig()
