(ns dust.deps
  (require pixie.string :as str)
  (require pixie.io :as io)
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

(defn resolved?
  "true when dependency name resolved"
  [name]
  (or (contains? @*deps* name)
      (zero? (cmd "ls" (str "deps/" name) ">> /dev/null 2>&1"))))

(defn load-project
  "Load project.pxi in dir - return project map"
  [dir]
  (-> (io/slurp (str dep-dir "/project.pxi"))
      (read-string)
      (rest)
      (p/project->map)
      (eval)))

(defn resolve-dependency
  "Download and extract dependency - return dependency project map."
  [[name version]]
  (let [url (str "https://github.com/" name "/archive/" version ".tar.gz")
        file-name (str "deps/" (str/replace (str name) "/" "-") ".tar.gz")
        dep-dir (str "deps/" name)]
    (when (not (resolved? name))
      (println "Downloading" name)
      (download url file-name)
      (extract-to file-name dep-dir)
      (rm file-name))
    (let [project (load-project)]
      (swap! *deps* assoc (:name project) project)
      project)))

(defn get-deps
  "Recursively download and extract all project dependencies."
  [project]
  (let [child-fn #(map resolve-dependency (:dependencies %))]
    (mkdir "deps")
    (vec (tree-seq :dependencies child-fn project))
    (swap! p/*project* assoc :dependencies (mapcat :dependencies (vals @*deps*)))))
