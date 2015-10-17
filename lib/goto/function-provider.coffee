{TextEditor} = require 'atom'

AbstractProvider = require './abstract-provider'

module.exports =

class FunctionProvider extends AbstractProvider
    hoverEventSelectors: '.function-call'
    clickEventSelectors: '.function-call'
    gotoRegex: /^(\$\w+)?((->|::)\w+\()+/

    ###*
     * Goto the class from the term given.
     *
     * @param {TextEditor} editor  TextEditor to search for namespace of term.
     * @param {string}     term    Term to search for.
    ###
    gotoFromWord: (editor, term) ->
        bufferPosition = editor.getCursorBufferPosition()

        calledClass = @parser.getCalledClass(editor, term, bufferPosition)

        if not calledClass
            return

        currentClass = @parser.getFullClassName(editor)

        if currentClass == calledClass && @jumpTo(editor, term)
            @manager.addBackTrack(editor.getPath(), bufferPosition)
            return

        value = @parser.getMemberContext(editor, term, bufferPosition, calledClass)

        if not value
            return

        atom.workspace.open(value.declaringStructure.filename, {
            initialLine    : (value.startLine - 1),
            searchAllPanes : true
        })

        @manager.addBackTrack(editor.getPath(), bufferPosition)

    ###*
     * Gets the regex used when looking for a word within the editor
     *
     * @param {string} term Term being search.
     *
     * @return {regex} Regex to be used.
    ###
    getJumpToRegex: (term) ->
        return ///function\ +#{term}(\ +|\()///i
