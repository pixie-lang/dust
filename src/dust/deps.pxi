(ns dust.deps
  (require pixie.string :as str)
  (require dust.util :as util))

(defn download [url file]
  (println "curl" "--silent" "--location" "--output" file url))

(defn extract-to
  [archive dir]
  (util/mkdir dir)
  (println "tar" "--strip-components" 1 "--extract" "--directory" dir "--file" archive))

(defn list-deps
  [project]
  (doseq [dep (:dependencies project)]
    (println (:name dep) (:version dep))))

(defn get-deps
  [project]
  (util/mkdir "deps")
  (doseq [{:keys [name version ref]} (:dependencies project)]
    (util/echo "Downloading" name)
    (let [download-url (str "https://github.com/" name "/archive/" version ".tar.gz")
          file-name (str "deps/" (str/replace (str name) "/" "-") ".tar.gz")
          dep-dir (str "deps/" name)]
      (download download-url file-name)
      (extract-to file-name dep-dir)
      (util/rm file-name))))
