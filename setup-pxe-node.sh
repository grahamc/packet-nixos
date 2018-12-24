#!/usr/bin/env nix-shell
#!nix-shell -i bash -p packet jq

set -euo pipefail
. ./expect-tests/config.sh

packet-cli () {
    packet \
        --key "$PACKET_TOKEN" \
        --project-id "$PACKET_PROJECT_ID" \
        "$@"
}

test_device() {
    ip_addr=$(packet-cli baremetal list-devices \
        | jq -sr '
            .
            | flatten
            | map(select(.hostname == "ipxe-test-node"))
            | map(.ip_addresses)
            | flatten
            | map(select(.public == true and .address_family == 4))
            | map(.address)
            | sort
            | .[0]
          ')

    if [ "$ip_addr" = "null" ]; then
        return 1
    fi
    echo $ip_addr
}

setup_pxe_node() {
    ssh "$@" /bin/sh -c "
        tee /etc/nixos/packet/pxe.nix > /dev/null
        cd /etc/nixos
        mkdir /var/www
        echo '{ imports = [' > packet.nix
        find ./packet -type f >> packet.nix
        echo ']; }' >> packet.nix
        nixos-rebuild switch
      "
}

hourly=15

if [ "${YES_I_KNOW_THIS_IS_EXPENSIVE:-x}" != "$hourly" ]; then
    echo "You must set YES_I_KNOW_THIS_IS_EXPENSIVE=$hourly before"
    echo "running this script, because this script creates a server"
    echo "in the spot market for $ $hourly/hr."
    exit 1
fi

ip_addr=$(test_device);
if [ $? -ne 0 ]; then
    echo "Provisioning a new test device..."
    packet-cli baremetal create-device \
               --os-type nixos_18_03 \
               --plan m2.xlarge.x86 \
               --facility any \
               --hostname "ipxe-test-node" \
               --spot-instance \
               --spot-price-max "$hourly"

    ip_addr=$(test_device);
    if [ $? -ne 0 ]; then
        echo "Failed to provision the test device? test_device() failed."
        exit 1
    fi
fi

ssh-keyscan "$ip_addr" > pxe-known-host 2>&1
SSHOPTS="-o UserKnownHostsFile=./pxe-known-host"

build_host_arm_key=$(ssh-keyscan "$BUILD_HOST_ARM_IP" 2> /dev/null | head -n1 | cut -d' ' -f 2-)
uuid=$(ssh $SSHOPTS "root@$ip_addr" curl https://metadata.packet.net/metadata | jq -r '.id' | cut -d- -f1)
url="$uuid.packethost.net"

cat <<EOF | setup_pxe_node $SSHOPTS "root@$ip_addr"
{ pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 443 80 ];
  services.nginx = {
    enable = true;
    virtualHosts."$url" = {
      default = true;
#      forceSSL = true;
#      enableACME = true;
      root = "/var/www";
    };
  };

  services.openssh.knownHosts = [
    {
      hostNames = [ "$BUILD_HOST_ARM_IP" ];
      publicKey = "$build_host_arm_key";
    }
  ];

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "$BUILD_HOST_ARM_IP";
      sshUser = "root";
      sshKey = "/root/arm-ssh-key";
      system = "aarch64-linux";
      maxJobs = 45;
      supportedFeatures = [ "big-parallel" "kvm" "nixos-test" ];
    }
  ];
}
EOF

echo "Copying SSH private key"
scp $SSHOPTS "$BUILD_HOST_ARM_PRIVATE_KEY" root@$ip_addr:/root/arm-ssh-key
ssh $SSHOPTS "root@$ip_addr" chmod 0600  /root/arm-ssh-key

echo "Testing ssh connectivity from $ip_addr and remote arm builder $BUILD_HOST_ARM_IP"
ssh $SSHOPTS "root@$ip_addr" ssh -i /root/arm-ssh-key "root@$BUILD_HOST_ARM_IP" nix-store --version

echo "Testing remote builds work via $BUILD_HOST_ARM_IP"
ssh $SSHOPTS "root@$ip_addr" nix-build -E "'
  (import <nixpkgs> { system = \"aarch64-linux\"; })
    .hello
    .overrideAttrs (x: { name = \"hello-check\"; })'"

echo "export PXE_BUILD_HOST=$url" >> ./expect-tests/config.sh
echo "export PXE_ROOT=https://$url/result/" >> ./expect-tests/config.sh
echo "Good for testing, use $url for builds!"
