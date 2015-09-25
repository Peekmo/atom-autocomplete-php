AbstractGoto = require './abstract-goto'
{TextEditor} = require 'atom'
{Point} = require 'atom'
{Range} = require 'atom'
SubAtom = require 'sub-atom'

module.exports =
class GotoFunction extends AbstractGoto

    hoverEventSelectors: '.function-call'
    clickEventSelectors: '.function-call'
    gotoRegex: /^(\$\w+)?((->|::)\w+\()+/
    annotationMarkers: []
    annotationSubAtoms: []

    ###*
     * Goto the class from the term given.
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
            @manager.addBackTrack(editor.getPath(), bufferPosition)
            return

        value = @getMethodForTerm(editor, term, bufferPosition, calledClass)

        if not value
            return

        parentClass = value.declaringClass

        proxy = require '../services/php-proxy.coffee'
        classMap = proxy.autoloadClassMap()

        atom.workspace.open(classMap[parentClass], {
            initialLine    : (value.startLine - 1),
            searchAllPanes : true
        })

        @manager.addBackTrack(editor.getPath(), bufferPosition)

    ###*
     * Retrieves information about the method described by the specified term.
     * @param  {TextEditor} editor          TextEditor to search for namespace of term.
     * @param  {string}     term            Term to search for.
     * @param  {Point}      bufferPosition  The cursor location the term is at.
     * @param  {Object}     calledClass     Information about the called class (optional).
    ###
    getMethodForTerm: (editor, term, bufferPosition, calledClass) ->
        if not calledClass
            calledClass = @getCalledClass(editor, term, bufferPosition)

        if not calledClass
            return

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
        @annotationSubAtoms[editor.getLongTitle()] = new SubAtom

        for rowNum,row of rows
            regex = /((?:public|protected|private)\ function\ )(\w+)\s*\(.*\)/g

            while (match = regex.exec(row))
                bufferPosition = new Point(parseInt(rowNum), match[1].length + match.index)
                currentClass = @parser.getCurrentClass(editor, bufferPosition)

                term = match[2]

                value = @getMethodForTerm(editor, term, null, currentClass)

                if not value
                    continue

                if value.override or value.implementation
                    rangeEnd = new Point(parseInt(rowNum), match[1].length + match.index + term.length)

                    range = new Range(bufferPosition, rangeEnd)

                    marker = editor.markBufferRange(range, {
                        maintainHistory: true,
                        invalidate: 'touch'
                    })

                    annotationClass = if value.override then 'override' else 'implementation'

                    decoration = editor.decorateMarker(marker, {
                        type: 'line-number',
                        class: annotationClass
                    })

                    if @annotationMarkers[editor.getLongTitle()] == undefined
                        @annotationMarkers[editor.getLongTitle()] = []

                    @annotationMarkers[editor.getLongTitle()].push(marker)

                    # Add tooltips and click handlers to the annotations.
                    textEditorElement = atom.views.getView(editor)
                    gutterContainerElement = @$(textEditorElement.shadowRoot).find('.gutter-container')

                    do (gutterContainerElement, term, value, editor) =>
                        selector = '.line-number' + '.' + annotationClass + '[data-buffer-row=' + rowNum + '] .icon-right'

                        @annotationSubAtoms[editor.getLongTitle()].add gutterContainerElement, 'mouseover', selector, (event) =>
                            if event.target.hasTooltipRegistered
                                return

                            event.target.hasTooltipRegistered = true;

                            tooltipText = ''

                            if value.override
                                tooltipText += 'Overrides method from ' + value.override.baseClass

                            else
                                tooltipText += 'Implements method from ' + value.implementation.interfaceName

                            atom.tooltips.add(event.target, {
                                title: '<div style="text-align: left;">' + tooltipText + '</div>'
                                html: true
                                placement: 'bottom'
                                delay:
                                    show: 0
                            })

                        @annotationSubAtoms[editor.getLongTitle()].add gutterContainerElement, 'click', selector, (event) =>
                            parentClass = value.declaringClass

                            proxy = require '../services/php-proxy.coffee'
                            classMap = proxy.autoloadClassMap()

                            if value.override
                                referencedClass = value.override.baseClass
                                referencedLine = value.override.baseMethodStartLine

                            else
                                referencedClass = value.implementation.interfaceName
                                referencedLine = value.implementation.interfaceMethodStartLine

                            atom.workspace.open(classMap[referencedClass], {
                                initialLine    : referencedLine - 1,
                                searchAllPanes : true
                            })

    ###*
     * Removes any markers previously created by registerMarkers.
     * @param  {TextEditor} editor The editor to search through
    ###
    cleanMarkers: (editor) ->
        for i,marker of @annotationMarkers[editor.getLongTitle()]
            marker.destroy()

        @annotationMarkers[editor.getLongTitle()] = []
        @annotationSubAtoms[editor.getLongTitle()]?.dispose()

    ###*
     * Gets the regex used when looking for a word within the editor
     * @param  {string} term Term being search.
     * @return {regex}       Regex to be used.
    ###
    getJumpToRegex: (term) ->
        return ///function\ +#{term}(\ +|\()///i
