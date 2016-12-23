# proto-repl-sayid package

**This is a work in progress.**

This is the future home of a package that provides an Atom Package that integrates [Proto REPL](https://github.com/jasongilman/proto-repl) and [Sayid](https://github.com/bpiel/sayid) to provide a visual call stack and debugging in Proto REPL.

See the [Proto REPL Clojure Conj 2016 talk video from 27:13](https://youtu.be/buPPGxOnBnk?t=27m13s) and the [Sayid video](https://youtu.be/ipDhvd1NsmE) for background information.

## TODOs


* Recent Ideas
  * Do larger test with real code as it is before making more changes.
  * The ideas here are to make it dead simple to get the basic usability out of this.
  * Toggling brings up the panel with Sayid Graph
  * Toolbar is its own class (maybe)
    * Buttons
      * Start/Stop Recording
      * Display last captured
      * Clear Captured
      * Expand all
      * Collapse all
  * Truncate very large trees in the call graph.
  * Detect if proto repl sayid library is not present and report error.
  * Detect if proto repl repl is not running


* User Experience
  * Nodes from left to right - X
  * Expandable and collapsible - X
  * Fast display of large trees - X
  * Too much data should be truncated
    * Tooltips - X
    * Large trees
      * Should have some kind of warning or indication that data is truncated.
    * Inline display
  * View tooltip of information about a node and what was captured. -X
  * Double click display inline data - X
  * Allow Defing data from inline display - X
  * Ability to expand all nodes or collapse all nodes. - X
* Eventually
  * Ability to filter out nodes easily or search it
* Search for all TODOs
* Remove extraneous logging
* Update this README
  * Description
  * gif of it in action.
  * Use instructions
* Update proto repl demo to show this integration
* Media
  * video of package in use?
  * blog post?
