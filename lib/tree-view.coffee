# Based on http:#bl.ocks.org/robschmuecker/7880033 which has the following copyright

# Copyright (c) 2013-2016, Rob Schmuecker
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * The name Rob Schmuecker may not be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MICHAEL BOSTOCK BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

{Range, Point} = require 'atom'
{$, $$$, ScrollView}  = require 'atom-space-pen-views'
d3 = require 'd3'

# A recursive helper function for performing some setup by walking through all nodes
visit = (parent, visitFn, childrenFn)->
  if !parent then return
  visitFn(parent)
  children = childrenFn(parent)
  if children
    for child in children
      visit(child, visitFn, childrenFn)

PAN_SPEED = 200
# Within 20px from edges will pan when dragging.
PAN_BOUNDARY = 20

NODE_TRANSITION_DURATION = 750

# Truncates a string to the specified length if needed.
truncateToLength = (s, length)->
  if s.length > length
    s.substring(0, length-1) + "…"
  else
    s

# The maximum width of inline data on one row
MAX_INLINE_WIDTH = 60
# The string separating arguments from the return value for inline display
ARG_RETURN_SEP = " => "
# The maximum amount of space the arguments can take with summarized with return value
ARG_SUMMARY_WITH_RETURN_MAX_LENGTH = (MAX_INLINE_WIDTH - ARG_RETURN_SEP.length) * 0.75


PROTOCOL = "proto-repl-sayid:"
NAME = "Sayid Call Graph"

module.exports =
  class TreeView extends ScrollView

    # The longest label for a node that was found.
    maxLabelLength: null

    # The root of the data tree
    root: null

    # The next id to assign to a node.
    nextNodeId: 0

    # The current width of the view
    viewerWidth: null

    #The current height of the view
    viewerHeight: null

    # An instance of a D3 tree layout
    tree: null

    # A div used to show the tool tip
    tooltipDiv: null

    # A timeout id used to set a timeout for delaying execution of code to get data for displaying the tooltip.
    toolTipDisplayTimeout: null

    # a d3 diagonal projection for use by the node paths
    diagonalProjection: null

    # The root svg group that holds everything. Used for zooming
    svgGroup: null

    # d3 zooming behavior
    zoomListener: null

    toolbar: null

    # A map of strings to functions to call when the button is pressed.
    toolbarButtons: {}

    atom.deserializers.add(this)

    @content: ->
      @div class: 'proto-repl-sayid-graph native-key-bindings', tabindex: -1

    constructor: () ->
      super
      this

    getURI: ->
      "proto-repl-sayid://"

    initiateView: (toolbarButtons)->
      @toolbarButtons = toolbarButtons
      holderDiv = document.createElement("div")
      @html $ holderDiv

      d3HolderDiv = d3.select(holderDiv)
        .attr("class", "sayid-holder")

      # Add toolbar
      @toolbar = d3HolderDiv.append("div")
          .attr("class", "sayid-toolbar")
        .append("div")
          .attr("class", "bar")
        .append("span")
          .attr("class", "inline-block")

      addButton = (name, f)=>
        @toolbar.append("button")
          .attr("class", "btn")
          .text(name)
          .on("click", f)

      for name, f of toolbarButtons
        addButton(name, f)

      # Expand all button
      addButton "Expand All", ()=>
        if @root
          @expand(@root)
          @updateNode(@root)
          @centerNode(@root)

      # Collapse all button
      addButton "Collapse All", ()=>
        if @root
          @collaps(@root)
          @updateNode(@root)
          @centerNode(@root)


      @graphDiv = d3HolderDiv.append("div")
                    .attr("class", "sayid-holder")

      # size of the diagram
      @viewerWidth = $(holderDiv).width()
      @viewerHeight = $(holderDiv).height()



    # Defines the arguments that were captured by sayid.
    defArgsForNode: (id)->
      window.protoRepl.executeCode "(proto-repl-sayid.core/def-args-for-node #{id})",
        displayInRepl: false,
        resultHandler: (result)->
          if result.error
            console.log result.error
            atom.notifications.addError "Unable to define args for node. See Atom console for full error.", dismissable: true


    # Creates an inline tree to display arguments and return values that were captured from the stack.
    # Expected keys are file, line, args, return
    # args is a map of argument name to edn value.
    # argsSummary is a string summarization of the arguments
    # returned is an edn value that was returned
    inlineDataToTree: (id, {args, argsSummary, returned})->
      topArgsSummary = truncateToLength(argsSummary, ARG_SUMMARY_WITH_RETURN_MAX_LENGTH)
      topSummary = truncateToLength(topArgsSummary + ARG_RETURN_SEP + returned, MAX_INLINE_WIDTH)
      # Create inline trees for each of the arguments.
      argsInlineTrees = for argName, argValue of args
        # Use Proto REPLs built in capability for this.
        [summary, rest...] = window.protoRepl.ednToDisplayTree(argValue)
        # Generate a new summary with the arg name.
        summary = truncateToLength(argName + ": " + summary, MAX_INLINE_WIDTH)
        [summary].concat(rest)
      [returnedSummary, rest...] = window.protoRepl.ednToDisplayTree(returned)
      returnedSummary = truncateToLength("Return: " + returnedSummary, MAX_INLINE_WIDTH)
      returnedInlineTree = [returnedSummary].concat(rest)

      # Defines button options to add a button that will define the arguments for a function.
      defArgsButton =
        button_text: "def",
        button_class: "def-saved-var"
        button_fn: ()=> @defArgsForNode(id)

      [topSummary, {},
        [truncateToLength("Args: " + argsSummary, MAX_INLINE_WIDTH), defArgsButton].concat(argsInlineTrees),
        returnedInlineTree]

    # Returns a promise that gets the data captured by sayid for a given node
    # so it can be displayed as an inline tree.
    fetchInlineData: (id)->
      new Promise (resolve, reject)->
        window.protoRepl.executeCode "(proto-repl-sayid.core/retrieve-node-inline-data #{id})",
          displayInRepl: false,
          resultHandler: (result)->
            if result.error
              reject(result.error)
            else
              resolve(window.protoRepl.parseEdn(result.value))

    # Retrieves data from sayid for the node with the given id and displays an
    # inline tree in the file where the function is located.
    displayNodeInlineData: (id)->
      @fetchInlineData(id).then((data)=>
        inlineTree = @inlineDataToTree(id, data)
        line = data.line - 1
        range = new Range(new Point(line), new Point(line,Infinity))
        textEditorPromise = atom.workspace.open(data.file, {initialLine: line, searchAllPanes: true})
        textEditorPromise.then (editor)->
          window.protoRepl.repl.displayInline(editor, range, inlineTree)
      ).catch((error)->
        console.error(error)
        atom.notifications.addError "Unable to retrieve node data. See Atom console for full error.", dismissable: true
      )

    # TODO  After resize get the latest sizes for controlling zooming.

    # Collapses all the nodes that are the children of the given node.
    collapse: (d)->
      if d.children
        d._children = d.children
        d._children.forEach (c)=>@collapse(c)
        d.children = null
      else if d._children
        d._children.forEach (c)=>@collapse(c)

    # Expands all the nodes that are the children of the given node.
    expand: (d)->
      if (d._children)
        d.children = d._children
        d.children.forEach (c)=>@expand(c)
        d._children = null
      else if d.children
        d.children.forEach (c)=>@expand(c)


    # Displays the sayid data in a D3 tree.
    display: (treeData)->
      @initiateView(@toolbarButtons)

      @maxLabelLength = 0
      @root = null
      @nextNodeId = 0

      @tree = d3.layout.tree().size([@viewerHeight, @viewerWidth])

      # Define the div for the tooltip
      @tooltipDiv = @graphDiv.append("div")
          .attr("class", "sayid-tooltip")
          .style("opacity", 0);

      # define a d3 diagonal projection for use by the node paths later on.
      @diagonalProjection = d3.svg.diagonal().projection((d)-> [d.y, d.x])

      # Fail out early but after GUI is setup if there is no data to display
      if !treeData
        atom.notifications.addWarning "No data was captured for display", dismissable: true
        return

      # Call visit function to establish maxLabelLength
      visit(treeData, (d)=>
        @nextNodeId++
        @maxLabelLength = Math.max(d.name.length, @maxLabelLength)
      , (d)-> if d.children && d.children.length > 0 then d.children else null)

      # Define the zoom function for the zoomable tree
      zoom = (d)=>
        @svgGroup.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")")

      # define the zoomListener which calls the zoom function on the "zoom" event constrained within the scaleExtents
      @zoomListener = d3.behavior.zoom().scaleExtent([0.1, 3]).on("zoom", zoom)

      baseSvg = @graphDiv.append("svg")
          .attr("class", "sayid-overlay")
          .call(@zoomListener)

      # Append a group which holds all nodes and which the zoom Listener can act upon.
      @svgGroup = baseSvg.append("g")

      # Define the root
      @root = treeData
      @root.x0 = @viewerHeight / 4
      @root.y0 = 0

      # Layout the tree initially and center on the root node.
      @updateNode(@root)
      @centerNode(@root)

    # Function to center node when clicked/dropped so node doesn't get lost when collapsing/moving with large amount of children.
    centerNode: (source)->
      scale = @zoomListener.scale()
      x = -1 * source.y0
      y = -1 * source.x0
      x = x * scale + @viewerWidth / 4
      y = y * scale + @viewerHeight / 2
      d3.select('g').transition()
          .duration(NODE_TRANSITION_DURATION)
          .attr("transform", "translate(" + x + "," + y + ")scale(" + scale + ")")
      @zoomListener.scale(scale)
      @zoomListener.translate([x, y])


    # Toggle children on click.
    handleNodeClick: (d)->
      if d3.event.defaultPrevented then return # click suppressed

      if d.children
        # Hide children
        d._children = d.children
        d.children = null
      else if d._children
        # Display children
        d.children = d._children
        d._children = null

      @updateNode(d)
      @centerNode(d)

    # Handles a node mouse over event. Takes the node that was moused over.
    handleMouseOver: (d)->
      x = d3.event.layerX
      y = d3.event.layerY
      @toolTipDisplayTimeout = setTimeout(=>
          window.protoRepl.executeCode("(proto-repl-sayid.core/node-tooltip-html #{d.id})",
            displayInRepl: false
            resultHandler: (result, options)=>
              if result.error
                console.error result.error
                atom.notifications.addError "Unable to retrieve tooltip display info. See console error message", dismissable: true
              else
                text = result.value
                text = text.substring(1, text.length-1)
                text = text + " <p>Double click show full details inline</p>"
                @displayToolTip(text, x, y)
          )
        , 200)

    # Displays a tooltip with the given html at position x,y
    displayToolTip: (html, x, y)->
      @tooltipDiv.transition()
          .duration(100)
          .style("opacity", 0.9)
      @tooltipDiv.html(html)
          .style("left", x + "px")
          .style("top", (y + 28) + "px")

    # Hides a currently displayed tooltip
    hideToolTip: ()->
      if @toolTipDisplayTimeout
        clearTimeout(@toolTipDisplayTimeout)
        @toolTipDisplayTimeout = null

      @tooltipDiv.transition()
          .duration(500)
          .style("opacity", 0)

    # Main handler of D3-afication of nodes. Takes a data node and adds it to
    # the displayed set of data. Can be used to update what's currently displayed
    # if the current state has changed to collapse or expand a node.
    updateNode: (source)->
      # Compute the new height, function counts total children of root node and sets tree height accordingly.
      # This prevents the layout looking squashed when new nodes are made visible or looking sparse when nodes are removed
      # This makes the layout more consistent.
      levelWidth = [1]
      childCount = (level, n)->
        if n.children && n.children.length > 0
          if levelWidth.length <= level + 1 then levelWidth.push(0)
          levelWidth[level + 1] += n.children.length
          n.children.forEach((d)-> childCount(level + 1, d))

      childCount(0, @root)
      newHeight = d3.max(levelWidth) * 25 # 25 pixels per line
      @tree = @tree.size([newHeight, @viewerWidth])

      # Compute the new tree layout.
      nodes = @tree.nodes(@root).reverse()
      links = @tree.links(nodes)

      # Set widths between levels based on maxLabelLength.
      nodes.forEach((d)=>d.y = (d.depth * (@maxLabelLength * 10)))

      # Update the nodes…
      node = @svgGroup.selectAll("g.node").data(nodes, (d)=> d.id || (d.id = ++@nextNodeId))

      # Enter any new nodes at the parent's previous position.
      nodeEnter = node.enter().append("g")
          .attr("class", "node")
          .attr("transform",(d)->
              "translate(" + source.y0 + "," + source.x0 + ")"
          )

      nodeEnter.append("circle")
          .attr('class', 'nodeCircle')
          .attr("r", 0)
          .style("fill", (d)->
              if d._children then "lightsteelblue" else "#fff"
          )
          .on('click', (d)=>@handleNodeClick(d))

      nodeEnter.append("text")
          .attr("x", (d)->
            if d.children || d._children then -10 else 10
          )
          .attr("dy", ".35em")
          .attr('class', 'nodeText')
          .attr("text-anchor", (d)->
              if d.children || d._children then "end" else "start"
          )
          .text((d)->d.name)
          .style("fill-opacity", 0)
          .on("mouseover", (d)=>@handleMouseOver(d))
          .on("mouseout", (d)=>@hideToolTip(d))
          .on("dblclick", (d)=>
            d3.event.stopPropagation()
            @displayNodeInlineData(d.id)
          )

      # phantom node to give us mouseover in a radius around it
      nodeEnter.append("circle")
          .attr('class', 'ghostCircle')
          .attr("r", 30)
          .attr("opacity", 0.2) # change this to zero to hide the target area
          .style("fill", "red")
          .attr('pointer-events', 'mouseover')


      # Update the text to reflect whether node has children or not.
      node.select('text')
          .attr("x", (d)->
              if d.children || d._children then -10 else 10
          )
          .attr("text-anchor", (d)->
              if d.children || d._children then "end" else "start"
          )
          .text((d)->d.name)

      # Change the circle fill depending on whether it has children and is collapsed
      node.select("circle.nodeCircle")
          .attr("r", 4.5)
          .style("fill", (d)->
            if d._children then "lightsteelblue" else "#fff"
          )

      # Transition nodes to their new position.
      nodeUpdate = node.transition()
          .duration(NODE_TRANSITION_DURATION)
          .attr("transform", (d)->
              "translate(" + d.y + "," + d.x + ")"
          )

      # Fade the text in
      nodeUpdate.select("text")
          .style("fill-opacity", 1)

      # Transition exiting nodes to the parent's new position.
      nodeExit = node.exit().transition()
          .duration(NODE_TRANSITION_DURATION)
          .attr("transform", (d)->
              "translate(" + source.y + "," + source.x + ")"
          )
          .remove()

      nodeExit.select("circle")
          .attr("r", 0)

      nodeExit.select("text")
          .style("fill-opacity", 0)

      # Update the links…
      link = @svgGroup.selectAll("path.link")
          .data(links, (d)->d.target.id)

      # Enter any new links at the parent's previous position.
      link.enter().insert("path", "g")
          .attr("class", "link")
          .attr("d", (d)=>
            o = {
              x: source.x0,
              y: source.y0
            }
            @diagonalProjection({
              source: o,
              target: o
            })
          )

      # Transition links to their new position.
      link.transition()
          .duration(NODE_TRANSITION_DURATION)
          .attr("d", @diagonalProjection)

      # Transition exiting nodes to the parent's new position.
      link.exit().transition()
          .duration(NODE_TRANSITION_DURATION)
          .attr("d", (d)=>
            o = {
              x: source.x,
              y: source.y
            }
            @diagonalProjection({
              source: o,
              target: o
            })
          )
          .remove()
      #
      # # Stash the old positions for transition.
      nodes.forEach((d)->
        d.x0 = d.x
        d.y0 = d.y
      )


    getTitle: ->
      NAME
