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

    return name

  ###*
   * Returns the stack of elements in a ->xxx->xxxx stack
   * @param  {TextEditor} editor
   * @param  {Rang}       position
   * @return string className
  ###
  getStackClasses: (editor, position) ->
    # Get the line
    text = editor.getTextInBufferRange([[position.row, 0], position])

    idx = 1
    while (not text.match(/([\$][a-zA-Z0-9]*)/g)) or (position.row - idx <= 0)
      text = editor.getTextInBufferRange([[position.row - idx, 0], position])
      idx++

    # Get the full text
    return [] if not text

    elements = text.split("->")
    elements[0] = elements[0].substr(text.lastIndexOf("$"), text.length)

    # Remove parenthesis and whitespaces
    for key, element of elements
      element = element.replace /^\s+|\s+$/g, ""
      if element[0] == '{' or element[0] == '(' or element[0] == '['
        element = element.substring(1)

      elements[key] = element
      if element.indexOf("(") != -1
        elements[key] = element.substr(0, element.indexOf("(")) + element.substr(element.indexOf(")")+1, element.length)

    return elements

  ###*
   * Get all variables declared in the current function
   * @param {TextEdutir} editor         Atom text editor
   * @param {Range}      bufferPosition Position of the current buffer
  ###
  getAllVariablesInFunction: (editor, bufferPosition) ->
    return if not @isInFunction(editor, bufferPosition)

    text = editor.getTextInBufferRange([@cache["functionPosition"], [bufferPosition.row, bufferPosition.column-1]])
    regex = /(\$[a-zA-Z_]+)/g

    matches = text.match(regex)
    return [] if not matches?

    matches.push "$this"
    return matches

  ###*
   * Search the use for the given class name
   * @param {TextEditor} editor    Atom text editor
   * @param {string}     className Name of the class searched
   * @return string
  ###
  findUseForClass: (editor, className) ->
    text = editor.getText()

    lines = text.split('\n')
    for line in lines
      line = line.trim()

      # If we found class keyword, we are not in namespace space, so return the className
      if line.indexOf('class ') != -1
        return if className.indexOf("\\") != 0 then className else className.substr(1)

      # Use keyword
      if line.indexOf('use') == 0
        useRegex = /(?:use)(?:[^\w\\])([\w\\]+)(?![\w\\])(?:(?:[ ]+as[ ]+)(\w+))?(?:;)/g

        matches = useRegex.exec(line)
        # just one use
        if matches[1]? and not matches[2]?
          splits = matches[1].split('\\')
          if splits[splits.length-1] == className
            return matches[1]

        # use aliases
        else if matches[1]? and matches[2]? and matches[2] == className
          return matches[1]

    return if className.indexOf("\\") != 0 then className else className.substr(1)

  ###*
   * Add the use for the given class if not already added
   * @param {TextEditor} editor    Atom text editor
   * @param {string}     className Name of the class to add
  ###
  addUseClass: (editor, className) ->
    text = editor.getText()
    lastUse = 0
    index = 0

    splits = className.split('\\')
    if splits.length == 1 || className.indexOf('\\') == 0
        return null

    lines = text.split('\n')
    for line in lines
      line = line.trim()

      # If we found class keyword, we are not in namespace space, so return
      if line.indexOf('class ') != -1
        editor.setTextInBufferRange([[lastUse+1,0], [lastUse+1, 0]], "use #{className};\n")
        return 'added'

      if line.indexOf('namespace ') == 0
        lastUse = index

      # Use keyword
      if line.indexOf('use') == 0
        useRegex = /(?:use)(?:[^\w\\])([\w\\]+)(?![\w\\])(?:(?:[ ]+as[ ]+)(\w+))?(?:;)/g
        matches = useRegex.exec(line)

        # just one use
        if matches? and matches[1]?
          if matches[1] == className
            return 'exists'
          else
            lastUse = index

      index += 1

    return null

  ###*
   * Checks if the given name is a class or not
   * @param  {string}  name Name to check
   * @return {Boolean}
  ###
  isClass: (name) ->
    return name.substr(0,1).toUpperCase() + name.substr(1) == name

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
          @cache["functionPosition"] = [row, 0]

        break

      row--

    @cache[text] = result
    return result
