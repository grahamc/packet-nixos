# NixOS <3 Packet.net
## The Official NixOS install images for Packet.net
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

If you pass `dumpkeys` in the commandline arguments, it will dump the
user-defined SSH keys to the root's account inside the netboot
environment, for installer debugging.




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
