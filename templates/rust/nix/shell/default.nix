{
  perSystem =
    {
      pkgs,
      craneLib,
      inputs',
      self',
      ...
    }:
    let
      valeConfigured = pkgs.callPackage ./vale { };

      # Packages from this flake
      leanTranslation = self'.packages.lean-translation;
      aeneasLib = self'.packages.aeneas-lean-backend;
    in
    {
      devShells.default = craneLib.devShell {
        packages = with pkgs; [
          # Nix
          nixd
          statix
          deadnix
          alejandra

          # Rust
          cargo-audit
          cargo-expand
          cargo-nextest
          rust-analyzer
          cargo-wizard
          bacon

          # Prose
          valeConfigured

          # Theorem proving
          inputs'.aeneas.packages.aeneas
          lean4
        ];

        LEAN_SRC_PATH = "${leanTranslation}/lib/lean:${aeneasLib}/lib/lean";
        LEAN_PATH = "${leanTranslation}/lib/lean:${aeneasLib}/lib/lean";
      };
    };
}
