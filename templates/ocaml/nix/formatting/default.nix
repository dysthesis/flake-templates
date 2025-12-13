{
  perSystem =
    {
      scope',
      ...
    }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        # Nix formatting and linting
        programs.nixfmt.enable = true;
        programs.statix.enable = true; # Nix linter for anti-patterns
        programs.deadnix.enable = true; # Detect unused Nix code

        # OCamlformat from opam scope
        # If treefmt-nix doesn't support programs.ocamlformat natively,
        # use settings.formatter.ocaml instead (see commented alternative below)
        settings.formatter.ocaml = {
          command = "${scope'.ocamlformat}/bin/ocamlformat";
          options = [ "--enable-outside-detected-project" ];
          includes = [
            "*.ml"
            "*.mli"
          ];
        };
      };
    };
}
