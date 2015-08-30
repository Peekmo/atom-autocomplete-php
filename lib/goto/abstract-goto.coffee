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
    gotoRegex: ''
    jumpLine: null
    jumpWord: ''

    ###*
     * Initialisation of Gotos
     * @param  {GotoManager} manager The manager that stores this goto.
     *                               Used mainly for backtrack registering.
    ###
    init: (manager) ->
        @subAtom = new SubAtom
        @$ = require 'jquery'
        @parser = require '../services/php-file-parser'
        @fuzzaldrin = require 'fuzzaldrin'
        {CompositeDisposable} = require 'atom'
        @subscriptions = new CompositeDisposable
        @manager = manager
        atom.workspace.observeTextEditors (editor) =>
            @registerMarkers editor
            @registerEvents editor

        atom.workspace.onDidChangeActivePaneItem (paneItem) =>
            if paneItem instanceof TextEditor && @jumpWord != '' && @jumpWord != undefined
                @jumpTo(paneItem, @jumpWord, @jumpLine)
                @jumpLine = null
                @jumpWord = ''

        # When you go back to only have 1 pane the events are lost, so need
        # to re-register.
        atom.workspace.onDidDestroyPane (pane) =>
            panes = atom.workspace.getPanes()
            if panes.length == 1
                for paneItem in panes[0].items
                    if paneItem instanceof TextEditor
                        @registerEvents paneItem

        # Having to re-register events as when a new pane is created the
        # old panes lose the events.
        atom.workspace.onDidAddPane (observedPane) =>
            panes = atom.workspace.getPanes()
            for pane in panes
                if pane == observedPane
                    continue
                for paneItem in pane.items
                    if paneItem instanceof TextEditor
                        @registerEvents paneItem

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
        if editor.getGrammar().scopeName.match /text.html.php$/
            position = editor.getCursorBufferPosition()
            term = @parser.getFullWordFromBufferPosition(editor, position)
            @gotoFromWord(editor, term)

    ###*
     * Goto from the term given.
     * @param  {TextEditor} editor  TextEditor to search for namespace of term.
     * @param  {string}     term    Term to search for.
    ###
    gotoFromWord: (editor, term) ->


    ###*
     * Retrieves a tooltip for the word given.
     * @param  {TextEditor} editor         TextEditor to search for namespace of term.
     * @param  {string}     term           Term to search for.
     * @param  {Point}      bufferPosition The cursor location the term is at.
    ###
    getTooltipForWord: (editor, term, bufferPosition) ->


    ###*
     * Registers the mouse events for alt-click.
     * @param  {TextEditor} editor  TextEditor to register events to.
    ###
    registerEvents: (editor) ->
        if editor.getGrammar().scopeName.match /text.html.php$/
            textEditorElement = atom.views.getView(editor)
            scrollViewElement = @$(textEditorElement.shadowRoot).find('.scroll-view')

            @subAtom.add scrollViewElement, 'mousemove', @hoverEventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null
                    return

                # Try to show a tooltip containing the documentation of the item.
                if not @showingDocumentationTooltip
                    cursorPosition = atom.views.getView(editor).component.screenPositionForMouseEvent(event)

                    tooltipText = @getTooltipForWord(editor, @$(selector).text(), cursorPosition)

                    @subscriptions.add atom.tooltips.add(event.target, {
                        title: tooltipText
                        html: true
                        placement: 'bottom'
                        delay:
                            show: 500
                    })

                    @showingDocumentationTooltip = true

                if event.altKey == false
                    return

                @$(selector).css('border-bottom', '1px solid ' + @$(selector).css('color'))
                @$(selector).css('cursor', 'pointer')
                @isHovering = true
            @subAtom.add scrollViewElement, 'mouseout', @hoverEventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null
                    return

                @subscriptions.dispose();
                @showingDocumentationTooltip = false

                @$(selector).css('border-bottom', '')
                @$(selector).css('cursor', '')
                @isHovering = false
            @subAtom.add scrollViewElement, 'click', @clickEventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null || event.altKey == false
                    return
                if event.handled != true
                    @gotoFromWord(editor, @$(selector).text())
                    event.handled = true
            editor.onDidChangeCursorPosition (event) =>
                # return # Temporary

                if @isHovering == false
                    return
                markerProperties =
                    containsBufferPosition: event.newBufferPosition
                markers = event.cursor.editor.findMarkers markerProperties
                for key,marker of markers
                    for allKey,allMarker of @allMarkers[editor.getLongTitle()]
                        if marker.id == allMarker.id
                            @gotoFromWord(event.cursor.editor, marker.getProperties().term)
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

    ###*
     * Returns whether this goto is able to jump using the term.
     * @param  {string} term Term to check.
     * @return {boolean}     Whether a jump is possible.
    ###
    canGoto: (term) ->
        return term.match(@gotoRegex)?.length > 0

    ###*
     * Gets the regex used when looking for a word within the editor
     * @param  {string} term Term being search.
     * @return {regex}       Regex to be used.
    ###
    getJumpToRegex: (term) ->

    ###*
     * Jumps to a word within the editor
     * @param  {TextEditor} editor The editor that has the function in.
     * @param  {string} word       The word to find and then jump to.
     * @return {boolean}           Whether the finding was successful.
    ###
    jumpTo: (editor, word, line) ->
        bufferPosition = @parser.findBufferPositionOfWord(editor, word, @getJumpToRegex(word), line)
        if bufferPosition == null
            return false

        # Small delay to wait for when a editor is being created.
        setTimeout(() ->
            editor.setCursorBufferPosition(bufferPosition, {
                autoscroll: false
            })
            # Separated these as the autoscroll on setCursorBufferPosition
            # didn't work as well.
            editor.scrollToScreenPosition(editor.screenPositionForBufferPosition(bufferPosition), {
                center: true
            })
        , 100)
