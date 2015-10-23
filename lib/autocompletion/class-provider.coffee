fuzzaldrin = require 'fuzzaldrin'
exec = require "child_process"

config = require "../config.coffee"
proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

module.exports =

# Autocompletion for class names (e.g. after the new or use keyword).
class ClassProvider extends AbstractProvider
    classes = []
    disableForSelector: '.source.php .string'

    ###*
     * Get suggestions from the provider (@see provider-api)
     * @return array
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # "new" keyword or word starting with capital letter
        @regex = /((?:new|use)?(?:[^a-z0-9_])\\?(?:[A-Z][a-zA-Z_\\]*)+)/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        @classes = proxy.classes()
        return unless @classes?.autocomplete?

        characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
        insertParameterList = if characterAfterPrefix == '(' then false else true

        suggestions = @findSuggestionsForPrefix(prefix.trim(), insertParameterList)
        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix
     * @param {string} prefix              Prefix to match.
     * @param {bool}   insertParameterList Whether to insert a list of parameters for methods.
     * @return array
    ###
    findSuggestionsForPrefix: (prefix, insertParameterList = true) ->
        # Get rid of the leading "new" or "use" keyword
        instantiation = false
        use = false

        if prefix.indexOf("new \\") != -1
            instantiation = true
            prefix = prefix.replace /new \\/, ''
        else if prefix.indexOf("new ") != -1
            instantiation = true
            prefix = prefix.replace /new /, ''
        else if prefix.indexOf("use ") != -1
            use = true
            prefix = prefix.replace /use /, ''

        if prefix.indexOf("\\") == 0
            prefix = prefix.substring(1, prefix.length)

        # Filter the words using fuzzaldrin
        words = fuzzaldrin.filter @classes.autocomplete, prefix

        # Builds suggestions for the words
        suggestions = []

        for word in words when word isnt prefix
            classInfo = @classes.mapping[word]

            # Just print classes with constructors with "new"
            if instantiation and @classes.mapping[word].methods.constructor.has
                args = classInfo.methods.constructor.args

                suggestions.push
                    text: word,
                    type: 'class',
                    className: if classInfo.class.deprecated then 'php-atom-autocomplete-strike' else ''
                    snippet: if insertParameterList then @getFunctionSnippet(word, args) else null
                    displayText: @getFunctionSignature(word, args)
                    data:
                        kind: 'instantiation',
                        prefix: prefix,
                        replacementPrefix: prefix

            else if use
                suggestions.push
                    text: word,
                    type: 'class',
                    prefix: prefix,
                    className: if classInfo.class.deprecated then 'php-atom-autocomplete-strike' else ''
                    replacementPrefix: prefix,
                    data:
                        kind: 'use'

            # Not instantiation => not printing constructor params
            else
                suggestions.push
                    text: word,
                    type: 'class',
                    className: if classInfo.class.deprecated then 'php-atom-autocomplete-strike' else ''
                    data:
                        kind: 'static',
                        prefix: prefix,
                        replacementPrefix: prefix

        return suggestions

    ###*
     * Adds the missing use if needed
     * @param {TextEditor} editor
     * @param {Position}   triggerPosition
     * @param {object}     suggestion
    ###
    onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
        return unless suggestion.data?.kind

        if suggestion.data.kind == 'instantiation' or suggestion.data.kind == 'static'
            editor.transact () =>
                linesAdded = parser.addUseClass(editor, suggestion.text, config.config.insertNewlinesForUseStatements)

                # Removes namespace from classname
                if linesAdded != null
                    name = suggestion.text
                    splits = name.split('\\')

                    nameLength = splits[splits.length-1].length
                    startColumn = triggerPosition.column - suggestion.data.prefix.length
                    row = triggerPosition.row + linesAdded

                    if suggestion.data.kind == 'instantiation'
                        endColumn = startColumn + name.length - nameLength - splits.length + 1

                    else
                        endColumn = startColumn + name.length - nameLength

                    editor.setTextInBufferRange([
                        [row, startColumn],
                        [row, endColumn] # Because when selected there's not \ (why?)
                    ], "")
