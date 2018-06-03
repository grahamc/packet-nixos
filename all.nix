let
  arm = import ./arm.nix;
  x86 = import ./x8664.nix;

  pkgs = import <nixpkgs> {};
  all = pkgs.buildEnv {
    name = "all-pxe-images";
    paths = [ x86 arm ];
  };
in pkgs.runCommand "indexed-pxe-images" {} ''
cp -r ${all} $out
chmod u+w $out
cd $out
for f in $(find -L . -name 'netboot.ipxe' | grep -v '-' | sort -h); do
  printf '<li><a href="%s">%s</a></li>\n' \
    $f \
    $(basename $(dirname $f));
done > $out/index.html
''
