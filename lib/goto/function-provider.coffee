{Range} = require 'atom'
{Point} = require 'atom'
{TextEditor} = require 'atom'

SubAtom = require 'sub-atom'
AbstractProvider = require './abstract-provider'

module.exports =

class FunctionProvider extends AbstractProvider
    hoverEventSelectors: '.function-call'
    clickEventSelectors: '.function-call'
    gotoRegex: /^(\$\w+)?((->|::)\w+\()+/
    annotationMarkers: []
    annotationSubAtoms: []

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

        value = @parser.getMethodContext(editor, term, bufferPosition, calledClass)

        if not value
            return

        atom.workspace.open(value.declaringStructure.filename, {
            initialLine    : (value.startLine - 1),
            searchAllPanes : true
        })

        @manager.addBackTrack(editor.getPath(), bufferPosition)

    ###*
     * Register any markers that you need.
     *
     * @param {TextEditor} editor The editor to search through
    ###
    registerMarkers: (editor) ->
        text = editor.getText()
        rows = text.split('\n')
        @annotationSubAtoms[editor.getLongTitle()] = new SubAtom

        for rowNum,row of rows
            regex = /(\s*(?:public|protected|private)\s+function\s+)(\w+)\s*\(/g

            while (match = regex.exec(row))
                currentClass = @parser.getFullClassName(editor)

                methodName = match[2]

                value = @parser.getMethodContext(editor, methodName, null, currentClass)

                if not value
                    continue

                if value.override or value.implementation
                    range = new Range(
                        new Point(parseInt(rowNum), match[1].length),
                        new Point(parseInt(rowNum), match[1].length + methodName.length)
                    )

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

                    do (gutterContainerElement, methodName, value, editor) =>
                        selector = '.line-number' + '.' + annotationClass + '[data-buffer-row=' + rowNum + '] .icon-right'

                        @annotationSubAtoms[editor.getLongTitle()].add gutterContainerElement, 'mouseover', selector, (event) =>
                            if event.target.hasTooltipRegistered
                                return

                            event.target.hasTooltipRegistered = true;

                            tooltipText = ''

                            # NOTE: We explicitly show the declaring class here, not the structure (which could be a
                            # trait).
                            if value.override
                                tooltipText += 'Overrides method from ' + value.override.declaringClass.name

                            else
                                tooltipText += 'Implements method for ' + value.implementation.declaringClass.name

                            atom.tooltips.add(event.target, {
                                title: '<div style="text-align: left;">' + tooltipText + '</div>'
                                html: true
                                placement: 'bottom'
                                delay:
                                    show: 0
                            })

                        @annotationSubAtoms[editor.getLongTitle()].add gutterContainerElement, 'click', selector, (event) =>
                            referencedObject = if value.override then value.override else value.implementation

                            atom.workspace.open(referencedObject.declaringStructure.filename, {
                                initialLine    : referencedObject.startLine - 1,
                                searchAllPanes : true
                            })

    ###*
     * Removes any markers previously created by registerMarkers.
     *
     * @param {TextEditor} editor The editor to search through
    ###
    cleanMarkers: (editor) ->
        for i,marker of @annotationMarkers[editor.getLongTitle()]
            marker.destroy()

        @annotationMarkers[editor.getLongTitle()] = []
        @annotationSubAtoms[editor.getLongTitle()]?.dispose()

    ###*
     * Gets the regex used when looking for a word within the editor
     *
     * @param {string} term Term being search.
     *
     * @return {regex} Regex to be used.
    ###
    getJumpToRegex: (term) ->
        return ///function\ +#{term}(\ +|\()///i
