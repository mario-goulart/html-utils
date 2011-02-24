(module html-utils
  (tabularize
   itemize
   enumerate
   html-page
   combo-box
   hidden-input
   text-input
   password-input
   submit-input)

(import chicken scheme files data-structures posix utils)
(use html-tags srfi-13)

(define (tabularize data #!key table-id table-class quote-procedure even-row-class odd-row-class header thead/tbody)
  (let ((even-row #f))
    (<table> id: table-id class: table-class quote-procedure: quote-procedure
             (string-append
              (if header
                  (let ((h (<tr> (string-intersperse (map <th> header) ""))))
                    (if thead/tbody
                        (<thead> h)
                        h))
                  "")
              (let ((body
                     (string-intersperse
                      (map (lambda (line)
                             (<tr> class: (and even-row-class odd-row-class
                                               (begin
                                                 (set! even-row (not even-row))
                                                 (if even-row
                                                     even-row-class
                                                     odd-row-class)))
                                   (string-intersperse (map <td> line) "")))
                           data)
                      "")))
                (if thead/tbody
                    (<tbody> body)
                    body))))))

(define (html-list listing self items #!key list-id list-class quote-procedure)
  (listing id: list-id class: list-class quote-procedure: quote-procedure
           (string-intersperse
            (map (lambda (item)
                   (if (list? item)
                       (self item quote-procedure: quote-procedure)
                       (<li> item)))
                 items)
            "")))

(define (itemize items #!key list-id list-class quote-procedure)
  (html-list <ul>
             itemize
             items
             list-id: list-id
             list-class: list-class
             quote-procedure: quote-procedure))

(define (enumerate items #!key list-id list-class quote-procedure)
  (html-list <ol>
             enumerate
             items
             list-id: list-id
             list-class: list-class
             quote-procedure: quote-procedure))

(define (html-page contents #!key css title (doctype "") (headers "") charset)
  (string-append
   doctype
   (<html>
    (<head>
     (if title (<title> title) "")
     (if charset
         (<meta> http-equiv: "Content-Type"
                 content:  (string-append "text/html; charset=" charset))
         "")
     (cond ((string? css)
            (<link> rel: "stylesheet" href: css type: "text/css"))
           ((list? css)
            (let ((inline ""))
              (string-intersperse
               (map (lambda (f)
                      (if (list? f)
                          (<style> (read-all (make-pathname (current-directory) (car f))))
                          (<link> rel: "stylesheet" href: f type: "text/css")))
                    css)
               "")))
           (else ""))
     headers)
    (if (string-prefix-ci? "<body" contents)
        contents
        (<body> contents)))))


(define (make-options options #!optional default first-empty)
  (string-append
   (if first-empty
       (<option> selected: (and default (equal? "" (->string default))))
       "")
   (string-intersperse
    (map (lambda (opt)
           (let ((val (->string (cond ((pair? opt) (car opt))
                                      ((vector? opt) (vector-ref opt 0))
                                      (else opt))))
                 (text (->string (cond ((list? opt) (cadr opt))
                                       ((pair? opt) (cdr opt))
                                       ((vector? opt) (vector-ref opt 1))
                                       (else opt)))))
             (<option> value: val
                       selected: (and default (equal? val (->string default)))
                       text)))
         options)
    "")))

(define (combo-box name options #!key default id first-empty onchange onkeyup disabled
                   length multiple selectedindex size tabindex type class)
  (<select> onchange: onchange
            onkeyup: onkeyup
            disabled: disabled
            length: length
            multiple: multiple
            selectedindex: selectedindex
            size: size
            tabindex: tabindex
            type: type
            name: name
            id: (or id name)
            class: class
            (make-options options default first-empty)))

(define (hidden-input name #!optional value id)
  (if (list? name)
      (string-intersperse
       (map (lambda (item)
              (let ((name (->string (car item))))
                (<input> type: "hidden"
                         id: (or id name)
                         name: name
                         value: (->string (cdr item)))))
            name)
       "")
      (<input> type: "hidden" name: name id: (or id name) value: value)))

(define (text-input name . args)
  (apply <input>
         (append
          (list type: "text"
                name: name
                id: (or (get-keyword id: args) name))
          args)))

(define (password-input name . args)
  (apply <input>
         (append
          (list type: "password"
                name: name
                id: (or (get-keyword id: args) name))
          args)))

(define (submit-input . args)
  (apply <input> type: "submit" args))

) ;; end module
