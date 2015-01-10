exec = require "child_process"

res = {}

parseData = (error, stdout, stderr) ->
  res = JSON.parse(stdout)
  console.log(res)

fetch = () ->
  for directory in atom.project.getDirectories()
    exec.exec("php " + __dirname + "/../php/parser.php " + directory.path, parseData)

get = () ->
  if not res.classes?
    fetch()

  return res

module.exports =
  classes: () ->
    return get().classes

  functions: () ->
    return get().functions
