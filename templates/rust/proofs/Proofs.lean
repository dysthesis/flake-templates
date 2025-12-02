import Aeneas
import Funs

open Aeneas.Std Result Error
open libtemplate

namespace Proofs

/-- A mathematical specification of the Fibonacci sequence matching the Rust implementation. -/
def fibNat : Nat → Nat
| 0 => 1
| 1 => 1
| n + 2 => fibNat (n + 1) + fibNat n

/-- The generated function agrees with the first base case. -/
@[simp] theorem fibonacci_zero : fibonacci 0#u64 = ok 1#u64 := by
  simp [fibonacci]

/-- The generated function agrees with the second base case. -/
@[simp] theorem fibonacci_one : fibonacci 1#u64 = ok 1#u64 := by
  simp [fibonacci]

end Proofs
