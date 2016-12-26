(ns test-ns)

(defn foo
  [v])
  ; (println "Foo" v))

(defn bar
  [n otherstuff]
  (dotimes [v n]
    (foo v))
  otherstuff)


(defn chew
  [n]
  (dotimes [v n]
    (bar v {:big (range 10) :foo (range 10) :car {:a 1 :b 5}})))

(defn funtimes
  [n]
  (chew n))

(defn root
  [n]
  (funtimes n))
