{
  lib,
  apollyon,
  craneLib,
  commonArgs,
  cargoArtifacts,
  src,
  advisory-db,
  apollyon-proof ? null,
  lean4-nix ? null,
  pkgs ? null,
  inputs' ? null,
  aeneas ? null,
  ...
}: let
  inherit (lib) fold;
  defaultCheckArgs = {
    inherit
      craneLib
      commonArgs
      cargoArtifacts
      src
      advisory-db
      ;
  };

  # Lean check needs different parameters than Cargo-based checks
  leanCheckArgs = {
    inherit
      lib
      apollyon-proof
      lean4-nix
      pkgs
      inputs'
      aeneas
      ;
  };

  mkCheck = name:
    if name == "proofs"
    then {"apollyon-${name}" = import (./. + "/${name}.nix") leanCheckArgs;}
    else {"apollyon-${name}" = import (./. + "/${name}.nix") defaultCheckArgs;};

  checkNames = [
    "clippy"
    "doc"
    "fmt"
    "audit"
    # "deny" # TODO: enable this once licensing is decided
    "nextest"
    # "proofs"
  ];
in
  fold (curr: acc: acc // mkCheck curr) {inherit apollyon;} checkNames
