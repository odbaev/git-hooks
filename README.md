# git-hooks

Development automation using git hooks.

## Hooks

### prepare-commit-msg

* parameterized git commit template using regex  

By default, adds branch name (without folder) matching Jira Issue to commit description.

* branch name excluding folder for merge commit message

### pre-commit

* convert files to utf-8 encoding or warn which files are not utf-8 encoded
* convert tabs to spaces or warn which files have tabs
* remove trailing whitespace or warn which files have trailing whitespace
* format SQL scripts (\*.sql files)
  - remove header containing date of script generation
  - align and replace CREATE with ALTER statement for stored procedure, function, view, and trigger
  - align batch terminator at the end of script

### pre-push

* execute SQL stored procedure for modified SQL objects

## Installation

* Copy all files from this project to some directory in your git repository.
* Use [install.sh](install.sh) script to install git hooks.

## Configuration

After installation there will be user config (gh-user.cfg) added to gitignore and overriding default config ([gh-default.cfg](gh-default.cfg)).

## Uninstallation

Use [uninstall.sh](uninstall.sh) script to uninstall git hooks.

## Requirements

* Bash 4.2+ (installed with [Git for Windows](https://git-scm.com/downloads))
* PowerShell 5+ (integrated in Windows 10, [installation](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell))
* Git client supporting git hooks (e.g. [GitKraken](https://www.gitkraken.com/download), [Sourcetree](https://www.sourcetreeapp.com))
