{Provider, Suggestion} = require "autocomplete-plus"
fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'

internals = require "./php-internals.coffee"
PhpAbstractProvider = require "./php-abstract-provider.coffee"
{$, $$, Range} = require 'atom'

module.exports =
# Autocompletion for class names
class PhpStaticsProvider extends PhpAbstractProvider
  # "self" keyword will be handled later
  # wordRegex: /\b((self::[a-zA-Z_]*$)|([A-Z][a-zA-Z_]*::[a-zA-Z_]*$))\b/g
  wordRegex: /\b([A-Z][a-zA-Z_]*::[a-zA-Z_]*)\b/g

  statics: []

  buildSuggestions: ->
    selection = @editor.getSelection()
    prefix = @prefixOfSelection selection
    return unless prefix.length

    # ClassName::method
    parts = prefix.split("::")
    @statics = internals.statics(parts[0])

    suggestions = @findSuggestionsForPrefix parts[1]
    return unless suggestions.length
    return suggestions

  confirm: (suggestion) ->
    selection = @editor.getSelection()
    startPosition = selection.getBufferRange().start
    buffer = @editor.getBuffer()

    # if some args => methods
    if suggestion.data?.args?
      @showSnippet(suggestion)

    # Static properties or constants
    else
      cursorPosition = @editor.getCursorBufferPosition()
      buffer.delete Range.fromPointWithDelta(cursorPosition, 0, -suggestion.prefix.length)
      @editor.insertText suggestion.word

    return false # Don't fall back to the default behavior

  findSuggestionsForPrefix: (prefix) ->
    # Filter the words using fuzzaldrin
    if prefix != ""
      words = fuzzaldrin.filter @statics.names, prefix
    else
      words = @statics.names

    # Builds suggestions for the words
    suggestions = []
    for word in words
      for element in @statics.values[word]
        if element.isPublic
          # Methods
          if element.isMethod
            params = element.args.join(',')
            suggestions.push new Suggestion this,
              word: word,
              prefix: prefix,
              label: "(#{params})",
              data:
                args: element.args

          # Constants and public properties
          else
            suggestions.push new Suggestion this, word: word, prefix: prefix

    return suggestions
