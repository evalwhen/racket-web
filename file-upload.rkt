#lang web-server/insta

(require web-server/formlets
         net/base64)

(define title "File Echo Demo")

(define (start req)
  (define file
    (send/formlet*
     (formlet (#%# (p ,{=> (file-upload #:attributes '([required ""]))
                           file})
                   (p (input ([type "submit"]
                              [value "Upload"]))))
              file)
     (λ (k-url formlet-xs)
       (make-page
        "Upload a File"
        `[(p "Give me a file, and I will give it back to you.")
          (form ([method "POST"]
                 [enctype "multipart/form-data"]
                 [action ,k-url])
                ,@formlet-xs)]))))
  (redirect/get)
  (match-define (binding:file id filename-bytes headers content-bytes) file)
  (define filename
    (bytes->string/utf-8 filename-bytes))
  (send/suspend
   (λ (k-url)
     (make-page
      "Here is your file."
      `[(p (a ([href ,k-url]
               [download ,filename])
              "Click here to download it."))
        (h3 ,filename)
        ;; x-expressions save us from injection attacks :)
        ,(or (with-handlers ([exn:fail? (λ (e) #f)])
               `(pre ,(bytes->string/utf-8 content-bytes)))
             `(div (p (i "Base64-encoded"))
                   (pre ,(bytes->string/utf-8
                          (base64-encode content-bytes #"\n")))))])))
  (response/output
   #:mime-type (cond
                 [(headers-assq* #"Content-Type" headers)
                  => header-value]
                 [else
                  #f])
   #:headers (list (header #"Content-Disposition"
                           (bytes-append #"attachment; filename=\""
                                         filename-bytes
                                         ;; we assume it's correctly encoded,
                                         ;; since we got it from a header,
                                         ;; but see aslo filename* and RFC 5987
                                         #"\"")))
   (λ (out)
     (write-bytes content-bytes out))))

(define (send/formlet* formlet wrap)
  ;; unfortunately, send/formlet and embed/formlet don't
  ;; have a way to set enctype="multipart/form-data"
  (formlet-process
   formlet
   (send/suspend
    (lambda (k-url)
      (wrap k-url (formlet-display formlet))))))

(define (make-page subtitle body-xs)
  (response/xexpr
   #:preamble #"<!DOCTYPE html>"
   `(html ([lang "en"])
          (head (title ,subtitle " | " ,title)
                (meta ([charset "utf-8"]))
                (meta ([name "viewport"]
                       [content "width=device-width, initial-scale=1.0"])))
          (body
           (h1 ,title)
           (h2 ,subtitle)
           ,@body-xs))))
