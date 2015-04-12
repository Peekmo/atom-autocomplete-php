fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'

internals = require "../services/php-internals.coffee"
AbstractProvider = require "./abstract-provider.coffee"
{$, $$, Range} = require 'atom'

module.exports =
# Autocompletion for class names
class StaticProvider extends AbstractProvider
  statics: []

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    @regex = /(\b[A-Z][a-zA-Z_]+::([a-zA-Z_]*))/g

    selection = editor.getSelection()
    prefix = @getPrefix(editor, bufferPosition)
    return unless prefix.length

    parts = prefix.split("::")
    @statics = internals.statics(parts[0])

    suggestions = @findSuggestionsForPrefix parts[1]
    return unless suggestions.length
    return suggestions

  findSuggestionsForPrefix: (prefix) ->
    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @statics.names, prefix

    # Builds suggestions for the words
    suggestions = []
    for word in words
      for element in @statics.values[word]
        if element.isPublic
          # Methods
          if element.isMethod
            suggestions.push
              text: word,
              snippet: @getFunctionSnippet(word, element.args),
              data:
                prefix: prefix,
                args: element.args

          # Constants and public properties
          else
            suggestions.push
              text: word,
              data:
                prefix: prefix

    return suggestions
