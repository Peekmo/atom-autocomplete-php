parser = require "../services/php-file-parser.coffee"

module.exports =
class AbstractProvider
  regex: ''
  selector: '.source.php'

  inclusionPriority: 1

  disableForSelector: '.source.php .comment, .source.php .string'

  # Only in function scope
  functionOnly: false

  ###*
   * Entry point of all request from autocomplete-plus
   * Calls @fetchSuggestion in the provider if allowed
   * @return array Suggestions
  ###
  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    return if @functionOnly == true and not parser.isInFunction(editor, bufferPosition)

    return @fetchSuggestions({editor, bufferPosition, scopeDescriptor, prefix})

  ###*
   * Builds a snipper for a PHP function
   * @param {string} word     Function name
   * @param {array}  elements All arguments for the snippet (parameters, optionals)
   * @return string The snipper
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
      body += "${" + (lastIndex + 1) + ":["
      body += "," if lastIndex != 0

      lastIndex += 1

      for arg, index in elements.optionals
        body += ", " if index != 0
        body += arg
      body += "]}"

    body += ")$0"

    return body

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
