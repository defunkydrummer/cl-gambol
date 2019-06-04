#|
  This file is a part of gambol project.
  Copyright (c) 2013 Stephen A. Goss (steveth45@gmail.com)
|#

(in-package :cl-user)
(defpackage gambol-test
  (:use :cl
        :gambol
        :cl-test-more)
  (:shadowing-import-from :gambol :is :fail))
(in-package :gambol-test)

(defmacro test-is (got expected &rest args)
  `(cl-test-more:is ,got ,expected ,@args))

(clear-rules)
(setf *print-circle* nil)

(plan nil)


(*- (product 1 "hammer" 100 32 1299 tool))
(*- (product 2 "box of nails" 100 20 399 tool))
(*- (product 3 "t-shirt" 100 12 1399 clothing))
(*- (product 4 "baseball cap" 100 8 799 clothing))


(test-is
 (pl-solve-all '((product ?? ?name ?? ?? ?? tool)))
 '(((?NAME . "hammer"))
   ((?NAME . "box of nails")))
 "This query finds all the tools and returns the names bound to ?name.")

(test-is
 (pl-solve-all '((product ?? ?name ?? ?? ?price tool)))
 '(((?NAME . "hammer") (?PRICE . 1299))
   ((?NAME . "box of nails") (?PRICE . 399)))
 "This query finds all the tools and return list of alists of bound vars.")


(test-is
 (bagof (?name ?price) '((product ?? ?name ?? ?? ?price tool)))
 '(("hammer" 1299)
   ("box of nails" 399))
 "Finds all the tools and return a list of name and price values.")

;; (CUSTOMER id name email)

(*- (customer 1 "John Doe" "jdoe@example.org"))
(*- (customer 2 "Jim Smith" "jsmith@something.com"))
(*- (customer 3 "Frank Zappa" "fzappa@music.com"))
(*- (customer 4 "Bob Jones" "bjones@example.org"))

;; (ORDER customer-id product-id quantity)

(*- (order 1 1 10)) ;; John Doe ordered 10 hammers
(*- (order 2 1 2)) ;; Jim Smith ordered 2 hammers
(*- (order 1 2 2)) ;; John Doe ordered 2 boxes of nails
(*- (order 3 3 3)) ;; Frank Zappa ordered 3 t-shirts

(*- (cust-prod ?customer-name ?product-name)
    (customer ?customer-id ?customer-name ??)
    (order ?customer-id ?product-id ??)
    (product ?product-id ?product-name ?? ?? ?? ??))

(test-is
 (bagof (?customer ?product) '((cust-prod ?customer ?product)))
 '(("John Doe" "hammer")
   ("John Doe" "box of nails")
   ("Jim Smith" "hammer")
   ("Frank Zappa" "t-shirt"))
 "Produce a list of customer and product names for orders in system.")


(test-is
 (bagof (?customer-id ?customer-name)
        '((customer ?customer-id ?customer-name ??)))
 '((1 "John Doe")
   (2 "Jim Smith")
   (3 "Frank Zappa")
   (4 "Bob Jones"))
 "Produce a list of customer ids and names.")

(test-is
 (bagof ?product-name 
        '((cust-prod "Jim Smith" ?product-name)))
 '("hammer")
 "Produce a list of product names Jim Smith ordered.")

(*- (head ?head (?head . ??)))

(test-is
 (pl-solve-all '((head x (a b c))))
 nil
 "Verify that the symbol x is not the HEAD of the list (a b c).")

(test-is
 (pl-solve-all '((head a (a b c))))
 '(t)
 "Verify that the symbol a is the HEAD of the list (a b c).")

(test-is
 (bagof ?what '((head ?what (a b c))))
 '(a)
 "Return the value of the head of the list (a b c).")

(test-is
 (bagof ?what '((head ?what ((a b) c))))
 '((a b))
 "Return the value of the head of the nested list ((a b) c).")

(test-is
 (bagof (?h2 ?h1) '((head (?h1 ?h2) ((a b) c d))))
 '((b a))
 "Binding two values from the head of a nested list. Switch order.")

(*- (tail ?tail (?? . ?tail)))

(test-is
 (bagof ?tail '((tail ?tail (a b c))))
 '((b c))
 "Bind to the tail of a list.")

(*- (member ?value (?value . ??)))
(*- (member ?value (?? . ?tail))
    (member ?value ?tail))

(test-is
 (pl-solve-all '((member foo (a b c))))
 nil
 "Show that foo is not a member of the list (a b c).")

(test-is
 (pl-solve-all '((member 3 (1 2 3 4 5))))
 '(T)
 "Show that 3 is a member of the list (1 2 3 4 5).")

(test-is
 (bagof ?elem '((member ?elem (1 2 3 4 5))))
 '(1 2 3 4 5)
 "Recreate a list by creating a list of its members")

(*- (append (?x . ?xs) ?ys (?x . ?zs))
    (append ?xs ?ys ?zs))
(*- (append nil ?ys ?ys))

(test-is
 (bagof ?x '((append (a b) (c d) ?x)))
 '((a b c d))
 "Append (a b) and (c d) to produce (a b c d).")

(test-is
 (bagof ?y '((append ?y (c d) (a b c d))))
 '((a b))
 "Find out what list appended to (c d) will produce (a b c d).")

(*- (reverse (?x . ?xs) ?zs)
    (reverse ?xs ?ys)
    (append ?ys (?x) ?zs))
(*- (reverse nil nil))

(test-is
 (bagof ?a '((reverse (8 15 19 20 0 3 3 6 5 0 11 21 21 24 5 19) ?a)))
 '((19 5 24 21 21 11 0 5 6 3 3 0 20 19 15 8))
 "Find the reverse of a list.")

(*- (not ?p)      ; assuming a closed world...
    ?p
    (cut)
    (fail))
(*- (not ?p))

(test-is
 (pl-solve-all '((not (member 5 (1 2 3 4 5)))))
 nil
 "Negation as failure. Fail.")

(test-is
 (pl-solve-all '((not (member 6 (1 2 3 4 5)))))
 '(t)
 "Negation as failure. Succeed.")

(*- (length nil 0))
(*- (length (?? . ?t) ?n)
    (length ?t ?n1)
    (is ?n (lop (1+ ?n1))))

(test-is
 (bagof ?l '((length (1 2 3 a b c) ?l)))
 '(6)
 "Use embedded Lisp call to count a list.")

(test-is
 (bagof (?a ?b) `((is ?a ?b ,(lop (values 1 2)))))
 '((1 2))
 "Multiple values with IS and LOP.")

(*- (factorial 0 1))
(*- (factorial ?n ?f)
    (lop (> ?n 0))
    (is ?n1 (lop (1- ?n)))
    (factorial ?n1 ?f1)
    (is ?f (lop (* ?n ?f1))))

(test-is
 (bagof ?f '((factorial 33 ?f)))
 '(8683317618811886495518194401280000000)
 "Slow factorial.")

(with-rulebase (make-rulebase)

  (*- (add ?p)
      ?p
      (cut))
  (*- (add ?p)
      (assertz ?p))
  (pl-solve-all '((add (fibonacci 0 1))))

  (test-is
   (bagof (?n ?f) '((fibonacci ?n ?f)))
   '((0 1))
   "assertz"))

(with-rulebase (make-rulebase)

  (*- (add ?p)
      ?p
      (cut))
  (*- (add ?p)
      (asserta ?p))
  (*- (fibonacci 0 1))
  (*- (fibonacci 1 1))
  (pl-solve-all '((add (fibonacci glad bags))))

  (test-is
   (bagof (?n ?f) '((fibonacci ?n ?f)))
   '((glad bags) (0 1) (1 1))
   "asserta"))

(with-rulebase (make-rulebase)
  (*- (fibonacci 0 1))
  (*- (fibonacci 1 1))
  (pl-solve-all '((retract (fibonacci 0 1))))
  (test-is
   (pl-solve-one '((fibonacci 0 1)))
   nil
   "retract"))

(with-rulebase (make-rulebase)
  (*- (fibonacci 0 1))
  (*- (fibonacci 1 1)))

(test-is
 (pl-solve-all '((retract (fibonacci 0 1))))
 nil
 "isolation")

(test-is
 (let ((default-rulebase (current-rulebase)))
   (with-rulebase (make-rulebase)
     (*- (fibonacci 0 1))
     (*- (fibonacci 1 1))
     (with-rulebase default-rulebase
       (pl-solve-one '((fibonacci 0 1))))))
 nil
 "isolation2")

(test-is
 (with-rulebase (make-rulebase)
   (*- (+ ?x ?y ?sum) (= ?sum (lop (+ ?x ?y))))
   (*- (call ?f) ?f)
   (pl-solve-one '((call (+ 1 3 ?x)))))
 '((?x . 4))
 "call-test-1")

(test-is
 (with-rulebase (make-rulebase)
   (*- (+ ?x ?y ?sum) (= ?sum (lop (+ ?x ?y))))
   (pl-solve-one '((= ?y (+ 1 3 ?x)) ?y)))
 '((?y . (+ 1 3 4)) (?x . 4))
 "call-test-2")

(test-is
 (pl-solve-one '((nonvar 1)))
 t
 "nonvar-1")

(test-is
 (pl-solve-one '((nonvar ?x)))
 nil
 "nonvar-2")

(test-is
 (pl-solve-one '((= ?x 1) (nonvar ?x)))
 '((?x . 1))
 "nonvar-3")

(test-is
 (pl-solve-one '((= ?x 1) (nonvar ?y)))
 nil
 "nonvar-4")

(test-is
 (with-rulebase (make-rulebase)
   (*- (foo bar))
   (*- (foo baz))
   (*- (qux ?x ?y) (foo ?x) (foo ?y))
   (setof ?x '((qux ?x ?y))))
 '(bar baz)
 "setof")

(finalize)
