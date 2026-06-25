{
  callPackage,
  common-updater-scripts,
  fetchurl,
  lib,
  stdenv,
  writeShellScript,
}:

let
  platformFiles = {
    "aarch64-darwin" = ./darwin.nix;
    "x86_64-linux" = ./linux.nix;
  };
  platforms = builtins.attrNames platformFiles;
  platformFile = platformFiles.${stdenv.hostPlatform.system}; # no throw needed: eval fails with clear error
in
(callPackage platformFile { }).overrideAttrs (
  finalAttrs: previousAttrs: {
    pname = "withlang-seed";
    version = "0.15.1";

    doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

    installCheckPhase = ''
      runHook preInstallCheck
      version_out="$("$out/bin/with-seed" version)"
      case "$version_out" in
        *v${finalAttrs.version}*) ;;
        *) echo "unexpected seed version: $version_out" >&2; exit 1 ;;
      esac
      runHook postInstallCheck
    '';

    passthru = (previousAttrs.passthru or { }) // {
      # Seed binaries are pre-built compilers used to bootstrap stage1.
      seedBase = "https://github.com/withlang-dev/with/releases/download/v${finalAttrs.version}";

      srcs = with finalAttrs.passthru; {
        "aarch64-darwin" = fetchurl {
          url = "${seedBase}/with-darwin-aarch64";
          hash = "sha256-K0zOUrm20ukMReZd6e358mDFjUJ5aHdokLm9IZt3CPM=";
        };
        "x86_64-linux" = fetchurl {
          url = "${seedBase}/with-bootstrap-c-v${finalAttrs.version}.tar.zst";
          hash = "sha256-A5REsQvJuDGVihhWc5KBEJwnuMdUFOoGdisbHeEm7Hc=";
        };
      };

      updateScript = writeShellScript "update-withlang-seed" ''
        set -euo pipefail

        if [ "$#" -ne 1 ]; then
          echo "usage: $0 <version>" >&2
          exit 2
        fi

        newVersion="$1"
        for platform in ${lib.escapeShellArgs platforms}; do
          ${lib.getExe' common-updater-scripts "update-source-version"} withlang-seed "$newVersion" \
            --source-key="passthru.srcs.$platform" \
            --ignore-same-version
        done
      '';
    };

    meta = (previousAttrs.meta or { }) // {
      description = "With compiler seed binary";
      homepage = "https://github.com/withlang-dev/with";
      license = lib.licenses.mit;
      inherit platforms;
    };
  }
)
