(require dust.project :as p)
(refer 'dust.project :only '(defproject))

(require pixie.string :as str)
(require pixie.test :as t)

(def *all-commands* (atom {}))

(defmacro defcmd [name description params & body]
  (let [f (cons `fn (cons params body))
        cmd {:name (str name)
             :description description
             :params `(quote ~params)
             :cmd f}]
    `(do (swap! *all-commands*
                assoc '~name ~cmd)
         '~name)))

(defcmd describe "Describe the current project."
  []
  (load-file "project.pxi")
  (p/describe @p/*project*))

(defcmd deps "List the dependencies and their versions of the current project."
  []
  (load-file "project.pxi")
  (doseq [dep (:dependencies @p/*project*)]
    (println (:name dep) (:version dep))))

(defn echo [& args]
  (apply println "echo" args))

(defn mkdir [dir]
  (println "mkdir" "-p" dir))

(defn rm [file]
  (println "rm" file))

(defn download [url file]
  (println "curl" "--silent" "--location" "--output" file url))

(defn extract-to [archive dir]
  (mkdir dir)
  (println "tar" "--strip-components" 1 "--extract" "--directory" dir "--file" archive))

(defcmd get-deps "Download the dependencies of the current project."
  []
  (load-file "project.pxi")

  (mkdir "deps")
  (doseq [{:keys [name version ref]} (get @p/*project* :dependencies)]
    (echo "Downloading" name)
    (let [download-url (str "https://github.com/" name "/archive/" version ".tar.gz")
          file-name (str "deps/" (str/replace (str name) "/" "-") ".tar.gz")
          dep-dir (str "deps/" name)]
      (download download-url file-name)
      (extract-to file-name dep-dir)
      (rm file-name))))

(defcmd load-path "Print the load path of the current project."
  [& [format]]
  (load-file "project.pxi")
  (let [print-fn (if (= format "option")
                   #(print "--load-path" % "")
                   println)
        project @p/*project*]
    (doseq [path (get project :source-paths)]
      (print-fn path))
    (doseq [{:keys [name]} (get project :dependencies)]
      (print-fn (str "deps/" name "/src")))))

(defcmd repl "Start a REPL in the current project."
  []
  (throw (str "This should be invoked by the wrapper.")))

(defcmd run "Run the code in the given file."
  [file]
  (throw (str "This should be invoked by the wrapper.")))

(defcmd test "Run the tests of the current project."
  [& args]
  (println @load-paths)

  (t/load-all-tests)

  (let [result (apply t/run-tests args)]
    (exit (get result :fail))))

(defn help-cmd [cmd]
  (let [{:keys [name description params] :as info} (get @*all-commands* (symbol cmd))]
    (if info
      (do
        (println (str "Usage: dust " name " " params))
        (println)
        (println description))
      (println "Unkown command:" cmd))))

(defn help-all []
  (println "Usage: dust <cmd> <options>")
  (println)
  (println "Availlable commands:")
  (doseq [{:keys [name description]} (vals @*all-commands*)]
    (println (str "  " name (apply str (repeat (- 10 (count name)) " ")) description))))

(defcmd help "Display the help"
  [& [cmd]]
  (if cmd
    (help-cmd cmd)
    (help-all)))

(def *command* (first program-arguments))

(let [cmd (get @*all-commands* (symbol *command*))]
  (if cmd
    (apply (get cmd :cmd) (next program-arguments))
    (println "Unknown command:" *command*)))
