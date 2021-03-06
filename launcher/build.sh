#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Create output folder
mkdir -p $DIR/dist

cd $DIR

GOOS=darwin GOARCH=amd64 go build -o dist/introspector_osx

GOOS=darwin GOARCH=arm64 go build -o dist/introspector_osx_m1

GOOS=linux GOARCH=amd64 go build -o dist/introspector_linux
