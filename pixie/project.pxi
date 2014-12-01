(ns pixie.project
  (require pixie.string :as str))

(def *project* (atom nil))

(defn expand-dependencies [project]
  (let [deps (get project :dependencies)]
    (if deps
      (assoc project
        :dependencies
        (vec (map (fn [[name version]]
                    {:name name, :version version})
                  deps)))
      project)))

(defmacro defproject
  [nm version & description]
  (let [description (apply hashmap description)
        description (if (contains? description :dependencies)
                      (update-in description [:dependencies] (fn [deps] `(quote ~deps)))
                      description)]
    `(reset! *project*
             (-> (assoc ~description
                   :name (quote ~nm)
                   :version ~version)
                 expand-dependencies))))

(defn describe [project]
  (let [{:keys [name version]} project]
    (println (str name "@" version))
    (doseq [k [:description :author :url]]
      (when-let [v (get project k)]
        (println (str "  " (str/capitalize k) ": " v))))
    (when-let [deps (get project :dependencies)]
      (println "  Dependencies:")
      (doseq [{:keys [name version]} deps]
        (println (str "    - " name "@" version))))))
