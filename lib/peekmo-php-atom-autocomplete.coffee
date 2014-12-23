PhpClassProvider = require "./php-class-provider.coffee"

module.exports =
  configDefaults:
    fileWhitelist: "*.php"
  editorSubscription: null
  autocomplete: null
  providers: []

  activate: ->
    atom.packages.activatePackage("autocomplete-plus")
      .then (pkg) =>
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
        provider = new PhpClassProvider editorView
        @autocomplete.registerProviderForEditorView provider, editorView
        @providers.push provider
