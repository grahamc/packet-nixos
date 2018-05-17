#!/bin/sh

set -eux

PATH=@kexectools@/bin:@jq@/bin:@packetconfiggen@/bin:@coreutils@/bin:@utillinux@/bin:@e2fsprogs@/bin:@zfs@/bin:@out@/bin:/run/current-system/sw/bin/:$PATH

pre_partition() {
    udevadm settle
}

pre_format() {
    udevadm settle
}

pre_mount() {
    udevadm settle
}

post_mount() {
    udevadm settle
    notify.py partitioned
}

generate_standard_config() {
    nixos-generate-config --root /mnt

    mkdir -p /mnt/etc/nixos/packet
    packet-config-gen > /mnt/etc/nixos/packet/metadata.nix

    # for ZFS
    hostId=$(printf "00000000%x" $(cksum /etc/machine-id | cut -d' ' -f1) | tail -c8)
    echo '{ networking.hostId = "'$hostId'"; }' > /mnt/etc/nixos/packet/host-id.nix
}

finalize_config() {
    update_includes_nix
    sed -i "s#./hardware-configuration.nix#./packet.nix#" /mnt/etc/nixos/configuration.nix
    rm /mnt/etc/nixos/hardware-configuration.nix

    place_temporary_modules
    update_includes_nix
}

place_temporary_modules() {
    cat @phonehomeconf@ \
        | sed -e "s#CURL_CALL#$(notify.py booted)#" \
        | cat > /mnt/etc/nixos/packet/phone-home.nix

    update_includes_nix
}

delete_temporary_modules() {
    rm /mnt/etc/nixos/packet/phone-home.nix
    update_includes_nix
}

update_includes_nix() {
    pushd /mnt/etc/nixos/
    (
        echo "{ imports = [";
        find ./packet/ -type f
        echo "]; }"
    ) > packet.nix
    popd
}

do_install() {
    nixos-install < /dev/null
    udevadm settle

    notify.py installed
    touch /mnt/etc/.packet-phone-home
    arm_kexec
    delete_temporary_modules
}

do_reboot() {
    udevadm settle
    # note: do_kexec depends upon do_reboot unloading
    kexec --unload
    reboot
}

arm_kexec() {
    nix-instantiate --json --eval @kexecconfig@ \
        | jq -r . \
        | bash -eux
}

do_kexec() {
    udevadm settle

    sync
    sleep 1
    sync
    sleep 1
    sync

    # In case kexec failed to actually do the thing, fall back to a
    # standard reboot.
    kexec -e || do_reboot
}
