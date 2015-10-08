fuzzaldrin = require 'fuzzaldrin'

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

config = require "../config.coffee"

module.exports =

# Autocompletion for internal PHP constants.
class ConstantProvider extends AbstractProvider
    constants: []

    ###*
     * Get suggestions from the provider (@see provider-api)
     * @return array
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # not preceded by a > (arrow operator), a $ (variable start), ...
        @regex = /(?:(?:^|[^\w\$_\>]))([A-Z_]+)(?![\w\$_\>])/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        @constants = proxy.constants()
        return unless @constants.names?

        suggestions = @findSuggestionsForPrefix(prefix.trim())
        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix
     * @param {string} prefix Prefix to match
     * @return array
    ###
    findSuggestionsForPrefix: (prefix) ->
        # Filter the words using fuzzaldrin
        words = fuzzaldrin.filter @constants.names, prefix

        # Builds suggestions for the words
        suggestions = []
        for word in words
            for element in @constants.values[word]
                suggestions.push
                    text: word,
                    type: 'constant',
                    description: 'Built-in PHP constant.'

        return suggestions
