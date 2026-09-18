# Primary verification — `src/Codegen.w` (+ `src/FnAbi.w` surface)

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `712585eec37660652d9c104c57d413b149752d69ea3421861841599887edab9b`
(`src/FnAbi.w`: `fbb768318dd046b1ee6d54af7b2b16c1a00795f3310bb62520f5725e8ec04b80`
— read for the classifier surface only, not checked off as a module)
Source examined: child Codegen.w 1-6516 complete (four reads) + FnAbi.w 134;
primary: call-lowering 2185-2274 (full read), D6 comment + classifier
4680-4724 (full read), declaration classifier 4426-4495 (full read),
`arg_pass_mode`/`declare_function_from_sig`/`compute_fn_abi` call-graph
(grep-verified), no probe (no behavioral divergence demonstrated — see below)

## Scope examined

Call lowering, function declaration, C-ABI attribute application, FnAbi
single-source rule (AGENTS.md D6).

Applicable overview targets examined: T2-3 (call/return + ABI), T13-14
(emission validity), T23 (fallbacks), T24 (classifier duplication).

## ABI-001 — per-path classifiers, NO demonstrated divergence (NOT filed)

Primary-verified structure:

1. `compute_fn_abi` / `push_call_arg` (the names AGENTS.md D6 mandates) have
   ZERO hits in `src/`. The live classifier is `Codegen.arg_pass_mode`
   (`:4719-4724`, wrapping `fn_abi_pass_mode` in `src/FnAbi.w:39`) fed by
   Sema's share-place verdict + the platform aggregate rule.
2. `arg_pass_mode` is called ONLY from `declare_function_from_sig`
   (`:4749`, `:4773`) — verified by grep; only three call sites route
   through `declare_function_from_sig` (`:4385`, `:4824`, `:4858`).
3. `declare_function_at_inner` (`:4341+`) classifies INLINE with its own
   if-chain (`:4426-4495`, primary-read): value_ref_abi → ptr, owner-type →
   ptr, fn-type → fat pointer, extern-fn → ptr, dyn → resolve, explicit-ref
   → resolve — never calling `arg_pass_mode`.
4. Call sites read RECORDED maps (`extern_fn_has_sret/byval/direct` in
   `coerce_call_args_for_fn_value`, `:2185-2238`, primary-read) — the
   record-once/read-everywhere shape, compliant in itself.

So the single-source rule is structurally violated (two live classifiers +
a mandated-but-nonexistent canonical name), but primary produced NO failing
probe: if each function kind consistently takes one declaration path for
both its declaration and all uses, behavior stays coherent, and the child
supplied no divergence execution. Per the audit's own execution standard
(findings require observed behavior), this is recorded as an architectural
risk for the owner, NOT filed as a defect. The evidence a future filing
needs: one signature classified differently by the two paths with an
observable caller/callee disagreement.

## Notes

- `src/FnAbi.w` itself (PM_* constants + `fn_abi_pass_mode`) is small and
  sane; it is NOT checked off — it falls in a later wave with its neighbors.
