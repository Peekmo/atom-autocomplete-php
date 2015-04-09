module.exports =
  # Build the snippet from the suggestion
  getFunctionSnippet: (word, elements) ->
    body = word + "("
    for arg, index in elements
      body += "," if body != word + "("
      body += "${" + (index+1) + ":" + arg + "}"
    body += ")$0"

    return body
