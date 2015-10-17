MethodProvider = require './method-provider.coffee'
PropertyProvider = require './property-provider.coffee'

module.exports =

class AnnotationManager
    providers: []

    ###*
     * Initializes the tooltip providers.
    ###
    init: () ->
        @providers.push new MethodProvider()
        @providers.push new PropertyProvider()

        for provider in @providers
            provider.init(@)

    ###*
     * Deactivates the tooltip providers.
    ###
    deactivate: () ->
        for provider in @providers
            provider.deactivate()
