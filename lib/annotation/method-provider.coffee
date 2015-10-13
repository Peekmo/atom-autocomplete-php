{Range} = require 'atom'
{Point} = require 'atom'
{TextEditor} = require 'atom'

SubAtom = require 'sub-atom'
AbstractProvider = require './abstract-provider'
AttachedPopover = require '../services/attached-popover'

module.exports =

class FunctionProvider extends AbstractProvider
    annotationMarkers: []
    annotationSubAtoms: []

    ###*
     * Registers event handlers.
     *
     * @param {TextEditor} editor TextEditor to register events to.
    ###
    registerEvents: (editor) ->
        if editor.getGrammar().scopeName.match /text.html.php$/
            # Ticket #107 - Mouseout isn't generated until the mouse moves, even when scrolling (with the keyboard or
            # mouse). If the element goes out of the view in the meantime, its HTML element disappears, never removing
            # it.
            editor.onDidDestroy () =>
                @removePopover()

            editor.onDidStopChanging () =>
                @removePopover()

            textEditorElement = atom.views.getView(editor)

            @$(textEditorElement.shadowRoot).find('.horizontal-scrollbar').on 'scroll', () =>
                @removePopover()

            @$(textEditorElement.shadowRoot).find('.vertical-scrollbar').on 'scroll', () =>
                @removePopover()

    ###*
     * Registers the annotations.
     *
     * @param {TextEditor} editor The editor to search through
    ###
    registerAnnotations: (editor) ->
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
                            tooltipText = ''

                            # NOTE: We explicitly show the declaring class here, not the structure (which could be a
                            # trait).
                            if value.override
                                tooltipText += 'Overrides method from ' + value.override.declaringClass.name

                            else
                                tooltipText += 'Implements method for ' + value.implementation.declaringClass.name

                            @attachedPopover = new AttachedPopover(event.target)
                            @attachedPopover.setText(tooltipText)
                            @attachedPopover.show()

                        @annotationSubAtoms[editor.getLongTitle()].add gutterContainerElement, 'mouseout', selector, (event) =>
                            @removePopover()

                        @annotationSubAtoms[editor.getLongTitle()].add gutterContainerElement, 'click', selector, (event) =>
                            referencedObject = if value.override then value.override else value.implementation

                            atom.workspace.open(referencedObject.declaringStructure.filename, {
                                initialLine    : referencedObject.startLine - 1,
                                searchAllPanes : true
                            })

    ###*
     * Removes any annotations that were created.
     *
     * @param {TextEditor} editor The editor to search through
    ###
    removeAnnotations: (editor) ->
        for i,marker of @annotationMarkers[editor.getLongTitle()]
            marker.destroy()

        @annotationMarkers[editor.getLongTitle()] = []
        @annotationSubAtoms[editor.getLongTitle()]?.dispose()

    ###*
     * Removes the popover, if it is displayed.
    ###
    removePopover: () ->
        if @attachedPopover
            @attachedPopover.dispose()
            @attachedPopover = null
