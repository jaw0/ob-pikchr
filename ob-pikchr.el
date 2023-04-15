;;; ob-pikchr.el --- Babel Functions for pikchr -*- lexical-binding: t; -*-
;; Copyright (c) 2023
;; Author: Jeff Weisberg <tcp4me.com!jaw>
;; Created: 2023-Apr-15 13:20 (EDT)
;; Function: Org-Babel support for pikchr: https://pikchr.org


;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


(require 'ob)

(defvar org-babel-default-header-args:pikchr
  '((:results . "file graphics") (:exports . "results"))
  "Default arguments to use when evaluating a pikchr source block.")

(defun org-babel-execute:pikchr (body params)
  "Execute a block of pic code with org-babel.  This function is
called by `org-babel-execute-src-block' via multiple-value-bind."
  (let*
      ((processed-params (org-babel-process-params params))
       (out-file (cdr (or (assq :file processed-params)
                          (user-error "You need to specify a :file parameter"))))
       (file-ext (file-name-extension out-file))
       (darkmode (if (assq :darkmode processed-params) "--dark-mode " ""))
       (in-file (org-babel-temp-file "pikchr-" ".pic"))
       (svg-file (if (or (null file-ext) (string-equal file-ext "svg"))
                     out-file
                   (org-babel-temp-file "pikchr-" ".svg")))
       (cmd (concat "pikchr --svg-only " darkmode in-file)))

    ;; actually execute the source-code block either in a session or
    ;; possibly by dropping it to a temporary file and evaluating the
    ;; file.
    (with-temp-file in-file
      (insert body))
    (with-temp-file svg-file
      (insert (org-babel-eval cmd "")))
    (unless (string-equal svg-file out-file)
      (with-temp-buffer
        (let ((exit-code (call-process "convert" nil t nil svg-file out-file)))
          (when (/= exit-code 0)
            (org-babel-eval-error-notify exit-code (buffer-string))))))))


(defun org-babel-prep-session:pikchr (_session _params)
  "Return an error because pikchr does not support sessions."
  (user-error "pikchr does not support sessions"))

(provide 'ob-pikchr)


;;; example:
;;;
;;; #+begin_src pikchr :darkmode :file picout.svg
;;; circle "words"
;;; arrow
;;; box "images" rad 0.2
;;; #+end_src
