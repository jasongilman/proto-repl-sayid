GraphView = require './graph-view'
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

  activate: (state) ->
    console.log("Proto REPL Sayid activated")
    @registerExtension()

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'proto-repl-sayid:show-traced-namespaces': =>
      window.protoRepl.executeCode("(do (require 'proto-repl-sayid.core)
                                        (proto-repl-sayid.core/show-traced-namespaces))")

    @subscriptions.add atom.commands.add 'atom-workspace', 'proto-repl-sayid:trace-project-namespaces': =>
      window.protoRepl.executeCode("(do (require 'proto-repl-sayid.core)
                                        (proto-repl-sayid.core/trace-all-namespaces-in-project))")

    @subscriptions.add atom.commands.add 'atom-workspace', 'proto-repl-sayid:reset-traced': =>
      window.protoRepl.executeCode("(do (require 'com.billpiel.sayid.core)
                                        (com.billpiel.sayid.core/ws-reset!))")

    atom.workspace.onDidDestroyPaneItem (event)=>
      item = event.item
      pane = event.pane
      if item instanceof GraphView
        @graphView = null

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        console.log error
        return

      return unless protocol == PROTOCOL
      new GraphView()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    {}
