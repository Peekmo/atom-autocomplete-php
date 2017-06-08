{$$, SelectListView} = require 'atom-space-pen-views'

module.exports =

class ClassListView extends SelectListView
    initialize: (@suggestions, @onConfirm) ->
        super
        @show()
        @setItems @suggestions.map((suggestion) ->
            return {name: suggestion.text}
        )
        @focusFilterEditor()
        @currentPane = atom.workspace.getActivePane()

    getFilterKey: -> 'name'

    show: ->
        @panel ?= atom.workspace.addModalPanel(item: this)
        @panel.show()
        @storeFocusedElement()

    cancelled: -> @hide()

    hide: -> @panel?.destroy()

    viewForItem: ({name}) ->
        $$ ->
            @li name

    confirmed: (item) ->
        @onConfirm(item)
        @cancel()
        @currentPane.activate() if @currentPane?.isAlive()
