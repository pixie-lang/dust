(ns dust.project
  (require pixie.fs :as fs)
  (require pixie.io :as io)
  (require pixie.string :as str))

(def *project* (atom nil))

(defn merge-defaults [project]
  (merge {:source-paths ["src"], :test-paths ["test"], :dependencies []} project))

(defn quote-dependency-names
  [project]
  (if-let [deps (:dependencies project)]
    (assoc project
           :dependencies
           (vec (map (fn [[nm & rest]]
                       (vec (cons `(quote ~nm) rest)))
                     deps)))
    project))

(defn project->map
  [[nm version & description]]
  (let [description (apply hashmap description)]
    (-> description
        (assoc :name `(quote ~nm) :version version)
        quote-dependency-names
        merge-defaults)))

(defn read-project
  "Load project in dir, returning the project map"
  [dir]
  (let [exists? #(fs/exists? (fs/file (str dir %)))
        project
        (cond
          (exists? "/project.edn") (-> (io/slurp (str dir "/project.edn"))
                                       (read-string)
                                       (merge-defaults))
          (exists? "/project.pxi") (-> (io/slurp (str dir "/project.pxi"))
                                       (read-string)
                                       (rest)
                                       (project->map)
                                       (eval))
          :else (throw "Dust did not find 'project.edn'"))]
    (assoc project :path dir)))

(defn load-project! []
  (reset! *project* (read-project ".")))

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
      (doseq [[name version] deps]
        (println (str "    - " name "@" version))))))
