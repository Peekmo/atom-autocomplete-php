module.exports =
class AbstractProvider
  regex: ''
  selector: '.source.php'

  inclusionPriority: 1
  excludeLowerPriority: true

  disableForSelector: '.source.php .comment, .source.php .string'

  # Build the snippet from the suggestion
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

  # Return the prefix to delete if press enter
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
            return match

    return ''
