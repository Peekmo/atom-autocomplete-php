{TextEditor} = require 'atom'

ClassProvider = require './class-provider.coffee'
FunctionProvider = require './function-provider.coffee'
PropertyProvider = require './property-provider.coffee'

parser = require '../services/php-file-parser.coffee'

module.exports =

class GotoManager
    providers: []
    trace: []

    ###*
     * Initialisation of all the providers and commands for goto
    ###
    init: () ->
        @providers.push new ClassProvider()
        @providers.push new FunctionProvider()
        @providers.push new PropertyProvider()

        for provider in @providers
            provider.init(@)

        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:goto-backtrack': =>
            @backTrack(atom.workspace.getActivePaneItem())

        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:goto': =>
            @goto(atom.workspace.getActivePaneItem())

    ###*
     * Deactivates the goto functionaility
    ###
    deactivate: () ->
        for provider in @providers
            provider.deactivate()

    ###*
     * Adds a backtrack step to the stack.
     *
     * @param {string}         fileName       The file where the jump took place.
     * @param {BufferPosition} bufferPosition The buffer position the cursor was last on.
    ###
    addBackTrack: (fileName, bufferPosition) ->
        @trace.push({
            file: fileName,
            position: bufferPosition
        })

    ###*
     * Pops one of the stored back tracks and jump the user to its position.
     *
     * @param {TextEditor} editor The current editor.
    ###
    backTrack: (editor) ->
        if @trace.length == 0
            return

        lastTrace = @trace.pop()

        if editor instanceof TextEditor && editor.getPath() == lastTrace.file
            editor.setCursorBufferPosition(lastTrace.position, {
                autoscroll: false
            })

            # Separated these as the autoscroll on setCursorBufferPosition
            # didn't work as well.
            editor.scrollToScreenPosition(editor.screenPositionForBufferPosition(lastTrace.position), {
                center: true
            })

        else
            atom.workspace.open(lastTrace.file, {
                searchAllPanes: true,
                initialLine: lastTrace.position[0]
                initialColumn: lastTrace.position[1]
            })

    ###*
     * Takes the editor and jumps using one of the providers.
     *
     * @param {TextEditor} editor Current active editor
    ###
    goto: (editor) ->
        fullTerm = parser.getFullWordFromBufferPosition(editor, editor.getCursorBufferPosition())

        for provider in @providers
            if provider.canGoto(fullTerm)
                provider.gotoFromEditor(editor)
                break
