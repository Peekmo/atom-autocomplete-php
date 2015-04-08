phpClassProvider = require "./php-class-provider.coffee"
#phpStaticProvider = require "./php-statics-provider.coffee"

module.exports =
  providers: []

  activate: ->
    @registerProviders()

  deactivate: ->
    @providers = []

  registerProviders: ->
    classesProvider = phpClassProvider
    @providers.push classesProvider

    #staticsProvider = phpStaticsProvider
    #@providers.push staticsProvider
  getProvider: ->
    @providers
