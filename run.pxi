(require dust.project :as p)
(refer 'dust.project :only '(defproject))

(require dust.deps :as d)
(require pixie.string :as str)
(require pixie.io :as io)
(require pixie.test :as t)

(def *all-commands* (atom {}))

(defn load-project
  "Perform all necessary steps to load a project."
  []
  (load-file "project.pxi")
  (d/get-deps @p/*project*))

(defmacro defcmd
  [name description params & body]
  (let [body (if (:no-project (meta name))
               body
               (cons '(load-project) body))
        cmd {:name (str name)
             :description description
             :params `(quote ~params)
             :cmd (cons `fn (cons params body))}]
    `(do (swap! *all-commands* assoc '~name ~cmd)
         '~name)))

(defcmd describe
  "Describe the current project."
  []
  (p/describe @p/*project*))

(defcmd deps
  "List the dependencies and their versions of the current project."
  []
  (doseq [dep (:dependencies @p/*project*)]
    (println (:name dep) (:version dep))))

(defcmd load-path
  "Print the load path of the current project.
  when format is 'option', write .load-path file"
  [& [format]]
  (let [path-fn (fn [{:keys [path source-paths]}]
                  (if path
                    (map #(str path "/" %) source-paths)
                    source-paths))
        deps (:dependencies @p/*project*)
        paths (mapcat path-fn (conj deps @p/*project*))]
    (if (= format "option")
      (io/spit ".load-path" (str "--load-path " (str/join " --load-path " paths)))
      (doseq [path paths] (println path)))))

(defcmd ^:no-project repl
  "Start a REPL in the current project."
  []
  (throw (str "This should be invoked by the wrapper.")))

(defcmd ^:no-project run
  "Run the code in the given file."
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
  (println "Usage: dust <cmd> <options>\n")
  (println "Available commands:")
  (doseq [{:keys [name description]} (vals @*all-commands*)]
    (println (str "  " name (apply str (repeat (- 10 (count name)) " ")) description))))

(defcmd ^:no-project help
  "Display the help"
  [& [cmd]]
  (if cmd
    (help-cmd cmd)
    (help-all)))

(def *command* (first program-arguments))

(let [cmd (get @*all-commands* (symbol *command*))]
  (if cmd
    (apply (get cmd :cmd) (next program-arguments))
    (println "Unknown command:" *command*)))
