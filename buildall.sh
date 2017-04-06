#!/bin/bash

set -e
set -u

images=( 
         "windows-server-2016-dc-core-v20170214"
         "windows-server-2008-r2-dc-v20170214" 
         "windows-server-2012-r2-dc-core-v20170214"
       )

for image in "${images[@]}"; do
    echo $image
    IMAGE=${image} ./rebuild.sh
    mkdir -p out
    ./test_buildlet.sh |& tee out/${image}.txt
done
