{
  pkgs,
  self',
  ...
}:
pkgs.runCommand "verify-proofs"
{
  translation = self'.packages.lean-translation;
  inherit
    (self'.packages)
    proofs
    verification
    ;
}
''
  set -eux

  echo "=========================================="
  echo "Lean proofs check"
  echo "=========================================="
  echo ""

  # Verify translation exists and contains generated Lean files
  echo "Checking Rust-to-Lean translation..."
  if [ ! -d "$translation/lib/lean" ]; then
    echo "ERROR: Translation output not found"
    exit 1
  fi

  lean_files=$(find "$translation/lib/lean" -name "*.lean" -type f | wc -l)
  if [ "$lean_files" -eq 0 ]; then
    echo "ERROR: No Lean files generated from Rust"
    exit 1
  fi
  echo "✓ Found $lean_files generated Lean file(s)"
  echo ""

  # Verify proofs built successfully
  echo "Checking Lean proofs..."
  if [ ! -d "$proofs/lib" ]; then
    echo "ERROR: Proofs output not found"
    exit 1
  fi
  echo "Lean proofs built successfully"
  echo ""

  # Verify the combined verification package
  echo "Checking combined verification package..."
  if [ ! -d "$verification/lib/lean" ]; then
    echo "ERROR: Verification package incomplete"
    exit 1
  fi
  echo "Verification package complete"
  echo ""
''
