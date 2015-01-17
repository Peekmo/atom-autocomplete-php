exec = require "child_process"

data = {}

# ----------------------------------------------------- CLASSES ----------------------------------------
# Parse --classes response
parseClasses = (error, stdout, stderr) ->
  console.log stdout
  res = JSON.parse(stdout)
  console.log(res)

  if res.error?
    data.error = true
    message = res.error.message

    if res.error.file? and res.error.line?
      message = message + ' [from file ' + res.error.file + ' - Line ' + res.error.line + ']';

    window.alert message

  data.classes = res

# Fetch --classes
fetchClasses = () ->
  for directory in atom.project.getDirectories()
    exec.exec("php " + __dirname + "/../php/parser.php --classes " + directory.path, parseClasses)

module.exports =
  classes: () ->
    if not data.classes? and not data.error?
      fetchClasses()

    return data.classes
