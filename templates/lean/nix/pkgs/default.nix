{
  perSystem = {
    pkgs,
    lake2nix,
    ...
  }: let
    inherit (pkgs) callPackage;
  in {
    packages = rec {
      mathlib = callPackage ./mathlib {
        inherit pkgs lake2nix proofwidgets;
      };

      proofwidgets = callPackage ./proofwidgets {inherit lake2nix;};

      default = lake2nix.mkPackage {
        src = ./.;
        roots = ["Example"];
      };
    };
  };
}
