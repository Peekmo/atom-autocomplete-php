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
        value = @parser.getMethodContext(editor, term, bufferPosition)

        if not value
            return

        description = ""

        # Show the method's signature.
        accessModifier = ''
        returnType = (if value.args.return then value.args.return else '')

        if value.isPublic
            accessModifier = 'public'

        else if value.isProtected
            accessModifier = 'protected'

        else
            accessModifier = 'private'

        description += '<div style="margin-top: -1em; margin-bottom: -1em;">'

        description += "<p><div>"
        description += accessModifier + ' ' + returnType + ' <strong>' + term + '</strong>' + '('

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

        # Show the summary (short description).
        description += '<p><div>'
        description +=     (if value.args.descriptions.short then value.args.descriptions.short else '(No documentation available)')
        description += '</p></div>'

        # Show the (long) description.
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
