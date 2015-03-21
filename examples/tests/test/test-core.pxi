(ns test-core
  (use 'core)
  (require pixie.test :as t))

(t/deftest test-greet
  (t/assert= (greet "Jane") "Hello, Jane!"))
