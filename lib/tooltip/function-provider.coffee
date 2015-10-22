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
        value = @parser.getMemberContext(editor, term, bufferPosition)

        if not value
            return

        description = ""

        # Show the method's signature.
        accessModifier = ''
        returnType = ''

        if value.args.return?.type
            returnType = value.args.return.type

        if value.isPublic
            accessModifier = 'public'

        else if value.isProtected
            accessModifier = 'protected'

        else
            accessModifier = 'private'

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
        description += '<div>'
        description +=     (if value.args.descriptions.short then value.args.descriptions.short else '(No documentation available)')
        description += '</div>'

        # Show the (long) description.
        if value.args.descriptions.long?.length > 0
            description += '<div class="section">'
            description +=     "<h4>Description</h4>"
            description +=     "<div>" + value.args.descriptions.long + "</div>"
            description += "</div>"

        # Show the parameters the method has.
        parametersDescription = ""

        for param,info of value.args.docParameters
            parametersDescription += "<tr>"

            parametersDescription += "<td>•&nbsp;<strong>"

            if param in value.args.optionals
                parametersDescription += "[" + param + "]"

            else
                parametersDescription += param

            parametersDescription += "</strong></td>"

            parametersDescription += "<td>" + (if info.type then info.type else '&nbsp;') + '</td>'
            parametersDescription += "<td>" + (if info.description then info.description else '&nbsp;') + '</td>'

            parametersDescription += "</tr>"

        if parametersDescription.length > 0
            description += '<div class="section">'
            description +=     "<h4>Parameters</h4>"
            description +=     "<div><table>" + parametersDescription + "</table></div>"
            description += "</div>"

        if value.args.return?.type
            returnValue = '<strong>' + value.args.return.type + '</strong>'

            if value.args.return.description
                returnValue += ' ' + value.args.return.description

            description += '<div class="section">'
            description +=     "<h4>Returns</h4>"
            description +=     "<div>" + returnValue + "</div>"
            description += "</div>"

        # Show an overview of the exceptions the method can throw.
        throwsDescription = ""

        for exceptionType,thrownWhenDescription of value.args.throws
            throwsDescription += "<div>"
            throwsDescription += "• <strong>" + exceptionType + "</strong>"

            if thrownWhenDescription
                throwsDescription += ' ' + thrownWhenDescription

            throwsDescription += "</div>"

        if throwsDescription.length > 0
            description += '<div class="section">'
            description +=     "<h4>Throws</h4>"
            description +=     "<div>" + throwsDescription + "</div>"
            description += "</div>"

        return description
