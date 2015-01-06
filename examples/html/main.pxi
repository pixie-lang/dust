(use 'hiccup.core)

(defn html-greet [name]
  (html [:h1.very-big "Hello, " name "!"]))

(let [name (or (first program-arguments) "World")]
  (println (html-greet name)))
