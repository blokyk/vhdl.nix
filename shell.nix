{
  pkgs ? import <nixpkgs> {},

  callPackage ? pkgs.callPackage,
  mkShell ? pkgs.mkShell,
}:
let
  my-nextpnr = callPackage ./nextpnr {};
  prjxray = callPackage ./prjxray {};
in
mkShell {
  packages = with pkgs; [
    ghdl
    (yosys.withPlugins [ yosys.allPlugins.ghdl ])
    openfpgaloader
    my-nextpnr.nextpnr-xilinx
    my-nextpnr.bbaexport
    prjxray.prjxray
  ];

  shellHook = ''
    export DEBUG=1
  '';
}