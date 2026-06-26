{
  description = "With language compiler";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      flake.overlays.default = final: prev: {
        withlang-llvm = prev.callPackage ./nix/withlang-llvm.nix { };
        withlang-seed = final.callPackage ./nix/withlang-seed { };
        withlang = final.callPackage ./nix/withlang { };
      };

      perSystem =
        { system, ... }:
        let
          pkgs = self.legacyPackages.${system};
        in
        {
          legacyPackages = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };

          packages = {
            default = pkgs.withlang;
            inherit (pkgs) withlang withlang-llvm withlang-seed;
          };

          apps.default = {
            type = "app";
            program = "${pkgs.withlang}/bin/with";
            meta.description = "Run the With compiler";
          };

          checks = {
            inherit (pkgs) withlang;
          }
          // pkgs.withlang.passthru.tests;
        };
    };
}
