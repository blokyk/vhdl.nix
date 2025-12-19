with import <nixpkgs> {};
let
  inherit (lib) getExe getExe';
  inherit (lib) concatStringsSep concatMapStringsSep;

  nix-make = callPackage /home/blokyk/dev/lab/make.nix {};
  inherit (nix-make.utils.stdenv) run;

  nextpnr = callPackage ../nextpnr {};
  nextpnr-xilinx = nextpnr.nextpnr-xilinx;
  bbaexport = nextpnr.bbaexport;

  filesWithExt = ext: root: lib.fileset.toList
    (lib.fileset.fileFilter (
      { type, hasExt, ... }: type == "regular" && hasExt ext
    ) root);

  yosys-with-ghdl = yosys.withPlugins [ yosys.allPlugins.ghdl ];

  run-yosys-ghdl = { module, sources, cmds }: { dep, name, ... }:
    assert sources != [] || throw "yosys-ghdl called with empty source file set";
    let
      dep-srcs = map dep sources;
      src-list =
        concatMapStringsSep " " (src: "\"${toString src}\"") dep-srcs;
    in
      pkgs.runCommand name
        { nativeBuildInputs = [ yosys-with-ghdl ]; }
        ''
          ${yosys-with-ghdl}/bin/yosys -q -m ghdl -p "
            ghdl ${src-list} -e ${module};
            ${concatStringsSep ";\n" cmds}
          "
        '';

  synthesize = {
    module,
    sources,
    arch ? "xc7"
  }: run-yosys-ghdl {
    inherit module sources;
    cmds = [
      "synth_xilinx -flatten -abc9 -nobram -arch ${arch} -top ${module}"
      "write_json $out"
    ];
  };

  routeFasm = {
    moduleJson,
    xdc,
  }: { dep, ... }:
    let
      chipdb = dep "basys3.chipdb";
    in run ''
      ${getExe nextpnr-xilinx} \
        --quiet \
        --chipdb ${chipdb} \
        --xdc ${dep xdc} \
        --json ${dep moduleJson} \
        --fasm $out
    '';
in
nix-make.make {
  root = ./.;

  rules = {
    "%.vhd" = nix-make.utils.autoSrc;

    "%.json" = { capture, root, ... }:
      synthesize {
        module = capture;
        sources = filesWithExt "vhd" root;
      };

    "%.fasm" = { dep, capture, ... }:
      routeFasm {
        moduleJson = dep "${capture}.json";
        xdc = dep ./display.xdc;
      };

    "%.chipdb" = { dep, capture, ... }: run ''
      ${getExe' nextpnr-xilinx "bbasm"} --l ${dep "${capture}.bba"} $out
    '';
    "%.bba" = { ... }: run ''
      ${getExe bbaexport} \
        --device xc7a35tcpg236-1 \
        --bba $out
    '';
  };
}