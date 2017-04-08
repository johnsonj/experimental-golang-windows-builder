#!/bin/bash

set -e -u

declare -A public_images

public_images=( 
         ['server-2016']='windows-server-2016-dc-core-v20170214'
         ['server-2008']='windows-server-2008-r2-dc-v20170214' 
         ['server-2012']='windows-server-2012-r2-dc-core-v20170214'
       )

mkdir -p out

for image in "${!public_images[@]}"; do
    prefix=$image
    base_image=${public_images[$image]}

    BASE_IMAGE="$base_image" IMAGE_PROJECT='windows-cloud' ./rebuild.sh "$prefix" |& tee "out/${base_image}.txt" &
done


wait
