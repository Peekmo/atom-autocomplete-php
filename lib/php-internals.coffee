exec = require "child_process"

res = {}

parseData = (error, stdout, stderr) ->
  console.log stdout
  res = JSON.parse(stdout)
  console.log(res)

  if res.error?
    message = res.error.message

    if res.error.file? and res.error.line?
      message = message + ' [from file ' + res.error.file + ' - Line ' + res.error.line + ']';

    window.alert message

fetch = () ->
  for directory in atom.project.getDirectories()
    exec.exec("php " + __dirname + "/../php/parser.php " + directory.path, parseData)

get = () ->
  if not res.classes? and not res.error?
    fetch()

  return res

module.exports =
  classes: () ->
    return get().classes

  functions: () ->
    return get().functions
