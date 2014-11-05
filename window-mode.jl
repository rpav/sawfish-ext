;;; window-mode: Switch to the WINDOW-MODE-KEYMAP on a keypress.

(require 'messages)

(defvar *window-mode* nil)
(defvar *window-mode-old-global-keymap* nil)

(defvar *window-mode-message* (make-message-window #:x 5 #:y 5))

(defcustom window-mode-global-keymap
  (bind-keys (make-keymap)
             "Super-v" 'window-mode-toggle)
  "Keymap used by WINDOW-MODE"
  :type keymap
  :group bindings
  :before-set (lambda ()
                (when *window-mode*
                  (ungrab-keymap global-keymap)))
  :after-set (lambda ()
               (when *window-mode*
                 (setq global-keymap window-mode-global-keymap)
                 (grab-keymap global-keymap))))

(defun window-mode-off ()
  (when *window-mode*
    (ungrab-keymap global-keymap)
    (setq global-keymap *window-mode-old-global-keymap*)
    (grab-keymap global-keymap)
    (grab-keymap window-keymap)
    (setq *window-mode* nil))
  (message-window-config *window-mode-message* #:bg "green")
  (message-window-display "Window mode OFF"
                          #:win *window-mode-message* #:ms 350))

(defun window-mode-on ()
  (unless *window-mode*
    (setq *window-mode-old-global-keymap* global-keymap)
    (ungrab-keymap global-keymap)
    (ungrab-keymap window-keymap)
    (setq global-keymap window-mode-global-keymap)
    (grab-keymap global-keymap)
    (setq *window-mode* t))
  (message-window-config *window-mode-message* #:bg "red")
  (message-window-display "Window mode ON"
                          #:win *window-mode-message*))

(defun window-mode-toggle ()
  (interactive)
  (if *window-mode*
      (window-mode-off)
      (window-mode-on)))

(setq before-exit-hook
      (delete-if (lambda (x) (eq (function-name x) 'window-mode-off))
                 before-exit-hook))

(setq before-exit-hook (cons #'window-mode-off before-exit-hook))
