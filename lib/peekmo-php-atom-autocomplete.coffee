ClassProvider = require "./providers/class-provider.coffee"
StaticProvider = require "./providers/static-provider.coffee"
ThisProvider = require "./providers/this-provider.coffee"
FunctionProvider = require "./providers/function-provider.coffee"
VariableProvider = require "./providers/variable-provider.coffee"

config = require './config.coffee'

module.exports =
  config:
    binComposer:
      title: 'Command to use composer'
      description: 'This plugin depends on composer in order to work. Specify the path
       to your composer bin (e.g : bin/composer, composer.phar, composer)'
      type: 'string'
      default: 'composer'
      order: 1

    binPhp:
      title: 'Command php'
      description: 'This plugin use php CLI in order to work. Please specify your php
       command ("php" on UNIX systems)'
      type: 'string'
      default: 'php'
      order: 2

    autoloadPaths:
      title: 'Composer autoloader directories'
      description: 'Relative path to the directory of autoload.php from composer. You can specify multiple
       paths (comma separated) if you have different paths for some projects.'
      type: 'array'
      default: ['vendor']
      order: 3

  providers: []

  activate: ->
    @registerProviders()
    config.init()

  deactivate: ->
    @providers = []

  registerProviders: ->
    @providers.push new ClassProvider()
    @providers.push new StaticProvider()
    @providers.push new ThisProvider()
    @providers.push new VariableProvider()
    @providers.push new FunctionProvider()

  getProvider: ->
    @providers
