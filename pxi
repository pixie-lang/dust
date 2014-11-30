#!/bin/bash

base_path=`dirname $0`
pixie_path="$base_path/pixie-vm"

case $1 in
    describe)
        $pixie_path $base_path/run.pxi describe
        ;;
    *)
        echo "Unknown command: $1"
        exit 1
        ;;
esac
