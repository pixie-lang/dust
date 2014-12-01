(require pixie.project :as p)
(refer 'pixie.project :only '(defproject))

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
        (println (str "Usage: pxi " name " " params))
        (println)
        (println description))
      (println "Unkown command:" cmd))))

(defn help-all []
  (println "Usage: pxi <cmd> <options>")
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
