{
  lib,
  stdenv,

  fetchFromGitHub,

  boost,
  cmake,
  eigen,
  llvmPackages,
  python312,
}:

let
  ref = "b9f013d";
  boost-python = boost.override {
    python = python312;
    enablePython = true;
  };
in
stdenv.mkDerivation (this: {
  pname = "nextpnr-xilinx";
  version = ref;

  src = fetchFromGitHub {
    owner = "openXC7";
    repo = "nextpnr-xilinx";
    rev = this.version;
    sha256 = "sha256-++TjoG/mFqY+/g/w5Z/Mt/EjexClhGzVL6M+JR8ldSY=";

    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    python312
  ];

  buildInputs = [
    boost-python
    eigen
  ]
  ++ (lib.optional stdenv.cc.isClang llvmPackages.openmp);

  cmakeFlags =
    let
      # the specified version must always start with "nextpnr-", so add it if
      # missing (e.g. if the user overrides with a git hash)
      rev = this.src.rev;
      version = if (lib.hasPrefix "nextpnr-xiling-" rev) then rev else "nextpnr-xilinx-${rev}";
    in
    [
      "-DCURRENT_GIT_VERSION=${version}"
      "-DARCH=xilinx"
      "-DBUILD_TESTS=ON"

      # https://github.com/YosysHQ/nextpnr/issues/1578
      # `Compatibility with CMake < 3.5 has been removed from CMake.`
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    ];

  doCheck = true;

  strictDeps = true;

  # we need to also install the `bbasm`
  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m755 nextpnr-xilinx "$out/bin"
    install -m755 bbasm "$out/bin"

    runHook postInstall
  '';

  outputs = [
    "out"
    "dev"
  ];

  meta = {
    description = "Experimental flows using nextpnr for Xilinx devices ";
    homepage = "https://github.com/openXC7";
    license = lib.licenses.isc;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ blokyk ];
    mainProgram = "nextpnr-xilinx";
  };
})