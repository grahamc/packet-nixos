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

# hacking

If you pass `dumpkeys` in the commandline arguments, it will dump the
user-defined SSH keys to the root's account inside the netboot
environment, for installer debugging.

## Customization

Check out ./default.nix for how the partitioning and formatting are
done. Per-instance config types are in ./instances/.

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
