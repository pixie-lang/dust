(ns dust.deps
  (require pixie.string :as str)
  (require pixie.io :as io)
  (require pixie.fs :as fs)
  (require dust.project :as p))

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
                      (:dependencies project))]
    (io/spit ".load-path"
             (str/trim (str "--load-path " (str/join " --load-path " paths))))))

(defn- download-dep [name version dep-dir]
  (let [url (str "https://github.com/" name "/archive/" version ".tar.gz")
        file-name (str "deps/" (str/replace (str name) "/" "-") ".tar.gz")
        _ (println "Downloading" name)
        _ (download url file-name)
        extraction-result (extract-to file-name dep-dir)]
    (when-not (zero? extraction-result)
      (throw [:dust/DustException (str "Didn't find a valid tarball at " url)]))
    (rm file-name)))

(defn resolve-dependency
  "Download and extract dependency - return dependency project map."
  [[name version]]
  (let [dep-dir (str "deps/" name)]
    (when (not (fs/exists? (fs/dir dep-dir)))
      (download-dep name version dep-dir))
    (p/read-project dep-dir)))

(defn get-deps
  "Recursively download and extract all project dependencies."
  [project]
  (let [child-fn #(map resolve-dependency (:dependencies %))
        dep-dir "deps"]
    (when (fs/exists? (fs/dir dep-dir))
      (cmd "rm" "-r" dep-dir))
    (mkdir dep-dir)
    (assoc project :dependencies
           (vec (tree-seq :dependencies child-fn project)))))
