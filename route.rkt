#lang racket/base

;; code from https://defn.io/2020/02/12/racket-web-server-guide/, tks

(require net/url
         web-server/dispatch
         (prefix-in files: web-server/dispatchers/dispatch-files)
         (prefix-in filter: web-server/dispatchers/dispatch-filter)
         (prefix-in sequencer: web-server/dispatchers/dispatch-sequencer)
         web-server/dispatchers/filesystem-map
         web-server/http
         web-server/servlet-dispatch
         web-server/web-server)

(define (response/template . content)
  (response/xexpr
   `(html
     (head
      (link ([href "/static/screen.css"] [rel "stylesheet"])))
     (body
      ,@content))))

(define (homepage req)
  (response/template '(h1 "Home")))

(define (blog req)
  (response/template '(h1 "Blog")))

(define (not-found req)
  (response/template '(h1 "Not Found")))

(define-values (app reverse-uri)
  (dispatch-rules
   [("") homepage]
   [("blog") blog]))

(define url->path/static (make-url->path "static"))

(define static-dispatcher
  (files:make #:url->path (lambda (u)
                            (url->path/static
                             (struct-copy url u [path (cdr (url-path u))])))))

(define stop
  (serve
   #:dispatch (sequencer:make
               (filter:make #rx"^/static/" static-dispatcher)
               (dispatch/servlet app)
               (dispatch/servlet not-found))
   #:listen-ip "127.0.0.1"
   #:port 8000))

(with-handlers ([exn:break? (lambda (e)
                              (displayln "will stop server, cuz event: ")
                              (displayln e)
                              (stop))])
  (sync/enable-break never-evt))
