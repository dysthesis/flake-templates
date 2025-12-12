{pkgs, ...}: let
  mathlibPkg =
    if pkgs ? lean4Packages && pkgs.lean4Packages ? mathlib
    then pkgs.lean4Packages.mathlib
    else
      pkgs.mathlib
    or
      throw
      "mathlib derivation not found in pkgs; ensure the lean4 overlay is applied.";
in
  mathlibPkg
