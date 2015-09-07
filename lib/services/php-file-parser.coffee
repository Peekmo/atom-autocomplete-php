proxy = require "../services/php-proxy.coffee"

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
        if line.indexOf(namespaceDeclaration) != -1
          line = line.replace('<?php', '').trim()
          line = line.substring(namespaceDeclaration.length, line.length).trim()

          namespaceEnd = line.indexOf(';')
          if namespaceEnd == -1
            namespaceEnd = line.indexOf('{')

          return line.substring(0, namespaceEnd).trim() + "\\" + name

      row--

    return name

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
    # remove first "\" if any
    if className.indexOf("\\") == 0
      className = className.substr(1)

    # fix #51
    classNameElements = className.split("\\")
    className = classNameElements.shift()

    text = editor.getText()

    lines = text.split('\n')
    for line in lines
      line = line.trim()

      # If we found class keyword, we are not in namespace space, so return the className
      if line.indexOf('class ') != -1
        break

      # Use keyword
      if line.indexOf('use') == 0
        useRegex = /(?:use)(?:[^\w\\])([\w\\]+)(?![\w\\])(?:(?:[ ]+as[ ]+)(\w+))?(?:;)/g

        matches = useRegex.exec(line)
        # just one use
        if matches[1]? and not matches[2]?
          splits = matches[1].split('\\')
          if splits[splits.length-1] == className
            className = matches[1]
            break

        # use aliases
        else if matches[1]? and matches[2]? and matches[2] == className
          className = matches[1]
          break

    if classNameElements.length > 0
      return className + "\\" + classNameElements.join("\\")
    else
      return className

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
    isInClosure = false

    # for each row
    while row != -1
      line = rows[row]

      character = 0
      lineLength = line.length
      lastChain = null

      # Scan the entire line, fetching the scope for each character position as one line can contain both a scope start
      # and end such as "} elseif (true) {". Here the scope descriptor will differ for different character positions on
      # the line.
      while character <= line.length
        # Get chain of all scopes
        chain = editor.scopeDescriptorForBufferPosition([row, character]).getScopeChain()

        # NOTE: Atom quirk: both line.length and line.length - 1 return the same scope descriptor, BUT you can't skip
        # scanning line.length as sometimes line.length - 1 does not return a scope descriptor at all.
        if not (character == line.length and chain == lastChain)
          # }
          if chain.indexOf("scope.end") != -1
            closedBlocks++
          # {
          else if chain.indexOf("scope.begin") != -1
            openedBlocks++

        # NOTE: atom/language-php quirk, when you open a closure definition, it's opening brace does NOT have the
        # 'scope.begin' class. See also https://github.com/atom/language-php/issues/98 .
        if chain.indexOf('.meta.function.closure.php') != -1
          if not isInClosure
            isInClosure = true
            openedBlocks++

        else
          isInClosure = false

        lastChain = chain
        character++

      # Get chain of all scopes
      chain = editor.scopeDescriptorForBufferPosition([row, line.length]).getScopeChain()

      # function
      if chain.indexOf("function") != -1
        # If more openedblocks than closedblocks, we are in a function. Otherwise, could be a closure, continue looking.
        if openedBlocks > closedBlocks
          result = true
          @cache["functionPosition"] = [row, 0]

          break

      row--

    @cache[text] = result
    return result

  ###*
   * Returns the stack of elements in a ->xxx->xxxx stack
   * @param  {TextEditor} editor
   * @param  {Rang}       position
   * @return string className
  ###
  getStackClasses: (editor, position) ->
    lineIdx = 0
    parenthesisOpened = 0
    parenthesisClosed = 0
    squiggleBracketOpened = false
    idx = 0
    end = false

    # Algorithm to get something inside parenthesis
    # Count parenthesis, when opened == closed and found a variable, it's done
    while (position.row - lineIdx > 0) and end == false
      text = editor.getTextInBufferRange([[position.row - idx, 0], position])
      lineIdx++
      len = text.length

      while idx < len and end == false
        if text[len - idx] == "("
          parenthesisOpened += 1
        else if text[len - idx] == ")"
          parenthesisClosed += 1
        else if text[len - idx] == "}"
          # Not going to do the semi,equals,{ check (else if below) as we are probably in a callback.
          squiggleBracketOpened = true
        else if text[len - idx] == "{" and squiggleBracketOpened
          squiggleBracketOpened = false
        # Checking we haven't hit a semi or equals. As parent calls won't have a $ to end on.
        else if (text[len - (idx + 1)] == ";" or text[len - (idx + 1)] == "=" or text[len - (idx + 1)] == "{") and !squiggleBracketOpened
          end = true
        if text[len - idx] == "$" and parenthesisClosed == parenthesisOpened
          end = true

        idx += 1

    text = text.substr(text.length - idx + 1, text.length).trim()

    return @parseStackClass(text)

  ###*
   * Removes content inside parantheses (including nested parantheses).
   * @param {string} text String to analyze.
   * @return String
  ###
  stripParanthesesContent: (text) ->
    i = 0
    openCount = 0
    closeCount = 0
    startIndex = -1

    while i < text.length
      if text[i] == '('
        ++openCount

        if openCount == 1
          startIndex = i

      else if text[i] == ')'
        ++closeCount

        if closeCount == openCount
          originalLength = text.length
          text = text.substr(0, startIndex + 1) + text.substr(i, text.length);

          i -= (originalLength - text.length)

          openCount = 0
          closeCount = 0

      ++i

    return text

  ###*
   * Parse stack class elements
   * @param {string} text String of the stack class
   * @return Array
  ###
  parseStackClass: (text) ->
    # Remove singe line comments
    regx = /\/\/.*\n/g
    text = text.replace regx, (match) =>
        return ''

    # Remove multi line comments
    regx = /\/\*[^(\*\/)]*\*\//g
    text = text.replace regx, (match) =>
        return ''

    # Remove content inside parantheses (including nested parantheses).
    text = @stripParanthesesContent(text)

    # Get the full text
    return [] if not text

    elements = text.split("->")

    # Remove parenthesis and whitespaces
    for key, element of elements
      element = element.replace /^\s+|\s+$/g, ""
      if element[0] == '{' or element[0] == '(' or element[0] == '['
        element = element.substring(1)
      else if element.indexOf('return ') == 0
        element = element.substring('return '.length)

      elements[key] = element

    return elements

  ###*
   * Get the type of a variable
   *
   * @param {TextEditor} editor
   * @param {Range}      bufferPosition
   * @param {string}     element        Variable to search
  ###
  getVariableType: (editor, bufferPosition, element) ->
    idx = 1

    if element.replace(/[\$][a-zA-Z0-9_]+/g, "").trim().length > 0
      return null

    if element.trim().length == 0
      return null

    # Regex variable definition
    regexElement = new RegExp("\\#{element}[\\s]*=[\\s]*([^;]+);", "g")
    while bufferPosition.row - idx > 0
      # Get the line
      line = editor.getTextInBufferRange([[bufferPosition.row - idx, 0], bufferPosition])

      # Get chain of all scopes
      chain = editor.scopeDescriptorForBufferPosition([bufferPosition.row - idx, line.length]).getScopeChain()
      matches = regexElement.exec(line)

      if null != matches
        value = matches[1]
        elements = @parseStackClass(value)
        elements.push("") # Push one more element to get fully the last class

        newPosition =
            row : bufferPosition.row - idx
            column: bufferPosition.column
        className = @parseElements(editor, newPosition, elements)

        # if className is null, we check if there's a /** @var */ on top of it, to guess the type
        # Get the line
        line = editor.getTextInBufferRange([[newPosition.row - 1, 0], [newPosition.row, 10000]])

        # Get chain of all scopes
        chain = editor.scopeDescriptorForBufferPosition([newPosition.row - 1, line.length]).getScopeChain()

        if chain.indexOf("comment") != -1
          regexVar = /\@var[\s]([a-zA-Z_\\]+)/g
          matches = regexVar.exec(line)

          if null == matches
            return className

          return @findUseForClass(editor, matches[1])

      if chain.indexOf("function") != -1
        regexFunction = new RegExp("function[\\s]+([a-zA-Z]+)[\\s]*[\\(](?:(?![a-zA-Z\\_\\\\]*[\\s]*\\#{element}).)*[,\\s]?([a-zA-Z\\_\\\\]*)[\\s]*\\#{element}[a-zA-Z0-9\\s\\$,=\\\"\\\'\(\)]*[\\s]*[\\)]", "g")
        matches = regexFunction.exec(line)

        if null == matches
          return null

        func = matches[1]
        value = matches[2]

        # If we have a type hint
        if value != ""
          return @findUseForClass(editor, value)

        # otherwise, we are parsing PHPdoc (@param)
        params = proxy.docParams(@getCurrentClass(editor, bufferPosition), func)
        if params.params? and params.params[element]?
          return @findUseForClass(editor, params.params[element])

        break

      idx++

    return null


  ###*
   * Parse all elements from the given array to return the last className (if any)
   * @param  Array elements Elements to parse
   * @return string|null full class name of the last element
  ###
  parseElements: (editor, bufferPosition, elements) ->
    loop_index = 0
    className  = null

    for element in elements
      # $this keyword
      if loop_index == 0
        if element == '$this'

          className = @getCurrentClass(editor, bufferPosition)
          loop_index++
          continue
        else
          className = @getVariableType(editor, bufferPosition, element)
          loop_index++
          continue

      # Last element
      if loop_index >= elements.length - 1
        break

      if className == null
        break

      methods = proxy.autocomplete(className, element)

      # Element not found or no return value
      if not methods.class? or not @isClass(methods.class)
        className = null
        break

      className = methods.class
      loop_index++

    # If no data or a valid end of line, OK
    if elements.length > 0 and (elements[elements.length-1].length == 0 or elements[elements.length-1].match(/([a-zA-Z0-9]$)/g))
      return className

    return null

  ###*
   * Gets the full words from the buffer position given.
   * E.g. Getting a class with its namespace.
   * @param  {TextEditor}     editor   TextEditor to search.
   * @param  {BufferPosition} position BufferPosition to start searching from.
   * @return {string}  Returns a string of the class.
  ###
  getFullWordFromBufferPosition: (editor, position) ->
    foundStart = false
    foundEnd = false
    startBufferPosition = []
    endBufferPosition = []
    forwardRegex = /-|(?:\()[\w\[\$\(\\]|\s|\)|;|'|,|"|\|/
    backwardRegex = /\(|\s|\)|;|'|,|"|\|/
    index = -1
    previousText = ''

    loop
      index++
      startBufferPosition = [position.row, position.column - index - 1]
      range = [[position.row, position.column], [startBufferPosition[0], startBufferPosition[1]]]
      currentText = editor.getTextInBufferRange(range)
      if backwardRegex.test(editor.getTextInBufferRange(range)) || startBufferPosition[1] == -1 || currentText == previousText
          foundStart = true
      previousText = editor.getTextInBufferRange(range)
      break if foundStart
    index = -1
    loop
      index++
      endBufferPosition = [position.row, position.column + index + 1]
      range = [[position.row, position.column], [endBufferPosition[0], endBufferPosition[1]]]
      currentText = editor.getTextInBufferRange(range)
      if forwardRegex.test(currentText) || endBufferPosition[1] == 500 || currentText == previousText
          foundEnd = true
      previousText = editor.getTextInBufferRange(range)
      break if foundEnd

    startBufferPosition[1] += 1
    endBufferPosition[1] -= 1
    return editor.getTextInBufferRange([startBufferPosition, endBufferPosition])

  ###*
   * Gets the parent class of the current class opened in the editor
   * @param  {TextEditor} editor Editor with the class in.
   * @return {string}            The namespace and class of the parent
  ###
  getParentClass: (editor) ->
    text = editor.getText()

    lines = text.split('\n')
    for line in lines
      line = line.trim()

      # If we found extends keyword, return the class
      if line.indexOf('extends ') != -1
        words = line.split(' ')
        extendsIndex = words.indexOf('extends')
        return @findUseForClass(editor, words[extendsIndex + 1])

  ###*
   * Finds the buffer position of the word given
   * @param  {TextEditor} editor TextEditor to search
   * @param  {string}     term   The function name to search for
   * @return {mixed}             Either null or the buffer position of the function.
  ###
  findBufferPositionOfWord: (editor, term, regex, line = null) ->
    if line != null
      lineText = editor.lineTextForBufferRow(line)
      result = @checkLineForWord(lineText, term, regex)
      if result != null
        return [line, result]
    else
      text = editor.getText()
      row = 0
      lines = text.split('\n')
      for line in lines
        result = @checkLineForWord(line, term, regex)
        if result != null
          return [row, result]
        row++
    return null;

  ###*
   * Checks the lineText for the term and regex matches
   * @param  {string}   lineText The line of text to check.
   * @param  {string}   term     Term to look for.
   * @param  {regex}    regex    Regex to run on the line to make sure it's valid
   * @return {null|int}          Returns null if nothing was found or an
   *                             int of the column the term is on.
  ###
  checkLineForWord: (lineText, term, regex) ->
    if regex.test(lineText)
      words = lineText.split(' ')
      propertyIndex = 0
      for element in words
        if element.indexOf(term) != -1
          break
        propertyIndex++;

      reducedWords = words.slice(0, propertyIndex).join(' ')
      return reducedWords.length + 1
    return null
