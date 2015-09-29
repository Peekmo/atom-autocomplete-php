fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider.coffee"

module.exports =

# Autocomplete for parent keyword
class ParentProvider extends AbstractProvider
    parent: []
    functionOnly: true

    ###*
     * Get suggestions from the provider (@see provider-api)
     * @return array
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        @regex = /(\bparent::([a-zA-Z_]*))/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        parts = prefix.split("::")
        @parent = proxy.parent(parser.getCurrentClass(editor, bufferPosition))
        return unless @parent.names?

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
        words = fuzzaldrin.filter @parent.names, prefix

        # Builds suggestions for the words
        suggestions = []
        for word in words
            element = @parent.values[word]
            if element.isPublic or element.isProtected
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

        return suggestions
