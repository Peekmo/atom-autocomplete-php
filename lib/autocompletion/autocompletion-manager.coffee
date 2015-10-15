ClassProvider = require './class-provider.coffee'
MemberProvider = require './member-provider.coffee'
ConstantProvider = require './constant-provider.coffee'
VariableProvider = require './variable-provider.coffee'
FunctionProvider = require './function-provider.coffee'

module.exports =

class AutocompletionManager
    providers: []

    ###*
     * Initializes the autocompletion providers.
    ###
    init: () ->
        @providers.push new ConstantProvider()
        @providers.push new VariableProvider()
        @providers.push new FunctionProvider()
        @providers.push new ClassProvider()
        @providers.push new MemberProvider()

        for provider in @providers
            provider.init(@)

    ###*
     * Deactivates the autocompletion providers.
    ###
    deactivate: () ->
        for provider in @providers
            provider.deactivate()

    ###*
     * Deactivates the autocompletion providers.
    ###
    getProviders: () ->
        @providers
