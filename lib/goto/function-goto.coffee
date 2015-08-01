AbstractGoto = require './abstract-goto'
{TextEditor} = require 'atom'

module.exports =
class GotoFunction extends AbstractGoto

    hoverEventSelectors: '.function-call'
    clickEventSelectors: '.function-call'

    init: () ->
        super
        @jumpToFunctionOnLoad = ''
        self = @
        atom.workspace.onDidChangeActivePaneItem (paneItem) ->
            if paneItem instanceof TextEditor && self.jumpToFunctionOnLoad != ''
                self.jumpToFunction(paneItem, self.jumpToFunctionOnLoad)
                self.jumpToFunctionOnLoad = ''

    ###*
     * Goto the class from the term given.
     * @param  {TextEditor} editor  TextEditor to search for namespace of term.
     * @param  {string}     term    Term to search for.
    ###
    gotoFromWord: (editor, term) ->
        proxy = require '../services/php-proxy.coffee'
        bufferPosition = editor.getCursorBufferPosition()
        fullCall = @parser.getFullWordFromBufferPosition(editor, bufferPosition)
        calledClass = ''

        if fullCall.indexOf('->') != -1
            calledClass = @parser.parseElements(editor, bufferPosition, fullCall.split('->'))
        else
            parts = fullCall.split('::')
            if parts[0] == 'parent'
                calledClass = @parser.getParentClass(editor)
            else
                calledClass = @parser.findUseForClass(editor, parts[0])

        currentClass = @parser.getCurrentClass(editor, bufferPosition)

        if currentClass == calledClass && @jumpToFunction(editor, term)
            return

        methods = proxy.methods(calledClass)
        if methods.names.indexOf(term) == -1
            return
        parentClass = methods.values[term].declaringClass;
        classMap = proxy.autoloadClassMap()

        atom.workspace.open(classMap[parentClass], {
            searchAllPanes: true
        })
        @jumpToFunctionOnLoad = term

    jumpToFunction: (editor, method) ->
        bufferPosition = @parser.findBufferPositionOfFunction(editor, method)
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
