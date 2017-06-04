###*
 * PHP import use statement
###

module.exports =

    ###*
     * Import use statement for class under cursor
     * @param {TextEditor} editor
    ###
    importUseStatement: (editor) ->
        ClassProvider = require '../autocompletion/class-provider.coffee'
        provider = new ClassProvider()
        word = editor.getWordUnderCursor()
        regex = new RegExp('\\\\' + word + '$');

        suggestions = provider.fetchSuggestionsFromWord(word)
        return unless suggestions

        suggestions = suggestions.filter((suggestion) ->
            return suggestion.text == word || regex.test(suggestion.text)
        )

        return unless suggestions.length

        if suggestions.length < 2
            return provider.onSelectedClassSuggestion {editor, suggestion: suggestions.shift()}

        ClassListView = require '../views/class-list-view'

        return new ClassListView(suggestions, ({name}) ->
            suggestion = suggestions.filter((suggestion) ->
                return suggestion.text == name
            ).shift()
            provider.onSelectedClassSuggestion {editor, suggestion}
        )
