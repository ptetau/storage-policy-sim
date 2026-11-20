/-
A helper for code that is not built yet. A stub calls `todo`, which panics with a message that
holds "not implemented". The test runner reads that message.
-/
namespace StoragePolicySim

/-- The body of a stub. It panics when the stub runs, and names the stub. The number keeps the
compiler from running the panic once at the start of the program. -/
@[noinline] def todo {α : Type} [Inhabited α] (what : String) (_n : Nat) : α :=
  panic! ("not implemented: " ++ what)

end StoragePolicySim
