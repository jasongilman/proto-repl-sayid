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
    maxDepth:
      description: "The maximum depth of the callstack to try to display. Setting this too high will take a long time when tracing very deep callstacks."
      type: "number"
      default: 100
    maxChildren:
      description: "The maximum number of children of a single node to try to display. Setting this too high will take a long time when tracing functions that make many calls."
      type: "number"
      default: 100

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
      infoButtons = []
      infoButtons.push(
         name: "Traced NS",
         icon: "list-ordered"
         onClick: ()=> @showTracedNamespaces()
      )
      displayButtons = []
      displayButtons.push(
        name: "Last Captured",
        icon: "eye",
        onClick: ()=> @displayLastCaptured()
      )
      displayButtons.push(
        name: "All Captured",
        icon: "eye",
        onClick: ()=> @displayAllCaptured()
      )
      actionButtons = []
      actionButtons.push(
        name: "Reapply Traces",
        icon: "sync"
        onClick: ()=> @reapplyTraces()
      )
      actionButtons.push(
        name: "Untrace All",
        icon: "trashcan"
        onClick: ()=> @untraceAll()
      )
      actionButtons.push(
        name: "Clear Captured",
        icon: "x"
        onClick: ()=> @clearCaptured()
      )

      atom.workspace.open(URI, split: 'right', searchAllPanes: true).done (view)=>
        @treeView = view
        @treeView.initiateView([infoButtons, displayButtons, actionButtons])
        if f
          f()

  # Makes the pane with the Proto REPL repl show the repl.
  showRepl: ->
    replView = window.protoRepl.repl.replView
    paneItem = replView.console || replView.textEditor
    pane = atom.workspace.paneForItem(paneItem)
    pane?.activateItem(paneItem)

  # Displays received data in the view
  display: (data)->
    @toggle =>
      @treeView.display(data)

  executeFunction: (ns, fn)->
    if window.protoRepl.running()
      window.protoRepl.executeCode("(do (require '#{ns}) (#{ns}/#{fn}))")
    else
      atom.notifications.addWarning "No REPL is connected and running", dismissable: true

  # Traces all namesapces in the directory
  traceDirectoryOrFile: (dir)->
    if window.protoRepl.running()
      window.protoRepl.executeCode("(do (require 'proto-repl-sayid.core)
                                        (proto-repl-sayid.core/trace-all-namespaces-in-dir \"#{dir}\"))")
    else
      atom.notifications.addWarning "No REPL is connected and running", dismissable: true

  # Untraces all namesapces in the directory
  untraceDirectoryOrFile: (dir)->
    if window.protoRepl.running()
      window.protoRepl.executeCode("(do (require 'proto-repl-sayid.core)
                                        (proto-repl-sayid.core/untrace-all-namespaces-in-dir \"#{dir}\"))")
    else
      atom.notifications.addWarning "No REPL is connected and running", dismissable: true

  # Displays traced namespaces in the REPL
  # TODO this would be better to do in the GUI somehow
  showTracedNamespaces: ->
    @showRepl()
    @executeFunction("proto-repl-sayid.core", "show-traced-namespaces")

  # Traces the current open file
  traceCurrentFile: (editor)->
    @traceDirectoryOrFile(editor.getPath())

  # Untraces the current open file
  untraceCurrentFile: (editor)->
    @untraceDirectoryOrFile(editor.getPath())

  # Retraces all the traced namespaces
  reapplyTraces: ->
    @executeFunction("com.billpiel.sayid.core", "ws-cycle-all-traces!")

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
                                         #{atom.config.get("proto-repl-sayid.maxDisplayedNameSize")}
                                         #{atom.config.get("proto-repl-sayid.maxDepth")}
                                         #{atom.config.get("proto-repl-sayid.maxChildren")}))")
    else
      atom.notifications.addWarning "No REPL is connected and running", dismissable: true

  # Displays all captured data that was traced in the view.
  displayAllCaptured: ->
    if window.protoRepl.running()
      window.protoRepl.executeCode("(do (require 'proto-repl-sayid.core)
                                        (proto-repl-sayid.core/display-all-captured
                                         #{atom.config.get("proto-repl-sayid.maxDisplayedNameSize")}
                                         #{atom.config.get("proto-repl-sayid.maxDepth")}
                                         #{atom.config.get("proto-repl-sayid.maxChildren")}))")
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
    addCommand "reapply-traces", => @reapplyTraces()
    addCommand "untrace-all", => @untraceAll()
    addCommand "clear-captured", => @clearCaptured()
    addCommand "display-last-captured", => @displayLastCaptured()
    addCommand "display-all-captured", => @displayAllCaptured()
    addCommand "trace-directory-or-file", (event)=>
      @traceDirectoryOrFile event.target.dataset.path
    addCommand "untrace-directory-or-file", (event)=>
      @untraceDirectoryOrFile event.target.dataset.path
    addCommand "trace-current-file", (event)=>
      @traceCurrentFile event.target.component.editor
    addCommand "untrace-current-file", (event)=>
      @untraceCurrentFile event.target.component.editor


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
