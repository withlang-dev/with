# D184 — A script's top-level bindings are module globals assigned in statement order

**Laws:** 1, 6 (docs/mission.md); D175.

**Date:** 2026-11-02. **Status:** ruled by Eric on the brief for #2951.

**Ruling (Eric's words).** "A script's `let`/`var` are module globals
assigned in statement order, a helper reading one before its line ran
hits the D175 uninitialized-access error, and that error *must* be a
compile-time one, which D175 makes possible because the dependency graph
is static. The script model is 'statements run top to bottom,' and a
global assigned in statement order preserves that. One thing to state: a
script that defines `fn main` loses nothing, because then there are no
top-level statements to order."

**What it means.** In a file with top-level statements (no `fn main`),
every top-level `let` and `var` is a global of the module: a helper `fn`
in the file names it as it names any global. The statements run top to
bottom and each binding is assigned where its statement stands; a call
reaching a binding before its statement has run is the D175
uninitialized-access error, reported at compile time from the static
dependency graph. A file with `fn main` has no top-level statements, so
nothing changes for it.

**Why.** Law 1: a helper that cannot see the counter it bumps forces the
value through parameters, ceremony the compiler can remove. Law 6: a
top-level binding is inside the module, where nothing is promised to a
reader outside it, so it is a module global, not a local of a synthesized
`main`. Python's module globals and Swift's `main.swift` are the model.

**Implementation.** The implicit-main lowering hoists top-level bindings
to module globals with statement-order assignment; D175's static
dependency check covers reads from helpers; fixtures for a helper that
bumps a counter, a helper called before the binding's line (compile
error), and a file with `fn main` unchanged.
