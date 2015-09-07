ClassProvider = require "./providers/class-provider.coffee"
StaticProvider = require "./providers/static-provider.coffee"
FunctionProvider = require "./providers/function-provider.coffee"
VariableProvider = require "./providers/variable-provider.coffee"
AutocompleteProvider = require "./providers/autocomplete-provider.coffee"
ParentProvider = require "./providers/parent-provider.coffee"
SelfProvider = require "./providers/self-provider.coffee"

GotoManager = require "./goto/goto-manager.coffee"

config = require './config.coffee'
proxy = require './services/php-proxy.coffee'

module.exports =
  config:
    binComposer:
      title: 'Command to use composer'
      description: 'This plugin depends on composer in order to work. Specify the path
       to your composer bin (e.g : bin/composer, composer.phar, composer)'
      type: 'string'
      default: '/usr/local/bin/composer'
      order: 1

    binPhp:
      title: 'Command php'
      description: 'This plugin use php CLI in order to work. Please specify your php
       command ("php" on UNIX systems)'
      type: 'string'
      default: 'php'
      order: 2

    autoloadPaths:
      title: 'Autoloader file'
      description: 'Relative path to the files of autoload.php from composer (or an other one). You can specify multiple
       paths (comma separated) if you have different paths for some projects.'
      type: 'array'
      default: ['vendor/autoload.php', 'autoload.php']
      order: 3

    classMapFiles:
      title: 'Classmap files'
      description: 'Relative path to the files that contains a classmap (array with "className" => "fileName"). By default
       on composer it\'s vendor/composer/autoload_classmap.php'
      type: 'array'
      default: ['vendor/composer/autoload_classmap.php', 'autoload/ezp_kernel.php']
      order: 4

  providers: []

  activate: ->
    if not config.testConfig()
      return

    @registerProviders()
    @gotoManager = new GotoManager()
    @gotoManager.init()
    config.init()
    proxy.init()

  deactivate: ->
    @providers = []
    @gotoManager.deactivate()

  registerProviders: ->
    @providers.push new VariableProvider()
    @providers.push new FunctionProvider()

    try
        proxy.composer()
    catch err
        return

    @providers.push new ClassProvider()
    @providers.push new AutocompleteProvider()
    @providers.push new StaticProvider()
    @providers.push new SelfProvider()
    @providers.push new ParentProvider()

  getProvider: ->
    @providers
