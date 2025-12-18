{
  stdenv,

  fetchFromGitHub,

  cmake,
}:

stdenv.mkDerivation (this: {
  pname = "prjxray";
  version = "c9f02d8";

  src = fetchFromGitHub {
    owner = "f4pga";
    repo = "prjxray";
    rev = this.version;
    sha256 = "";

    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake ];

  buildPhase = ''
    runHook preBuild
    make build
    runHook postBuild
  '';
})