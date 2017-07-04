#!/bin/sh

ident() {
    # MD5 the files, then MD5 the MD5s for our ident
    find . -path "./.git" -prune -o -type f -print0 \
        | xargs -0 md5sum \
        | md5sum
}

sync() {
    echo "Syncing"
    rsync -avp . zoidberg.gsc.io:gsc.io/public/nixos-packet-ts
    ssh zoidberg.gsc.io /bin/sh -c "'cd gsc.io/public/nixos-packet-ts && pwd && ./pxe.sh ./ x86-64 '"
    printf "\n\n\n\n\n\nFinished\n"
}

curid="bogus"
while true; do
    newid="$(ident)"
    if [ "$curid" != "$newid" ]; then
        sync
        curid="$newid"
    fi
    sleep .1
done
