#!/bin/bash

# bash strict mode
set -euo pipefail

# post-checkout git hook

config_dir="$(dirname "$(dirname "$BASH_SOURCE")")"

# load default config
. "$config_dir/gh-default.cfg"

# load user config
. "$config_dir/gh-user.cfg"

# checkout type (1 - branch, 0 - file)
checkout_type=$3

# check for branch checkout
if [ "$checkout_type" -eq 1 ]
then
    # git commit template
    git_commit_template="$(git config commit.template || true)"

    # git hooks commit template
    gh_commit_template="$(git rev-parse --absolute-git-dir)/gh-commit-template.txt"

    # use parameterized git commit template
    if [ "$use_commit_template" = "true" ]
    then
        # set git commit template
        if [ "$git_commit_template" != "$gh_commit_template" ]
        then
            git config commit.template "$gh_commit_template"
        fi

        # custom commit template
        template="$commit_template"

        # template parameters
        declare -A params

        params['summary']=''
        params['description']=''

        # git branch name excluding folder
        params['branch']=$(basename $(git rev-parse --abbrev-ref HEAD))

        # internal field separator
        IFS='|'

        # parameters pattern
        params_pattern="@({.+})?(${!params[*]})"

        # template parameter substitution
        while read -r match
        do
            [[ $match =~ ^@({(.+)})?(.+)$ ]]

            param=${params[${BASH_REMATCH[3]}]}
            pattern=${BASH_REMATCH[2]}

            # check if template parameter matches pattern
            if [ $pattern ] && [[ ! $param =~ ^$pattern$ ]]
            then
                param=''
            fi

            template=${template//"$match"/$param}
        done < <(grep -Eo "$params_pattern" <<< "$template" | sort -u)

        # enable extended pattern matching
        shopt -s extglob

        # remove trailing whitespace
        template=${template%%+([[:space:]])}

        # update git commit template
        echo -n "$template" > "$gh_commit_template"
    else
        # unset git commit template
        if [ "$git_commit_template" = "$gh_commit_template" ]
        then
            git config --unset commit.template
        fi
    fi
fi
