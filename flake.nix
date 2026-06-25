{
  description = "With programming language compiler";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forEachSystem = f:
        nixpkgs.lib.genAttrs systems (system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
            inherit system;
          }
        );
    in
    {
      packages = forEachSystem ({ pkgs, ... }: {
        llvm-sdk = pkgs.callPackage ./nix/llvm-sdk.nix { };
      });

      overlays.default = final: prev: {
        with-llvm-sdk = prev.callPackage ./nix/llvm-sdk.nix { };
      };
    };
}
