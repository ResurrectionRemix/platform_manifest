#!/bin/bash
# To be run from the root of the build tree.
# NOT FROM THE PLATFORM_MANIFEST DIRECTORY!!!
# -KhasMek

manifest=.repo/local_manifests/kernel_manifest.xml

echo "adding kernel repos to your build tree"

if [ ! -d ".repo/local_manifests" ]; then
    mkdir ".repo/local_manifests"
fi

# Safely merge depricated local_manifest.xml
if [ -f ".repo/local_manifest.xml" ]; then
    mv .repo/local_manifest.xml .repo/local_manifests/local_manifest.xml
    tail -n +3 platform_manifest/kernel_manifest.xml | head -n -1 | while read line
    do
        # See if there are dublicate entries, remove from local_manifest if true
        chickenfucker=`grep "$line" .repo/local_manifests/local_manifest.xml`
        if [ -n "$chickenfucker" ]; then
            fuckedchicken=$(echo "$line" |sed 's!\(\/\)!\\\1!g')
            sed -i "/$fuckedchicken/d" .repo/local_manifests/local_manifest.xml
            if [ `cat .repo/local_manifests/local_manifest.xml | wc -l` = 3 ]; then
                rm .repo/local_manifests/local_manifest.xml
            fi
        fi
    done
fi

if [ -f $manifest ]; then
        echo "kernel manifest already present."
        echo "merging kernel manifests."
        cat platform_manifest/kernel_manifest.xml | while read line
        do
                kernel=`grep "$line" $manifest`
                if [ -z "$kernel" ]; then
                        echo "  $line" >> $manifest
                fi
        done
        # Cleanup
        grep -Ev "^</manifest>" $manifest > '$manifest'.new
        echo "</manifest>" >> '$manifest'.new
        mv '$manifest'.new $manifest
fi

cp platform_manifest/kernel_manifest.xml $manifest
echo "syncing kernel repos"
tail -n +3 platform_manifest/kernel_manifest.xml | head -n -1 | cut -f2 -d '"' > .sync

. build/resurrection_remix.sh

while read line ;do
        reposync "$line"
        echo "$line synced successfully"
done < .sync

#cleanup
rm .sync
