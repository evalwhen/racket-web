#lang racket/base

(require net/url
         (prefix-in files: web-server/dispatchers/dispatch-files)
         (prefix-in filter: web-server/dispatchers/dispatch-filter)
         (prefix-in sequencer: web-server/dispatchers/dispatch-sequencer)
         web-server/dispatchers/filesystem-map
         web-server/http
         web-server/servlet-dispatch
         web-server/web-server)

(define (homepage req)
  (response/xexpr
   '(html
     (head
      (link ([href "/static/screen.css"] [rel "stylesheet"])))
     (body
      (h1 "Hello!")))))

(define url->path/static
  (make-url->path "static"))

(define static-dispatcher
  (files:make #:url->path (lambda (u)
                            (url->path/static
                             (struct-copy url u [path (cdr (url-path u))])))))

(define stop
  (serve
   #:dispatch (sequencer:make
               (filter:make #rx"^/static/" static-dispatcher)
               (dispatch/servlet homepage))
   #:listen-ip "127.0.0.1"
   #:port 8000))

(with-handlers ([exn:break? (lambda (e)
                              (stop))])
  (sync/enable-break never-evt))
