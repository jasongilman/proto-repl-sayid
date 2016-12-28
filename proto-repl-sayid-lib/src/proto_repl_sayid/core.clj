(ns proto-repl-sayid.core
  (:require
   [clojure.pprint :as pprint]
   [clojure.string :as str]
   [clojure.tools.namespace.find :as ns-find]
   [com.billpiel.sayid.core :as sayid]
   [proto-repl.extension-comm :as comm]
   [proto-repl-sayid.truncation :as t]))


;; TODO write unit tests for this namespace. This is mainly to know if when
;; upgrading sayid if the newer version breaks things here.


(comment
 ;; Mini test
 (test-ns/root 5))



(defn show-traced-namespaces
  "Prints the current traced namespaces"
  []
  (println "Currently Traced Namespaces")
  (pprint/pprint (sort (seq (:ns (sayid/ws-show-traced*))))))

(defn trace-all-namespaces-in-dir
  "Traces all namespaces in the dir Extracted from Sayid nREPL middleware."
  [dir]
  (doseq [n (ns-find/find-namespaces-in-dir (java.io.File. dir))]
    (sayid/ws-add-trace-ns!* n))
  (sayid/ws-cycle-all-traces!))

(defn untrace-all-namespaces-in-dir
  "Untraces all namespaces in the dir Extracted from Sayid nREPL middleware."
  [dir]
  (doseq [n (ns-find/find-namespaces-in-dir (java.io.File. dir))]
    (sayid/ws-remove-trace-ns! n))
  (sayid/ws-cycle-all-traces!))

(declare extract-display-data)

(def max-depth-exceeded-node
  "Placeholder node used when the maximum configured depth is exceeded."
  {:id -1
   :name "..."
   :children nil})

(def max-depth-exceeded-tooltip
  "Tooltip to show when hovering above max depth node."
  (str "<b>Max Depth Exceeded</b>"
       "<p>Maximum configured depth was exceeded. Either reduce the amount of traced"
       " namespaces or increase depth in settings.</p>"))

(def max-children-exceeded-node
  "Placeholder node used when the maximum number of children is exceeded."
  {:id -2
   :name "..."
   :children nil})

(def max-children-exceeded-tooltip
  "Tooltip to show above max children node"
  (str "<b>Max Children Exceeded</b>"
       "<p>Maximum configured number of children in a single node was exceeded. Either reduce the amount of traced"
       " namespaces or increase size in settings.</p>"))

(defn- extract-children
  "Extracts display data from the child nodes."
  [max-name-length max-depth max-children children]
  (when (seq children)
    (if (= 0 max-depth)
      ;; The maximum depth was exceeded. Return place holder node.
      [max-depth-exceeded-node]
      (let [new-children (mapv #(extract-display-data max-name-length (dec max-depth) max-children %)
                               (take max-children children))]
        (if (> (count children) max-children)
          ;; Max children exceeded. Add placeholder child
          (conj new-children max-children-exceeded-node)
          new-children)))))

(defn- extract-display-data
  "Takes a sayid workspace node and recursively extracts out id, name, and children."
  [max-name-length max-depth max-children node]
  (-> node
      (select-keys [:name :children :id])
      (update :id #(name %))
      (update :name #(->> % str (t/truncate-var-name max-name-length)))
      (update :children #(extract-children max-name-length max-depth max-children %))))

(defn display-last-captured
  "Displays the last set of captured data."
  [max-name-length max-depth max-children]
  (let [data (some->> (sayid/ws-deref!)
                      :children
                      last
                      (extract-display-data max-name-length max-depth max-children))]
    [:proto-repl-code-execution-extension "proto-repl-sayid" data]))

(defn display-all-captured
  "Displays all the captured data."
  [max-name-length max-depth max-children]
  (let [data (some->> (sayid/ws-deref!)
                      (extract-display-data max-name-length max-depth max-children))]
    [:proto-repl-code-execution-extension "proto-repl-sayid" data]))

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
 (find-node-by-id 18435)
 (retrieve-node-inline-data 18435)
 (node-tooltip-html 18435))

(defn- arg->html
  "Formats an argument for display in a tooltip."
  [[arg-name arg-value]]
  (format "<li><b>%s</b> - <code>%s</code></li>" arg-name (pr-str arg-value)))

(defn node-tooltip-html
  "Returns an HTML string of information to display for the given node in a tooltip."
  [id]
  (cond
    (= id (:id max-depth-exceeded-node))
    max-depth-exceeded-tooltip

    (= id (:id max-children-exceeded-node))
    max-children-exceeded-tooltip

    :else
    (when-let [snode (find-node-by-id id)]
      ;; Limit the depth of things that are printed for tooltips
      (with-bindings
       {#'*print-length* 4
        #'*print-level* 4}
       (let [{:keys [return arg-map]} snode]
         (format (str "<b>%s</b><br><br>"
                      "<b>Arguments</b><ul>%s</ul>"
                      "<b>Returned:</b><p><code>%s</code></p>")
                 (:name snode)
                 (str/join (map arg->html arg-map))
                 (pr-str return)))))))

(defn def-args-for-node
  "Defines arguments captured in a sayid node as temporary vars of the namespace."
  [id]
  (when-let [snode (find-node-by-id id)]
    (let [the-ns (get-in snode [:meta :ns])]
      (println (format "Defining in ns [%s] the arguments %s"
                       the-ns (vec (keys (:arg-map snode)))))
      (doseq [[arg-name arg-value] (:arg-map snode)]
        (intern the-ns arg-name arg-value)))))
