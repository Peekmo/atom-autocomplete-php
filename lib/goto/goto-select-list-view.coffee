{SelectListView} = require 'atom-space-pen-views'

class GotoSelectListView extends SelectListView
 initialize: ->
   super
   @addClass('overlay from-top php-atom-autocomplete-goto-overlay')

 viewForItem: ({item, file}) ->
   return "<li>#{item}<br><small>#{file}</small></li>"

 confirmed: ({item, file}) ->
   atom.workspace.open(file)
   @cancel()

 cancelled: ->
   @panel.hide()

 show: ->
   @panel ?= atom.workspace.addModalPanel(item: this)
   @panel.show()
   @keyBindings = atom.keymaps.findKeyBindings(target: atom.views.getView(atom.workspace))
   @focusFilterEditor()

 getFilterKey: ->
   return "item"

module.exports = GotoSelectListView
