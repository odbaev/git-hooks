#!/bin/bash

# post-checkout git hook

# checkout type (1 - branch, 0 - file)
checkout_type=$3

# use parameterized git commit template

# check for branch checkout
if [ $checkout_type -ne 1 ]
then
    exit 0
fi

# git commit template
git_commit_template="$(git rev-parse --git-dir)/commit-template.txt"

# custom commit template
commit_template="$(dirname "$(dirname "$BASH_SOURCE")")/commit-template.txt"

if [ ! -f "$commit_template" ]
then
    echo "Commit template doesn't exist." >&2
    exit 1
fi

template=$(< "$commit_template")

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
echo -n "$template" > "$git_commit_template"
