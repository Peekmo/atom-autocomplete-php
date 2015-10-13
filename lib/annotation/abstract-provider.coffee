{TextEditor} = require 'atom'

module.exports =

class AbstractProvider
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
        #if editor.getGrammar().scopeName.match /text.html.php$/

    ###*
     * Registers the annotations.
     *
     * @param {TextEditor} editor The editor to search through.
    ###
    registerAnnotations: (editor) ->

    ###*
     * Removes any annotations that were created.
     *
     * @param {TextEditor} editor The editor to search through.
    ###
    removeAnnotations: (editor) ->

    ###*
     * Rescans the editor, updating all annotations.
     *
     * @param {TextEditor} editor The editor to search through.
    ###
    rescan: (editor) ->
        @removeAnnotations(editor)
        @registerAnnotations(editor)
