ClassProvider = require "./php-class-provider.coffee"
#phpStaticProvider = require "./php-statics-provider.coffee"

module.exports =
  providers: []

  activate: ->
    @registerProviders()

  deactivate: ->
    @providers = []

  registerProviders: ->
    @providers.push new ClassProvider()

    #staticsProvider = phpStaticsProvider
    #@providers.push staticsProvider
  getProvider: ->
    @providers
