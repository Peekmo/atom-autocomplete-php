exec = require "child_process"
config = require "../config.coffee"
md5 = require 'MD5'
fs = require 'fs'

data =
  statics: [],
  methods: [],
  autocomplete: [],
  parent: [],
  composer: null

###*
 * Executes a command to PHP proxy
 * @param  {string}  command Command to exectue
 * @param  {boolean} async   Must be async or not
 * @return {array}           Json of the response
###
execute = (command, async) ->
  command = command.replace(/\\/g, '\\\\')
  for directory in atom.project.getDirectories()
    if not async
      try
        stdout = exec.execSync(config.config.php + " " + __dirname + "/../../php/parser.php " + directory.path + " " + command)
        res = JSON.parse(stdout)
      catch err
        res =
          error: err

      if !res
        return []

      if res.error?
        printError(res.error)

      return res
    else
      console.log 'Building index'
      exec.exec(config.config.php + " " + __dirname + "/../../php/parser.php " + directory.path + " " + command, (error, stdout, stderr) ->
        console.log 'Build done'
        return []
      )

###*
 * Reads an index by its name (file in indexes/index.[name].json)
 * @param {string} name Name of the index to read
###
readIndex = (name) ->
  for directory in atom.project.getDirectories()
    crypt = md5(directory.path)
    path = __dirname + "/../../indexes/" + crypt + "/index." + name + ".json"
    try
      fs.accessSync(path, fs.F_OK | fs.R_OK)
    catch err
      return []

    options =
      encoding: 'UTF-8'
    return JSON.parse(fs.readFileSync(path, options))

    break

###*
 * Open and read the composer.json file in the current folder
###
readComposer = () ->
  for directory in atom.project.getDirectories()
    path = "#{directory.path}/composer.json"

    try
      fs.accessSync(path, fs.F_OK | fs.R_OK)
    catch err
      continue

    options =
      encoding: 'UTF-8'
    data.composer = JSON.parse(fs.readFileSync(path, options))
    return data.composer

  console.log 'Unable to find composer.json file or to open it. The plugin will not work as expected. It only works on composer project'

###*
 * Throw a formatted error
 * @param {object} error Error to show
###
printError = (error) ->
  data.error = true
  message = error.message

  #if error.file? and error.line?
    #message = message + ' [from file ' + error.file + ' - Line ' + error.line + ']'

  #throw new Error(message)

module.exports =
  ###*
   * Clear all cache of the plugin
  ###
  clearCache: () ->
    data =
      error: false,
      statics: [],
      methods: [],
      parent: [],
      composer: null

  ###*
   * Autocomplete for classes name
   * @return {array}
  ###
  classes: () ->
    return readIndex('classes')

  ###*
   * Returns composer.json file
   * @return {Object}
  ###
  composer: () ->
    return readComposer()

  ###*
   * Autocomplete for internal PHP functions
   * @return {array}
  ###
  functions: () ->
    if not data.functions?
      res = execute("--functions", false)
      data.functions = res

    return data.functions

  ###*
   * Autocomplete for statics methods of a class
   * @param  {string} className Class complete name (with namespace)
   * @return {array}
  ###
  statics: (className) ->
    if not data.statics[className]?
      res = execute("--statics #{className}", false)
      data.statics[className] = res

    return data.statics[className]

  ###*
   * Autocomplete for methods & properties of a class
   * @param  {string} className Class complete name (with namespace)
   * @return {array}
  ###
  methods: (className) ->
    if not data.methods[className]?
      res = execute("--methods #{className}", false)
      data.methods[className] = res

    return data.methods[className]

  ###*
   * Autocomplete for methods & properties of the parent class
   * @param  {string} className Class complete name (with namespace)
   * @return {array}
  ###
  parent: (className) ->
    if not data.parent[className]?
      res = execute("--parent #{className}", false)
      data.parent[className] = res

    return data.parent[className]

  ###*
   * Autocomplete for methods & properties of a class
   * @param  {string} className Class complete name (with namespace)
   * @return {array}
  ###
  autocomplete: (className, name) ->
    res = execute("--autocomplete #{className} #{name}", false)
    return res


  ###*
   * Refresh the full index or only for the given classPath
   * @param  {string} classPath Full path (dir) of the class to refresh
  ###
  refresh: (classPath) ->
    if not classPath?
      execute("--refresh", true)
    else
      execute("--refresh #{classPath}", true)

  ###*
   * Method called on plugin activation
  ###
  init: () ->
    @refresh()
    atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave((event) =>
        # Only .php file
        if event.path.substr(event.path.length - 4) == ".php"
          @clearCache()
          @refresh(event.path)
      )

    atom.config.onDidChange 'atom-autocomplete-php.binPhp', () =>
      @clearCache()

    atom.config.onDidChange 'atom-autocomplete-php.binComposer', () =>
      @clearCache()

    atom.config.onDidChange 'atom-autocomplete-php.autoloadPaths', () =>
      @clearCache()
