{
  stdenv,
}:

stdenv.mkDerivation (finalAttrs: {
  src = finalAttrs.passthru.srcs.${stdenv.hostPlatform.system};

  dontBuild = true;
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    cp "$src" "$out/bin/with-seed"
    chmod 0755 "$out/bin/with-seed"
    runHook postInstall
  '';
})
