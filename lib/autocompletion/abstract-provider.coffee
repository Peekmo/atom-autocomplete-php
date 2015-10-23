parser = require "../services/php-file-parser.coffee"

module.exports =

# Abstract base class for autocompletion providers.
class AbstractProvider
    regex: ''
    selector: '.source.php'

    inclusionPriority: 1

    disableForSelector: '.source.php .comment, .source.php .string'

    ###*
     * Initializes this provider.
    ###
    init: () ->

    ###*
     * Deactives the provider.
    ###
    deactivate: () ->

    ###*
     * Entry point of all request from autocomplete-plus
     * Calls @fetchSuggestion in the provider if allowed
     * @return array Suggestions
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return @fetchSuggestions({editor, bufferPosition, scopeDescriptor, prefix})

    ###*
     * Builds a snippet for a PHP function
     * @param {string} word     Function name
     * @param {array}  elements All arguments for the snippet (parameters, optionals)
     * @return string The snippet
    ###
    getFunctionSnippet: (word, elements) ->
        body = word + "("
        lastIndex = 0

        # Non optional elements
        for arg, index in elements.parameters
            body += ", " if index != 0
            body += "${" + (index+1) + ":" + arg + "}"
            lastIndex = index+1

        # Optional elements. One big same snippet
        if elements.optionals.length > 0
            body += " ${" + (lastIndex + 1) + ":["
            body += ", " if lastIndex != 0

            lastIndex += 1

            for arg, index in elements.optionals
                body += ", " if index != 0
                body += arg
            body += "]}"

        body += ")"

        # Ensure the user ends up after the inserted text when he's done cycling through the parameters with tab.
        body += "$0"

        return body

    ###*
     * Builds the signature for a PHP function
     * @param {string} word     Function name
     * @param {array}  elements All arguments for the signature (parameters, optionals)
     * @return string The signature
    ###
    getFunctionSignature: (word, element) ->
        snippet = @getFunctionSnippet(word, element)

        # Just strip out the placeholders.
        signature = snippet.replace(/\$\{\d+:([^\}]+)\}/g, '$1')

        return signature[0 .. -3]

    ###*
     * Get prefix from bufferPosition and @regex
     * @return string
    ###
    getPrefix: (editor, bufferPosition) ->
        # Get the text for the line up to the triggered buffer position
        line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

        # Match the regex to the line, and return the match
        matches = line.match(@regex)

        # Looking for the correct match
        if matches?
            for match in matches
                start = bufferPosition.column - match.length
                if start >= 0
                    word = editor.getTextInBufferRange([[bufferPosition.row, bufferPosition.column - match.length], bufferPosition])
                    if word == match
                        # Not really nice hack.. But non matching groups take the first word before. So I remove it.
                        # Necessary to have completion juste next to a ( or [ or {
                        if match[0] == '{' or match[0] == '(' or match[0] == '['
                            match = match.substring(1)

                        return match

        return ''
