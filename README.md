# git-hooks

Development automation using git hooks.

## Hooks

### post-checkout

* parameterized git commit template using regex  

By default, adds branch name (without folder) matching Jira Issue to commit description.

## Installation

* Copy all files from this project to some directory in your git repository.
* Use [install.sh](install.sh) script to install git hooks.

## Configuration

After installation there will be user config (gh-user.cfg) added to gitignore and overriding default config ([gh-default.cfg](gh-default.cfg)).

## Uninstallation

Use [uninstall.sh](uninstall.sh) script to uninstall git hooks.

## Requirements

* Bash (installed with [Git for Windows](https://git-scm.com/downloads))
* Git client supporting git hooks and commit message templates (e.g. [GitKraken](https://www.gitkraken.com/download))
