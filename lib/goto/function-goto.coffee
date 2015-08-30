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
        bufferPosition = editor.getCursorBufferPosition()

        calledClassInfo = @getCalledClassInfo(editor, term, bufferPosition)
        calledClass = calledClassInfo.calledClass
        splitter = calledClassInfo.splitter

        currentClass = @parser.getCurrentClass(editor, bufferPosition)

        termParts = term.split(splitter)
        term = termParts.pop().replace('(', '')
        if currentClass == calledClass && @jumpTo(editor, term)
            @manager.addBackTrack(editor.getPath(), bufferPosition)
            return

        value = @getMethodForTerm(editor, term, bufferPosition, calledClassInfo)

        parentClass = value.declaringClass

        proxy = require '../services/php-proxy.coffee'
        classMap = proxy.autoloadClassMap()

        atom.workspace.open(classMap[parentClass], {
            searchAllPanes: true
        })
        @manager.addBackTrack(editor.getPath(), bufferPosition)
        @jumpWord = term
        @jumpLine = value.startLine - 1

    ###*
     * Retrieves a tooltip for the word given.
     * @param  {TextEditor} editor         TextEditor to search for namespace of term.
     * @param  {string}     term           Term to search for.
     * @param  {Point}      bufferPosition The cursor location the term is at.
    ###
    getTooltipForWord: (editor, term, bufferPosition) ->
        value = @getMethodForTerm(editor, term, bufferPosition)

        if not value
            return

        # Create a useful description to show in the tooltip.
        returnType = if value.args.return then value.args.return else 'void'

        description = returnType + ' ' + term + '('

        if value.args.parameters.length > 0
            description += value.args.parameters.join(', ');

        if value.args.optionals.length > 0
            description += '['

            if value.args.parameters.length > 0
                description += ', '

            description += value.args.optionals.join(', ')
            description += ']'

        description += ')'
        description += "<br/><br/>"

        if value.args.descriptions.short
            description += value.args.descriptions.short

        else
            description += '(No documentation available)'

        return description

    ###*
     * Retrieves information about the method described by the specified term.
     * @param  {TextEditor} editor          TextEditor to search for namespace of term.
     * @param  {string}     term            Term to search for.
     * @param  {Point}      bufferPosition  The cursor location the term is at.
     * @param  {Object}     calledClassInfo Information about the called class (optional).
    ###
    getMethodForTerm: (editor, term, bufferPosition, calledClassInfo) ->
        if not calledClassInfo
            calledClassInfo = @getCalledClassInfo(editor, term, bufferPosition)

        calledClass = calledClassInfo.calledClass
        splitter = calledClassInfo.splitter

        termParts = term.split(splitter)
        term = termParts.pop().replace('(', '')

        proxy = require '../services/php-proxy.coffee'
        methods = proxy.methods(calledClass)
        if methods.error? and methods.error != ''
            atom.notifications.addError('Failed to get methods for ' + calledClass, {
                'detail': methods.error.message
            })
            return

        if methods.names.indexOf(term) == -1
            return
        value = methods.values[term]

        # If there are multiple matches, just select the first method.
        if value instanceof Array
            for val in value
                if val.isMethod
                    value = val
                    break

        return value

    ###*
     * Gets the regex used when looking for a word within the editor
     * @param  {string} term Term being search.
     * @return {regex}       Regex to be used.
    ###
    getJumpToRegex: (term) ->
        return ///function\ +#{term}(\ +|\()///i
