{
  lib,
  makeWrapper,
  stdenv,
  withlang-llvm,
  zstd,
}:
let
  gccDir = "${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${stdenv.cc.cc.version}";
  libcDir = "${stdenv.cc.libc}/lib";
  libcDevLibDir = "${stdenv.cc.libc.dev}/lib";
  gccLibDir = "${stdenv.cc.cc.lib}/lib";
  dynamicLinker = lib.removeSuffix "\n" (builtins.readFile "${stdenv.cc}/nix-support/dynamic-linker");
  runtimeLibraryPath = lib.makeLibraryPath [ stdenv.cc.cc.lib ];
in
stdenv.mkDerivation (finalAttrs: {
  src = finalAttrs.passthru.srcs.${stdenv.hostPlatform.system};

  # Temporary packaging patch for the frozen v0.15.1 Linux seed.
  # TODO: upstream these link-path fixes over time and remove this patch.
  patches = [ ./patches/linux-seed-link-paths.patch ];

  nativeBuildInputs = [
    makeWrapper
    zstd
  ];

  unpackPhase = ''
    runHook preUnpack
    mkdir source
    zstd -dc "$src" | tar -xf - -C source
    sourceRoot=source
    runHook postUnpack
  '';

  dontConfigure = true;
  # This executable is hand-linked. Nix's generic ELF patch/strip pass corrupts
  # its dynamic version metadata, so the link command owns interpreter/RPATH.
  dontPatchELF = true;
  dontStrip = true;

  buildPhase = ''
    runHook preBuild

    mkdir -p obj
    printf '%s\n' \
      '#include "bootstrap_types.h"' \
      'void with_panic(with_str, with_str, int32_t);' \
      > obj/bootstrap_forward_decls.h

    cflags=(
      -std=gnu11
      -O2
      -D_GNU_SOURCE
      -iquote runtime
      -I"${withlang-llvm}/include"
      -isystem "${stdenv.cc.libc.dev}/include"
      -isystem "${gccDir}/include"
      -isystem "${gccDir}/include-fixed"
    )
    runtime_cflags=(
      "''${cflags[@]}"
      -DWITH_RUNTIME_H
      -include obj/bootstrap_forward_decls.h
      -include runtime/wl_decls.h
    )
    compiler_cflags=(
      "''${cflags[@]}"
      # The v0.15.1 emitted-C compiler is a bootstrap artifact. Clang -O1/O2
      # tail-merges ToolFs integer-result branches incorrectly on Linux and
      # leaves the shared result slot register uninitialized for mkdir_all.
      -O0
    )

    "${withlang-llvm}/bin/clang" "''${compiler_cflags[@]}" \
      -include runtime/wl_decls.h \
      -c src/with_compiler.c \
      -o obj/with_compiler.o

    for file in src/linux_platform.c ${./bootstrap-linux-compat.c}; do
      name="''${file##*/}"
      "${withlang-llvm}/bin/clang" "''${cflags[@]}" -c "$file" -o "obj/''${name%.c}.o"
    done

    for file in src/{compat_runtime,fiber_stubs,panic_runtime,regex_runtime,rt_core}.c; do
      name="''${file##*/}"
      "${withlang-llvm}/bin/clang" "''${runtime_cflags[@]}" -c "$file" -o "obj/''${name%.c}.o"
    done

    "${withlang-llvm}/bin/ld.lld" \
      -m elf_x86_64 \
      --eh-frame-hdr \
      --hash-style=gnu \
      --build-id \
      --gc-sections \
      --as-needed \
      "--dynamic-linker=${dynamicLinker}" \
      -rpath "${runtimeLibraryPath}" \
      -o with-bootstrap \
      "${libcDir}/crt1.o" \
      "${libcDir}/crti.o" \
      "${gccDir}/crtbegin.o" \
      obj/*.o \
      -L"${gccDir}" \
      -L"${gccLibDir}" \
      -L"${libcDir}" \
      -L"${libcDevLibDir}" \
      --start-group \
      "${withlang-llvm}"/lib/libclang*.a \
      "${withlang-llvm}"/lib/libLLVM*.a \
      "${withlang-llvm}"/lib/liblld*.a \
      --end-group \
      -lstdc++ \
      -lgcc \
      -lgcc_eh \
      -lpthread \
      -ldl \
      -lm \
      -lc \
      -lgcc \
      "${gccDir}/crtend.o" \
      "${libcDir}/crtn.o"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp with-bootstrap "$out/bin/with-seed"
    chmod 0755 "$out/bin/with-seed"
    makeWrapper ${stdenv.cc}/bin/cc "$out/bin/with-seed-cc" \
      --prefix PATH : ${withlang-llvm}/bin \
      --add-flags -fuse-ld=lld
    ln -s with-seed-cc "$out/bin/cc"
    runHook postInstall
  '';
})
