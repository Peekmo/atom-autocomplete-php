PhpProvider = require './PhpProvider.coffee'

module.exports =
  configDefaults:
    fileWhitelist: "*.php"
  editorSubscription: null
  autocomplete: null
  providers: []

  activate: ->
    atome.packages.activatePackage("autocomplete-plus").then(pkg) =>
      @autocomplete = pkg.mainModule
      @registerProviders()

  deactivate: ->
    @editorSubscription?.off()
    @editorSubscription = null

    @providers.forEach (provider) =>
      @autocomplete.unregisterProvider provider

    @providers = []

  registerProviders: ->
    @editorSubscription = atom.workspaceView.eachEditorView (editorView) =>
      if editorView.attached and not editorView.mini
        provider = new ExampleProvider editorView.editor
        @autocomplete.registerProviderForEditorView provider, editorView.editor
        @providers.push provider
