AbstractProvider = require './abstract-provider'

module.exports =

# Provides annotations for overriding property.
class FunctionProvider extends AbstractProvider
    regex: /(\s*(?:public|protected|private)\s+\$)(\w+)\s+/g

    ###*
     * @inheritdoc
    ###
    extractAnnotationInfo: (editor, row, rowText, match) ->
        currentClass = @parser.getFullClassName(editor)

        propertyName = match[2]

        context = @parser.getMemberContext(editor, propertyName, null, currentClass)

        if not context or not context.override
            return null

        # NOTE: We deliberately show the declaring class here, not the structure (which could be a trait).
        return {
            lineNumberClass : 'override'
            tooltipText     : 'Overrides property from ' + context.override.declaringClass.name
            extraData       : context.override
        }

    ###*
     * @inheritdoc
    ###
    handleMouseClick: (event, editor, annotationInfo) ->
        atom.workspace.open(annotationInfo.extraData.declaringStructure.filename, {
            # initialLine    : annotationInfo.startLine - 1,
            searchAllPanes : true
        })
