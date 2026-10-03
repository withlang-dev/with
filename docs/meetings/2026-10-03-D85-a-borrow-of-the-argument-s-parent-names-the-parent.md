# D85 — A facade operation that hands out a borrow of its argument's parent names it: `returns borrow T from parent T of param N`

**Date:** 2026-10-03. **Status:** BDFL ruling (Eric: "rule the explicit
clause now", then "blessed" on the words). Spec v7.17: ffi.md §16.2b.6.
Extends D51 (the canonical ruling is not edited; this clause is a later
ruling beside it). Issue #2003 (split from #1977). **The compiler is
NON-COMPLIANT** until the facade parser, the contract audit and origin
tracking implement the clause.

**Context.** `sqlite3_db_handle(stmt)` hands out a borrowed `Database`
whose real origin is the statement's parent connection. The only facade
tools were `preserves param N` / `preserves domain D`, which cover every
view of an origin, so `let b = st.database().unwrap(); st.step();
b.changes()` was refused, and `preserves param 0` on `step` would keep
`column_text` views alive across `step`, a use-after-free.

**Decision.** The borrowing operation states the parent:
`returns borrow T from parent T of param N`, resolved through the
argument resource's declared `borrows` clause; naming an undeclared parent
or a type the parent does not have is an error. The borrow lives as long
as the parent's origin, and every operation through it is an operation on
the parent's origin, invalidating the parent's views exactly as the same
call on the parent would. Naming the parent type keeps a resource with
several borrowed parents unambiguous.

**Alternatives rejected.** Per-call `preserves` clauses on every mutating
operation of the child: unsound (keeps child-derived views alive) and
repeated everywhere. Inferring the parent from the `borrows` clause alone:
fails D51's test, since a wrong inference of origin creates unsafety.
Rust ties such a result to the parent lifetime
(`Iter<'a,T>::as_slice -> &'a [T]`), Mojo returns `ref[Self.origin]`;
this is the facade's stated form of the same fact.

**Reopen if** a library hands out a borrow of a grandparent, or of a
parent the argument does not declare in `borrows`.
