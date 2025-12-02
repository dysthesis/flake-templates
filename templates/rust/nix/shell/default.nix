{
  perSystem = {
    pkgs,
    craneLib,
    inputs',
    ...
  }: let
    valeConfigured = pkgs.callPackage ./vale {};
  in {
    devShells.default = craneLib.devShell {
      packages = with pkgs; [
        # Nix
        nixd
        statix
        deadnix
        nixfmt
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
        lean
      ];
    };
  };
}
