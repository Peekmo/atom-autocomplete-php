PhpClassProvider = require "./php-class-provider.coffee"
PhpStaticsProvider = require "./php-statics-provider.coffee"

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
        classesProvider = new PhpClassProvider editorView
        @autocomplete.registerProviderForEditorView classesProvider, editorView
        @providers.push classesProvider

        staticsProvider = new PhpStaticsProvider editorView
        @autocomplete.registerProviderForEditorView staticsProvider, editorView
        @providers.push staticsProvider
