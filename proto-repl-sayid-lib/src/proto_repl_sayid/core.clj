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
 (do
  (sayid/ws-add-trace-ns! test-ns)
  (test-ns/bar 5)
  (display-last-captured))
 (display-all-captured)

 (-> (->> (sayid/ws-deref!) :children first :children first)
     (dissoc :meta)
     pr-str)
 (sayid/ws-reset!)
 (sayid/ws-clear-log!))


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
        child-edges-and-nodes (mapv extract-edges-and-nodes children)
        current-node {:id id
                      :label (str/replace name "/" "\n")
                      :group (str/replace name #"/.*" "")}]
    {:edges (vec (concat (mapv #(hash-map :from id :to (:id %))
                               children)
                         (mapcat :edges child-edges-and-nodes)))
     :nodes (reduce #(into %1 %2)
                    #{current-node}
                    (map :nodes child-edges-and-nodes))
     :options {}}))

(defn display-last-captured
  "Displays the last set of captured data."
  []
  (let [data (-> (sayid/ws-deref!)
                 :children
                 last
                 extract-name-children
                 extract-edges-and-nodes)]
    [:proto-repl-code-execution-extension "proto-repl-sayid" data]))

(defn display-all-captured
  "Displays all of the captured data."
  []
  (let [data (->> (sayid/ws-deref!)
                  :children
                  (map extract-name-children)
                  (map extract-edges-and-nodes)
                  (apply merge-with into))]
    [:proto-repl-code-execution-extension "proto-repl-sayid" data]))

;; TODO this should return data in format
;; ["text for display", {button options}, [childtree1, childtree2, ...]]
(defn retrieve-node-inline-data
  "Retrieves information about a sayid node for display inline"
  [id]
  (when-let [snode (-> (sayid/ws-query [:id (keyword (str id))])
                       :children
                       first)]
    (let [{:keys [return arg-map]} snode
          {:keys [line file]} (or (:meta snode) (:src-pos snode))
          file (.getPath (.getResource (clojure.lang.RT/baseLoader) file))]
      {:file file
       :line line
       :args arg-map
       :return return})))
