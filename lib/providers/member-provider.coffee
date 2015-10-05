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
        @regex = /([a-zA-Z0-9_]+)(?:\(.*\))?(?:->|::)/g

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

        owner = elements[elements.length - 3].trim()

        conditions =
            isStatic    : false
            noProtected : false
            noNonStatic : false

        if elements[elements.length - 2] == '::'
            if owner == 'parent'
                conditions.noPrivate = true

            else if owner == 'self' or owner == 'static'
                conditions.isStatic = true

            else # Static class name.
                conditions.noPrivate = true
                conditions.noProtected = true
                conditions.isStatic = true

        suggestions = @findSuggestionsForPrefix(className, elements[elements.length-1].trim(), conditions)

        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix
     * @param {string} className The name of the class to show members of.
     * @param {string} prefix    Prefix to match (may be left empty to list all members).
     * @param {object} options   Additional conditions to apply to the listed members.
     * @return array
    ###
    findSuggestionsForPrefix: (className, prefix, conditions) ->
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
                if (conditions.isStatic and not ele.isStatic) or
                   (conditions.noPrivate and ele.isPrivate) or
                   (conditions.noProtected and ele.isProtected) or
                   (ele.isPrivate and not ele.isDirectMember)
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

                else if conditions.isStatic
                    # Constants are only available when statically accessed.
                    type = 'constant'
                    snippet = null

                else
                    continue

                suggestions.push
                    text        : word,
                    type        : type
                    snippet     : snippet
                    leftLabel   : returnValue
                    description : if ele.args.descriptions.short? then ele.args.descriptions.short else ''
                    className   : if ele.args.deprecated then 'php-atom-autocomplete-strike' else ''

        return suggestions
