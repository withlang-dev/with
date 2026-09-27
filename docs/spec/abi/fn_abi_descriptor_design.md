# The FnAbi Descriptor — one source of truth

## Implementation snapshot — 2026-09-12

`src/FnAbi.w` defines the immutable `FnAbi` and `ArgAbi` records.
`Codegen.compute_fn_abi` interns descriptors from finalized source types,
declared place/reference modes, and calling convention. Named declarations,
concrete specializations, async declarations, callable types, closures, adapters, and destructor
entries use this classifier. Symbol aliases and LLVM function values point to
the same descriptor; callable types cache their descriptor by resolved type and
convention. No byval/direct parameter masks or parallel reference-ABI tables
remain.

`push_call_arg` handles physical argument marshalling. Callee parameter binding,
LLVM function types, aggregate return handling, and call attributes read the
descriptor. Semantic adjustments such as contextual Copy and constructing a dyn
value happen before physical ABI marshalling. A fat value's already-built LLVM
aggregate receives the target's Direct/Indirect mode; `PM_FAT` is reserved, not a
second classifier. Fixed runtime/intrinsic calls retain the Group A exemption
described below.

Consuming destructor receivers remain owned, with `Indirect` plus
`owned_place`: their body and the following compiler-generated field cleanup
must observe the same storage. This does not turn an owned parameter into a
borrow. See [the current ABI description](with-abi.md).

Regression coverage includes callable C and With `c_va_list` across all five
targets, explicit pointers, C aggregate returns, closures and adapters,
consuming receivers, inferred async returns, and aggregate parameters beyond
the former 64-bit mask (including default trait methods).
LLVM declaration and call audits check descriptor shapes and byval attributes.
`da_trait_default_tail.w` additionally checks the cleanup frame shared in intent
with ordinary function bodies; broader synthesized-body ownership audit coverage
is tracked in #1117. Missing/undefined callee coverage in the audit is tracked
in #1119; native execution also guards the wide default-method regression.

The analysis below records the original architectural finding and proposed
rewire. Statements that With lacked descriptors describe that earlier compiler.

> **2026-07-23 ownership-mode amendment.** The one-descriptor architecture in
> this document remains canonical (D6), but its D5 effect-inferred SHARE-PLACE
> classifier is superseded. Source ownership now comes from the signature:
> `&T` borrows, plain `T` consumes, and receiver modes govern receiver passing.
> An explicit `&T` is a reference value with the ABI of that reference type.
> `IndirectPlace` remains a physical by-place mechanism for compiler-modeled
> borrowed places such as in-place receivers; it is not the default for a
> read-only plain `T`.
>
> **D22 boundary.** `docs/d22-Eric-Ruling.md` is authoritative. Contextual Copy
> is a semantic expression adjustment after ordinary resolution; it must never
> choose or mutate a function ABI, overload, receiver mode, or lookup signature.
> Once resolution establishes an owned `T` demand, the adjusted expression is
> passed using that already-resolved signature's single `FnAbi` descriptor.

Answering the three questions for the *call-lowering* problem (the cathedral),
the same way we answered them for share-place. The finding: the transparent
`T*`/`T**` divergence is not a quirk — it is the textbook symptom of With lacking
the one structure every serious compiler has.

## 1. How the references deal with it (grounded in their source)

The problem: lowering a call requires deciding, per argument, its *passing form*
(value / by-pointer-to-copy / by-pointer-to-place / fat-pointer / sret / ignore),
and the **callee prologue** (how params are received) and **every call site**
(how args are passed) MUST agree. If each side — or each call path — derives that
independently, they diverge. That divergence is exactly With's transparent bug:
two call paths computing different ABIs for the same callee.

Every reference prevents it the same way: **compute a per-function ABI descriptor
ONCE, and have both the prologue and all call sites read that same descriptor.**

- **Rust** — `FnAbi { args: [ArgAbi { mode: PassMode, .. }], ret }`
  (`rustc_target/src/callconv/mod.rs`). `PassMode = Ignore | Direct | Pair | Cast
  | Indirect { on_stack, .. }`. Computed once: `fn_abi = cx.fn_abi_of_instance(..)`
  (`rustc_codegen_ssa/src/mir/mod.rs:187`), then the SAME `fn_abi` drives the
  caller's arg emission, the callee prologue, AND the return
  (`fn_abi.args[i].mode`, `fn_abi.ret.mode` — `mir/block.rs:548`). Rust literally
  names the per-arg thing `PassMode` — the exact one-descriptor architecture
  With needs.
- **Go** — `ABIParamResultInfo` (`InParams()`/`OutParams()` → `ABIParamAssignment`
  per param), computed once by `ABIAnalyzeFuncType` (`internal/abi/abiutils.go`).
  Caller (ssagen) and callee prologue read the one assignment.
- **Zig** — the interned `fn_info` + one classification (`firstParamSRet(fn_info)`,
  `isByRef`) consulted by both the function-def lowering and every call
  (`src/codegen/llvm.zig:1276+`).
- **Clang/LLVM** (which With targets) — `CGFunctionInfo` with a per-arg
  `ABIArgInfo` (`Direct | Extend | Indirect(byval) | Expand | InAlloca | Ignore
  | CoerceAndExpand`), computed once by `ABIInfo::computeInfo`, cached, and read
  by BOTH `EmitFunctionProlog` (callee) and `EmitCall` (caller).

**Universal pattern:** one ABI descriptor per function, a vector of per-arg pass
modes, computed once, the single source of truth for prologue + all call sites.
Divergence is impossible by construction. With is the outlier: it has no such
descriptor, so the ABI is re-derived per call path — and they drifted.

## 2. The greenfield minimal design

One structure, computed once, read by both sides:

```
FnAbi(sig) = { args: [ArgAbi], ret: ArgAbi, sret: bool }
ArgAbi     = { pass: PassMode, llvm_ty }
PassMode =
    Direct          // by value (SSA/register) — Copy types, small scalars
    Indirect        // pointer to a CALLEE-OWNED copy (byval) — owned aggregates
    IndirectPlace   // pointer to a borrowed CALLER place — in-place receiver;
                    //   callee may mutate it and does NOT drop it
    Fat             // dyn-trait fat pointer
    Ignore          // zero-sized
```

`compute_fn_abi(sig)` computes it once (cached per signature) from the declared
parameter/receiver mode plus physical type shape: plain consuming scalars use
`Direct`, plain consuming aggregates use the target's owned `Direct`/`Indirect`
form, explicit `&T` is a borrowed pointer value, `mut fn` receivers use
`IndirectPlace`, `move fn` receivers use an owned mode, and dyn values use
`Fat`. Inferred body effects remain analysis facts; they never select a
different source ownership contract. Then:

- **Callee prologue** (`declare_function`): for each `ArgAbi`, emit the param type
  + attrs from `pass` (Direct → value; Indirect/IndirectPlace → `ptr` + byval/
  noalias; Fat → fat-ptr). ONE loop.
- **Every call site**: `push_call_arg(fn_abi, i, operand)` — Direct → value;
  Indirect → owned-temp + ptr; IndirectPlace → address-of-caller-place (with the
  #568 already-a-pointer short-circuit + rvalue temp); Fat → build fat-ptr. ONE
  routine.

**The transparent `T*`/`T**` question dissolves:** the transparent receiver's
pass mode is decided ONCE in `compute_fn_abi`; every caller and the callee read it.
Two paths cannot disagree because there is only one decision. By-place receiver
passing is then one `IndirectPlace` variant, and callee-no-drop +
caller-address-passing are automatically consistent — they read the same ArgAbi.

## 3. What to rewire in With to conform

With today splatters the ABI across `value_ref_abi` (a bit), `internal_abi_needs_
indirect_param` (recomputed), byval masks, `fn_ref_param_*` records, sret flags,
and per-path receiver logic. The rewire consolidates all of it into one
descriptor:

1. **Introduce `FnAbi`/`ArgAbi`/`PassMode` + `compute_fn_abi(sig)`**, cached per
   sig and computed from the finalized declared signature and receiver mode.
   This subsumes `value_ref_abi`, `internal_abi_needs_indirect_param`, the byval
   mask, `fn_ref_param_*`, and the sret flag into ONE place.
2. **`declare_function` reads `FnAbi`** for the prologue — replaces the ad-hoc
   param-type/byval/value_ref_abi logic (Codegen.w:4088-4123).
3. **Collapse the ~3 call-lowering loops** (concrete 14049-14158, generic
   12884-12909, Group B receiver blocks) into one `push_call_arg(fn_abi, i,
   operand)` keyed on `PassMode`. This is the cathedral — now *descriptor-driven*,
   not per-path guesswork. The runtime/intrinsic (Group A) sites keep pushing
   synthesized constants (their "sig" is a fixed runtime ABI, expressible as a
   trivial FnAbi or left as-is).
4. **The transparent divergence is fixed at the root** — one `PassMode` per
   transparent param, read everywhere. No per-path special-casing.
5. **A compiler-modeled borrowed place = `IndirectPlace`** when the finalized
   receiver/contract requires the caller's storage itself; callee-no-drop follows from
   `pass == IndirectPlace`, and caller-address passing follows from the same
   descriptor. Explicit `&T` remains a reference value, plain `T` stays owned,
   `move x` is an explicit owned rvalue, and `copy x` creates an independent
   owned value.

The order: build `FnAbi` + `compute_fn_abi` as the descriptor (behavior-neutral:
reproduce today's classifications) → route `declare_function` + `push_call_arg`
through it (behavior-neutral cathedral, transparent bug fixed by unification) →
then classify compiler-modeled borrowed-place receiver/contracts in one place. The
cathedral brick already landed (`mir_ref_arg_ptr`) is the `IndirectPlace`
marshalling code; it becomes the `push_call_arg` IndirectPlace arm.

## One-sentence version

Every serious compiler computes a per-function ABI descriptor (Rust `FnAbi`/
`PassMode`, Go `ABIParamResultInfo`, Clang `CGFunctionInfo`) once and shares it
between the callee prologue and all call sites; With lacks it, re-derives the ABI
per call path, and they drifted (the transparent `T*`/`T**` bug) — so the real
move is to **introduce `FnAbi`/`compute_fn_abi` as the single ABI source of
truth**, after which the cathedral is just "both sides read the descriptor" and
declared by-place receiver passing is one `PassMode`.
