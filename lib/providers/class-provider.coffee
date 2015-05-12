fuzzaldrin = require 'fuzzaldrin'
minimatch = require 'minimatch'
exec = require "child_process"

proxy = require "../services/php-proxy.coffee"
parser = require "../services/php-file-parser.coffee"
AbstractProvider = require "./abstract-provider"

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
    @regex = /(?:[^\$\>\w])((?:new )?\\?(?:[A-Z][a-zA-Z_\\]*)+)/g

    prefix = @getPrefix(editor, bufferPosition)
    return unless prefix.length

    @classes = proxy.classes()
    return unless @classes.autocomplete?

    suggestions = @findSuggestionsForPrefix prefix.trim()
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
      prefix = prefix.replace /new \\/, ''
    else if prefix.indexOf("new ") != -1
      instanciation = true
      prefix = prefix.replace /new /, ''

    if prefix.indexOf("\\") == 0
      prefix = prefix.substring(1, prefix.length)

    # Filter the words using fuzzaldrin
    words = fuzzaldrin.filter @classes.autocomplete, prefix

    # Builds suggestions for the words
    suggestions = []
    for word in words when word isnt prefix
      # Just print classes with constructors with "new"
      if instanciation and @classes.mapping[word].methods.constructor.has
        suggestions.push
          text: word,
          type: 'class',
          snippet: @getFunctionSnippet(word, @classes.mapping[word].methods.constructor.args),
          data:
            kind: 'instanciation',
            prefix: prefix,
            replacementPrefix: prefix

      # Not instanciation => not printing constructor params
      else if not instanciation
        suggestions.push
          text: word,
          type: 'class',
          data:
            kind: 'static',
            prefix: prefix,
            replacementPrefix: prefix

    return suggestions

  ###*
   * Adds the missing use if needed
   * @param {TextEditor} editor
   * @param {Position}   triggerPosition
   * @param {object}     suggestion
  ###
  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
    if suggestion.data.kind == 'instanciation'
      added = parser.addUseClass(editor, suggestion.text)

      # Removes namespace from classname
      if added?
        name = suggestion.text
        splits = name.split('\\')

        nameLength = splits[splits.length-1].length
        wordStart = triggerPosition.column - suggestion.data.prefix.length
        lineStart = if added == "added" then triggerPosition.row + 1 else triggerPosition.row

        editor.setTextInBufferRange([
            [lineStart, wordStart],
            [lineStart, wordStart + name.length - nameLength - splits.length + 1] # Because when selected there's not \ (why?)
        ], "")
