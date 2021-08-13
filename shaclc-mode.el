;;; shaclc-mode.el --- mode for SHACL Compact Syntax (SHACLC)
;; Copyright (c) 2020 <vladimir.alexiev@ontotext.com>
;; https://github.com/VladimirAlexiev/shaclc-mode

;; For documentation on SHACLC, see:
;; https://w3c.github.io/shacl/shacl-compact-syntax/

;;; Comentary:
;; - Mostly stolen from from the great shex-mode of EricP

;; How to install:
;; - optionally byte compile
;; - add this to .emacs
;; (add-to-list 'load-path "{path-to-shaclc}")
;; (autoload 'shaclc-mode "shaclc-mode" "Major mode for SHACLC (SCHACL Compact Syntax)" t)
;; (add-to-list 'auto-mode-alist '("\\.\\(shaclc\\|shc\\)$" . shaclc-mode))

;; What it does now:
;; - Syntax highlighting
;; - Syntax checking using shaclconvert and flycheck
;; - Comment/uncomment block with M-;
;; - Index of shape definitions (imenu) and panel on the right (imenu-list)

;; Todo:
;; - Use SHACLC.g4 grammar to make highlighting better
;; - Merge shaclconvert to TopQuadrant SHACL
;; - Make an ELPA package

;;; Code:

(define-derived-mode shaclc-mode shexc-mode "shaclc"
  ;; index of shape definitions (imenu) and panel on the right (imenu-list)
  (let*
      ((HEX             "[0-9A-Fa-f]")
       (UCHAR           (format "\\(?:\\\\u%s%s%s%s\\|\\\\U%s%s%s%s%s%s%s%s\\)" HEX HEX HEX HEX HEX HEX HEX HEX HEX HEX HEX HEX))
       (IRIREF          (format "<\\(?:[^\x0\ -\x20\ <>\"{}|^`\\\\]\\|%s\\)*>" UCHAR)) ; #x00=NULL #01-#x1F=control codes #x20=space
       (PN_CHARS_BASE	"\\(?:[A-Za-z\x00C0\ -\x00D6\ \x00D8\ -\x00F6\ \x00F8\ -\x02FF\ \x0370\ -\x037D\ \x037F\ -\x1FFF\ \x200C\ -\x200D\ \x2070\ -\x218F\ \x2C00\ -\x2FEF\ \x3001\ -\xD7FF\ \xF900\ -\xFDCF\ \xFDF0\ -\xFFFD\ ]\\)")
       (PN_CHARS_U	(format "\\(?:%s\\|_\\)" PN_CHARS_BASE))
       (PN_CHARS	(format "\\(?:%s\\|-\\|[0-9]\\|\x00B7\ \\|[\x0300\ -\x036F\ ]\\|[\x203F\ -\x2040\ ]\\)" PN_CHARS_U))
       (PN_PREFIX	(format "\\(?:%s\\(?:\\(?:%s\\|\\.\\)*%s\\)?\\)" PN_CHARS_BASE PN_CHARS PN_CHARS))
       (PNAME_NS	(format "\\(?:%s?:\\)" PN_PREFIX))
       (PN_LOCAL_ESC	"\\(?:\\\\[_~.-!$&'()*+,;=/?#@%]\\)")
       (PERCENT         (format "\\(?:%%%s%s\\)" HEX HEX))
       (PLX		(format "\\(?:%s\\|%s\\)" PERCENT PN_LOCAL_ESC))
       (PN_LOCAL	(format "\\(?:\\(?:%s\\|:\\|[0-9]\\|%s\\)\\(?:\\(?:%s\\|\\.\\|:\\|%s\\)*\\(?:%s\\|:\\|%s\\)\\)?\\)" PN_CHARS_U PLX PN_CHARS PLX PN_CHARS PLX))
       (PNAME_LN	(format "%s%s" PNAME_NS PN_LOCAL))
       (PrefixedName	(format "\\(?:%s\\|%s\\)" PNAME_LN PNAME_NS))
       (shaclc-imenu-generic-expression
        (list (list nil (format "^\\s-*shape\\(?:Class\\)?\\s-+\\(%s\\|%s\\)" IRIREF PrefixedName) 1))))
    (setq-local imenu-generic-expression shaclc-imenu-generic-expression)))

;; Use one of two shaclc parsers/convertor to check shaclc syntax.

;; 1. https://gitlab.ontotext.com/yasen.marinov/shaclconvert: not open sourced yet but we hope to merge it to TopQuadrant SHACL soon.
;; https://github.com/TopQuadrant/shacl/issues/98
;; This convertor is not part of TQ SHACL but I've put it in the same folder.
(flycheck-define-checker shaclc-shaclconvert
  "shaclc syntax checker using shaclconvert"
  :command ("java" "-jar" "c:\\prog\\shacl-1.3.2\\bin\\shaclconvert.jar" source temporary-file-name)
  :error-patterns
  ((error "line " line ":" column " " (message))
   (error "Exception in thread \"main\" java.lang.RuntimeException: " (message)))
  :modes (shaclc-mode))

;; 2. https://jena.apache.org/documentation/shacl/#command-line
(flycheck-define-checker shaclc-jena
  "shaclc syntax checker using jena shacl"
  :command ("sh" "shacl" "parse" source)
  :error-patterns
  ((error "Lexical error at line " line ", column " column ".  " (message))
   (error "Encountered " (message (minimal-match (one-or-more not-newline))) " at line " line ", column " column "."
          ;; "\nWas expecting one of: " (message (one-or-more anything)) ; allow newline; but can't concat two (message)'s
          ))
  :modes (shaclc-mode))

;; Use one or the other:
(add-to-list 'flycheck-checkers 'shaclc-shaclconvert)
;; (add-to-list 'flycheck-checkers 'shaclc-jena)

(provide 'shaclc-mode)
