ClassProvider = require "./php-class-provider.coffee"
StaticProvider = require "./php-statics-provider.coffee"

module.exports =
  providers: []

  activate: ->
    @registerProviders()

  deactivate: ->
    @providers = []

  registerProviders: ->
    @providers.push new ClassProvider()
    @providers.push new StaticProvider()

    #staticsProvider = phpStaticsProvider
    #@providers.push staticsProvider
  getProvider: ->
    @providers
