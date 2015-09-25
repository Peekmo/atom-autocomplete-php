{Point} = require 'atom'
{TextEditor} = require 'atom'

AbstractProvider = require './abstract-provider'

module.exports =

class FunctionProvider extends AbstractProvider
    hoverEventSelectors: '.function-call'

    ###*
     * Retrieves a tooltip for the word given.
     * @param  {TextEditor} editor         TextEditor to search for namespace of term.
     * @param  {string}     term           Term to search for.
     * @param  {Point}      bufferPosition The cursor location the term is at.
    ###
    getTooltipForWord: (editor, term, bufferPosition) ->
        value = @getMethodForTerm(editor, term, bufferPosition)

        if not value
            return

        description = ""

        # Show the method's signature.
        description += '<div style="margin-top: -1em; margin-bottom: -1em;">'
        returnType = (if value.args.return then value.args.return else '')

        description += "<p><div>"
        description += returnType + ' <strong>' + term + '</strong>' + '('

        if value.args.parameters.length > 0
            description += value.args.parameters.join(', ');

        if value.args.optionals.length > 0
            description += '['

            if value.args.parameters.length > 0
                description += ', '

            description += value.args.optionals.join(', ')
            description += ']'

        description += ')'
        description += '</div></p>'

        # Show the summary (short description) of the method.
        description += '<p><div>'
        description +=     (if value.args.descriptions.short then value.args.descriptions.short else '(No documentation available)')
        description += '</p></div>'

        # Show the (long) description of the method.
        if value.args.descriptions.long?.length > 0
            description += "<p>"
            description +=     "<div>Description:</div>"
            description +=     "<div style='padding-left: 1em;'>" + value.args.descriptions.long + "</div>"
            description += "</p>"

        # Show the parameters the method has.
        parametersDescription = ""

        for param in value.args.parameters
            parametersDescription += "<div>"
            parametersDescription += "• <strong>" + param + "</strong>"
            parametersDescription += "</div>"

        for param in value.args.optionals
            parametersDescription += "<div>"
            parametersDescription += "• <strong>" + param + "</strong>"
            parametersDescription += "</div>"

        if value.args.parameters.length > 0 or value.args.optionals.length > 0
            description += "<p>"
            description +=     "<div>Parameters:</div>"
            description +=     "<div style='padding-left: 1em;'>" + parametersDescription + "</div>"
            description += "</p>"

        if value.args.return
            description += "<p>"
            description +=     "<div>Returns:</div>"
            description +=     "<div style='padding-left: 1em;'>" + value.args.return + "</div>"
            description += "</p>"

        # Show an overview of the exceptions the method can throw.
        throwsDescription = ""

        for exceptionType,thrownWhenDescription of value.args.throws
            throwsDescription += "<div>"
            throwsDescription += "• <strong>" + exceptionType + "</strong>"

            if thrownWhenDescription
                throwsDescription += ' ' + thrownWhenDescription

            throwsDescription += "</div>"

        if throwsDescription.length > 0
            description += "<p>"
            description +=     "<div>Throws:</div>"
            description +=     "<div style='margin-left: 1em;'>" + throwsDescription + "</div>"
            description += "</p>"

        description += "</div>"

        return description

    ###*
     * Retrieves information about the method described by the specified term.
     * @param  {TextEditor} editor          TextEditor to search for namespace of term.
     * @param  {string}     term            Term to search for.
     * @param  {Point}      bufferPosition  The cursor location the term is at.
     * @param  {Object}     calledClass     Information about the called class (optional).
    ###
    getMethodForTerm: (editor, term, bufferPosition, calledClass) ->
        if not calledClass
            calledClass = @parser.getCalledClass(editor, term, bufferPosition)

        if not calledClass
            return

        proxy = require '../services/php-proxy.coffee'
        methods = proxy.methods(calledClass)

        if not methods
            return

        if methods.error? and methods.error != ''
            atom.notifications.addError('Failed to get methods for ' + calledClass, {
                'detail': methods.error.message
            })
            return

        if methods.names.indexOf(term) == -1
            return
        value = methods.values[term]

        # If there are multiple matches, just select the first method.
        if value instanceof Array
            for val in value
                if val.isMethod
                    value = val
                    break

        return value
