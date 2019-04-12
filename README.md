# NixOS <3 Packet.net
## The Official NixOS install images for Packet.net

### User data

Add Nix user-data to your server, and it will be used as part of the
installation.

Your userdata must look like this:

```
#!nix
{ your nix config }
```

For example, the following user data will install hello automatically:

```
#!nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.hello ];
}
```

If your user data is not valid Nix or causes the NixOS installation to
fail, it will be removed and the installation will continue without
it.

## Boot Packet.net bare metal with iPXE

Creates an iPXE-based NixOS installer. Has no hard-coded credentials,
so my image will work for you too.

Currently supports:

 - Type 0
 - Type 1
 - Type 2
 - Type 2A
 - Type 3
 - Type S

Uses ZFS on Type 1 and Type 2.


Run `./pxe.sh` to generate your PXE images and upload to a webserver.

Example:

```
$ ./pxe.sh gsc.io:sites/gsc.io/public/nixos-packet-ipxe type-0
```

Or, you can build all x86_64 the images with:

```
$ ./all.sh
```

It will output them all to `./nixos-ipxe-<type>/`

If you pass `debug-install` in the commandline arguments, it will
dump the user-defined SSH keys to the root's account inside the
netboot environment, and stop the automatic, unattended install
process.

## Customization

Check out ./default.nix for how the partitioning and formatting are
done. Per-instance config types are in ./instances/.


---

todo:

  c2.medium
  x1.small
  m2.xlarge.x86

---

x t1.small.x86
x c1.small.x86
x m1.xlarge.x86
x c1.large.arm
x c1.xlarge.x86
x s1.large.x86

---

expect-tests/config.sh:

```
export YES_I_KNOW_THIS_IS_EXPENSIVE=
export PACKET_TOKEN=
export PACKET_PROJECT_ID=
export IPXE_ROOT=
export TEST_IPV4_PUBLIC=
export TEST_IPV6_PUBLIC=
export TEST_IPV4_PRIVATE=
export BUILD_HOST_ARM_IP=
export BUILD_HOST_ARM=root@$BUILD_HOST_ARM_IP
export BUILD_HOST_ARM_PRIVATE_KEY=
```
