fs = require 'fs'

module.exports =
  config: {}

  ###*
   * Get plugin configuration
  ###
  getConfig: () ->
    @config['composer'] = atom.config.get('atom-autocomplete-php.binComposer')
    @config['php'] = atom.config.get('atom-autocomplete-php.binPhp')
    @config['autoload'] = atom.config.get('atom-autocomplete-php.autoloadPaths')
    @config['packagePath'] = atom.packages.resolvePackagePath('atom-autocomplete-php')

  ###*
   * Writes configuration in "php lib" folder
  ###
  writeConfig: () ->
    @getConfig()

    files = ""
    for file in @config.autoload
      files += "'#{file}',"

    text = "<?php
      $config = array(
        'composer' => '#{@config.composer}',
        'php' => '#{@config.php}',
        'autoload' => array(#{files})
      );
    "

    fs.writeFile(@config.packagePath + '/php/tmp.php', text)

  ###*
   * Init function called on package activation
   * Register config events and write the first config
  ###
  init: () ->
    @writeConfig()

    atom.config.onDidChange 'atom-autocomplete-php.binPhp', () =>
      @writeConfig()

    atom.config.onDidChange 'atom-autocomplete-php.binComposer', () =>
      @writeConfig()

    atom.config.onDidChange 'atom-autocomplete-php.autoloadPaths', () =>
      @writeConfig()
