{
  perSystem =
    {
      scope',
      ...
    }:
    {
      treefmt = {
        projectRootFile = "flake.nix";

        programs.nixfmt.enable = true;

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
