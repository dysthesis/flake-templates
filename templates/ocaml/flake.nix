{
  outputs =
    inputs@{
      flake-parts,
      opam-nix,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        ./nix/pkgs
        ./nix/shell
        ./nix/formatting
        ./nix/checks
      ];

      perSystem =
        { system, ... }:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          on = opam-nix.lib.${system};

          # Filter source to exclude build artifacts
          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter =
              path: type:
              let
                baseName = baseNameOf path;
              in
              # Exclude build artifacts and editor files
              baseName != "_build"
              && baseName != "_opam"
              && baseName != ".direnv"
              && baseName != "result"
              && !pkgs.lib.hasSuffix ".swp" baseName
              && !pkgs.lib.hasSuffix ".swo" baseName;
          };

          # Discover local packages (gracefully handles empty repositories)
          localPackagesQuery = builtins.mapAttrs (_: pkgs.lib.last) (on.listRepo (on.makeOpamRepo src));

          # Development packages for tooling
          devPackagesQuery = {
            ocaml-lsp-server = "*";
            ocamlformat = "*";
          };

          # Merged query for scope construction
          query = devPackagesQuery // {
            ocaml-base-compiler = "*";
          };

          # Build the opam scope
          scope = on.buildOpamProject' { } src query;

          # Apply overlays (currently empty)
          overlay = final: prev: {
            # Custom package overrides can be added here
          };
          scope' = scope.overrideScope overlay;

        in
        {
          _module.args = {
            inherit
              pkgs
              on
              scope'
              localPackagesQuery
              devPackagesQuery
              ;
          };
        };
    };

  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    nixpkgs.follows = "opam-nix/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
