;;; sly-code-lens.el --- Code lens for Sly showing function/macro usage -*- lexical-binding: t; -*-

;; Author: Lari <ralii>
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.1") (sly "1.0.0"))
;; Keywords: languages, lisp, tools
;; URL: https://github.com/ralii/sly-code-lens

;; This file is not part of GNU Emacs.

;;; License:
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; Commentary:
;; Provides code lens functionality for Common Lisp buffers using Sly.
;; Shows inline overlays with usage counts for functions and macros
;; using SBCL's sb-introspect package.
;;
;; Usage:
;;   M-x sly-code-lens-refresh    - Add reference counts to all defun/defmacro
;;   M-x sly-code-lens-show-uses-at-point - Show count for symbol at point
;;
;; The package automatically refreshes when opening Lisp files with an
;; active SLY connection.

;;; Code:

(require 'sly)

(defun sly-code-lens--get-buffer-package ()
  "Get the package declaration from current buffer."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^(in-package[ \t\n]+#?:\\([^)]+\\)" nil t)
      (match-string 1))))

(defun sly-code-lens-count-function-uses (symbol)
  "Query SBCL via SLY for how many times SYMBOL is called using sb-introspect:who-calls."
  (let* ((form (format "(progn (use-package :sb-introspect) (length (sb-introspect:who-calls '%s)))" symbol))
         (result (sly-eval `(slynk:eval-and-grab-output ,form)
                           (sly-code-lens--get-buffer-package))))
    (car (read-from-string (car (cdr result))))))

(defun sly-code-lens-count-macro-uses (symbol)
  "Query SBCL via SLY for how many times SYMBOL is macroexpanded using sb-introspect:who-macroexpands."
  (let* ((form (format "(progn (use-package :sb-introspect) (length (sb-introspect:who-macroexpands '%s)))" symbol))
         (result (sly-eval `(slynk:eval-and-grab-output ,form)
                           (sly-code-lens--get-buffer-package))))
    (car (read-from-string (car (cdr result))))))

(defun sly-code-lens-show-uses-at-point ()
  "Display call count for function at point using sb-introspect:who-calls."
  (interactive)
  (let* ((symbol (thing-at-point 'symbol t))
         (count (when symbol (sly-code-lens-count-function-uses symbol))))
    (if symbol
        (message "Function `%s` is called %d time(s)." symbol count)
      (message "No symbol at point."))))

(defun sly-code-lens-remove-overlays ()
  "Remove all usage count overlays from the buffer."
  (remove-overlays (point-min) (point-max) 'sly-code-lens-overlay t))

(defface sly-code-lens-face
  '((t :inherit shadow :height 0.9))
  "Face for code lens overlays showing reference counts."
  :group 'sly)

(defun sly-code-lens--add-overlay (count)
  "Add an inline overlay showing COUNT uses for the symbol at point."
  (when count
    (let ((ov (make-overlay (line-end-position) (line-end-position))))
      (overlay-put ov 'sly-code-lens-overlay t)
      (overlay-put ov 'after-string
                   (propertize (format "  %d %s" count (if (= count 1) "reference" "references"))
                               'face 'sly-code-lens-face)))))

(defun sly-code-lens--add-overlay-at-point (&optional is-macro)
  "Add an inline overlay showing how many times the function/macro at point is called.
If IS-MACRO is non-nil, count macro expansions instead of function calls."
  (let* ((symbol (thing-at-point 'symbol t))
         (count (when symbol
                  (if is-macro
                      (sly-code-lens-count-macro-uses symbol)
                    (sly-code-lens-count-function-uses symbol)))))
    (sly-code-lens--add-overlay count)))

(defun sly-code-lens-refresh ()
  "Add usage overlays for all defuns and defmacros in the buffer."
  (interactive)
  (sly-code-lens-remove-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^(def\\(un\\|macro\\)\\s-+\\(\\_<[^ )]+\\_>\\)" nil t)
      (let ((type (match-string 1))
            (name (match-string 2)))
        (goto-char (match-end 2))
        (sly-code-lens--add-overlay-at-point (string= type "macro"))))))

(defun sly-code-lens--on-mode-hook ()
  "Analyze function usage when opening a Lisp buffer with SLY."
  (when (and (bound-and-true-p sly-mode)
             (sly-connected-p))
    (sly-code-lens-refresh)))

(add-hook 'sly-mode-hook 'sly-code-lens--on-mode-hook)

(provide 'sly-code-lens)
;;; sly-code-lens.el ends here
