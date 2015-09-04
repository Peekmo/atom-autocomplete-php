fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

module.exports =
# Autocomplete for internal PHP functions
class FunctionProvider extends AbstractProvider
  functions: []
  functionOnly: true

  ###*
   * Get suggestions from the provider (@see provider-api)
   * @return array
  ###
  fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    # "new" keyword or word starting with capital letter
    @regex = /(?:[^\w\$_\>])([a-z_]+)(?![\w\$_\>])/g

    prefix = @getPrefix(editor, bufferPosition)
    return unless prefix.length

    @functions = proxy.functions()
    return unless @functions.names?

    suggestions = @findSuggestionsForPrefix(prefix.trim())
    return unless suggestions.length
    return suggestions

  ###*
   * Returns suggestions available matching the given prefix
   * @param {string} prefix Prefix to match
   * @return array
  ###
  findSuggestionsForPrefix: (prefix) ->
    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @functions.names, prefix

    # Builds suggestions for the words
    suggestions = []
    for word in words
      for element in @functions.values[word]
        suggestions.push
          text: word,
          type: 'function',
          className: if element.args.deprecated then 'php-atom-autocomplete-strike' else ''
          snippet: @getFunctionSnippet(word, element.args),
          replacementPrefix: prefix

    return suggestions
