PeekmoPhpAtomAutocompleteView = require './peekmo-php-atom-autocomplete-view'

module.exports =
  peekmoPhpAtomAutocompleteView: null

  activate: (state) ->
    @peekmoPhpAtomAutocompleteView = new PeekmoPhpAtomAutocompleteView(state.peekmoPhpAtomAutocompleteViewState)

  deactivate: ->
    @peekmoPhpAtomAutocompleteView.destroy()

  serialize: ->
    peekmoPhpAtomAutocompleteViewState: @peekmoPhpAtomAutocompleteView.serialize()
