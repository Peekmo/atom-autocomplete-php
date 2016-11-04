fuzzaldrin = require 'fuzzaldrin'

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

config = require "../config.coffee"

module.exports =

# Autocompletion for internal PHP functions.
class FunctionProvider extends AbstractProvider
    functions: []

    ###*
     * Get suggestions from the provider (@see provider-api)
     * @return array
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # not preceded by a > (arrow operator), a $ (variable start), ...
        @regex = /(?:(?:^|[^\w\$_\>]))([a-zA-Z_]+)(?![\w\$_\>])/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        @functions = proxy.functions()
        return unless @functions?.names?

        characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
        insertParameterList = if characterAfterPrefix == '(' then false else true

        suggestions = @findSuggestionsForPrefix(prefix.trim(), insertParameterList)
        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {string} prefix              Prefix to match.
     * @param {bool}   insertParameterList Whether to insert a list of parameters.
     *
     * @return {Array}
    ###
    findSuggestionsForPrefix: (prefix, insertParameterList = true) ->
        # Filter the words using fuzzaldrin
        words = fuzzaldrin.filter @functions.names, prefix

        # Builds suggestions for the words
        suggestions = []
        for word in words
            for element in @functions.values[word]
                returnValueParts = if element.args.return?.type then element.args.return.type.split('\\') else []
                returnValue = returnValueParts[returnValueParts.length - 1]

                suggestion =
                    text: word,
                    type: 'function',
                    description: if element.isInternal then 'Built-in PHP function.' else (if element.args.descriptions.short? then element.args.descriptions.short else '')
                    className: if element.args.deprecated then 'php-atom-autocomplete-strike' else ''
                    snippet: if insertParameterList then @getFunctionSnippet(word, element.args) else null
                    displayText: @getFunctionSignature(word, element.args)
                    replacementPrefix: prefix
                    leftLabel: returnValue

                if element.isInternal
                  suggestion.descriptionMoreURL = config.config.php_documentation_base_url.functions + word

                suggestions.push suggestion


        return suggestions
