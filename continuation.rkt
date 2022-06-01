#lang racket/base

(require web-server/http
         web-server/http/bindings)

(require web-server/web-server
         web-server/servlet/web
         web-server/servlet-dispatch)

(define (get-number req)
  (define num-req
    (send/suspend
     (lambda (k-url)
       (response/xexpr (build-request-page "sum" k-url "")))))
  (string->number (extract-binding/single 'number (request-bindings num-req))))

(define (build-request-page label next-url hidden)
  `(html
    (head (title "Enter a Number to Add"))
    (body ([bgcolor "white"])
          (form ([action ,next-url] [method "get"])
                ,label
                (input ([type "text"] [name "number"]
                                      [value ""]))
                (input ([type "hidden"] [name "hidden"]
                                        [value ,hidden]))
                (input ([type "submit"] [name "enter"]
                                        [value "Enter"]))))))


(define (sum req)
  (response/xexpr (number->string (+ (get-number req)
                                     (get-number req)))))


(define stop
  (serve
   #:dispatch (dispatch/servlet sum)
   #:listen-ip "127.0.0.1"
   #:port 8000))

(with-handlers ([exn:break? (lambda (e)
                              (displayln "will stop server, cuz event: ")
                              (displayln e)
                              (stop))])
  (sync/enable-break never-evt))
