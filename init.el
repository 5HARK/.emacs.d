
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.


;;; Code:
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl
    (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  ;; (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/"))
  ;; (add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
  (add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t))
(package-initialize)
(when (not package-archive-contents)
    (package-refresh-contents))

;; Set custom settings to load in own file
(setq custom-file (make-temp-file "emacs-custom"))

;; Store all backup and autosave files in the tmp dir
;; Save all tempfiles in $TMPDIR/emacs$UID/
    (defconst emacs-tmp-dir (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory))
    (setq backup-directory-alist
        `((".*" . ,emacs-tmp-dir)))
    (setq auto-save-file-name-transforms
        `((".*" ,emacs-tmp-dir t)))
    (setq auto-save-list-file-prefix
        emacs-tmp-dir)

;; Bootstrap use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Emacs GUI
;; 메뉴바 설정
(menu-bar-mode -99) ;; -99 는 popup mode

;; 툴바 설정
(tool-bar-mode -1) ;; -1 은 disable mode

;; Enable desktop saving
(desktop-save-mode 1)

;; Theme
(use-package github-modern-theme
	     :ensure t
	     :config
	     (load-theme 'github-modern t))
;; (use-package borland-blue-theme
;;   :ensure t
;;   :config
;;   (load-theme 'borland-blue t))

;; Org-Mode
(require 'org)
;; org-mode global settings
(setq org-log-done t)
;; org-mode global key settings
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cc" 'org-capture)
(global-set-key "\C-cb" 'org-iswitchb)


;; org latex margin adjust Settings
(setq org-latex-packages-alist '(("margin=2cm" "geometry" nil)))

;; add agenda files
(setq org-agenda-files
      (list "~/.GTD/gtd.org"))
;; default note files settings
(setq org-default-notes-file (concat " ~/.GTD/notes.org"))

;; refile targets
(setq org-refile-targets (quote (("~/.GTD/gtd.org" :maxlevel . 1)
				 ("~/.GTD/(setq )omeday.org" :level . 2))))
;; custom agenda views
(setq org-agenda-custom-commands
      '(
	("D" "오늘의 할일"
	 (
	  (agenda "" ((org-agenda-ndays 1)
		      (org-agenda-sorting-strategy
		       (quote ((agenda time-up priority-down tag-up) )))
		      (org-deadline-warning-days 0)))))
	("w" todo "WAITING" nil)
	("1" "미리미리 합시다"
	 (
	  (agenda "" ((org-agenda-span 'month)
		      (org-agenda-time-grid nil)
		      (org-agenda-show-all-dates nil)
		      (org-agenda-entry-types '(:deadline)) ;; this entry exclues :scheduled
		      (org-deadline-warning-days 0)))))
	)
      )

;; custom capture templates
(setq org-capture-templates
      '(("i" "add to Inbox" entry (file+headline "~/.GTD/inbox.org" "INBOX")
	 "* TODO %? \n %i\n")
	("n" "Note" entry (file+datetree "~/.GTD/notes.org")
	 "* %?\nEntered on %U \n %i\n %a")))

(define-key org-mode-map "\M-q" 'toggle-truncate-lines)

;; pop up capture screen hacks ;;
(defadvice org-capture-finalize
    (after delete-capture-frame activate)
  "Advise capture-finalize to close the frame"
  (if (equal "capture" (frame-parameter nil 'name))
      (delete-frame)))

(defadvice org-capture-destroy
    (after delete-capture-frame activate)
  "Advise capture-destroy to close the frame"
  (if (equal "capture" (frame-parameter nil 'name))
      (delete-frame)))

;; make the frame contain a single window. by default org-capture
;; splits the window.
(add-hook 'org-capture-mode-hook
	  'delete-other-windows)

(defadvice org-switch-to-buffer-other-window
    (after supress-window-splitting activate)
  "Delete the extra window if we're in a capture frame"
  (if (equal "capture" (frame-parameter nil 'name))
      (delete-other-windows)))

(defun make-capture-frame ()
  "Create a new frame and run org-capture."
  (interactive)
  (make-frame '((name . "capture")
		(width . 120)
		(height . 15)))
  (select-frame-by-name "capture")
  (setq word-wrap 1)
  (setq truncate-lines nil)
  (org-capture))

;; org mode realign indentation custom fuction
;; https://emacs.stackexchange.com/questions/19252/how-can-i-paste-paragraph-not-to-interrupt-numbers-in-list-org-mode/19278#19278
(defun org-adjust-region (b e)
  "Readjust stuff in region according to the preceeding stuff."
  (interactive "r") ;; current region
  (save-excursion
    (let ((e (set-marker (make-marker) e))
	  (_indent (lambda ()
		     (insert ?\n)
		     (backward-char)
		     (org-indent-line)
		     (delete-char 1)))
	  last-item-pos)
      (goto-char b)
      (beginning-of-line)
      (while (< (point) e)
	(indent-line-to 0)
	(cond
	 ((looking-at "[[:space:]]*$")) ;; ignore empty lines
	 ((org-at-heading-p)
	  (error "Headings cannot be balanced (yet)."))
	 ((org-at-item-p)
	  (funcall _indent)
	  (let ((struct (org-list-struct))
		(mark-active nil))
	    (ignore-errors (org-list-indent-item-generic -1 t struct)))
	  (setq last-item-pos (point)))
	 ((org-at-block-p)
	  (funcall _indent)
	  (goto-char (plist-get (cadr (org-element-special-block-parser e nil)) :contents-end))
	  (org-indent-line))
	 (t (funcall _indent)))
	(forward-line))
      (when last-item-pos
	(goto-char last-item-pos)
	(org-list-repair)
	))))

(define-key org-mode-map (kbd "C-+") 'org-adjust-region)

;; Org-Pomodoro
(use-package org-pomodoro
	     :ensure t)

;; Key-Chord, Jump-char
(use-package key-chord
	     :ensure t
	     :config
	     (key-chord-mode 1)
	     (key-chord-define-global "fg" 'jump-char-forward)
	     (key-chord-define-global "df" 'jump-char-backward))
(use-package jump-char
	     :ensure t)

;; Multiple-Cursors
(use-package multiple-cursors
	     :ensure t
	     :config
	     (global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
	     (global-set-key (kbd "C->") 'mc/mark-next-like-this)
	     (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
	     (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
	     )

;; TRAMP settings
(setq tramp-default-method "ssh")

;; Windmove 
(when (fboundp 'windmove-default-keybindings)
  (windmove-default-keybindings))
;; Make windmove work in org-mode:
(add-hook 'org-shiftup-final-hook 'windmove-up)
(add-hook 'org-shiftleft-final-hook 'windmove-left)
(add-hook 'org-shiftdown-final-hook 'windmove-down)
(add-hook 'org-shiftright-final-hook 'windmove-right)

;; right justify rectangle

(require 'rect)
(defun right-justify-rectangle (start end)
  (interactive "r")
  (let ((indent-tabs-mode nil))
    (apply-on-rectangle (lambda (c0 c1)
                          (move-to-column c1 t)
                          (let ((start (- (point) (- c1 c0)))
                                (end (point)))
                            (when (re-search-backward "\\S-" start t)
                              (transpose-regions start (match-end 0)
                                                 (match-end 0) end))))
                        start end))
  (when indent-tabs-mode (tabify start end)))
(global-set-key (kbd "C-x r a") 'right-justify-rectangle)

;; Company
(use-package company
	     :ensure t
	     :init
	     (setq company-tooltip-align-annotations t)
	     )

;; auto-complete
(use-package auto-complete
	     :ensure t)

;; flycheck
(use-package flycheck
	     :ensure t
	     :hook (after-init-hook . global-flycheck-mode)
	     :config
	     (with-eval-after-load 'flycheck
	       (flycheck-add-mode 'html-tidy 'web-mode)
	       (flycheck-add-mode 'css-csslint 'web-mode)))

;; yasnippet
(use-package yasnippet
	     :ensure t
	     :init
	     (setq yas-snippet-dirs
		   '("~/.emacs.d/snippets"
		     "~/.emacs.d/elpa/yasnippet-20181015.1212/snippets"))
	     :config
	     (yas-global-mode 1))

;; php-mode
(use-package php-mode
	     :ensure t)

;; emmet-mode
(use-package emmet-mode
	     :ensure t)

;; Slime
(use-package slime
	     :ensure t
	     :init
	     (setq inferior-lisp-program "/usr/bin/clisp")
	     (setq slime-contribs '(slime-repl)); repl only
	     )

;; Web-Mode
(use-package web-mode
	     :ensure t
	     :mode (("\\.html?\\'" . web-mode))
	     :bind ("C-'" . company-web-html)
	     :init
	     (add-hook 'web-mode-hook (lambda ()
			   (set (make-local-variable 'company-backend) '(company-web-html))
			   (company-mode t)))
	     (add-hook 'web-mode-hook 'emmet-mode)
	     (setq web-mode-css-indent-offset 2)
	     (setq web-mode-enable-auto-expanding t)
	     (setq web-mode-markup-indent-offset 2)
	     )


;; Tide(TypeScript Interactive Development Environment for Emacs)
(use-package tide
  :ensure t
  :after (typescript-mode company flycheck)
  :config
  ;; aligns annotation to the right hand side
  (setq company-tooltip-align-annotations t)
  ;; formats the buffer before saving
  (add-hook 'before-save-hook 'tide-format-before-save)
  (add-hook 'typescript-mode-hook #'setup-tide-mode))

(defun setup-tide-mode ()
  (interactive)
  (tide-setup)
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  ;; company is an optional dependency. You have to
  ;; install it separately via package-install
  ;; `M-x package-install [ret] company`
  (company-mode +1))

;; Elpy(Emacs Lisp Python Environment)
;; 나중에 설치 고려


;; js2-mode, ac-Js2
(use-package js2-mode
	     :ensure t
	     :mode (("\\.js\\'" . js2-mode))
	     :hook (js2-mode-hook . ac-js2-mode) )

(use-package ac-js2
	     :ensure t)

;; ac-html, ac-html-csswatcher
(use-package ac-html
	     :ensure t)
(use-package ac-html-csswatcher
	     :ensure t)

;; emacsclient cursor color settings
(require 'frame)
(defun set-cursor-hook (frame)
  (modify-frame-parameters
   frame (list (cons 'cursor-color "DeepSkyBlue"))))
(add-hook 'after-make-frame-functions 'set-cursor-hook)

;; 이맥스 서버화
(server-start)

;; 커스텀 함수
"Edit config.org"
(defun init()
  (interactive)
  (find-file "~/.emacs.d/init.el"))

(defun reload-init()
  (interactive)
  (load-file "~/.emacs.d/init.el"))

;; custom functions
(defun gtd()
  (interactive)
  (find-file "~/.GTD/gtd.org"))

(defun inbox()
  (interactive)
  (find-file "~/.GTD/inbox.org"))

(defun note()
  (interactive)
  (find-file "~/.GTD/notes.org"))

(defun op()
  (interactive)
  (org-pomodoro))

;; 폰트 설정
;; default Latin font (e.g. Consolas)
;; But I use Monaco
(set-face-attribute 'default nil :family "Ubuntu Mono")
;;(set-face-attribute 'default nil :family "NanumGothicCoding")


;; default font size (point * 10)
;;
;; WARNING!  Depending on the default font,
;; if the size is not supported very well, the frame will be clipped
;; so that the beginning of the buffer may not be visible correctly
;;(set-face-attribute 'default nil :height 132)
(set-face-attribute 'default nil :height 132)



;; use specific font for Korean charset.
;; if you want to use different font size for specific charset,
;; add :size POINT-SIZE in the font-spec.
(set-fontset-font t 'hangul (font-spec :name "D2Coding"))
;;(set-fontset-font t 'hangul (font-spec :name "NanumGothicCoding"))

;; You may want to add different for other charset in this way.
					;(dolist (elt '(
					;	       ("NanumGothicCoding" . 2.3846153846153846)
					;	       ))
					;  (add-to-list 'face-font-rescale-alist elt))

;;(setq face-font-rescale-alist
;;      '(("Ubuntu Mono" . 1.2)
;;        ("NanumGothicCoding" . 1.2307692307692308)))






	     
;; (custom-set-variables
;;  ;; custom-set-variables was added by Custom.
;;  ;; If you edit it by hand, you could mess it up, so be careful.
;;  ;; Your init file should contain only one such instance.
;;  ;; If there is more than one, they won't work right.
;;  '(custom-enabled-themes (quote (github)))
;;  '(custom-safe-themes
;;    (quote
;;     ("ec13410d459f1b67158c500d13d290560fc4dad2edaaa22e33a4d1df08e8f887" "3d5307e5d6eb221ce17b0c952aa4cf65dbb3fa4a360e12a71e03aab78e0176c5" "5dd70fe6b64f3278d5b9ad3ff8f709b5e15cd153b0377d840c5281c352e8ccce" default)))
;;  '(package-selected-packages
;;    (quote
;;     (org-pomodoro key-chord jump-char tide multiple-cursors elpy slime skewer-mode ac-js2 js2-mode impatient-mode simple-httpd company ac-html ac-html-csswatcher auto-complete yasnippet flycheck emmet-mode web-mode ubuntu-theme php-mode github-theme borland-blue-theme)))
;;  '(web-mode-css-indent-offset 2)
;;  '(web-mode-enable-auto-expanding t)
;;  '(web-mode-markup-indent-offset 2))
;; (custom-set-faces
;;  ;; custom-set-faces was added by Custom.
;;  ;; If you edit it by hand, you could mess it up, so be careful.
;;  ;; Your init file should contain only one such instance.
;;  ;; If there is more than one, they won't work right.
;;  )





;; ;; 테마 로드
;; (push (substitute-in-file-name "~/.emacs.d/elpa/borland-blue-theme-20160117.521/") custom-theme-load-path)
;; ;;(load-theme 'borland-blue t)

;; (push (substitute-in-file-name "~/.emacs.d/elpa/github-theme-20170221.804/") custom-theme-load-path)
;; (load-theme 'github t)

;; ;; 창 투명도 설정 함수
;; (defun transparent (alpha-level no-focus-alpha-level)
;;   "Let's you make the window transparent"
;;   (interactive "nAlpha level (0-100): \nnNo focus alpha level (0-100): ")
;;   (set-frame-parameter (selected-frame) 'alpha (list alpha-level no-focus-alpha-level))
;;   (add-to-list 'default-frame-alist `(alpha, alpha-level)))

;; ;; 창 투명도 설정
;; (when window-system
;;   (set-frame-parameter (selected-frame) 'alpha (list 100))
;;   (add-to-list 'default-frame-alist `(alpha, 100)))

;; ;; 한/영 키로 입력기 전환
;; (global-set-key (kbd "<multi_key>") 'toggle-input-method)









;; ;; zoom-frm 관련 설정
;; (add-to-list 'load-path "~/.emacs.d/elisp")
;; (require 'zoom-frm)
;; (define-key ctl-x-map [(control ?+)] 'zoom-in/out)
;; (define-key ctl-x-map [(control ?-)] 'zoom-in/out)
;; (define-key ctl-x-map [(control ?=)] 'zoom-in/out)
;; (define-key ctl-x-map [(control ?0)] 'zoom-in/out)




;; ;; Enable auto-complete

;; (require 'auto-complete-config)
;; (ac-config-default)
;; (setq ac-modes (delq 'python-mode ac-modes)) ; disable ac-python when it in elpy ide modes

;; skewer (html+css+javascript 동적 개발 용 패키지) 설정
;; (add-hook 'html-mode-hook 'skewer-html-mode)

;; Enable elpy

;; (elpy-enable)

;; latex path
					;(defun set-exec-path-from-shell-PATH ()
					;  "Sets the exec-path to the same value used by the user shell"
					;  (let ((path-from-shell
					;         (replace-regexp-in-string
					;          "[[:space:]\n]*$" ""
					;          (shell-command-to-string "$SHELL -l -c 'echo $PATH'"))))
					;    (setenv "PATH" path-from-shell)
					;    (setq exec-path (split-string path-from-shell path-separator))))

					;(set-exec-path-from-shell-PATH)


;; annotation to the right hand side

;; (add-hook 'before-save-hook 'tide-format-before-save)

;; (add-hook 'typescript-mode-hook #'setup-tide-mode)



;;; org-mode configuations ;;;









;; 					; directory local variables reload functions
;; (defun my-reload-dir-locals-for-current-buffer ()
;;   "reload dir locals for the current buffer"
;;   (interactive)
;;   (let ((enable-local-variables :all))
;;     (hack-dir-local-variables-non-file-buffer)))

;; (defun my-reload-dir-locals-for-all-buffer-in-this-directory ()
;;   "For every buffer with the same `default-directory` as the 
;; current buffer's, reload dir-locals."
;;   (interactive)
;;   (let ((dir default-directory))
;;     (dolist (buffer (buffer-list))
;;       (with-current-buffer buffer
;;         (when (equal default-directory dir))
;;         (my-reload-dir-locals-for-current-buffer)))))



					; inline image settings
					;(setq org-startup-with-inline-images t)



;; org latex inputenc Unicode Settings
					;(require 'ox-latex)
					;(setq org-latex-inputenc-alist '(("")))

;; emacs rocks !
;; iy-go-to-char - like f in Vim
;; (global-set-key (kbd "M-m") 'jump-char-forward)
;; (global-set-key (kbd "M-M") 'jump-char-backward)
;; (global-set-key (kbd "s-m") 'jump-char-backward)

(provide 'init)
;;; init.el ends here
