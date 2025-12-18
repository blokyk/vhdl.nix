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
      (filename: path: ''
        echo "Copying ${path} to ${targetDir}/${filename}"
        cp -r "${path}" "${targetDir}"/"${filename}"
      '')
      files;
in
buildPythonApplication rec {
  pname = "bbaexport";
  version = "0.0.1+${nextpnr-xilinx.version}";

  # use the same src tarball as the nextpnr-xilinx package
  src = nextpnr-xilinx.src;
  # the scripts we care about are in `xilinx/`, so just navigate there directly
  sourceRoot = "${src.name}/xilinx/python";

  pyproject = true;
  build-system = [ python312Packages.setuptools ];

  dependencies = [];

  meta.mainProgram = pname;

  patches = [ ./patches/fix-rwbase-path.patch ];

  preConfigure = ''
      mkdir -p ./bbaexport_data
    '' +
    cpFilesTo "./bbaexport_data" {
      # right now, this embeds all the external file (prjxray-db and
      # nextpnr-xilinx-meta) into the python package, which is incredibly
      # wasteful in general, and bloats it up to more than 700MB.
      # instead, we could use a pattern like `pkgs.yosys.withPlugin [ ... ]`,
      # where we specify the board(s) or general architecture(s) we want, so
      # that the user doesn't end up with half a gigabyte of data they won't use.
      # fixme(bbaexport): implement something like .withBoard/.withDatabase/.withMetadata
      "./" = "../external/";
      "./constids.inc" = "../constids.inc";
      "./chipdb.hexpat" = "../chipdb.hexpat";
    } +
    cpFilesTo "." {
      "pyproject.toml" = writeText "pyproject.toml" ''
        [build-system]
        requires = ["setuptools"]
        build-backend = "setuptools.build_meta"

        [project]
        name = "bbaexport"
        version = "${version}"

        [project.scripts]
        bbaexport = "bbaexport:main"

        # [tool.setuptools.packages.find]
        # where = ["python/"]

        [tool.setuptools.package-data]
        "bbaexport_data" = [ "*", "**/*" ]
        #   "external",
        #   "constids.inc",
        #   "chipdb.hexpat"
        # ]

        [tool.setuptools]
        packages = [ "bbaexport_data" ]
        py-modules = [
          "bba",
          "bbaexport",
          "bels",
          "constid",
          "nextpnr_structs",
          "parse_sdf",
          "tileconn",
          "xilinx_device"
        ]
      '';
    };
}