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
        suggestions.push new Suggestion this, word: word, prefix: prefix, label: "(#{params})"

      # Not instanciation => not printing constructor params
      else if not instanciation
        suggestions.push new Suggestion this, word: word, prefix: prefix

    return suggestions
