{
  stdenv,

  python312Packages,
  buildPythonApplication
    ? python312Packages.buildPythonApplication,

  prjxray,
}:

let
in
buildPythonApplication rec {
  pname = "fasm2frames";
  version = "0.0.1+${prjxray.version}";

  src = prjxray.src;
  sourceRoot = "${src.name}/utils";

  preConfigure = ''
    source 
  '';
}