AbstractGoto = require './abstract-goto'
{TextEditor} = require 'atom'

module.exports =
class GotoFunction extends AbstractGoto

    hoverEventSelectors: '.function-call'
    clickEventSelectors: '.function-call'
    gotoRegex: /^(\$\w+)?((->|::)\w+)+/

    ###*
     * Initialisation of Gotos
     * @param  {GotoManager} manager The manager that stores this goto.
     *                               Used mainly for backtrack registering.
    ###
    init: (manager) ->
        super(manager)
        @jumpToFunctionOnLoad = ''
        atom.workspace.onDidChangeActivePaneItem (paneItem) =>
            if paneItem instanceof TextEditor && @jumpToFunctionOnLoad != ''
                @jumpToFunction(paneItem, @jumpToFunctionOnLoad)
                @jumpToFunctionOnLoad = ''

    ###*
     * Goto the class from the term given.
     * @param  {TextEditor} editor  TextEditor to search for namespace of term.
     * @param  {string}     term    Term to search for.
    ###
    gotoFromWord: (editor, term) ->
        proxy = require '../services/php-proxy.coffee'
        bufferPosition = editor.getCursorBufferPosition()
        fullCall = @parser.getStackClasses(editor, bufferPosition)

        if fullCall.length == 0 or !term
          return

        calledClass = ''
        splitter = '->'
        if fullCall.length > 1
            calledClass = @parser.parseElements(editor, bufferPosition, fullCall)
        else
            parts = fullCall[0].trim().split('::')
            splitter = '::'
            if parts[0] == 'parent'
                calledClass = @parser.getParentClass(editor)
            else
                calledClass = @parser.findUseForClass(editor, parts[0])

        currentClass = @parser.getCurrentClass(editor, bufferPosition)
        termParts = term.split(splitter)
        term = termParts.pop()
        if currentClass == calledClass && @jumpToFunction(editor, term)
            @manager.addBackTrack(editor.getPath(), editor.getCursorBufferPosition())
            return

        methods = proxy.methods(calledClass)
        if methods.names.indexOf(term) == -1
            return
        value = methods.values[term]
        parentClass = ''
        if value instanceof Array
            for val in value
                if val.isMethod
                    parentClass = val.declaringClass
                    break
        else
            parentClass = value.declaringClass;

        classMap = proxy.autoloadClassMap()

        atom.workspace.open(classMap[parentClass], {
            searchAllPanes: true
        })
        @manager.addBackTrack(editor.getPath(), editor.getCursorBufferPosition())
        @jumpToFunctionOnLoad = term

    ###*
     * Jumps to the function within the editor
     * @param  {TextEditor} editor The editor that has the function in.
     * @param  {string} method     The function to find and then jump to.
     * @return {boolean}           Whether the finding was successful.
    ###
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
