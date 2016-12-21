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
  (test-ns/chew 20)
  (display-last-captured))

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

(defn display-last-captured
  "Displays the last set of captured data."
  []
  (let [data (-> (sayid/ws-deref!)
                 :children
                 last
                 extract-name-children)]
    [:proto-repl-code-execution-extension "proto-repl-sayid" data]))

;; TODO determine if keeping this.
; (defn display-all-captured
;   "Displays all of the captured data."
;   []
;   (let [data (->> (sayid/ws-deref!)
;                   :children
;                   (map extract-name-children)
;                   ; (map extract-edges-and-nodes)
;                   ;; TODO this won't work with the new tree combo. May want to get rid of this function.
;                   (apply merge-with into))]
;     [:proto-repl-code-execution-extension "proto-repl-sayid" data]))

(defn- find-node-by-id
  [id]
  (-> (sayid/ws-query [:id (keyword (str id))])
      :children
      first))

(def MAX_INLINE_WIDTH
  "The Maximum width that something can be displayed inline"
  60)

(defn retrieve-node-inline-data
  "Retrieves information about a sayid node for display inline."
  [id]
  (when-let [snode (find-node-by-id id)]
    (let [{:keys [return arg-map]} snode
          {:keys [line file]} (or (:meta snode) (:src-pos snode))
          ;; TODO fix the saved values bug when file is not included here
          ; _ (proto-repl.saved-values/save 1 file)
          file (if-let [r (.getResource (clojure.lang.RT/baseLoader) file)]
                 (.getPath r)
                 file)
          args-summary (pr-str arg-map)
          args-summary (subs args-summary 0 (min (count args-summary) (inc MAX_INLINE_WIDTH)))]
      {:file file
       :line line
       :args (into {} (mapv (fn [[k v]]
                              [k (pr-str v)])
                            arg-map))
       :argsSummary args-summary
       :returned (pr-str return)})))

(comment
 (find-node-by-id 12560)
 (retrieve-node-inline-data 12560)
 (node-tooltip-html 12560))

(defn- arg->html
  "Formats an argument for display in a tooltip."
  [[arg-name arg-value]]
  (format "<li><b>%s</b> - <code>%s</code></li>" arg-name (pr-str arg-value)))

(defn node-tooltip-html
  "Returns an HTML string of information to display for the given node in a tooltip."
  [id]
  (when-let [snode (find-node-by-id id)]
    ;; Limit the depth of things that are printed for tooltips
    (with-bindings
     {#'*print-length* 4
      #'*print-level* 4}
     (let [{:keys [return arg-map]} snode]
       (format (str "<b>Arguments</b><ul>%s</ul>"
                    "<b>Returned:</b><p><code>%s</code></p>")
               (str/join (map arg->html arg-map))
               (pr-str return))))))
