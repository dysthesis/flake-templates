{
  lake2nix,
  fetchFromGitHub,
  stdenvNoCC,
  nodejs,
  ...
}: let
  rawSrc = fetchFromGitHub {
    owner = "AeneasVerif";
    repo = "Aeneas";
    rev = "ec7b11e31650d8ac43a608c6b0f094fd91d9163c";
    hash = "sha256-p25AVnGqjk9ppVGfT+DKZUPBdLUXghcRSetgglYvQdg=";
  };

  src = stdenvNoCC.mkDerivation {
    name = "aeneas-lean-backend-cleaned";
    version = "0.1.0";
    src = rawSrc;

    phases = ["installPhase"];

    installPhase = ''
      cp -r $src/backends/lean $out
    '';
  };
in
  lake2nix.mkPackage {
    inherit src;
    roots = ["Aeneas"];
  }
