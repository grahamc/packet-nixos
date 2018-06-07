let
  arm = import ./arm.nix;
  x86 = import ./x8664.nix;

  pkgs = import <nixpkgs> {};
  all = pkgs.buildEnv {
    name = "all-pxe-images";
    paths = [ x86 arm ];
};
  allWithTarball = pkgs.runCommand "all-pxe-images-with-tarball" {} ''
    now=$(date '+%Y-%m-%d--%H-%M-%S')
    cp -r ${all} "./nixos-netboot-images-$now"
    chmod u+w "./nixos-netboot-images-$now"
    tar --create \
        --verbose \
        --bzip2 \
        --dereference \
        --file "./nixos-netboot-images-$now.tar.bz2" \
        "./nixos-netboot-images-$now"

    mv "./nixos-netboot-images-$now" $out
    mv "./nixos-netboot-images-$now.tar.bz2" $out/
'';
in pkgs.runCommand "indexed-pxe-images" {} ''
  cp -r ${if false then all else allWithTarball} $out
chmod u+w $out

cd $out

for f in $(find -L . -name 'netboot.ipxe' -o -name '*.bz2' | sort -h); do
  printf '<li><a href="%s">%s</a></li>\n' \
    $f \
    $f;
done > $out/index.html

''
