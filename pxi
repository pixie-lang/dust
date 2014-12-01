#!/bin/bash

base_path=`dirname $0`
pixie_path="$base_path/pixie-vm"

function load_path() {
    load_path=""
    if [ -f "project.pxi" ]; then
        load_path="`$pixie_path $base_path/run.pxi load-path option`"
    fi
    echo $load_path
}

case $1 in
    "get-deps")
        $pixie_path $base_path/run.pxi $@ | sh
        ;;
    ""|"repl")
        rlwrap -a -n $pixie_path `load_path`
        ;;
    "run")
        shift
        file=$1
        shift
        $pixie_path `load_path` $file $@
        ;;
    -h|--help)
        $pixie_path $base_path/run.pxi help
        ;;
    *)
        $pixie_path $base_path/run.pxi $@
        ;;
esac
