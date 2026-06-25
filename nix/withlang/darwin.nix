{
  apple-sdk,
  lib,
  libcxx,
  stdenv,
  withlang-llvm,
}:

let
  sdkRoot = "${apple-sdk}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";
  cxxLibDir = "${lib.getLib libcxx}/lib";
in
stdenv.mkDerivation {
  buildInputs = [
    apple-sdk
    libcxx
  ];

  preBuild = ''
    export WITH_LLVM_LD="${withlang-llvm}/bin/ld64.lld"
    export WITH_DARWIN_CXX_LIB_DIR="${cxxLibDir}"
    export SDKROOT="${sdkRoot}"
  '';

  passthru = {
    llvmHostName = "darwin-arm64";
    wrapperArgs = [
      "--set"
      "WITH_LLVM_LD"
      "${withlang-llvm}/bin/ld64.lld"
      "--set"
      "WITH_DARWIN_CXX_LIB_DIR"
      cxxLibDir
      "--set"
      "SDKROOT"
      sdkRoot
    ];
  };
}
