(module html-utils
  (tabularize
   itemize
   enumerate
   html-page
   combo-box
   hidden-input
   text-input
   submit-input)

(import chicken scheme files data-structures posix utils)
(use html-tags srfi-13 srfi-1)

(define (list-attribs attribs)
  (let ((attribs
         (filter-map (lambda (attrib)
                       (let ((value (cdr attrib)))
                         (and value
                              (list (car attrib) value))))
                     attribs)))
    (if (null? attribs)
        '()
        (list (cons '@ attribs)))))


;;; tabularize
(define (sxml-tabularize data #!key table-id table-class even-row-class odd-row-class header thead/tbody)
  (let ((even-row #f))
    (append '(table)
            (list-attribs `((id . ,table-id)
                            (class . ,table-class)))
            (if header
                (let ((h `(tr ,@(map (lambda (item) `(th ,item)) header))))
                  (if thead/tbody
                      `((thead ,h))
                      `(,h)))
                '())
            (let ((body
                   (map (lambda (line)
                          (append '(tr)
                                  (list-attribs `((class . ,(if even-row
                                                                even-row-class
                                                                odd-row-class))))
                                  (begin
                                    (set! even-row (not even-row))
                                    (map (lambda (cell) `(td ,cell)) line))))
                        data)))
              (if thead/tbody
                  `((tbody ,body))
                  body)))))


(define (tabularize data #!key table-id table-class quote-procedure even-row-class odd-row-class header thead/tbody)
  (if (generate-sxml?)
      (sxml-tabularize data
                       table-id: table-id
                       table-class: table-class
                       even-row-class: even-row-class
                       odd-row-class: odd-row-class
                       header: header
                       thead/tbody: thead/tbody)
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
                        body)))))))


;;; itemize & enumerate
(define (sxml-list listing self items #!key list-id list-class)
  (cons listing
        (append
         (list-attribs `((id . ,list-id)
                         (class . ,list-class)))
         (map (lambda (item)
                (if (list? item)
                    (self item)
                    `(li ,item)))
              items))))

(define (html-list listing self items #!key list-id list-class quote-procedure)
  (if (generate-sxml?)
      (sxml-list 'ul
                 itemize
                 items
                 list-id: list-id
                 list-class: list-class)
      (listing id: list-id class: list-class quote-procedure: quote-procedure
               (string-intersperse
                (map (lambda (item)
                       (if (list? item)
                           (self item quote-procedure: quote-procedure)
                           (<li> item)))
                     items)
                ""))))

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


;;; html-page
(define (sxml-page contents #!key css title doctype headers charset)
  (let ((page
         `(html
           ,(append '(head)
                    (if title `((title ,title)) '())
                    (if charset
                        `((meta (@ (http-equiv "Content-Type")
                                   (content ,(string-append "text/html; charset=" charset)))))
                        '())
                    (cond ((string? css)
                           `((link (@ (rel "stylesheet")
                                      (href ,css)
                                      (type "text/css")))))
                          ((list? css)
                           (map (lambda (f)
                                  (if (list? f)
                                      `(style ,(read-all (make-pathname (current-directory) (car f))))
                                      `(link (@ (rel "stylesheet")
                                                (href ,f)
                                                (type "text/css")))))
                                css))
                          (else '()))
                    (if headers `(,headers) '()))
           ,(if (string? contents)
                `(body ,contents)
                `(body ,@contents)))))
    (if doctype
        (append `((literal ,doctype)) `(,page))
        page)))

(define (html-page contents #!key css title doctype headers charset)
  (if (generate-sxml?)
      (sxml-page contents
                 css: css
                 title: title
                 doctype: doctype
                 headers: headers
                 charset: charset)
      (string-append
       (or doctype "")
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
                (string-intersperse
                 (map (lambda (f)
                        (if (list? f)
                            (<style> (read-all (make-pathname (current-directory) (car f))))
                            (<link> rel: "stylesheet" href: f type: "text/css")))
                      css)
                 ""))
               (else ""))
         (or headers ""))
        (if (string-prefix-ci? "<body" contents)
            contents
            (<body> contents))))))


;;; combo-box
(define (sxml-make-options options #!optional default first-empty)
  (let ((opts (map (lambda (opt)
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
                   options)))
    (if first-empty
        (cons (<option> selected: (and default (equal? "" (->string default))))
              opts)
        opts)))

(define (make-options options #!optional default first-empty)
  (if (generate-sxml?)
      (sxml-make-options options default first-empty)
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
        ""))))

(define (combo-box name options #!key default id first-empty onchange onkeyup disabled
                   length multiple selectedindex size tabindex type class)
  (if (generate-sxml?)
      (append '(select)
              (list-attribs `((name . ,name)
                              (id . ,(or id name))
                              (onchange . ,onchange)
                              (onkeyup . ,onkeyup)
                              (disabled . ,disabled)
                              (length . ,length)
                              (multiple . ,multiple)
                              (selectedindex . ,selectedindex)
                              (size . ,size)
                              (tabindex . ,tabindex)
                              (type . ,type)
                              (class . ,class)))
              (sxml-make-options options default first-empty))
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
            (make-options options default first-empty))))


;;; inputs
(define (sxml-hidden-input name #!optional value id)
  (if (list? name)
      (map (lambda (item)
             (let ((name (->string (car item))))
               (<input> type: "hidden"
                        id: (or id name)
                        name: name
                        value: (->string (cdr item)))))
           name)
      (<input> type: "hidden" name: name id: (or id name) value: value)))

(define (hidden-input name #!optional value id)
  (if (generate-sxml?)
      (sxml-hidden-input name value id)
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
          (<input> type: "hidden" name: name id: (or id name) value: value))))

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
