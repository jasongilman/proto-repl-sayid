(ns user
  (require [clojure.tools.namespace.repl :as tnr]
           [clojure.repl :refer :all]
           [test-ns]
           [proto-repl.saved-values]))

(def system nil)

(defn start [])

(defn stop [])

(defn reset []
  (stop)
  (tnr/refresh :after 'user/start))

(println "Proto REPL Sayid project started")
