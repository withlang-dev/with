# D6 — `FnAbi` is the single ABI source of truth: compute once, both sides read it, never re-derive per call path

**Date:** 2026-07-06
**Status:** Accepted — CANONICAL standard for all call-ABI lowering
**Design:** `docs/fn_abi_descriptor_design.md` · **Deciders:** Eric (BDFL)

### The standard

Every function signature has ONE ABI descriptor — `FnAbi { args: [ArgAbi], ret,
sret }`, where `ArgAbi = { pass: PassMode, llvm_ty }` and
`PassMode = Direct | Indirect | IndirectPlace | Fat | Ignore`. It is computed
ONCE by `compute_fn_abi(sig)` (cached per sig) and is the **single source of
truth** for both the callee prologue (`declare_function`) and every call site
(`push_call_arg`). No code may re-derive "how is this argument passed" from the
type or context on its own — it reads the descriptor.

`PassMode` meanings: `Direct` = direct value; `Indirect` = pointer to a
callee-owned value (byval); `IndirectPlace` = pointer to a borrowed caller place
(used by in-place receiver modes; the callee does NOT drop it); `Fat` =
dyn-trait fat pointer; `Ignore` = zero-sized. Source ownership is declared by
the signature: an indirect physical ABI never turns plain consuming `T` into a
borrow.

### Why (the reference consensus)

Every serious compiler does exactly this and only this: Rust `FnAbi`/`PassMode`
(`fn_abi_of_instance`, read by caller + prologue + return), Go
`ABIParamResultInfo` (`ABIAnalyzeFuncType`), Zig `fn_info` classification,
Clang/LLVM `CGFunctionInfo`/`ABIArgInfo` (read by `EmitFunctionProlog` +
`EmitCall`). The single descriptor makes caller/callee/path divergence
**impossible by construction**. With historically lacked it — it re-derived the
ABI per call path (`value_ref_abi`, `internal_abi_needs_indirect_param`, byval
masks, `fn_ref_param_*`, sret flags, all separate and recomputed), and the paths
drifted. The transparent `Box`/`Rc`/`Arc` receiver bug (`T*` on the concrete
path, `T**` on the generic path, both "working") is the textbook symptom.

### Protection / the rule going forward

- **All call-ABI classification flows through `compute_fn_abi`.** Adding a new
  call-lowering path, a new receiver shape, or a new parameter kind means
  extending `PassMode`/`compute_fn_abi` in ONE place, then reading it — never
  writing a fresh per-path "value vs address vs byval" decision.
- The scattered predecessors (`value_ref_abi`, per-path
  `internal_abi_needs_indirect_param`, byval masks, `fn_ref_param_*`) are being
  consolidated into `FnAbi`; after consolidation, re-introducing a per-path ABI
  derivation is a regression.
- Explicit reference parameters use the ABI of their reference type. A
  compiler-modeled borrowed place, such as an in-place receiver, uses the
  appropriate by-place descriptor. Callee no-drop and caller address-passing
  remain consistent because both read the same `ArgAbi` — this is *why* the
  descriptor is the right home. Inferred body effects never change a declared
  mode.

### Consequences (the rewire)

Build `FnAbi`/`ArgAbi`/`PassMode` + `compute_fn_abi(sig)` (behavior-neutral —
reproduce today's classifications, resolving the transparent divergence to one
form) → route `declare_function` + one `push_call_arg` through it (the cathedral,
descriptor-driven; the transparent bug fixed by unification). The landed
`mir_ref_arg_ptr` brick is the `IndirectPlace` marshalling arm for declared
by-place contracts.

---
