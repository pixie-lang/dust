#!/bin/bash

base_path=`dirname $0`
pixie_path=`which pixie-vm`
run_pxi="$pixie_path $base_path/run.pxi"

function load_path() {
    load_path=""
    if [ -f "project.pxi" ]; then
        load_path="`$run_pxi load-path option`"
    fi
    echo $load_path
}

case $1 in
    "get-deps")
        $run_pxi $@ | sh
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
        $run_pxi help
        ;;
    *)
        $run_pxi $@
        ;;
esac
