AbstractGoto = require './abstract-goto'
{TextEditor} = require 'atom'

module.exports =
class GotoFunction extends AbstractGoto

    hoverEventSelectors: '.function-call'
    clickEventSelectors: '.function-call'
    gotoRegex: /^(\$\w+)?((->|::)\w+\()+/

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
        term = termParts.pop().replace('(', '')
        if currentClass == calledClass && @jumpTo(editor, term)
            @manager.addBackTrack(editor.getPath(), editor.getCursorBufferPosition())
            return

        methods = proxy.methods(calledClass)
        if methods.error? and methods.error != ''
            atom.notifications.addError('Failed to get methods for ' + calledClass, {
                'detail': methods.error.message
            })
            return

        if methods.names.indexOf(term) == -1
            return
        value = methods.values[term]
        parentClass = ''
        if value instanceof Array
            for val in value
                if val.isMethod
                    parentClass = val.declaringClass
                    value = val
                    break
        else
            parentClass = value.declaringClass;

        classMap = proxy.autoloadClassMap()

        atom.workspace.open(classMap[parentClass], {
            searchAllPanes: true
        })
        @manager.addBackTrack(editor.getPath(), editor.getCursorBufferPosition())
        @jumpWord = term
        @jumpLine = value.startLine - 1

    ###*
     * Gets the regex used when looking for a word within the editor
     * @param  {string} term Term being search.
     * @return {regex}       Regex to be used.
    ###
    getJumpToRegex: (term) ->
        return ///function\ +#{term}(\ +|\()///i
