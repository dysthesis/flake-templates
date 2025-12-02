# This is the entrypoint of the flake. This file should define constants that
# are shared across various modules.
{
  description = "Rust project";

  outputs =
    inputs@{
      flake-parts,
      crane,
      advisory-db,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      perSystem =
        {
          # NOTE: This packages is only used to construct the common argument for
          # crane; the actual `pkgs` used in the other Nix modules are defined
          # below
          pkgs,
          system,
          ...
        }:
        let
          craneLib = crane.mkLib pkgs;
          # Common arguments can be set here to avoid repeating them later
          # NOTE: changes here will rebuild all dependency crates
          src = craneLib.cleanCargoSource ./.;
          commonArgs = {
            inherit src;
            strictDeps = true;

            buildInputs = pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.libiconv
            ];

            nativeBuildInputs = [
              pkgs.pkg-config
            ];
          };

          cargoArtifacts = craneLib.buildDepsOnly commonArgs;

          charonToolchain = inputs.aeneas.inputs.charon.packages.${system}.rustToolchain;
        in
        {
          _module.args = {
            inherit
              craneLib
              cargoArtifacts
              commonArgs
              src
              charonToolchain
              advisory-db
              ;

            # NOTE: This is where overlays, and other such modifications to the
            # general shared packages list.
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.rust-overlay.overlays.default
                (inputs.lean4-nix.readToolchainFile ./proofs/lean-toolchain)
              ];
            };
          };
        };
      imports = [
        ./nix/shell
        ./nix/pkgs
        ./nix/checks
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # General rust stuff
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };

    # Theorem proving
    aeneas.url = "github:AeneasVerif/aeneas";
    lean4-nix.url = "github:lenianiva/lean4-nix";

    # Formatting
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
}
