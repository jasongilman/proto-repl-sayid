(defproject proto-repl-sayid "0.1.0"
  :description "Proto REPL Sayid integration that provides a visual call stack and debugging"
  :url "https://github.com/jasongilman/proto-repl-sayid"
  :license {:name "MIT"
            :url "https://opensource.org/licenses/MIT"}
  :dependencies [[org.clojure/clojure "1.8.0"]
                 [proto-repl "0.3.1"]
                 [com.billpiel/sayid "0.0.10"]]
  :profiles {:dev {:dependencies [[pjstadig/humane-test-output "0.7.1"]]
                   :injections [(require 'pjstadig.humane-test-output)
                                (pjstadig.humane-test-output/activate!)]
                   :source-paths ["dev" "src" "test"]}})
