{
  cmake,
  fetchurl,
  lib,
  ninja,
  python3,
  stdenv,
}:
stdenv.mkDerivation (
  finalAttrs: with finalAttrs; {
    pname = "withlang-llvm";
    version = "22.1.6";

    src = fetchurl {
      url = "${passthru.urlBase}/llvmorg-${version}/llvm-project-${version}.src.tar.xz";
      sha256 = "6e0b376a1f6d9873e7dfb09ae6e04b9c7024400f01733fa4c29be69d5c138bc2";
    };
    sourceRoot = "llvm-project-${version}.src/llvm";

    nativeBuildInputs = [
      cmake
      ninja
      python3
    ];

    cmakeBuildDir = "build";
    cmakeFlags = [
      "-DLLVM_ENABLE_PROJECTS=clang;lld"
      "-DLLVM_TARGETS_TO_BUILD=${passthru.llvmTargetsToBuild}"
      "-DLIBCLANG_BUILD_STATIC=ON"
      "-DLLVM_ENABLE_PIC=ON"
      "-DBUILD_SHARED_LIBS=OFF"
      "-DLLVM_BUILD_LLVM_DYLIB=OFF"
      "-DLLVM_LINK_LLVM_DYLIB=OFF"
      "-DCLANG_LINK_CLANG_DYLIB=OFF"
      "-DLLVM_DISTRIBUTION_COMPONENTS=${lib.concatStringsSep ";" passthru.distributionComponents}"
      "-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON"
      "-DLLVM_INCLUDE_TESTS=OFF"
      "-DLLVM_INCLUDE_BENCHMARKS=OFF"
      "-DLLVM_INCLUDE_EXAMPLES=OFF"
      "-DCLANG_INCLUDE_TESTS=OFF"
      "-DCLANG_BUILD_EXAMPLES=OFF"
      "-DLLVM_ENABLE_ZLIB=OFF"
      "-DLLVM_ENABLE_ZSTD=OFF"
      "-DLLVM_ENABLE_LIBXML2=OFF"
      "-DLLVM_ENABLE_TERMINFO=OFF"
      "-DLLVM_ENABLE_LIBEDIT=OFF"
    ];

    ninjaFlags = [ "distribution" ];
    installTargets = "install-distribution";

    postInstall = ''
      mkdir -p "$out/lib"
      cp -f "$NIX_BUILD_TOP/$sourceRoot/$cmakeBuildDir"/lib/*.a "$out/lib/"
    '';

    doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

    postInstallCheck = ''
      test -x "$out/bin/clang"
      test -x "$out/bin/clang++"
      grep -q clang_createIndex <("$out/bin/llvm-nm" -g "$out/lib/libclang.a")
    '';

    passthru = {
      distributionComponents = [
        "clang"
        "clang-resource-headers"
        "libclang_static"
        "lld"
        "llvm-nm"
      ];
      llvmTargetsToBuild = "AArch64;X86"; # both expected by rt/llvm_bridge.w
      urlBase = "https://github.com/llvm/llvm-project/releases/download";
    };

    meta = {
      description = "With-owned static LLVM, Clang, and lld SDK";
      homepage = "https://github.com/withlang-dev/with";
      license = lib.licenses.asl20;
      platforms = lib.platforms.darwin ++ lib.platforms.linux;
    };
  }
)
