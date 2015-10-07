fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'
exec = require "child_process"

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

module.exports =

# Autocompletion for members of variables such as after ->, ::.
class MemberProvider extends AbstractProvider
    methods: []

    ###*
     * Get suggestions from the provider (@see provider-api)
     * @return array
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # Autocompletion for class members, i.e. after a ::, ->, ...
        @regex = /(?:[a-zA-Z0-9_]+)(?:\(.*\))?(?:->|::)([a-zA-Z0-9_]*)/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        elements = parser.getStackClasses(editor, bufferPosition)
        return unless elements?

        className = parser.parseElements(editor, bufferPosition, elements)
        return unless className?

        elements = prefix.split(/(->|::)/)

        # We only autocomplete after splitters, so there must be at least one word, one splitter, and another word
        # (the latter which could be empty).
        return unless elements.length > 2

        currentClass = parser.getCurrentClass(editor, bufferPosition)
        currentClassParents = []

        if currentClass
            classInfo = proxy.methods(currentClass)
            currentClassParents = if classInfo?.parents then classInfo?.parents else []

        mustBeStatic = false

        if elements[elements.length - 2] == '::' and elements[elements.length - 3].trim() != 'parent'
            mustBeStatic = true

        suggestions = @findSuggestionsForPrefix(className, elements[elements.length-1].trim(), (element) =>
            # See also ticket #127.
            return false if mustBeStatic and not element.isStatic
            return false if element.isPrivate and element.declaringClass.name != currentClass
            return false if element.isProtected and element.declaringClass.name != currentClass and element.declaringClass.name not in currentClassParents

            # Constants are only available when statically accessed.
            return false if not element.isMethod and not element.isProperty and not mustBeStatic

            return true
        )

        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix
     * @param {string}   className      The name of the class to show members of.
     * @param {string}   prefix         Prefix to match (may be left empty to list all members).
     * @param {callback} filterCallback A callback that should return true if the item should be added to the
     *                                  suggestions list.
     * @return array
    ###
    findSuggestionsForPrefix: (className, prefix, filterCallback) ->
        methods = proxy.methods(className)

        if not methods?.names
            return []

        # Filter the words using fuzzaldrin
        words = fuzzaldrin.filter(methods.names, prefix)

        # Builds suggestions for the words
        suggestions = []

        for word in words
            element = methods.values[word]

            if element not instanceof Array
                element = [element]

            for ele in element
                if filterCallback and not filterCallback(ele)
                    continue

                # Ensure we don't get very long return types by just showing the last part.
                returnValueParts = if ele.args.return then ele.args.return.split('\\') else []
                returnValue = returnValueParts[returnValueParts.length - 1]

                if ele.isMethod
                    type = 'method'
                    snippet = @getFunctionSnippet(word, ele.args)

                else if ele.isProperty
                    type = 'property'
                    snippet = null

                else
                    type = 'constant'
                    snippet = null

                suggestions.push
                    text        : word,
                    type        : type
                    snippet     : snippet
                    leftLabel   : returnValue
                    description : if ele.args.descriptions.short? then ele.args.descriptions.short else ''
                    className   : if ele.args.deprecated then 'php-atom-autocomplete-strike' else ''

        return suggestions
