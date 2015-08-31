AbstractGoto = require './abstract-goto'
{TextEditor} = require 'atom'
{Point} = require 'atom'
{Range} = require 'atom'

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

        if not value
            return

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

        # Show the method's signature.
        returnType = if value.args.return then value.args.return else 'void'

        description = returnType + ' <strong>' + term + '</strong>' + '('

        if value.args.parameters.length > 0
            description += value.args.parameters.join(', ');

        if value.args.optionals.length > 0
            description += '['

            if value.args.parameters.length > 0
                description += ', '

            description += value.args.optionals.join(', ')
            description += ']'

        description += ')'

        # Show a description of the method.
        description += "<br/><br/>"
        description += (if value.args.descriptions.short then value.args.descriptions.short else '(No documentation available)');

        # Show an overview of the exceptions the method can throw.
        throwsDescription = "";

        for exceptionType,thrownWhenDescription of value.args.throws
            throwsDescription += "<div style='margin-left: 1em;'>• " + "<strong>" + exceptionType + "</strong>" + ' ' + thrownWhenDescription + "</div>"

        if throwsDescription.length > 0
            description += "<br/><br/>"
            description += "Throws:<br/>"
            description += throwsDescription

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

        if not calledClassInfo
            return

        calledClass = calledClassInfo.calledClass
        splitter = calledClassInfo.splitter

        termParts = term.split(splitter)
        term = termParts.pop().replace('(', '')

        proxy = require '../services/php-proxy.coffee'
        methods = proxy.methods(calledClass)

        if not methods
            return

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
     * Register any markers that you need.
     * @param  {TextEditor} editor The editor to search through
    ###
    registerMarkers: (editor) ->
        text = editor.getText()
        rows = text.split('\n')

        gutter = editor.addGutter({
            name: 'atom-autocomplete-php-symbol-gutter',
            priority: -1
        });

        for rowNum,row of rows
            regex = /((?:public|protected|private)\ function\ )(\w+)\s*\(.*\)/g

            while (match = matches = regex.exec(row))
                bufferPosition = new Point(parseInt(rowNum), match[1].length + match.index)
                currentClass = @parser.getCurrentClass(editor, bufferPosition)

                value = @getMethodForTerm(editor, match[2], null, {
                    calledClass: currentClass,
                    splitter: '->'
                })

                if not value
                    continue

                if value.isOverride or value.isImplementation
                    rangeEnd = new Point(parseInt(rowNum), match[1].length + match.index + match[2].length)

                    range = new Range(bufferPosition, rangeEnd)

                    marker = editor.markBufferRange(range, {
                        maintainHistory: true,
                        invalidate: 'touch'
                    })

                    decoration = gutter.decorateMarker(marker, {
                        type: 'line-number',
                        class: if value.isOverride then 'override' else 'implementation'
                    })

                    # TODO: Need something more stylish. The following problems exist:
                    #   - Can't align icons in the standard gutter right of the line numbers.
                    #   - With a custom gutter, the background can't be made transparent and looks ugly.
                    #   - Background colors are ugly.
                    #   - We can't attach code or fetch a HTMLElement from decorations, so we can't make it clickable
                    #     to navigate to the method being overridden (base class) or implemented (interface). (use
                    #     isOverrideOf and isImplementationOf).

                    console.log("Found override/implementation", match[2], 'with', currentClass, 'value', value)


    ###*
     * Gets the regex used when looking for a word within the editor
     * @param  {string} term Term being search.
     * @return {regex}       Regex to be used.
    ###
    getJumpToRegex: (term) ->
        return ///function\ +#{term}(\ +|\()///i
