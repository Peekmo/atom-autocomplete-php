{WorkspaceView} = require 'atom'
PeekmoPhpAtomAutocomplete = require '../lib/peekmo-php-atom-autocomplete'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "PeekmoPhpAtomAutocomplete", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('peekmo-php-atom-autocomplete')

  describe "when the peekmo-php-atom-autocomplete:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.peekmo-php-atom-autocomplete')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch atom.workspaceView.element, 'peekmo-php-atom-autocomplete:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        
