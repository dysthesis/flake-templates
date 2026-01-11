{
  perSystem = {
    lib,
    pkgs,
    self',
    advisory-db,
    craneLib,
    commonArgs,
    cargoArtifacts,
    src,
    ...
  }: {
    checks = let
      inherit (lib) fold;
      defaultCheckArgs = {
        inherit
          craneLib
          commonArgs
          cargoArtifacts
          src
          pkgs
          advisory-db
          ;
        inherit self';
      };

      mkCheck = name: {
        "package-${name}" =
          import (./. + "/${name}.nix") defaultCheckArgs;
      };

      checkNames = [
        "clippy"
        "doc"
        "fmt"
        "audit"
        "nextest"
        "taplo"
        "deny"
        "hakari"
      ];
    in
      fold
      (curr: acc: acc // mkCheck curr)
      {package = self'.packages.my-cli;}
      checkNames;
  };
}
