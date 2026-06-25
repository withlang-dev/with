{
  lib,
  libxml2,
  patchelf,
  stdenv,
  symlinkJoin,
  withlang-llvm,
  zlib,
  zstd,
}:

let
  gccDir = "${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${stdenv.cc.cc.version}";
  libcDir = "${stdenv.cc.libc}/lib";
  dynamicLinker = lib.removeSuffix "\n" (builtins.readFile "${stdenv.cc}/nix-support/dynamic-linker");
  libxml2Lib = lib.getLib libxml2;
  zlibLib = lib.getLib zlib;
  zstdLib = lib.getLib zstd;
  linuxSysLibs = symlinkJoin {
    name = "with-linux-syslibs";
    paths = [
      stdenv.cc.cc.lib
      zlibLib
      zstdLib
      libxml2Lib
    ];
  };
  runtimeLibraryPath = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    zlibLib
    zstdLib
    libxml2Lib
  ];
  cImportISystem = lib.concatStringsSep ":" [
    "${stdenv.cc.libc.dev}/include"
    "${gccDir}/include"
    "${gccDir}/include-fixed"
  ];
in
stdenv.mkDerivation {
  nativeBuildInputs = [ patchelf ];

  preBuild = ''
    export WITH_LLVM_LD="${withlang-llvm}/bin/ld.lld"
    export WITH_LINUX_DYNAMIC_STDCXX=1
    export WITH_LINUX_DYNAMIC_LINKER="${dynamicLinker}"
    export WITH_LINUX_CRT_DIR="${libcDir}"
    export WITH_LINUX_GCC_DIR="${gccDir}"
    export WITH_LINUX_SYSLIB_DIR="${linuxSysLibs}/lib"
    export WITH_CIMPORT_ISYSTEM="${cImportISystem}"
    export LD_LIBRARY_PATH="${runtimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  preFixup = ''
    runtimeObjectDir="$TMPDIR/with-runtime-objects"
    mkdir -p "$runtimeObjectDir"
    for obj in "$out"/bin/runtime/*.o; do
      if [ -e "$obj" ]; then
        mv "$obj" "$runtimeObjectDir/"
      fi
    done
  '';

  postFixup = ''
    for obj in "$runtimeObjectDir"/*.o; do
      if [ -e "$obj" ]; then
        mv "$obj" "$out/bin/runtime/"
      fi
    done

    patchelf \
      --set-interpreter "${dynamicLinker}" \
      --set-rpath "${runtimeLibraryPath}" \
      "$out/bin/with"
  '';

  passthru = {
    llvmHostName = "linux-x86_64";
    wrapperArgs = [
      "--set"
      "WITH_LLVM_LD"
      "${withlang-llvm}/bin/ld.lld"
      "--set"
      "WITH_LINUX_DYNAMIC_STDCXX"
      "1"
      "--set"
      "WITH_LINUX_DYNAMIC_LINKER"
      dynamicLinker
      "--set"
      "WITH_LINUX_CRT_DIR"
      libcDir
      "--set"
      "WITH_LINUX_GCC_DIR"
      gccDir
      "--set"
      "WITH_LINUX_SYSLIB_DIR"
      "${linuxSysLibs}/lib"
      "--set"
      "WITH_CIMPORT_ISYSTEM"
      cImportISystem
      "--prefix"
      "LD_LIBRARY_PATH"
      ":"
      runtimeLibraryPath
    ];
  };
}
