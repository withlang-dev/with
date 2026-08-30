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

      flake.overlays.default = _: prev: {
        withlang-bin = prev.callPackage ./nix/withlang-bin { };
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
            default = pkgs.withlang-bin;
            inherit (pkgs) withlang-bin;
          };

          apps.default = {
            type = "app";
            program = "${pkgs.withlang-bin}/bin/with";
            meta.description = "Run the With compiler";
          };

          checks.withlang-bin = pkgs.withlang-bin;
        };
    };
}
