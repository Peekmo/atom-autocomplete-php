exec = require "child_process"
config = require "../config.coffee"
md5 = require 'MD5'
fs = require 'fs'

data =
  statics: [],
  methods: []

###*
 * Executes a command to PHP proxy
 * @param  {string}  command Command to exectue
 * @param  {boolean} async   Must be async or not
 * @return {array}           Json of the response
###
execute = (command, async) ->
  for directory in atom.project.getDirectories()
    if not async
      try
        stdout = exec.execSync(config.config.php + " " + __dirname + "/../../php/parser.php " + directory.path + " " + command)
        res = JSON.parse(stdout)
      catch err
        res =
          error: err

      if res.error?
        printError(res.error)

      return res
    else
      exec.exec(config.config.php + " " + __dirname + "/../../php/parser.php " + directory.path + " " + command, (error, stdout, stderr) ->
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
 * Throw a formatted error
 * @param {object} error Error to show
###
printError = (error) ->
  data.error = true
  message = error.message

  if error.file? and error.line?
    message = message + ' [from file ' + error.file + ' - Line ' + error.line + ']'

  throw new Error(message)

module.exports =
  ###*
   * Clear all cache of the plugin
  ###
  clearCache: () ->
    data =
      error: false,
      statics: [],
      methods: []

  ###*
   * Autocomplete for classes name
   * @return {array}
  ###
  classes: () ->
    return readIndex('classes')

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
   * Refresh the full index or only for the given className
   * @param  {string} className Full path (with namespace) of the class to refresh
  ###
  refresh: (className) ->
    if not className?
      execute("--refresh", true)
    else
      execute("--refresh #{className}")

  ###*
   * Method called on plugin activation
  ###
  init: () ->
    @refresh()
    atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        @clearCache()

    atom.config.onDidChange 'atom-autocomplete-php.binPhp', () =>
      @clearCache()

    atom.config.onDidChange 'atom-autocomplete-php.binComposer', () =>
      @clearCache()

    atom.config.onDidChange 'atom-autocomplete-php.autoloadPaths', () =>
      @clearCache()
