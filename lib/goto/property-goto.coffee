AbstractGoto = require './abstract-goto'
{TextEditor} = require 'atom'

module.exports =
class GotoProperty extends AbstractGoto

    hoverEventSelectors: '.property'
    clickEventSelectors: '.property'
    gotoRegex: /^(\$\w+)?((->|::)\w+)+/

    ###*
     * Goto the property from the term given.
     * @param  {TextEditor} editor  TextEditor to search for namespace of term.
     * @param  {string}     term    Term to search for.
    ###
    gotoFromWord: (editor, term) ->
        bufferPosition = editor.getCursorBufferPosition()

        calledClass = @getCalledClass(editor, term, bufferPosition)

        if not calledClass
            return

        currentClass = @parser.getCurrentClass(editor, bufferPosition)

        if currentClass == calledClass && @jumpTo(editor, term)
            @manager.addBackTrack(editor.getPath(), editor.getCursorBufferPosition())
            return

        value = @getPropertyForTerm(editor, term, bufferPosition, calledClass)

        if not value
            return

        parentClass = value.declaringClass

        proxy = require '../services/php-proxy.coffee'
        classMap = proxy.autoloadClassMap()

        atom.workspace.open(classMap[parentClass], {
            searchAllPanes: true
        })
        @manager.addBackTrack(editor.getPath(), editor.getCursorBufferPosition())
        @jumpWord = term

    ###*
     * Retrieves information about the property described by the specified term.
     * @param  {TextEditor} editor          TextEditor to search for namespace of term.
     * @param  {string}     term            Term to search for.
     * @param  {Point}      bufferPosition  The cursor location the term is at.
     * @param  {Object}     calledClass     Information about the called class (optional).
    ###
    getPropertyForTerm: (editor, term, bufferPosition, calledClass) ->
        if not calledClass
            calledClass = @getCalledClass(editor, term, bufferPosition)

        if not calledClass
            return

        proxy = require '../services/php-proxy.coffee'
        methodsAndProperties = proxy.methods(calledClass)
        if not methodsAndProperties.names?
            return

        if methodsAndProperties.names.indexOf(term) == -1
            return
        value = methodsAndProperties.values[term]

        if value instanceof Array
            for val in value
                if !val.isMethod
                    value = val
                    break

        return value

    ###*
     * Gets the regex used when looking for a word within the editor
     * @param  {string} term Term being search.
     * @return {regex}       Regex to be used.
    ###
    getJumpToRegex: (term) ->
        return ///(protected|public|private|static)\ +\$#{term}///i
