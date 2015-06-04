###*
 * PHP files namespace management
###
proxy = require "./php-proxy.coffee"

module.exports =
  ###*
   * Add the good namespace to the given file
   * @param {TextEditor} editor
  ###
  createNamespace: (editor) ->
    composer = proxy.composer()
    namespace = "Prout"

    text = editor.getText()
    index = 0

    lines = text.split('\n')
    for line in lines
      line = line.trim()

      # If we found class keyword, we are not in namespace space, so return
      if line.indexOf('class ') != -1 || line.indexOf('use ') != -1
        editor.setTextInBufferRange([[index-1,0], [index-1, 0]], "namespace #{namespace};\n\n")

      if line.indexOf('namespace ') == 0
        editor.setTextInBufferRange([[index,0], [index, 0]], "namespace #{namespace};\n")

      index += 1

    return null
