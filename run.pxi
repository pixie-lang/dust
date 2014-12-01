(require pixie.project :as p)
(refer 'pixie.project :only '(defproject))

(require pixie.test :as t)

(def *all-commands* (atom {}))

(defmacro defcmd [name description & body]
  (let [f (cons `fn body)
        cmd {:name (str name)
             :description description
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

(defcmd repl "Start a REPL in the current project."
  []
  (throw (str "This should be invoked by the wrapper.")))

(defcmd run "Run the code in the given file."
  [file]
  (throw (str "This should be invoked by the wrapper.")))

(defcmd test "Run the tests of the current project."
  []
  (println @load-paths)

  (t/load-all-tests)

  (let [result (apply t/run-tests program-arguments)]
    (exit (get result :fail))))

(defcmd help "Display the help"
  []
  (println "Usage: pxi <cmd> <options>")
  (println)
  (println "Availlable commands:")
  (doseq [{:keys [name description]} (vals @*all-commands*)]
    (println (str "  " name (apply str (repeat (- 10 (count name)) " ")) description))))

(def *command* (first program-arguments))

(let [cmd (get @*all-commands* (symbol *command*))]
  (if cmd
    (apply (get cmd :cmd) (next program-arguments))
    (println "Unknown command:" *command*)))
