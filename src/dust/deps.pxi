(ns dust.deps
  (require pixie.string :as str)
  (require pixie.io :as io)
  (require dust.util :as util)
  (require dust.project :as p))

(def *deps* (atom {}))

(defn- download [url file]
  (println "curl" "--silent" "--location" "--output" file url))

(defn- extract-to [archive dir]
  (util/mkdir dir)
  (println "tar" "--strip-components" 1 "--extract" "--directory" dir "--file" archive))

;; -----------------------------------------------------
;; should be moved into stdlib if needed
(defn tree-seq
   [branch? children root]
   (let [walk (fn walk [node]
                (lazy-seq
                 (cons node
                   (when (branch? node)
                     (mapcat walk (children node))))))]
     (walk root)))
;; -----------------------------------------------------

(defn- resolve-dependency
  "Download and extract dependency - return dependency project map"
  [{:keys [name version]}]
  (let [url (str "https://github.com/" name "/archive/" version ".tar.gz")
        file-name (str "deps/" (str/replace (str name) "/" "-") ".tar.gz")
        dep-dir (str "deps/" name)]
    (when (not (contains? @*deps* name))
      (util/echo "Downloading" name)
      (download url file-name)
      (extract-to file-name dep-dir)
      (util/rm file-name)
      (swap! *deps* assoc name version)
      (-> (io/slurp (str dep-dir "/project.pxi"))
          (read-string)
          (rest)
          (p/project->map)))))

(defn get-deps
  [project]
  (let [child-fn #(map resolve-dependency (:dependencies %))]
    (vec (tree-seq :dependencies child-fn project))))
