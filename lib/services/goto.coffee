###*
 * Goto PHP Classes
###
fuzzaldrin = require 'fuzzaldrin'
parser = require './php-file-parser'

module.exports =
  ###*
   * Goto the class the cursor is on
   * @param {TextEditor} editor
  ###
  goto: (editor) ->
    proxy = require './php-proxy.coffee'

    term = editor.getWordUnderCursor()
    term = parser.findUseForClass(editor, term)
    console.log term

    classMap = proxy.autoloadClassMap()
    classMapArray = [];

    for key,value of classMap
      classMapArray.push(key)

    matches = fuzzaldrin.filter classMapArray, term

    atom.workspace.open(classMap[matches[0]])
