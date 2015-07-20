###*
 * Goto PHP Classes
###
fuzzaldrin = require 'fuzzaldrin'
parser = require './php-file-parser'
SubAtom = require 'sub-atom'
GotoSelectView = require './goto-select-list-view.coffee'
{TextEditor} = require 'atom'
$ = require 'jquery'
allMarkers = []

module.exports =

    init: () ->
        @subAtom = new SubAtom
        self = this
        atom.workspace.observeTextEditors (editor) ->
            self.parseComments editor
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
        for key,marker of allMarkers
            marker.destroy()

    ###*
     * Goto the class the cursor is on
     * @param TextEditor editor TextEditor to pull term from.
    ###
    gotoFromEditor: (editor) ->
        if editor.getGrammar().scopeName.match /text.html.php$/
            position = editor.getCursorBufferPosition()
            term = parser.getClassFromBufferPosition(editor, position)
            @gotoFromWord(editor, term)

    ###*
     * Goto the class from the term given.
     * @param  {TextEditor} editor  TextEditor to search for namespace of term.
     * @param  {string}     term    Term to search for.
    ###
    gotoFromWord: (editor, term) ->
        proxy = require './php-proxy.coffee'

        if term.indexOf('$') == 0
            return

        if term.indexOf('\\') == 0
            term = term.substring(1)

        namespaceTerm = parser.findUseForClass(editor, term)
        if namespaceTerm != undefined
            term = namespaceTerm

        classMap = proxy.autoloadClassMap()
        classMapArray = [];
        listViewArray = [];

        for key,value of classMap
            classMapArray.push(key)

        matches = fuzzaldrin.filter classMapArray, term

        if matches[0] == term || matches.length == 1
            atom.workspace.open(classMap[matches[0]])
        else
            for key,value of matches
                listViewArray.push({
                    item: value,
                    file: classMap[value]
                })

            @selectView.setItems(listViewArray)
            @selectView.show()

    ###*
     * Registers the mouse events for alt-click.
     * @param  {TextEditor} editor  TextEditor to register events to.
    ###
    registerEvents: (editor) ->
        if editor.getGrammar().scopeName.match /text.html.php$/
            textEditorElement = atom.views.getView(editor)
            hoverEventSelectors = '.entity.inherited-class, .support.namespace, .support.class, .comment-clickable .region'
            clickEventSelectors = '.entity.inherited-class, .support.namespace, .support.class'
            scrollViewElement = $(textEditorElement.shadowRoot).find('.scroll-view')

            self = @
            @subAtom.add scrollViewElement, 'mousemove', hoverEventSelectors, (event) =>
                if event.altKey == false
                    return
                selector = @getSelector(event)
                if selector == null
                    return
                $(selector).css('border-bottom', '1px solid ' + $(selector).css('color'))
                $(selector).css('cursor', 'pointer')
                self.isHovering = true
            @subAtom.add scrollViewElement, 'mouseout', hoverEventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null
                    return
                $(selector).css('border-bottom', '')
                $(selector).css('cursor', '')
                self.isHovering = false
            @subAtom.add scrollViewElement, 'click', clickEventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null || event.altKey == false
                    return
                if event.handled != true
                    @gotoFromWord(editor, $(selector).text())
                    event.handled = true
            editor.onDidChangeCursorPosition (event) ->
                if self.isHovering == false
                    return
                markerProperties =
                    containsBufferPosition: event.newBufferPosition
                markers = event.cursor.editor.findMarkers markerProperties
                for key,marker of markers
                    for allKey,allMarker of allMarkers
                        if marker.id == allMarker.id
                            self.gotoFromWord(event.cursor.editor, marker.getProperties().class)
                            break

    ###*
     * Gets the correct selector when a class or namespace is clicked.
     * @param  {jQuery.Event}  event  A jQuery event.
     * @return {object|null}          A selector to be used with jQuery.
    ###
    getSelector: (event) ->
        selector = event.currentTarget

        if $(selector).hasClass('builtin') || $(selector).children('.builtin').length > 0
            return null

        if $(selector).parent().hasClass('function argument') ||
           $(selector).prev().hasClass('namespace') && $(selector).hasClass('class') ||
           $(selector).next().hasClass('class')
            return $(selector).parent().children('.namespace, .class:not(.operator):not(.constant)')

        return selector

    ###*
     * Goes through all the lines within the editor looking for classes within
     * comments. More specifically if they have @var, @param or @return prefixed.
     * @param  {TextEditor} editor The editor to search through
    ###
    parseComments: (editor) ->
        text = editor.getText()
        rows = text.split('\n')
        for key,row of rows
            regex = /@param|@var|@return|@throws|@see/gi
            if regex.test(row)
                @addMarkerToCommentLine row.split(' '), parseInt(key), editor, true

    ###*
     * Analyses the words array given for any classes and then creates a marker
     * for them.
     * @param {array} words             The array of words to check.
     * @param {int} rowIndex            The current row the words are on within the editor.
     * @param {TextEditor} editor       The editor the words are from.
     * @param {bool} shouldBreak        Flag to say whether the search should break after finding 1 class.
     * @param {int} currentIndex = 0    The current column index the search is on.
     * @param {int} offset       = 0    Any offset that should be applied when creating the marker.
    ###
    addMarkerToCommentLine: (words, rowIndex, editor, shouldBreak, currentIndex = 0, offset = 0) ->
        for key,value of words
            regex = /^\\?([A-Za-z0-9_]+)\\?([A-Za-zA-Z_\\]*)?/g
            keywordRegex = /^(array|object|bool|string|static|null|boolean|void|int|integer|mixed|callable)$/gi
            if regex.test(value) && keywordRegex.test(value) == false
                if value.includes('|')
                    @addMarkerToCommentLine value.split('|'), rowIndex, editor, false, currentIndex, parseInt(key)
                else
                    range = [[rowIndex, currentIndex + parseInt(key) + offset], [rowIndex, currentIndex + parseInt(key) + value.length + offset]];
                    marker = editor.markBufferRange(range)
                    markerProperties =
                        class: value
                    marker.setProperties markerProperties
                    options =
                        type: 'highlight'
                        class: 'comment-clickable comment'

                    editor.decorateMarker marker, options
                    allMarkers.push(marker)
                if shouldBreak == true
                    break
            currentIndex += value.length;
