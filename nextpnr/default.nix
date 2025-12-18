{ callPackage }: rec {
  nextpnr-xilinx = callPackage ./nextpnr-xilinx.nix {};
  bbaexport = callPackage ./bbaexport.nix { inherit nextpnr-xilinx; };
}