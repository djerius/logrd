#!/bin/bash -u

################################################################################
#
#  output things.

_logrd_LOG_LEVELS=( error warn notice info debug )

_logrd_create-log-facilities () {

    local loglevel=0
    local facility
    for facility in ${_logrd_LOG_LEVELS[*]} ; do

	local var=LOG_$facility
	local log_level=$(( loglevel++ ))

        eval $var=$log_level
	eval \
	    log-$facility '() {'                                \
	    "if (( _logrd_LOG_LEVEL >= $log_level )); then"     \
	    "local fd=\${_logrd_REDIR_FD[$_logrd_stdlog_idx]};" \
	    "echo \"\$@\">&\$fd ;"				\
	    "fi;" \						\
	    "}"

    done

    # redefine die() to use log facility
    # first level is error
    local err=${_logrd_LOG_LEVELS[0]}

    eval					\
    	'die () {'				\
    	    "log-$err \"\$@\" ;"		\
    	    'exit 1 ;'				\
        "}"
}

_logrd_level_to_int () {
    local var=LOG_${1}
    echo ${!var:-0}
}

die () {
    echo >&2 "$@"
    exit 1
}

# override value in variable named _logrd_${1} from variable with name
# ${_logrd_ENV_PREFIX}${1} if the latter is set or not null
_logrd_set-var-from-env () {

    local var=$1

    local logrd_var=_logrd_$1
    local env_var=${_logrd_ENV_PREFIX}${1}

    eval "${logrd_var}=${!env_var:-${!logrd_var}}"
}

_logrd_error () {

    local errorstr="${BASH_SOURCE[1]}:${BASH_LINENO[1]} called ${FUNCNAME[1]}: $@"$'\n'
    logrd_ERRORS=$errorstr
    return 1
}

_logrd_errors () {

    local errorstr="${BASH_SOURCE[1]}:${BASH_LINENO[1]} called ${FUNCNAME[1]}: $@"$'\n'
    logrd_ERRORS+=( "$errorstr" )
    return 1
}

################################################################################
#
# Logging

# can't assume associative arrays. thanks Apple.
_logrd_set_attr_level=1

logrd-set () {

    local attr=$1 ; shift
    local var=_logrd_set_attr_$attr

    if (( ${!var:-0} )) ; then
	eval _logrd_set-$attr "$@" || _logrd_error "error setting attribute: $attr"
    else
	_logrd_error "unknown attribute or unsettable attribute: $attr"
    fi
}

_logrd_set-level () {

    local level=$(_logrd_level_to_int "$1")

    [[ $level != '' ]]				\
	&& _logrd_LOG_LEVEL=$level		\
	|| _logrd_error "unknown log level: $1"
}

# can't assume associative arrays. thanks Apple.
_logrd_get_attr_level=1
_logrd_get_attr_copy_to_console=1
_logrd_get_attr_copy_to_stream=1
_logrd_get_attr_copied_to_console=1
_logrd_get_attr_starting_save_fd=1
_logrd_get_attr_stdlog=1

logrd-get () {

    local attr=$1
    local var=_logrd_get_attr_$attr

    if (( ${!var:-0} )) ; then
	shift
	_logrd_get-$attr "$@"
    else
	_logrd_error "can't retrieve attribute '$attr'"
    fi
}


_logrd_get-level () {
    echo ${_logrd_LOG_LEVELS[$_logrd_LOG_LEVEL]}
}

_logrd_get-copy_to_console () {
    (( _logrd_COPY_TO_CONSOLE ))
}

_logrd_get-copy_to_stream () {
    (( _logrd_COPY_TO_STREAM ))
}

_logrd_get-starting_save_fd () {
    echo $_logrd_STARTING_SAVE_FD
}

_logrd_get-stdlog () {
    echo ${_logrd_REDIR_FD[$_logrd_stdlog_idx]}
}

_logrd_get-copied_to_console () {

    _logrd_stream-idx $1 && (( ${_logrd_COPIED_TO_CONSOLE[$_logrd_STREAM_IDX]} ))
}

declare -a logrd_ERRORS
_logrd_reset-errors () {
    logrd_ERRORS=()
}

logrd_has-error () { (( ${#logrd_ERRORS[*]} )); }

################################################################################
# Redirection of stdout/stderr
# we rely upon running commands in subshells to avoid
# needing to keep a stack of redirections.

# index into our FD arrays for the various output streams. can't use
# associative arrays. Thanks Apple.
_logrd_stdout_idx=1
_logrd_stderr_idx=2
_logrd_stdlog_idx=3

declare _logrd_STREAM_IDX
_logrd_stream-idx () {
    local var=_logrd_${1}_idx
    _logrd_STREAM_IDX=${!var:-}

    [[ $_logrd_STREAM_IDX != '' ]] || _logrd_error "unknown stream: $1" || return
}

declare -a _logrd_SAVED_FD
declare -a _logrd_REDIR_FD

_logrd_dup-fd () {
    local dst=${1#/dev/fd/}
    local src=${2#/dev/fd/}

    # bash 3.x won't close $dst before redirection, and the redirect
    # will silently fail.
    _logrd_close-fd $dst

    eval "exec $dst>&$src" || _logrd_errors "error duping: $1>&$2"
}

_logrd_move-fd () {
    local dst=${1#/dev/fd/}
    local src=${2#/dev/fd/}

    # bash 3.x won't close $dst before redirection, and the redirect
    # will silently fail.
    _logrd_close-fd $dst

    eval "exec $dst>&$src-" || _logrd_errors "error moving: $1>&$2-"
}

_logrd_redirect-fd () {
    local dst=${1#/dev/fd/}

    # bash 3.x won't close $dst before redirection, and the redirect
    # will silently fail.
    _logrd_close-fd $dst
    eval "exec $dst>$2" || _logrd_errors "error redirecting: $1>$2"
}


_logrd_close-fd () {
    local fd=${1#/dev/fd/}
    eval "exec $fd>&-" || _logrd_errors "error closing $1"
}

_logrd_close-fds () {

    error=0
    local fd
    for fd; do
	_logrd_close-fd $fd || error=1
    done

    (( ! error )) || return 1
}

# tee-fd () {
#     eval "redirect-fd \$1 >(tee >&$2 >( cat >& $3 ) )"
# }


_logrd_tee-fd () {
    local  redir_fd=$1 tee=$2 thru=$3

    local code="_logrd_redirect-fd $redir_fd >(tee -a >( cat >$tee ) >$thru )"
    eval "$code" || _logrd_errors "error creating tee: $code"
}

# indicates whether a stream has been redirected to the  console
declare -a _logrd_COPIED_TO_CONSOLE

_logrd_reset-copied-to-console-status () {
    _logrd_COPIED_TO_CONSOLE=( 0 0 0 0 )
}

# results for reserve-fds are stored here
declare -a _logrd_RESERVE_FDS

# atomicaly reserve a set of fd's later bash's allow {foo}>&n; this is
# for those that don't (that's you, Apple)
_logrd_reserve-fds () {

   local nfds=$#
   local -a dups="$@"
   local fd=$(( _logrd_STARTING_SAVE_FD - 1 ))

   local -a FD

   local found
   local reserve=dup
   local target
   for target; do

       (( fd < 255 )) || break

       case $target in

	   --redirect)
	       reserve=redirect
	       continue
	       ;;

	   --dup)
	       reserve=dup
	       continue
	       ;;

       esac

       found=0
       while (( !found && ++fd < 255 )) ; do
	   if [[ ! -e /dev/fd/$fd ]] ; then
	       _logrd_${reserve}-fd $fd $target || break
	       FD+=( $fd )
	       found=1
	   fi
       done

       (( ! found )) && break
   done

   # rollback reservations if we've failed to reserve enough
   if (( !found )); then

       _logrd_close-fds ${FD[*]}
       _logrd_errors "failed to reserve enough file descriptors"
       return 1
   fi

   _logrd_RESERVE_FDS=( ${FD[*]} )
   return 0
}

# operates on these global arrays
declare -a _logrd_RESTORE_FDS_DUPS
declare -a _logrd_RESTORE_FDS_ORIG

_logrd_restore-fds () {

    local nfds=${#_logrd_RESTORE_FDS_DUPS[*]}

    (( nfds == ${#_logrd_RESTORE_FDS_ORIG[*]} )) || _logrd_errors "inconsistent inputs" || return

    local idx=-1
    local -a errors
    while (( ++idx < nfds )); do

    	_logrd_move-fd ${_logrd_RESTORE_FDS_ORIG[$idx]} ${_logrd_RESTORE_FDS_DUPS[$idx]} || errors+=( $_{logrd_RESTORE_FDS_ORIG[$idx]} )
    done

    (( ! ${#errors[*]} )) || _logrd_errors  "error restoring fds: ${errors[*]}" || return
}


# save original FD's
_logrd_save-fds () {

    # save the current fd's
    _logrd_reserve-fds  1 2 $_logrd_STDLOG_FD || _logrd_errors "error saving current fds" || return
    local -a saved_fds=( ${_logrd_RESERVE_FDS[*]} )

    # set up an array which contains the fd's for stdin stdout stdlog
    # that should be used in redirections.  need to create a new fd
    # for stdlog that points to the current stdlog output. these will
    # never change
    if _logrd_reserve-fds $_logrd_STDLOG_FD ; then
	local -a redir_fds=( 1 2 ${_logrd_RESERVE_FDS} )
    else
	_logrd_close-fds ${saved_fds[*]}
	return 1
    fi

    _logrd_SAVED_FD=( _ ${saved_fds[*]} )
    _logrd_REDIR_FD=( _ ${redir_fds[*]} )

    return 0
}

_logrd_setup () {

    _logrd_set-var-from-env COPY_TO_CONSOLE
    _logrd_set-var-from-env COPY_TO_STREAM
    _logrd_set-var-from-env STARTING_SAVE_FD
    _logrd_set-var-from-env STDLOG_FD

    _logrd_save-fds

    _logrd_reset-copied-to-console-status

    _logrd_create-log-facilities

    # this is a bit of a cheat, as _logrd_LOG_LEVEL normally is an
    # integer, and the passed log level is a string
    _logrd_set-var-from-env LOG_LEVEL

    # set log level and make _logrd_LOG_LEVEL an integer
    logrd-set level ${_logrd_LOG_LEVEL}

    return 0
}


# restore streams to original fd's
_logrd_restore-stream () {

    _logrd_stream-idx $1 || _logrd_error "can't restore stream" || return
    local idx=_logrd_STREAM_IDX

    local redir_fd=${_logrd_REDIR_FD[$idx]}
    local saved_fd=${_logrd_SAVED_FD[$idx]}

    _logrd_dup-fd  $redir_fd $saved_fd || _logrd_errors "error restoring fd $redir_fd to $saved_fd" || return

    _logrd_COPIED_TO_CONSOLE[$idx]=0

    return 0
}

logrd-restore-streams () {

    local error=0
    local stream

    for stream ; do
	_logrd_restore-stream $stream || error=1
    done

    (( ! error )) || return 1
}

logrd-redirect-streams () {

    _logrd_reset-errors

    local -a copy_to_console=( $_logrd_COPY_TO_CONSOLE )
    local -a copy_to_stream=( $_logrd_COPY_TO_STREAM )

    local file=$1
    shift

    [[ $file != '' ]] || _logrd_error "file parameter was not specified" || return

    local var
    local idx
    local -a fds
    local -a fd_idx
    local dup_fd

    # ensure that the passed streams are legit
    local stream
    idx=0
    for stream ; do

	case $stream in

	    --copy-to-console )
		copy_to_console[$idx]=1
		continue
		;;

	    --no-copy-to-console )
		copy_to_console[$idx]=0
		continue
		;;

	    --copy-to-stream )
		copy_to_stream[$idx]=1
		continue
		;;

	    --no-copy-to-stream )
		copy_to_stream[$idx]=0
		continue
		;;

	esac

	_logrd_stream-idx $stream || _logrd_errors "unknown stream" || continue
	idx=_logrd_STREAM_IDX

	fd_idx+=( $idx )
	fds+=( ${_logrd_REDIR_FD[$idx]} )

	copy_to_console[$idx]=$copy_to_console
	copy_to_stream[$idx]=$copy_to_stream
    done

    logrd_has-error && return 1

    # save current streams in case we need to revert everything
    _logrd_reserve-fds  ${fds[*]} \
	|| _logrd_errors "error making backup of current streams"

    local -a dups=( ${_logrd_RESERVE_FDS[*]} )

    # create a single fd to redirect to file, then dup it for
    # all of the streams


    local nfds=${#fds[*]}

    # if only one stream is being redirected, can just perform a
    # redirection to the file.  however, if more than one stream is redirected
    # to the same file, need to create an fd which redirects to the file and
    # dup it for each output steam

    local file_redir
    if (( nfds == 1 )) ; then
	file_redir=">$file"
    else
	_logrd_reserve-fds --redirect $file
	local file_fd=${_logrd_RESERVE_FDS#/dev/fd/}
	file_redir="&$file_fd"
    fi


    for (( idx=0; idx < nfds ; ++idx )) ; do

 	local fd=${fds[$idx]}
	local fidx=${fd_idx[$idx]}
	local copied_to_console=${_logrd_COPIED_TO_CONSOLE[$fidx]}
	local console_fd=${_logrd_SAVED_FD[$fidx]}

	# copied      copy         copy
        # to_console  to_console   to_stream
        # 0           0            0           => fd > file
        # 1           0            0           => fd > >(tee dup_fd  > file )
        # 0           1            0           => fd > >(tee console > file )
        # 1           1            0           => fd > >(tee dup_fd  > file )
        # 0           0            1           => fd > >(tee dup_fd  > file )
        # 1           0            1           => fd > >(tee dup_fd  > file )
        # 0           1            1           => fd > >(tee >(tee dup_fd > console ) > file )
        # 1           1            1           => fd > >(tee dup_fd  > file )

	# or

        # 0           0            0           => fd > file
        # 0           1            0           => fd > >(tee console > file )
        # 0           1            1           => fd > >(tee >(tee dup_fd > console ) > file )

	# everything else
        # ?           ?            ?           => fd > >(tee dup_fd  > file )



	if (( ! copied_to_console && ! copy_to_console && ! copy_to_stream )) ; then

	    _logrd_redirect-fd $fd $file_redir || break

	elif (( ! copied_to_console && copy_to_console && ! copy_to_stream )) ; then

	    _logrd_tee-fd $fd "&$console_fd" $file_redir || break

	elif (( ! copied_to_console && copy_to_console && copy_to_stream )) ; then

	    _logrd_reserve-fds --dup $fd $fd || break

	    dup_fd=${_logrd_RESERVE_FDS[0]}
	    tmp_fd=${_logrd_RESERVE_FDS[1]}
	    _logrd_tee-fd $tmp_fd "&$dup_fd" "&$console_fd" || break
	    _logrd_tee-fd $fd "&$tmp_fd" $file_redir || break

	else

	    _logrd_reserve-fds --dup $fd || break
	    dup_fd=$_logrd_RESERVE_FDS
	    _logrd_tee-fd $fd "&$dup_fd" $file_redir || break

	fi

	# this must happen regardless of dispatch table
	(( copy_to_console )) && _logrd_COPIED_TO_CONSOLE[$fidx]=1

    done

    if logrd_has-error; then

	_logrd_RESTORE_FDS_DUPS=( ${dups[*]} )
	_logrd_RESTORE_FDS_ORIG=( ${fds[*]} )
	_logrd_restore-fds

	_logrd_errors "unable to redirect streams"
	return 1
    fi

    return 0
}

################################################################################

_logrd_ENV_PREFIX=LOGRD_
_logrd_STARTING_SAVE_FD=20
_logrd_LOG_LEVEL=warn
_logrd_COPY_TO_CONSOLE=0
_logrd_COPY_TO_STREAM=0
_logrd_STDLOG_FD=2

while (( $#  )) ;
do
    case "$1" in

	--copy-to-console)
	    _logrd_COPY_TO_CONSOLE=1
	    ;;

       --no-copy-to-console)
	    _logrd_COPY_TO_CONSOLE=0
	    ;;

       --copy-to-stream)
	    _logrd_COPY_TO_STREAM=1
            ;;

       --no-copy-to-stream)
	    _logrd_COPY_TO_STREAM=0
            ;;

	-q|--quiet )
	    _logrd_LOG_LEVEL=error
	    ;;

	--env-prefix)
	    shift
	    _logrd_ENV_PREFIX=$1
	    ;;

	--env-prefix=*)
	    _logrd_ENV_PREFIX=${1:#--env-prefix=}
	    ;;

	--starting-save-fd)
	    shift
	    _logrd_STARTING_SAVE_FD=$1
	    ;;

	--starting-save-fd=*)
	    _logrd_STARTING_SAVE_FD=${1#--starting-save-fd=}
	    ;;

	--stdlog-fd)
	    shift
	    _logrd_STDLOG_FD=$1
	    ;;

	--stdlog-fd=*)
	    _logrd_STDLOG_FD=${1#--stdlog-fd=}
	    ;;

	--log-level)
	    shift
	    _logrd_LOG_LEVEL=$1
	    ;;

	--log-level=*)
	    _logrd_LOG_LEVEL=${1#--log-level=}
	    ;;

	*)
	   die "uknown option to logrd: $1"
	   ;;

    esac

    shift

done

_logrd_setup


