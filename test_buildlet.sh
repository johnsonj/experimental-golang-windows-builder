#!/usr/bin/env bash

set -e -u

hostname="$(grep ip_address instance.txt | cut -d ':' -f 2 | xargs echo -n)"
BUILDLET="windows-amd64-gce@${hostname}"

echo "Pushing GCC, go1.4, go to buildlet"
gomote puttar "$BUILDLET" gcc5-1/gcc.tar.gz
gomote put14 "$BUILDLET"

# TODO(jrjohnson): this version tries to run 'go.exe' in the the test dirs.
#                  need to determine if it's a env issue or a bug.
# gomote puttar -url https://storage.googleapis.com/golang/go1.8.src.tar.gz $BUILDLET
#
# workaround is to use this patch:
#
# diff --git a/src/cmd/dist/test.go b/src/cmd/dist/test.go
# index c51dcead2b..8e61ba2774 100644
# --- a/src/cmd/dist/test.go
# +++ b/src/cmd/dist/test.go
# @@ -657,6 +657,11 @@ func (t *tester) registerSeqTest(name, dirBanner, bin string, args ...string) {
#  }
# 
#  func (t *tester) bgDirCmd(dir, bin string, args ...string) *exec.Cmd {
# +       //TODO(jrjohnson): hack?
# +       if bin == "go" {
# +               bin = filepath.Join(t.goroot, "bin", bin)
# +       }
# +
#         cmd := exec.Command(bin, args...)
#         if filepath.IsAbs(dir) {
#                 cmd.Dir = dir
#
gomote puttar "$BUILDLET" go.tar.gz

echo "Building go"
gomote run -path '$WORKDIR\gcc\bin,$PATH' "$BUILDLET" go/src/make.bat
echo "Running tests for go"
gomote run -path '$WORKDIR\gcc\bin,$WORKDIR\go\bin,$PATH' "$BUILDLET" go/bin/go tool dist test
