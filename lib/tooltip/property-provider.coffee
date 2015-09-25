{TextEditor} = require 'atom'

AbstractProvider = require './abstract-provider'

module.exports =

class PropertyProvider extends AbstractProvider
    hoverEventSelectors: '.property'

    ###*
     * Retrieves a tooltip for the word given.
     * @param  {TextEditor} editor         TextEditor to search for namespace of term.
     * @param  {string}     term           Term to search for.
     * @param  {Point}      bufferPosition The cursor location the term is at.
    ###
    getTooltipForWord: (editor, term, bufferPosition) ->
        value = @getPropertyForTerm(editor, term, bufferPosition)

        if not value
            return

        # Create a useful description to show in the tooltip.
        returnType = if value.args.return then value.args.return else 'mixed'

        description = ''

        if value.isPublic
            description += 'public'

        else if value.isProtected
            description += 'protected'

        else
            description += 'private'

        description += ' ' + returnType + '<strong>' + ' $' + term + '</strong>';
        description += "<br/><br/>"

        if value.args.descriptions.short
            description += value.args.descriptions.short

        else
            description += '(No documentation available)'

        return description

    ###*
     * Retrieves information about the property described by the specified term.
     * @param  {TextEditor} editor          TextEditor to search for namespace of term.
     * @param  {string}     term            Term to search for.
     * @param  {Point}      bufferPosition  The cursor location the term is at.
     * @param  {Object}     calledClass     Information about the called class (optional).
    ###
    getPropertyForTerm: (editor, term, bufferPosition, calledClass) ->
        if not calledClass
            calledClass = @parser.getCalledClass(editor, term, bufferPosition)

        if not calledClass
            return

        proxy = require '../services/php-proxy.coffee'
        methodsAndProperties = proxy.methods(calledClass)
        if not methodsAndProperties.names?
            return

        if methodsAndProperties.names.indexOf(term) == -1
            return
        value = methodsAndProperties.values[term]

        if value instanceof Array
            for val in value
                if !val.isMethod
                    value = val
                    break

        return value
