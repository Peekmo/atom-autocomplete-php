GotoManager = require "./goto/goto-manager.coffee"
TooltipManager = require "./tooltip/tooltip-manager.coffee"
AnnotationManager = require "./annotation/annotation-manager.coffee"
AutocompletionManager = require "./autocompletion/autocompletion-manager.coffee"
StatusInProgress = require "./services/status-in-progress.coffee"
config = require './config.coffee'
proxy = require './services/php-proxy.coffee'
parser = require './services/php-file-parser.coffee'
plugins = require './services/plugin-manager.coffee'

module.exports =
    config:
        binComposer:
            title: 'Command to use composer'
            description: 'This plugin depends on composer in order to work. Specify the path
             to your composer bin (e.g : bin/composer, composer.phar, composer)'
            type: 'string'
            default: '/usr/local/bin/composer'
            order: 1

        binPhp:
            title: 'Command php'
            description: 'This plugin use php CLI in order to work. Please specify your php
             command ("php" on UNIX systems)'
            type: 'string'
            default: 'php'
            order: 2

        autoloadPaths:
            title: 'Autoloader file'
            description: 'Relative path to the files of autoload.php from composer (or an other one). You can specify multiple
             paths (comma separated) if you have different paths for some projects.'
            type: 'array'
            default: ['vendor/autoload.php', 'autoload.php']
            order: 3

        classMapFiles:
            title: 'Classmap files'
            description: 'Relative path to the files that contains a classmap (array with "className" => "fileName"). By default
             on composer it\'s vendor/composer/autoload_classmap.php'
            type: 'array'
            default: ['vendor/composer/autoload_classmap.php', 'autoload/ezp_kernel.php']
            order: 4

        insertNewlinesForUseStatements:
            title: 'Insert newlines for use statements.'
            description: 'When enabled, the plugin will add additional newlines before or after an automatically added
                use statement when it can\'t add them nicely to an existing group. This results in more cleanly
                separated use statements but will create additional vertical whitespace.'
            type: 'boolean'
            default: false
            order: 5

        verboseErrors:
            title: 'Errors on file saving showed'
            description: 'When enabled, you\'ll have a notification once an error occured on autocomplete. Otherwise, the message will just be logged in developer console'
            type: 'boolean'
            default: false
            order: 6

    activate: ->
        config.testConfig()
        config.init()

        @autocompletionManager = new AutocompletionManager()
        @autocompletionManager.init()

        @gotoManager = new GotoManager()
        @gotoManager.init()

        @tooltipManager = new TooltipManager()
        @tooltipManager.init()

        @annotationManager = new AnnotationManager()
        @annotationManager.init()

        proxy.init()

    deactivate: ->
        @gotoManager.deactivate()
        @tooltipManager.deactivate()
        @annotationManager.deactivate()
        @autocompletionManager.deactivate()

    consumeStatusBar: (statusBar) ->
        config.statusInProgress.initialize(statusBar)
        config.statusInProgress.attach()

    consumePlugin: (plugin) ->
        plugins.plugins.push(plugin)

    provideAutocompleteTools: ->
        @services =
            proxy: proxy
            parser: parser

        return @services

    getProvider: ->
        return @autocompletionManager.getProviders()
