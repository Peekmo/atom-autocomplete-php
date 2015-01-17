{Provider, Suggestion} = require "autocomplete-plus"
fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'
exec = require "child_process"

internals = require "./php-internals.coffee"
{$, $$, Range} = require 'atom'

module.exports =
# Autocompletion for class names
class PhpClassProvider extends Provider
  # "new" keyword or word starting with capital letter
  wordRegex: /\b(^new \w*[a-zA-Z_]\w*)|(^[A-Z]([a-zA-Z])*)\b/g

  classes: []

  buildSuggestions: ->
    selection = @editor.getSelection()
    prefix = @prefixOfSelection selection
    return unless prefix.length

    @classes = internals.classes()

    suggestions = @findSuggestionsForPrefix prefix
    return unless suggestions.length
    return suggestions

  confirm: (suggestion) ->
    selection = @editor.getSelection()
    startPosition = selection.getBufferRange().start
    buffer = @editor.getBuffer()

    # if some args (even empty) => instanciation
    if suggestion.data?.args?
      snippetModule = atom.packages.getActivePackage('snippets').mainModule

      body = "("
      for arg, index in suggestion.data.args
        body += "," if body != "("
        body += "${" + (index+1) + ":" + arg + "}"
      body += ")$0"

      snippetName = suggestion.word + suggestion.label
      snippet =
        ".source.php":
          snippetName:
            prefix: suggestion.prefix
            body: suggestion.word + body
      snippetModule.add('current', snippet)

      # Emit the snippet
      snippetModule.expandSnippetsUnderCursors(@editor)
      snippetModule.deactivate()
      snippetModule.activate()

    # Static methods on classes
    else
      cursorPosition = @editor.getCursorBufferPosition()
      buffer.delete Range.fromPointWithDelta(cursorPosition, 0, -suggestion.prefix.length)
      @editor.insertText suggestion.word + "::"

    return false # Don't fall back to the default behavior

  findSuggestionsForPrefix: (prefix) ->
    # Get rid of the leading "new" keyword
    instanciation = false
    if prefix.indexOf("new ") != -1
      instanciation = true
      prefix = prefix.replace /^new /, ''

    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @classes.names, prefix

    # Builds suggestions for the words
    suggestions = []
    for word in words when word isnt prefix
      # Just print classes with constructors with "new"
      if instanciation and @classes.methods[word].constructor.has
        params = @classes.methods[word].constructor.args.join(',')
        suggestions.push new Suggestion this,
          word: word,
          prefix: prefix,
          label: "(#{params})",
          data:
            args: @classes.methods[word].constructor.args

      # Not instanciation => not printing constructor params
      else if not instanciation
        suggestions.push new Suggestion this, word: word, prefix: prefix

    return suggestions
