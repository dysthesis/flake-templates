{
  pkgs,
  lake2nix,
  proofwidgets,
  ...
}: let
  # Mathlib revision exactly matching the Lean backend used by Aeneas
  rev = "c98ae54af00eaefe79c51b2b278361ca94e59bfb";
  src = pkgs.fetchFromGitHub {
    owner = "leanprover-community";
    repo = "mathlib4";
    inherit rev;
    hash = "sha256-1t+547fnaOpSMbLOcIzfWHhWygJeHaWZaPLPHeLxGiI=";
  };
in
  lake2nix.mkPackage {
    name = "mathlib";
    inherit src;

    # Reuse the locally patched ProofWidgets to avoid rebuilding JS assets in
    # bubblewrap.
    depOverride = {
      proofwidgets = {src = proofwidgets;};
    };
  }
