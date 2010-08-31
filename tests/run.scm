(use html-utils)

(use posix test html-tags)

(test-begin "html-utils")

;;; combo-box
(test "<select name='test' id='test'><option value='1'>1</option><option value='2'>2</option><option value='3'>3</option></select>"
      (combo-box "test" '(1 2 3)))

(test "<select name='test' id='test'><option value='1'>1</option><option value='2'>2</option><option value='3'>3</option></select>"
      (combo-box "test" '((1 1) (2 2) (3 3))))

(test "<select name='test' id='test'><option value='1'>1</option><option value='2'>2</option><option value='3'>3</option></select>"
      (combo-box "test" '((1 . 1) (2 . 2) (3 . 3))))

(test "<select name='test' id='test'><option value='1'>1</option><option value='2'>2</option><option value='3'>3</option></select>"
      (combo-box "test" '(#(1 1) #(2 2) #(3 3))))

(test "<select name='test' id='test'><option value='1' selected>1</option><option value='2'>2</option><option value='3'>3</option></select>"
      (combo-box "test" '(#(1 1) #(2 2) #(3 3)) default: 1))

(test "<select name='test' id='test'><option></option><option value='1'>1</option><option value='2'>2</option><option value='3'>3</option></select>"
      (combo-box "test" '(#(1 1) #(2 2) #(3 3)) first-empty: #t))

(test "<select name='test' id='test'><option></option><option value='1'>1</option><option value='2' selected>2</option><option value='3'>3</option></select>"
      (combo-box "test" '(#(1 1) #(2 2) #(3 3)) first-empty: #t default: 2))

(test "<select name='test' id='test'><option selected></option><option value='1'>1</option><option value='2'>2</option><option value='3'>3</option></select>"
      (combo-box "test" '(#(1 1) #(2 2) #(3 3)) first-empty: #t default: ""))

;;; hidden-input
(test "<input type='hidden' name='test' id='test'>"
      (hidden-input "test"))

(test "<input type='hidden' name='test' id='test' value='0'>"
      (hidden-input "test" 0))

(test "<input type='hidden' id='test' name='test' value='0'><input type='hidden' id='test2' name='test2' value='1'>"
      (hidden-input '((test . 0) (test2 . 1))))


;;; itemize
(test "<ul><li>a</li><li>b</li><li>c</li></ul>"
      (itemize '(a b c)))

(test "<ul id='test'><li>a</li><li>b</li><li>c</li></ul>"
      (itemize '(a b c) list-id: "test"))


;;; enumerate
(test "<ol><li>a</li><li>b</li><li>c</li></ol>"
      (enumerate '(a b c)))

(test "<ol id='test'><li>a</li><li>b</li><li>c</li></ol>"
      (enumerate '(a b c) list-id: "test"))


;;; tabularize
(test "<table><tr><td>1</td><td>2</td><td>3</td></tr><tr><td>4</td><td>5</td><td>6</td></tr></table>"
      (tabularize '((1 2 3) (4 5 6))))

(test "<table id='test'><tr><td>1</td><td>2</td><td>3</td></tr><tr><td>4</td><td>5</td><td>6</td></tr></table>"
      (tabularize '((1 2 3) (4 5 6)) table-id: "test"))

(test "<table id='test'><tr class='yellow'><td>1</td><td>2</td><td>3</td></tr><tr class='blue'><td>4</td><td>5</td><td>6</td></tr></table>"
      (tabularize '((1 2 3) (4 5 6)) table-id: "test" even-row-class: "yellow" odd-row-class: "blue"))

(test "<table><tr><th>a</th><th>b</th><th>c</th></tr><tr><td>1</td><td>2</td><td>3</td></tr><tr><td>4</td><td>5</td><td>6</td></tr></table>"
      (tabularize '((1 2 3) (4 5 6)) header: '(a b c)))

;;; html-page
(test "<html><head></head><body></body></html>"
      (html-page ""))

(test "<test-doctype><html><head></head><body></body></html>"
      (html-page "" doctype: "<test-doctype>"))

(test "<html><head><title>title</title></head><body></body></html>"
      (html-page "" title: "title"))

(test "<html><head><title>title</title><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'></head><body></body></html>"
      (html-page "" title: "title" charset: "UTF-8"))

(test "<html><head><title>title</title><script type='text/javascript' src='js.js'></script></head><body></body></html>"
      (html-page ""
                 title: "title"
                 headers: (<script> type: "text/javascript" src: "js.js")))

(test "<html><head><title>title</title><link rel='stylesheet' href='style.css' type='text/css'><script type='text/javascript' src='js.js'></script></head><body></body></html>"
      (html-page ""
                 title: "title"
                 headers: (<script> type: "text/javascript" src: "js.js")
                 css: "style.css"))

(test "<html><head><title>title</title><link rel='stylesheet' href='style.css' type='text/css'><script type='text/javascript' src='js.js'></script></head><body></body></html>"
      (html-page ""
                 title: "title"
                 headers: (<script> type: "text/javascript" src: "js.js")
                 css: '("style.css")))

(test "<html><head><title>title</title><link rel='stylesheet' href='style.css' type='text/css'><link rel='stylesheet' href='style2.css' type='text/css'><script type='text/javascript' src='js.js'></script></head><body></body></html>"
      (html-page ""
                 title: "title"
                 headers: (<script> type: "text/javascript" src: "js.js")
                 css: '("style.css" "style2.css")))

(test "<html><head><title>title</title><link rel='stylesheet' href='style.css' type='text/css'><style>body { font-size: 10pt; }
</style><script type='text/javascript' src='js.js'></script></head><body></body></html>"
      (let ((page #f))
        (with-output-to-file "style2.css" (cut print "body { font-size: 10pt; }"))
        (set! page
              (html-page ""
                         title: "title"
                         headers: (<script> type: "text/javascript" src: "js.js")
                         css: '("style.css" ("style2.css"))))
        (delete-file "style2.css")
        page))

(test-end "html-utils")
