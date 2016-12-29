{$, View, TextEditorView} = require 'atom-space-pen-views'

# Defines a view for adding or removing namespaces matched by a pattern.
module.exports =
  class FilterView extends View
    @content: ->
      @div class: "proto-repl-sayid proto-repl-sayid-filter-dialog", =>
        @h3 "Filter Namespaces", class: "icon icon-clobe"
        @div class: "block", =>
          @label "Enter a namespace pattern. * will match 0 or more characters. Press esc to cancel."
          @subview "nsPattern", new TextEditorView(mini: true, attributes: tabindex: 1)

    # * `confirmCallback` The {Function} execute on confirm.
    constructor: (@confirmCallback)->
      super

    initialize: ->
      atom.commands.add @element,
        "core:confirm": => @onConfirm()
        "core:cancel": => @onCancel()

    show: ->
      @panel ?= atom.workspace.addModalPanel(item: this, visible: false)
      @storeActiveElement()
      @resetEditors()
      @panel.show()
      @nsPattern.focus()

    onConfirm: ->
      @confirmCallback? @nsPattern.getText()
      @panel?.hide()

    onCancel: ->
      @panel?.hide()
      @restoreFocus()

    storeActiveElement: ->
      @previousActiveElement = $(document.activeElement)

    restoreFocus: ->
      @previousActiveElement?.focus()

    resetEditors: ->
      @nsPattern.setText('')
