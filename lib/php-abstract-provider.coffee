{Provider, Suggestion} = require "autocomplete-plus"

module.exports =
# Tooling for all providers
class PhpAbstractProvider extends Provider
  classes: []

  # Build the snippet from the suggestion
  showSnippet: (suggestion) ->
    snippetModule = atom.packages.getActivePackage('snippets').mainModule

    body = "("
    for arg, index in suggestion.data.args
      body += "," if body != "("
      body += "${" + (index+1) + ":" + arg + "}"
    body += ")$0"

    snippet =
      ".source.php":
        "php_snippet":
          prefix: suggestion.prefix
          body: suggestion.word + body
    snippetModule.add('current', snippet)

    # Emit the snippet
    snippetModule.expandSnippetsUnderCursors(@editor)
