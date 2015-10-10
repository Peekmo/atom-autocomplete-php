{Disposable} = require 'atom'

Popover = require './popover'

module.exports =

class AttachedPopover extends Disposable
    ###
        NOTE: The reason we do not use Atom's native tooltip is because it is attached to an element, which caused
        strange problems such as tickets #107 and #72. This implementation uses the same CSS classes and transitions but
        handles the displaying manually as we don't want to attach/detach, we only want to temporarily display a popover
        on mouseover.
    ###
    popover: null
    timeoutId: null
    elementToAttachTo: null

    ###*
     * Constructor.
     *
     * @param {HTMLElement} elementToAttachTo The element to show the popover over.
     * @param {int}         delay             How long the mouse has to hover over the elment before the popover shows
     *                                        up (in miliiseconds).
    ###
    constructor: (@elementToAttachTo, delay = 500) ->
        @$ = require 'jquery'
        
        @popover = new Popover()

        super @destructor

    ###*
     * Destructor.
     *
    ###
    destructor: () ->
        if @timeoutId
            clearTimeout(@timeoutId)
            @timeoutId = null

        @popover.dispose()

    ###*
     * Shows the popover with the specified text.
     *
     * @param {string} text       The text to display.
     * @param {int}    fadeInTime The amount of time to take to fade in the tooltip.
    ###
    show: (text, fadeInTime = 100) ->
        coordinates = @elementToAttachTo.getBoundingClientRect();

        centerOffset = ((coordinates.right - coordinates.left) / 2)

        x = coordinates.left - (@$(@popover.getElement()).width() / 2) + centerOffset
        y = coordinates.bottom

        @popover.show(text, x, y, fadeInTime)

    ###*
     * Shows the popover with the specified text after the specified delay (in miliiseconds). Calling this method
     * multiple times will cancel previous show requests and restart.
     *
     * @param {string} text       The text to display.
     * @param {int}    delay      The delay before the tooltip shows up (in milliseconds).
     * @param {int}    fadeInTime The amount of time to take to fade in the tooltip.
    ###
    showAfter: (text, delay, fadeInTime = 100) ->
        @timeoutId = setTimeout(() =>
            @show(text, fadeInTime)
        , delay)

    ###*
     * Hides the tooltip, if it is displayed.
    ###
    hide: () ->
        @popover.hide()
