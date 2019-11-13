#!/bin/bash

# git hooks installer

exit_command () {
    read -rep 'Press any key to exit...' -n 1
    exit 0
}

# git directory
git_dir=$(git rev-parse --absolute-git-dir)

# check for git repository existance
if [ $? -ne 0 ]
then
    echo >&2
    exit_command
fi

# git hooks directory
git_hooks_dir="$git_dir/hooks"

# create git hooks directory if it doesn't exist
mkdir -p "$git_hooks_dir"

#install directory
install_dir="$(dirname "$(realpath "$BASH_SOURCE")")"

# custom git hooks directory
hooks_dir="$install_dir/hooks"

# checking non-empty git hooks directory exists
if [ ! -d "$hooks_dir" ] || [ ! "$(find "$hooks_dir" -maxdepth 1 -type f -not -name ".*")" ]
then
    echo "\"hooks\" directory doesn't exist or is empty!" >&2
    echo >&2
    exit_command
fi

# git repository dir
repo_dir=$(git rev-parse --show-toplevel)

# git hooks user config
user_config="$install_dir/gh-user.cfg"

cfg_desc='# git hooks user config'

# add user config to gitignore
if ! git check-ignore -q "$user_config"
then
    user_cfg_repo_rel="/$(realpath --relative-to="$repo_dir" "$user_config")"
    printf "\n$cfg_desc\n$user_cfg_repo_rel\n" >> "$repo_dir/.gitignore"
fi

# create user config
if [ ! -f "$user_config" ]
then
    printf "$cfg_desc (overrides default config)\n" > "$user_config"
fi

# shebang interpreter directive
interpreter='#!/bin/bash'

for file in "$hooks_dir"/*
do
    # check for regular file
    if [ ! -f "$file" ]
    then
        continue
    fi

    file_name=$(basename "$file")
    hook_name="${file_name%%.*}"

    echo "Git hook: $hook_name"

    git_hook="$git_hooks_dir/$hook_name"

    # link to custom git hook script
    hook_script=$(printf "$interpreter\n\n. '$file'\n")

    # check for the git hook existance with different content
    if [ -f "$git_hook" ] && [ "$hook_script" != "$(< "$git_hook")" ]
    then
        read -rep 'Git hook already exists! Replace it? (y/n) ' -n 1
        
        if [[ ! $REPLY =~ ^[yY]$ ]]
        then
            echo
            continue
        fi
    fi

    # create git hook
    echo "$hook_script" > "$git_hook"

    # check for successful git hook creation
    if [ $? -ne 0 ]
    then
        echo >&2
        continue
    fi

    # create commit template
    if [ "$hook_name" = "post-checkout" ]
    then
        "$git_hook" "" "" 1 >/dev/null

        if [ $? -ne 0 ]
        then
            echo >&2
            continue
        fi
    fi

    echo 'Git hook created.'
    echo
done

exit_command
