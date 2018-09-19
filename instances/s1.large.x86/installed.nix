{
    boot.loader.grub.devices = [ "/dev/disk/by-path/pci-0000:00:1f.2-ata-5" ];
    boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
    terminal_output serial console
    terminal_input serial console
  '';

  fileSystems = {
    "/" = {
      label = "nixos";
      fsType = "ext4";
    };
  };

  swapDevices = [
    {
      label = "swap";
    }
  ];
}
