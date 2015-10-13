MethodProvider = require './method-provider.coffee'

module.exports =

class AnnotationManager
    providers: []

    ###*
     * Initializes the tooltip providers.
    ###
    init: () ->
        @providers.push new MethodProvider()

        for provider in @providers
            provider.init(@)

    ###*
     * Deactivates the tooltip providers.
    ###
    deactivate: () ->
        for provider in @providers
            provider.deactivate()
