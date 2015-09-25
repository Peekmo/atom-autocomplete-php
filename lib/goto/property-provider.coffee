{TextEditor} = require 'atom'

AbstractProvider = require './abstract-provider'

module.exports =

class PropertyProvider extends AbstractProvider
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

        calledClass = @parser.getCalledClass(editor, term, bufferPosition)

        if not calledClass
            return

        currentClass = @parser.getCurrentClass(editor, bufferPosition)

        if currentClass == calledClass && @jumpTo(editor, term)
            @manager.addBackTrack(editor.getPath(), editor.getCursorBufferPosition())
            return

        value = @parser.getPropertyContext(editor, term, bufferPosition, calledClass)

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
     * Gets the regex used when looking for a word within the editor
     * @param  {string} term Term being search.
     * @return {regex}       Regex to be used.
    ###
    getJumpToRegex: (term) ->
        return ///(protected|public|private|static)\ +\$#{term}///i
