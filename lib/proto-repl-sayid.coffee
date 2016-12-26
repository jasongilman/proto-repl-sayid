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
      toolBarButtons = {}
      toolBarButtons["Trace Project Namespaces"] = => @traceProjectNamespaces()
      toolBarButtons["Untrace All"] = => @untraceAll()
      toolBarButtons["Clear Captured"] = => @clearCaptured()
      toolBarButtons["Display Last Captured"] = => @displayLastCaptured()

      atom.workspace.open(URI, split: 'right', searchAllPanes: true).done (view)=>
        @treeView = view
        @treeView.initiateView(toolBarButtons)
        if f
          f()

  # Displays received data in the view
  display: (data)->
    @toggle =>
      @treeView.display(data)

  executeFunction: (ns, fn)->
    if window.protoRepl.running()
      window.protoRepl.executeCode("(do (require '#{ns}) (#{ns}/#{fn}))")
    else
      atom.notifications.addWarning "No REPL is connected and running", dismissable: true

  # Displays traced namespaces in the REPL
  # TODO this would be better to do in the GUI somehow
  showTracedNamespaces: ->
    @executeFunction("proto-repl-sayid.core", "show-traced-namespaces")

  # Starts tracing all project namespaces.
  traceProjectNamespaces: ->
    @executeFunction("proto-repl-sayid.core", "trace-all-project-namespaces")

  # Untraces everything
  untraceAll: ->
    @executeFunction("com.billpiel.sayid.core", "ws-reset!")

    # Clears out traced data.
  clearCaptured: ->
    @executeFunction("com.billpiel.sayid.core", "ws-clear-log!")

  # Displays data that was traced in the view.
  displayLastCaptured: ->
    if window.protoRepl.running()
      window.protoRepl.executeCode("(do (require 'proto-repl-sayid.core)
                                        (proto-repl-sayid.core/display-last-captured
                                         #{atom.config.get("proto-repl-sayid.maxDisplayedNameSize")}))")
    else
      atom.notifications.addWarning "No REPL is connected and running", dismissable: true


  activate: (state) ->
    console.log("Proto REPL Sayid activated")
    @registerExtension()

    @subscriptions = new CompositeDisposable

    # Helper for defining a command that calls a method on this class..
    addCommand = (name, f)=>
      @subscriptions.add(atom.commands.add('atom-workspace', {"proto-repl-sayid:#{name}": f}))

    addCommand "toggle", => @toggle()
    addCommand "show-traced-namespaces", => @showTracedNamespaces()
    addCommand "trace-project-namespaces", => @traceProjectNamespaces()
    addCommand "untrace-all", => @untraceAll()
    addCommand "clear-captured", => @clearCaptured()
    addCommand "display-last-captured", => @displayLastCaptured()


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
