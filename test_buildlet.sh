#!/usr/bin/env bash
set -e -u

hostname="$1"
BUILDLET="windows-amd64-gce@${hostname}"

echo "Pushing GCC, go1.4, go to buildlet"
gomote puttar -url https://storage.googleapis.com/godev/gcc5-1.tar.gz  "$BUILDLET" 
gomote puttar -url https://storage.googleapis.com/golang/go1.8.src.tar.gz "$BUILDLET"
gomote put14 "$BUILDLET"

echo "Building go"
gomote run -path '$PATH,$WORKDIR/gcc/bin,$WORKDIR/go/bin,$PATH' -e 'GOROOT=c:\workdir\go' "$BUILDLET" go/src/make.bat
echo "Running tests for go"
gomote run -path '$WORKDIR/gcc/bin,$WORKDIR/go/bin,$PATH' -e 'GOROOT=C:\workdir\go' "$BUILDLET" go/bin/go.exe test cmd/go -short
