;;; test-browser-utility.el --- test for browser utility

;; Copyright (C) 2014 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'ert)

(ert-deftest git-github-url ()
  "editutil--git-github-url"
  (let ((got (editutil--git-github-url "origin" "master")))
    (string= got "https://github.com/syohex/emacs-editutil"))

  (let ((got (editutil--git-github-url "origin" "foobar")))
    (string= got "https://github.com/syohex/emacs-editutil/tree/foobar")))

;;; test-browser-utility.el ends here