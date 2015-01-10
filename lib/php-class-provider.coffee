{Provider, Suggestion} = require "autocomplete-plus"
fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'
exec = require "child_process"

internals = require "./php-internals.coffee"

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

  findSuggestionsForPrefix: (prefix) ->
    # Get rid of the leading "new" keyword
    prefix = prefix.replace /^new /, ''

    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @classes, prefix

    # Builds suggestions for the words
    suggestions = for word in words when word isnt prefix
      new Suggestion this, word: word, prefix: prefix, label: "@#{word}"

    return suggestions
