(ns dust.util)

(defn echo [& args]
  (apply println "echo" args))

(defn rm [file]
  (println "rm" file))

(defn mkdir [file]
  (println "mkdir" "-p" file))
