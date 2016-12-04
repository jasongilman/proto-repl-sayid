(ns test-ns)

(defn foo
  [v]
  (println "Foo" v))

(defn bar
  [n]
  (dotimes [v n]
    (foo v)))
