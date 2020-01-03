#!/bin/bash

# bash strict mode
set -euo pipefail

# pre-commit git hook

config_dir=${BASH_SOURCE%/*/*}

# export variables and functions
set -a

# load default config
. "$config_dir/gh-default.cfg"

# load user config
. "$config_dir/gh-user.cfg"

# create temp directory
tmp_dir=$(mktemp -d --suffix=-gh)

# cleanup on exit
trap "rm -rf $tmp_dir" EXIT

process_file() {
    file=$1

    need_warn="false"

    tmp_file="$tmp_dir/${file##*/}"

    # use utf-8 encoding
    if [ "$use_utf8_encoding" = "true" ]
    then
        file_encoding=$(file -b --mime-encoding "$file")

        if [[ ! $file_encoding =~ ^utf-8|us-ascii$ ]]
        then
            # check for warning when file is not utf-8 encoded
            if [ "$warn_file_not_utf8_encoded" = "false" ]
            then
                case $file_encoding in
                    'binary')
                        file_encoding='utf-16'
                        ;;
                    'iso-8859-1')
                        file_encoding='cp1251'
                        ;;
                esac

                # convert file to utf-8 encoding
                iconv -f $file_encoding -t utf-8 "$file" > "$tmp_file"
                mv -f "$tmp_file" "$file"
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
            else
                echo "$file: has tabs."
                need_warn="true"
            fi
        fi
    fi

    sed_commands=''

    nl='\n'

    # check for CRLF
    if grep -q -P '\r' "$file"
    then
        nl='\r'$nl
    fi

    # remove trailing whitespace
    if [ "$remove_trailing_whitespace" = "true" ]
    then
        if grep -q -P '\h\r?$' "$file"
        then
            if [ "$warn_file_has_trailing_whitespace" = "false" ]
            then
                sed_commands+="s/[[:blank:]]+$nl/$nl/g;"
            else
                echo "$file: has trailing whitespace."
                need_warn="true"
            fi
        fi
    fi

    if [ "$sed_commands" ]
    then
        sed -i -z -b -E "$sed_commands" "$file"
    fi

    # prevent commit on warning
    if [ "$need_warn" = "true" ]
    then
        return 1
    fi
}

set +a

# staged processed files
staged_files=$(git diff --cached --name-only --diff-filter=AM | grep -E "^$processed_files$" || true)

if [ "$staged_files" ]
then
    # file processing
    echo "$staged_files" | xargs -n 1 -P 0 -I {} bash -c 'set -euo pipefail; process_file "$@"' _ {}

    # add files to index after processing
    git add $staged_files
fi
