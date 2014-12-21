{Provider, Suggestion} = require "autocomplete-plus"

module.exports =
class PhpClassProvider extends Provider
  wordRegex: /@\b\w*[a-zA-Z_]\w*\b/g
  possibleWords: ["async", "attributes", "author", "beta", "borrows", "bubbles"]
  buildSuggestions: ->
    selection = @editor.getSelection()
    prefix = @prefixOfSelection selection
    return unless prefix.length

    suggestions = @findSuggestionsForPrefix prefix
    return unless suggestions.length
    return suggestions

  findSuggestionsForPrefix: (prefix) ->
    # Get rid of the leading @
    prefix = prefix.replace /^@/, ''

    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @possibleWords, prefix

    # Builds suggestions for the words
    suggestions = for word in words when word isnt prefix
      new Suggestion this, word: word, prefix: prefix, label: "@#{word}"

    return suggestions
