AbstractGoto = require './abstract-goto'

module.exports =
class GotoClass extends AbstractGoto

    hoverEventSelectors: '.meta.inherited-class, .support.namespace, .support.class, .comment-clickable .region'
    clickEventSelectors: '.meta.inherited-class, .support.namespace, .support.class'
    gotoRegex: /^\\?[A-Z][A-za-z0-9_]*(\\[A-Z][A-Za-z0-9_])*$/

    ###*
     * Goto the class from the term given.
     * @param  {TextEditor} editor  TextEditor to search for namespace of term.
     * @param  {string}     term    Term to search for.
    ###
    gotoFromWord: (editor, term) ->
        proxy = require '../services/php-proxy.coffee'
        if term == undefined || term.indexOf('$') == 0
            return

        if term.indexOf('\\') == 0
            term = term.substring(1)

        namespaceTerm = @parser.findUseForClass(editor, term)
        if namespaceTerm != undefined
            term = namespaceTerm

        classMap = proxy.autoloadClassMap()
        classMapArray = [];
        listViewArray = [];

        for key,value of classMap
            classMapArray.push(key)

        matches = @fuzzaldrin.filter classMapArray, term

        @manager.addBackTrack(editor.getPath(), editor.getCursorBufferPosition())
        if matches[0] == term || matches.length == 1
            atom.workspace.open(classMap[matches[0]], {
                searchAllPanes: true
            })
        else
            for key,value of matches
                listViewArray.push({
                    item: value,
                    file: classMap[value]
                })

            @selectView.setItems(listViewArray)
            @selectView.show()

    ###*
     * Gets the correct selector when a class or namespace is clicked.
     * @param  {jQuery.Event}  event  A jQuery event.
     * @return {object|null}          A selector to be used with jQuery.
    ###
    getSelector: (event) ->
        selector = event.currentTarget

        if @$(selector).hasClass('builtin') || @$(selector).children('.builtin').length > 0
            return null

        if @$(selector).parent().hasClass('function argument') ||
           @$(selector).prev().hasClass('namespace') && @$(selector).hasClass('class') ||
           @$(selector).next().hasClass('class')
            return @$(selector).parent().children('.namespace, .class:not(.operator):not(.constant)')

        return selector

    ###*
     * Goes through all the lines within the editor looking for classes within
     * comments. More specifically if they have @var, @param or @return prefixed.
     * @param  {TextEditor} editor The editor to search through
    ###
    registerMarkers: (editor) ->
        text = editor.getText()
        rows = text.split('\n')
        for key,row of rows
            regex = /@param|@var|@return|@throws|@see/gi
            if regex.test(row)
                @addMarkerToCommentLine row.split(' '), parseInt(key), editor, true

    ###*
     * Analyses the words array given for any classes and then creates a marker
     * for them.
     * @param {array} words             The array of words to check.
     * @param {int} rowIndex            The current row the words are on within the editor.
     * @param {TextEditor} editor       The editor the words are from.
     * @param {bool} shouldBreak        Flag to say whether the search should break after finding 1 class.
     * @param {int} currentIndex = 0    The current column index the search is on.
     * @param {int} offset       = 0    Any offset that should be applied when creating the marker.
    ###
    addMarkerToCommentLine: (words, rowIndex, editor, shouldBreak, currentIndex = 0, offset = 0) ->
        for key,value of words
            regex = /^\\?([A-Za-z0-9_]+)\\?([A-Za-zA-Z_\\]*)?/g
            keywordRegex = /^(array|object|bool|string|static|null|boolean|void|int|integer|mixed|callable)$/gi
            if regex.test(value) && keywordRegex.test(value) == false
                if value.includes('|')
                    @addMarkerToCommentLine value.split('|'), rowIndex, editor, false, currentIndex, parseInt(key)
                else
                    range = [[rowIndex, currentIndex + parseInt(key) + offset], [rowIndex, currentIndex + parseInt(key) + value.length + offset]];
                    marker = editor.markBufferRange(range)
                    markerProperties =
                        term: value
                    marker.setProperties markerProperties
                    options =
                        type: 'highlight'
                        class: 'comment-clickable comment'

                    editor.decorateMarker marker, options
                    if @allMarkers[editor.getLongTitle()] == undefined
                        @allMarkers[editor.getLongTitle()] = []
                    @allMarkers[editor.getLongTitle()].push(marker)
                if shouldBreak == true
                    break
            currentIndex += value.length;
