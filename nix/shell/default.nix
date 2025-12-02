{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # Nix
        nixd
        statix
        deadnix
        nixfmt
        alejandra

        # Rust
        cargo
        rustc
        rust-analyzer
        bacon

        # Lean
        lean4
      ];
    };
  };
}
