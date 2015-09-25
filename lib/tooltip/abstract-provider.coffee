{TextEditor} = require 'atom'
{CompositeDisposable} = require 'atom'

SubAtom = require 'sub-atom'

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
        @subscriptions = new CompositeDisposable

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
        @subAtom.dispose()

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
                selector = @getSelectorFromEvent(event)

                if selector == null
                    return

                # Try to show a tooltip containing the documentation of the item.
                cursorPosition = atom.views.getView(editor).component.screenPositionForMouseEvent(event)

                tooltipText = @getTooltipForWord(editor, @$(selector).text(), cursorPosition)

                if tooltipText?.length > 0
                    @subscriptions.add atom.tooltips.add(event.target, {
                        title: '<div style="text-align: left;">' + tooltipText.replace(/\n/g, '<br/>') + '</div>'
                        html: true
                        placement: 'bottom'
                        delay:
                            show: 500
                    })

            @subAtom.add scrollViewElement, 'mouseout', @hoverEventSelectors, (event) =>
                @subscriptions.dispose();

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
