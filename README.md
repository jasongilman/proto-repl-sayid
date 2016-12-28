# proto-repl-sayid package

**This is a work in progress but it is available for alpha testing.**

Proto REPL Sayid is an Atom Package that integrates [Proto REPL](https://github.com/jasongilman/proto-repl) and [Sayid](https://github.com/bpiel/sayid) to provide a visual call stack in Proto REPL.


## Installation Instructions

1. Install the proto-repl-sayid Atom package.
2. Add the proto-repl-sayid Clojure library to your dependencies. [![Clojars Project](https://img.shields.io/clojars/v/proto-repl-sayid.svg)](https://clojars.org/proto-repl-sayid)

## Usage

1. Start a REPL using Proto REPL or connect to a REPL.
2. Bring up the *Proto-REPL Sayid Call Graph* display. Click *Packages* -> *proto-repl-sayid* -> *Toggle*
3. Right click in the Atom tree view on a folder and select *Proto REPL Sayid* -> *Trace Directory/File*
4. Execute some code. You can run a test or manually execute something.
5. Click *Display Last Captured* in the *Proto-REPL Sayid Call Graph* tab.
6. Hover above displayed nodes to see details.
7. Double click on a node to show the details inline.
8. Click the *def* button to temporarily define the arguments the function received.

## Videos

* Background before the plugin existed
  * [Proto REPL Clojure Conj 2016 talk video from 27:13](https://youtu.be/buPPGxOnBnk?t=27m13s)
  * [Sayid Clojure Conj talk](https://youtu.be/ipDhvd1NsmE) for background information.

## TODOs

* Detect if proto repl sayid library is not present and report error.
* Eventually
  * A better way to display the currently traced namespaces than in REPL. Would like to have a side panel with a list of namespaces. Would have ability to removed traced namespaces. Could also be a location for tracing by pattern.
  * Ability to filter out nodes easily or search it
* Search for all TODOs
* Unit test clojure code
* Update this README
  * Description
  * gif of it in action.
  * Use instructions
* Update proto repl demo to show this integration
* Update proto repl installation instructions to include this.
* Media
  * video of package in use?
  * blog post?
