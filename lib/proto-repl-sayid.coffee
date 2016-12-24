TreeView = require './tree-view'
{CompositeDisposable} = require 'atom'
url = require 'url'

PROTOCOL = "proto-repl-sayid:"

module.exports = ProtoReplSayid =
  config:
    maxDisplayedNameSize:
      description: "The maximum size of a displayed name in the graph."
      type: "number"
      default: 32


  subscriptions: null

  treeView: null

  # Boolean indicates if this extension has been registered with Proto REPL
  registeredExtension: false

  registerExtension: ->
    unless @registeredExtension
      if window.protoRepl
        protoRepl.registerCodeExecutionExtension("proto-repl-sayid", (data)=>
          @display(data))
        @registeredExtension = true

  display: (data)->
    if @treeView
      @treeView.display(data)
    else
      atom.workspace.open("#{PROTOCOL}//", split: 'right', searchAllPanes: true).done (view)=>
        @treeView = view
        @treeView.display(data)

  # Helper for defining a command that calls a function on a namespace.
  addCommand: (name, ns, fn)->
    @subscriptions.add atom.commands.add 'atom-workspace', "proto-repl-sayid:#{name}": =>
      window.protoRepl.executeCode("(do (require '#{ns}) (#{ns}/#{fn}))")

  activate: (state) ->
    console.log("Proto REPL Sayid activated")
    @registerExtension()

    @subscriptions = new CompositeDisposable
    @addCommand("show-traced-namespaces", "proto-repl-sayid.core", "show-traced-namespaces")
    @addCommand("trace-project-namespaces", "proto-repl-sayid.core", "trace-all-project-namespaces")
    @addCommand("reset-trace", "com.billpiel.sayid.core", "ws-reset!")
    @addCommand("clear-captured", "com.billpiel.sayid.core", "ws-clear-log!")

    @subscriptions.add atom.commands.add 'atom-workspace', "proto-repl-sayid:display-last-captured": =>
      window.protoRepl.executeCode("(do (require 'proto-repl-sayid.core)
                                        (proto-repl-sayid.core/display-last-captured
                                         #{atom.config.get("proto-repl-sayid.maxDisplayedNameSize")}))")

    atom.workspace.onDidDestroyPaneItem (event)=>
      item = event.item
      pane = event.pane
      if item instanceof TreeView
        console.log "Tree view was closed"
        @treeView = null

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
