{Disposable} = require 'atom'

module.exports =

class Popover extends Disposable
    element: null

    ###*
     * Constructor.
    ###
    constructor: () ->
        @$ = require 'jquery'

        @element = document.createElement('div')
        @element.id = 'php-atom-autocomplete-popover'
        @element.className = 'tooltip bottom fade'
        @element.innerHTML = "<div class='tooltip-arrow'></div><div class='tooltip-inner'></div>"

        document.body.appendChild(@element)

        super @destructor

    ###*
     * Destructor.
    ###
    destructor: () ->
        @hide()
        document.body.removeChild(@element)

    ###*
     * Retrieves the HTML element containing the popover.
     *
     * @return {HTMLElement}
    ###
    getElement: () ->
        return @element

    ###*
     * Shows a popover at the specified location with the specified text and fade in time.
     *
     * @param {string} text       The text to display.
     * @param {int}    x          The X coordinate to show the popover at (left).
     * @param {int}    y          The Y coordinate to show the popover at (top).
     * @param {int}    fadeInTime The amount of time to take to fade in the tooltip.
    ###
    show: (text, x, y, fadeInTime = 100) ->
        @$('.tooltip-inner', @element).html(
            '<div class="php-atom-autocomplete-popover-wrapper">' + text.replace(/\n/g, '<br/>') + '</div>'
        )

        @$(@element).css('left', x + 'px')
        @$(@element).css('top', y + 'px')

        @$(@element).addClass('in')
        @$(@element).css('opacity', 100)
        @$(@element).css('display', 'block')

    ###*
     * Hides the tooltip, if it is displayed.
    ###
    hide: () ->
        @$(@element).removeClass('in')
        @$(@element).css('opacity', 0)
        @$(@element).css('display', 'none')
