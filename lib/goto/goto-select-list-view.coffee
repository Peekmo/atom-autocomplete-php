{SelectListView} = require 'atom-space-pen-views'

class GotoSelectListView extends SelectListView
 ###*
  * Initialises the SelectListView
 ###
 initialize: ->
   super
   @addClass('overlay from-top php-atom-autocomplete-goto-overlay')

 ###*
  * The html used for the select list view.
  * @param  {string} item The name of the item.
  * @param  {string} file The file related to the item given.
  * @return {string}      The completed HTML of a list item.
 ###
 viewForItem: ({item, file}) ->
   return "<li>#{item}<br><small>#{file}</small></li>"

 ###*
  * Called when a user has selected one of the options on the select view.
  * @param  {string} item Item name that was selected.
  * @param  {string} file File name that was selected.
 ###
 confirmed: ({item, file}) ->
   atom.workspace.open(file)
   @cancel()

 ###*
  * Hides the list view.
 ###
 cancelled: ->
   @panel.hide()

 ###*
  * Shows the list view.
 ###
 show: ->
   @panel ?= atom.workspace.addModalPanel(item: this)
   @panel.show()
   @keyBindings = atom.keymaps.findKeyBindings(target: atom.views.getView(atom.workspace))
   @focusFilterEditor()

 ###*
  * Gets the key that the filter should look at.
 ###
 getFilterKey: ->
   return "item"

module.exports = GotoSelectListView
