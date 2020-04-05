#!/bin/bash

# bash strict mode
set -euo pipefail

# pre-push git hook

config_dir=${BASH_SOURCE%/*/*}

# load default config
. "$config_dir/gh-default.cfg"

# load user config
. "$config_dir/gh-user.cfg"

read local_ref local_sha remote_ref remote_sha || true

cur_ref=$(git rev-parse --symbolic-full-name HEAD)

if [ "$cur_ref" = "$local_ref" ]
then
    # execute sql procedure
    if [ "$execute_sql_procedure" = "true" ]
    then
        branch=$(git rev-parse --abbrev-ref HEAD)

        declare -A sql_connections=([$dev_branch]=$dev_connection [$test_branch]=$test_connection [$preprod_branch]=$preprod_connection [$prod_branch]=$prod_connection)

        if [[ -v sql_connections[$branch] ]]
        then
            powershell -ExecutionPolicy RemoteSigned -File "${BASH_SOURCE%/*}/ps/pre-push.ps1" \
                -ConnectionString "${sql_connections[$branch]}" \
                -SqlProcedure "$sql_procedure"
        fi
    fi
fi
