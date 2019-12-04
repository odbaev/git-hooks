#!/bin/bash

# bash strict mode
set -euo pipefail

# pre-commit git hook

config_dir="$(dirname "$(dirname "$BASH_SOURCE")")"

# load default config
. "$config_dir/gh-default.cfg"

# load user config
. "$config_dir/gh-user.cfg"

# create temp directory
tmp_dir=$(mktemp -d --suffix=-gh)

# cleanup on exit
trap "rm -rf $tmp_dir" EXIT

need_warn="false"

# file processing
while read -r file
do
    if ! [[ -f $file && $file =~ ^$processed_files$ ]]
    then
        continue
    fi

    file_changed="false"

    file_name=$(basename "$file")
    tmp_file="$tmp_dir/$file_name"

    # use utf-8 encoding
    if [ "$use_utf8_encoding" = "true" ]
    then
        file_encoding=$(file -b --mime-encoding "$file")

        if [[ ! $file_encoding =~ ^utf-8|us-ascii$ ]]
        then
            # check for warning when file is not utf-8 encoded
            if [ "$warn_file_not_utf8_encoded" = "false" ]
            then
                if [ "$file_encoding" = "binary" ]
                then
                    file_encoding="utf-16"
                elif [ "$file_encoding" = "iso-8859-1" ]
                then
                    file_encoding="cp1251"
                fi

                # convert file to utf-8 encoding
                iconv -f $file_encoding -t utf-8 "$file" > "$tmp_file"
                mv -f "$tmp_file" "$file"

                file_changed="true"
            else
                echo "$file: not utf-8 encoded."
                need_warn="true"
            fi
        fi
    fi

    # use spaces instead of tabs
    if [ "$use_spaces_for_tabs" = "true" ]
    then
        if grep -q $'\t' "$file"
        then
            if [ "$warn_file_has_tabs" = "false" ]
            then
                # convert tabs to spaces
                expand -t $tab_size "$file" > "$tmp_file"
                mv -f "$tmp_file" "$file"

                file_changed="true"
            else
                echo "$file: has tabs."
                need_warn="true"
            fi
        fi
    fi

    if [ "$file_changed" = "true" ]
    then
        git add "$file"
    fi
done <<< $(git diff --cached --name-only --diff-filter=AM)

# prevent commit on warning
if [ "$need_warn" = "true" ]
then
    exit 1
fi
