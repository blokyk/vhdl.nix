{
  lib,
  writeText,

  python312Packages,
  buildPythonApplication
    ? python312Packages.buildPythonApplication,

  nextpnr-xilinx,
}:

let
  cpFilesTo = targetDir: files:
    lib.concatMapAttrsStringSep
      "\n"
      (filename: path: ''cp -r "${path}" "${targetDir}"/"${filename}"'')
      files;
in
buildPythonApplication rec {
  pname = "bbaexport";
  # use the same src tarball and version as the nextpnr-xilinx package
  inherit (nextpnr-xilinx) version src;

  # the scripts we care about are in `xilinx/python`, so just navigate there directly
  sourceRoot = "${src.name}/xilinx/python";

  pyproject = true;
  build-system = [ python312Packages.setuptools ];

  dependencies = [];

  meta.mainProgram = pname;

  patches = [

  ];

  # add basic packaging files to reduce friction with `buildPythonApplication`
  preConfigure = cpFilesTo "." {
    "setup.py" = writeText "setup.py" ''
      from setuptools import setup
      setup(
        name = "bbaexport",
        # version = "${version}",
        entry_points = {"console_scripts": [
          "bbaexport=bbaexport:main"
        ]},
        py_modules = [
          "bba",
          "bbaexport",
          "bels",
          "constid",
          "nextpnr_structs",
          "parse_sdf",
          "tileconn",
          "xilinx_device"
        ],
      )
    '';
  };
}