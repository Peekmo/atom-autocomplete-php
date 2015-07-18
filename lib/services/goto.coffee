###*
 * Goto PHP Classes
###
fuzzaldrin = require 'fuzzaldrin'
parser = require './php-file-parser'
SubAtom = require 'sub-atom'
GotoSelectView = require './goto-select-list-view.coffee'
{TextEditor} = require 'atom'
$ = require 'jquery'

module.exports =

    init: () ->
        @subAtom = new SubAtom
        self = this
        atom.workspace.observeTextEditors (editor) ->
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
            eventSelectors = '.inherited-class, .support.namespace, .support.class'
            scrollViewElement = $($(textEditorElement)[0].shadowRoot).find('.scroll-view')

            @subAtom.add scrollViewElement, 'mousemove', eventSelectors, (event) =>
                if event.altKey == false
                    return
                selector = @getSelector(event)
                if selector == null
                    return
                $(selector).css('text-decoration', 'underline')
                $(selector).css('cursor', 'pointer')
            @subAtom.add scrollViewElement, 'mouseout', eventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null
                    return
                $(selector).css('text-decoration', '')
                $(selector).css('cursor', '')
            @subAtom.add scrollViewElement, 'click', eventSelectors, (event) =>
                selector = @getSelector(event)
                if selector == null || event.altKey == false
                    return
                if event.handled != true
                    @gotoFromWord(editor, $(selector).text())
                    event.handled = true

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
