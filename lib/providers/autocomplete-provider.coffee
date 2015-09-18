fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'
exec = require "child_process"

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

module.exports =
# Other autocompletions (Everything is here !!)
# WORK IN PROGRESS
class AutocompleteProvider extends AbstractProvider
  methods: []
  functionOnly: true

  ###*
   * Get suggestions from the provider (@see provider-api)
   * @return array
  ###
  fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    # "new" keyword or word starting with capital letter
    @regex = /(?:[\$]?)(?![this])([a-zA-Z0-9_]+)(?:\([.]*\))?(?:->)?/g

    prefix = @getPrefix(editor, bufferPosition)

    elements = parser.getStackClasses(editor, bufferPosition)
    return unless elements?

    className = parser.parseElements(editor, bufferPosition, elements)
    return unless className?

    @methods = proxy.methods(className)
    return unless @methods.names?

    elements = prefix.split('->')
    suggestions = @findSuggestionsForPrefix(elements[elements.length-1].trim())
    return unless suggestions.length
    return suggestions

  ###*
   * Returns suggestions available matching the given prefix
   * @param {string} prefix Prefix to match
   * @return array
  ###
  findSuggestionsForPrefix: (prefix) ->
    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @methods.names, prefix

    # Builds suggestions for the words
    suggestions = []
    for word in words
      element = @methods.values[word]
      if element instanceof Array
        for ele in element
          suggestions = @addSuggestion(word, ele, suggestions)
      else
        suggestions = @addSuggestion(word, element, suggestions)

    return suggestions

  ###*
   * Adds the suggestion the the suggestions array.
   * @param {string} word        The word being currently typed.
   * @param {object} element     The object returns from proxy.methods.
   * @param {array} suggestions  An array of suggestions for the current word.
  ###
  addSuggestion: (word, element, suggestions) ->
    returnValues = if element.args.return then element.args.return.split('\\') else []

    # Methods
    if element.isMethod
      suggestions.push
        text: word,
        type: 'method',
        className: if element.args.deprecated then 'php-atom-autocomplete-strike' else ''
        snippet: @getFunctionSnippet(word, element.args),
        leftLabel: returnValues[returnValues.length - 1]
        description: if element.args.descriptions.short? then element.args.descriptions.short else ''

    # Constants and public properties
    else
      suggestions.push
        text: word,
        type: if element.isProperty then 'property' else 'constant'
        leftLabel: returnValues[returnValues.length - 1]
        description: if element.args.descriptions.short? then element.args.descriptions.short else ''
        className: if element.args.deprecated then 'php-atom-autocomplete-strike' else ''

    return suggestions
