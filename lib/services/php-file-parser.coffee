# PHP classes/traits declaration
classDeclarations = [
  'class ',
  'abstract class ',
  'trait '
]

namespaceDeclaration = 'namespace '
module.exports =
  # Simple cache to avoid duplicate computation for each providers
  cache: []

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

    # If last request was the same
    if @cache[text]?
      return @cache[text]

    # Reinitialize current cache
    @cache = []

    console.log 'ok'
    row = bufferPosition.row
    rows = text.split('\n')

    openedBlocks = 0
    closedBlocks = 0

    result = false

    # for each row
    while row != -1
      line = rows[row]

      # Get chain of all scopes
      chain = editor.scopeDescriptorForBufferPosition([row, line.length]).getScopeChain()

      # }
      if chain.indexOf("scope.end") != -1
        closedBlocks++
      # {
      else if chain.indexOf("scope.begin") != -1
        openedBlocks++
      # function
      else if chain.indexOf("function") != -1
        # If more openedblocks than closedblocks, we are in a function
        if openedBlocks > closedBlocks
          result = true

        break

      row--

    @cache[text] = result
    return result
