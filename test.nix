with import <nixpkgs> {}; rec {
  prjxray = callPackage ./prjxray {};
  nextpnr = callPackage ./nextpnr {};
}