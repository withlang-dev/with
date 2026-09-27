# D61 — Debug (`:?`) is recursive, quoted and escaped; an explicit `impl Debug` is honored at every depth; maps print sorted

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric: option (a), "bless the
second as written, with one addition" — sort map keys — and the derive
question decided by the existing "Available for all types"). §15.4.7 and
§11.9 carry the text.

**Decision.** Every struct field, enum payload and collection element is
formatted with `:?`, so a value formats the same at every depth. A `str` is
quoted and escaped (`\"`, `\\`, C0 controls and DEL as `\n` `\t` `\r` `\0`
`\xHH`); printable non-ASCII appears as itself, so `"café"` reads `"café"`.
A type with an explicit `impl Debug` formats through its `debug_str` at top
level and nested alike; every other type uses the generated form. `:?`
needs no derive; `@[derive(Debug)]` provides the trait for `T: Debug`
bounds. `HashMap` entries print ordered by the Debug text of their keys;
`BTreeMap` in key order.

**Why.** Before this, `P { name: "x, y" }` printed `P { name: x, y }`,
`V("x, y")` and `W("x", "y")` printed identically, the top-level string
`q"t` printed `"q"t"`, and `Vec`/`HashMap` printed the placeholder
`<unsupported>` — a live no-silent-fallback violation. Rust's derived Debug
and Swift's `debugPrint` both format nested values in debug form; Go's `%v`
does not, and its `%#v` does. §11.9 said `:?` "does not dispatch through"
the Debug trait, which under recursion would make formatting depth-dependent;
it now honors an explicit impl everywhere. Maps sort because Debug is for
humans and diffs: a seeded hash order would make every snapshot of a map
flaky and break byte-identical fixpoint wherever a map is debug-printed
during self-hosting. Keys sort by their Debug text because a `HashMap` key
need not be `Ord`.

**Not decided here.** With has no `char` type (`'a'` is a `u8`), so there is
no `char` row and no `\'` escape; a character type is its own ruling.

---
