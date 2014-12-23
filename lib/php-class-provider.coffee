{Provider, Suggestion} = require "autocomplete-plus"
fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'
sys = require "sys"
exec = require "child_process"

module.exports =
# Autocompletion for class names
class PhpClassProvider extends Provider
  # "new" keyword or word starting with capital letter
  wordRegex: /\b(^new \w*[a-zA-Z_]\w*)|(^[A-Z]([a-zA-Z])*)\b/g

  possibleWords: ["async", "attributes", "author", "beta", "borrows", "bubbles", "Master"]

  buildSuggestions: ->
    selection = @editor.getSelection()
    prefix = @prefixOfSelection selection
    return unless prefix.length

    words = @generateClasses()

    suggestions = @findSuggestionsForPrefix prefix
    return unless suggestions.length
    return suggestions

  findSuggestionsForPrefix: (prefix) ->
    # Get rid of the leading "new" keyword
    prefix = prefix.replace /^new /, ''

    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @possibleWords, prefix

    # Builds suggestions for the words
    suggestions = for word in words when word isnt prefix
      new Suggestion this, word: word, prefix: prefix, label: "@#{word}"

    return suggestions

  getClasses: (error, stdout, stderr) =>
    console.log error
    console.log stderr
    console.log stdout

  generateClasses: ->
    console.log 'ok';
    exec.exec("ls", @getClasses)
