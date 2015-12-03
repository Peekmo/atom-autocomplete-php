{Range, Point, TextEditor} = require 'atom'

SubAtom = require 'sub-atom'

AttachedPopover = require '../services/attached-popover'

module.exports =

class AbstractProvider
    # The regular expression that a line must match in order for it to be checked if it requires an annotation.
    regex: null
    markers: []
    subAtoms: []

    ###*
     * Initializes this provider.
    ###
    init: () ->
        @$ = require 'jquery'
        @parser = require '../services/php-file-parser'

        atom.workspace.observeTextEditors (editor) =>
            editor.onDidSave (event) =>
                @rescan(editor)

            @registerAnnotations editor
            @registerEvents editor

        # When you go back to only have 1 pane the events are lost, so need to re-register.
        atom.workspace.onDidDestroyPane (pane) =>
            panes = atom.workspace.getPanes()

            if panes.length == 1
                for paneItem in panes[0].items
                    if paneItem instanceof TextEditor
                        @registerEvents paneItem

        # Having to re-register events as when a new pane is created the old panes lose the events.
        atom.workspace.onDidAddPane (observedPane) =>
            panes = atom.workspace.getPanes()

            for pane in panes
                if pane == observedPane
                    continue

                for paneItem in pane.items
                    if paneItem instanceof TextEditor
                        @registerEvents paneItem

    ###*
     * Deactives the provider.
    ###
    deactivate: () ->
        @removeAnnotations()

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
     * @param {TextEditor} editor The editor to search through.
    ###
    registerAnnotations: (editor) ->
        text = editor.getText()
        rows = text.split('\n')
        @subAtoms[editor.getLongTitle()] = new SubAtom

        for rowNum,row of rows
            while (match = @regex.exec(row))
                @placeAnnotation(editor, rowNum, row, match)

    ###*
     * Places an annotation at the specified line and row text.
     *
     * @param {TextEditor} editor
     * @param {int}        row
     * @param {String}     rowText
     * @param {Array}      match
    ###
    placeAnnotation: (editor, row, rowText, match) ->
        annotationInfo = @extractAnnotationInfo(editor, row, rowText, match)

        if not annotationInfo
            return

        range = new Range(
            new Point(parseInt(row), 0),
            new Point(parseInt(row), rowText.length)
        )

        # For Atom 1.3 or greater, maintainHistory can only be applied to entire
        # marker layers. Layers don't exist in earlier versions, hence the
        # conditional logic.
        if typeof editor.addMarkerLayer is 'function'
            @markerLayers ?= new WeakMap
            unless markerLayer = @markerLayers.get(editor)
                markerLayer = editor.addMarkerLayer(maintainHistory: true)
                @markerLayers.set(editor, markerLayer)

        marker = (markerLayer ? editor).markBufferRange(range, {
            maintainHistory : true,
            invalidate      : 'touch'
        })

        decoration = editor.decorateMarker(marker, {
            type: 'line-number',
            class: annotationInfo.lineNumberClass
        })

        longTitle = editor.getLongTitle()

        if @markers[longTitle] == undefined
            @markers[longTitle] = []

        @markers[longTitle].push(marker)

        @registerAnnotationEventHandlers(editor, row, annotationInfo)

    ###*
     * Exracts information about the annotation match.
     *
     * @param {TextEditor} editor
     * @param {int}        row
     * @param {String}     rowText
     * @param {Array}      match
    ###
    extractAnnotationInfo: (editor, row, rowText, match) ->

    ###*
     * Registers annotation event handlers for the specified row.
     *
     * @param {TextEditor} editor
     * @param {int}        row
     * @param {Object}     annotationInfo
    ###
    registerAnnotationEventHandlers: (editor, row, annotationInfo) ->
        textEditorElement = atom.views.getView(editor)
        gutterContainerElement = @$(textEditorElement.shadowRoot).find('.gutter-container')

        do (editor, gutterContainerElement, annotationInfo) =>
            longTitle = editor.getLongTitle()
            selector = '.line-number' + '.' + annotationInfo.lineNumberClass + '[data-buffer-row=' + row + '] .icon-right'

            @subAtoms[longTitle].add gutterContainerElement, 'mouseover', selector, (event) =>
                @handleMouseOver(event, editor, annotationInfo)

            @subAtoms[longTitle].add gutterContainerElement, 'mouseout', selector, (event) =>
                @handleMouseOut(event, editor, annotationInfo)

            @subAtoms[longTitle].add gutterContainerElement, 'click', selector, (event) =>
                @handleMouseClick(event, editor, annotationInfo)

    ###*
     * Handles the mouse over event on an annotation.
     *
     * @param {jQuery.Event} event
     * @param {TextEditor}   editor
     * @param {Object}       annotationInfo
    ###
    handleMouseOver: (event, editor, annotationInfo) ->
        if annotationInfo.tooltipText
            @removePopover()

            @attachedPopover = new AttachedPopover(event.target)
            @attachedPopover.setText(annotationInfo.tooltipText)
            @attachedPopover.show()

    ###*
     * Handles the mouse out event on an annotation.
     *
     * @param {jQuery.Event} event
     * @param {TextEditor}   editor
     * @param {Object}       annotationInfo
    ###
    handleMouseOut: (event, editor, annotationInfo) ->
        @removePopover()

    ###*
     * Handles the mouse click event on an annotation.
     *
     * @param {jQuery.Event} event
     * @param {TextEditor}   editor
     * @param {Object}       annotationInfo
    ###
    handleMouseClick: (event, editor, annotationInfo) ->

    ###*
     * Removes the existing popover, if any.
    ###
    removePopover: () ->
        if @attachedPopover
            @attachedPopover.dispose()
            @attachedPopover = null

    ###*
     * Removes any annotations that were created.
     *
     * @param {TextEditor} editor The editor to search through.
    ###
    removeAnnotations: (editor) ->
        for i,marker of @markers[editor.getLongTitle()]
            marker.destroy()

        @markers[editor.getLongTitle()] = []
        @subAtoms[editor.getLongTitle()]?.dispose()

    ###*
     * Rescans the editor, updating all annotations.
     *
     * @param {TextEditor} editor The editor to search through.
    ###
    rescan: (editor) ->
        @removeAnnotations(editor)
        @registerAnnotations(editor)
