module.exports =
class AbstractProvider
  regex: ''
  selector: '.source.php'

  inclusionPriority: 1
  excludeLowerPriority: true

  # Build the snippet from the suggestion
  getFunctionSnippet: (word, elements) ->
    body = word + "("
    for arg, index in elements
      body += "," if body != word + "("
      body += "${" + (index+1) + ":" + arg + "}"
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

