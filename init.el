;;; init.el --- Spacemacs Initialization File -*- no-byte-compile: t; lexical-binding: nil; -*-
;;
;; Copyright (c) 2012-2025 Sylvain Benner & Contributors
;;
;; Author: Sylvain Benner <sylvain.benner@gmail.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;; ---------------------------------------------------------------------------
;; * Startup Optimization
;; ---------------------------------------------------------------------------
;; Increase garbage collection threshold to speed up startup.
(defconst emacs-start-time (current-time))
(setq gc-cons-threshold 402653184 gc-cons-percentage 0.6)
(setq byte-compile-warnings nil)
;; ---------------------------------------------------------------------------
;; * Load Core Paths
;; ---------------------------------------------------------------------------
;; Load the paths to Spacemacs core files.
(load (concat (file-name-directory load-file-name) "core/core-load-paths")
      nil (not init-file-debug))

;; ---------------------------------------------------------------------------
;; * Load Version Info
;; ---------------------------------------------------------------------------
;; Load Spacemacs and Emacs version information.
(load (concat spacemacs-core-directory "core-versions")
      nil (not init-file-debug))

;; ---------------------------------------------------------------------------
;; * Remove Stale Compiled Files
;; ---------------------------------------------------------------------------
;; Remove old compiled files if Emacs version has changed.
(load (concat spacemacs-core-directory "core-compilation")
      nil (not init-file-debug))
(load spacemacs--last-emacs-version-file t (not init-file-debug))

;; Update saved Emacs version if necessary.
(unless (string= spacemacs--last-emacs-version emacs-version)
  (spacemacs//update-last-emacs-version))

;; ---------------------------------------------------------------------------
;; * Emacs Version Check
;; ---------------------------------------------------------------------------
;; Stop initialization if Emacs is too old.
(when (not (version<= spacemacs-emacs-min-version emacs-version))
  (error (concat "Your version of Emacs (%s) is too old. "
                 "Spacemacs requires Emacs version %s or above.")
         emacs-version spacemacs-emacs-min-version))

;; -------------------------------------------------------------------------
;; * Startup Speed Tweaks
;; -------------------------------------------------------------------------
;; Simplify file-name-handler-alist for faster startup.
;; Prefer newer files over older compiled ones.
(let ((load-prefer-newer t)
      (file-name-handler-alist '(("\\.gz\\'" . jka-compr-handler))))

  ;; -----------------------------------------------------------------------
  ;; * Load Spacemacs Core
  ;; -----------------------------------------------------------------------
  ;; Load main Spacemacs core and configuration layers.
  (require 'core-spacemacs)
  (configuration-layer/load-lock-file)
  (spacemacs/init)
  (configuration-layer/stable-elpa-init)
  (configuration-layer/load)
  (spacemacs-buffer/display-startup-note)
  (spacemacs/setup-startup-hook)

  ;; -----------------------------------------------------------------------
  ;; * Start Emacs Server (Optional)
  ;; -----------------------------------------------------------------------
  ;; Start Emacs server if enabled in user config.
  (when (and dotspacemacs-enable-server (not noninteractive))
    (require 'server)
    (when dotspacemacs-server-socket-dir
      (setq server-socket-dir dotspacemacs-server-socket-dir))
    (unless (or (daemonp) (server-running-p))
      (message "Starting a server...")
      (server-start))))

(setq evil-want-keybinding nil)

(use-package exec-path-from-shell
  :ensure t
  :config (exec-path-from-shell-initialize))

(use-package evil
  :ensure t
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init)
  (evil-collection-init 'evil-magit))

(use-package nov
  :after evil-collection
  :ensure t
  :config
  (evil-collection-init 'evil-nov)
  (evil-collection-nov-setup)
  (evil-normal-state)
  (evil-set-initial-state 'nov-mode 'normal))

(use-package vterm
  :ensure t
  :after evil-collection
  :init (evil-collection-vterm-setup)
  :custom (vterm-always-compile-module t))

(use-package flycheck
  :ensure t)

(use-package flycheck-clojure
  :ensure t
  :init (flycheck-clojure-setup))

(use-package flycheck-clj-kondo
  :ensure t)

(use-package sly
  :ensure t)

(use-package slime
  :ensure t)

(use-package pdf-tools
  :ensure t
  :after evil-collection
  :init
  (pdf-tools-install)
  (evil-collection-init 'evil-pdf)
  (evil-collection-pdf-setup)
  (evil-normal-state)
  (evil-set-initial-state 'pdf-view-mode 'normal))

(use-package org-zettelkasten
  :ensure t
  :config
  (add-hook 'org-mode-hook #'org-zettelkasten-mode)
  (setq org-zettelkasten-directory (expand-file-name "~/org/org-zettelkasten"))
  (setq org-zettelkasten-mapping-file (expand-file-name "~/org/org-zettelkasten/org-zettelkasten-index")))

(use-package alchemist
  :after evil-collection
  :ensure t
  :config
  (evil-collection-alchemist-setup)
  (evil-collection-init 'evil-alchemist)
  (evil-normal-state)
  (evil-set-initial-state 'alchemist-mode 'normal))

(defun set-org-agenda-files ()
  (setq org-agenda-files
        (cl-remove-if
         (lambda (s) (cl-search "sync-conflict" s))
         (append (directory-files "~/org/" 1 ".org$")
                 (directory-files-recursively "~/org/work" ".org$")
                 (directory-files-recursively "~/org/tdls" ".org$")))))

(defun get-target-path (buffer-path)
  (replace-regexp-in-string "/org/" "/Google Drive/My Drive/org/" buffer-path nil 'literal))

(defun sync-org-file-to-gdrive (org-file-path)
  (copy-file org-file-path (get-target-path org-file-path) ""))

(defun internet-up-p (&optional host)
  (= 0 (call-process "ping" nil nil nil "-c" "1" "-W" "1"
                     (if host host "www.google.com"))))

(defun get-plain-text-file-path-for-org (org-file-path)
  (replace-regexp-in-string "\\.org" ".txt" (buffer-file-name) nil 'literal))


(defun org-sync-hook ()
  (when (and (buffer-file-name) (string-match-p "/org/" (buffer-file-name)))
    (progn
      (set-org-agenda-files)
      ;; (sync-org-file-to-gdrive (buffer-file-name))
      (when (eq major-mode 'org-mode)
        (org-ascii-export-to-ascii)
        ;; (sync-org-file-to-gdrive (get-plain-text-file-path-for-org (buffer-file-name)))
        )
      )))

(add-hook 'after-save-hook 'org-sync-hook)
(setq create-lockfiles nil)

(setq initial-scratch-message
      ";; There is no final victory,\n;; as there is no final defeat.\n;; There is just the same battle.\n;; To be fought, over and over again.\n;; So toughen up, bloody toughen up.\n")

(setq initial-major-mode 'org-mode)
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))


(evil-collection-init 'evil-nov)
(evil-collection-nov-setup)
(evil-collection-alchemist-setup)
(add-hook 'nov-mode-hook 'evil-collection-init 100)
(add-hook 'nov-mode-hook (lambda () (evil-collection-init 'evil-nov)) 100)
(add-hook 'nov-mode-hook 'evil-collection-nov-setup 100)
(add-hook 'nov-mode-hook (lambda () (evil-mode t)) 100)
(add-hook 'nov-mode-hook 'evil-normal-state 100)

(evil-normal-state)
(add-hook 'pdf-view-mode-hook 'evil-collection-init 100)
(add-hook 'pdf-view-mode-hook (lambda () (evil-collection-init 'evil-pdf)) 100)
(add-hook 'pdf-view-mode-hook 'evil-collection-nov-setup 100)
(add-hook 'pdf-view-mode-hook (lambda () (evil-mode t)) 100)
(add-hook 'pdf-view-mode-hook 'evil-normal-state 100)

(add-hook 'alchemist-mode-hook 'evil-collection-init 100)
(add-hook 'alchemist-mode-hook (lambda () (evil-collection-init 'evil-alchemist)) 100)
(add-hook 'alchemist-mode-hook 'evil-collection-alchemist-setup 100)
(add-hook 'alchemist-mode-hook (lambda () (evil-mode t)) 100)
(add-hook 'alchemist-mode-hook 'evil-normal-state 100)

(setq auth-sources '("~/.authinfo"))
