#!/bin/bash
# To be run from the root of the build tree.
# NOT FROM THE PLATFORM_MANIFEST DIRECTORY!!!
# -KhasMek

echo "adding kernel repos to your build tree"

if [ -f .repo/local_manifest.xml ]; then
        echo "local manifest already present."
        echo "merging with kernel manifest for safety."
        cat platform_manifest/kernel_manifest.xml | while read line
        do
                kernel=`grep "$line" .repo/local_manifest.xml`
                if [ -z "$kernel" ]; then
                        echo "  $line" >> .repo/local_manifest.xml
                fi
        done
        # Cleanup
        grep -Ev "^</manifest>" .repo/local_manifest.xml > .repo/local_manifest.new
        echo "</manifest>" >> .repo/local_manifest.new
        mv .repo/local_manifest.new .repo/local_manifest.xml
fi

cp platform_manifest/kernel_manifest.xml .repo/local_manifest.xml
echo "syncing kernel repos"
tail -n +3 platform_manifest/kernel_manifest.xml | head -n -1 | cut -f2 -d '"' > .sync

. build/envsetup.sh

while read line ;do
        reposync "$line"
        echo "$line synced successfully"
done < .sync

#cleanup
rm .sync
