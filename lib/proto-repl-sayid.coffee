GraphView = require './graph-view'
TreeView = require './tree-view'
{CompositeDisposable} = require 'atom'
url = require 'url'

PROTOCOL = "proto-repl-sayid:"

module.exports = ProtoReplSayid =
  subscriptions: null

  graphView: null

  # Boolean indicates if this extension has been registered with Proto REPL
  registeredExtension: false

  registerExtension: ->
    unless @registeredExtension
      if window.protoRepl
        protoRepl.registerCodeExecutionExtension("proto-repl-sayid", (data)=>
          @display(data))
        @registeredExtension = true

  display: (data)->
    if @graphView
      @graphView.display(data)
    else
      atom.workspace.open("#{PROTOCOL}//", split: 'right', searchAllPanes: true).done (view)=>
        @graphView = view
        @graphView.display(data)

  # Helper for defining a command that calls a function on a namespace.
  addCommand: (name, ns, fn)->
    @subscriptions.add atom.commands.add 'atom-workspace', "proto-repl-sayid:#{name}": =>
      window.protoRepl.executeCode("(do (require '#{ns}) (#{ns}/#{fn}))")

  activate: (state) ->
    console.log("Proto REPL Sayid activated")
    @registerExtension()

    @subscriptions = new CompositeDisposable
    @addCommand("show-traced-namespaces", "proto-repl-sayid.core", "show-traced-namespaces")
    @addCommand("trace-project-namespaces", "proto-repl-sayid.core", "trace-all-namespaces-in-project")
    @addCommand("reset-trace", "com.billpiel.sayid.core", "ws-reset!")
    @addCommand("clear-captured", "com.billpiel.sayid.core", "ws-clear-log!")
    @addCommand("display-last-captured", "proto-repl-sayid.core", "display-last-captured")
    @addCommand("display-all-captured", "proto-repl-sayid.core", "display-all-captured")

    # TODO temporary to make testing tree easier
    @subscriptions.add atom.commands.add 'atom-workspace', "proto-repl-sayid:show-tree": =>
      @display({nodes: [], edges: []})


    atom.workspace.onDidDestroyPaneItem (event)=>
      item = event.item
      pane = event.pane
      if item instanceof TreeView
        console.log "Graph view was closed"
        @graphView = null

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        console.log error
        return

      return unless protocol == PROTOCOL
      new TreeView()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {}
