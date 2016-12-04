(ns proto-repl-sayid.core
  (:require
   [clojure.string :as str]
   [com.billpiel.sayid.core :as sayid]
   [clojure.tools.namespace.find :as ns-find]
   [proto-repl.extension-comm :as comm]
   [clojure.pprint :as pprint]))


;; TODO write unit tests for this namespace. This is mainly to know if when
;; upgrading sayid if the newer version breaks things here.


(comment
 (show-traced-namespaces)
 (trace-all-project-namespaces)

 ;; Mini test
 (sayid/ws-add-trace-ns! test-ns)
 (test-ns/bar 5)
 (display-last-stack)

 
 (sayid/ws-reset!))



(defn show-traced-namespaces
  "Prints the current traced namespaces"
  []
  (println "Currently Traced Namespaces")
  (pprint/pprint (seq (:ns (sayid/ws-show-traced*)))))


(defn trace-all-namespaces-in-dir
  "Traces all namespaces in the dir Extracted from Sayid nREPL middleware."
  [dir]
  (doseq [n (ns-find/find-namespaces-in-dir (java.io.File. dir))]
    (sayid/ws-add-trace-ns!* n))
  (sayid/ws-cycle-all-traces!))

(defn trace-all-project-namespaces
  "Traces all namespaces in the project assuming src is project dir"
  []
  (trace-all-namespaces-in-dir "src"))


(defn- extract-name-children
  "Takes a sayid workspace node and recursively extracts out id, name, and children."
  [node]
  (-> node
      (select-keys [:name :children :id])
      (update :id #(Long. (name %)))
      (update :name str)
      (update :children #(when (seq %)
                           (mapv extract-name-children %)))))

(defn- extract-edges-and-nodes
  "Extracts edges and nodes for display in Proto REPL Charts graph."
  [node]
  (let [{:keys [id name children]} node
        child-edges-and-nodes (mapv extract-edges-and-nodes children)]
    {:edges (vec (concat (mapv #(hash-map :from id :to (:id %))
                               children)
                         (mapcat :edges child-edges-and-nodes)))
     :nodes (reduce #(into %1 %2)
                    #{{:id id
                       ;; TODO don't strip out the namespace
                       :label (str/replace name #".*/" "")
                       :group (str/replace name #"/.*" "")}}
                    (map :nodes child-edges-and-nodes))}))

(defn display-last-stack
  "Displays the last set of captured data."
  []
  (let [data (-> (sayid/ws-deref!)
                 :children
                 last
                 extract-name-children
                 extract-edges-and-nodes)]
    [:proto-repl-code-execution-extension "proto-repl-sayid" data]))

(defn handle-double-click
  "Handles a double click event in a displayed graph. If a node is double clicked
   the code related to the function call is opened and an inline display shows
   the arguments and return value of that function."
  [event-data]
  ;; Make sure a node was clicked. Edges can be clicked too.
  (when-let [node-id (-> event-data :nodes first :id)]
    ;; Find the sayid node that was clicked
    (if-let [snode (-> (sayid/ws-query [:id (keyword (str node-id))])
                       :children
                       first)]
      (let [{:keys [return arg-map]} snode
            {:keys [line file]} (or (:meta snode) (:src-pos snode))
            display-data {:args arg-map
                          :return return}
            file (.getPath (.getResource (clojure.lang.RT/baseLoader) file))]
        (comm/send-command
         :proto-repl-built-in
         {:command :display-at-line
          :file file
          :line line
          :data (pr-str display-data)}))
      (println "Could not find node with id in captured sayid data" node-id))))
