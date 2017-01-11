module.exports =

##*
# Progress bar in the status bar
##
class StatusErrorAutocomplete
  actions: []

  constructor: ->
    @span = document.createElement("span")
    @span.className = "inline-block text-subtle"
    @span.innerHTML = "Autocomplete failure"

    @container = document.createElement("div")
    @container.className = "inline-block"

    @subcontainer = document.createElement("div")
    @subcontainer.className = "block"
    @container.appendChild(@subcontainer)

    @subcontainer.appendChild(@span)

  initialize: (@statusBar) ->

  update: (text, show) ->
    if show
        @container.className = "inline-block"
        @span.innerHTML = text
        @actions.push(text)
    else
        @actions.forEach((value, index) ->
            if value == text
                @actions.splice(index, 1)
        , @)

        if @actions.length == 0
            @hide()
        else
            @span.innerHTML = @actions[0]

  hide: ->
    @container.className = 'hidden'

  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)

  detach: ->
    @tile.destroy()
