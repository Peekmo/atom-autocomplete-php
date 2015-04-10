exec = require "child_process"

data =
  statics: []

printError = (error) ->
  data.error = true
  message = error.message

  if error.file? and error.line?
    message = message + ' [from file ' + error.file + ' - Line ' + error.line + ']';

  window.alert message

# -------------------------------------- CLASSES ----------------------------------------
fetchClasses = () ->
  for directory in atom.project.getDirectories()
    stdout = exec.execSync("php " + __dirname + "/../php/parser.php " + directory.path + " --classes")

    res = JSON.parse(stdout)

    if res.error?
      printError(res.error)

    data.classes = res

# -------------------------------------- STATICS ----------------------------------------
fetchStatics = (className) ->
  for directory in atom.project.getDirectories()
    stdout = exec.execSync("php " + __dirname + "/../php/parser.php " + directory.path + " --statics " + className)
    res = JSON.parse(stdout)

    if res.error?
      printError(res.error)

    data.statics[res.class] = res

module.exports =
  classes: () ->
    if not data.classes? and not data.error?
      fetchClasses()

    return data.classes

  statics: (className) ->
    if not data.statics[className]? and not data.error?
      fetchStatics(className)

    return data.statics[className]
