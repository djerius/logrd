#! /usr/bin/env bats

load functions

# can't use setup, as we need to run tests in subshell
# so that bats' stderr/stdout aren't affected
# and that messes up the stack trace,
# (https://github.com/sstephenson/bats/issues/212)

@test "redirect stdout" {(

    set -eu
    save-fds
    source logrd.bash
    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    logfile=$tmpdir/output

    ok logrd-redirect-streams $logfile stdout '${logrd_ERRORS[*]}'

    teststr=$(date)

    echo "$teststr"

    ok logrd-restore-streams stdout '${logrd_ERRORS[*]}'

    output=$(< $logfile )

    is "$output" "$teststr" 'stdout test string'
)}


@test "redirect stderr" {(

    set -eu
    save-fds
    source logrd.bash

    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    logfile=$tmpdir/output

    ok logrd-redirect-streams  $logfile stderr '${logrd_ERRORS[*]}'

    teststr=$(date)

    echo "$teststr" >&2

    ok logrd-restore-streams stderr '${logrd_ERRORS[*]}'

    output=$(< $logfile )

    is "$output" "$teststr" 'stderr test string'
)}

@test "redirect stdlog" {(

    set -eu
    save-fds
    source logrd.bash

    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    logfile=$tmpdir/output

    ok logrd-redirect-streams  $logfile stdlog '${logrd_ERRORS[*]}'

    teststr=$(date)

    stdlog=$( logrd-get stdlog )

    echo "$teststr" >&$stdlog

    ok logrd-restore-streams stdlog '${logrd_ERRORS[*]}'

    output=$(< $logfile )

    is "$output" "$teststr" 'stdlog test string'
)}

@test "redirect stdout & stderr to same file" {(

    set -eu
    save-fds
    source logrd.bash

    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    logfile=$tmpdir/output

    ok logrd-redirect-streams $logfile stdout stderr '${logrd_ERRORS[*]}'

    teststderr="stderr $(date)"
    teststdout="stdout $(date)"

    echo "$teststderr" >&2
    echo "$teststdout"

    ok logrd-restore-streams stderr stdout '${logrd_ERRORS[*]}'

    output=$(< $logfile )

    is "$output" "$teststderr"$'\n'"$teststdout" 'test string'
)}

@test "redirect stdout & stderr to different files" {(

    set -eu
    save-fds
    source logrd.bash

    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    stdout_file=$tmpdir/stdout
    stderr_file=$tmpdir/stderr

    ok logrd-redirect-streams $stdout_file stdout '${logrd_ERRORS[*]}'
    ok logrd-redirect-streams $stderr_file stderr '${logrd_ERRORS[*]}'

    teststderr="stderr $(date)"
    teststdout="stdout $(date)"

    echo "$teststderr" >&2
    echo "$teststdout"

    ok logrd-restore-streams stderr stdout '${logrd_ERRORS[*]}'

    local stdout=$(< $stdout_file )
    is "$stdout" "$teststdout" 'stdout test string'

    local stderr=$(< $stderr_file )
    is "$stderr" "$teststderr" 'stderr test string'
)}


@test "redirect stdout & stderr & stdlog to same file" {(

    set -eu
    save-fds
    source logrd.bash

    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    logfile=$tmpdir/output

    ok logrd-redirect-streams $logfile stdout stderr stdlog '${logrd_ERRORS[*]}'

    teststderr="stderr $(date)"
    teststdout="stdout $(date)"
    teststdlog="stdlog $(date)"

    stdlog=$( logrd-get stdlog )

    echo "$teststderr" >&2
    echo "$teststdout"
    echo "$teststdlog" >&$stdlog

    ok logrd-restore-streams stderr stdout stdlog '${logrd_ERRORS[*]}'

    output=$(< $logfile )

    is "$output" "$teststderr"$'\n'"$teststdout"$'\n'"$teststdlog" 'test string'
)}

@test "redirect stdout & stderr & stdlog to different files" {(

    set -eu
    save-fds
    source logrd.bash

    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    stdout_file=$tmpdir/stdout
    stderr_file=$tmpdir/stderr
    stdlog_file=$tmpdir/stdlog

    ok logrd-redirect-streams $stdout_file stdout '${logrd_ERRORS[*]}'
    ok logrd-redirect-streams $stderr_file stderr '${logrd_ERRORS[*]}'
    ok logrd-redirect-streams $stdlog_file stdlog '${logrd_ERRORS[*]}'

    teststderr="stderr $(date)"
    teststdout="stdout $(date)"
    teststdlog="stdlog $(date)"

    stdlog=$( logrd-get stdlog )

    echo "$teststdout"
    echo "$teststderr" >&2
    echo "$teststdlog" >&$stdlog

    ok logrd-restore-streams stderr stdout stdlog '${logrd_ERRORS[*]}'

    stdout=$(< $stdout_file )
    is "$stdout" "$teststdout" 'stdout test string'

    stderr=$(< $stderr_file )
    is "$stderr" "$teststderr" 'stderr test string'

    stdlog=$(< $stdlog_file )
    is "$stdlog" "$teststdlog" 'stdlog test string'
)}

@test "redirect stdout, target is fd" {(

    set -eu
    save-fds
    source logrd.bash
    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    logfile=$tmpdir/output
    exec 200>$logfile

    ok logrd-redirect-streams --fd 200 stdout '${logrd_ERRORS[*]}'

    teststr=$(date)

    echo "$teststr"

    ok logrd-restore-streams stdout '${logrd_ERRORS[*]}'

    output=$(< $logfile )

    is "$output" "$teststr" 'stdout test string'
)}

@test "redirect stdout & stderr to fd target" {(

    set -eu
    save-fds
    source logrd.bash

    tmpdir=$(mktmpdir)

    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    logfile=$tmpdir/output
    exec 200>$logfile

    ok logrd-redirect-streams --fd 200 stdout stderr '${logrd_ERRORS[*]}'

    teststderr="stderr $(date)"
    teststdout="stdout $(date)"

    echo "$teststderr" >&2
    echo "$teststdout"

    ok logrd-restore-streams stderr stdout '${logrd_ERRORS[*]}'

    output=$(< $logfile )

    is "$output" "$teststderr"$'\n'"$teststdout" 'test string'
)}


@test "copy to console" {(

    set -eu
    save-fds

    tmpdir=$(mktmpdir)
    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    # save stdout & stderr
    exec 51>&1
    exec 52>&2
    exec 53>$tmpdir/stdlog-console

    # redirect "console"
    exec 1>$tmpdir/stdout-console
    exec 2>$tmpdir/stderr-console

    source logrd.bash --copy-to-console --stdlog-fd 53

    local -a streams=( stderr stdlog )

    local stream
    for stream in ${streams[*]}  ; do
	ok logrd-redirect-streams $tmpdir/$stream $stream '${logrd_ERRORS[*]}'
    	ok logrd-get copied_to_console $stream '${logrd_ERRORS[*]}$stream copied-to-console flag not set'
    done


    local -a teststring
    teststring[1]="stdout $(date)"
    teststring[2]="stderr $(date)"
    teststring[3]="stdlog $(date)"

    local stdlog=$( logrd-get stdlog )

    echo "${teststring[1]}"
    echo "${teststring[2]}" >&2
    echo "${teststring[3]}" >&$stdlog

    ok logrd-restore-streams ${streams[*]} '${logrd_ERRORS[*]}'

    # restore "console"
    exec 1>&51
    exec 2>&52

    for stream in ${streams[*]} ; do
    	_logrd_stream-idx $stream || error '${logrd_ERRORS[*]}'
	local idx=$_logrd_STREAM_IDX

	output=$(< $tmpdir/$stream )
	is  "$output" "${teststring[$idx]}" "$stream test string"

	output=$(< $tmpdir/${stream}-console )
	is "$output" "${teststring[$idx]}" "console $stream test string"

    done


)}

@test "copy to stream" {(

    set -eu
    save-fds

    tmpdir=$(mktmpdir)
    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir ; " ERR

    # save stdout & stderr
    exec 51>&1
    exec 52>&2
    exec 53>$tmpdir/stdlog-default

    local -a teststring

    write-output () {

	local n=$1

	teststring=( _ "stdout$n $(date)" "stderr$n $(date)" "stdlog$n $(date)" )

	echo "${teststring[1]}"
	echo "${teststring[2]}" >&2
	echo "${teststring[3]}" >&$stdlog
    }

    source logrd.bash --stdlog-fd 53

    local stream
    for stream in stdout stderr stdlog ; do
	ok logrd-redirect-streams $tmpdir/${stream}1 $stream '${logrd_ERRORS[*]}'
    done

    local stdlog=$( logrd-get stdlog )
    write-output 1
    local -a teststring1=( "${teststring[@]}" )

    for stream in stdout stderr stdlog ; do
	ok logrd-redirect-streams $tmpdir/${stream}2 --copy-to-stream $stream '${logrd_ERRORS[*]}'
    done


    local stdlog=$( logrd-get stdlog )
    write-output 2
    local -a teststring2=( "${teststring[@]}" )

    ok logrd-restore-streams stderr stdout stdlog '${logrd_ERRORS[*]}'

    for stream in stdout stderr stdlog ; do
    	_logrd_stream-idx $stream || error '${logrd_ERRORS[*]}'
	local idx=$_logrd_STREAM_IDX

	output=$(< $tmpdir/${stream}2 )
	is  "$output" "${teststring2[$idx]}" "second $stream test string"

	output=$(< $tmpdir/${stream}1 )
	is "$output" "${teststring1[$idx]}"$'\n'"${teststring2[$idx]}" "first $stream test string"

    done

)}

@test "copy to console, copy to stream" {(

    set -eu
    save-fds

    tmpdir=$(mktmpdir)
    trap "rm -rf $tmpdir" EXIT
    trap "trap - EXIT ; error See $tmpdir" ERR

    # save stdout & stderr
    exec 51>&1
    exec 52>&2
    exec 53>$tmpdir/stdlog-console

    # redirect "console"
    exec 1>$tmpdir/stdout-console
    exec 2>$tmpdir/stderr-console

    local -a teststring

    write-output () {

	local n=$1

	teststring=( _ "stdout$n $(date)" "stderr$n $(date)" "stdlog$n $(date)" )

	echo "${teststring[1]}"
	echo "${teststring[2]}" >&2
	echo "${teststring[3]}" >&$stdlog
    }

    source logrd.bash --stdlog-fd 53

    # write to stream1
    local stream
    for stream in stdout stderr stdlog ; do
	ok logrd-redirect-streams $tmpdir/${stream}1 $stream '${logrd_ERRORS[*]}'
    done


    local stdlog=$( logrd-get stdlog )
    write-output 1
    local -a teststring1=( "${teststring[@]}" )

    # write to stream1, stream2, stream-console
    for stream in stdout stderr stdlog ; do
	ok logrd-redirect-streams $tmpdir/${stream}2 --copy-to-console --copy-to-stream $stream '${logrd_ERRORS[*]}'
    done

    local stdlog=$( logrd-get stdlog )
    write-output 2
    local -a teststring2=( "${teststring[@]}" )


    # write to stream1, stream2, stream3, stream-console

    for stream in stdout stderr stdlog ; do
	ok logrd-redirect-streams $tmpdir/${stream}3 --copy-to-stream $stream '${logrd_ERRORS[*]}'
    done

    local stdlog=$( logrd-get stdlog )
    write-output 3
    local -a teststring3=( "${teststring[@]}" )

    ok logrd-restore-streams stderr stdout stdlog '${logrd_ERRORS[*]}'

    # restore "console"
    exec 1>&51
    exec 2>&52

    for stream in stdout stderr stdlog ; do
    	_logrd_stream-idx $stream || error '${logrd_ERRORS[*]}'
    	local idx=$_logrd_STREAM_IDX

    	output=$(< $tmpdir/${stream}3 )
    	is  "$output" "${teststring3[$idx]}" "${stream}3 test string"

    	output=$(< $tmpdir/${stream}2 )
    	is  "$output" "${teststring2[$idx]}"$'\n'"${teststring3[$idx]}" "${stream}2 test string"

    	output=$(< $tmpdir/${stream}-console )
    	is  "$output" "${teststring2[$idx]}"$'\n'"${teststring3[$idx]}" "${stream}-console test string"

    	output=$(< $tmpdir/${stream}1 )
    	is  "$output" "${teststring1[$idx]}"$'\n'"${teststring2[$idx]}"$'\n'"${teststring3[$idx]}" "${stream}1 test string"

    done


)}
