{
  autoPatchelfHook,
  fetchurl,
  lib,
  lld,
  makeWrapper,
  stdenv,
}:

let
  version = "0.15.1.4";
  sources = {
    aarch64-darwin = {
      url = "https://github.com/withlang-dev/with/releases/download/v${version}/with-darwin-aarch64";
      hash = "sha256-ZnnRbl6IGp9DUOyHXHmQgxSakBZB7VFZyJQIf1Gtoxc=";
    };
    x86_64-linux = {
      url = "https://github.com/withlang-dev/with/releases/download/v${version}/with-linux-x86_64";
      hash = "sha256-Nu1gzXuHgr9LPqMWI43XFFKm5apC6RWTUB6zkUtA2nU=";
    };
  };
  source = sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "withlang-bin";
  inherit version;

  src = fetchurl source;

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  dontBuild = true;
  dontStrip = true;
  dontUnpack = true;

  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    test "$($out/bin/with version)" = "with v${version}"
    test "$($out/bin/with -e 'print("hello, with")')" = "hello, with"
    runHook postInstallCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m0755 "$src" "$out/bin/with"
    wrapProgram "$out/bin/with" --prefix PATH : "${
      lib.makeBinPath [
        lld
        stdenv.cc
        stdenv.cc.bintools
      ]
    }"
    runHook postInstall
  '';

  meta = {
    description = "Prebuilt With programming language compiler";
    homepage = "https://github.com/withlang-dev/with";
    license = lib.licenses.mit;
    mainProgram = "with";
    maintainers = with lib.maintainers; [ siriobalmelli ];
    platforms = builtins.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
