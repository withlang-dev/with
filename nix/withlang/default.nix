{
  bash,
  callPackage,
  coreutils,
  fetchurl,
  gzip,
  lib,
  makeWrapper,
  python3,
  runCommand,
  stdenv,
  withlang-llvm,
  withlang-seed,
}:

let
  platformFiles = {
    "aarch64-darwin" = ./darwin.nix;
    "x86_64-linux" = ./linux.nix;
  };
  platformPackage = callPackage platformFiles.${stdenv.hostPlatform.system} { };

  pcre2Src = fetchurl {
    url = "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.gz";
    hash = "sha256-wIriOI7zM+hAPmcK1wwKEfHu0CH9iDCNfgL1lvzZ3BY=";
  };
in
platformPackage.overrideAttrs (
  finalAttrs: previousAttrs:
  let
    withlangLlvmProjectPrefix = ".deps/llvm-${withlang-llvm.version}-${previousAttrs.passthru.llvmHostName}";
    wrapperArgs = [
      "--set"
      "LLVM_PREFIX"
      "${withlang-llvm}"
      "--set"
      "WITH_LIBCLANG"
      "${withlang-llvm}/lib/libclang.a"
      "--set"
      "WITH_LINK_CC"
      "${stdenv.cc}/bin/cc"
      "--set"
      "WITH_LLVM_CC"
      "${withlang-llvm}/bin/clang"
      "--prefix"
      "PATH"
      ":"
      (lib.makeBinPath [
        withlang-llvm
        stdenv.cc
      ])
    ]
    ++ previousAttrs.passthru.wrapperArgs
    ++ [
      "--set"
      "BASH"
      "${bash}/bin/bash"
      "--set"
      "WITH_ECHO"
      "${coreutils}/bin/echo"
      "--set"
      "WITH_ENV"
      "${coreutils}/bin/env"
      "--set"
      "WITH_TEST"
      "${coreutils}/bin/test"
      "--set"
      "WITH_TRUE"
      "${coreutils}/bin/true"
    ];
  in
  {
    pname = "withlang";
    version = "0.15.1";

    src = ../../.;

    patches = [
      ./patches/nix-env-compat.patch
    ];

    nativeBuildInputs = [
      bash
      coreutils
      gzip
      makeWrapper
      python3
    ]
    ++ (previousAttrs.nativeBuildInputs or [ ]);

    # Runtime objects are relocatable .o files, not executables or shared libs.
    # The package patches the compiler binary explicitly.
    dontPatchELF = true;

    postUnpack = ''
      install -m0755 ${withlang-seed}/bin/with-seed "$sourceRoot/src/main"
    '';

    preBuild = ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"

      export WITH="$PWD/src/main"
      export WITH_SEED_INPUT_SHA256="$(${coreutils}/bin/sha256sum "$WITH" | ${coreutils}/bin/cut -d ' ' -f 1)"
      export WITH_OUT_DIR="$PWD/out"
      export LLVM_PREFIX="${withlang-llvm}"
      export WITH_LINK_CC="${stdenv.cc}/bin/cc"
      export WITH_LLVM_CC="${withlang-llvm}/bin/clang"
      export WITH_LIBCLANG="${withlang-llvm}/lib/libclang.a"
      export WITH_VERSION="v${finalAttrs.version}"
      export WITH_TMPDIR="$TMPDIR"

      mkdir -p .deps
      ln -sfn ${withlang-llvm} "${withlangLlvmProjectPrefix}"

      export BASH="${bash}/bin/bash"
      export WITH_ECHO="${coreutils}/bin/echo"
      export WITH_ENV="${coreutils}/bin/env"
      export WITH_TEST="${coreutils}/bin/test"
      export WITH_TRUE="${coreutils}/bin/true"

      ${lib.optionalString stdenv.hostPlatform.isLinux ''
        export WITH_LINK_CC="${withlang-seed}/bin/with-seed-cc"
        export PATH="${withlang-seed}/bin:$PATH"
      ''}

      pcre2_dir="$PWD/out/nix-pcre2-source"
      mkdir -p "$pcre2_dir"
      tar -xzf ${pcre2Src} -C "$pcre2_dir"
      export WITH_PCRE2_SOURCE="out/nix-pcre2-source/pcre2-10.47"
    ''
    + previousAttrs.preBuild;

    buildPhase = ''
      runHook preBuild
      "$WITH" build
      runHook postBuild
    '';

    doCheck = true;
    checkPhase = ''
      runHook preCheck
      ./out/release/bin/with build :fixpoint
      ./out/release/bin/with build :pcre2-migrate-smoke
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      PREFIX="$out" ./out/release/bin/with build :install
      runHook postInstall
    '';

    postFixup = (previousAttrs.postFixup or "") + ''
      wrapProgram "$out/bin/with" ${lib.escapeShellArgs wrapperArgs}
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      unset WITH
      unset WITH_OUT_DIR
      test "$($out/bin/with version)" = "with v${finalAttrs.version}"
    '';

    passthru = previousAttrs.passthru // {
      tests.smoke = runCommand "${finalAttrs.pname}-smoke-test" { } ''
        # TODO: remove 2>/dev/null once upstream no longer attempts to write .o files to ro nix store
        ${lib.getExe finalAttrs.finalPackage} -e 'print("hello, with")' 2>/dev/null > "$out"
        diff $out <(echo "hello, with")
      '';
    };

    meta = {
      description = "With programming language compiler";
      homepage = "https://github.com/withlang-dev/with";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ siriobalmelli ];
      mainProgram = "with";
      platforms = builtins.attrNames platformFiles;
    };
  }
)
