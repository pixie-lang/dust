(require pixie.project :as p)
(refer 'pixie.project :only '(defproject))

(def *command* (first program-arguments))

(cond
 (= *command* "describe") (do (load-file "project.pxi")
                              (p/describe @p/*project*))
 :else (println "Unknown command:" *command*))
