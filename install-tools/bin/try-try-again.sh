#!/bin/sh

(
    while ! $1 < /dev/null; do
        echo "Failed..."
        umount /mnt
        sleep 1
        echo "Trying again!"
    done
    echo "finished"
)  2>&1 | tee -a /root/install.log
