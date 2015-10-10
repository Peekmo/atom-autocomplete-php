{TextEditor} = require 'atom'

SubAtom = require 'sub-atom'
Popover = require '../services/popover'

module.exports =

class AbstractProvider
    hoverEventSelectors: ''

    ###*
     * Initializes this provider.
    ###
    init: () ->
        @$ = require 'jquery'
        @parser = require '../services/php-file-parser'

        @subAtom = new SubAtom

        atom.workspace.observeTextEditors (editor) =>
            @registerEvents editor

        # When you go back to only have one pane the events are lost, so need to re-register.
        atom.workspace.onDidDestroyPane (pane) =>
            panes = atom.workspace.getPanes()

            if panes.length == 1
                for paneItem in panes[0].items
                    if paneItem instanceof TextEditor
                        @registerEvents paneItem

        # Having to re-register events as when a new pane is created the old panes lose the events.
        atom.workspace.onDidAddPane (observedPane) =>
            panes = atom.workspace.getPanes()

            for pane in panes
                if pane == observedPane
                    continue

                for paneItem in pane.items
                    if paneItem instanceof TextEditor
                        @registerEvents paneItem

    ###*
     * Deactives the goto feature.
    ###
    deactivate: () ->
        document.removeChild(@popover)
        @subAtom.dispose()
        @hideTooltip()

    ###*
     * Registers the necessary event handlers.
     *
     * @param {TextEditor} editor TextEditor to register events to.
    ###
    registerEvents: (editor) ->
        if editor.getGrammar().scopeName.match /text.html.php$/
            textEditorElement = atom.views.getView(editor)
            scrollViewElement = @$(textEditorElement.shadowRoot).find('.scroll-view')

            @subAtom.add scrollViewElement, 'mouseover', @hoverEventSelectors, (event) =>
                if @timeout
                    clearTimeout(@timeout)

                selector = @getSelectorFromEvent(event)

                if selector == null
                    return

                # Try to show a tooltip containing the documentation of the item.
                @timeout = setTimeout(() =>
                    editorViewComponent = atom.views.getView(editor).component

                    # Ticket #140 - In rare cases the component is null.
                    if editorViewComponent
                        cursorPosition = editorViewComponent.screenPositionForMouseEvent(event)

                        @showTooltipFor(editor, selector, cursorPosition)
                , 500)

            @subAtom.add scrollViewElement, 'mouseout', @hoverEventSelectors, (event) =>
                clearTimeout(@timeout)

                @hideTooltip()

    ###*
     * Shows a tooltip containing the documentation of the specified element located at the specified location.
     *
     * @param {TextEditor} editor         TextEditor containing the elemment.
     * @param {string}     element        The element to search for.
     * @param {Point}      bufferPosition The cursor location the element is at.
     * @param {int}        fadeInTime     The amount of time to take to fade in the tooltip.
    ###
    showTooltipFor: (editor, element, bufferPosition, fadeInTime = 100) ->
        term = @$(element).text()
        tooltipText = @getTooltipForWord(editor, term, bufferPosition)

        if tooltipText?.length > 0
            @popover = new Popover(element)
            @popover.show(tooltipText, fadeInTime)

    ###*
     * Hides the tooltip, if it is displayed.
    ###
    hideTooltip: () ->
        if @popover
            @popover.dispose()
            @popover = null

    ###*
     * Retrieves a tooltip for the word given.
     *
     * @param {TextEditor} editor         TextEditor to search for namespace of term.
     * @param {string}     term           Term to search for.
     * @param {Point}      bufferPosition The cursor location the term is at.
    ###
    getTooltipForWord: (editor, term, bufferPosition) ->

    ###*
     * Gets the correct selector when a selector is clicked.
     * @param  {jQuery.Event}  event  A jQuery event.
     * @return {object|null}          A selector to be used with jQuery.
    ###
    getSelectorFromEvent: (event) ->
        return event.currentTarget
