# PHP classes/traits declaration
classDeclarations = [
  'class ',
  'abstract class ',
  'trait '
]

namespaceDeclaration = 'namespace '

module.exports =
  ###*
   * Returns the current class from the buffer
   * @param {TextEditor} editor
   * @param {Range}      position
   * @return string className
  ###
  getCurrentClass: (editor, position) ->
    # Get text before the current position
    text = editor.getTextInBufferRange([[0, 0], position])
    row = position.row
    rows = text.split('\n')

    name = ''
    # for each row
    while row != -1
      line = rows[row].trim()

      # Looking for a line starting with one of the allowed php declaration of
      # a class (see on top of the file)
      if name == ''
        for classDeclaration in classDeclarations
          if line.indexOf(classDeclaration) == 0
            line = line.substring(classDeclaration.length, line.length).trim()

            name = line.split(' ')[0]
      else
        if line.indexOf(namespaceDeclaration) == 0
          line = line.substring(namespaceDeclaration.length, line.length).trim()

          namespaceEnd = line.indexOf(';')
          if namespaceEnd == -1
            namespaceEnd = line.indexOf('{')

          return line.substring(0, namespaceEnd).trim() + "\\" + name

      row--

    return ''

  ###*
   * Checks if the current buffer is in a functon or not
   * @param {TextEditor} editor         Atom text editor
   * @param {Range}      bufferPosition Position of the current buffer
   * @return bool
  ###
  isInFunction: (editor, bufferPosition) ->
    text = editor.getTextInBufferRange([[0, 0], bufferPosition])

    row = bufferPosition.row
    rows = text.split('\n')

    # for each row
    while row != -1
      line = rows[row].trim()

      # Looking for a line with function scope
      if editor.scopeDescriptorForBufferPosition([row, 0]).getScopeChain().indexOf("function.php") != -1
        return true

      row--

    return false
