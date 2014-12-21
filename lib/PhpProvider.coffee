{Provider, Suggestion} = require "autocomplete-plus"

class PhpProvider extends Provider
  wordRegex: /@\b\w*[a-zA-Z_]\w*\b/g
  buildSuggestions: ->
    selection = @editor.getSelection()
    prefix = @prefixOfSelection selection
    return unless prefix.length

    suggestions = []
    suggestions.push new Suggestion(this, word: "async", label: "@async")
    suggestions.push new Suggestion(this, word: "attributes", label: "@attribute")
    suggestions.push new Suggestion(this, word: "author", label: "@author")
    suggestions.push new Suggestion(this, word: "beta", label: "@beta")
    suggestions.push new Suggestion(this, word: "borrows", label: "@borrows")
    suggestions.push new Suggestion(this, word: "bubbles", label: "@bubbles")
    return suggestions
