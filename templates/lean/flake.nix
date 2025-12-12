{
  description = "Lean 4 Example Project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    lean4-nix.url = "github:dysthesis/lean4-nix/dev";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    lean4-nix,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      perSystem = {
        system,
        pkgs,
        ...
      }: let
        lake2nix = pkgs.callPackage lean4-nix.lake {};
      in {
        _module.args = {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [(lean4-nix.readToolchainFile ./lean-toolchain)];
          };
          inherit lake2nix;
        };
      };

      imports = [
        ./nix/pkgs
        ./nix/shell
      ];

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    };
}
