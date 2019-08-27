;;; lang/sh/config.el -*- lexical-binding: t; -*-

(defvar +sh-builtin-keywords
  '("cat" "cd" "chmod" "chown" "cp" "curl" "date" "echo" "find" "git" "grep"
    "kill" "less" "ln" "ls" "make" "mkdir" "mv" "pgrep" "pkill" "pwd" "rm"
    "sleep" "sudo" "touch")
  "A list of common shell commands to be fontified especially in `sh-mode'.")


;;
;; Packages

(use-package! sh-script ; built-in
  :mode ("\\.zunit\\'" . sh-mode)
  :mode ("/bspwmrc\\'" . sh-mode)
  :init
  (add-to-list 'auto-mode-alist '("/bin/[^/]+\\'" . sh-mode) 'append)
  :config
  (set-electric! 'sh-mode :words '("else" "elif" "fi" "done" "then" "do" "esac" ";;"))
  (set-repl-handler! 'sh-mode #'+sh/open-repl)

  (setq sh-indent-after-continuation 'always)

  ;; [pedantry intensifies]
  (setq-hook! 'sh-mode-hook mode-name "sh")

  ;; recognize function names with dashes in them
  (add-to-list 'sh-imenu-generic-expression
               '(sh (nil "^\\s-*function\\s-+\\([[:alpha:]_-][[:alnum:]_-]*\\)\\s-*\\(?:()\\)?" 1)
                    (nil "^\\s-*\\([[:alpha:]_-][[:alnum:]_-]*\\)\\s-*()" 1)))

  ;; `sh-set-shell' is chatty about setting up indentation rules
  (advice-add #'sh-set-shell :around #'doom-shut-up-a)

  ;; 1. Fontifies variables in double quotes
  ;; 2. Fontify command substitution in double quotes
  ;; 3. Fontify built-in/common commands (see `+sh-builtin-keywords')
  (add-hook! 'sh-mode-hook
    (defun +sh-init-extra-fontification-h ()
      (font-lock-add-keywords
       nil `((+sh--match-variables-in-quotes
              (1 'font-lock-constant-face prepend)
              (2 'font-lock-variable-name-face prepend))
             (+sh--match-command-subst-in-quotes
              (1 'sh-quoted-exec prepend))
             (,(regexp-opt +sh-builtin-keywords 'words)
              (0 'font-lock-type-face append))))))
  ;; 4. Fontify delimiters by depth
  (add-hook 'sh-mode-hook #'rainbow-delimiters-mode)

  ;; autoclose backticks
  (sp-local-pair 'sh-mode "`" "`" :unless '(sp-point-before-word-p sp-point-before-same-p))

  ;; sh-mode has file extensions checks for other shells, but not zsh, so...
  (add-hook! 'sh-mode-hook
    (defun +sh-detect-zsh-h ()
      (when (or (and buffer-file-name
                     (string-match-p "\\.zsh\\'" buffer-file-name))
                (save-excursion
                  (goto-char (point-min))
                  (looking-at-p "^#!.+/zsh[$ ]")))
        (sh-set-shell "zsh")))))


(use-package! company-shell
  :when (featurep! :completion company)
  :after sh-script
  :config
  (set-company-backend! 'sh-mode '(company-shell company-files))
  (setq company-shell-delete-duplicates t))


(use-package! fish-mode
  :when (featurep! +fish)
  :defer t
  :config (set-formatter! 'fish-mode #'fish_indent))
