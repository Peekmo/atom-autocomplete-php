###*
 * Goto PHP Classes
###
SubAtom = require 'sub-atom'
GotoSelectView = require './goto-select-list-view.coffee'
{TextEditor} = require 'atom'

module.exports =

class AbstractGoto
    allMarkers: []
    hoverEventSelectors: ''
    clickEventSelectors: ''
    manager: {}

    init: (manager) ->
        @subAtom = new SubAtom
        @$ = require 'jquery'
        @parser = require '../services/php-file-parser'
        @fuzzaldrin = require 'fuzzaldrin'
        @manager = manager
        self = this
        atom.workspace.observeTextEditors (editor) ->
            self.registerMarkers editor
            self.registerEvents editor

        # When you go back to only have 1 pane the events are lost, so need
        # to re-register.
        atom.workspace.onDidDestroyPane (pane) ->
            panes = atom.workspace.getPanes()
            if panes.length == 1
                for paneItem in panes[0].items
                    if paneItem instanceof TextEditor
                        self.registerEvents paneItem

        # Having to re-register events as when a new pane is created the
        # old panes lose the events.
        atom.workspace.onDidAddPane (observedPane) ->
            panes = atom.workspace.getPanes()
            for pane in panes
                if pane == observedPane
                    continue
                for paneItem in pane.items
                    if paneItem instanceof TextEditor
                        self.registerEvents paneItem

        @selectView = new GotoSelectView

    ###*
     * Deactives the goto feature.
    ###
    deactivate: () ->
        @subAtom.dispose()
        allMarkers = []

    ###*
     * Goto from the current cursor position in the editor.
     * @param TextEditor editor TextEditor to pull term from.
    ###
    gotoFromEditor: (editor) ->

    ###*
     * Goto from the term given.
     * @param  {TextEditor} editor  TextEditor to search for namespace of term.
     * @param  {string}     term    Term to search for.
    ###
    gotoFromWord: (editor, term) ->


    ###*
     * Registers the mouse events for alt-click.
     * @param  {TextEditor} editor  TextEditor to register events to.
    ###
    registerEvents: (editor) ->
        if editor.getGrammar().scopeName.match /text.html.php$/
            textEditorElement = atom.views.getView(editor)
            scrollViewElement = @$(textEditorElement.shadowRoot).find('.scroll-view')

            self = @
            @subAtom.add scrollViewElement, 'mousemove', self.hoverEventSelectors, (event) =>
                if event.altKey == false
                    return
                selector = @getSelector(event)
                if selector == null
                    return
                self.$(selector).css('border-bottom', '1px solid ' + self.$(selector).css('color'))
                self.$(selector).css('cursor', 'pointer')
                self.isHovering = true
            @subAtom.add scrollViewElement, 'mouseout', self.hoverEventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null
                    return
                self.$(selector).css('border-bottom', '')
                self.$(selector).css('cursor', '')
                self.isHovering = false
            @subAtom.add scrollViewElement, 'click', self.clickEventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null || event.altKey == false
                    return
                if event.handled != true
                    @gotoFromWord(editor, self.$(selector).text())
                    event.handled = true
            editor.onDidChangeCursorPosition (event) ->
                if self.isHovering == false
                    return
                markerProperties =
                    containsBufferPosition: event.newBufferPosition
                markers = event.cursor.editor.findMarkers markerProperties
                for key,marker of markers
                    for allKey,allMarker of self.allMarkers[editor.getLongTitle()]
                        if marker.id == allMarker.id
                            self.gotoFromWord(event.cursor.editor, marker.getProperties().term)
                            break

    ###*
     * Register any markers that you need.
     * @param  {TextEditor} editor The editor to search through
    ###
    registerMarkers: (editor) ->

    ###*
     * Gets the correct selector when a selector is clicked.
     * @param  {jQuery.Event}  event  A jQuery event.
     * @return {object|null}          A selector to be used with jQuery.
    ###
    getSelector: (event) ->
        return event.currentTarget
