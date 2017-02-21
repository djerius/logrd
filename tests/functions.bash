
# save stdout & stderr
save-fds () {
    local start=${1:-101}

    eval "exec $(( start ))>&1"
    eval "exec $(( start + 1 ))>&2"
}

restore-fds () {
    exec 1>&101
    exec 2>&102
}

error () { echo  >&102 "ERROR: $@" ; return 1 ; }

ok () {
    local -a args=( "$@" )
    local last=$(( ${#args[*]} - 1 ))
    local message=${args[$last]}
    unset args[$last]

    eval "${args[@]}" || eval error "$message"
}

is () {

    local got=$1 expected=$2
    shift 2

    [[ $got == $expected ]] || {
	error "$@"			\
	      $'\n' "     got: $got"		\
	      $'\n' "expected: $expected"
    }

}


################################################################################
# a generic temporary directory script which works on most platforms
mktmpdir () {
    mktemp -d -t logrd.XXXXXXX
}

save-fds 151

DEBUG () { echo  >&152 "DEBUG: $@" ; }
DEBUG-EXEC () { eval "$@" | sed >&152 "s/./DEBUG: &/" ; }
