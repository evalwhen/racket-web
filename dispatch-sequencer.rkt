#lang racket/base

(require net/url
         racket/string
         web-server/dispatchers/dispatch
         (prefix-in sequencer: web-server/dispatchers/dispatch-sequencer)
         web-server/http
         web-server/http/response
         web-server/web-server)

(define (request-path-has-prefix? req p)
  (string-prefix? (path->string (url->path (request-uri req))) p))

(define (a-dispatcher conn req)
  (if (request-path-has-prefix? req "/a/")
      (output-response conn (response/output
                             (lambda (out)
                               (displayln "hello from a" out))))
      (next-dispatcher)))

(define (b-dispatcher conn req)
  (output-response conn
                   (response/output
                    (lambda (out)
                      (displayln "hello from b" out)))))

(define stop
  (serve
   #:dispatch (sequencer:make a-dispatcher
                              b-dispatcher)
   #:listen-ip "127.0.0.1"
   #:port 8000))

(with-handlers ([exn:break? (lambda (e)
                              (stop))])
  (sync/enable-break never-evt))
