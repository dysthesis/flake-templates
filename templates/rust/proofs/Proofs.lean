import Aeneas
import Libtemplate.Funs

open Aeneas.Std Result Error
open libtemplate

set_option allowUnsafeReducibility true
attribute [local reducible] libtemplate.fibonacci

-- Rewrite-friendly version of the generated step function
def fib_step (f : U64 → Result U64) (n : U64) : Result U64 :=
  match n with
  | 0#uscalar => ok 1#u64
  | 1#uscalar => ok 1#u64
  | _ => do
    let i ← n - 1#u64
    let i1 ← f i
    let i2 ← n - 2#u64
    let i3 ← f i2
    i1 + i3

namespace Proofs

/-- A mathematical specification of the Fibonacci sequence matching the Rust implementation. -/
def fibNat : Nat → Nat
| 0 => 1
| 1 => 1
| n + 2 => fibNat (n + 1) + fibNat n

/-- The generated function agrees with the first base case. -/
@[simp] theorem fibonacci_zero : fibonacci 0#u64 = ok 1#u64 := by
  have h := Lean.Order.fix_eq (f := fib_step) (hf := fibonacci._proof_3)
  have h0 := congrArg (fun g => g 0#u64) h
  simpa [fib_step, fibonacci]

/-- The generated function agrees with the second base case. -/
@[simp] theorem fibonacci_one : fibonacci 1#u64 = ok 1#u64 := by
  have h := Lean.Order.fix_eq (f := fib_step) (hf := fibonacci._proof_3)
  have h0 := congrArg (fun g => g 1#u64) h
  simpa [fib_step, fibonacci]

end Proofs
