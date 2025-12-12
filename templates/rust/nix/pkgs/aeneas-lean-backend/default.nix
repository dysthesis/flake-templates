{
  lake2nix,
  fetchFromGitHub,
  proofwidgets,
  ...
}:
let
  rawSrc = fetchFromGitHub {
    owner = "AeneasVerif";
    repo = "Aeneas";
    rev = "ec7b11e31650d8ac43a608c6b0f094fd91d9163c";
    hash = "sha256-p25AVnGqjk9ppVGfT+DKZUPBdLUXghcRSetgglYvQdg=";
  };

  src = "${rawSrc}/backends/lean";
in
lake2nix.mkPackage {
  inherit src;
  roots = [ "Aeneas" ];
  depOverride = {
    proofwidgets = {
      src = proofwidgets;
    };
  };
}
