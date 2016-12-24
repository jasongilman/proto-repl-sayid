TreeView = require './tree-view'
{CompositeDisposable} = require 'atom'
url = require 'url'

PROTOCOL = "proto-repl-sayid:"
URI = "#{PROTOCOL}//"

module.exports = ProtoReplSayid =
  config:
    maxDisplayedNameSize:
      description: "The maximum size of a displayed name in the graph."
      type: "number"
      default: 28

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

  # Opens the view without displaying data
  toggle: (f=null)->
    if @treeView
      pane = atom.workspace.paneForItem(@treeView)
      window.thePane = pane
      pane.activateItemForURI(URI)
      if f
        f()
    else
      atom.workspace.open(URI, split: 'right', searchAllPanes: true).done (view)=>
        @treeView = view
        if f
          f()

  # Displays received data in the view
  display: (data)->
    @toggle =>
      @treeView.display(data)

  # Helper for defining a command that calls a function on a namespace.
  addCommand: (name, ns, fn)->
    @subscriptions.add atom.commands.add 'atom-workspace', "proto-repl-sayid:#{name}": =>
      window.protoRepl.executeCode("(do (require '#{ns}) (#{ns}/#{fn}))")

  activate: (state) ->
    console.log("Proto REPL Sayid activated")
    @registerExtension()

    @subscriptions = new CompositeDisposable

    # Opens up the display
    @subscriptions.add atom.commands.add 'atom-workspace', "proto-repl-sayid:toggle": =>
      @toggle()

    # Displays traced namespaces in the REPL
    # TODO this would be better to do in the GUI somehow
    @addCommand("show-traced-namespaces", "proto-repl-sayid.core", "show-traced-namespaces")

    # Starts tracing all project namespaces.
    @addCommand("trace-project-namespaces", "proto-repl-sayid.core", "trace-all-project-namespaces")

    # Untraces everything
    @addCommand("reset-trace", "com.billpiel.sayid.core", "ws-reset!")

    # Clears out traced data.
    @addCommand("clear-captured", "com.billpiel.sayid.core", "ws-clear-log!")

    # Displays data that was traced in the view.
    @subscriptions.add atom.commands.add 'atom-workspace', "proto-repl-sayid:display-last-captured": =>
      window.protoRepl.executeCode("(do (require 'proto-repl-sayid.core)
                                        (proto-repl-sayid.core/display-last-captured
                                         #{atom.config.get("proto-repl-sayid.maxDisplayedNameSize")}))")

    # The tab was closed
    atom.workspace.onDidDestroyPaneItem (event)=>
      item = event.item
      pane = event.pane
      if item instanceof TreeView
        console.log "Tree view was closed"
        @treeView = null

    # Add an opener for the view
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
