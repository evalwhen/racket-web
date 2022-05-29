#lang racket/base

(require racket/match
         web-server/http
         web-server/servlet-dispatch
         web-server/web-server)

(define (age req)
  (define binds (request-bindings/raw req))
  (define message
    (match (list (bindings-assq #"name" binds)
                 (bindings-assq #"age" binds))
      [(list #f #f)
       "Anonymous is unknown years old."]

      [(list #f (binding:form _ age))
       (format "Anonymous is ~a years old." age)]

      [(list (binding:form _ name) #f)
       (format "~a is unknown years old." name)]

      [(list (binding:form _ name)
             (binding:form _ age))
       (format "~a is ~a years old." name age)]))
  (response/output
   (lambda (out)
     (displayln message out))))


(define stop
  (serve
   #:dispatch (dispatch/servlet age)
   #:listen-ip "127.0.0.1"
   #:port 8000))

(with-handlers ([exn:break? (lambda (e)
                              (stop))])
  (sync/enable-break never-evt))
