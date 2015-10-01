fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider.coffee"

module.exports =

# Autocomplete for static methods and constants
class StaticProvider extends AbstractProvider
    statics: []

    ###*
     * Get suggestions from the provider (@see provider-api)
     * @return array
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        @regex = /(\b[\\]?[A-Z][a-zA-Z_\\]+::([a-zA-Z_]*))/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        parts = prefix.split("::")
        @statics = proxy.statics(parser.findUseForClass(editor, parts[0]))
        return unless @statics.names?

        suggestions = @findSuggestionsForPrefix parts[1].trim()
        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix
     * @param {string} prefix Prefix to match
     * @return array
    ###
    findSuggestionsForPrefix: (prefix) ->
        # Filter the words using fuzzaldrin
        words = fuzzaldrin.filter @statics.names, prefix

        # Builds suggestions for the words
        suggestions = []
        for word in words
            element = @statics.values[word]
            if element instanceof Array
                for ele in element
                    suggestions = @addSuggestion(word, ele, suggestions, prefix)
            else
                suggestions = @addSuggestion(word, element, suggestions, prefix)

        return suggestions

    ###*
     * Adds the suggestion the the suggestions array.
     * @param {string} word        The word being currently typed.
     * @param {object} element     The object returns from proxy.methods.
     * @param {array} suggestions  An array of suggestions for the current word.
     * @param {string} word        The prefix to insert for the suggestion.
    ###
    addSuggestion: (word, element, suggestions, prefix) ->
        if element.isPublic
            # Methods
            if element.isMethod
                suggestions.push
                    text: word,
                    type: 'method',
                    snippet: @getFunctionSnippet(word, element.args),
                    replacementPrefix: prefix,
                    leftLabel: element.args.return,
                    description: if element.args.descriptions.short? then element.args.descriptions.short else ''
                    data:
                        prefix: prefix,
                        args: element.args

            # Constants and public static properties
            else
                suggestions.push
                    text: word,
                    type: if element.isProperty then 'property' else 'constant'
                    leftLabel: element.args.return
                    description: if element.args.descriptions.short? then element.args.descriptions.short else ''
                    className: if element.args.deprecated then 'php-atom-autocomplete-strike' else ''
                    replacementPrefix: prefix,
                    data:
                        prefix: prefix

        return suggestions
