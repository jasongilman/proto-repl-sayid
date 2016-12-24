(ns proto-repl-sayid.truncation
  "Truncates var and namespace names."
  (:require
   [clojure.string :as str]))

;; TODO unit tests

(def ellipsis
  "A single character ellipsis for truncating long values.
   Unicode: U+2026, UTF-8: E2 80 A6"
  "…")

(defn- truncate-middle
  "Truncates a string if it's too long from the middle and replaces it with an ellipsis."
  [max-length s]
  (if (<= (count s) max-length)
    s
    (let [str-length (count s)
          half-length (long (/ max-length 2))]
      (str (subs s 0 (dec half-length)) ellipsis (subs s (- str-length half-length))))))

(defn- truncate-front
  "Truncates a string if it's too long from the front and replaces it with an ellipsis."
  [max-length s]
  (if (<= (count s) max-length)
    s
    (let [str-length (count s)
          half-length (long (/ max-length 2))]
      (str ellipsis (subs s (- str-length max-length -1) str-length)))))

(defn- truncate-namespace
  "Truncates a namespace name if it's too long. Shortens each segment individually
   into a single letter first and then from the front if necessary."
  [max-length n]
  (if (<= (count n) max-length)
    n
    (let [parts (str/split n #"\.")
          num-full (reduce (fn [{:keys [cnt length]} part]
                             (if (> (+ length (inc (count part))) max-length)
                               (reduced cnt)
                               {:cnt (inc cnt)
                                :length (+ length (inc (count part)))}))
                           {:cnt 0 :length 0}
                           (reverse parts))
          num-single (- (count parts) num-full)
          ;; Shorten each segment of the namespace as needed
          shortened (str/join
                     "."
                     (concat
                      (map first (take num-single parts))
                      (drop num-single parts)))]
      ;; Truncate the front of the namespace if it's still too long.
      (truncate-front max-length shortened))))

(defn truncate-var-name
  "Truncates a var name if necessary to the length indicated."
  [max-length nm]
  (if (<= (count nm) max-length)
    nm
    (let [[_ the-ns var-name] (re-matches #"([^/]+)/(.*)" nm)
          var-name-length (count var-name)]
      (if (>= var-name-length max-length)
        (truncate-middle max-length var-name)
        (str (truncate-namespace (- max-length var-name-length 1) the-ns)
             "/" var-name)))))
