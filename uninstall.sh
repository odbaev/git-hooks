#!/bin/bash

# git hooks uninstaller

exit_command () {
    read -rep 'Press any key to exit...' -n 1
    exit 0
}

# git directory
git_dir=$(git rev-parse --git-dir)

# check for git repository existance
if [ $? -ne 0 ]
then
    echo >&2
    exit_command
fi

# git hooks directory
git_hooks_dir="$git_dir/hooks"

# checking non-empty git hooks directory exists
if [ ! -d "$git_hooks_dir" ] || [ ! "$(find "$git_hooks_dir" -maxdepth 1 -type f -not -name "*.*")" ]
then
    echo "\".git/hooks\" directory doesn't exist or is empty." >&2
    echo >&2
    exit_command
fi

# git commit template
git_commit_template="$git_dir/commit-template.txt"

for file in "$git_hooks_dir"/*
do
    file_name=$(basename "$file")

    # check for file without extension
    if [[ $file_name == *.* ]]
    then
        continue
    fi

    hook_name="${file_name%%.*}"
    
    echo "Git hook: $hook_name"

    read -rep 'Uninstall it? (y/n) ' -n 1

    if [[ ! $REPLY =~ ^[yY]$ ]]
    then
        echo
        continue
    fi

    # remove git hook
    rm "$file"

    # check for successful git hook removal
    if [ $? -ne 0 ]
    then
        echo >&2
        continue
    fi

    # remove commit template
    if [ "$hook_name" = "post-checkout" ]
    then
        rm "$git_commit_template"
    fi

    echo 'Git hook removed.'
    echo
done

read -rep 'Press any key to exit...' -n 1
