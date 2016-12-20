{$, $$$, ScrollView}  = require 'atom-space-pen-views'
vis = require 'vis'

# TODO how do we make jQuery available for qtip without doing this
jQuery = require('jquery')
window.jQuery = jQuery
qtip = require 'qtip2'

PROTOCOL = "proto-repl-sayid:"
NAME = "Sayid Call Graph"

DEFAULT_OPTIONS =
  layout:
    hierarchical:
      direction: "UD",
      sortMethod: "directed"
  physics:
    hierarchicalRepulsion:
      nodeDistance: 150,
      springConstant: 0.4
  edges:
    arrows:
      to:
        enabled: true

module.exports =
  class GraphView extends ScrollView
    network: null
    graphDiv: null

    atom.deserializers.add(this)

    @deserialize: (state) ->
      new GraphView()

    @content: ->
      @div class: 'proto-repl-sayid-graph native-key-bindings', tabindex: -1

    constructor: () ->
      super
      @showLoading()

    serialize: ->
      deserializer : 'GraphView'

    displayNodeInlineData: (id)->
      console.log("Node clicked", id)
      window.protoRepl.executeCode "(proto-repl-sayid.core/retrieve-node-inline-data #{id})",
        displayInRepl: false,
        resultHandler: (result)->
          console.log("Retrieved inline data", result)
          if result.error
            console.error(result.error)
            atom.notifications.addError "Unable to retrieve node data. See console error message", dismissable: true
          else
            inlineData = window.protoRepl.parseEdn(result.value)
            # TODO finish this


    display: (data)->
      console.log("Received data of #{data.nodes.length} nodes and #{data.edges.length} edges")
      # Fail out early if there is no data to display
      if !data.nodes
        atom.notifications.addWarning "No data was captured for display", dismissable: true
        return

      if @network
        @network = @network.destroy()
      else
        @graphDiv = document.createElement("div")
        @html $ @graphDiv


      # create an array with nodes
      # nodes should be objects with id and label
      nodes = new vis.DataSet(data.nodes)

      # Edges should be objects from and to
      edges = new vis.DataSet(data.edges)

      #create a network
      graphData =
        nodes: nodes,
        edges: edges

      # Capture events that were passed. This is not a standard visjs key
      options = data.options || DEFAULT_OPTIONS
      events = options.events
      delete options.events

      @network = new vis.Network(@graphDiv, graphData, options);

      # TODO add doublc click handler. Should do following
      # - Make call to repl to extract needed data.
      # - Data returned should be args and return value and file and line number
      # - Display an inline view at that file and line.
      # - Def buttons should be tied back to a handler with a sayid id.
      # - On click of def button based on sayid id define vars for each of the args.
      @network.on "doubleClick", (eventData)=>
        console.log "Double click event data", eventData
        if eventData.nodes && eventData.nodes[0]
          @displayNodeInlineData(eventData.nodes[0])

      # TODO temporarily here while trying to get popups to work
      @network.on "showPopup", (eventData)->
        console.log("Popup", eventData)

      # Handle any event handlers specified via options
      if events
        for event, handler of events
          @network.on event, (eventData)->
            dataToPass =
              edges: (edges.get(id) for id in eventData.edges),
              nodes: (nodes.get(id) for id in eventData.nodes),

            code = "(#{handler} #{protoRepl.jsToEdn(dataToPass)})"
            protoRepl.executeCode code,
              displayInRepl: false,
              resultHandler: (result)->
                if result.error
                  console.error("Failure to execute handler #{handler}: #{result.error}")
                  window.protoRepl.stderr("Failure to execute handler #{handler}: #{result.error}")

    getTitle: ->
      NAME

    showLoading: ->
      @html $$$ ->
        @div class: 'atom-html-spinner', 'Loading your visualization\u2026'
