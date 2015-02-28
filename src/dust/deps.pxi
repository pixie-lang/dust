(ns dust.deps
  (require pixie.string :as str)
  (require pixie.io :as io)
  (require pixie.fs :as fs)
  (require dust.project :as p))

(def *deps* (atom {}))

(defn cmd
  [& args]
  (sh (str/join " " args)))

(defn rm [file]
  (cmd "rm" file))

(defn mkdir [file]
  (cmd "mkdir" "-p" file))

(defn download [url file]
  (cmd "curl" "--silent" "--location" "--output" file url))

(defn extract-to [archive dir]
  (mkdir dir)
  (cmd "tar" "--strip-components" 1 "--extract" "--directory" dir "--file" archive))

(defn write-load-path
  "Write .load-path for project"
  [project]
  (let [paths (mapcat (fn [{:keys [path source-paths]}]
                        (if path
                          (map #(str path "/" %) source-paths)
                          source-paths))
                      (conj (:dependencies project) project))]
    (io/spit ".load-path"
             (str "--load-path " (str/join " --load-path " paths)))))

(defn load-project
  "Load project.pxi in dir - return project map"
  [dir]
  (-> (io/slurp (str dir "/project.pxi"))
      (read-string)
      (rest)
      (p/project->map)
      (eval)
      (assoc :path dir)))

(defn resolve-dependency
  "Download and extract dependency - return dependency project map."
  [[name version]]
  (let [url (str "https://github.com/" name "/archive/" version ".tar.gz")
        file-name (str "deps/" (str/replace (str name) "/" "-") ".tar.gz")
        dep-dir (str "deps/" name)]
    (when (not (fs/exists? (fs/->Dir dep-dir)))
      (println "Downloading" name)
      (download url file-name)
      (extract-to file-name dep-dir)
      (rm file-name))
    (let [project (load-project dep-dir)]
      (swap! *deps* assoc (:name project) project)
      project)))

(defn get-deps
  "Recursively download and extract all project dependencies."
  [project]
  (let [child-fn #(map resolve-dependency (:dependencies %))]
    (mkdir "deps")
    (vec (tree-seq :dependencies child-fn project))
    (assoc project :dependencies (vals @*deps*))))
