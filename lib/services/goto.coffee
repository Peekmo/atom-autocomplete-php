###*
 * Goto PHP Classes
###
fuzzaldrin = require 'fuzzaldrin'
parser = require './php-file-parser'
SubAtom = require 'sub-atom'
$ = require 'jquery'

module.exports =

    init: () ->
        @subAtom = new SubAtom
        @subAtom.add atom.workspace.observeTextEditors (editor) =>
            @registerEvents editor, editor.getGrammar()

    ###*
     * Goto the class the cursor is on
     * @param {TextEditor} editor
    ###
    gotoFromEditor: (editor) ->
        term = editor.getWordUnderCursor()

        console.log term
        @gotoFromWord(editor, term)

    gotoFromWord: (editor, term) ->
        proxy = require './php-proxy.coffee'

        if term.indexOf('$') == 0
            return

        if term.indexOf('\\') == 0
            term = term.substring(1)

        namespaceTerm = parser.findUseForClass(editor, term)
        if namespaceTerm != undefined
            term = namespaceTerm

        console.log term

        classMap = proxy.autoloadClassMap()
        classMapArray = [];

        for key,value of classMap
            classMapArray.push(key)

        matches = fuzzaldrin.filter classMapArray, term

        atom.workspace.open(classMap[matches[0]])

    registerEvents: (editor, grammar) ->
        if grammar.scopeName.match /text.html.php$/
            textEditorElement = atom.views.getView(editor)
            eventSelectors = '.function.argument > .support, .inherited-class, .namespace, .class.support'
            scrollViewElement = $($(textEditorElement)[0].shadowRoot).find('.scroll-view')

            @subAtom.add scrollViewElement, 'mousemove', eventSelectors, (event) =>
                if event.altKey == false
                    return
                selector = @getSelector(event)
                $(selector).css('text-decoration', 'underline')
                $(selector).css('cursor', 'pointer')
            @subAtom.add scrollViewElement, 'mouseout', eventSelectors, (event) =>
                selector = @getSelector(event)
                $(selector).css('text-decoration', '')
                $(selector).css('cursor', '')
            @subAtom.add scrollViewElement, 'click', eventSelectors, (event) =>
                if event.altKey == false
                    return
                if event.handled != true
                    @gotoFromWord(editor, $(@getSelector(event)).text())
                    event.handled = true
            @subAtom.add editor.onDidDestroy =>
                $(scrollViewElement).off('click', eventSelectors)
                $(scrollViewElement).off('mousehover', eventSelectors)
                $(scrollViewElement).off('mouseout', eventSelectors)


    getSelector: (event) ->
        selector = event.currentTarget
        if $(selector).parent().hasClass('function argument') ||
           $(selector).prev().hasClass('namespace') ||
           $(selector).next().hasClass('class')
            return $(selector).parent().children('.namespace, .class')

        return selector
