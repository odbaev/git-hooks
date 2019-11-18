#!/bin/bash

# bash strict mode
set -euo pipefail

# post-checkout git hook

config_dir="$(dirname "$(dirname "$BASH_SOURCE")")"

# load default config
. "$config_dir/gh-default.cfg"

# load user config
. "$config_dir/gh-user.cfg"

# commit message file
commit_msg_file=$1

commit_msg=$(< "$commit_msg_file")

# commit type
commit_type=${2-}

case $commit_type in
    'message'|'template'|'')
        # use parameterized git commit template
        if [ "$use_commit_template" = "true" ]
        then
            # custom commit template
            template="$commit_template"

            # template parameters
            declare -A params

            params['summary']=$(head -n 1 <<< "$commit_msg")
            params['description']=$(tail -n +2 <<< "$commit_msg")

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
                if [[ $pattern && ! $param =~ ^$pattern$ ]]
                then
                    param=''
                fi

                template=${template//"$match"/$param}
            done < <(grep -Eo "$params_pattern" <<< "$template" | sort -u)

            # enable extended pattern matching
            shopt -s extglob

            # remove trailing whitespace
            template=${template%%+([[:space:]])}

            # update git commit message
            echo -n "$template" > "$commit_msg_file"
        fi
        ;;

    'merge')
        # use branch name excluding folder for merge message
        if [ "$use_short_branch_name_for_merge" = "true" ] \
            && git rev-parse -q --verify MERGE_HEAD >/dev/null
        then
            cur_branch=$(git name-rev --name-only HEAD)
            merge_branch=$(git name-rev --name-only MERGE_HEAD)

            merge_msg=${commit_msg/$cur_branch/$(basename $cur_branch)}
            merge_msg=${merge_msg/$merge_branch/$(basename $merge_branch)}

            # update git merge commit message
            echo -n "$merge_msg" > "$commit_msg_file"
        fi
        ;;
esac
