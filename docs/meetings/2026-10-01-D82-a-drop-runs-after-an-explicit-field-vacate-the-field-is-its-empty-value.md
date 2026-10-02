# D82 — A destructor runs after an explicit field vacate; the vacated field is its empty value; the storage sentinel is not a disarm

**Date:** 2026-10-01. **Status:** BDFL ruling (Eric: "Approved." on the
brief). No normative spec text changes: §2.2 (D32), §2.5.1 and D72 already
rule it; the implementation was non-compliant. Issue #1944 (the hunt that
exposed it).

**Question.** `var v = Value { text: "a".to_owned() }; let t = move v.text`
where `Value` implements `Drop`. The vacate leaves `v`'s storage all zero,
which the guarded drop (§2.5.1) reads as the moved-out sentinel, so
`Value`'s destructor was skipped — but only for a one-field type; a
two-field `Tagged { kind: i32, text: str }` ran its destructor after the
same vacate, with `kind == 0` and `kind == 7` alike.

**Ruling.** The explicit vacate is legal outside the type (§2.2, D32: "no
type condition"; the `FileWrapper { fd: move w1.fd, … }` example is a
`Drop` type). The containing value stays live, and its destructor runs at
the usual point with the vacated field holding its valid empty value
("reset-on-move leaves the field a valid empty value — the take", §2.2).
All-zero storage left by a vacate is therefore a live value, D72's exact
case ("a `Drop` type whose all-zero storage can be a live value … cannot
use its storage as the sentinel"), and never a disarm: "the only way to
skip a destructor is a spelling that is visible at the type's own
boundary" (§2.5.1), and `move w1.fd` in a caller is not one.

**Alternatives weighed.** (a) Refuse the vacate on `Drop` types, as Rust
(E0509, `rustc_borrowck/src/borrowck_errors.rs:314`) and Swift ("cannot
partially consume … when it has a deinitializer",
`DiagnosticsSIL.def:896`) do: reopens D32's uniformity and makes the
application developer write `.clone()` or wait for a `move fn take_*()` —
Rust's ceremony with a guardrail the empty-value contract already gives.
(b) Today's accidental behavior, the destructor skipped when storage is
all zero: whether a destructor fires would depend on sibling fields' bytes
from a spelling invisible at the type boundary — fails §2.5.1 outright.

**Implementation (the compiler's representation choice, not the ruling).**
`struct_decl_needs_liveness_byte` (`Sema.w`) inferred "has an owning
non-null field ⇒ zero storage proves a whole-value move ⇒ no byte"; that
inference is sound only while no field can be vacated from a live value,
which §2.2 forbids assuming. Either give such types the D72 byte, or —
preferred, so D72's "pays nothing" stays true for the common case — emit a
per-local drop flag only at a drop site reached both by a path that
whole-moved the local and by a path that vacated one of its fields
(MirLower's field-sensitive move state already knows both); elsewhere the
static answer is exact. The guard elision in `mir_emit_guarded_user_drop`
must stop reading "all zero" as "moved" for a local with a vacated field.
The containing destructor receives the vacated field already reset (the
#1944 branch's reset-before-drop ordering).

**What would reopen this.** Retiring the sentinel model for per-path drop
elaboration (D72 option 2) makes the question moot; a ruling that `Drop`
types refuse field vacates (alternative a) would amend D32 and §2.2 first.
