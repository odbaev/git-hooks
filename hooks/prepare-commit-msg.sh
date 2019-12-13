#!/bin/bash

# bash strict mode
set -euo pipefail

# post-checkout git hook

config_dir=${BASH_SOURCE%/*/*}

# load default config
. "$config_dir/gh-default.cfg"

# load user config
. "$config_dir/gh-user.cfg"

# commit message file
commit_msg_file=$1

commit_msg=$(< "$commit_msg_file")$'\n'

# commit type
commit_type=${2-}

# enable extended pattern matching
shopt -s extglob

# trim whitespace
trim() {
    local str=$1

    # remove leading whitespace
    str=${str##+([[:space:]])}

    # remove trailing whitespace
    str=${str%%+([[:space:]])}

    echo -n "$str"
}

case $commit_type in
    'message'|'template'|'')
        # use parameterized git commit template
        if [ "$use_commit_template" = "true" ]
        then
            # custom commit template
            template="$commit_template"

            # template parameters
            declare -A params

            params['summary']=$(trim "${commit_msg%%$'\n'*}")
            params['description']=$(trim "${commit_msg#*$'\n'}")

            branch=$(git rev-parse --abbrev-ref HEAD)

            # git branch name excluding folder
            params['branch']=${branch##*/}

            # internal field separator
            IFS='|'

            # parameters pattern
            params_pattern="@(\{[^}]+})?(${!params[*]})"

            unset IFS

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

            template=$(trim "$template")

            # update git commit message
            echo -n "$template" > "$commit_msg_file"
        fi
        ;;

    'merge')
        # use branch name excluding folder for merge message
        if [ "$use_short_branch_name_for_merge" = "true" ] \
            && git rev-parse -q --verify MERGE_HEAD >/dev/null
        then
            mapfile -t branch < <(git name-rev --name-only HEAD MERGE_HEAD)

            cur_branch=${branch[0]}
            cur_branch_short=${cur_branch##*/}

            merge_branch=${branch[1]}
            merge_branch_short=${merge_branch##*/}

            merge_msg=${commit_msg/$cur_branch/$cur_branch_short}
            merge_msg=${merge_msg/$merge_branch/$merge_branch_short}

            # update git merge commit message
            echo -n "$merge_msg" > "$commit_msg_file"
        fi
        ;;
esac
