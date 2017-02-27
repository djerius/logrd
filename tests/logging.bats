#! /usr/bin/env bats

load functions

@test "levels" {(

    set -eu
    save-fds
    source logrd.bash

    tmpdir=$(mktmpdir)
    logfile=$tmpdir/stdlog

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    declare -a level
    level[0]=error
    level[1]=warn
    level[2]=notice
    level[3]=info
    level[4]=debug

    declare -a output
    output[0]=${level[0]}
    output[1]=${output[0]}$'\n'${level[1]}
    output[2]=${output[1]}$'\n'${level[2]}
    output[3]=${output[2]}$'\n'${level[3]}
    output[4]=${output[3]}$'\n'${level[4]}

    local idx
    for (( idx=0 ; idx < ${#level[*]} ; ++idx )) ; do

	rm -f $logfile

        ok logrd-redirect-streams $logfile stdlog '${logrd_ERRORS[*]}'
	logrd-set level ${level[$idx]}

	log-to error  ${level[0]}
	log-to warn   ${level[1]}
    	log-to notice ${level[2]}
	log-to info   ${level[3]}
	log-to debug  ${level[4]}

	ok logrd-restore-streams stdlog '${logrd_ERRORS[*]}'

	log=$(< $logfile )

	is "$log" "${output[$idx]}" 'test string'

    done

)}

@test "format" {(

    set -eu
    save-fds
    source logrd.bash

    logrd-set level warn

    tmpdir=$(mktmpdir)
    logfile=$tmpdir/stdlog

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    logrd-set level warn
    ok logrd-redirect-streams $logfile stdlog '${logrd_ERRORS[*]}'

    logrd-format-message () {
        local facility=$1
    	shift
    	echo "$facility: $@"
    }

    log-to error log1
    log-to warn  log2

    ok logrd-restore-streams stdlog '${logrd_ERRORS[*]}'

    log=$(< $logfile )

    is "$log" $'error: log1\nwarn: log2' 'test string'

)}
