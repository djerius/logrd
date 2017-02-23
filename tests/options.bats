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

    unset LOGRD_STARTING_SAVE_FD
    source logrd.bash --log-level info --copy-to-console --copy-to-stream --starting-save-fd 13

    is "$(logrd-get level)" info level
    ok logrd-get copy_to_console copy_to_console
    ok logrd-get copy_to_stream  copy_to_stream
    is "$(logrd-get starting_save_fd)"  13   starting_save_fd

)}

@test "source set=  options" {(

    set -eu
    save-fds

    unset LOGRD_STARTING_SAVE_FD
    source logrd.bash --log-level=info --copy-to-console --copy-to-stream --starting-save-fd=13

    is "$(logrd-get level)"  info level
    ok logrd-get copy_to_console copy_to_console
    ok logrd-get copy_to_stream  copy_to_stream
    is "$(logrd-get starting_save_fd)"  13   starting_save_fd
)}
