#lang racket/base

(require (prefix-in filter: web-server/dispatchers/dispatch-filter)
         (prefix-in sequencer: web-server/dispatchers/dispatch-sequencer)
         web-server/http
         web-server/http/response
         web-server/web-server)

(define (a-dispatcher conn req)
  (output-response conn
                   (response/output
                    (lambda (out)
                      (displayln "hello from a" out)))))

(define (b-dispatcher conn req)
  (output-response conn
                   (response/output
                    (lambda (out)
                      (displayln "hello from b" out)))))

(define stop
  (serve
   #:dispatch (sequencer:make (filter:make #rx"^/a/" a-dispatcher)
                              b-dispatcher)
   #:listen-ip "127.0.0.1"
   #:port 8000))

(with-handlers ([exn:break? (lambda (e)
                              (stop))])
  (sync/enable-break never-evt))
