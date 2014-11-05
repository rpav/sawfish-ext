;;; messages: Display messages, in the "global" window or a custom one.

(require 'records)
(require 'x)

;;; If reloading this, don't invalidate old records
(unless (boundp 'message-window)
  (define-record-type message-window
      (%make-message-window xwin msg width height)
    message-window-p
    (xwin message-window-xwin %message-window-xwin-set)
    (msg message-window-message %message-window-message-set)
    (margin message-window-margin %message-window-margin-set)
    (width message-window-width %message-window-width-set)
    (height message-window-height %message-window-height-set)
    (attrs message-window-attrs %message-window-attrs-set)))

(defun message-window-draw (msgwin)
  (let* ((xwin (message-window-xwin msgwin))
         (msg (message-window-message msgwin))
         (attrs (message-window-attrs msgwin))
         (width (message-window-width msgwin))
         (height (message-window-height msgwin))
         (margin (or (message-window-margin msgwin) 20))
         (gc (x-create-gc xwin attrs))
         (new-width (+ (* 2 margin) (text-width msg))))
    (message-window-config msgwin #:w new-width)
    (x-clear-window xwin)
    (x-draw-string xwin gc (cons margin margin) msg)
    (x-destroy-gc gc)))

(defun make-message-window (#!key (msg "") (x 0) (y 0) (w 200) (h 30)
                            (border-width 2) (fg "black") (bg "white")
                            border-color)
  (let* ((msgwin (%make-message-window nil msg w h))
         (xwin (x-create-window (cons x y) (cons w h) border-width nil
                                (lambda (type xw)
                                  (message-window-draw msgwin)))))
    (%message-window-xwin-set msgwin xwin)
    (message-window-config msgwin
                           #:fg fg #:bg bg #:border-width border-width
                           #:border-color border-color)
    msgwin))

(defun message-window-destroy (msgwin)
  (let ((xwin (message-window-xwin msgwin)))
    (x-destroy-window xwin)))

(defun message-window-show (msgwin)
  (let ((xwin (message-window-xwin msgwin)))
    (x-map-window xwin)))

(defun message-window-hide (#!optional msgwin)
  (if msgwin
      (let ((xwin (message-window-xwin msgwin)))
        (x-unmap-window xwin))
      (display-message)))

(defun message-window-config (msgwin #!key x y w h fg bg margin
                              border-color border-width attrs)
  (let ((xwin (message-window-xwin msgwin)))
    (x-configure-window xwin
                        `(,@(when x `((x . ,x)))
                          ,@(when y `((y . ,y)))
                          ,@(when w `((width . ,w)))
                          ,@(when h `((height . ,h)))
                          ,@(when border-width `((border-width . ,border-width)))))
    (when w (%message-window-width-set msgwin w))
    (when h (%message-window-height-set msgwin h))
    (x-change-window-attributes xwin
                                `(,@(when bg `((background . ,(get-color bg))))
                                  ,@(when border-color `((border-color . ,(get-color border-color))))))
    (when (or fg attrs)
      (%message-window-attrs-set msgwin
                                 `(,@(when fg `((foreground . ,(get-color fg))))
                                   ,@attrs)))
    (when margin
      (%message-window-margin-set msgwin margin))
    t))

(defun message-window-display (string #!key win (sec 0) (ms 0))
  (if win
      (progn
        (%message-window-message-set win string)
        (message-window-draw win)
        (message-window-show win)
        (make-timer (lambda () (message-window-hide win)) sec ms))
      (progn
        (display-message string)
        (make-timer (lambda () (display-message)) sec ms))))
