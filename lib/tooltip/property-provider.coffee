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
        value = @parser.getMemberContext(editor, term, bufferPosition)

        if not value
            return

        accessModifier = ''
        returnType = if value.args.return then value.args.return else 'mixed'

        if value.isPublic
            accessModifier = 'public'

        else if value.isProtected
            accessModifier = 'protected'

        else
            accessModifier = 'private'

        # Create a useful description to show in the tooltip.
        description = ''

        description += "<p><div>"
        description += accessModifier + ' ' + returnType + '<strong>' + ' $' + term + '</strong>'
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

        if value.args.return
            description += '<div class="section">'
            description +=     "<h4>Type</h4>"
            description +=     "<div>" + value.args.return + "</div>"
            description += "</div>"

        return description
