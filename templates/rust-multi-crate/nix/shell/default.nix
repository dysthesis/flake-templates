{
  perSystem = {
    pkgs,
    craneLib,
    self',
    system,
    ...
  }: let
    valeConfigured = pkgs.callPackage ./vale {};
  in {
    devShells.default = craneLib.devShell {
      checks = self'.checks.${system};
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
        cargo-hakari

        # Prose
        valeConfigured
      ];
    };
  };
}
