#! /usr/bin/env bats

load functions

@test "source default options" {(

    set -eu
    save-fds
    source logrd.bash

    is "$(logrd-get level)" warn level
    ok ! logrd-get copy_to_console copy_to_console
    ok ! logrd-get copy_to_stream  copy_to_stream
    is  "$(logrd-get starting_save_fd)"  20   starting_save_fd

)}

@test "source set options" {(

    set -eu
    save-fds

    source logrd.bash
    logrd-setup  --log-level info --copy-to-console --copy-to-stream --starting-save-fd 13

    is "$(logrd-get level)" info level
    ok logrd-get copy_to_console copy_to_console
    ok logrd-get copy_to_stream  copy_to_stream
    is "$(logrd-get starting_save_fd)"  13   starting_save_fd

)}

@test "source set=  options" {(

    set -eu
    save-fds

    source logrd.bash
    logrd-setup --log-level=info --copy-to-console --copy-to-stream --starting-save-fd=13

    is "$(logrd-get level)"  info level
    ok logrd-get copy_to_console copy_to_console
    ok logrd-get copy_to_stream  copy_to_stream
    is "$(logrd-get starting_save_fd)"  13   starting_save_fd
)}

@test "environment" {(

    set -eu
    save-fds

    export LOGRD_LOG_LEVEL=debug
    export LOGRD_COPY_TO_CONSOLE=1
    export LOGRD_COPY_TO_STREAM=1
    export LOGRD_STARTING_SAVE_FD=99

    source logrd.bash

    is "$(logrd-get level)"            debug level
    ok logrd-get copy_to_console       copy_to_console
    ok logrd-get copy_to_stream        copy_to_stream
    is "$(logrd-get starting_save_fd)"    99 starting_save_fdlevel
)}
