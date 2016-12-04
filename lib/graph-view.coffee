{$, $$$, ScrollView}  = require 'atom-space-pen-views'
vis = require 'vis'

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

    display: (data)->
      console.log("Received data", data)
      if @network
        @network = @network.destroy()
      else
        @graphDiv = document.createElement("div")
        @html $ @graphDiv

      # create an array with nodes
      # nodes should be objects with id and label
      nodes = new vis.DataSet(data.nodes)

      #create an array with edges
      # Edges should be objects from and to
      edges = new vis.DataSet(data.edges)

      #create a network
      graphData =
        nodes: nodes,
        edges: edges

      # TODO options should probably be a default. I like the idea of still allowing
      # the clojure code to specify optiosn here as it could override some of the settings
      # if needed. Pushing more of the functionality to Clojure might be good.
      options = data.options || DEFAULT_OPTIONS

      # Capture events that were passed. This is not a standard visjs key
      events = options.events
      delete options.events
      console.log "Options", options

      @network = new vis.Network(@graphDiv, graphData, options);

      # TODO add doublc click handler. Should do following
      # - Make call to repl to extract needed data.
      # - Data returned should be args and return value and file and line number
      # - Display an inline view at that file and line.
      # - Def buttons should be tied back to a handler with a sayid id.
      # - On click of def button based on sayid id define vars for each of the args.

      # TODO won't need this explicitly anymore but leaving it in would be handy.
      # Handle any event handlers
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
      @name

    showLoading: ->
      @html $$$ ->
        @div class: 'atom-html-spinner', 'Loading your visualization\u2026'
