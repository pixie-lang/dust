(ns dust.project
  (require pixie.string :as str))

(def *project* (atom nil))

(defn merge-defaults [project]
  (merge {:source-paths ["src"]}
         project))

(defn expand-dependencies
  [project]
  (if-let [deps (:dependencies project)]
    (assoc project
           :dependencies
           (vec (map (fn [[name version & options]]
                       (merge {:name `(quote ~name) :version version}
                              (apply hashmap options)))
                     deps)))
    project))

(defn project->map
  [[nm version & description]]
  (let [description (apply hashmap description)]
    (-> description
        (assoc :name `(quote ~nm) :version version)
        expand-dependencies
        merge-defaults)))

(defmacro defproject
  [& args]
  (let [project (project->map args)]
    `(reset! *project* ~project)))

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
