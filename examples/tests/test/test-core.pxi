(ns test-core
  (:require [pixie.test :as t]
            [core :refer :all]))

(t/deftest test-greet
  (t/assert= (greet "Jane") "Hello, Jane!"))
