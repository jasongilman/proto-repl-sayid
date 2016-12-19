(ns test-ns)

(defn foo
  [v])
  ; (println "Foo" v))

(defn bar
  [n]
  (dotimes [v n]
    (foo v)))

(defn chew
  [n]
  (dotimes [v n]
    (bar v)))
