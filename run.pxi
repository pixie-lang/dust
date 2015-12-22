(require dust.project :as p)
(refer 'dust.project :only '(defproject load-project!))

(require dust.deps :as d)
(require pixie.string :as str)
(require pixie.io :as io)
(require pixie.fs :as fs)
(require pixie.test :as t)



(def *all-commands* (atom {}))
(def unknown-command (atom true))
(def show-all (atom false))
(def namespaces (atom '(""  "pixie.async" "pixie.math" "pixie.stacklets" "pixie.system" "pixie.buffers" "pixie.test" "pixie.channels" "pixie.parser" "pixie.time" "pixie.csp" "pixie.uv" "pixie.repl" "pixie.streams" "pixie.ffi-infer" "pixie.io.common" "pixie.io.tty" "pixie.io.tcp" "pixie.io.uv-common" "pixie.io" "pixie.io-blocking" "pixie.fs" "pixie.set" "pixie.string" "pixie.walk")))


(defmacro defcmd
  [name description params & body]
  (let [body (if (:no-project (meta name))
               body
               (cons `(load-project!) body))
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


(defn showdoc [ns function]
  (let [name (str (if (not= ns "") (str ns "/") ""))]
  ;loads other possible namespaces in case function is in other namespace
    (if (= @show-all true) (eval (read-string (str "(require " ns ")"))))
      
    (def data (meta (eval (read-string (str name function)))))
      (if (nil? data)
        (#(%) 
          (println (str "\n  " name function "\n\n\t No documentation available.\n"))
          (reset! unknown-command false)
          (if (= (first @namespaces) "") (reset! namespaces '())))
        (#(%)
          (print (str "\n  " name function)) 
          (print 
            (if (not= (str (:added data)) "nil") 
                (str " (added: v" (:added data) ")") 
                (str ""))) 
          (print (str "\n\n\t"))
          (println
            (if (not= (str (:doc data)) "nil") 
                (str (:doc data) "\n")
                (str "No documentation available.\n"))) 
          (reset! unknown-command false)
          (if (= (first @namespaces) "")
            (reset! namespaces '()))))))

(defcmd doc
  "Show function documentation. Broaden search using -all"
  [function-name & search-all]
  (if (= (str (first search-all)) "-all") (reset! show-all true))
  (loop [_ 0]
    (when (not= @namespaces '()) 
      (try (showdoc (str (first @namespaces)) (str function-name))
        (catch e
         nil)) 
         (recur (reset! namespaces (rest @namespaces)))))
  (if (= @unknown-command true) (println (str "\n  " function-name "\n\n\t Function not found. " (if (not= (str (first search-all)) "-all") (str "Broaden search using -all flag.\n") (str "\n"))))))

(defcmd deps
  "List the dependencies and their versions of the current project."
  []
  (doseq [[name version] (:dependencies @p/*project*)]
    (println name version)))

(defcmd load-path
  "Print the load path of the current project."
  []
  (when (not (fs/exists? (fs/file ".load-path")))
    (println "Please run `dust get-deps`")
    (exit 1))
  (doseq [path (str/split (io/slurp ".load-path") "--load-path")]
    (when (not (str/empty? path))
      (println (str/trim path)))))

(defcmd get-deps
  "Download the dependencies of the current project."
  []
  (-> @p/*project* d/get-deps d/write-load-path))

(defcmd ^:no-project repl
  "Start a REPL in the current project."
  []
  (throw (str "This should be invoked by the wrapper.")))

(defcmd ^:no-project run
  "Run the code in the given file."
  [file]
  (throw (str "This should be invoked by the wrapper.")))

(defn load-tests [dirs]
  (println "Looking for tests...")
  (let [dirs (distinct (map fs/dir dirs))
        pxi-files (->> dirs
                       (mapcat fs/walk-files)
                       (filter #(fs/extension? % "pxi"))
                       (filter #(str/starts-with? (fs/basename %) "test-"))
                       (distinct))]
    (foreach [file pxi-files]
             (println "Loading " file)
             (load-file (fs/abs file)))))

(defcmd test "Run the tests of the current project."
  [& args]
  (println @load-paths)

  (load-tests (:test-paths @p/*project*))

  (let [result (apply t/run-tests args)]
    (exit (get result :fail))))

(defn help-cmd [cmd]
  (let [{:keys [name description params] :as info} (get @*all-commands* (symbol cmd))]
    (if info
      (do
        (println (str "Usage: dust " name " " params))
        (println)
        (println description))
      (println "Unknown command:" cmd))))

(defn help-all []
  (println "Usage: dust <cmd> <options>")
  (println)
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
  (try
    (if cmd
      (apply (get cmd :cmd) (next program-arguments))
      (println "Unknown command:" *command*))
    (catch :dust/Exception e
      (println (str "Dust encountered an error: " (pr-str (ex-msg e)))))))
