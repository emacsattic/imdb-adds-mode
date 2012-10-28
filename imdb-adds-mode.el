;;; imdb-adds-mode.el --- Major mode for editing IMDb data submissions
;;;
;;;  Editing and syntax highlighting extensions for off-line editing 
;;;  data submission files for the Internet Movie Database
;;;  (http://www.imdb.com/)
;;;  
;;;   ______________
;;;  |      /\      |   __________ 
;;;  |    /    \    |  |    /\    |   ______ 
;;;  |  /        \  |  |  /    \  |  |  /\  |
;;;  |/            \|  |/        \|  |/    \|
;;;  |\    IMDb    /|  |\  adds  /|  |\mode/|
;;;  |  \        /  |  |  \    /  |  |__\/__|
;;;  |    \    /    |  |____\/____|
;;;  |______\/______|
;;;
;;; Author: Oliver Heidelbach <ohei [at] imdb . com>
;;; Maintainer: Oliver Heidelbach <ohei [at] imdb . com>
;;; Created: 19 Jan 2001
;;; $Id: imdb-adds-mode.el,v 2.5 2005/06/12 19:56:17 ohei Exp ohei $
;;; Keywords: IMDb movies additions submission major-mode
;;;
;;; Copyright (C) 2001-2005 Oliver Heidelbach
;;;
;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 2, or (at your option)
;;; any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to
;;; the Free Software Foundation, 675 Massachusettes Ave,
;;; Cambridge, MA 02139, USA.

;;; Commentary:

;;; WHO SHOULD USE OR NEEDS THIS MODE?
;;; - This mode is for editing data additions for the Internet Movie
;;;   Database (IMDb). It's for people who submit such additions
;;;   regularly and don't use the IMDb's online additions system.
;;; - PLEASE NOTE: E-mail additions to IMDb have been mostly phased
;;;   out since Jan 1st, 2004. This mode will only be of use for you,
;;;   if you are one of the few people still allowed to send in e-mail
;;;   additions to IMDb.
;;;
;;; FEATURES
;;; - Provides easy help (description, formal syntax, example,
;;;   on-line guide and e-mail address) for every IMDb submission keyword
;;; - Can use locally saved on-line guides instead of connecting to
;;;   the IMDb WWW server
;;; - Syntax highlighting (font-lock)
;;; - Provides menu with most important commands
;;; - Creates new submission templates with the keywords you choose inserted
;;; - Creates sub-templates for keywords
;;; - Has beginner mode which makes using templates even more easier
;;; - Auto-creates a mail buffer for your data additions to IMDb
;;; - Provides insertion of comment, correct and namecorrect keywords
;;; - Provides copying any data field from the next/previous line
;;; - Provides moving to next/previous IMDb submission keyword
;;; - Provides swapping any name from non-comma to comma form
;;; - Provides auto-insertion, increasing or decreasing of
;;;   roman numerals, e.g. (II), for indexed names
;;; - Provides insertion of 'fulltext quotes' (qv).
;;;
;;; SETUP
;;; - Copy this file to a directory in your Emacs load-path and
;;;   byte-compile it
;;;   You may also want to update the TAGS file in that directory
;;;   by issuing 'etags *.el' on the command line for the documentation
;;;   to work properly
;;;
;;; - You can easily force autoloading for this mode. Let's say e.g.
;;;   you are naming your addition files 'contrib.1', 'contrib.2'
;;;   etc. Putting the following to your .emacs file will force
;;;   this mode on such files:
;;; 
;;;   ;;; Force IMDb adds mode
;;;   (setq auto-mode-alist (cons '("contrib\\..*$" . imdb-adds-mode) 
;;;      auto-mode-alist))
;;;   (autoload 'imdb-adds-mode "imdb-adds-mode" nil t)
;;;
;;; - You can force creating a new submission template for adding
;;;   data even if you are not currently editing a file in 
;;;   imdb-adds-mode by putting the following in your .emacs file:
;;;   
;;;   (defun my-make-imdb-submission-template ()
;;;     (interactive)
;;;     (switch-to-buffer (generate-new-buffer "New IMDb submission"))
;;;	(imdb-adds-mode)
;;;     (imdb-adds-insert-new-template))
;;;
;;;   ... and then binding it to an appropriate key, e.g.
;;;
;;;   (global-set-key [C-f8] 'my-make-imdb-submission-template)
;;;
;;;   Now you can create a new submission template any time
;;;   by just pressing CTRL-F8 on your keyboard.
;;;
;;; - You may want to have a look at the variable 
;;;   `imdb-adds-additions-template-alist' below which defines 
;;;   which keywords to add to a new template submission file by default.
;;;
;;; - There is not much more to set up. Putting the statement 
;;;   (setq imdb-adds-beginner-mode t) in your .emacs will turn 
;;;   on beginner-mode permanently.
;;;
;;; - Putting (setq imdb-adds-additions-template-reminder nil) in
;;;   your .emacs will turn off the character set reminder
;;;   insertion in new template files.
;;;
;;; - You may want to have look at and extend the abbreviations to add
;;;   production companies etc. you use most often.
;;;
;;; CHANGES
;;; - If you have used local help files and set the variables in your
;;;   startup file, you need to delete those. There are new extra variables
;;;   for setting a local path to the help files. Those are
;;;   * imdb-adds-mode-load-guides-local-extension (see below)
;;;   * imdb-adds-mode-local-www-server            (see below)
;;;   * imdb-adds-mode-local-www-guides-path       (see below)
;;;   The variable imdb-adds-mode-load-guides-local-extension works 
;;;   like before and is used as trigger for using local help files.
;;;
;;; COMMENTS
;;; - This file will not work with Emacs versions < 20.x
;;;   There are two things missing with Emacs versions 19.x and those
;;;   are regex-opt and browse-url. While those two could be copied
;;;   and installed, this mode also makes use of assoc-default.
;;;   This function was introduced in Emacs version 20.3. To make
;;;   this mode work in Emacs 19.x version, you would have to
;;;   implement this function somehow.
;;;
;;; - Please let me know if you find any keyword which is not supported.
;;;
;;; - Please let me know if you have written a cute extension
;;;   for this mode and I'll incorporate it into the next release.
;;;

;;; Code:

(require 'easymenu)  ;; needed for XEmacs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; User definable variables for IMDb adds mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar imdb-adds-mode-hook nil
  "*List of functions to call when entering imdb-adds mode.")

(defvar imdb-adds-beginner-mode nil
  "*Variable to set beginner mode if wanted.

Set this variable to 't' if you want to have 
beginner mode switched on permanently.

In beginner mode new template files are being built
by inserting the syntax descriptions as a reminder
of how to format the data to be added correctly.
This affects `imdb-adds-make-new-template' and
`imdb-adds-insert-new-template'.

The setting of this variable is also used by
the function `imdb-adds-insert-sub-template'.

Please note:
It is up to you to delete or overwrite thoses 
reminders before you are going to send the submission 
file to the IMDb mail server.

Please also see `imdb-adds-beginner-mode-use-examples'.

Default: nil")

(defvar imdb-adds-beginner-mode-use-examples nil
  "*Use keyword examples instead of formal syntax for beginner mode.

Set this variable to 't' if you want to have examples
inserted instead of formal syntax descriptions in
beginner mode.

Please do not ever forget to delete the examples
before you actually send in the data.

Please note that many examples are based on the least
information you have to add and thus are not showing
every possible bit you may add. If you want a complete 
pattern, you should use the formal syntax.
\(Of course you may also change the examples in
`imdb-adds-display-example' to fit your needs 
or way of thinking.)

The setting of this variable has no effect as long
as `imdb-adds-beginner-mode' is not set to 't'.")

(defvar imdb-adds-mail-server-address "adds"
  "*Address for the IMDb mail server (without domain).

The IMDb e-mail address where submissions should be sent to,
i.e. the part before the \@.

Default: \"adds\"")

(defvar imdb-adds-mail-domain "imdb.com"
  "*Mail domain for mailing to the Internet Movie Database (IMDb).

The general IMDb e-mail domain, i.e. the part after the \@.

Default: \"imdb.com\"")

(defvar imdb-adds-mode-www-server "http://www.imdb.com/"
  "*URL of the Internet Movie Database (IMDb) WWW server.

To access IMDb Pro, set this variable to \"http://pro.imdb.com/\".
See also `imdb-adds-mode-www-guides-path'.

   Default: \"http://www.imdb.com/\"")

(defvar imdb-adds-mode-www-guides-path "updates/guides/"
  "*Relative path to the Internet Movie Database (IMDb) online addition guides.

This is the WWW server directory where the online guides reside.

To access IMDb Pro, set this variable to \"updates/guide/\".
See also `imdb-adds-mode-www-server'.

Default: \"updates/guides/\"")

(defvar imdb-adds-mode-load-guides-local-extension nil
  "*Set this variable to '.html' to load the online addition guides from disk.

If you want to store the Internet Movie Database (IMDb) online
addition guides locally on your hard disk, please append the extension
'.html' to the files.

E.g. the online guide 'actors' should become 'actors.html'.

For this to work you will also need to set
`imdb-adds-mode-local-www-server' and
`imdb-adds-mode-local-www-guides-path' to non-nil:

E.g.
\(setq imdb-adds-mode-local-www-server \"file:///my-imdb-directory/\")
\(setq imdb-adds-mode-local-www-guides-path \"guides/\")
\(setq imdb-adds-mode-load-guides-local-extension \".html\")

If you request help for the 'actors' keyword, the guide will 
now load locally in your browser as
'file:///my-imdb-directory/guides/actors.html'

Default: nil")

(defvar imdb-adds-mode-local-www-server nil
  "*Set this variable to your local main path or WWW domain.

Please note that the Internet Movie Database (IMDb) online
addition guides saved locally will not load unless you set
the variable `imdb-adds-mode-load-guides-local-extension',
which is used as a trigger for this process.

For this to work you will also need to set
`imdb-adds-mode-local-www-guides-path'.

E.g.
\(setq imdb-adds-mode-local-www-server \"file:///my-imdb-directory/\")
\(setq imdb-adds-mode-local-www-guides-path \"guides/\")
\(setq imdb-adds-mode-load-guides-local-extension \".html\")

Default: nil")

(defvar imdb-adds-mode-local-www-guides-path nil
  "*Set this variable to your local sub-path.

Please note that the Internet Movie Database (IMDb) online
addition guides saved locally will not load unless you set
the variable `imdb-adds-mode-load-guides-local-extension',
which is used as a trigger for this process.

For this to work you will also need to set
`imdb-adds-mode-local-www-server'.

E.g.
\(setq imdb-adds-mode-local-www-server \"file:///my-imdb-directory/\")
\(setq imdb-adds-mode-local-www-guides-path \"guides/\")
\(setq imdb-adds-mode-load-guides-local-extension \".html\")

Default: nil")

(defvar imdb-adds-mode-feedback-path "help/feedback/contact"
  "*Relative path to the Internet Movie Database (IMDb) online contact form.

This is the WWW server directory where the online contact form resides.

To access IMDb Pro, set this variable to \"help/feedback/contact\".
See also `imdb-adds-mode-www-server'.

Default: \"help/feedback/contact\"")

(defvar imdb-adds-mode-contrib-mboard-path "board/bd0000042/threads/"
  "*Relative path to the Internet Movie Database (IMDb) contributors help message board.

This is the WWW server directory where the contributors help
message board resides.

To access IMDb Pro, set this variable to \"board/bd0000042/threads/\".
See also `imdb-adds-mode-www-server'.

Default: \"board/bd0000042/threads/\"")

(defvar imdb-adds-mode-czone-path "czone/"
  "*Relative path to the Internet Movie Database (IMDb) Contributor Zone.

This is the WWW server directory where the Contributor Zone resides..

The Contributor Zone is not available on IMDb Pro.

Default: \"czone/\"")

;;; Use the following to set up which IMDb submission keywords
;;; should be used for building an empty submission template
;;; by default.
;;; t   for inclusion
;;; nil for exclusion
;;;
(defvar imdb-adds-additions-template-alist
'(
  (TITLE . t)
  (TITLE-ATTRIBUTE . nil)
  (TITLECORRECT . t)
  (TITLEYEARS . nil)
  (AKA . t)
  (ISO2TITLE . nil)
  (ISO5TITLE . nil)
  (ISO7TITLE . nil)
  (RUSSIANTITLE . nil)
  (NAME . t)
  (NAMECORRECT . t)
  (NAMECORRECTAS . nil)
  (NAKA . t)
  (ISO2NAME . nil)
  (ISO5NAME . nil)
  (ISO7NAME . nil)
  (RUSSIANNAME . nil)
  (MALE . nil)
  (FEMALE . nil)
  (ACTOR . t)
  (ACTRESS . t)
;  (CAST . nil)   ;; phased out with v1.5 additions system
  (CHARA . t)
  (ORDER . t)
  (CASTCOM . t)
  (CASTVER . t)
  (GUEST . t)
  (EPISODECORRECT-GUEST . nil)
  (DIRECTOR . t)
  (WRITER . t)
  (PRODUCER . t)
  (COMPOSER . t)
  (CINEMATOGRAPHER . t)
  (EDITOR . t)
  (CASTINGDIRECTOR . t)
  (DESIGN . t)
  (ARTDIRECTOR . t)
  (SETDECORATOR . t)
  (COSTUME . t)
  (MAKEUP . t)
  (PRODUCTIONMANAGER . t)
  (ASSISTANTDIRECTOR . t)
  (ARTDEPARTMENT . t)
  (SOUNDDEPARTMENT . t)
  (SPECIALEFFECTSDEPARTMENT . t)
  (VISUALEFFECTSDEPARTMENT . t)
  (STUNTS . t)
  (MISC . t)
  (CREWCOM . t)
  (CREWVER . t)
  (BIOGR . t)
  (AGENT . nil)
  (URLNAME . t)
  (URLTITLE . t)
  (PRODCO . t)
  (AKAPRODCO . nil)
  (DISTRIB . t)
  (AKADISTRIB . nil)
  (SFXCO . t)
  (AKASFXCO . nil)
  (COMPANY . t)
  (COMPANYCORRECT . nil)
  (COMPANY-CONTACT . nil)
  (COLOR . t)
  (MIX . t)
  (COUNTRY . t)
  (LANGUAGE . t)
  (TIME . t)
  (CERT . t)
  (RELEASE . t)
  (OUTLINE . t)
  (PLOTS . t)
  (GENRE . t)
  (KEYWORD . t)
  (QUOTE . nil)
  (TRIVIA . nil)
  (GOOF . nil)
  (SOUNDTRACK . nil)
  (CRAZY . nil)
  (VERSIONS . nil)
  (MOVIELINK . t)
;  (BUSINESS . nil)  ;; phased out with v1.5 additions system
  (BUDGET . t)       ;; new with v1.5 additions system
  (OPENWEEK . nil)   ;; new with v1.5 additions system
  (GROSSBOX . nil)   ;; new with v1.5 additions system
  (WEEKGROSS . nil)  ;; new with v1.5 additions system
  (ADMISSIONS . nil) ;; new with v1.5 additions system
  (RENTALS . nil)    ;; new with v1.5 additions system
  (PRODDATES . nil)  ;; new with v1.5 additions system
  (SHOOTDATES . t)   ;; new with v1.5 additions system
  (COPYRIGHTS . t)   ;; new with v1.5 additions system
  (LOCATION . t)
  (LOCATIONCORRECT . nil)
  (LAB . t)
  (CAMERA . nil)
  (METRES . t)
  (PROCESS . t)
  (RATIO . t)
  (PRINTS . t)
  (NEGATIVE . t)
  (LASERDISC . nil)
  (DVD . nil)
  (LITERATURE . nil) ;; still used for correct/replace
  (LITERATURENEW . nil) ;; new with v1.5 additions system
  (TAG . t)
  (COMMENT . nil)
  (AWMASTER . nil)
  (AWARD . nil)
)
  "*List defining the default IMDb addition keywords for templates.

Use 't' to add the keyword, 'nil' to exclude it from the template.

This list is to define which of the IMDb submission keywords should
be used to build a new submission template by default. E.g. if you are
never submitting information about laserdiscs, simply set the value
for the LASER keyword to 'nil'.

If you always only want to submit TV guest appearances, set all
keywords except GUEST to 'nil'.

Of course you can always add or delete keywords in your
submission file later manually.

Please also note that the keyword END is always appended to
the end of the template automatically.")

(defvar imdb-adds-entry-okay "\t"
  "*String to insert at beginning of line, when an entry of an 
old submission file is okay, i.e. appears in the database now.

Default: \"\\t\"")

(defvar imdb-adds-additions-template-reminder t
  "*Insert a character set reminder into submission template.

Set this variable to 'nil' if you don't want to be reminded of
the character set to use for IMDb mail-server additions.

Default: t")

(defvar imdb-adds-additions-template-reminder-text "
The character set you have to use is ASCII or ISO-8859-1 
depending on the data you want to submit.

If the data has accented characters such as äöñàé...
you must use the ISO-8859-1 character set for West 
European languages.
Data mailed in with it must be MIME compatible.

You can disable this reminder by setting the value of
`imdb-adds-additions-template-reminder' to 'nil' in 
your Emacs configuration.

Please delete these lines, before you are going to mail
your additions to the mail-server.

"
  "Character set reminder to be inserted into new templates.")

(defvar imdb-adds-mode-map nil
  "Keymap for imdb-adds major mode.")

;;; Define a syntax table for imdb-adds mode
(defvar imdb-adds-mode-syntax-table nil
  "Syntax table for imdb-adds major mode.")

;;; Define an abbreviations table for imdb-adds mode
(defvar imdb-adds-mode-abbrev-table (make-abbrev-table)
  "Abbreviation table for imdb-adds major mode.")

;;; Tags for abbreviations
;; USA
(define-abbrev imdb-adds-mode-abbrev-table "mgm" "Metro-Goldwyn-Mayer (MGM) [us]")
(define-abbrev imdb-adds-mode-abbrev-table "fox" "20th Century Fox [us]")
(define-abbrev imdb-adds-mode-abbrev-table "foxtv" "20th Century Fox Television [us]")
(define-abbrev imdb-adds-mode-abbrev-table "abc" "American Broadcasting Company (ABC) [us]")
(define-abbrev imdb-adds-mode-abbrev-table "nbc" "National Broadcasting Company (NBC) [us]")
(define-abbrev imdb-adds-mode-abbrev-table "pbs" "Public Broadcasting Service (PBS) [us]")
(define-abbrev imdb-adds-mode-abbrev-table "cbs" "CBS Television [us]")
(define-abbrev imdb-adds-mode-abbrev-table "hbo" "Home Box Office (HBO) [us]")
(define-abbrev imdb-adds-mode-abbrev-table "mtv" "Music Television (MTV) [us]")
;; Canada
(define-abbrev imdb-adds-mode-abbrev-table "nfb" "National Film Board of Canada (NFB) [ca]")
;; Austira/Germany/Switzerland
(define-abbrev imdb-adds-mode-abbrev-table "ndr" "Norddeutscher Rundfunk (NDR) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "wdr" "Westdeutscher Rundfunk (WDR) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "swr" "Südwestdeutscher Rundfunk (SWR) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "zdf" "Zweites Deutsches Fernsehen (ZDF) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "sfb" "Sender Freies Berlin (SFB) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "br" "Bayerischer Rundfunk (BR) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "hr" "Hessischer Rundfunk (HR) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "orb" "Ostdeutscher Rundfunk Brandenburg (ORB) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "rb" "Radion Bremen (RB) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "mdr" "Mitteldeutscher Rundfunk (MDR) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "orf" "Österreichischer Rundfunk (ORF) [at]")
(define-abbrev imdb-adds-mode-abbrev-table "hff" "Hochschule für Fernsehen und Film München (HFF) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "drs" "Schweizer Fernsehen DRS [ch]")
(define-abbrev imdb-adds-mode-abbrev-table "dffb" "Deutsche Film- und Fernsehakademie Berlin (DFFB) [de]")
(define-abbrev imdb-adds-mode-abbrev-table "hkw" "Hochschule für Film und Fernsehen 'Konrad Wolf' [de]")
;; UK/Great Britain
(define-abbrev imdb-adds-mode-abbrev-table "bbc" "BBC (British Broadcasting Corporation) [gb]")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Basic definition of IMDb additions keywords
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar imdb-adds-kw-title
   '("TITLE" "TITLELOCK" "TITLEYEARS" "AKA" "ISO2TITLE" "ISO5TITLE"
     "ISO7TITLE" "RUSSIANTITLE"))

(defvar imdb-adds-kw-basic-cast
   '("ACTOR" "ACTRESS" "GUEST"))

(defvar imdb-adds-kw-main-crew
   '("DIRECTOR" "WRITER" "COMPOSER" "CINEMATOGRAPHER" "DESIGN" "COSTUME"
     "EDITOR" "PRODUCER"))

(defvar imdb-adds-kw-other-crew
   '("CASTINGDIRECTOR" "SOUNDDEPARTMENT" "ASSISTANTDIRECTOR"
     "PRODUCTIONMANAGER" "ARTDIRECTOR" "SETDECORATOR" "MAKEUP"
     "SPECIALEFFECTSDEPARTMENT" "VISUALEFFECTSDEPARTMENT" "STUNTS"
     "MISC" "ARTDEPARTMENT"))

(defvar imdb-adds-kw-meta-name
;;   '("CAST" "CASTCOM" "CASTVER" "CHARA" "ORDER" "CREWCOM" "CREWVER")) 
   '("CASTCOM" "CASTVER" "CHARA" "ORDER" "CREWCOM" "CREWVER")) 

(defvar imdb-adds-kw-any-name
   '("NAKA" "URLNAME" "ISO2NAME" "ISO5NAME" "ISO7NAME" "RUSSIANNAME"))

(defvar imdb-adds-kw-company
   '("PRODCO" "AKAPRODCO" "DISTRIB" "AKADISTRIB" "SFXCO" "AKASFXCO" "COMPANY"))

(defvar imdb-adds-kw-title-basic
   '("COLOR" "MIX" "GENRE" "KEYWORD" "MOVIELINK" "URLTITLE"))

(defvar imdb-adds-kw-title-country-related
   '("COUNTRY" "LANGUAGE" "TIME" "CERT" "RELEASE" "LOCATION"))

(defvar imdb-adds-kw-title-technical
   '("LAB" "PROCESS" "PRINTS" "NEGATIVE" "RATIO" "METRES" "CAMERA"))

(defvar imdb-adds-kw-title-business
   '("ADMISSIONS" "BUDGET" "COPYRIGHTS" "GROSSBOX" "OPENWEEK" "PRODDATES"
     "RENTALS" "SHOOTDATES" "WEEKGROSS"))

(defvar imdb-adds-kw-title-other
   '("LITERATURENEW"))

;;; List of IMDb additions keywords which may span over
;;; multiple lines
;;; AGENT and COMPANY-CONTACT probably don't take COMMENT- and other
;;; prefixes, but stay here for now
;;; deleted BUSINESS
(defvar imdb-adds-kw-multiline
   '("PLOTS" "OUTLINE" "TAG" "BIOGR" "AWARD" "AWMASTER"
     "SOUNDTRACK" "LITERATURE" "QUOTE" "TRIVIA" "CRAZY"
     "DVD" "LASERDISC" "GOOF" "VERSIONS" "INPROD" "AGENT" "COMPANY-CONTACT"))
                   
(defvar imdb-adds-kw-meta
   '("TITLE-ATTRIBUTE" "TITLECORRECT" "NAME" "NAMECORRECT" "NAMECORRECTAS"
     "MALE" "FEMALE" "ATTRIBUTE" "REPLACE" "COMMENT" "CORRECT" "COMPANYCORRECT"
     "LOCATIONCORRECT" "EPISODECORRECT-GUEST" "END"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Definition of IMDb additions keyword groups
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar imdb-adds-title-kw
  (append imdb-adds-kw-title imdb-adds-kw-title-basic 
    imdb-adds-kw-title-country-related imdb-adds-kw-title-technical))

;;; all namecorrect- candidates
(defvar imdb-adds-name-kw
  (append imdb-adds-kw-basic-cast imdb-adds-kw-main-crew
	  imdb-adds-kw-other-crew))

(defvar imdb-adds-other-kw
  (append imdb-adds-kw-company imdb-adds-kw-any-name imdb-adds-kw-title-other
	  imdb-adds-kw-title-business imdb-adds-kw-meta-name))

(defvar imdb-adds-kw-single-line
  (append imdb-adds-title-kw imdb-adds-name-kw imdb-adds-other-kw))

(defvar imdb-adds-prefix-keywords
  (append imdb-adds-kw-single-line imdb-adds-kw-multiline))

(defvar imdb-adds-non-prefix-keywords
  (append imdb-adds-kw-meta))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Basic IMDb additions keyword font-lock groups
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; List of IMDb additions keywords which do take COMMENT-
;;; or CORRECT- prefixes
(defvar imdb-adds-mode-keywords-base
  (regexp-opt imdb-adds-prefix-keywords))

;;; List of IMDb additions keywords which don't take COMMENT-
;;; or CORRECT- prefixes
(defvar imdb-adds-mode-keywords-other
  (regexp-opt imdb-adds-non-prefix-keywords))

;;; List of IMDb additions keywords which do take the
;;; NAMECORRECT- prefix
(defvar imdb-adds-mode-keywords-namecorrect
  (regexp-opt imdb-adds-name-kw))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Basic definition of IMDb built-in tags
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; phased out
;; (defvar imdb-adds-business-builtin
;;  '("MV" "BT" "GR" "OW" "RT" "AD" "PD" "ST"))

(defvar imdb-adds-plots-builtin
  '("MV" "PL" "BY"))

(defvar imdb-adds-outline-builtin
  '("MV" "PL" "BY"))

(defvar imdb-adds-awards-builtin
  '("MV" "NM" "CY" "EV" "AW" "CT" "YR" "RK" "CO"))

(defvar imdb-adds-awmaster-builtin
  '("EV" "AW" "EL" "EO" "AO" "AF" "AC" "AI" "OW"
    "ST" "SG" "TP" "CO" "CR" "JU" "HO" "DA" "LO" "TR"))

(defvar imdb-adds-dvd-builtin
  '("DN" "LB" "CN" "DT" "OT" "PC" "YR" "CF" "LE" "CA"
    "GR" "RD" "ST" "PR" "RC" "AC" "CP" "LA" "SF" "SU"
    "VS" "CO" "MF" "PP" "PK" "SI" "DF" "PF" "AS" "CC"
    "CS" "QP" "BR" "IN"))

(defvar imdb-adds-inprod-builtin
  '("MV" "ST" "CM" "UP"))

(defvar imdb-adds-laserdisc-builtin
  '("LN" "LB" "CN" "LT" "OT" "PC" "YR" "CF" "CA" "GR"
    "LA" "SU" "LE" "RD" "ST" "PR" "VS" "CO" "SE" "DS"
    "AL" "AR" "MF" "PP" "SZ" "SI" "DF" "PF" "AS" "CC"
    "CS" "QP" "IN"))

(defvar imdb-adds-literature-builtin
  '("MOVI" "SCRP" "NOVL" "ADPT" "BOOK" "PROT" "IVIW" 
    "CRIT" "ESSY" "OTHR"))

(defvar imdb-adds-biogr-builtin
  '("NM" "RN" "NK" "DB" "DD" "HT" "BG" "BY" "SP" "BO"
    "BT" "PI" "OW" "TM" "TR" "QU" "IT" "AG" "PT" "CV"
    "WN" "SA" "AT"))

(defvar imdb-adds-agent-builtin
  '("NM" "CONTACT" "JOB" "COMP" "ADDR" "TEL" "FAX" 
    "EMAIL" "ONLYPRO" "REPLACE"))

(defvar imdb-adds-companycontact-builtin
  '("COMP" "CONTACT" "ADDR" "TEL" "FAX" "EMAIL"
    "WEBSITE" "ONLYPRO" "REPLACE" "COMM"))

(defvar imdb-adds-misc-multiline-builtin
  '("\#"))

(defvar imdb-adds-weblinks-builtin
  '("COM" "IMG" "MOV" "MSC" "OFF" "POS" "SND" "TRA"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Definition of IMDb bulit-in tag groups
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; deleted imdb-adds-business-builtin  
(defvar imdb-adds-multiline-builtin
  (append imdb-adds-plots-builtin
	  imdb-adds-awards-builtin imdb-adds-awmaster-builtin
	  imdb-adds-dvd-builtin imdb-adds-inprod-builtin
	  imdb-adds-laserdisc-builtin imdb-adds-literature-builtin
	  imdb-adds-biogr-builtin imdb-adds-agent-builtin
	  imdb-adds-companycontact-builtin
	  ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Basic IMDb built-in tag font-lock groups
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; List of IMDb additions keywords' built-in tags
(defvar imdb-adds-mode-builtin-base
  (regexp-opt imdb-adds-multiline-builtin))

(defvar imdb-adds-mode-builtin-misc
  (regexp-opt imdb-adds-misc-multiline-builtin))

(defvar imdb-adds-mode-builtin-www-links
  (regexp-opt imdb-adds-weblinks-builtin))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Define IMDb additions font-lock keywords
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar imdb-adds-mode-keywords
  (list
     (cons (concat "^\\(" imdb-adds-mode-keywords-base "\\)\\>$")
	   'font-lock-keyword-face)
     (cons (concat "^CORRECT-\\(" imdb-adds-mode-keywords-base "\\)\\>")
	   'font-lock-keyword-face)
     (cons (concat "^COMMENT-\\(" imdb-adds-mode-keywords-base "\\)\\>")
	   'font-lock-keyword-face)
     (cons (concat "^NAMECORRECT-\\("
		   imdb-adds-mode-keywords-namecorrect "\\)\\>")
	   'font-lock-keyword-face)
     (cons (concat "^NAMECORRECTAS-\\("
		   imdb-adds-mode-keywords-namecorrect "\\)\\>")
	   'font-lock-keyword-face)
     (cons (concat "^ATTRIBUTE-\\("
		   imdb-adds-mode-keywords-namecorrect "\\)\\>")
	   'font-lock-keyword-face)
     (cons (concat "^REPLACE-\\("
		   imdb-adds-mode-keywords-namecorrect "\\)\\>")
	   'font-lock-keyword-face)
     (cons "^\\(COMMENT-TITLECORRECT\\)\\>" 'font-lock-keyword-face)
     (cons "^\\(COMMENT-NAMECORRECT\\)\\>" 'font-lock-keyword-face)
     (cons "^\\(TITLE-ATTRIBUTE\\)\\>" 'font-lock-keyword-face)
     (cons (concat "^\\(" imdb-adds-mode-keywords-other "\\)\\>") 
	   'font-lock-keyword-face)
     ;;; does not work: say comment-start is ';'
     ;;;   (cons (concat "^" comment-start "\\(.*\\)$") 'font-lock-comment-face)
     (cons "^=>\\(.*\\)$" 'font-lock-comment-face)
     ))

(defvar imdb-adds-mode-builtins
  (list
   (cons (concat "^\\(" imdb-adds-mode-builtin-base "\\)\\>: ")
	 'font-lock-builtin-face)
   (cons (concat "|\\<\\(" imdb-adds-mode-builtin-www-links "\\)\\>|")
	 'font-lock-builtin-face)
   (cons (concat "^" imdb-adds-mode-builtin-misc " ")
         'font-lock-builtin-face)
))

(defvar imdb-adds-mode-additional-builtins
  '(
    ("\\(^\\|: \\)\\(!.*\\)$" 2 font-lock-function-name-face t)
    ("|" 0 font-lock-builtin-face t)
))

(defvar imdb-adds-mode-fontlock-keywords
  (append imdb-adds-mode-keywords imdb-adds-mode-builtins
	  imdb-adds-mode-additional-builtins))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Definition of IMDb keyword help texts and functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Return first element
;; (nth 0 (nth 0 (assoc-default 'TITLE imdb-adds-keyword-alist 'string=)))
;; Return second element
;; (nth 1 (nth 0 (assoc-default 'TITLE imdb-adds-keyword-alist 'string=)))
;; Return third element
;; (nth 2 (nth 0 (assoc-default 'TITLE imdb-adds-keyword-alist 'string=)))

;;; Alist format is as follows:
;;; (KEYWORD (
;;;  on-line guide
;;;  formal keyword-syntax
;;;  keyword-syntax example
;;;  maintainer e-mail address without domain
;;;  Short description as what to submit under a keyword.
;;;  attribute formal keyword-syntax
;;;  replace formal keyword-syntax, *only* the additional replace part
;;;  ))
;;; Store column width with ruler in mini-buffer???
;;;
;;; You may safely add new keywords to this alist. It is not
;;; considered to be of fix length.
(defvar imdb-adds-keyword-alist
  '(
    (ACTOR (
      cast  ;; v1.5
      "<name>|<title>|*(<attribute>)|<role>|<credits order>|"
      "Ford, Harrison|Blade Runner (1982)||Rick Deckard|1"
      "actors"
      "Male performances as credited on-screen 
except from TV guest appearances"
      "<name>|<title>|(<attribute>)|<role>|<order>|(<new attr.>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<new role>|<new order>|<explanation>|"
      ))
    (ACTRESS (
      cast  ;; v1.5
      "<name>|<title>|*(<attribute>)|<role>|<credits order>|"
      "Ryan, Meg|Anastasia (1997)|(voice)|Anastasia|1"
      "actresses"
      "Female performances as credited on-screen 
except from TV guest appearances"
      "<name>|<title>|(<attribute>)|<role>|<order>|(<new attr.>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<new role>|<new order>|<explanation>|"
      ))
    (ADMISSIONS (
      business_ad  ;; v1.5
      "<title>|<volume>|<country>|<date>|*(<attribute>)|"
      "Hunt for Red October, The (1990)|1,000|Afghanistan|18 November 1999|"
      "business"
      "Ticket sales (admissions) data (business data)"
      nil
      nil
      ))
    (AGENT (
      nil
      (imdb-adds-display-help "AGENT")
      (imdb-adds-display-example "AGENT")
      nil
      "Agent contact details for IMDb Pro and IMDb"
      nil
      nil
      ))
    (AKA (
      akas  ;; v1.5
      "<title>|<aka-title>|(<country-language>)|(<title-type>)"
      "Maestrale (2000)|Winds of Passion (2001)|(International: English title)"
      "aka-titles"
      "Alternative or foreign release titles"
      nil
      nil
      ))
    (AKADISTRIB (
      distributors
      "<derived-company-name>|<company-name>"
      "BBC Enterprises|British Broadcasting Corporation (BBC) [uk]"
      "distributors"
      "Merge two distributor names into one"
      nil
      nil
      ))
    (AKAPRODCO (
      production_companies
      "<derived-company-name>|<company-name>"
      "BBC Enterprises [uk]|British Broadcasting Corporation (BBC) [uk]"
      "prod-companies"
      "Merge two production company names into one"
      nil
      nil
      ))
    (AKASFXCO (
      special_effects_companies
      "<derived-company-name>|<company-name>"
      "ILM [us]|Industrial Light & Magic [us]"
      "sfx-companies"
      "Merge two special effects company names into one"
      nil
      nil
      ))
    (ARTDEPARTMENT (
      art_department  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Acord, Joe|Opposite of Sex, The (1998)|(property master)"
      "art-department"
      "All art department on-screen credits excluding
\(lead) art directors, (lead) set decorators, 
\(lead) production and costume designers who
all have their own keywords to submit data for."
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (ARTDIRECTOR (
      art_directors  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Ybarra, Alfred|Hour of the Gun (1967)|(as Alfred C. Ybarra)"
      "art-directors"
      "Art directors as credited on-screen including 
chief, supervising or associate art director credits"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (ASSISTANTDIRECTOR (
      assistant_directors  ;; v1.5
      "<name>|<title>|(<attribute>)"
      "Ziesmer, Jerry|Almost Famous (2000)|(first assistant director)"
      "assistant-directors"
      "Assistant directors and unit directors,
as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (AWARD (
      awards  ;; v1.5
      (imdb-adds-display-help "AWARD")
      (imdb-adds-display-example "AWARD")
      "awards"
      "Award winners and nominees"
      nil
      nil
      ))
    (AWMASTER (
      awards  ;; v1.5
      (imdb-adds-display-help "AWMASTER")
      (imdb-adds-display-example "AWMASTER")
      "awards"
      "Award events and film festivals including their 
awards as well as juries, hosts, venues and dates"
      nil
      nil
      ))
    (BIOGR (
      biography  ;; v1.5
      (imdb-adds-display-help "BIOGR")
      (imdb-adds-display-example "BIOGR")
      "biographies"
      "Biographical data including birth dates, marriages,
agents, press material, trivia, other works, etc."
      nil
      nil
      ))
    (BUDGET (
      business_bt  ;; v1.5
      "<title>|<currency>|<numeric>|*<attribute>|*<order>|"
      "Hunt for Red October, The (1990)|GBP|20,000|"
      "business"
      "Budget information (business data)"
      nil
      nil
      ))
;     (BUSINESS (
;       business
;       (imdb-adds-display-help "BUSINESS")
;       (imdb-adds-display-example "BUSINESS")
;       "business"
;       "Business data like grosses, admissions, 
; copyright and shooting dates"
;      ))
    (CAMERA (
      technical  ;; v1.5
      "<title>|<camera>|*(<attribute>)"
      "Benny & Joon (1993)|Panavision Cameras and Lenses|"
      "technical"
      "Cameras being used for shooting"
      nil
      nil
      ))
;     (CAST (   ;; phased out, submitters must decide on gender
;       nil   ;;; no guide available
;       "<name>|<title>|(<attribute>)|<role>|<cast order>"
;       "Lan, Sai|Baak Fan Baak Ngam 'Feel' (1996)|(cameo)|"
;       "actors"
;       "Performers who's gender is unknown 
; except from TV guest appearances"
;       nil
;       nil
;       ))
    (CASTCOM (
      nil   ;;; no guide available
      "<title>|<your-name> <your-email-address>"
      "Bound (1997)|Oliver Heidelbach <ohei\>"
      "actors"
      "Claim that the cast for a movie is complete 
as the on-screen credits read"
      nil
      nil
      ))
    (CASTINGDIRECTOR (
      casting_directors  ;; v1.5
      "<name>|<title>|(<attribute>)"
      "Barden, Kerry|54 (1998)|"
      "casting-directors"
      "Casting directors (lead person(s)),
as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (CASTVER (
      nil   ;;; no guide available
      "<title>|<your-name> <your-mail-address>"
      "Bound (1997)|Oliver Heidelbach <ohei\>"
      "actors"
      "Claim that you could verify an IMDb 
cast listing already marked as complete"
      nil
      nil
      ))
    (CERT (
      certificates  ;; v1.5
      "<title>|<country>|<certificate>|(<attribute>)"
      "1999 Madeleine (1999)|Switzerland|12|(canton of Geneva)"
      "certificates"
      "National certificates recommending a certain 
age for watching a movie"
      nil
      nil
      ))
    (CHARA (
      characters  ;; v1.5
      "<name>|<title>|<role>"
      "Ford, Harrison|Blade Runner (1982)|Rick Deckard"
      "actors"
      "A character name for an existing IMDb 
actor or actress credit"
      nil
      nil
      ))
    (CINEMATOGRAPHER (
      cinematographers  ;; v1.5
      "<name>|<title>|*(<attribute>)|"
      "Allen, Paul H.|West of Santa Fe (1928)|(as Paul Allen)"
      "cinematographers"
      "Director of photography (lead person(s)),
as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (COLOR (
      color_info  ;; v1.5
      "<title>|<type-of-color-format>|(<attribute>)"
      "12 Angry Men (1957)|Black and White"
      "color"
      "Color format information"
      nil
      nil
      ))
    (COMMENT (
      nil
      nil
      nil
      nil
      "Any free form text comment. This is the least 
specific type of comment. Whenever possible you 
should use the more specific form like COMMENT-ACTOR
or COMMENT-BIOGR or others"
      nil
      nil
      ))
    (COMPANY (
      miscellaneous_companies  ;; v1.5
      "<title>|<company-name> [country-tag]|(<credit>)|<order>|"
      "X Files, The (1998)|Chapman/Leonard Studio Equipment|(camera dollies)"
      "misc-companies"
      "Miscellaneous company credits including their credit
except for the laboratory, special effects company, 
production company or distributor which all have
their own keywords to submit data for"
       "<title>|<company>|(<credit>)|<order>|(<new credit>)|<explanation>|"
       "<new title>|<new company>|(<new credit>)|<new order>|<explanation>|"
      ))
    (COMPANY-CONTACT (
      company
      (imdb-adds-display-help "COMPANY-CONTACT")
      (imdb-adds-display-example "COMPANY-CONTACT")
      nil
      "Company contact details for IMDb Pro and IMDb"
      nil
      nil
      ))
    (COMPANYCORRECT (
      miscellaneous-companies
      "<wrong company-name>|<correct company-name>"
      "Roxy Film|Roxy Film GmbH [de]"
      "misc-companies"
      "Correct misspelled or otherwise false company entries."
      nil
      nil
      ))
    (COMPOSER (
      composers
      "<name>|<title>|(<attribute>)|"
      "Zimmer, Hans|As Good As It Gets (1997)|"
      "composers"
      "Composers (lead person(s)), as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (COPYRIGHTS (
      business_cp  ;; v1.5
      "<title>|<copyright>|<attribute>|"
      "White Rush (2003)|(2003) White Rush, LLC.|(on print)|"
      "business"
      "Copyright information for a movie (business data)"
      nil
      nil
      ))
    (CORRECT (
      nil
      nil
      nil
      nil
      "Any free form text correction. This is the least 
specific type of a correction. Whenever possible you 
should use the more specific form like CORRECT-ACTOR
or CORRECT-BIOGR or others"
      nil
      nil
      ))
    (COSTUME (
      costume_designers  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Wells, Larry S.|\"X Files, The\" (1993)|(1993-1995)"
      "costumes"
      "Costume designer (lead person(s)), 
as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (COUNTRY (
      countries  ;; v1.5
      "<title>|<country>|*(<order>)"
      "Babas mou o tedy boys, O (1966)|Greece"
      "countries"
      "Production countries"
      nil
      nil
      ))
    (CRAZY (
      crazy_credits  ;; v1.5
      (imdb-adds-display-help "CRAZY")
      (imdb-adds-display-example "CRAZY")
      "crazy-credits"
      "Crazy things or jokes contained in a movie's credits"
      nil
      nil
      ))
    (CREWCOM (
      nil  ;;; no guide available
      "<title>|<your-name> <your-mail-address>"
      "Bound (1997)|Oliver Heidelbach <ohei\@imdb.com>"
      nil
      "Claim that the whole crew for a movie is 
complete as can be seen by the on-screen credits"
      nil
      nil
      ))
    (CREWVER (
      nil  ;;; no guide available
      "<title>|<your-name> <your-mail-address>"
      "Bound (1997)|Oliver Heidelbach <ohei\@imdb.com>"
      nil
      "Claim that an IMDb crew listing already 
marked complete is really complete for a movie"
      nil
      nil
      ))
    (DESIGN (
      production_designers
      "<name>|<title>|(<attribute>)|"
      "Sylbert, Paul|Free Willy 2: The Adventure Home (1995)|"
      "prod-designers"
      "Production designers (lead person(s)), 
as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (DIRECTOR (
      directors  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Scorsese, Martin|Bringing Out the Dead (1999)|"
      "directors"
      "Director(s) (lead person), as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (DISTRIB (
      distributors  ;; v1.5
      "<title>|<company-name> [country-tag]|(<attribute>)|*<order>|"
      "Absolute Power (1997)|Lusomundo [pt]|(Portugal)"
      "distributors"
      "Distribution companies with country informations"
      "<title>|<company>|(<attribute>)|<order>|(<new attribute>)|<explanation>|"
      "<new title>|<new company>|(<new attribute>)|<new order>|<explanation>|"
      ))
    (DVD (
      dvd  ;; v1.5
      (imdb-adds-display-help "DVD")
      (imdb-adds-display-example "DVD")
      "dvds"
      "Details about available DVDs"
      nil
      nil
      ))
    (EDITOR (
      editors  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Baird, Stuart|Mission: Impossible II (2000)|(uncredited)"
      "editors"
      "Film editors (lead person(s)), as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (END (
      nil  ;;; no guide available
      "This keyword has no syntax."
      "This keyword has no syntax."
      nil
      "End of data submission marker. Everything below 
this keyword will be ignored by the IMDb mail 
server, e.g. e-mail signatures."
      nil
      nil
      ))
    (EPISODECORRECT-GUEST (
      guest-appearances
      "title|ep. title|air date|ep. number|new ep. title|new air|new number"
      "\"JAG\" (1995)|Shadows|9/30/1995|1.3|Shadow|9/30/1995|1.3"
      nil
      "Clean up the episode lists for a given title."
      nil
      nil
      ))
    (FEMALE (
      nil  ;;; no guide available
      "<name>|"
      "Gong, Li|"
      nil
      "Swap the gender of a female falsely listed 
as an actor"
      nil
      nil
      ))
    (GENRE (
      genres  ;; v1.5
      "<title>|<genre>"
      "Star Wars (1977)|Sci-Fi"
      "genres"
      "Main genre of a movie"
      nil
      nil
      ))
    (GOOF (
      goofs  ;; v1.5
      (imdb-adds-display-help "GOOF")
      (imdb-adds-display-example "GOOF")
      "goofs"
      "Production mistakes, factual errors, anachronisms and such"
      nil
      nil
      ))
    (GROSSBOX (
      business_gr  ;; v1.5
      "<title>|<currency>|<numeric>|<country>|<date>|<attribute>|"
      "Hunt for Red October, The (1990)|GBP|150,000,000|Afghanistan|13 September 1999|"
      "business"
      "Cummulative box office gross (business data)"
      nil
      nil
      ))
    (GUEST (
      guests  ;; v1.5
      "<name>|<title>|<role>|(<attribute>)|<epis. title>|<air date>|<epis. #>"
      "Long, Shelley|\"Frasier\" (1993)|Diane Chambers||Diane|2/13/1996|3.14|"
      "guests"
      "Noteable TV guest apearances, male and female"
      nil
      nil
      ))
    (INPROD (
      inproduction  ;; v1.5
      (imdb-adds-display-help "INPROD")
      (imdb-adds-display-example "INPROD")
      nil
      "Status of movies still in production"
      nil
      nil
      ))
    (ISO2NAME (
      nil  ;;; no guide available
      nil
      nil
      "help"
      "Original on-screen name in ISO2 character set"
      nil
      nil
      ))
    (ISO5NAME (
      nil  ;;; no guide available
      nil
      nil
      "help"
      "Original on-screen name in ISO5 character set"
      nil
      nil
      ))
    (ISO7NAME (
      nil  ;;; no guide available
      nil
      nil
      "help"
      "Original on-screen name in ISO7 character set"
      nil
      nil
      ))
    (ISO2TITLE (
      nil  ;;; no guide available
      "<title>|<iso2-title>|(<attribute>)"
      nil
      "original-titles"
      "Original on-screen movie title in ISO2 character set"
      nil
      nil
      ))
    (ISO5TITLE (
      nil  ;;; no guide available
      "<title>|<iso5-title>|(<attribute>)"
      nil
      "original-titles"
      "Original on-screen movie title in ISO5 character set"
      nil
      nil
      ))
    (ISO7TITLE (
      nil  ;;; no guide available
      "<title>|<iso7-title>|(<attribute>)"
      nil
      "original-titles"
      "Original on-screen movie title in ISO7 character set"
      nil
      nil
      ))
    (KEYWORD (
      keywords  ;; v1.5
      "<title>|<keyword>"
      "Almost Famous (2000)|based-on-true-story"
      "keywords"
      "Categorizing or describing keywords for a movie 
which are not a main genre"
      nil
      nil
      ))
    (LAB (
      technical  ;; v1.5
      "<title>|<laboratory, city, country>|"
      "2001: A Space Odyssey (1968)|Technicolor, UK|"
      "technical"
      "Laboratory where the movie was developed"
      nil
      nil
      ))
    (LANGUAGE (
      language  ;; v1.5
      "<title>|<language-spoken>|*(<attribute>)|*<order>"
      "2001: A Space Odyssey (1968)|English"
      "languages"
      "Language(s) spoken in the movie"
      nil
      nil
      ))
    (LASERDISC (
      laserdisc  ;; v1.5
      (imdb-adds-display-help "LASERDISC")
      (imdb-adds-display-example "LASERDISC")
      "laserdiscs"
      "Details about available laserdiscs"
      nil
      nil
      ))
    (LITERATURE (
      literature  ;; v1.5
      (imdb-adds-display-help "LITERATURE")
      (imdb-adds-display-example "LITERATURE")
      "literature"
      "Corrections and replacements for details about available literature such as the original literary sources, screenplays, production protocols etc"
      nil
      nil
      ))
    (LITERATURENEW (
      literature  ;; v1.5
      (imdb-adds-display-help "LITERATURENEW")
      "Felsen, Der (2002)|ESSY|Greiner, Ariane|Nirgendwo auf Korsika|In: arte TV Magazin|ARTE G.E.I.E.|Germany||2|February 2004||Magazine|8-9|1288-3263"
      "literature"
      "New details about available literature such as the original 
literary sources, screenplays, production protocols etc"
      nil
      nil
      ))
    (LOCATION (
      locations  ;; v1.5
      "<title>|<location, city, country>|*<attribute>|*<order>"
      "Jurassic Park (1993)|Kauai, Hawaii, USA"
      "locations"
;;      "Real world shooting locations except from studios" (old ruleset)
      "Real world shooting locations including studios"
      nil
      nil
      ))
    (LOCATIONCORRECT (
      locations
      "wrong-location|correct-location"
      "Rome, Italy|Rome, Lazio, Italy"
      "locations"
      "Corrections to the IMDb location tree. All occurences will be corrected"
      nil
      nil
      ))
    (MALE (
      nil  ;;; no guide vailable
      "<name>|"
      "Aaltoila, Heikki|"
      nil
      "Swap the gender of a male falsely listed 
in the actresses list"
      nil
      nil
      ))
    (MAKEUP (
      make_up_department
      "<name>|<title>|(<attribute>)|"
      "Abbott, Pat|Cowboys, The (1972)|(hair stylist) (as Patricia Abbott)"
      "make-up-department"
      "Any make-up or hair person, as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (METRES (
      technical  ;; v1.5
      "<title>|<film-length>|(<attribute>)"
      "2001: A Space Odyssey (1968)|4064 m|(35 mm, Germany)"
      "technical"
      "Length of the movie"
      nil
      nil
      ))
    (MISC (
      miscellaneous  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Abdul, Paula|American Beauty (1999)|(choreographer)"
      "misc-crew"
      "Any screen credit not fitting under 
another submission keyword"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (MIX (
      sound_mix  ;; v1.5
      "<title>|<type-of-soundmix>|(<attribute>)"
      "102 Dalmatians (2000)|Dolby Digital"
      "sound-mix"
      "Sound format(s) the movie is available in 
such as DTS, SDDS, mono etc."
      nil
      nil
      ))
    (MOVIELINK (
     movie_links  ;; v1.5
     ;; reason/description is v1.5 additions stuff
     "<title>|<type-of-link>|<title>|reason/description"
     "Natural Born Killers (1994)|features|\"77 Sunset Strip\" (1958/I)"
     "movie-connections"
     "Movie connections such as if a movie references,
spoofs or features another movie"
     nil
      nil
     ))
    (NAKA (
       naka  ;; v1.5
       "<name>|<aka-name>"
       "Zsigmond, Vilmos|Zsigmond, William"
       "aka-names"
       "Alternative names used on-screen, 
but no real names not being used professionally"
       nil
      nil
       ))
    (NAME (
      name_formats  ;; v1.5
      "<new-name>|"
      "Lambert, Stephen (II)|"
      nil
      "Any name not previously known to IMDb must 
be 'registered' at first"
      nil
      nil
      ))
    (NAMECORRECT (
      name_correct  ;; v1.5
      ;; reason/description is v1.5 additions stuff
      "<name>|<corrected name>|<reason>"
      "Coppola, Francis|Coppola, Francis Ford"
      nil
      "Correction of an existing name falsely listed in the IMDb. This will correct the name at all. For section specific name correction, please use NAMECORRECT- as a keyword prefix"
      nil
      nil
      ))
    (NAMECORRECTAS (
      name_correct  ;; v1.5
      "<current name>|<current primary IMDb name>|<reason>"
      "Coppola, Francis|Coppola, Francis Ford"
      nil
      "Correction for an existing name falsely listed 
under an alternative name with the corrected 
version of the name being put into an (as ...) comment.
Coppola, Francis|Gardens of Stone (1987)|      becomes
Coppola, Francis Ford|Gardens of Stone (1987)|(as Francis Coppola)
This will correct the name at all. For section specific name correction, please use NAMECORRECTAS- as a keyword prefix"
      nil
      nil
      ))
    (NEGATIVE (
      technical  ;; v1.5
      "<title>|<print-format>|(<attribute>)"
      "2001: A Space Odyssey (1968)|65 mm|(spherical)"
      "technical"
      "Format of a movie's negative print"
      nil
      nil
      ))
    (OPENWEEK (
      business_ow  ;; v1.5
      "<title>|<currency>|<numeric>|<country>|<date>|(<screens>)|<attribute>|"
      "Hunt for Red October, The (1990)|GBP|25,000|France|15 October 1999|(265 screens)|"
      "business"
      "Opening week gross information (business data)"
      nil
      nil
      ))
    (ORDER (
      order  ;; v1.5
      "<name>|<title>|<billing order>"
      "Ford, Harrison|Blade Runner (1982)|1"
      "actors"
      "Screen credit order of an existing IMDb
actor or actress credit"
      nil
      nil
      ))
    (OUTLINE (
      outlines  ;; v1.5
      (imdb-adds-display-help "OUTLINE")
      (imdb-adds-display-example "OUTLINE")
      "outlines"
      "One or two lines outlining the movie plot"
      nil
      nil
      ))
    (PLOTS (
      plot  ;; v1.5
      (imdb-adds-display-help "PLOTS")
      (imdb-adds-display-example "PLOTS")
      "plots"
      "Ten or less lines describing a movie's plot 
without spoiling the end"
      nil
      nil
      ))
    (PRINTS (
      technical  ;; v1.5
      "<title>|<print-format>|(<attribute>)"
      "True Lies (1994)|35 mm|(anamorphic)"
      "technical"
      "Format(s) in which a movie has been printed 
except from the negative"
      nil
      nil
      ))
    (PROCESS (
      technical  ;; v1.5
      "<title>|<process>|(<attribute>)"
      "2001: A Space Odyssey (1968)|Super Panavision 70|"
      "technical"
      "Technical process such as Cinemascope or Betacam SP"
      nil
      nil
      ))
    (PRODCO (
      production_companies  ;; v1.5
      "<title>|<company-name> [country-tag]|*(<attribute>)|*<billing-order>|"
      "Jurassic Park (1993)|Universal Pictures [us]||1"
      "prod-companies"
      "All production companies involved in making a movie"
       "<title>|<company>|(<attribute>)|<order>|(<new attr.>)|<explanation>|"
      "<new title>|<new company>|(<new attribute>)|<new order>|<explanation>|"
      ))
    (PRODDATES (
      business_pd  ;; v1.5
      "<title>|<startdate>|<enddate>|<attribute>|<order>|"
      "Hunt for Red October, The (1990)|11 April 1991|9 August 1991|"
      "business"
      "Production dates, includes pre- and postproduction (business data)"
      nil
      nil
      ))
    (PRODUCER (
      producers  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Astaire, Fred|Second Chorus (1940)|(associate producer) (uncredited)"
      "producers"
      "All producers including the exact type of job they did, 
as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (PRODUCTIONMANAGER (
      production_managers  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Binyon Jr., Claude|Westworld (1973)|(unit production manager)"
      "production-managers"
      "All production and unit managers, as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (QUOTE (
      quotes  ;; v1.5
      (imdb-adds-display-help "QUOTE")
      (imdb-adds-display-example "QUOTE")
      "quotes"
      "Memorable or funny quotes from a movie"
      nil
      nil
      ))
    (RATIO (
      technical  ;; v1.5
      "<title>|<print-ratio>|(<attribute>)"
      "2001: A Space Odyssey (1968)|2.35 : 1|(35 mm prints)"
      "technical"
      "The aspect ratio of a movie's print(s)"
      nil
      nil
      ))
    (RELEASE (
      release_dates  ;; v1.5
      "<title>|<country>|<release-date>|(<attribute)>)"
      "Scratch-As-Catch-Can (1931)|USA|6 November 1931"
      "release-dates"
      "The release date of a movie with country information"
      nil
      nil
      ))
    (RENTALS (
      business_rt  ;; v1.5
      "<title>|<currency>|<numeric>|<country>|<attribute>|"
      "Hunt for Red October, The (1990)|ARS|2,000|India|"
      "business"
      "Rentals data (business data)"
      nil
      nil
      ))
    (RUSSIANNAME (
      russian  ;; v1.5
      nil
      nil
      "help"
      "Original name in Russian language"
      nil
      nil
      ))
    (RUSSIANTITLE (
      russian  ;; v1.5
      "<title>|<russian-title>|(<attribute>)"
      nil
      "original-titles"
      "Original on-screen movie title in Russian language"
      nil
      nil
      ))
    (SETDECORATOR (
      set_decorators  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Alcorn, Sarah|Amityville: Dollhouse (1996) (V)|(as Sarah Brooks Alcorn)"
      "set-decorators"
      "Set decorators (lead person(s)), as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (SFXCO (
      special_effects_companies  ;; v1.5
      "<title>|<company-name> [country-tag]|*(<credit>)|*<order>|"
      "Armageddon (1998)|Hunter Gratzner Industries, Inc.|(model maker)"
      "sfx-companies"
      "Special and visual effects companies 
including their on-screen credit if specified"
      "<title>|<company>|(<credit>)|<order>|(<new credit>)|<explanation>|"
      "<new title>|<new company>|(<new credit>)|<new order>|<explanation>|"
      ))
    (SHOOTDATES (
      business_sd  ;; v1.5
      "<title>|<startdate>|<enddate>|<attribute>|<order>|"
      "Hunt for Red October, The (1990)|11 April 1991|9 August 1991|"
      "business"
      "Shooting dates, excludes pre- and postproduction (business data)"
      nil
      nil
      ))
    (SOUNDDEPARTMENT (
      sound_department  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Adair, Deb|\"Buffy the Vampire Slayer\" (1997)|(foley mixer)"
      "sound-department"
      "All sound related on-screen credits"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (SOUNDTRACK (
      soundtracks  ;; v1.5
      (imdb-adds-display-help "SOUNDTRACK")
      (imdb-adds-display-example "SOUNDTRACK")
      "soundtracks"
      "The soundtrack information as it appears on-screen"
      nil
      nil
      ))
    (SPECIALEFFECTSDEPARTMENT (
      special_effects_department  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Aldridge, William (II)|Liar Liar (1997)|(special effects: second unit)"
      "special-effects-department"
      "All special effects credits, but no visual effects, 
as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (STUNTS (
      stunts  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Aiello III, Danny|Coyote Ugly (2000)|(stunt co-ordinator)"
      "stunts"
      "All stunt related on-screen credits"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (TAG (
      taglines  ;; v1.5
      (imdb-adds-display-help "TAG")
      (imdb-adds-display-example "TAG")
      "tag-lines"
      "Promotional tag line(s) for a movie, 
e.g. 'The Weirdest Film You Ever Saw!"
      nil
      nil
      ))
    (TIME (
      running_times
      "<title>|<country>|<running-time>|(<attribute)>"
      "Hard Boiled Egg (2000)|USA|3|(Chicago Children's Film Festival)"
      "running-times"
      "Running length in minutes with country information"
      nil
      nil
      ))
    (TITLE (
      movies
      "<title>|<year>|(<comment>)"
      "Don Camillo VI (1970)|1970|(unfinished)"
      "original-titles"
      "New movie or TV titles as seen on-screen 
with year of first release"
      nil
      nil
      ))
    (TITLE-ATTRIBUTE (
      movies
      "<title>|(<attribute>)|<explanation>"
      "Ciudad sagrada, La (1959)|(unreleased)|Never released"
      "original-titles"
      "Add attribute(s) to an existing IMDb movie or TV title"
      nil
      nil
      ))
    (TITLECORRECT (
      movies
      "<title>|<corrected title>"
      "Power of Kangwon Province, The (1998)|Kangwon-du ui him (1998)"
      "original-titles"
      "Correction of falsely spelled or false primary 
on-screen movie titles"
      nil
      nil
      ))
    (TITLEYEARS (
      movies
      "<title>|<corrected year range>"
      "\"Muwie\" (1992)|1992-2004|"
      "original-titles"
      "Correction of a TV series' year range"
      nil
      nil
      ))
    (TRIVIA (
      trivia  ;; v1.5
      (imdb-adds-display-help "TRIVIA")
      (imdb-adds-display-example "TRIVIA")
      "trivia"
      "Trivia and behind the scenes information for a movie"
      nil
      nil
      ))
    (URLNAME (
      urls  ;; v1.5
      (imdb-adds-display-help "URLNAME")
      "Wenders, Wim|OFF|http://www.wim-wenders.com|Official Home Page"
      "title-urls"
      "Working WWW hyperlink for a person listed in the IMDb
which may link to images, official home pages etc."
      nil
      nil
      ))
    (URLTITLE (
      urls  ;; v1.5
      (imdb-adds-display-help "URLTITLE")
      "Gohbi and God (2000)|OFF|http://www.gohbiandgod.com/|Official Site"
      "title-urls"
      "Working WWW hyperlink for a movie listed in the IMDb
which may link to images, reviews, official home pages etc."
      nil
      nil
      ))
    (VERSIONS (
      alternate_versions  ;; v1.5
      (imdb-adds-display-help "VERSIONS")
      (imdb-adds-display-example "VERSIONS")
      "versions"
      "Decription of alternative version of a movie 
which differs from the original release"
      nil
      nil
      ))
    ;;; guide not yet published
    (VISUALEFFECTSDEPARTMENT (
      visual_effects_department  ;; v1.5
      "<name>|<title>|(<attribute>)|"
      "Abbas-Klahr, Jonathan|Mummy, The (1999)|(animatronic model designer)"
      "visual-effects-department"
      "All visual effects credits, but no special effects, 
as credited on-screen"
      "<name>|<title>|(<attribute>)|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<explanation>|"
      ))
    (WEEKGROSS (
      business_wg
      "<title>|<currency>|<numeric>|<country>|<date>|(<screens>)|<attribute>|"
      "Hunt for Red October, The (1990)|ALL|1,000|Andorra|15 May 1999|(100 screens)|"
      "business"
      "Weekly box office gross, not cummulative (business data)"
      nil
      nil
      ))
    (WRITER (
      writers  ;; v1.5
      "<name>|<title>|(<attribute>)|<billing-sequence>|"
      "Proust, Marcel|Temps retrouvé, Le (1999)|(novel)"
      "writers"
      "Writing on-screen credits"
      "<name>|<title>|(<attribute>)|<sequence>|(<new attribute>)|<explanation>|"
      "<new name>|<new title>|(<new attrib.>)|<new seq.>|<explanation>|"
      ))
    )
  "Syntax examples and e-mail addresses for the various IMDb keywords.")

(defun imdb-adds-browse-keyword-online-help (&optional help-page)
  "Load IMDb online additions guide into WWW browser.

This function connects to the Internet Movie Database's WWW server and
loads the additions guide for the current keyword.

The current IMDb submission keyword is the one the cursor
is on or below.

You may also open a locally saved additions guide by changing
the default value of `imdb-adds-mode-load-guides-local-extension'."
  (interactive)
  (let ((iad-p) (iad-key) (iad-key-val) (browser-string) (fq-filename))
    (save-excursion
      (if (eq help-page 'nil)
	(progn
          (beginning-of-line)
          (if (looking-at "[A-Z\-]+\n")
	    (forward-line) nil)
          (end-of-line)
          (imdb-adds-move-to-keyword "previous")
          (beginning-of-line)
          (setq iad-p (point))
          (end-of-line)
          (setq iad-key (buffer-substring iad-p (point)))
          (setq iad-key-val (nth 0
	    (nth 0 (assoc-default iad-key imdb-adds-keyword-alist 'string=)))))
	(setq iad-key-val help-page))
      (if (eq iad-key-val 'nil)
        (message "No on-line guide known for %s" iad-key)
	(if (eq imdb-adds-mode-load-guides-local-extension nil)
	  ;; fetch online help
 	  (browse-url (format "%s%s%s" imdb-adds-mode-www-server 
			    imdb-adds-mode-www-guides-path iad-key-val))
	  ;; fetch locally saved page
	  (progn
	    (setq browser-string (format "%s%s%s%s"
	       imdb-adds-mode-local-www-server 
	       imdb-adds-mode-local-www-guides-path iad-key-val 
	       imdb-adds-mode-load-guides-local-extension))
               (setq fq-filename (substring browser-string
		                   (+ 3 (string-match "://" browser-string))))
	    (if (eq (file-readable-p fq-filename) 't)
	      (browse-url (format "%s" browser-string))
	      (if (eq (y-or-n-p "No local help. Browse online? ") 't)
	     	(browse-url (format "%s%s%s" imdb-adds-mode-www-server 
		      imdb-adds-mode-www-guides-path iad-key-val))))))))))

(defun imdb-adds-browse-extended-help (extended-help-page)
  "Wrapper function to browse extended online help pages.

The function calls `imdb-adds-browse-keyword-online-help' with
an argument as to which online help page to open."
  (interactive "s")
  (unless (eq extended-help-page 'nil)
    (imdb-adds-browse-keyword-online-help extended-help-page)))

(defun imdb-adds-browse-iso ()
  "Wrapper function to browse accented/special characters online help."
  (interactive)
  (imdb-adds-browse-keyword-online-help "iso"))

(defun imdb-adds-browse-attributes ()
  "Wrapper function to browse attributes online help."
  (interactive)
  (imdb-adds-browse-keyword-online-help "attributes"))

(defun imdb-adds-browse-characters ()
  "Wrapper function to browse character names online help."
  (interactive)
  (imdb-adds-browse-keyword-online-help "characters"))

(defun imdb-adds-browse-iso-country ()
  "Wrapper function to browse country codes online help."
  (interactive)
  (imdb-adds-browse-keyword-online-help "iso_country"))

(defun imdb-adds-browse-order ()
  "Wrapper function to browse order/sequence numbers online help."
  (interactive)
  (imdb-adds-browse-keyword-online-help "order"))

(defun imdb-adds-browse-russian ()
  "Wrapper function to browse Russian names and titles online help."
  (interactive)
  (imdb-adds-browse-keyword-online-help "russian"))

(defun imdb-adds-show-keyword-syntax ()
  "Display formal description of keyword submission syntax.

The function will display a formal syntax description for the current
keyword. If the current keyword has a simple single line syntax, the
description will be displayed in the mini-buffer, descriptions for
multi-line keywords and more complex single line keywords will be 
displayed in another buffer.

The current IMDb submission keyword is the one the cursor
is on or below."
  (interactive)
  (let ((iad-p) (iad-q) (iad-r) (iad-key) (iad-key-lookup) (gofor)
	(iad-key-val) (prefix))
    (save-excursion
      (beginning-of-line)
      (if (looking-at "[A-Z\-]+\n")
	 (forward-line) nil)
      (end-of-line)
      (imdb-adds-move-to-keyword "previous")
      (beginning-of-line)
      ;;; Fetch prefixed keywords
      (cond ((looking-at "CORRECT-")
	      (setq iad-key-val "Please use free-form text for the correction"))
            ((looking-at "COMMENT-")
	      (setq iad-key-val "Please use free-form text for the comment"))
            ((looking-at "NAMECORRECT-")
	      (setq iad-key-val
		"<current name>|<corrected name> [current name to be deleted]"))
            ((looking-at "NAMECORRECTAS-")
	      (setq iad-key-val
		"<current name>|<correct IMDb name> [current name to be attributed]"))
            ((looking-at "ATTRIBUTE-")
	      (setq prefix "ATTRIBUTE-")
	      (forward-char 10))
            ((looking-at "REPLACE-")
     	      (setq prefix "REPLACE-")
	      (forward-char 8))
	    (t))
      (setq iad-p (point))
      (end-of-line)
      (setq iad-key-lookup (buffer-substring iad-p (point)))
      (unless (eq prefix 'nil)
	(setq iad-key (concat prefix iad-key-lookup)))
      ;;; Now lookup help string if not already preset above
      (if (eq iad-key-val 'nil)
        ;;; Handle attribute case
	(cond ((string= prefix "ATTRIBUTE-")
          ;; Get attribute syntax from imdb-adds-keyword-alist
	  (setq iad-key-val 
            (nth 5 (nth 0 (assoc-default iad-key-lookup
			     imdb-adds-keyword-alist 'string=)))))
          ;; Get kw syntax *and* replace syntax from imdb-adds-keyword-alist
	  ;; This can get too long for minibuffer, we need to check
          ((string= prefix "REPLACE-")
   	    (setq iad-key-val (concat
              (nth 1 (nth 0 (assoc-default iad-key-lookup
			      imdb-adds-keyword-alist 'string=)))
              (nth 6 (nth 0 (assoc-default iad-key-lookup
			      imdb-adds-keyword-alist 'string=))))))
	  ;; Get kw syntax from imdb-adds-keyword-alist
	  (t
 	    (setq iad-key-val 
              (nth 1 (nth 0 (assoc-default iad-key-lookup
			      imdb-adds-keyword-alist 'string=)))))))
        ;;; Now display what was found in imdb-adds-keyword-alist
        (cond ((eq iad-key-val 'nil)
	        ;; No help message at all
	        (message "No syntax description for %s" iad-key))
	  ;; Help message is string and fits into minibuffer
	  ((and (eq (type-of iad-key-val) 'string) (< (length iad-key-val) 80))
	    (message "%s" iad-key-val))
  	  ;; Help message is string and doesn't fit into minibuffer
	  ;; from Emacs v21.1 onwards: function display-message-or-buffer
	  ((eq (type-of iad-key-val) 'string)
 	    (progn
	      (setq iad-r (point))
	      (setq iad-p (selected-window))
	      (if (eq (get-buffer-window "* IMDb adds help *") nil)
	        (progn
		  (get-buffer-create "* IMDb adds help *")
		  (setq iad-q (split-window iad-p (- (window-height) 6)))
		  (select-window iad-q)
		  (set-window-buffer iad-q "* IMDb adds help *"))
	        (select-window (get-buffer-window "* IMDb adds help *")))
	      (if (string= (buffer-name) "* IMDb adds help *")
	        (erase-buffer) nil)
	      (imdb-adds-mode)
	      (insert iad-key)
	      (insert "\n")
	      (insert iad-key-val)
	      (insert "\n\n")
  	      (goto-char (point-min))
	      (select-window iad-p)
	      (goto-char iad-r)
              (message
	       "Type C-x 1 to remove help window. M-C-v to scroll the help.")))
	  ;; Help message is a function to eval
	  (t (eval iad-key-val)))
	)))

(defun imdb-adds-show-keyword-example ()
  "Display an example of keyword submission syntax.

The function will display a syntax example for the current keyword.
If the current keyword has single line syntax, the example will be
displayed in the mini-buffer, examples for multi-line keywords will
be displayed in another buffer.

The current IMDb submission keyword is the one the cursor
is on or below."
  (interactive)
  (let ((iad-p) (iad-key) (iad-key-val))
    (save-excursion
      (beginning-of-line)
      (if (looking-at "[A-Z\-]+\n")
	 (forward-line) nil)
      (end-of-line)
      (imdb-adds-move-to-keyword "previous")
      (beginning-of-line)
      (setq iad-p (point))
      (end-of-line)
      (setq iad-key (buffer-substring iad-p (point)))
      (setq iad-key-val 
        (nth 2
	     (nth 0 (assoc-default iad-key imdb-adds-keyword-alist 'string=))))
      (if (eq iad-key-val 'nil)
	  (message "No example for %s" iad-key)
	(if (eq (type-of iad-key-val) 'string)      
	    (message "%s" iad-key-val)
	  (eval iad-key-val))))))

(defun imdb-adds-keyword-full-help ()
  "Show all available help for a given IMDb submission keyword.

The function asks for an IMDb submission keyword to enter and
displays all available information about it in an extra window."
  (interactive)
  (let ((iad-p) (iad-q) (iad-r) (iad-key) (iad-kw) (iad-desc)
	(iad-syntax) (iad-example) (iad-attrib) (iad-repl) (iad-url) (iad-mail)
	(keyword-count) (keyword-index) (num 0))
    (setq iad-r (point))

    ;;; ask for a keyword, but assume current one
    ;;; (check for keyword first in order we ever extend this function
    ;;; to take a keyword as given parameter)
    (if (eq iad-kw 'nil)
      (progn
        (beginning-of-line)
        (if (looking-at "[A-Z\-]+\n")
	  (forward-line) nil)
        (end-of-line)
        (imdb-adds-move-to-keyword "previous")
        (beginning-of-line)
        (setq iad-q (point))
        (end-of-line)
        (setq iad-key (buffer-substring iad-q (point)))
	(setq iad-kw "")
	(while (string= iad-kw "")
	  (setq iad-kw
	    (upcase (read-from-minibuffer
		       "Enter an IMDb submission keyword: " iad-key))))) nil)
    ;;; look up keyword in keyword-alist and fetch help data
    (cond ((string-match "ATTRIBUTE-" iad-kw)
              (setq iad-kw (substring iad-kw 10)))
      ((string-match "REPLACE-" iad-kw)
        (setq iad-kw (substring iad-kw 8)))
      (t))
    (setq keyword-count (safe-length imdb-adds-keyword-alist))
    (while (< num keyword-count)
      (if (string= iad-kw
		   (prin1-to-string (car (nth num imdb-adds-keyword-alist))))
	  (setq keyword-index num) nil)
      (setq num (1+ num)))
    (if (eq keyword-index 'nil)
	(message (concat iad-kw " not found in keyword list"))
      (progn
	(setq iad-kw
	  (prin1-to-string (car (nth keyword-index imdb-adds-keyword-alist))))
        (setq iad-desc
	  (nth 4 (nth 0
	    (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
        (setq iad-syntax
	  (nth 1 (nth 0
	    (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
        (setq iad-example
	  (nth 2 (nth 0
	    (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
        (setq iad-url
	  (nth 0 (nth 0
	    (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
	(setq iad-mail
	  (nth 3 (nth 0
	    (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
	(setq iad-attrib
	  (nth 5 (nth 0
	    (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
	(setq iad-repl
	  (nth 6 (nth 0
	    (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
        (setq iad-p (selected-window))

        ;;; display what was found in a help window
        (if (eq (get-buffer-window "* IMDb adds help *") nil)
	    (progn
	      (get-buffer-create "* IMDb adds help *")
	      (setq iad-q (split-window iad-p))
	      (select-window iad-q)
	      (set-window-buffer iad-q "* IMDb adds help *"))
          (select-window (get-buffer-window "* IMDb adds help *")))
        (if (string= (buffer-name) "* IMDb adds help *")
	    (erase-buffer) nil)
	(insert (concat iad-kw "\n\n"))
	(insert "Short description\n=================\n")
	(insert (concat iad-desc "\n\n"))
	(insert "Formal syntax\n=============\n")
        (if (eq iad-syntax 'nil)
	    (insert (concat "No syntax for " iad-kw "\n\n"))
	  (if (eq (type-of iad-syntax) 'string)
	      (insert (concat iad-kw "\n" iad-syntax "\n\n"))
            (imdb-adds-display-help iad-kw t)))
	(insert "Example with real data\n======================\n")
        (if (eq iad-example 'nil)
	    (insert (concat "No example for " iad-kw "\n\n"))
	  (if (eq (type-of iad-example) 'string)
	      (insert (concat iad-kw "\n" iad-example "\n\n"))
	    (imdb-adds-display-example iad-kw t)))
	(insert "Attribute syntax\n================\n")
        (if (eq iad-attrib 'nil)
	    (insert (concat iad-kw " takes no attribute syntax\n\n"))
	  (if (eq (type-of iad-attrib) 'string)
	      (insert (concat "ATTRIBUTE-" iad-kw "\n" iad-attrib "\n\n"))
	    ;;; this will not work w/o additional parameter, but
	    ;;; currently there are no multiline attribute examples
            (imdb-adds-display-help iad-kw t)))
	(insert "Replace syntax\n==============\n")
        (if (eq iad-repl 'nil)
	    (insert (concat iad-kw " takes no replace syntax\n\n\n"))
	  (if (eq (type-of iad-repl) 'string)
	      (progn
	        (setq iad-repl (concat iad-syntax iad-repl))
	        (insert (concat "REPLACE-" iad-kw "\n" iad-repl "\n\n\n")))
	    ;;; this will not work w/o additional parameter, but
	    ;;; currently there are no multiline replace examples
            (imdb-adds-display-help iad-kw t)))
	(insert "A full on-line guide can be found at\n")
	(insert "====================================\n")
        (if (eq iad-url 'nil)
	    (insert (concat "No on-line guide known for " iad-kw "\n\n"))
	  ;; hard coded path here, because the variables
	  ;; can be replaced with local settings
	  (insert (concat "http://www.imdb.com/updates/guide/"
			  (prin1-to-string iad-url) "\n\n")))
	(insert "Keyword specific problems/questions to\n")
        (insert "(Please don't use for submissions)\n")
        (insert "======================================\n")
        (if (eq iad-mail 'nil)
	    (insert (concat "No maintainer e-mail address for " iad-kw "\n\n"))
	  (insert (concat iad-mail "@" imdb-adds-mail-domain "\n\n")))
	(imdb-adds-mode)
        (goto-char (point-min))
	(select-window iad-p)
        (message "Type C-x 1 to remove help window. M-C-v to scroll the help.")))
    (goto-char iad-r)))

(defun imdb-adds-show-all-keywords ()
  "Show all existing keywords with a short description."
  (interactive)
  (let ((iad-p) (iad-q) (iad-r) (iad-kw) (iad-desc) (keyword-count) (num 0))
    (setq iad-r (point))

    ;;; display a help window
    (setq iad-p (selected-window))
    (if (eq (get-buffer-window "* IMDb adds help *") nil)
	(progn
	  (get-buffer-create "* IMDb adds help *")
	  (setq iad-q (split-window iad-p))
	  (select-window iad-q)
	  (set-window-buffer iad-q "* IMDb adds help *"))
      (select-window (get-buffer-window "* IMDb adds help *")))
    (if (string= (buffer-name) "* IMDb adds help *")
	(erase-buffer) nil)

    ;;; get all keywords with their descriptions
    (setq keyword-count (safe-length imdb-adds-keyword-alist))
    (while (< num keyword-count)
      (progn
	(setq iad-kw (prin1-to-string (car (nth num imdb-adds-keyword-alist))))
	(setq iad-desc
	      (nth 4 (nth 0
		(assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
	(insert (concat iad-kw "\n"))
	(insert (concat iad-desc "\n\n"))
        (setq num (1+ num))))
    (imdb-adds-mode)
    (goto-char (point-min))
    (select-window iad-p)
    (goto-char iad-r)
    (message "Type C-x 1 to remove help window. M-C-v to scroll the help.")
    ))

(defun imdb-adds-mail-to-maintainer ()
  "Address submission problems to the IMDb.

By calling this function, you will be given the opportunity
to connect to the IMDb online support in several ways.

Please note that due to massive abuse and spam it is not
longer possible to contact the IMDb data managers directly
via e-mail."
  (interactive)
  (let ( (iad-p) (iad-r) (iad-q) (www-option "") (www-url))
  (save-excursion
    (if (eq (y-or-n-p "E-mail support phased out. Browse online support? ") 't)
      (progn
        (setq iad-r (point))
        (setq iad-p (selected-window))
        (if (eq (get-buffer-window "* IMDb adds help *") nil)
          (progn
            (get-buffer-create "* IMDb adds help *")
  	    (setq iad-q (split-window iad-p (- (window-height) 7)))
	    (select-window iad-q)
	    (set-window-buffer iad-q "* IMDb adds help *"))
          (select-window (get-buffer-window "* IMDb adds help *")))
        (if (string= (buffer-name) "* IMDb adds help *")
          (erase-buffer) nil)
        (insert "Submission related problems should preferably be posted on the\n")
        (insert "Contributors Help message board or via an online feedback form.\n\n")
        (insert "You may also start at the Contributors Zone, which provides\n")
        (insert "additional help and information for submitters.\n")
	(goto-char (point-min))
        (while (not (or (string= www-option "1") (string= www-option "2")
		  (string= www-option "3")))
        (setq www-option (read-from-minibuffer
          "Browse: [1] message board, [2] feedback form, [3] CZone: ")))
        (cond ((string= www-option "1")
          (setq www-url (concat imdb-adds-mode-www-server
				imdb-adds-mode-contrib-mboard-path)))
          ((string= www-option "2")
            (setq www-url (concat imdb-adds-mode-www-server
				  imdb-adds-mode-feedback-path)))
          ((string= www-option "3")
	    (progn
              (unless (string= imdb-adds-mode-www-server "http://www.imdb.com/")
		(setq imdb-adds-mode-www-server "http://www.imdb.com/"))
              (setq www-url (concat imdb-adds-mode-www-server
				    imdb-adds-mode-czone-path)))))
	(browse-url www-url)
        (select-window iad-p)
	(goto-char iad-r)) nil))))
	      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Definition of functions for moving around
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun imdb-adds-move-to-keyword (direction)
  "Function to move to previous/next IMDb additions keyword."
  (interactive "s")
  (let ((keyword (concat "^\\(" imdb-adds-mode-keywords-base 
	  "\\)$\\|^\\(" imdb-adds-mode-keywords-other "\\)$\\|^CO\\|^ATTRIBUTE\\|^REPLACE\\|^NAMECORRECT"))
        (case-fold-search nil))
    (progn
      (if (string= direction 'next)
	  ;;; search forward for keyword...
	  (progn
	    (end-of-line)
	    (re-search-forward keyword nil t)) nil)
      (if (string= direction 'previous)
	  ;;; search backwards for keyword...
	  (progn
	    (beginning-of-line)
	    (re-search-backward keyword nil t)) nil)
      (end-of-line))))

;;; Wrapper function to call imdb-adds-move-to-keyword
(defun imdb-adds-move-to-previous-keyword ()
  "Move to previous IMDb additions keyword."
  (interactive)
  (imdb-adds-move-to-keyword "previous"))

;;; Wrapper function to call imdb-adds-move-to-keyword
(defun imdb-adds-move-to-next-keyword ()
  "Move to next IMDb additions keyword."
  (interactive)
  (imdb-adds-move-to-keyword "next"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Definition of functions for editing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun imdb-adds-copy-data-field (direction)
  "Copy the content of current data field from previous/next line.

This function evaluates the current data field on the current line
and then copies the contents of the same field from the previous
or next line.

Example:

Children of Artsakh (1999)|Short

becomes

Children of Artsakh (1999)|Short
Children of Artsakh (1999)|


\"Rote Quadrat, Das\" (2000)|Germany|45|(3 episodes)
\"Apokalypse Vietnam\" (2000)|Germany|

becomes

\"Rote Quadrat, Das\" (2000)|Germany|45|(3 episodes)
\"Apokalypse Vietnam\" (2000)|Germany|45|"
  (interactive "s")
  (let ((iad-p) (iad-q) (iad-r) (iad-field) (iad-overwrite)
	(iad-copy-condition) (iad-insert-separator))
    (save-excursion
      ;;; first evaluate current field
      (setq iad-p (point))
      (unless (string= (char-to-string (following-char)) (bolp))
	(setq iad-overwrite t))
      (beginning-of-line)
      (setq iad-q (point))
      (goto-char iad-p)
      (setq iad-field 1)
      (while (re-search-backward "\|" iad-q t)
	(setq iad-field (+ 1 iad-field)))
      ;;; now get same field on previous or next line
      (if (string= direction 'next)
        (forward-line 1)
        (forward-line -1))
      (end-of-line)
      (setq iad-q (point))
      (beginning-of-line)
      ;;; check whether previous/next line has tag syntax at all
      ;;; valid number of fields
      (setq iad-r 0)
      (while (re-search-forward "\|" iad-q t)
	(setq iad-r (+ 1 iad-r)))
      (cond ((eq iad-r '0)
 	     (message "No valid syntax found on %s line" direction))
            ;;; handle special case when last field on previous/next line
            ;;; is valid, but not terminated by field separator '|'
            ((eq iad-r (- iad-field 1))
             (progn
               (beginning-of-line)
    	       (re-search-forward "\|" iad-q t (- iad-field 1))
               (if (eolp)
                 (message "Not enough data fields on %s line" direction)
  	         (setq iad-copy-condition t))))
            ((>= iad-r iad-field)
	      (setq iad-copy-condition t))
            ((< iad-r iad-field)
                 (message "Not enough data fields on %s line" direction))
            (t 
              (message "Unknown condition (%s) (%s)" iad-field iad-r)))
      (if iad-copy-condition
        (progn
          (beginning-of-line)
	  (re-search-forward "\|\\|$" iad-q t iad-field)
          (if (string= (char-to-string (preceding-char)) "|")
	   (progn
	     (forward-char -1)
	     (setq iad-insert-separator t)) nil)
	  (setq iad-r (point))
	  (if (eq iad-field '1)
	    (beginning-of-line)
	    (progn
	      (re-search-backward "\|" nil t)
	      (forward-char 1)))
	  (kill-new (buffer-substring (point) iad-r))
	  ;;; go back and insert data
	  (goto-char iad-p)
;;          (setq iad-r (point-marker))
	  (yank)
	  (if (eq iad-insert-separator 't)
	    (insert "|") nil)
	  ;;; move cursor behind inserted data
          (setq iad-p (point)))))
      (goto-char iad-p)))

;;; Wrapper function to call imdb-adds-move-to-keyword
(defun imdb-adds-copy-previous-data-field ()
  "Copy the content of current data field from previous line.

This function calls `imdb-adds-copy-data-field'."
  (interactive)
  (imdb-adds-copy-data-field "previous"))

;;; Wrapper function to call imdb-adds-move-to-keyword
(defun imdb-adds-copy-next-data-field ()
  "Copy the content of current data field from next line.

This function calls `imdb-adds-copy-data-field'."
  (interactive)
  (imdb-adds-copy-data-field "next"))

(defun imdb-adds-insert-comment-or-correct-for-keyword (prefix)
  "Insert COMMENT-, CORRECT- or or NAMECORRECT- for current or given keyword.

The function inserts a COMMENT-, CORRECT- or NAMECORRECT-
keyword below the current keyword. It is assumed that you 
want to insert it for the current keyword. However you will 
be prompted to enter any keyword.

Use this if you need to make comments or corrections in
free form text.

The current IMDb submission keyword is the one the cursor
is on or below."
  (interactive "*s")
  (let ((iad-p) (iad-q) (iad-key) (iad-key-val) (iad-prompt))
    (save-excursion
      (setq iad-p (point))
      (beginning-of-line)
      (if (looking-at "[A-Z\-]+\n")
	 (forward-line) nil)
      (end-of-line)
      (imdb-adds-move-to-keyword "previous")
      (beginning-of-line)
      (setq iad-q (point))
      (end-of-line)
      (setq iad-key (buffer-substring iad-q (point)))
      (setq iad-prompt (concat "Insert " prefix " for keyword: "))
      (setq iad-key-val "")
      (while (string= iad-key-val "")
        (setq iad-key-val
	  (upcase (read-from-minibuffer iad-prompt iad-key))))
      (cond
        ((string-match "\-" iad-key-val)
	  (message "%s already has a prefix" iad-key-val))
	((and (not
	       (string-match imdb-adds-mode-keywords-namecorrect iad-key-val))
	      ;; this may mismatch in one or two cases not set up,
	      ;; safer would be to set up a t/nil in imdb-adds-keyword-alist
	       (or (string= prefix "NAMECORRECT-")
		   (string= prefix "NAMECORRECTAS-")))
	  (message "Not a valid %s keyword: %s" prefix iad-key-val))
         ((string= prefix "ATTRIBUTE-")
	    ;; check whether this keyword has attribute syntax,
	    ;; only then add attribute prefix
            (if (eq (nth 5 (nth 0
	      (assoc-default iad-key-val
			     imdb-adds-keyword-alist 'string=))) 'nil)
	      	(message "Not a valid %s keyword: %s" prefix iad-key-val)
  	        (progn
                  (imdb-adds-move-to-keyword "next")
                  (forward-line -1)
                  (insert (concat "\n" prefix iad-key-val "\n\n"))
                  (forward-line -1)
                  (setq iad-p (point)))))
         ((string= prefix "REPLACE-")
	    ;; check whether this keyword has replace syntax,
	    ;; only then add replace prefix
            (if (eq (nth 6 (nth 0
	      (assoc-default iad-key-val
			     imdb-adds-keyword-alist 'string=))) 'nil)
	      	(message "Not a valid %s keyword: %s" prefix iad-key-val)
  	        (progn
                  (imdb-adds-move-to-keyword "next")
                  (forward-line -1)
                  (insert (concat "\n" prefix iad-key-val "\n\n"))
                  (forward-line -1)
                  (setq iad-p (point)))))
	;; default: non-prefix keyword
	(t 
	  (progn
            (imdb-adds-move-to-keyword "next")
            (forward-line -1)
            (insert (concat "\n" prefix iad-key-val "\n\n"))
            (forward-line -1)
            (setq iad-p (point))))))
    (goto-char iad-p)))

;;; wrapper function for imdb-adds-insert-comment-or-correct-for-keyword
(defun imdb-adds-insert-prefix-comment ()
  "Insert a COMMENT- for current or given keyword.

The function inserts a COMMENT-... below the current IMDb
submission keyword. You will be prompted for the keyword
to add this prefix for. By default the current keyword is
assumed.

The current IMDb submission keyword is the one the cursor
is on or below.

Example:

AKA
Baumfrau, Die (1999)|Tree Woman, The (1999)|(International: English title)

becomes

AKA
Baumfrau, Die (1999)|Tree Woman, The (1999)|(International: English title)

COMMENT-AKA"
  (interactive)
  (imdb-adds-insert-comment-or-correct-for-keyword "COMMENT-"))

;;; wrapper function for imdb-adds-insert-comment-or-correct-for-keyword
(defun imdb-adds-insert-prefix-correct ()
  "Insert a CORRECT- for current or given keyword.

The function inserts a CORRECT-... below the current IMDb
submission keyword. You will be prompted for the keyword
to add this prefix for. By default the current keyword is
assumed.

The current IMDb submission keyword is the one the cursor
is on or below.

Example:

PRODCO
Robochick (1993)|Amalgam [be]
Pan Loaf, The (1995)|Imagine Films [uk]

becomes

PRODCO
Robochick (1993)|Amalgam [be]
Pan Loaf, The (1995)|Imagine Films [uk]

CORRECT-PRODCO"
  (interactive)
  (imdb-adds-insert-comment-or-correct-for-keyword "CORRECT-"))

;;; wrapper function for imdb-adds-insert-comment-or-correct-for-keyword
(defun imdb-adds-insert-prefix-namecorrect ()
  "Insert a NAMECORRECT- for current or given keyword.

The function inserts a NAMECORRECT-... below the current 
IMDb submission keyword. You will be prompted for the keyword
to add this prefix for. By default the current keyword is
assumed.

The current IMDb submission keyword is the one the cursor
is on or below.

Example:

EDITOR
Tomasini, George|Psycho (1960)|

becomes

EDITOR
Tomasini, George|Psycho (1960)|

NAMECORRECT-EDITOR"
  (interactive)
  (imdb-adds-insert-comment-or-correct-for-keyword "NAMECORRECT-"))

;;; wrapper function for imdb-adds-insert-comment-or-correct-for-keyword
(defun imdb-adds-insert-prefix-namecorrectas ()
  "Insert a NAMECORRECTAS- for current or given keyword.

The function inserts a NAMECORRECTAS-... below the current 
IMDb submission keyword. You will be prompted for the keyword
to add this prefix for. By default the current keyword is
assumed.

The current IMDb submission keyword is the one the cursor
is on or below.

Example:

EDITOR
Tomasini, George|Psycho (1960)|

becomes

EDITOR
Tomasini, George|Psycho (1960)|

NAMECORRECTAS-EDITOR"
  (interactive)
  (imdb-adds-insert-comment-or-correct-for-keyword "NAMECORRECTAS-"))

;;; wrapper function for imdb-adds-insert-comment-or-correct-for-keyword
(defun imdb-adds-insert-prefix-replace ()
  "Insert a REPLACE- for current or given keyword.

The function inserts a REPLACE-... below the current 
IMDb submission keyword. You will be prompted for the keyword
to add this prefix for. By default the current keyword is
assumed.

The current IMDb submission keyword is the one the cursor
is on or below.

Example:

EDITOR
Tomasini, George|Psycho (1960)|

becomes

EDITOR
Tomasini, George|Psycho (1960)|

REPLACE-EDITOR"
  (interactive)
  (imdb-adds-insert-comment-or-correct-for-keyword "REPLACE-"))

;;; wrapper function for imdb-adds-insert-comment-or-correct-for-keyword
(defun imdb-adds-insert-prefix-attribute ()
  "Insert a ATTRIBUTE- for current or given keyword.

The function inserts a ATTRIBUTE-... below the current 
IMDb submission keyword. You will be prompted for the keyword
to add this prefix for. By default the current keyword is
assumed.

The current IMDb submission keyword is the one the cursor
is on or below.

Example:

EDITOR
Tomasini, George|Psycho (1960)|

becomes

EDITOR
Tomasini, George|Psycho (1960)|

ATTRIBUTE-EDITOR"
  (interactive)
  ;;; Check whether valid attribute keyword goes here
  (imdb-adds-insert-comment-or-correct-for-keyword "ATTRIBUTE-"))

(defun imdb-adds-entry-checked-as-accepted ()
  "Mark current line as accepted.

The function simply inserts the value of `imdb-adds-entry-okay' the
beginning of the current line to mark an entry as okay, i.e. it made
it into the database.

Use this if you want to check whether your previously sent-in
submissions were really accepted."
  (interactive)
  (beginning-of-line)
  (insert imdb-adds-entry-okay)
  (forward-line))

;;; BUG: 
;;; Anthony, Marc|Marc Anthony: The 
;;; => Anthony, Marc|Marc Anthony:  (I)The 
(defun imdb-adds-count-roman-numeral (incr)
  "Increase or decrease the current roman numeral indexed name.

The current name is considered to be the text in the current data
field if '\|' separators are found or the whole line if the line
appears to be preceeded by a tag such as 'NM: '.

This function makes use of `imdb-adds-roman-numerals-alist'. The actual
computation is done with arabic numbers."
  (interactive "*s")
  (let ((my-p) (my-q) (my-r) (skip-tag) (numeral) (kval))
    (save-excursion
      ;;; evaluate and store beginning of line
      (setq my-r (point))
      (beginning-of-line)
      (if (looking-at "^[#@]*..:")
	(setq skip-tag t) nil)
      (setq my-p (point))
      ;;; do the same for end of line
      (end-of-line)
      (setq my-q (point))
      ;;; evaluate name position
      (goto-char my-r)
      (if (or (bolp) (eq skip-tag 't))
	(progn
	  (beginning-of-line)
	  ;;; Does that really cover all tag cases with names?
          (search-forward "NM: " my-q t))
        (if (eq (search-backward "|" my-p t) 'nil)
	  (if (eq (search-backward ": " my-p t) nil)
	    (beginning-of-line) (forward-char 2))
	  (forward-char)))
      ;;; name starts here
      (setq my-p (point))
      (goto-char my-r)
      (if (eq (search-forward "|" my-q t) 'nil)
	(progn
	  (end-of-line)
          (search-backward "  (" my-p t))
	(backward-char))
      ;;; name ends here
      (setq my-q (point-marker))
    ;;; evaluation done, now for the action
    ;;; narrow to name (excluding comments)
    (save-restriction
      (narrow-to-region my-p my-q)
      (end-of-line)
      ;;; search for roman numerals
      (if (re-search-backward "([IVXL]+)" nil t)
	(progn
          ;;; if roman numeral get next/previous from alist
	  (setq numeral (buffer-substring (match-end 0) (match-beginning 0)))
	  (setq kval (+ incr (car (rassoc numeral imdb-adds-roman-numerals-alist))))
	  (setq numeral (cdr (assoc kval imdb-adds-roman-numerals-alist)))
          ;;; if no next/previous numeral we are at end/beginning of alist
          ;;; if we increase just inform, if we decrease, delete the ' (I)'
	  (if (eq numeral 'nil)
 	    (if (eq incr 1)
	      (message "End of `roman-numerals-alist'")
	      (progn
	        (replace-match "")
	        (delete-backward-char 1)))
	    (replace-match numeral)))
        ;;; if no roman numeral at all insert ' (I)' if we increase
        (if (eq incr 1)
            (insert " (I)")
            (message "Nothing to do..."))
)))))

(defun imdb-adds-increase-roman-numeral ()
  "Increase the current roman numeral indexed name.

Call the function several times to increase by more than one.

The function does not really know what a 'name' is in terms of
IMDb submission syntax. It does not check whether the current data
field is really a name. Thus please make sure the cursor is on a
name before you call it.

Example:

Evans, Peter|Saving Grace (2000)|(uncredited)|Alex

becomes

Evans, Peter (I)|Saving Grace (2000)|(uncredited)|Alex


NM: Evans, Peter (V)

becomes

NM: Evans, Peter (VI)

This function calls `imdb-adds-count-roman-numeral'."
  (interactive)
  (imdb-adds-count-roman-numeral 1))

(defun imdb-adds-decrease-roman-numeral ()
  "Decrease the current roman numeral indexed name.

Call the function several times to decrease by more than one.

The function does not really know what a 'name' is in terms of
IMDb submission syntax. It does not check whether the current data
field is really a name. Thus please make sure the cursor is on a
name before you call it.

Example:

Evans, Peter (III)|Saving Grace (2000)|(uncredited)|Alex

becomes

Evans, Peter (II)|Saving Grace (2000)|(uncredited)|Alex


NM: Evans, Peter (I)

becomes

NM: Evans, Peter

This function calls `imdb-adds-count-roman-numeral'."
  (interactive)
  (imdb-adds-count-roman-numeral -1))

(defun imdb-adds-swap-name-insert-comma (pos)
  "Swap given name and surname and insert a comma.

If you call this function without any argument, you must
enter the position to insert the comma at into the mini-buffer.

Enter '1' to divide after the name's first part.
  Philip Seymour Hoffman  =>  Seymour Hoffman, Philip

Enter '2' to divide after the name's second part.
  Philip Seymour Hoffman  =>  Hoffman, Philip Seymour

And so on..."
  (interactive "*N")
  (let ((my-p) (my-q) (my-r) (skip-tag))
    (save-excursion
      ;;; quick hack to solve Invalid search bound/wrong side of point 
      ;;; problem on certain lines, seems only to occur when point is
      ;;; bolp
      (if (bolp) (forward-char 1))
      ;;; evaluate and store beginning of line
      (setq my-r (point))
      (beginning-of-line)
      (if (looking-at "^[#@]*..:")
	(setq skip-tag t) nil)
      (setq my-p (point))
      ;;; do the same for end of line
      (end-of-line)
      (setq my-q (point))
      ;;; evaluate name position
      (goto-char my-r)
      (if (or (bolp) (eq skip-tag 't))
	(progn
	  (beginning-of-line)
          (search-forward ": " my-q t))
        (if (eq (search-backward "|" my-p t) 'nil)
	  (if (eq (search-backward ": " my-p t) nil)
	    (beginning-of-line) (forward-char 2))
	  (forward-char)))
      ;;; name starts here
      (setq my-p (point))
      (goto-char my-r)
      (if (eq (search-forward "|" my-q t) 'nil)
	(progn
	  (end-of-line)
          (search-backward "  (" my-p t))
	(backward-char))
      ;;; name ends here
      (setq my-q (point-marker))
      ;;; evaluation done, now for the action
      (goto-char my-p)
      (cond ((not (eq (search-forward "," my-q t) 'nil))
	      (message "Name already has a comma"))
            ((eq (search-forward " " my-q t pos) 'nil)
	      (message "Name has not enough parts"))
	    (t
  	      (progn
              (delete-char -1)
              (kill-new (buffer-substring my-p (point)))
              (delete-region my-p (point))
              (goto-char my-q)
              ;;; delete pending spaces at end of name
              (while (string= (char-to-string (preceding-char)) " ")
                (delete-backward-char 1))
              (insert ", ")
              (insert (car kill-ring-yank-pointer))))))))

(defun imdb-adds-swap-name-insert-comma-1-given-name ()
  "Swap one given name and surname(s) and insert a comma.

Use this function to insert a comma and swap 
name parts for names with one given name.
This will work on the whole line if there are no 
separators ('|') or a name tag ('NM:').

If you are going to swap a name on a line which is
in single line syntax and separated with '|', make
sure the cursor is on the name before you invoke
this function.

Examples:

Emile Abossolo M'bo|Joie de vivre, La (1993)||Arsene
=>
Abossolo M'bo, Emile|Joie de vivre, La (1993)||Arsene

or

NM: Nick Nolte  (performer)
=>
NM: Nolte, Nick  (performer)

or

Gwyneth Paltrow
=>
Paltrow, Gwyneth"
  (interactive)
  (imdb-adds-swap-name-insert-comma 1))

(defun imdb-adds-swap-name-insert-comma-2-given-names ()
  "Swap two given names and surname(s) and insert a comma.

Use this function to insert a comma and swap 
name parts for names with two given names.

Example:

Michael Clarke Duncan|Bulworth (1998)||Bouncer
=>
Duncan, Michael Clarke|Bulworth (1998)||Bouncer

Please see `imdb-adds-swap-name-insert-comma-1-given-name'
for a more complete explanation."
  (interactive)
  (imdb-adds-swap-name-insert-comma 2))

(defun imdb-adds-swap-name-insert-comma-3-given-names ()
  "Swap three given names and surname(s) and insert a comma.

Use this function to insert a comma and swap 
name parts for names with three given names.

Example:

Timothy 'TJ' James Driscoll
=>
Driscoll, Timothy 'TJ' James

Please see `imdb-adds-swap-name-insert-comma-1-given-name'
for a more complete explanation."
  (interactive)
  (imdb-adds-swap-name-insert-comma 3))

(defun imdb-adds-swap-name-insert-comma-4-given-names ()
  "Swap four given names and surname(s) and insert a comma.

Use this function to insert a comma and swap 
name parts for names with four given names.

Example:

Gilbert M. 'Broncho Billy' Anderson
=>
Anderson, Gilbert M. 'Broncho Billy'

Please see `imdb-adds-swap-name-insert-comma-1-given-name'
for a more complete explanation."
  (interactive)
  (imdb-adds-swap-name-insert-comma 4))

(defun imdb-adds-region-make-fulltext-hyperlink (beg end)
  "Make an IMDb fulltext hyperlink for the current region

The function will insert IMDb hyperlink delimiters around the
current region. If the current region contains a string
recognizable as year of a title, e.g. '(1992)' or '(????)',
title syntax will be used, in any other case name syntax
will be inserted.

Please use hyperlink syntax in comments and free-form text
additions like biographies, trivia, crazy-credits and soundtracks
only.

E.g.
CO: - For episode with host Roseanne.

=>
CO: - For episode with host 'Roseanne' (qv).

Please note that it is up to you to ensure the correct title
or name format is being used. This function will only put
the quotes around those."

  (interactive "*r")
  (let ((tlink) (nlink) (tl "_") (nl"\'") (bl " (qv)") (begol) (endol))
  (save-excursion
    (beginning-of-line)
    (setq begol (point))
    (end-of-line)
    (setq endol (point))
    (goto-char beg)
    (setq iam-p (point))
    (goto-char end)
    (setq iam-q (point))
    (if (or (< iam-p begol) (> iam-q endol))
      (message "IMDb hyperlinks cannot span multiple lines")
      (save-restriction
        (narrow-to-region iam-p iam-q)
        (goto-char (point-min))
        (if (re-search-forward "\(\\([12][890][0-9][0-9]\\|\\?\\?\\?\\?\\)\\(\\/[IVX]+\\)*\)" nil t)
	  (setq tlink 't) nil)
        (goto-char (point-max))
        (if (eq tlink 't)
	  (setq nlink tl)
	  (setq nlink nl))
        (insert nlink)
	(insert bl)
	(goto-char (point-min))
	(insert nlink))))))

(defun imdb-adds-make-new-template ()
  "Make a new template buffer for submissions.

This functions does the same as `imdb-adds-insert-new-template',
but makes a new buffer before inserting the new template."
  (interactive)
  (switch-to-buffer (generate-new-buffer-name "* IMDb submission file *"))
  (imdb-adds-insert-new-template))

(defun imdb-adds-insert-new-template ()
  "Make a new template buffer for submissions.

This function uses the IMDb keywords from 
`imdb-adds-additions-template-alist' to build 
a new submission template.

If you don't want to have the character set reminder 
to be inserted at the beginning of the file, please set 
the variable `imdb-adds-additions-template-reminder' to 'nil'.

If you have problems recalling the syntax of the IMDb 
submission keywords, you may switch on beginner mode by 
setting the variable `imdb-adds-beginner-mode' to 't'."
  (interactive)
  (let ((keyword-count) (num 0) (iad-kw) (iad-p) (iad-begin))

    ;;; insert character set reminder
    (unless (eq imdb-adds-additions-template-reminder 'nil)
      (insert imdb-adds-additions-template-reminder-text))

    ;;; find out which keywords to insert into template
    (setq keyword-count (safe-length imdb-adds-additions-template-alist))
    (while (<= num keyword-count)
      (unless (eq (cdr (nth num imdb-adds-additions-template-alist)) nil)
	(progn
	  (setq iad-kw (prin1-to-string
			(car (nth num imdb-adds-additions-template-alist))))

          ;;; check whether user wants beginner mode and if so insert
          ;;; syntax or example for every keyword
	  (if (eq imdb-adds-beginner-mode 't)
	    (progn
	      (if (eq imdb-adds-beginner-mode-use-examples 't)
                ;;; insert reminder to delete examples here

                ;;; user prefers examples over formal syntax
		(progn
		  (setq iad-p
		    (nth 2 (nth 0
		      (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
		  (if (eq iad-p 'nil)
		    (setq iad-begin
		      (concat iad-kw "\nNo example available.\n\n\n"))
		    (if (eq (type-of iad-p) 'string)
		      (setq iad-begin (concat iad-kw "\n" iad-p "\n\n\n"))
		      (progn
			(kill-line -1)
		        (imdb-adds-display-example iad-kw t)
		        (insert "\n")))))
                ;;; user prefers formal syntax
		(progn
		  (setq iad-p
		    (nth 1 (nth 0
		      (assoc-default iad-kw imdb-adds-keyword-alist 'string=))))
		  (if (eq iad-p 'nil)
		    (setq iad-begin
		      (concat iad-kw
			      "\nNo syntax description available.\n\n\n"))
		    (if (eq (type-of iad-p) 'string)
		      (setq iad-begin (concat iad-kw "\n" iad-p "\n\n\n"))
		      (progn
			(kill-line -1)
		        (imdb-adds-display-help iad-kw t)
			(insert "\n"))))))
	      (unless (eq iad-begin 'nil)
		(insert iad-begin)))

            ;;; no beginner mode, just insert keywords
	    (progn
	      (insert iad-kw) 
	      (insert "\n\n\n")))))
        (setq num (1+ num) iad-kw nil iad-p nil iad-begin nil))

    ;;; insert the obligatory end-of-data keyword    
    (insert "END\n")
    (imdb-adds-mode)
    (goto-char (point-min))))

(defun imdb-adds-insert-sub-template ()
  "Make a sub-template for keywords which have multiline syntax.

This function will insert a sub-template for the current
IMDb submission keyword.

If the variable `imdb-adds-beginner-mode' is 't' 
syntax descriptions for multi-line keywords are 
being kept, otherwise only the blank tags (MV:, NM:) 
are used.

Please note that it is up to you to delete any formal
description or comments not being part of your data
and inserted by this function before you are going to
send the data to the IMDb mail server.

Example:

OUTLINE

becomes

OUTLINE

MV: 
PL: 
BY: 

and in beginner mode it would look like 

OUTLINE

MV: <title>
PL: <plot outline line 1>
BY: <your name> <your-mail-address>

=> (Please note: two PL: lines maximum)
=> (Please note: column width maximum is 78, then newline)
=>       1         2         3         4         5         6         7        <


While you just have to fill out the first example, you 
will have to delete the descriptions and comments from 
the second one (beginner mode) before you are going to 
send your additions to the IMDb mail server.
"
  (interactive)
  (let ((iad-p) (iad-q) (iad-r) (iad-key) (iad-key-val) (iad-key-lookup)
	(prefix) (iad-match) (iad-last-match) (kill-whole-line t)
	(case-fold-search nil))
    (setq iad-r (point))
    (save-excursion
      ;;; check for current keyword
      (if (eq iad-key 'nil)
	(progn
	  (beginning-of-line)
	  (if (looking-at "[A-Z\-]+\n")
	    (forward-line) nil)
	  (end-of-line)
	  (imdb-adds-move-to-keyword "previous")
	  (beginning-of-line)
          ;;; Fetch prefixed keywords
          (cond ((looking-at "CORRECT-")
	    (setq iad-key-val "[Please use free-form text for the correction]"))
            ((looking-at "COMMENT-")
	      (setq iad-key-val "[Please use free-form text for the comment]"))
            ((looking-at "NAMECORRECT-")
	      (setq iad-key-val
		"<current name>|<corrected name>"))
            ((looking-at "NAMECORRECTAS-")
	      (setq iad-key-val
		"<current name>|<correct IMDb name>"))
            ((looking-at "ATTRIBUTE-")
	      (setq prefix "ATTRIBUTE-")
	      (forward-char 10))
            ((looking-at "REPLACE-")
     	      (setq prefix "REPLACE-")
	      (forward-char 8))
	    (t))
	  (setq iad-q (point))
	  (end-of-line)
	  (setq iad-key-lookup (buffer-substring iad-q (point)))
          ;; Add prefix to keyword if existent (for messages etc.)
          (if (eq prefix 'nil)
	    (setq iad-key iad-key-lookup)
	    (setq iad-key (concat prefix iad-key-lookup)))))
     ;;; Now fetch syntax for template insertion if not preset above
     (if (eq iad-key-val 'nil)
       ;;; Handle attribute case
       (cond ((string= prefix "ATTRIBUTE-")
         ;; Get attribute syntax from imdb-adds-keyword-alist
	 (setq iad-key-val 
           (nth 5 (nth 0 (assoc-default iad-key-lookup
			   imdb-adds-keyword-alist 'string=)))))
         ;; Get kw syntax *and* replace syntax from imdb-adds-keyword-alist
         ((string= prefix "REPLACE-")
   	   (setq iad-key-val (concat
             (nth 1 (nth 0 (assoc-default iad-key-lookup
			     imdb-adds-keyword-alist 'string=)))
             (nth 6 (nth 0 (assoc-default iad-key-lookup
			     imdb-adds-keyword-alist 'string=))))))
         ;; Get kw syntax from imdb-adds-keyword-alist
	 (t
 	   (setq iad-key-val
	     (nth 1 (nth 0 (assoc-default iad-key-lookup
			     imdb-adds-keyword-alist 'string=)))))))
      ;;; Now insert what we have fetched
      (if (eq iad-key-val 'nil)
	(message "No syntax description available for %s" iad-key)
	(progn
	  (goto-char iad-r)
	  (if (eq (type-of iad-key-val) 'string)
	    (insert (concat iad-key-val "\n"))
	    (progn
	      (setq iad-p (point))
	      (imdb-adds-display-help iad-key-lookup t)
	      (setq iad-q (point))
	      (save-restriction
		(narrow-to-region iad-p iad-q)
		(setq kill-whole-line t)
		(goto-char (point-min))
;; is iad-key still right here?
		(if (re-search-forward (concat iad-key "\n") nil t)
		  (replace-match "") nil)
                ;;; unless beginner-mode is wanted kill all syntax
                ;;; descriptions, only leave tags over as template
		(unless (eq imdb-adds-beginner-mode 't)
		  (progn
		    (goto-char (point-min))
		    (while (re-search-forward "^[A-Z]+: \\(\* \\)*" nil t)
		      (kill-line))
		    (goto-char (point-min))
		    (while (re-search-forward "^[A-Z]+: " nil t)
		      (setq iad-p (point))
		      (beginning-of-line)
		      (setq iad-match (buffer-substring (point) iad-p))
		      (if (string= iad-last-match iad-match)
			(kill-line)
			(goto-char iad-p))
		      (setq iad-last-match iad-match))
		    (goto-char (point-min))
		    (while (re-search-forward "^=>" nil t)
		      (beginning-of-line)
		      (kill-line))))))))))
    (message "Please delete anything you don't fill out or need")))

(defun imdb-adds-mail-submission ()
  "Mail your submissions to the IMDb mail-server.

This functions opens a mail buffer and inserts the 
content of the current buffer for sending it to the 
IMDb mail-server. Use it when you have finished
editing your submission data.

If you should have forgotten to end your submission
file with END you will be asked whether it should be
appended at the end of your file automatically. If you
answer 'no' to that question, the functions stops
without creating a mail buffer.

The e-mail address to send the submission to is taken
from the two variables `imdb-adds-mail-server-address'
and `imdb-adds-mail-domain'."
  (interactive)
  (let ((iad-p) (mail-condition))
    (save-excursion
      (setq iad-p (point))
      (goto-char (point-min))
      (if (re-search-forward "^END\n" nil t)
	(setq mail-condition t)
        (if (y-or-n-p "END keyword not found. Append automatically?")
	  (progn
	    (goto-char (point-max))
	    (insert "\nEND\n")
	    (setq mail-condition t)) nil))
      (goto-char iad-p))
    (if (eq mail-condition 't)
      (progn
        (kill-new (buffer-substring (point-min) (point-max)))
        (mail)
        (beginning-of-buffer)
        (search-forward "To: ")
        (insert
	 (concat imdb-adds-mail-server-address "@" imdb-adds-mail-domain))
        (search-forward "Subject: ")
        (insert "Submission")
        (end-of-buffer)
        (insert "\n\n")
        (yank)))))

(defun imdb-adds-toggle-beginner-mode ()
  "Toggle beginner mode on or off.

This function toggles the IMDb adds beginner mode on 
or off regardless of its default setting which is defined
by the variable `imdb-adds-beginner-mode'.

Beginner mode changes the behaviour of the template
functions `imdb-adds-make-new-template', 
`imdb-adds-insert-new-template' and 
`imdb-adds-insert-sub-template'.

With beginner mode on those functions will insert
additional information which shall conveniently
remind you of any IMDb submission keywords' specific 
syntax.

Please remember to delete or overwrite this additional
information before you are going to send your data
submissions to the IMDb mail server.
"
   (interactive)
   (if (eq imdb-adds-beginner-mode 't)
     (progn
       (setq imdb-adds-beginner-mode nil)
       (setq mode-name "IMDb Adds")
       (message "Beginner mode now OFF")
       (force-mode-line-update))
     (progn
       (setq imdb-adds-beginner-mode t)
       (setq mode-name "IMDb Adds Beginner")
       (message "Beginner mode now ON")
       (force-mode-line-update))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Definition for keybings ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Describe key bindings for imdb-adds mode
(if imdb-adds-mode-map
    nil
  (setq imdb-adds-mode-map (make-sparse-keymap)) ; or make-keymap
  (define-key imdb-adds-mode-map [(meta up)] 'imdb-adds-move-to-previous-keyword)
  (define-key imdb-adds-mode-map "\C-cp" 'imdb-adds-move-to-previous-keyword)
  (define-key imdb-adds-mode-map [(meta down)] 'imdb-adds-move-to-next-keyword)
  (define-key imdb-adds-mode-map "\C-cn" 'imdb-adds-move-to-next-keyword)
  (define-key imdb-adds-mode-map "\C-cf" 'font-lock-fontify-buffer)
  (define-key imdb-adds-mode-map "\C-ctb" 'imdb-adds-toggle-beginner-mode)
  (define-key imdb-adds-mode-map "\ec" 'imdb-adds-entry-checked-as-accepted)
  (define-key imdb-adds-mode-map "\C-ctt" 'imdb-adds-make-new-template)
  (define-key imdb-adds-mode-map "\C-cti" 'imdb-adds-insert-new-template)
  (define-key imdb-adds-mode-map "\C-cts" 'imdb-adds-insert-sub-template)
  (define-key imdb-adds-mode-map "\C-cm" 'imdb-adds-mail-submission)
  (define-key imdb-adds-mode-map "\C-ctm" 'imdb-adds-insert-prefix-comment)
  (define-key imdb-adds-mode-map "\C-ctr" 'imdb-adds-insert-prefix-correct)
  (define-key imdb-adds-mode-map "\C-ctn" 'imdb-adds-insert-prefix-namecorrect)
  (define-key imdb-adds-mode-map "\C-ctc" 'imdb-adds-insert-prefix-namecorrectas)
  (define-key imdb-adds-mode-map "\C-ctp" 'imdb-adds-insert-prefix-replace)
  (define-key imdb-adds-mode-map "\C-cta" 'imdb-adds-insert-prefix-attribute)
  (define-key imdb-adds-mode-map "\C-chs" 'imdb-adds-show-keyword-syntax)
  (define-key imdb-adds-mode-map [(meta f1)] 'imdb-adds-show-keyword-syntax)
  (define-key imdb-adds-mode-map "\C-che" 'imdb-adds-show-keyword-example)
  (define-key imdb-adds-mode-map [(meta f2)] 'imdb-adds-show-keyword-example)
  (define-key imdb-adds-mode-map "\C-chb" 'imdb-adds-browse-keyword-online-help)
  (define-key imdb-adds-mode-map [(meta f3)] 'imdb-adds-browse-keyword-online-help)
  (define-key imdb-adds-mode-map "\C-cte" 'imdb-adds-mail-to-maintainer)
  (define-key imdb-adds-mode-map "\C-chh" 'imdb-adds-keyword-full-help)
  (define-key imdb-adds-mode-map "\C-cha" 'imdb-adds-show-all-keywords)
  (define-key imdb-adds-mode-map [(meta kp-add)] 'imdb-adds-increase-roman-numeral)
  (define-key imdb-adds-mode-map [(meta kp-subtract)] 'imdb-adds-decrease-roman-numeral)
  (define-key imdb-adds-mode-map "\ep" 'imdb-adds-copy-previous-data-field)
  (define-key imdb-adds-mode-map "\en" 'imdb-adds-copy-next-data-field)
  (define-key imdb-adds-mode-map "\e1" 'imdb-adds-swap-name-insert-comma-1-given-name)
  (define-key imdb-adds-mode-map "\e2" 'imdb-adds-swap-name-insert-comma-2-given-names)
  (define-key imdb-adds-mode-map "\e3" 'imdb-adds-swap-name-insert-comma-3-given-names)
  (define-key imdb-adds-mode-map "\e4" 'imdb-adds-swap-name-insert-comma-4-given-names)
  (define-key imdb-adds-mode-map  "\C-cth" 'imdb-adds-region-make-fulltext-hyperlink)
  (define-key imdb-adds-mode-map "\C-ca" 'abbrev-mode)
  ; ...

  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Definition for the menu ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun imdb-adds-create-mode-menu ()
  "Create IMDb Adds Mode menu."
  (list
   "IMDb-Adds"
   '("Help On IMDb Keywords"
     ["Show Keyword Syntax" imdb-adds-show-keyword-syntax t]
     ["Show Keyword Example" imdb-adds-show-keyword-example t]
     ["Browse Keyword Online Help" imdb-adds-browse-keyword-online-help t]
     ("Extended Online Help"
       ["Accented/Special Characters" imdb-adds-browse-iso t]
       ["Attributes" imdb-adds-browse-attributes t]
       ["Character Names" imdb-adds-browse-characters t]
       ["ISO Country Codes" imdb-adds-browse-iso-country t]
       ["Order/Sequence Numbers" imdb-adds-browse-order t]
       ["Russian Names/Titles" imdb-adds-browse-russian t]
       )
     "--"
     ["Full Help For Keyword..." imdb-adds-keyword-full-help t]
     ["Describe All Keywords" imdb-adds-show-all-keywords t]
     "--"
     ["Mail To List Maintainer" imdb-adds-mail-to-maintainer t]
     )
   ["Insert Sub-Template" imdb-adds-insert-sub-template t]
   ["Toggle IMDb Adds Beginner Mode" imdb-adds-toggle-beginner-mode t]
   "--"
   ["Insert Comma, 1 Given Name" imdb-adds-swap-name-insert-comma-1-given-name t]
   '("Insert Comma..."
     ["Insert Comma, 2 Given Names" imdb-adds-swap-name-insert-comma-2-given-names t]
     ["Insert Comma, 3 Given Names" imdb-adds-swap-name-insert-comma-3-given-names t]
     ["Insert Comma, 4 Given Names" imdb-adds-swap-name-insert-comma-4-given-names t]
     )
   ["Increase Roman Numeral" imdb-adds-increase-roman-numeral t]
   ["Decrease Roman Numeral" imdb-adds-decrease-roman-numeral t]
   ["Hyperlink Region [(qv)]" imdb-adds-region-make-fulltext-hyperlink t]
   "--"
   ["Insert COMMENT-..." imdb-adds-insert-prefix-comment t]
   ["Insert CORRECT-..." imdb-adds-insert-prefix-correct t]
   ["Insert NAMECORRECT-..." imdb-adds-insert-prefix-namecorrect t]
   ["Insert NAMECORRECTAS-..." imdb-adds-insert-prefix-namecorrectas t]
   ["Insert REPLACE-..." imdb-adds-insert-prefix-replace t]
   ["Insert ATTRIBUTE-..." imdb-adds-insert-prefix-attribute t]
   "--"
   ["Make New Adds Template" imdb-adds-make-new-template t]
   ["Insert New Adds Template" imdb-adds-insert-new-template t]
   ["Mail Buffer To IMDb Adds Server" imdb-adds-mail-submission t]
   ["Fontify Buffer" font-lock-fontify-buffer t]
   ["Toggle Abbrev Mode" abbrev-mode t]
   ))

(defvar imdb-adds-mode-menu-list (imdb-adds-create-mode-menu)
  "IMDb Adds Mode menu.")

;;; Define the imdb-adds-mode entry function:
(defun imdb-adds-mode ()
  "Major mode for editing IMDb data submission files.

Special commands:
\\{imdb-adds-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'imdb-adds-mode)
  (if (eq imdb-adds-beginner-mode 'nil)
    (setq mode-name "IMDb Adds")
    (setq mode-name "IMDb Adds Beginner"))
;;  (setq mode-name "IMDb Adds")
  (make-local-variable 'comment-start)
  (setq comment-start "=>")
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "=>")
  (setq local-abbrev-table imdb-adds-mode-abbrev-table)
  (make-local-variable 'font-lock-keywords-only)
  (setq font-lock-keywords-only t)
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(imdb-adds-mode-fontlock-keywords nil nil))
  (put 'imdb-adds-mode 'mode-class 'special)
  (use-local-map imdb-adds-mode-map)
  (easy-menu-define imdb-adds-mode-menu imdb-adds-mode-map
		    "Menu keymap for IMDb Adds Mode." imdb-adds-mode-menu-list)
  (run-hooks 'imdb-adds-mode-hook))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Definition of more help functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun imdb-adds-display-help (keyword &optional no-own-window)
  "Display multi-line keyword syntax' in an extra window.

The function displays the formal syntax for 
the given IMDb multi-line keyword. 

By default its output is displayed in an extra window. 
You may suppress opening an extra window by setting
the parameter `no-own-window' to 't'."
  (interactive "s")
  (let ((iad-p) (iad-q) (iad-r) (iad-help) (iad-nope))

    (cond ((string= keyword 'AGENT)
	   (setq iad-help "
AGENT
NM: <IMDb name>
CONTACT: <agent's name>
JOB:  <job of agent>
COMP: <name of agent's company>
ADDR: <complete address of company>
TEL: <telephone number>
FAX: <fax number>
EMAIL: <e-mail>
ONLYPRO: <display agent details on IMDb Pro only? [Y/N]>
REPLACE: <replace existing agent details? [Y/N]>"))

          ((string= keyword 'AWARD)
	   (setq iad-help "
AWARD
MV: <title>
NM: <name> and/or CY: <company-name>
EV: <event's name>
AW: <award's name>
CT: <category>
YR: <year of event>
RK: <ranking>
CO: - <additional comment...>"))

	  ((string= keyword 'AWMASTER)
	   (setq iad-help 
		 "
AWMASTER
EV: <event's name>, <city>, <country>
AW: <award's common/english name>
EL: <city>, <country>
EO: <event's official/native name>
AO: <award's official/native name>
AF: <award's format and/or amount>
AC: <award's criteria...>
AI: <award's initiator>
OW: <official web site>
ST: <time specification>
SG: <geographic specification>
TP: <award given in/since this year(s)>
CO: - <additional comment...>
CR: <year>: <IMDb title of TV/video coverage of event>
JU: <year>: <member of jury>
HO: <year>: <host of event>
DA: <year>: <date of event>
LO: <year>: <location of event>
TR: <year>: - <trivia for that year...>"))

	  ((string= keyword 'BIOGR)
	   (setq iad-help "
BIOGR
NM: <name> 
RN: <person's real name>
NK: <person's nick-name>
DB: <date of birth>, <place of birth>
DD: <date of death>, <place of death>. (cause of death)
HT: <height of person>
BG: <mini-biography...>
BY: <mini-bio author>
SP: * <spouse entry>
BO: * <available print biography>
BT: * <title of biographical films about the person>
PI: * <title of movie that person is portrayed in>
OW: * <other works...>
TM: * <trade mark>
TR: * <general trivia...>
QU: * \"<personal quotes>\"
SA: * <title> -> <salary>
AG: * <agent's address...>
IT: * \"<journal>\" (<country>), <(<day> <month>) <year>>, Vol. <volume>, 
IT: Iss. <issue>, pg. <pages>, by: <author>, \"<title>\", <language>
PT: * \"<journal>\" (<country>), <(<day> <month>) <year>>, Vol. <volume>, 
PT: Iss. <issue>, pg. <pages>, by: <photographer>, \"<title>\"
CV: * \"<journal>\" (<country>), <(<day> <month>) <year>>, Vol. <volume>, 
CV: Iss. <issue>
WN: * <(<month>) <year>> <where are they now?>
AT: * \"<journal>\" (<country>), <(<day> <month>) <year>>, Vol. <volume>, 
AT: Iss. <issue>, pg. <pages>, by: <author>, \"<title>\", <language>"))

; 	  ((string= keyword 'BUSINESS)
; 	   (setq iad-help "
; BUSINESS
; MV: <title>
; BT: <movie budget (country)>
; OW: <opening weekend box office take (territory) (date) (screens)>
; GR: <box office gross (territory) (date)>
; RT: <rentals>
; AD: <admissions (territory) (date)>
; PD: <production dates: start - end>
; ST: <studio where movie was filmed (country)>
; CP: <copyright holder and contact information...>"))

          ((string= keyword 'COMPANY-CONTACT)
	   (setq iad-help "
COMPANY-CONTACT
COMP: <company's name>
CONTACT: <contact person>
ADDR: <complete address of company>
TEL: <telephone number>
FAX: <fax number>
EMAIL: <e-mail>
WEBSITE: <web site>
ONLYPRO: <display company information on IMDb Pro only? [Y/N]>
REPLACE: <replace existing company information? [Y/N]>
COMM: <additional comment(s)>"))

	  ((string= keyword 'CRAZY)
	   (setq iad-help "
CRAZY
# <title>
- entry 1
  ...
- entry 2

=> (Please note: column width maximum is 68, then newline)
=>       1         2         3         4         5         6        <"))

	  ((string= keyword 'DVD)
	   (setq iad-help "
DVD
DN: <dvd number>
LB: <label>
CN: <catalogue number>
DT: <dvd title>
OT: <original title>
PC: <production country>
YR: <year>
CF: <certification>
LE: <length>
CA: <category>
GR: <group (genre)>
RD: <release date>
ST: <status of availablility>
PR: <official retail price>
RC: <release country>
AC: <area code>
CP: <copy protection>
LA: <language>
SF: <sound format>
SU: <subtitles>
VS: <video standard>
CO: <color information>
MF: <master format>
PP: <pressing plant>
PK: <packaging>
SI: <number of sides>
DF: <disc format>
PF: <picture format>
AS: <aspect ratio>
CC: <close captions/teletext>
CS: <number of chapter stops>
QP: <quality program>
BR: <average bitrate>
IN: <additional information>

=> Please do not leave out fields for information which is not
=> applicable, just use \"-\" as value. For example a disc without area
=> code sound would get this entry:
=> 
=> AC: -
=> or a DVD which is under no qaulity program will get:
=> QP: -"))

	  ((string= keyword 'GOOF)
	   (setq iad-help "
GOOF
# <title>
- CONT: A continuity error\; a minor technical inconsistency of little 
  importance to the plot. 
- PLOT: Plot holes. Errors in narrative structure as opposed to technical 
  detail. 
- FACT: Concept in the film contradicts science or known facts. 
- DATE: Anachronisms\; objects/concepts that hadn't existed at the time 
  the film was set. 
- FAKE: Mistakes that reveal how the filmmakers composed a scene of the film. 
- BOOM: Boom mike visible in an interesting or unusual way. A special case 
  of CREW below. 
- CREW: Crew or equipment visible in shot. 
- SYNC: Audio/visual tracks don't match exactly. 
- GEOG: Errors in geography of specific places. 
- MISC: Anything else."))

	  ((string= keyword 'INPROD)
	   (setq iad-help "
MV: <title>
ST: <status of production>
CM: <additional comment>
UP: <date of updated information>

=> with <status of production> to be one of the following
=> 
=> Unknown
=> Announced
=> Pre-production
=> Filming
=> Post-production
=> Completed"))

	  ((string= keyword 'LASERDISC)
	   (setq iad-help "
LASERDISC
LN: <laserdisc number> 
LB: <label> 
CN: <catalogue number> 
LT: <laserdisc title> 
OT: <original title> 
PC: <production country> 
YR: <year> 
CF: <certification> 
CA: <category> 
GR: <genre> 
LA: <language> 
SU: <subtitles> 
LE: <length> 
RD: <release date> 
ST: <status of availablility> 
PR: <official retail price> 
VS: <video standard> 
CO: <color information> 
SE: <sound encoding> 
DS: <digital sound> 
AL: <analog left> 
AR: <analog right> 
MF: <master format> 
PP: <pressing plant> 
SZ: <disc size> 
SI: <number of sides> 
DF: <disc format> 
PF: <picture format> 
AS: <aspect ratio> 
CC: <close captions/teletext/ld+g> 
CS: <number of chapter stops> 
QP: <quality program> 
IN: <additional information>"))

	  ((string= keyword 'LITERATURE)
	   (setq iad-help "
LITERATURE
MOVI: <title>
SCRP: <published screenplay>
NOVL: <original literary source>
NOVL:  <still original literary source>
ADPT: <adaptated literary source>
BOOK: <monographic book>
PROT: <production protocol>
IVIW: <interview cast or crew>
IVIW:  <still interview cast or crew>
CRIT: <printed review>
ESSY: <printed essay>
OTHR: <other literature>

=> (Please note: column width maximum is 76, then newline)
=>        1         2         3         4         5         6         7     <"))

	  ((string= keyword 'LITERATURENEW)
	   (setq iad-help "
LITERATURENEW
<title>|<literature type>|<author>|<literature title>|<source>|<publisher>|<location>||<issue>|<date>||<literature format>|<page(s)>|<isbn/issn>

=> Literature types tags:
=> SCRP = Published screenplay
=> NOVL = Original literary source
=> ADPT = Adaptated literary source
=> BOOK = Monographic book
=> PROT = Production protocol
=> IVIW = Interview cast or crew
=> CRIT = Printed review
=> ESSY = Printed essay
=> OTHR = Other literature
=> 
=> Literature formats:
=> Book
=> Magazine
=> Newspaper
=> Weekly Newspaper"))

	  ((string= keyword 'OUTLINE)
	   (setq iad-help "
OUTLINE
MV: <title>
PL: <plot outline line 1>
PL: <plot outline line 2>
BY: <your name> <your-mail-address>

=> (Please note: two PL: lines maximum)
=> (Please note: column width maximum is 78, then newline)
=>       1         2         3         4         5         6         7        <"))

	  ((string= keyword 'PLOTS)
	   (setq iad-help "
PLOTS
MV: <title>
PL: <plot summary line 1> 
PL: <plot summary line 2> 
PL: ...
BY: <your name> <your-mail-address>

=> (Please note: ten PL: lines maximum)
=> (Please note: column width maximum is 78, then newline)
=>       1         2         3         4         5         6         7        <"))

	  ((string= keyword 'QUOTE)
	   (setq iad-help "
QUOTE
# <title>
{<name>@<character>}: Exact quote goes here...
  ... still quote."))


	  ((string= keyword 'SOUNDTRACK)
	   (setq iad-help "
SOUNDTRACK
# <title>
- \"music title 1\"
  complete info as on-screen goes here
  ...
- \"music title 2\"
  ...
- ...
=> (Please note: data as it appears on-screen, *not* on the CD cover)"))

	  ((string= keyword 'TAG)
	   (setq iad-help "
TAG
# <title>
 tabulator <tagline 1>
 tabulator <tagline 2>"))

	  ((string= keyword 'TRIVIA)
	   (setq iad-help "
TRIVIA
# <title>
- <first trivia entry...>
- <second trivia entry...>"))

	  ((string= keyword 'URLNAME)
	   (setq iad-help "
URLNAME
<name>|<type-of-link>|<URL>|<description (size)>

=> with <type-of-link> to be one of the following
=> 
=> IMG  image e.g. gifs or jpegs
=> SND  sound e.g. Sun \".au\" format
=> MOV  movie e.g. mpeg or quicktime
=> OFF  official sites (movie releases etc)
=> MSC  miscellaneous i.e. anything that doesn't fit into a type above"))

	  ((string= keyword 'URLTITLE)
	   (setq iad-help "
URLTITLE
<title>|<type-of-link>|<URL>|<description (size)>

=> with <type-of-link> to be one of the following
=> 
=> IMG  image e.g. gifs or jpegs
=> SND  sound e.g. Sun \".au\" format
=> MOV  movie e.g. mpeg or quicktime
=> COM  comments/reviews e.g. in online newspapers
=> OFF  official sites (movie releases etc)
=> POS  movie posters
=> TRA  movie trailers
=> MSC  miscellaneous i.e. anything that doesn't fit into a type above"))

	  ((string= keyword 'VERSIONS)
	   (setq iad-help "
VERSIONS
# <title>
- <description of version... >
  <... still description>
- <description of another version>

=> An \"alternate version\" in this sense is a new version of a 
=> movie that is different from the one that was originally and 
=> widely released in theatres."))

	  (t (setq iad-nope "No syntax description for")))
    (if (eq iad-nope 'nil)
      (progn
      (unless (eq no-own-window 't)
	(progn
	  (setq iad-r (point))
 	  (setq iad-p (selected-window))
	  (if (eq (get-buffer-window "* IMDb adds help *") nil)
	    (progn
	      (get-buffer-create "* IMDb adds help *")
	      (setq iad-q (split-window iad-p))
	      (select-window iad-q)
	      (set-window-buffer iad-q "* IMDb adds help *"))
	    (select-window (get-buffer-window "* IMDb adds help *")))
	  (if (string= (buffer-name) "* IMDb adds help *")
	    (erase-buffer) nil)
  	  (imdb-adds-mode)))
       (insert iad-help)
       (insert "\n\n")
       (unless (eq no-own-window 't)
	 (progn
	   (goto-char (point-min))
	   (select-window iad-p)
	   (goto-char iad-r)
           (message "Type C-x 1 to remove help window. M-C-v to scroll the help."))))
      (if (eq no-own-window 't)
	(insert (concat iad-nope " " keyword "\n\n"))
        (message "%s %s" iad-nope keyword)))
      ))

(defun imdb-adds-display-example (keyword &optional no-own-window)
  "Display multi-line keyword examples in an extra window.

The function displays the real world example data for 
the given IMDb multi-line keyword. 

By default its output is displayed in an extra window. 
You may suppress opening an extra window by setting
the parameter `no-own-window' to 't'."
  (interactive "s")
  (let ((iad-p) (iad-q) (iad-r) (iad-help) (iad-nope))

    (cond ((string= keyword 'AGENT)
	   (setq iad-help "
AGENT
NM: Actor, Joe (II)
CONTACT: David Gersh
JOB: Talent Agent
COMP: The Gersh Agency
ADDR: 222 N. Canon Drive, Beverly Hills, CA 90210, USA
TEL: 555-205-5812
EMAIL: dg\@dg.nirwana.net
ONLYPRO: Y
REPLACE: Y"))

          ((string= keyword 'AWARD)
	   (setq iad-help "
AWARD
MV: \"Love & Money\" (1999)
CY: CBS
NM: Delu, Dahl  (production designer)
NM: Lipscomb, Rusty  (set decorator)
EV: Emmy Awards
AW: Emmy
CT: Outstanding Art Direction for a Multi-Camera Series
YR: 2000
RK: 1
CO: - For the pilot."))

	  ((string= keyword 'AWMASTER)
	   (setq iad-help 
		 "AWMASTER
EV: Academy Awards, USA
AW: Oscar
EL: Los Angeles, California, USA
EO: *th Annual Academy Awards
AO: The Academy Award of Merit
AF: Oscar statuette
AI: Academy of Motion Picture Arts and Sciences (AMPAS)
AC: With the exceptions of animated and foreign films any film can qualify
AC:  for Oscars in all narrative feature categories with a seven-day
AC:  run in any Los Angeles County theater during the year of eligibility.
AC: Films submitted for Best Foreign Language Film Award consideration may
AC:  also qualify for Academy Awards in most other categories provided they
AC:  meet the requirements governing those categories.
OW: http://www.oscar.com/
ST: regular
SG: national  (international)
TP: 1929-
CO: - The Academy Award (Oscar) is the main national film award in the USA.
CO: - The Academy of Motion Picture Arts and Sciences is a professional
CO:  honorary organization composed of over 6,000 motion picture
CO:  craftsmen and women. (as of 1999).
CR: 1999: 71st Annual Academy Awards, The (1999) (TV)
HO: 1999: Goldberg, Whoopi
HO: 2001: Martin, Steve
DA: 1999: 21 March
DA: 2001: 25 March
LO: 1999: Dorothy Chandler Pavilion, L.A. County Music Center, Los Angeles, California, USA
LO: 2001: Shrine Auditorium, Los Angeles, California, USA
TR: 1953: - The ceremony is telecasted nation-wide in the USA and Canada
TR: 1953:  for the first time."))

	  ((string= keyword 'BIOGR)
	   (setq iad-help "
BIOGR
NM: Actor, Joe
RN: Joseph Smith
DB: 10 September 1945, London, England, UK
DD: 13 October 1994, Beverly Hills, USA. (heart attack) 
SP: 'Heather Actress' (qv) (January 1982 - December 1993) (divorced)
BG: Stage actor in San Francisco; founding member of the 1980's comedy troup,
BG: Stomp Out Loud, Radio Drama work includes hundreds of shows on American 
BG: Radio Theatre.
BY: Joe Actor
HT: 6'
QU: * \"Sentiment without action is the ruin of the soul.\"
IT: * \"Empire\" (UK), 1995, Vol. 5, Iss. 10, pg. 25-33, by: Arnold Aufer, 
IT: English
PT: * \"Sight & Sound\" (UK), 1996, Vol. 5, Iss. 10, pg. 54, by: John Alist, 
PT: English
CV: * \"Premiere\" (UK), July 1997, Vol. 5, Iss. 10
SA: * _Fictional Movie, A (1996)_ (qv) -> $2,500,000
AT: * \"Sight & Sound\" (UK), 1996, Vol. 5, Iss. 10, pg. 54, by: John Alist, 
AT: English
AG: * Peter Chaser & Dunbar
AG:   Fury House
AG:   34-43 Russell St.
AG:   London WC2C 5YA
AG:   Tel: +44 (0)20 4436 9500
AG:   Fax: +44 (0)20 3678 1044"))

; 	  ((string= keyword 'BUSINESS)
; 	   (setq iad-help "
; BUSINESS
; MV: Fictional Title, A (1996)
; BT: $43,000,000 (USA)
; OW: $5,400,000 (USA) (8-10 March 1996) (450 screens)
; GR: $15,340,000 (USA) (10 March 1996)
; GR: $35,405,000 (Non-USA) (10 March 1996)
; GR: $50,745,000 (Worldwide) (10 March 1996)
; RT: $25,130,000 
; AD: 330,150 (USA)
; AD: 145,000 (Sweden) (16 November 1996)
; AD: 105,000 (Sweden) (9 November 1996)
; PD: 21 December 1995 - 7 February 1996 (shooting)
; ST: Shepperton Studios, Shepperton (UK)
; ST: Cinecitta', Rome (Italy)
; CP: (1996) Foobar Productions, Inc.
; CP: 1234 Wilshire Blvd.
; CP: 90210 Beverly Hills, CA, U.S.A.
; CP: Phone: 301-555-1234"))

          ((string= keyword 'COMPANY-CONTACT)
	   (setq iad-help "
COMPANY-CONTACT
COMP: Viacom Prods. Inc.
CONTACT: Mr. Smith
ADDR: 10880 Wilshire Blvd., #1101, Los Angeles, CA 90024
TEL: 555-234-5000
FAX: 555-234-5059
EMAIL: viacom-desk\@vc.nirvana.net
WEBSITE: http://www.viacom.com/
ONLYPRO: N
REPLACE: Y
COMM: Founded in 1977."))

	  ((string= keyword 'CRAZY)
	   (setq iad-help "
CRAZY
# 10 Things I Hate About You (1999)
- During the credits there are practical jokes made by
  cast and crew and also goofs - including scenes that didn't make
  the final cut."))

	  ((string= keyword 'DVD)
	   (setq iad-help "
DVD
DN: 66
LB: Newline Home Video
CN: N4381 DVD

DT: Se7en
OT: Se7en (1995)

PC: USA
YR: 1995
CF: R
LE: 127
CA: Movie
GR: Thriller

RD: April 1997
ST: Available
PR: $ 24.98
RC: USA
AC: 1
CP: Macrovision

LA: English
SF: Dolby Digital 5.1
LA: French (Canadian Dub)
SF: Dolby Digital 2.0
SU: English/French/Spanish

VS: NTSC
CO: Color
MF: Film
PK: Keep Case
SI: 2
DF: DS-SL
PF: Letterbox
AS: 2.35 : 1

CC: Teletext
CS: 38
QP: -
BR: 8.0
IN: This is one of the best DVDs so far."))

	  ((string= keyword 'GOOFS)
	   (setq iad-help "
GOOFS
# Abyss, The (1989)
- FAKE: When the nuclear submarine is diving at a steep angle,
  dripping water indicates the effect was achieved by tilting the
  camera, not the set.
- CONT: The Explorer has its name written on its side in some shots,
  but not in others.
- CREW: Shoulder of crew member visible in bottom left corner of
  screen just after Coffee screws the silencer to the gun."))

	  ((string= keyword 'INPROD)
	   (setq iad-help "
MV: Long Hello and the Short Goodbye, The (1998)
ST: Filming
CM: Shooting in Hamburg, Germany, from June to August 1998.
UP: 1 June 1998"))

	  ((string= keyword 'LASERDISC)
	   (setq iad-help "
LASERDISC
LN: 1124
LB: CBS FOX
CN: 0693-84

LT: Star Wars Trilogy - The Definitive Collection
OT: Star Wars (1977)
OT: Empire Strikes Back, The (1980)
OT: Return of the Jedi (1983)

PC: USA
YR: VAR
CF: PG
CA: Movie
GR: Sci-Fi
LA: English
SU: -
LE: 376

RD: 15 September 1993
ST: Available
PR: $ 249.98

VS: NTSC
CO: Color
SE: Digital/Analog
DS: Dolby Surround
AL: Commentary
AR: Commentary
MF: Film
PP: Mitsubishi
SZ: 12
SI: 18
DF: CAV
PF: Letterbox
AS: 2.35 : 1
CC: CC
CS: 287
QP: THX
IN: Collector's Edition. This disc has the rolling bar problem. See text
IN: _StarWarsFlaws_.
IN: 
IN: Supplements: Book \"George Lucas: The Creative Impulse\"\; audio
IN: commentary\; interviews; trailers; production photos."))

	  ((string= keyword 'LITERATURE)
	   (setq iad-help "
LITERATURE
MOVI: Star Wars (1977)
NOVL: Lucas, George. Star Wars: A New Hope. New York: Ballantine Books, 
NOVL:  1976. 260 pages. ISBN 0345400771.
BOOK: Geraldine Richelson, \"The Star Wars Storybook\" (New York: Random 
BOOK:  House 1978, ISBN 0001382187)
PROT: Carol Titelman, ed. \"The Art of Star Wars\" (New York: Ballantine 
PROT:  1979, ISBN 0345282736, reprinted 1997)
IVIW: Russo, Tom. \"Star Struck\". In: Premiere (USA). February 1997, 
IVIW:  Vol. 10, Iss. 6. pg. 80-87. (MG)
CRIT: Schiller, Hans. Romantik i världsrymden. In: Svenska Dagbladet 
CRIT:  (Sweden). 17 December 1977 (NP)"))

	  ((string= keyword 'OUTLINE)
	   (setq iad-help "
OUTLINE
MV: Frog Girl: The Jennifer Graham Story (1989) (TV)
PL: A 15-year old school girl refuses to dissect a frog and sues her
PL: school district for not allowing her to do an alternative project.
BY: Oliver Heidelbach"))

	  ((string= keyword 'PLOTS)
	   (setq iad-help "
PLOTS
MV: Ángeles gordos (1980)
PL: An overweight man and woman become penpals but are too embarrassed to send
PL: each other photographs of themselves and instead exchange pictures of
PL: two thinner people.  Comedic complications arise when the two penpals
PL: finally arrange to meet in person.
BY: Michaela May <mmay\@shuffle.com>"))

	  ((string= keyword 'QUOTE)
	   (setq iad-help "
QUOTE
# \"Adam-12\" (1968)
{McCord, Kent\@Officer James A. 'Jim' Reed}: You just have to know how to 
  arrest them and still make them like you. We call it technique."))

	  ((string= keyword 'SOUNDTRACK)
	   (setq iad-help "
SOUNDTRACK
# 12:01 (1993) (TV)
- \"BABY DON'T LEAVE\"
  Performed by 'William Peterkin' (qv)
  Written by Barbara L. Jordan, William Peterkin
  Used by permission of Heavy Hitters & Wild About Music
- \"FAMILY\"
  Performed by William Peterkin
  Written by Barbara L. Jordan, Heavy Hitters and William Peterkin
  Used by permission of Heavy Hitters"))

	  ((string= keyword 'TAG)
	   (setq iad-help "
TAG
# Jaws (1975)
\tShe was the first"))

	  ((string= keyword 'TRIVIA)
	   (setq iad-help "
TRIVIA
# X-Men (2000)
- When Wolverine complains about their outfits, Cyclops asks him if
  he'd prefer yellow spandex. This in-joke refers to the fact that one
  of Wolverine's costumes in the X-Men comics is predominantly yellow."))

	  ((string= keyword 'VERSIONS)
	   (setq iad-help "
VERSIONS
# American Psycho (2000)
- To avoid a NC-17 rating, a scene which depicted a three-way sexual
  encounter between the lead character Christian Bale and two
  prostitutes was slightly cut for the U.S. release, removing about 20
  seconds of footage. The scene has been left intact for the
  Canadian/international release.
- Region 2 DVD features 5 deleted scenes."))

	  (t (setq iad-nope "No example for")))
    (if (eq iad-nope 'nil)
      (progn
	(unless (eq no-own-window 't)
	   (progn
	     (setq iad-r (point))
	     (setq iad-p (selected-window))
	     (if (eq (get-buffer-window "* IMDb adds help *") nil)
	       (progn
		 (get-buffer-create "* IMDb adds help *")
		 (setq iad-q (split-window iad-p))
		 (select-window iad-q)
		 (set-window-buffer iad-q "* IMDb adds help *"))
	       (select-window (get-buffer-window "* IMDb adds help *")))
	     (if (string= (buffer-name) "* IMDb adds help *")
	       (erase-buffer) nil)
	     (imdb-adds-mode)))
	  (insert iad-help)
	  (insert "\n\n")
  	  (unless (eq no-own-window 't)
	    (progn
  	      (goto-char (point-min))
	      (select-window iad-p)
	      (goto-char iad-r)
              (message "Type C-x 1 to remove help window. M-C-v to scroll the help."))))
      (if (eq no-own-window 't)
	(insert (concat iad-nope " " keyword "\n\n"))
        (message "%s %s" iad-nope keyword))
      )))

(defvar imdb-adds-roman-numerals-alist
'(
  (1 . "(I)") (2 . "(II)") (3 . "(III)") (4 . "(IV)")
  (5 . "(V)") (6 . "(VI)") (7 . "(VII)") (8 . "(VIII)")
  (9 . "(IX)") (10 . "(X)") (11 . "(XI)") (12 . "(XII)") 
  (13 . "(XIII)") (14 . "(XIV)") (15 . "(XV)") (16 . "(XVI)")
  (17 . "(XVII)") (18 . "(XVIII)") (19 . "(XIX)") (20 . "(XX)")
  (21 . "(XXI)") (22 . "(XXII)") (23 . "(XXIII)") (24 . "(XXIV)")
  (25 . "(XXV)") (26 . "(XXVI)") (27 . "(XXVII)") (28 . "(XXVIII)")
  (29 . "(XXIX)") (30 . "(XXX)") (31 . "(XXXI)") (32 . "(XXXII)")
  (33 . "(XXXIII)") (34 . "(XXXIV)") (35 . "(XXXV)") (36 . "(XXXVI)")
  (37 . "(XXXVII)") (38 . "(XXXVIII)") (39 . "(XXXIX)") (40 . "(XL)")
  (41 . "(XLI)") (42 . "(XLII)") (43 . "(XLIII)") (44 . "(XLIV)")
  (45 . "(XLV)") (46 . "(XLVI)") (47 . "(XLVII)") (48 . "(XLVIII)")
  (49 . "(XLIX)") (50 . "(L)")
)
"List holding the values for roman numerals. Extend as needed.")

;;; provide mode
(provide 'imdb-adds)

;;; imdb-adds-mode.el ends here

