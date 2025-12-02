{
  perSystem = {
    pkgs,
    craneLib,
    inputs',
    lean-translation,
    aeneasLib,
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
        lean4
      ];
      LEAN_SRC_PATH = "${lean-translation}/lib/lean:${aeneasLib}/lib/lean";
      LEAN_PATH = "${lean-translation}/lib/lean:${aeneasLib}/lib/lean";
    };
  };
}
