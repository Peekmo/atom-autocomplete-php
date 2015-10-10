{Disposable} = require 'atom'

module.exports =

class Popover extends Disposable
    ###
        NOTE: The reason we do not use Atom's native tooltip is because it is attached to an element, which caused
        strange problems such as tickets #107 and #72. This implementation uses the same CSS classes and transitions but
        handles the displaying manually as we don't want to attach/detach, we only want to temporarily display a popover
        on mouseover.
    ###
    element: null
    elementToAttachTo: null

    ###*
     * Constructor.
     *
     * @param {HTMLElement} elementToAttachTo The element to show the popover over.
    ###
    constructor: (@elementToAttachTo) ->
        @$ = require 'jquery'

        @element = document.createElement('div')
        @element.id = 'php-atom-autocomplete-popover'
        @element.className = 'tooltip bottom fade'
        @element.innerHTML = "<div class='tooltip-arrow'></div><div class='tooltip-inner'></div>"

        document.body.appendChild(@element)

        super @destructor

    ###*
     * Destructor.
     *
    ###
    destructor: () ->
        @hide()
        document.body.removeChild(@element)

    ###*
     * Shows a tooltip containing the documentation of the specified element located at the specified location.
     *
     * @param {string} text       The text to display.
     * @param {int}    fadeInTime The amount of time to take to fade in the tooltip.
    ###
    show: (text, fadeInTime = 100) ->
        coordinates = @elementToAttachTo.getBoundingClientRect();

        centerOffset = ((coordinates.right - coordinates.left) / 2)

        @$('.tooltip-inner', @element).html(
            '<div class="php-atom-autocomplete-popover-wrapper">' + text.replace(/\n/g, '<br/>') + '</div>'
        )

        @$(@element).css('left', (coordinates.left - (@$(@element).width() / 2) + centerOffset) + 'px')
        @$(@element).css('top', (coordinates.bottom) + 'px')

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
