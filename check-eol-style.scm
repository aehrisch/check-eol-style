#!/bin/sh
exec scsh -e main -s "$0" "$@"
!#

(define dir ".")

(define (get-files dir)
  (with-cwd dir
    (map string-trim-right
         (run/strings ("svn" "ls" "-R")))))

(define (get-svn-properties file-name)
  (let ((res (map string-trim-both
                  (run/strings ("svn" "proplist" ,file-name)))))
    (if (null? res)
        res
        (cdr res))))

(define (contains-eol-style-property? props)
  (member "svn:eol-style" props))

(define (set-eol-style-property file-name value)
  (display "Setting svn:eol-style on file ")
  (display file-name)
  (newline)
  (run ("svn" "propset" "svn:eol-style" ,value ,file-name)))

(define (set-unix-eol-style file-name)
  (set-eol-style-property file-name "LF"))

(define (file-has-eol-style-property? file-name)
  (let* ((props (get-svn-properties file-name))
         (has-property? (contains-eol-style-property? props)))
    (display "Checking ")
    (display file-name)
    (display " -> ")
    (display (if has-property? "ok" "need to set"))
    (newline)
    has-property?))

(define (filter-regular-files file-lst)
  (filter (lambda (file-name)
            (let ((name (string-append (cwd) "/" file-name)))
              (and (file-exists? name)
                   (not (file-directory? name)))))
          file-lst))

(define (is-text-file? file-name)
  (member (file-name-extension file-name)
	  '(".java" ".html" ".wsdl" ".xsd" ".xml" ".sig" ".jsp" ".rb" ".sh")))

(define (filter-files-without-property file-lst)
  (filter (lambda (file-name)
	    (and (is-text-file? file-name)
		 (not (file-has-eol-style-property? file-name))))
          file-lst))

(define (main . args)
  (display "Getting list of all svn-managed files...")
  (newline)
  (let* ((all-files (get-files (cwd)))
         (regular-files (filter-regular-files all-files)))
    (display "Checking for missing svn:eol-style properties...")
    (newline)
  (let* ((need-to-set (filter-files-without-property regular-files)))
    (display "Setting missing svn:eol-style properties...")
    (newline)
    (for-each set-unix-eol-style need-to-set)

    (display "Finished. Check before you commit!")
    (newline))))

;;; Local Variables:
;;; mode:scheme
;;; End:
