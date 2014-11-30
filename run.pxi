(require pixie.project :as p)
(refer 'pixie.project :only '(defproject))

(def *command* (first program-arguments))

(cond
 (= *command* "describe") (do (load-file "project.pxi")
                              (p/describe @p/*project*))
 (= *command* "deps") (do (load-file "project.pxi")
                          (doseq [dep (:dependencies @p/*project*)]
                            (println (:name dep) (:version dep))))
 :else (println "Unknown command:" *command*))
