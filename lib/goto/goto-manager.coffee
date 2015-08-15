GotoClass = require './class-goto.coffee'
GotoFunction = require './function-goto.coffee'
GotoProperty = require './property-goto.coffee'
{TextEditor} = require 'atom'
parser = require '../services/php-file-parser.coffee'

module.exports =
class GotoManager
    gotos: []
    trace: []

    ###*
     * Initialisation of all the gotos and commands for goto
    ###
    init: () ->
        @gotos.push new GotoClass()
        @gotos.push new GotoFunction()
        @gotos.push new GotoProperty()
        for goto in @gotos
            goto.init(@)

        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:goto-backtrack': =>
            @backTrack(atom.workspace.getActivePaneItem())

        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:goto': =>
            @goto(atom.workspace.getActivePaneItem())

    ###*
     * Deactivates the goto functionaility
    ###
    deactivate: () ->
        for goto in @gotos
            goto.deactivate()

    ###*
     * Adds a backtrack step to the stack
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
     * @param  {TextEditor} editor The current editor
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
     * Takes the editor and jumps using one of the gotos.
     * @param  {TextEditor} editor Current active editor
    ###
    goto: (editor) ->
        fullTerm = parser.getFullWordFromBufferPosition(editor, editor.getCursorBufferPosition())
        for goto in @gotos
            if goto.canGoto(fullTerm)
                goto.gotoFromEditor(editor)
                break
