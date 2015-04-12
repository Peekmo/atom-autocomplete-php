ClassProvider = require "./providers/class-provider.coffee"
StaticProvider = require "./providers/static-provider.coffee"
ThisProvider = require "./providers/this-provider.coffee"
FunctionProvider = require "./providers/function-provider.coffee"

module.exports =
  providers: []

  activate: ->
    @registerProviders()

  deactivate: ->
    @providers = []

  registerProviders: ->
    @providers.push new ClassProvider()
    @providers.push new StaticProvider()
    @providers.push new ThisProvider()
    @providers.push new FunctionProvider()

    #staticsProvider = phpStaticsProvider
    #@providers.push staticsProvider
  getProvider: ->
    @providers
