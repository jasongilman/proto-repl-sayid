# proto-repl-sayid package

**This is a work in progress.**

This is the future home of a package that provides an Atom Package that integrates [Proto REPL](https://github.com/jasongilman/proto-repl) and [Sayid](https://github.com/bpiel/sayid) to provide a visual call stack and debugging in Proto REPL.

See the [Proto REPL Clojure Conj 2016 talk video from 27:13](https://youtu.be/buPPGxOnBnk?t=27m13s) and the [Sayid video](https://youtu.be/ipDhvd1NsmE) for background information.

## TODOs

* Toggling brings up the panel with Sayid Graph
* Toolbar is its own class (maybe)
  * Buttons
    * Start/Stop Recording
    * Display last captured
    * Clear Captured
    * Expand all - X
    * Collapse all - X
* Detect if proto repl sayid library is not present and report error.
* Detect if proto repl repl is not running
* Handle trees that are too large (truncate nodes)
* Eventually
  * Ability to filter out nodes easily or search it
* Search for all TODOs
* Unit test clojure code
* Update this README
  * Description
  * gif of it in action.
  * Use instructions
* Update proto repl demo to show this integration
* Media
  * video of package in use?
  * blog post?
