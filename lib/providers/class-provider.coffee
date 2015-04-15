fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'
exec = require "child_process"

internals = require "../services/php-internals.coffee"
AbstractProvider = require "./abstract-provider"
{$, $$, Range} = require 'atom'

module.exports =
# Autocompletion for class names
class ClassProvider extends AbstractProvider
  classes = []

  ###*
   * Get suggestions from the provider (@see provider-api)
   * @return array
  ###
  fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    # "new" keyword or word starting with capital letter
    @regex = /((?:new )?\\?(?:[A-Z][a-zA-Z_\\]*)+)/g

    selection = editor.getSelection()
    prefix = @getPrefix(editor, bufferPosition)
    return unless prefix.length

    @classes = internals.classes()

    suggestions = @findSuggestionsForPrefix prefix
    return unless suggestions.length
    return suggestions

  ###*
   * Returns suggestions available matching the given prefix
   * @param {string} prefix Prefix to match
   * @return array
  ###
  findSuggestionsForPrefix: (prefix) ->
    # Get rid of the leading "new" keyword
    instanciation = false
    if prefix.indexOf("new \\") != -1
      instanciation = true
      prefix = prefix.replace /^new \\/, ''
    else if prefix.indexOf("new ") != -1
      instanciation = true
      prefix = prefix.replace /^new /, ''

    if prefix.indexOf("\\") == 0
      prefix = prefix.substring(1, prefix.length)

    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @classes.names, prefix

    # Builds suggestions for the words
    suggestions = []
    for word in words when word isnt prefix
      # Just print classes with constructors with "new"
      if instanciation and @classes.methods[word].constructor.has
        suggestions.push
          text: word,
          snippet: @getFunctionSnippet(word, @classes.methods[word].constructor.args),
          data:
            kind: 'instanciation',
            prefix: prefix

      # Not instanciation => not printing constructor params
      else if not instanciation
        suggestions.push
          text: word,
          data:
            kind: 'static',
            prefix: prefix

    return suggestions
