# D221 — The alternatives of an or-pattern share their bindings

**Laws:** 1 (the second arm restates what the first already says), 4 (one
name, one meaning in the arm).

**Date:** 2026-11-18. **Status:** delegated (D98). It adds no ownership
rule: the arm means exactly what the same arm written once per alternative
means. Easy to reverse (programs that use it are rewritten by duplicating
the arm). Prediction 85%. Eric vetoes by revert.

**Context.** #823: `.A(x, ..) | .B(x, ..) => use(x)` was refused as
shadowing, because the checker bound each alternative's names in turn in
one scope, and lowering bound only the first alternative. The workaround
was one arm per alternative with the same body.

**Decision.**

- Every alternative binds the same names, each with one type; the guard
  and the body see one binding per name, made by the alternative that
  matched. Position does not matter; names define the correspondence.
- It is sugar for the duplicated arms: a value is moved once and dropped
  once; a failed guard puts it back in the subject; an observed subject is
  still observed, and the name is the payload in place.
- A missing name, an extra name, or two types is an error that names the
  alternative.

**What the others do** (from knowledge, not checked in the reference trees). Rust: the same rule (same names, same types and
binding modes in every alternative). Swift: a `case` with several patterns
requires each to bind the same variables with the same types. Zig has no
or-pattern bindings beyond a shared payload capture of one type.

**How.** The first alternative introduces the bindings; a later one names
them again. Lowering records which alternative matched, binds from it in
its own block into the first alternative's locals (a place binding is held
by reference, since the place differs by alternative), blanks what the
other alternatives scheduled for drop, and on a failed guard restores only
the matched alternative's moves.

**Not in the grammar.** Alternatives nested inside a payload, and `if let`
with `|`. (A list pattern that takes elements inside an alternative was
refused at first; #3459 logs the takes by alternative as well.)

**Reopen if** the one-type rule proves too strict where the types differ
only by a view of the same value.
