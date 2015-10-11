ClassProvider = require './class-provider.coffee'
FunctionProvider = require './function-provider.coffee'
PropertyProvider = require './property-provider.coffee'

module.exports =

class TooltipManager
    providers: []

    ###*
     * Initializes the tooltip providers.
    ###
    init: () ->
        @providers.push new ClassProvider()
        @providers.push new FunctionProvider()
        @providers.push new PropertyProvider()

        for provider in @providers
            provider.init(@)

    ###*
     * Deactivates the tooltip providers.
    ###
    deactivate: () ->
        for provider in @providers
            provider.deactivate()
