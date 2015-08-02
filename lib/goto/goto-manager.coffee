GotoClass = require './class-goto.coffee'
GotoFunction = require './function-goto.coffee'
{TextEditor} = require 'atom'
parser = require '../services/php-file-parser.coffee'

module.exports =
class GotoManager
    gotos: []
    trace: []

    init: () ->
        @gotos.push new GotoClass()
        @gotos.push new GotoFunction()
        for goto in @gotos
            goto.init(@)

        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:goto-backtrack': =>
            @backTrack(atom.workspace.getActivePaneItem())

        atom.commands.add 'atom-workspace', 'atom-autocomplete-php:goto': =>
            @goto(atom.workspace.getActivePaneItem())

    deactivate: () ->
        for goto in @gotos
            goto.deactivate()

    addBackTrack: (fileName, bufferPosition) ->
        @trace.push({
            file: fileName,
            position: bufferPosition
        })

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

    goto: (editor) ->
        fullTerm = parser.getFullWordFromBufferPosition(editor, editor.getCursorBufferPosition())
        for goto in @gotos
            if goto.canGoto(fullTerm)
                goto.gotoFromEditor(editor)
                break
