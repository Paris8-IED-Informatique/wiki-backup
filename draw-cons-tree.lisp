; Original version in scheme:  http://www.t3x.org/s9fes/draw-tree.scm.html
; Scheme 9 from Empty Space, Function Library
; By Nils M Holm, 2009-2012
; Placed in the Public Domain
;
; Ported to Common Lisp (CLISP) by Britney Spears
; Minimal porting, in Paris 8 IED flavor of Common Lisp
; Public domain, like the original

(defparameter *nothing* (cons 'N nil))
(defparameter *visited* (cons 'V nil))

(defun newline () (format t "~%"))

(defun emptyp (x) (equal x *nothing*))

(defun visitedp (x) (equal (car x) *visited*))

(defun mark-visited (x) (cons *visited* x))

(defun members-of (x) (cdr x))

(defun donep (x) 
  (and 
    (consp x) 
    (visitedp x) 
    (null (cdr x)) ) )

(defun draw-fixed-string (s &aux b)
  (setq b (make-string 8 :initial-element #\space))
  (setq 
    s 
    (cond
      ((> (length s) 7) (subseq s 0 7))
      ((< (length s) 3) (string-concat " " s))
      (t s) ) )
  (format t (string-concat s (subseq b 0 (- 8 (length s))))) )

(defun draw-atom (n) 
  (cond 
    ((null n) (draw-fixed-string "nil"))
    ((eq n t) (draw-fixed-string "t"))
    ((symbolp n) (draw-fixed-string (string n)))
    ((numberp n) (draw-fixed-string (write-to-string n)))
    ((stringp n) (draw-fixed-string (string-concat "\"" n "\"")))
    ((characterp n) (draw-fixed-string (string-concat "#\\" (string n))))
    (t (draw-fixed-string "X")) ) )

(defun draw-conses (n &optional r)
  (cond 
    ((not (consp n)) (draw-atom n) (reverse r))
    ((null (cdr n)) (format t "[o|/]") (reverse (cons (car n) r)))
    (t (format t "[o|o]---") (draw-conses (cdr n) (cons (car n) r))) ) )

(defun draw-bars-aux (n)
  (cond 
    ((not (consp n)))
    ((emptyp (car n)) (draw-fixed-string "") (draw-bars-aux (cdr n))) 
    ((and (consp (car n)) (visitedp (car n))) (draw-bars-aux (members-of (car n))) (draw-bars-aux (cdr n)))
    (t (draw-fixed-string "|") (draw-bars-aux (cdr n))) ) )

(defun draw-bars (n)
  (draw-bars-aux (members-of n)) )

(defun skip-empty (n)
  (cond
    ((and 
        (consp n) 
        (or (emptyp (car n)) (donep (car n))) ) 
      (skip-empty (cdr n)) )
    (t n) ) )

(defun remove-trailing-nothing (n)
  (reverse (skip-empty (reverse n))) )

(defun all-verticalp (n)
  (or 
    (not (consp n))
    (and (null (cdr n)) (all-verticalp (car n))) ) )

(defun draw-members-aux (n r)
  (cond 
    ((not (consp n)) (mark-visited (remove-trailing-nothing (reverse r))))
    ((emptyp (car n)) (draw-fixed-string "") (draw-members-aux (cdr n) (cons *nothing* r)))
    ((not (consp (car n))) (draw-atom (car n)) (draw-members-aux (cdr n) (cons *nothing* r)))
    ((null (cdr n)) (draw-members-aux (cdr n) (cons (draw-final (car n)) r)))
    ((all-verticalp (car n)) (draw-fixed-string "[o|/]") (draw-members-aux (cdr n) (cons (caar n) r)))
    (t (draw-fixed-string "|") (draw-members-aux (cdr n) (cons (car n) r))) ) )

(defun draw-members (n)
  (draw-members-aux (members-of n) nil) )

(defun draw-final (n)
  (cond 
    ((not (consp n)) (draw-atom n) *nothing*)
    ((visitedp n) (draw-members n))
    (t (mark-visited (draw-conses n))) ) )

(defun draw-tree-aux (n)
   (cond 
    ((not (donep n))
      (newline)
      (draw-bars n)
      (newline)
      (draw-tree-aux (draw-members n)) ) ) )

(defun draw-tree (n)
  (cond 
    ((not (consp n)) (draw-atom n))
    (t (draw-tree-aux (mark-visited (draw-conses n)))) )
  (newline) )
