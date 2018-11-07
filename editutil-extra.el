
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (バッファ関係)

;; C-, C-. でバッファを次々に表示
;; -> http://www-tsujii.is.s.u-tokyo.ac.jp/~yoshinag/tips/elisp_tips.html

;; 表示させないバッファのリスト
(defvar my-ignore-buffer-list
  '("TAGS" "*Help*" "*Compile-Log*" "*compilation*" "*Completions*" "*Bookmark List*"
    "*Shell Command Output*" "*Apropos*" "*Buffer List*" "*WoMan-Log*"
    "*helm-mode-execute-extended-command*" "*helm-mode-iswitchb-buffer*"
    "*helm-mode-describe-variable*" "*helm-mode-describe-function*"
    ))

(defun my-visible-buffer (blst)
  (let ((bufn (buffer-name (car blst))))
    (if (or (= (aref bufn 0) ? ) (member bufn my-ignore-buffer-list))
        (my-visible-buffer (cdr blst)) (car blst))))
(defun my-grub-buffer ()
  (interactive)
  (switch-to-buffer (my-visible-buffer (reverse (buffer-list)))))
(defun my-bury-buffer ()
  (interactive)
  (let ((nbuf (my-visible-buffer (cdr (buffer-list)))))
    (bury-buffer)
    (switch-to-buffer nbuf)))

;; C-, / C-. にバインド (ターミナル環境下ではPageUp / PageDown にバインド)
(if window-system
    (progn
      (defvar my-grub-buffer-key "C-.")
      (defvar my-bury-buffer-key "C-,"))
  (defvar my-grub-buffer-key "<next>")
  (defvar my-bury-buffer-key "<prior>"))

(define-key global-map (kbd my-grub-buffer-key) 'my-grub-buffer)
(define-key global-map (kbd my-bury-buffer-key) 'my-bury-buffer)

;; 他のキーマップで上書きされないように
(with-eval-after-load 'flyspell
  (define-key flyspell-mode-map (kbd my-grub-buffer-key) 'my-grub-buffer)
  (define-key flyspell-mode-map (kbd my-bury-buffer-key) 'my-bury-buffer))
(with-eval-after-load 'org-mode
  (define-key org-mode-map (kbd my-grub-buffer-key) 'my-grub-buffer)
  (define-key org-mode-map (kbd my-bury-buffer-key) 'my-bury-buffer))

(with-eval-after-load 'tabbar
  (define-key global-map (kbd my-grub-buffer-key) 'tabbar-forward-tab)
  (define-key global-map (kbd my-bury-buffer-key) 'tabbar-backward-tab)

  (with-eval-after-load 'flyspell
    (define-key flyspell-mode-map (kbd my-grub-buffer-key) 'tabbar-forward-tab)
    (define-key flyspell-mode-map (kbd my-bury-buffer-key) 'tabbar-backward-tab))
  (with-eval-after-load 'org-mode
    (define-key org-mode-map (kbd my-grub-buffer-key) 'tabbar-forward-tab)
    (define-key org-mode-map (kbd my-bury-buffer-key) 'tabbar-backward-tab))
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;

(with-eval-after-load "editutil"
  (defadvice editutil-other-window (around my/editutil-other-window activate)
    (let ((one-window (one-window-p)))
      ad-do-it
      (if one-window
          (dired ".")))))

(defun my/editutil-quit-other-window ()
  (interactive)
  (if (or (not (eq major-mode 'dired-mode))
          (one-window-p))
      (keyboard-quit)
    (kill-this-buffer)
    (delete-window)))

(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "C-g") 'my/editutil-quit-other-window))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (repeat だけを指定回数実行させる)
;; -> http://homepage1.nifty.com/blankspace/emacs/repeat.html

;; real repeat
(defun my-repeat (arg)
  (interactive "p")
  (unless (eq real-last-command this-command)
    (let ((i 0))
      (while (< i arg)
        (repeat 1)
        (setq i (1+ i))))))

;; (global-set-key (kbd "C-z") 'my-repeat) ;; C-z に設定

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (kill-ring)

;; kill-ring はテキスト属性を保存しない
(defadvice kill-new (around my-kill-ring-disable-text-property activate)
  (let ((new (ad-get-arg 0)))
    (set-text-properties 0 (length new) nil new)
    ad-do-it))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (バッファリスト関係)

;; バッファリスト中 'G' や 'R' でGrep
(defun Buffer-menu-grep (str)
  (interactive "sregexp:")
  (goto-char (point-min))
  (let (lines)
    (forward-line 2)
    (setq lines (buffer-substring (point-min) (point)))
    (while (re-search-forward str nil t)
      (let ((bol (progn (beginning-of-line) (point)))
            (eol (progn (forward-line) (point))))
        (setq lines (concat lines (buffer-substring bol eol)))))
    (let ((buffer-read-only nil))
      (erase-buffer)
      (insert lines))))
(define-key Buffer-menu-mode-map "G" 'Buffer-menu-grep)

(defun Buffer-menu-grep-delete (str)
  (interactive "sregexp:")
  (save-excursion
    (goto-char (point-min))
    (forward-line 2)
    (while (re-search-forward str nil t)
      (Buffer-menu-delete))))
(define-key Buffer-menu-mode-map "R" 'Buffer-menu-grep-delete)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (history)

;; ;; 重複したのを消す
;; (require' cl)
;; (defun my-minibuffer-delete-overlap ()
;;   (let (lst)
;;     (dolist (elt (symbol-value minibuffer-history-variable))
;;       (unless (member elt lst)
;;         (push elt lst)))
;;     (set minibuffer-history-variable (nreverse lst))))
;; (add-hook 'minibuffer-setup-hook 'my-minibuffer-delete-overlap)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (自動置換関係)

;; 余分な空白を削除する (ただしカーソル前の空白は保持する）
(defun my-trim-buffer ()
  "Delete excess white space."
  (interactive)
  (let ((indent
         (if (save-excursion
               (re-search-backward "\\(^\\|[^ \t]\\)\\([ \t]*\\)$" (line-beginning-position) t))
             (buffer-substring-no-properties (match-beginning 2) (match-end 2)) "")))
    (save-excursion
      ;; 行末の空白を削除する
      (goto-char (point-min))
      (while (re-search-forward "[ \t]+$" nil t)
        (replace-match ""))
      ;; ファイルの終わりにある空白行を削除する
      (goto-char (point-max))
      (delete-blank-lines)
      ;; ;; タブに変換できる空白は変換する
      ;; (mark-whole-buffer)
      ;; (tabify (region-beginning) (region-end))
      )
    (insert indent)))

;; 保存時に実行
;;(add-hook 'write-file-hooks 'my-trim-buffer)
;; (解除)
;;(setq write-file-hooks (delq 'my-trim-buffer write-file-hooks))

;; (参考) http://www3.big.or.jp/~sian/linux/tips/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (空ファイル削除)
;; -> http://www.bookshelf.jp/cgi-bin/goto.cgi?file=meadow&node=delete%20nocontents

(defun my-delete-file-if-no-contents ()
  (when (and
         (buffer-file-name (current-buffer))
         (= (point-min) (point-max)))
    (when (y-or-n-p "Delete file and kill buffer?")
      (delete-file
       (buffer-file-name (current-buffer)))
      (kill-buffer (current-buffer)))))
(if (not (memq 'my-delete-file-if-no-contents after-save-hook))
    (setq after-save-hook
          (cons 'my-delete-file-if-no-contents after-save-hook)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (Emacs 終了時に聞かれる yes/no を y/n に)

(defadvice save-buffers-kill-emacs
  (around save-buffers-kill-emacs-yornp activate)
  (let ((default (symbol-function 'yes-or-no-p)))
    (fset 'yes-or-no-p 'y-or-n-p)
    ad-do-it
    (fset 'yes-or-no-p default)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (マーク箇所に色をつける)
;; -> http://www.emacswiki.org/cgi-bin/wiki.pl/VisibleMark
;; -> http://www.bookshelf.jp/cgi-bin/goto.cgi?file=meadow&node=region%20color

;; This was hacked together by Jorgen Schafer
;; Donated to the public domain. Use at your own risk.
(defgroup visible-mark nil
  "Show the position of your mark."
  :group 'convenience
  :prefix "visible-mark-")

(defface visible-mark-face
  `((((type tty) (class color))
     (:background "blue" :foreground "white"))
    (((type tty) (class mono))
     (:inverse-video t))
    (((class color) (background dark))
     (:background "blue"))
    (((class color) (background light))
     (:background "lightblue"))
    (t (:background "gray")))
  "Face for the mark."
  :group 'visible-mark)

(defvar visible-mark-overlay nil
  "The overlay used in this buffer.")
(make-variable-buffer-local
 'visible-mark-overlay)

(defun visible-mark-move-overlay ()
  "Move the overlay in `visible-mark-overlay'
 to a new position."
  (move-overlay visible-mark-overlay
                (mark)
                (1+ (mark))))

(define-minor-mode visible-mark-mode
  "A mode to make the mark visible."
  nil nil nil
  :group 'visible-mark
  (if visible-mark-mode
      (unless visible-mark-overlay
        (setq visible-mark-overlay
              (make-overlay (mark)
                            (1+ (mark))))
        (overlay-put visible-mark-overlay
                     'face 'visible-mark-face)
        (add-hook 'post-command-hook
                  'visible-mark-move-overlay))
    (when visible-mark-overlay
      (delete-overlay visible-mark-overlay)
      (setq visible-mark-overlay nil))))

;; ;; 各自設定
;; (setq transient-mark-mode nil)        ;; 反転表示をしない
;; (add-hook 'find-file-hook
;;           (lambda () (visible-mark-mode t)));; visible-mark-mode オン

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (quit-window)

;; quit-window ('q') でウィンドウを明示的に消してやる. ;; default: C-u q
(defadvice quit-window
  (before quit-and-delete-window (&optional kill window) activate)
  (if (and (null window)
           (not (one-window-p)))
      (setq window (selected-window))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (ウィンドウ分割の上下⇔左右を切り替え)
;; -> http://www.bookshelf.jp/soft/meadow_30.html#SEC404

(defun window-toggle-division ()
  "ウィンドウ 2 分割時に、縦分割<->横分割"
  (interactive)
  (unless (= (count-windows 1) 2)
    (error "ウィンドウが 2 分割されていません。"))
  (let (before-height (other-buf (window-buffer (next-window))))
    (setq before-height (window-height))
    (delete-other-windows)

    (if (= (window-height) before-height)
        (split-window-vertically)
      (split-window-horizontally)
      )

    (switch-to-buffer-other-window other-buf)
    (other-window -1)))

;; C-x 9 でトグル
(define-key ctl-x-map (kbd "9") 'window-toggle-division)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (ヘルプ)

;; ヘルプから関数を辿るとき移動先を read only に (書き換え防止)
(defadvice help-follow
  (after help-follow-read-only activate)
  (setq buffer-read-only t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (chmod)
;; スクリプトを保存する時，自動的に chmod +x を行なうようにする
;; -> http://namazu.org/~tsuchiya/elisp/#chmod

(defun make-file-executable ()
  "Make the file of this buffer executable, when it is a script source."
  (save-restriction
    (widen)
    (if (string= "#!" (buffer-substring-no-properties 1 (min 3 (point-max))))
        (let ((name (buffer-file-name)))
          (or (equal ?. (string-to-char (file-name-nondirectory name)))
              (let ((mode (file-modes name)))
                (set-file-modes name (logior mode (logand (/ mode 4) 73)))
                (message (concat "Wrote " name " (+x)"))))))))
(add-hook 'after-save-hook 'make-file-executable)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (sudo で再オープン)
;; -> http://qiita.com/k_ui/items/d9e03ea9523036970519

(defun reopen-with-sudo ()
  "Reopen current buffer-file with sudo using tramp."
  (interactive)
  (let ((file-name (buffer-file-name)))
    (if file-name
        (find-alternate-file (concat "/sudo::" file-name))
      (error "Cannot get a file name"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (dabbrev)

;; dabbrev日本語用修正 dabbrev-ja (土屋さん)
;; -> http://namazu.org/%7Etsuchiya/elisp/dabbrev-ja.el
(defadvice dabbrev-expand
  (around modify-regexp-for-japanese activate compile)
  "Modify `dabbrev-abbrev-char-regexp' dynamically for Japanese words."
  (if (bobp)
      ad-do-it
    (let ((dabbrev-abbrev-char-regexp
           (let ((c (char-category-set (char-before))))
             (cond
              ((aref c ?a) "[-_A-Za-z0-9]") ; ASCII
              ((aref c ?j)        ; Japanese
               (cond
                ((aref c ?K) "\\cK") ; katakana
                ((aref c ?A) "\\cA") ; 2byte alphanumeric
                ((aref c ?H) "\\cH") ; hiragana
                ((aref c ?C) "\\cC") ; kanji
                (t "\\cj")))
              ((aref c ?k) "\\ck") ; hankaku-kana
              ((aref c ?r) "\\cr") ; Japanese roman ?
              (t dabbrev-abbrev-char-regexp)))))
            ad-do-it)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (dabbrev)
;; C-i (TAB) を文脈によってインデントと dabbrev に使い分ける
;; -> http://webcvs.kde.org/cgi-bin/cvsweb.cgi/~checkout~/kdesdk/scripts/kde-emacs/kde-emacs-core.el

;; (when (not (locate-library "kde-emacs")) ;; agulbra-c++-tab がなければ

;;   (defun my-agulbra-c++-tab (arg)
;;     "Do the right thing about tabs in c++ mode.
;; Try to finish the symbol, or indent the line."
;;     (interactive "*P")
;;     (cond
;;      ((and (not (looking-at "[A-Za-z0-9]"))
;;            (save-excursion
;;              (forward-char -1)
;;              (looking-at "[A-Za-z0-9:>_\\-\\&\\.(){}\\*\\+/]")))
;;       (dabbrev-expand arg))
;;      (t
;;       (c-indent-command))))

;;   ;; c++-mode-map で使用する．
;;   (define-key c++-mode-map (kbd "C-i") 'my-agulbra-c++-tab)

;;   ) ;; my-agulbra-c++-tab

;; 参考: インテリジェント補完コマンド ac-mode
;; -> http://taiyaki.org/elisp/ac-mode/

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (upcase/downcase-region)

;; ;; upcase-region (C-x C-u) を有効にする
;; (put 'upcase-region 'disabled nil)

;; ;; downcase-region (C-x C-l) を有効にする
;; (put 'downcase-region 'disabled nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (set-goal-column)

;; set-goal-column (C-x C-n) を有効にする
(put 'set-goal-column 'disabled nil)

;; C-n や C-p において、デフォルトでは現在のカラム位置を保持するように
;; 上下移動を行なうが、set-goal-column した場合どのカラム位置からも
;; この設定した位置に添って上下するようになる
;; 解除は C-u C-x C-n.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (narrowing)

;; ;; narrowing を有効にする (わからない人は使わないこと)
;; (put 'narrow-to-page 'disabled nil)
;; (put 'narrow-to-region 'disabled nil)

;; ;; 十字キーでページ単位の移動ができるように
;; (defadvice next-line
;;   (around next-line-page activate)
;;   (if (and (not (eq major-mode 'Info-mode))
;;            (= (save-excursion (end-of-line) (point)) (point-max))
;;            (not (= (point-max)
;;                    (save-excursion (save-restriction (widen) (point-max))))))
;;       (if (eq last-command 'next-line) (narrow-to-page 0)) ad-do-it))
;; (defadvice previous-line
;;   (around previous-line-page activate)
;;   (if (and (not (eq major-mode 'Info-mode))
;;            (= (save-excursion (beginning-of-line) (point)) (point-min))
;;            (not (= (point-min)
;;                    (save-excursion (save-restriction (widen) (point-min))))))
;;       (if (eq last-command 'previous-line)
;;           (progn (narrow-to-page -1) (goto-char (- (point-max) 1)))) ad-do-it))

;; *Help*
;; C-x n n (narrow-to-region)   : リージョンを narrowing
;; C-x n p (narrow-to-page)     : page-delimiter () 単位で narrowing
;; C-x n d (narrow-to-defun)    : 関数内で narrowing
;; C-x n w (widen)              : narrowing を解除

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (現在の文字コードと異なる文字を置換)
;; -> http://www.ysnb.net/meadow/meadow-users-jp/2003/msg00113.html
;; -> http://www.bookshelf.jp/cgi-bin/goto.cgi?file=meadow&node=encode%20able

(defun my-check-encode-able (beg end)
  (interactive "r")
  (save-excursion
    (let* ((mycodingsystem buffer-file-coding-system)
           mychar
           mycharname
           (mycount 0)
          ;;;encoding に対応する charset のリストを取得する。
          ;;;Meadow2 (Emacs21) でも動くかどうか未確認
          ;;;うまくいかなければ、自分で対応を定義すれば良い
           (mycharsetlist (coding-system-get mycodingsystem 'safe-charsets))
           )
      (goto-char beg) ;;;リージョンの先頭に移動
      (while (< (point) end) ;;;リージョン内を順に調べる
        (setq mychar (following-char))
        (setq mycharsetname (char-charset mychar))
        ;;合成文字に対する処理。 Meadow2 (Emacs21) では不要かも????
        (if (equal 'composition mycharsetname)
            (setq mycharsetname
                  (char-charset (string-to-char
                                 (decompose-string (char-to-string mychar))))))
        ;;encode できない文字だったら色をつける
        (if (or (equal mycharsetlist t) (member mycharsetname mycharsetlist))
            nil ;;;encode できる時は何もしない。 encode できない時↓
          (if (y-or-n-p (format "Delete %s?" (buffer-substring-no-properties
                                              (point) (1+ (point)))))
              (delete-region (point) (1+ (point)))
            (delete-region (point) (1+ (point)))
            (insert (read-from-minibuffer "Replace String: "))
            (setq mycount (1+ mycount))))
        (forward-char) ;;;次の文字へ
        )
      ;;結果の表示
      (if (< 0 mycount)
          (message "%s で encode できない文字が%d 個ありました。"
                   mycodingsystem mycount))
      )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (日本語をエンコードする関数.  要w3)
;; -> http://www.bookshelf.jp/cgi-bin/goto.cgi?file=meadow&node=url-hexify-string

;; ;; (url-hexify-string-cs "検索") => "%8C%9F%8D%F5"
;; ;; (url-hexify-string-cs "検索" 'euc-jp) => "%B8%A1%BA%F7"

;; (require 'url)
;; (defun url-hexify-string-cs (str &optional cs)
;;   "Escape characters in a string"
;;   (mapconcat
;;    (function
;;     (lambda (char)
;;       (if (not (memq char url-unreserved-chars))
;;           (if (< char 16)
;;               (upcase (format "%%0%x" char))
;;             (upcase (format "%%%x" char)))
;;         (char-to-string char))))
;;    (encode-coding-string str (or cs 'sjis)) ""))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (行頭の空白文字をアンダースコア `_' に置換する関数)

(defun my-replace-whitespace-to-underscore (beg end)
  (interactive "r")
  (let (count max)
    (save-excursion
      (goto-char beg)
      (while (re-search-forward "^[ \t]+" end t)
        (setq count (string-width (buffer-substring (match-beginning 0) (match-end 0))))
        (replace-match "")
        (insert-char ?_  count)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (Emacs 起動後の再接続時に DNS Error を回避する)
;; -> http://ko.meadowy.net/~shirai/diary/20041016.html

;; (defun zaurus-host-to-ip (host)
;;   "Convert hostname to IP-Address for Zaurus network."
;;   (if (string-match "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$" host)
;;       host
;;     (condition-case nil
;;         (with-temp-buffer
;;           (call-process "nslookup" nil (current-buffer) nil host)
;;           (goto-char (point-min))
;;           (when (re-search-forward "^Name: +" nil t)
;;             (forward-line 1)
;;             (when (looking-at "^Address\\(es\\)?: +\\([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+\\)")
;;               (setq host (match-string 2))))
;;           host)
;;       (error host))))

;; (defadvice open-network-stream (around get-ipaddr activate)
;;   "Convert host to IP-Address."
;;   (setq host (or (zaurus-host-to-ip host) host))
;;   ad-do-it)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (ミニバッファでの削除を区切り文字単位に)
;; -> http://ko.meadowy.net/~shirai/diary/20030819.html#p01

;; 行末で C-d とすると，`/' などの区切り文字まで消去する．
;; また M-C-d すると 相対パス <=> 絶対パス の変換を行う．

(defvar minibuf-shrink-type0-chars '((w3m-input-url-history . (?/ ?+ ?:))
                                     (read-expression-history . (?\) ))
                                     (t . (?/ ?+ ?~ ?:)))
  "*minibuffer-history-variable とセパレータと見なす character の alist。
type0 はセパレータを残すもの。")

(defvar minibuf-shrink-type1-chars '((file-name-history . (?.))
                                     (w3m-input-url-history . (?# ?? ?& ?.))
                                     (t . (?- ?_ ?. ? )))
  "*minibuffer-history-variable とセパレータと見なす character の alist。
type1 はセパレータを消去するもの。")

(defun minibuf-shrink-get-chars (types)
  (or (cdr (assq minibuffer-history-variable types))
      (cdr (assq t types))))

(defun minibuf-shrink (&optional args)
  "point が buffer の最後なら 1 word 消去する。その他の場合は delete-char を起動する。
単語のセパレータは minibuf-shrink-type[01]-chars。"
  (interactive "p")
  (if (/= (if (fboundp 'field-end) (field-end) (point-max)) (point))
      (delete-char args)
    (let ((type0 (minibuf-shrink-get-chars minibuf-shrink-type0-chars))
          (type1 (minibuf-shrink-get-chars minibuf-shrink-type1-chars))
          (count (if (<= args 0) 1 args))
          char)
      (while (not (zerop count))
        (when (memq (setq char (char-before)) type0)
          (delete-char -1)
          (while (eq char (char-before))
            (delete-char -1)))
        (setq count (catch 'detect
                      (while (/= (if (fboundp 'field-beginning)
                                     (field-beginning) (point-min))
                                 (point))
                        (setq char (char-before))
                        (cond
                         ((memq char type0)
                          (throw 'detect (1- count)))
                         ((memq char type1)
                          (delete-char -1)
                          (while (eq char (char-before))
                            (delete-char -1))
                          (throw 'detect (1- count)))
                         (t (delete-char -1))))
                      ;; exit
                      0))))))

(defvar minibuf-expand-filename-original nil)
(defvar minibuf-expand-filename-begin nil)

(defun minibuf-expand-filename (&optional args)
  "file-name-history だったら minibuffer の内容を expand-file-name する。
連続して起動すると元に戻す。C-u 付きだと link を展開する。"
  (interactive "P")
  (when (eq minibuffer-history-variable 'file-name-history)
    (let* ((try-again (eq last-command this-command))
           (beg (cond
                 ;; Emacs21.3.50 + ange-ftp だと2回目に変になる
                 ((and try-again minibuf-expand-filename-begin)
                  minibuf-expand-filename-begin)
                 ((fboundp 'field-beginning) (field-beginning))
                 (t (point-min))))
           (end (if (fboundp 'field-end) (field-end) (point-max)))
           (file (buffer-substring-no-properties beg end))
           (remote (when (string-match "^\\(/[^:/]+:\\)/" file)
                     (match-string 1 file)))
           (home (if (string-match "^\\(/[^:/]+:\\)/" file)
                     (expand-file-name (format "%s~" (match-string 1 file)))
                   (expand-file-name "~"))))
      (unless try-again
        (setq minibuf-expand-filename-begin beg))
      (cond
       ((and args try-again minibuf-expand-filename-original)
        (setq file (file-chase-links (expand-file-name file))))
       (args
        (setq minibuf-expand-filename-original file)
        (setq file (file-chase-links (expand-file-name file))))
       ((and try-again minibuf-expand-filename-original)
        (setq file minibuf-expand-filename-original)
        (setq minibuf-expand-filename-original nil))
       (t
        (setq minibuf-expand-filename-original file)
        (if (string-match (concat "^" (regexp-quote home)) file)
            (if remote
                (setq file (concat remote "~" (substring file (match-end 0))))
              (setq file (concat "~" (substring file (match-end 0)))))
          (setq file (expand-file-name file)))))
      (delete-region beg end)
      (insert file))))

(mapc (lambda (map)
        (define-key map "\C-d" 'minibuf-shrink)
        (define-key map "\M-\C-d" 'minibuf-expand-filename))
      (delq nil (list (and (boundp 'minibuffer-local-map)
                           minibuffer-local-map)
                      (and (boundp 'minibuffer-local-ns-map)
                           minibuffer-local-ns-map)
                      (and (boundp 'minibuffer-local-completion-map)
                           minibuffer-local-completion-map)
                      (and (boundp 'minibuffer-local-must-match-map)
                           minibuffer-local-must-match-map))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (M−d で単語削除するときにkill-ringに追加しない)
;; -> http://www.emacswiki.org/emacs/BackwardDeleteWord
;; -> http://qiita.com/kizashi1122/items/7028aa19f51823b69277

(defun delete-word (arg)
  "Delete characters forward until encountering the end of a word.
With argument, do this that many times."
  (interactive "p")
  (delete-region (point) (progn (forward-word arg) (point))))

(defun backward-delete-word (arg)
  "Delete characters backward until encountering the end of a word.
With argument, do this that many times."
  (interactive "p")
  (delete-word (- arg)))

;; ;; M-d でkill-ring追加なし単語削除
;; ;; (以下の kill-word-or-delete-horizontal-space に割り当てるためコメントアウト)
;; (global-set-key (kbd "M-d") 'delete-word)

;; M-DEL でkill-ring追加なし前方単語削除
(global-set-key (read-kbd-macro "<M-DEL>") 'backward-delete-word)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (shellと同様の単語削除コマンド)
;; -> http://d.hatena.ne.jp/kiwanami/20091222/1261504543

;; リージョンが活性化していればリージョン削除
;; 非活性であれば、直前の単語を削除
(defun kill-region-or-backward-kill-word ()
  (interactive)
  (if (region-active-p)
      (kill-region (point) (mark))
    (backward-kill-word 1)))
(global-set-key (kbd "C-w") 'kill-region-or-backward-kill-word)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (空白削除)
;; -> http://d.hatena.ne.jp/kiwanami/20091222/1261504543

;; カーソル位置前後が空白であれば空白削除
;; 空白でなければ単語削除
(defun kill-word-or-delete-horizontal-space (arg)
  (interactive "p")
  (let ((pos (point)))
    (if (and (not (eobp))
             (= (char-syntax (char-after pos)) 32)
             (= (char-syntax (char-after (1+ pos))) 32))
        (prog1 (delete-horizontal-space)
          (unless (memq (char-after pos) '(?( ?) ?{ ?} ?[ ?]))
            (insert " ")))
      (delete-word arg) ;; (kill-word arg) から上記定義の関数に変更
      )))
(global-set-key (kbd "M-d") 'kill-word-or-delete-horizontal-space)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 便利な設定 (-*- coding: 挿入関数)
;; -> http://d.hatena.ne.jp/syohex/20091002/1254496402

(defun insert-encoding-pragma (charset)
  "Insert encoding pragma for each programming language"
  (interactive "sInput encoding: ")
  (let* ((extension (insert-encoding-get-file-extension (buffer-name)))
         (comment-char (insert-encoding-get-comment-char extension))
         (pragma (concat comment-char "-*- coding:" charset " -*-")))
    (progn (beginning-of-line)
           (insert-string pragma))))

(defun insert-encoding-get-comment-char (extension)
  (let ((sharp-langs '("sh" "pl" "t" "pm" "rb" "py"))
        (slash-langs '("c" "h" "cpp"))
        (semicolon-langs '("gosh" "el" "scm" "lisp")))
    (cond ((member extension sharp-langs) "#")
          ((member extension slash-langs) "//")
          ((member extension semicolon-langs) ";;")
          (t ""))))

(defun insert-encoding-get-file-extension (filename)
  (if (string-match "\\.\\([a-zA-Z0-9]+\\)$" filename)
      (substring filename (match-beginning 1) (match-end 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; ハイライト (yank)

;; yank した文字列をハイライト表示
(when window-system
  (defadvice yank (after ys:highlight-string activate)
    (let ((ol (make-overlay (mark t) (point))))
      (overlay-put ol 'face 'highlight)
      (sit-for 0.5)
      (delete-overlay ol)))
  (defadvice yank-pop (after ys:highlight-string activate)
    (when (eq last-command 'yank)
      (let ((ol (make-overlay (mark t) (point))))
        (overlay-put ol 'face 'highlight)
        (sit-for 0.5)
        (delete-overlay ol)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; ハイライト (*completions* バッファの補完位置ハイライト)
;; -> http://homepage1.nifty.com/blankspace/emacs/tips.html

(defadvice display-completion-list (after display-completion-list-highlight activate)
  (let* ((str-list (mapc (lambda(x) (cond ((stringp x) x)
                                          ((symbolp x) (symbol-name x))
                                          ((listp x) (concat (car x)
                                                             (cadr x)))))
                         (ad-get-arg 0)))
         (str (car str-list)))
    (mapc (lambda (x)
            (while (or (> (length str) (length x))
                       (not (string= (substring str 0 (length str))
                                     (substring   x 0 (length str)))))
              (setq str (substring str 0 -1))))
          str-list)
    (save-current-buffer
      (set-buffer "*Completions*")
      (save-excursion
        (re-search-forward "Possible completions are:" (point-max) t)
        (while (re-search-forward (concat "[ \n]\\<" str) (point-max) t)
          (let ((o1 (make-overlay (match-beginning 0) (match-end 0)))
                (o2 (make-overlay (match-end 0)       (1+ (match-end 0)))))
            (overlay-put o1 'face '(:foreground "blue"))
            (overlay-put o2 'face '(:foreground "blue" :background "lavender"))))))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; 現在のファイルをIntelliJで開く
;; -> https://blog.shibayu36.org/entry/2017/08/07/190421

(defun my/open-by-intellij ()
  (interactive)
  (shell-command
   (format "/Applications/IntelliJ\\ IDEA.app/Contents/MacOS/idea --line %d %s >/dev/null 2>&1"
           (line-number-at-pos)
           (buffer-file-name)))
  (shell-command "open -a /Applications/IntelliJ\\ IDEA.app"))

(define-key global-map (kbd "C-c C-j") 'my/open-by-intellij)


;;;; IntelliJのファイルをEmacsで開く
;; -> https://developer.atlassian.com/blog/2015/03/emacs-intellij/
;; ~/bin/openinemacs
;; (ウィンドウアクティベート処理はオリジナルから変更しています)
;;--------------------------------------------------------------------
;;#!/bin/bash
;;
;;file=$1
;;line=$2
;;col=$3
;;/usr/local/bin/emacsclient -n -e \
;;    "(progn
;;
;;       ;; Load the file
;;       (find-file \"$file\")
;;
;;       ;; Jump to the same point as in IntelliJ
;;       ;; Unfortunately, IntelliJ doesn't always supply the values
;;       ;; depending on where the open is invoked from; e.g. keyboard
;;       ;; works, tab context doesn't
;;       (when (not (string= \"\" \"$line\"))
;;         (goto-char (point-min))
;;         (forward-line (1- $2))
;;         (forward-char (1- $3)))
;;
;;       ;; Raise/focus our window; depends on the windowing system
;;       (if (string-equal system-type \"darwin\")
;;         (if window-system
;;             (shell-command \"/usr/bin/osascript -e 'tell application \\\"Emacs\\\" to activate'\")
;;           (shell-command \"/usr/bin/osascript -e 'tell application \\\"iTerm2\\\" to activate'\"))
;;         (raise-frame))
;;
;;       ;; Automatically pick up changes made in IntelliJ
;;       (auto-revert-mode t))"
;;--------------------------------------------------------------------

;; IntelliJ Preferences -> Tools -> External Tools
;; Name: Open In Emacs Advanced
;; Description: Load file in Emacs, Advanced version
;; Tool Settings:
;;   Program: openinemacs
;;   Arguments: $FilePath$ $LineNumber$ $ColumnNumber$
;;   Working directory: $FileDir$
;; Advanced Options:
;;   [x] Synchronize files after execution
;;   [ ] Open console for tool output

;;********************************************************************
;;; Appendix
;;********************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Appendix: レジスタのヘルプ

;;;; レジスタ
;;;;; `M-x view-register RET R'
;;;;;      レジスタRの内容を表示する。

;;;; レジスタに位置を保存する
;;;;; `C-x r SPC R'
;;;;;      ポイント位置をレジスタRに保存する（`point-to-register'）。
;;;;; `C-x r j R'
;;;;;      レジスタRに保存した位置に移動する（`jump-to-register'）。

;;;; レジスタにテキストを保存する
;;;;; `C-x r s R'
;;;;;      レジスタRにリージョンをコピーする（`copy-to-register'）。
;;;;; `C-x r i R'
;;;;;      レジスタRからテキストを挿入する（`insert-register'）。

;;;; レジスタに矩形領域を保存する
;;;;; `C-x r r R'
;;;;;      矩形領域をレジスタRにコピーする（`copy-rectangle-to-register'）。
;;;;;      数引数を指定すると、コピー後に矩形領域を削除する。
;;;;; `C-x r i R'
;;;;;      レジスタRに保存した矩形領域（が存在すればそれ）を挿入する
;;;;;      （`insert-register'）。

;;;; レジスタにウィンドウ構成を保存する
;;;;; `C-x r w R'
;;;;;      選択したフレームのウィンドウの状態をレジスタRに保存する
;;;;;      （`window-configuration-to-register'）。
;;;;; `C-x r f R'
;;;;;      全フレームの状態を、各フレームのすべてのウィンドウを含めて、レジ
;;;;;      スタRに保存する（`frame-configuration-to-register'）。

;;;; レジスタに数値を保持する
;;;;; `C-u NUMBER C-x r n REG'
;;;;;      数値NUMBERをレジスタREGに保存する（`number-to-register'）。
;;;;; `C-u NUMBER C-x r + REG'
;;;;;      レジスタREG内の数値をNUMBERだけ増やす（`increment-register'）。
;;;;; `C-x r g REG'
;;;;;      レジスタREGの数値をバッファに挿入する。

;;;; レジスタにファイル名を保持する
;;;;;      (set-register ?z '(file . "/gd/gnu/emacs/19.0/src/ChangeLog"))
;;;;;      レジスタRに入れた名前のファイルを訪問するには、`C-x r j R'と打ちます。

;;;; ブックマーク
;;;;; `C-x r m RET'
;;;;;      訪問先のファイルのポイント位置にブックマークを設定する。
;;;;; `C-x r m BOOKMARK RET'
;;;;;      ポイント位置に、BOOKMARKという名前のブックマークを設定する
;;;;;      （`bookmark-set'）。
;;;;; `C-x r b BOOKMARK RET'
;;;;;      名前がBOOKMARKであるブックマークに移動する（`bookmark-jump'）。
;;;;; `C-x r l'
;;;;;      すべてのブックマークを一覧表示する（`list-bookmarks'）。
;;;;; `M-x bookmark-save'
;;;;;      現在のすべてのブックマークの値をデフォルトのブックマークファイル
;;;;;      に保存する。

;;********************************************************************
;;; EOF

(provide 'editutil-extra)
