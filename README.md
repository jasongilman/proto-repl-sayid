# proto-repl-sayid package

**This is a work in progress.**

This is the future home of a package that provides an Atom Package that integrates [Proto REPL](https://github.com/jasongilman/proto-repl) and [Sayid](https://github.com/bpiel/sayid) to provide a visual call stack and debugging in Proto REPL.

See the [Proto REPL Clojure Conj 2016 talk video from 27:13](https://youtu.be/buPPGxOnBnk?t=27m13s) and the [Sayid video](https://youtu.be/ipDhvd1NsmE) for background information.

## TODOs


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
  * Ability to expand all nodes or collapse all nodes.
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
