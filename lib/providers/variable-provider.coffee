fuzzaldrin = require 'fuzzaldrin'

parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

module.exports =

# Autocomplete for local variable names.
class VariableProvider extends AbstractProvider
    variables: []

    ###*
     * Get suggestions from the provider (@see provider-api)
     * @return array
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # "new" keyword or word starting with capital letter
        @regex = /(\$[a-zA-Z_]*)/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        @variables = parser.getAllVariablesInFunction(editor, bufferPosition)
        return unless @variables.length

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
        words = fuzzaldrin.filter @variables, prefix

        # Builds suggestions for the words
        suggestions = []
        for word in words
            suggestions.push
                text: word,
                type: 'variable',
                replacementPrefix: prefix

        return suggestions
