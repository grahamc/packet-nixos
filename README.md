# NixOS <3 Packet.net
## Boot Packet.net bare metal with iPXE

Creates an iPXE-based NixOS installer. Has no hard-coded credentials,
so my image will work for you too.

Currently supports:

 - Type 0
 - Type 1
 - Type 2

Uses ZFS on Type 1 and Type 2.


Run `./pxe.sh` to generate your PXE images and upload to a webserver.

Example:

```
$ ./pxe.sh gsc.io:sites/gsc.io/public/nixos-packet-ipxe
```

Then use `http://gsc.io/nixos-packet-ipxe/netboot.ipxe` when booting
your Packet.net server.

Also, you could just use http://gsc.io/lol-t2/netboot.ipxe
