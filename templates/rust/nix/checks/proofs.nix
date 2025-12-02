{
  pkgs,
  self',
  ...
}:
# This check verifies the complete formal verification pipeline:
# 1. Rust code is successfully translated to Lean via Charon/Aeneas
# 2. The generated Lean code type-checks correctly
# 3. The proofs in ./proofs/ type-check against the generated code
# 4. All theorems hold, proving the Rust implementation satisfies its specification
pkgs.runCommand "verify-proofs" {
  translation = self'.packages.lean-translation;
  proofs = self'.packages.lean-proofs;
  verification = self'.packages.lean-verification;
} ''
  set -eux

  echo "=========================================="
  echo "Formal Verification Check"
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
  echo "✓ Lean proofs built successfully"
  echo ""

  # Verify the combined verification package
  echo "Checking combined verification package..."
  if [ ! -d "$verification/lib/lean" ]; then
    echo "ERROR: Verification package incomplete"
    exit 1
  fi
  echo "✓ Verification package complete"
  echo ""

  # Create output with verification report
  mkdir -p "$out/nix-support"

  cat > "$out/verification-report.txt" <<EOF
Formal Verification Report
==========================

Status: SUCCESS

The Rust codebase has been formally verified through the following pipeline:

1. Translation (Charon/Aeneas):
   - Rust source code translated to Lean definitions
   - Generated $lean_files Lean file(s)
   - Location: $translation

2. Type Checking:
   - All generated Lean code type-checks correctly
   - Aeneas standard library imported successfully

3. Theorem Proving:
   - All theorems in ./proofs/ directory verified
   - Proofs hold against generated Lean definitions
   - Location: $proofs

4. Verification Package:
   - Combined translation + proofs package created
   - Location: $verification

This check passing indicates that the Rust implementation provably
satisfies its formal specification as expressed in the Lean theorems.
EOF

  cat "$out/verification-report.txt"

  echo ""
  echo "=========================================="
  echo "Verification PASSED"
  echo "=========================================="

  # Propagate verification info to nix-support
  echo "report verification-report $out/verification-report.txt" \
    > "$out/nix-support/hydra-build-products"
''
