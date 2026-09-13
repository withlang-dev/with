# Storage Types and Caller-Place Parameters — Implementation Notes

Companion to `storage-types-and-caller-places-spec.md`. This document
says how to build the feature in the With compiler: which modules
change, in what order, what each stage must prove before the next
starts, and where the tests go. Module and function names below were
checked against `src/` at the time of writing; line numbers are omitted
because they rot.

Governing discipline, unchanged from the D22 and fn-ABI campaigns: every
stage lands behind a green test suite, every rule in the spec gets a
pinned fixture, and no stage may regress an existing lane. Behavior-
neutral refactors land first and separately from behavior changes.

---

## 0. Dependency order

```
S1  physical-type capabilities (BitwiseCopyable / AnyBitPattern)
S2  storage type: parse, declare, layout check
S3  storage projections as places + origin facts
S4  storage codegen
S5  storage reflection + diagnostics polish
        │
P1  ParamMode in signatures + call-site spelling
P2  FnAbi alias contract + codegen attrs
P3  borrow checker: exclusivity, byref class, no-move-out
P4  reservation between designator evaluation and invocation
P4b returned-view provenance across calls
P5  suspend / first-class / closure restrictions
P6  intra-callee byref may-alias
```

S1–S5 have no dependency on P. P3 depends on S3 (origin overlap facts).
P1–P2 can proceed in parallel with S2–S4.

**Feature gate.** `inout`/`byref` in source programs remain rejected
(or accepted only under an internal `--enable-caller-places` gate used
by the test lanes) until *every* P stage, P1 through P6 including P4b,
has landed. "P6 landed" below is shorthand for that. Every intermediate state is unsafe
for real programs: after P1 alone, `byref` inherits today's `noalias`;
after P2 before P3, overlapping `inout` is accepted with an exclusive
ABI contract; before P4, a projected place can go stale during argument
evaluation; before P4b, a view returned from `fn balance(r: inout Rec) -> &i32`
carries no caller origin and the borrow checker's cross-call facts are
wrong; before P6, the callee's alias model is incomplete. The
refactors land separately and green; the *language* feature lands once.
Accordingly, S4 + P2 (a storage value passed `inout`, projection
mutated, round-tripped through LLVM) is an internal lowering milestone,
not a usable-language milestone.

---

## Part A — Storage types

### S1. Capabilities

**Where.** `SemaTypes.w` (type property queries), `SemaDecl.w` (derive
at declaration), `CapabilityRegistry.w` if the existing registry is the
right home for compiler-derived traits (check before adding a parallel
mechanism).

**What.**
- Two new derived predicates on `TypeId`: `is_bitwise_copyable(ty)` and
  `is_any_bit_pattern(ty)`. Both memoized per type like the existing
  `Copy` query.
- Base cases: fixed-size integers (both), `f32`/`f64` (`BitwiseCopyable`
  only — NaN payloads are valid bits, but keep floats out of
  `AnyBitPattern` for v1 to avoid a debate we don't need), `bool`
  (`BitwiseCopyable` only; `2` is not a `bool`), `bytes[K]` (both),
  raw pointers (`BitwiseCopyable` only).
- Structural cases: `[T; K]` inherits both from `T`. A `@[repr(C)]` or
  `@[repr(packed)]` struct is `BitwiseCopyable` iff every field is and it
  has no `Drop`; `AnyBitPattern` iff every field is *and there is no
  padding* (padding bytes are unspecified, so the struct's size has
  bits not covered by any field — treat as not `AnyBitPattern` unless
  packed with no gaps).
- Storage types (S2) are both by construction.
- `impl Drop` anywhere in the type → not `BitwiseCopyable`.
- Ephemeral types (§5) → neither.
- A `@[physical]` attribute (std/compiler-internal; rejected in user
  code) requests exact layout: alignment 1, no padding, size = sum of
  fields, and **every field must itself have alignment 1** (`u8`, `i8`,
  `[u8; N]`, other `@[physical]` types). Otherwise ordinary field access
  on a `@[physical]` value at an odd address would need its own
  unaligned lowering; keeping fields at alignment 1 means `@[physical]`
  needs no codegen support at all. It does **not** assert either
  capability. The compiler still
  derives `BitwiseCopyable` and `AnyBitPattern` structurally from the
  fields, so `@[physical] type Bad { flag: bool }` is `BitwiseCopyable`
  but not `AnyBitPattern` and is rejected as a projection type. This is
  how `text[N, Enc]` and `packed_dec[P, S]` are declared without
  compiler special cases, and without the attribute being able to lie.

**Tests.** `test/compile_errors/` fixtures for each false case (a type
with `Drop` claimed bitwise; a padded struct claimed any-bit-pattern);
`test/comptime_diff/` fixtures asserting `T.is_bitwise_copyable()` via
reflection once S5 exposes it.

**Done when.** Both predicates are queryable, memoized, and pinned.

### S2. Parse, declare, layout check

**Where.** `Lexer.w` (no new token kinds; `storage`, `overlay`, `at` are
contextual identifiers), `Parser.w`/`Parse.w` (new decl form), `Ast.w`
(`TypeDeclKind.Storage = 7`; a new node kind for a projection carrying
`(name, type_node, offset, overlay_group)`), `SemaDecl.w` (declaration
and layout verification).

**Parsing.** `storage` is recognized only as the first token of a
declaration when followed by `type`. Inside a storage body, `at` is
recognized only after a type expression. `overlay at N:` opens an
indented block; projections inside default to offset `N` and may add
`at K` for `N + K`. Record for each projection: byte offset, overlay
group id (0 = none), source span. Do not compute size yet.

**Declaration (SemaDecl).** v1 declarations are concrete: `N` is an
integer literal and projection types are concrete (generic storage is
deferred; see spec A.8). After the projection types resolve:
1. Verify `N > 0`. Verify `align(A)` if present: `A` power of two,
   `N % A == 0`.
2. For each projection: resolve the type, require `is_bitwise_copyable
   and is_any_bit_pattern` (S1), compute `size = sizeof(type)`, range
   `[offset, offset + size)`, require range within `[0, N)`.
3. Overlap check. Adjacent-pair comparison after sorting is *not*
   sufficient (`A=[0,100)`, `B=[10,20)`, `C=[30,40)`: A–B and A–C
   intersect but B–C do not, so an adjacent walk misses A–C). Use an
   active-interval sweep:

   ```
   sort projections by start
   for each P:
       retire active projections whose end <= P.start
       for each still-active Q: if Q.group != P.group or P.group == 0:
           error(overlap, P, Q, intersection)
       add P to active
   ```

   With copybook-scale counts, plain O(n²) pairwise comparison is also
   acceptable and easier to audit; either is fine, adjacent-pair is not.
4. Reject `impl Drop for` the storage type at the impl site
   (`SemaDecl.w` impl handling), reject ephemeral flag on the decl.
4a. Recursive views: add storage types to the declaration-cycle audit,
   but with their own rule. A projection whose type is (or transitively
   projects) the enclosing storage type is rejected with
   `err_storage_recursive_view` — *not* by the existing infinite-size
   aggregate cycle checker, which would either mis-diagnose it as
   infinitely sized or, worse, accept it because projections add no
   size. Mutual reference between two storage types is rejected the same
   way. Fixture: `err_storage_recursive_view.w`, `err_storage_mutual_view.w`.
5. Record the storage type's layout as `(N, align, projections)` in the
   type table. Layout is *declared*; the existing struct-layout
   computation in `Codegen.w` (`wl_struct_set_body` path) must not run
   for `Storage`.

**Fieldwise initializer.** In `SemaCheck.w`'s struct-literal path, a
literal whose type is `Storage` is an error with the `zeroed()` /
`from_bytes()` suggestion. Add `zeroed` and `from_bytes` as compiler
intrinsics on storage types (or as generated methods; intrinsic is
simpler for v1 since they are a `memset` and a `memcpy`). There is no
literal construction form in v1; `from_bytes` already covers it.

**Tests.** `test/compile_errors/err_storage_*.w` for every S2
diagnostic. `test/behavior/behav_storage_decl_sizes.w` asserting
`sizeof` and array stride via existing size-probe helpers.

**Done when.** A storage type declares, all layout diagnostics fire, and
`sizeof(T) == N` for an array element.

### S3. Projections as places; origin facts

**Where.** `SemaCheck.w` (place classification, view-origin machinery
around `compute_expr_view_origin_mask` and `set_sig_param_view_origin`),
`BorrowCfg.w` if the CFG walk needs a new place kind, `Mir.w`/`MirCore.w`
(a place projection variant).

**Place kind.** Add a place projection `StorageField(base_place, offset,
size, overlay_group)`. *Every* subprojection below a storage root
refines the flattened `(root_place, [lo, hi))`, not only nested
`storage` fields: ordinary field access on an admissible physical type
(`r.header.code`, `r.balance.raw[2]`), and array indexing (`r.items[0]`).
A constant index narrows to the exact element range; a runtime index
keeps the enclosing array's range (a later pass may use index facts to
narrow `i != j`). The borrow checker never sees a chain, only the
flattened range on the root. This is rule A.5.4 and it is what makes
the overlap query cheap; it is also what makes `inout r.items[0], inout
r.items[1]` provably disjoint, which the `OCCURS` modernization path
depends on. Fixtures: `behav_storage_index_disjoint_inout_ok.w`,
`err_storage_runtime_index_inout_overlap.w`.

**Overlap query.** Two storage places on the same root overlap iff their
ranges intersect. Two storage places on different *owned* roots never
overlap. Two places whose roots are `byref` parameters in a common
may-alias class (P6) are *potentially overlapping* regardless of
syntactic root; the query must consult the class, and this is the same
query used by every overlap check (call arguments, guards, mutating
receivers, nested calls), not only view invalidation. A storage place
and a whole-value access of its root overlap. Until P6 lands, the query
treats every pair of `byref`-rooted places as potentially overlapping
(maximally conservative), which is one more reason the feature stays
gated. This query is used by:
- existing `mut self` argument conflict checks (a projection of the
  receiver's root passed as an argument), and
- P3's `inout`/`byref` checks.

**Reads and writes.** A projection *write* stores a value
(`store_bytes(place, temp, size)`). A projection *read* in an owned
context (`let x = r.f`, owned argument, return) is permitted only when
the projection type is `Copy`; it then materializes as a byte copy into
a temporary (MIR: `load_bytes(place, size)` → temp). For a non-`Copy`
projection type, the owned demand is rejected with a diagnostic pointing
at the type and suggesting a borrow, `inout`/`byref`, or an explicit
snapshot. This is the `BitwiseCopyable` vs. `Copy` split enforced at the
read: the former lets *codegen* move bytes (whole-value `=`, `byref`
marshalling, `memcpy` lowering), the latter lets *source* duplicate a
value. Wire this through the same owned-demand resolution used by D22
(`resolve_contextual_join` and the owned-anchor path), not as a separate
check, so it behaves identically to any other non-`Copy` place. Neither touches the
union last-written tracking (`Sema.w`'s `union_last_written`); storage
overlays are a different kind and that map must not be consulted for
them. Add an assertion in `SemaCheck.w` that a `Storage` place never
reaches the union tracking path.

**Views.** `&record.field` is permitted when the alignment proof (rule
A.5.6) passes. Implement the proof as: `guaranteed_align(root_place)`
(1 for a storage local unless `align(A)` was declared, or the target's
guarantee if the root is a known-aligned allocation) combined with the
offset via `gcd(align, offset)` for offset ≠ 0, then compared against
`alignof(T)`. Emit the under-aligned diagnostic otherwise. Views derived
from a projection carry the root as their view origin using the existing
origin mask machinery, so §21's rules apply unchanged.

**`prefix(n)`.** Implement as a compiler-recognized method on `[P; K]`
projections returning a read slice view over `[0, n*sizeof(P))` of the
projection's range; bounds-check `n <= K` at runtime. Origin: the root.
It is a typed view, so it is subject to the same alignment proof as
`&P`; on an under-aligned `[u32; 4] at 1` it is rejected. The same
applies to `with r.field as mut b:` place aliases. Add fixtures
`err_storage_prefix_unaligned.w` and `err_storage_with_alias_unaligned.w`
alongside `err_storage_unaligned_ref.w`.

**Tests.** `test/behavior/behav_storage_overlay_read.w` (write via one
overlay member, read via the other, assert bytes);
`err_storage_owned_read_non_copy.w` (`let c = parent.child` for a
non-`Copy` nested storage type); `behav_storage_owned_read_copy_ok.w`
(same shape with `impl Copy for Child`); `behav_storage_non_copy_place_ok.w`
(borrow / `inout` / assign to a non-`Copy` projection all fine); `behav_storage_nested_origin.w`
(mutate `r.address.zip`, confirm a live `&r.address` view is rejected —
a `compile_errors` fixture); `err_storage_unaligned_ref.w`.

**Done when.** Overlapping projections are readable and writable in safe
code; the borrow checker rejects a live view across an overlapping write;
the alignment proof fires correctly for `at 4` in an align-1 type.

### S4. Codegen

**Where.** `Codegen.w` (type lowering; `declare_function` is untouched),
`CodegenDispatch.w` (MIR op lowering).

**Note on `bytes[N]`.** Wherever the spec says `bytes[N]` it means
`[u8; N]`. No new type is introduced by this campaign; if a prelude alias
is wanted, it is a one-line std change.

**Type lowering.** A storage type lowers to `[N x i8]`. Never to an LLVM
struct with typed fields. `align(A)` is recorded in the central
type-layout record (`SemaTypes.w`, wherever `alignof` is answered), not
inferred from the LLVM byte-array type: every site that asks `alignof`,
lays a storage value inside another aggregate, allocates one, or
classifies its ABI (`fn_abi_platform_aggregate_indirect`) reads that
record. The LLVM `alloca`/global gets the matching `align` attribute
from the same source. This means the
existing `wl_struct_set_body` path is bypassed for `Storage`.

**Projection access.** `load_bytes(place, size)`: GEP `i8` to
`root + offset`, then load the projection's *actual* codegen value type
with `align 1`, or `memcpy` into a correctly aligned alloca of that type
and load it. Do **not** reconstruct aggregates, `[u8; K]`, storage
values, or `@[physical]` wrappers from an `i<size*8>` integer; that is
both a representation mismatch and an endianness trap for a future
big-endian target. The `iN` shortcut is permitted only when the
projection type's codegen representation *is* that integer (`u32`,
`i64`, ...). Projection access performs **no conversion**; an
explicit-endian type such as `be_i32` is an alignment-1 `[u8; 4]`
physical type whose `.value()`/`.store()` perform the interpretation,
exactly like `packed_dec`. Do not hide a byte swap in projection
loading. Fixed-size `memcpy` optimizes away
readily; do not micro-optimize here. Store is symmetric. Never emit a
typed load at the projection type with its natural alignment; that is
exactly the UB the spec rules out.

**Whole-value assignment.** `=` between storage values (including
storage-typed *projections*) lowers by overlap class, using S3's range
query on the two places:

```
known disjoint (or distinct owned roots)  → memcpy(N)
identical place                           → no-op permitted
possible overlap                          → memmove(N), or RHS into a
                                            temporary then memcpy
```

`r.a = r.b` with `a` and `b` overlapping projections must leave `r.a`
holding the pre-assignment bytes of `r.b`; an unconditional `memcpy` on
overlapping ranges is UB and will produce garbage under LLVM. Fixture:
`behav_storage_assign_partial_overlay.w` (12-byte record, two 8-byte
`Copy` blocks at 0 and 4, assign, assert bytes). Because storage types
have no `Drop`, the existing drop-state machinery (see the
`*-drop-state-debug.md` docs) has nothing to do; add a `debug_assert`
in the drop lowering that a `Storage` value never reaches it.

**`zeroed` / `from_bytes`.** `memset` / `memcpy` into the destination
alloca.

**Optimizer.** `MirOpt.w`: storage loads/stores are ordinary memory ops
on the root's alloca; alias analysis at the MIR level should use the
same range-intersection query as S3 (share the helper). LLVM will see
byte GEPs on an `[N x i8]` and can reason about them precisely on its
own.

**Tests.** `test/codegen/` corpus entries for each lowering shape
(integer-representation projection → typed `align 1` load; aggregate /
`[u8; K]` / `@[physical]` projection → `memcpy` to aligned temporary and
typed load; disjoint whole copy → `memcpy`; overlapping assignment →
`memmove`/temp; `zeroed`). Run under the
debug allocator (`docs/debug-allocator.md`) to confirm no hidden
allocations.

**Done when.** The S3 behavior tests pass through LLVM on all three
supported targets; stage2 self-host is unaffected (storage types are
not used by the compiler itself).

### S5. Reflection and polish

**Where.** `ComptimeEval.w` / `ComptimeValue.w` (`T.fields()`
extension), `Lsp.w` (hover shows offset/range/overlay), `Fmt.w`
(formatting the new decl form), `Analysis.w` (`analysis_collect_types`
reports storage layout for the `with analyze` output).

**Reflection.** `T.fields()` for a storage type returns entries with
`name, type, offset, size, overlay_group`. Add `T.is_storage()`,
`T.storage_size()`. This is the surface `cobol_import` will build on.

**Portable attribute.** Defer the spelling to the syntax ruling, but
reserve the check: if the attribute is present, reject native multi-byte
integers (`i16`..`u128`, `usize`, `isize`, floats) *anywhere* in a
projection type, recursively through arrays, `@[physical]` wrappers, and
nested storage types (a nested storage type qualifies iff it is itself
portable). Implement as a memoized per-type predicate
`contains_native_endian(ty)` alongside the S1 capability predicates,
consulted in S2's projection validation when the attribute is present.

**Done when.** `cobol_import`'s author can enumerate a storage layout at
comptime without further compiler changes.

---

## Part B — Caller-place parameters

### P1. Parameter mode in signatures; call-site spelling

**Where.** `Ast.w` (param node gets a mode field; arg node gets a mode
prefix), `Parser.w` (accept `inout`/`byref` in both positions), `Sema.w`
(a `ParamMode: i32` enum `Value=0, Inout=1, Byref=2` beside
`ReceiverMode`; do not extend `ReceiverMode`), `SemaTypes.w` (signature
identity includes per-param mode), `Codegen.w` (monomorphization cache
key includes mode — the `llvm_type_mangle` / mono-cache path). Precisely:
every signature, type, and monomorphization identity that distinguishes
parameter *types* must also distinguish parameter *mode* (overload
resolution, mono cache, bundle interface signature). Link-symbol naming
policy in `docs/with-abi.md` (semantic symbol names, types carried by the
source interface) is preserved; do not add mode to external link names
unless overload implementation already requires type-distinguished link
names.

**Checks (SemaCheck).** At every call: for each parameter, the argument's
mode marker must equal the parameter's declared mode; mismatch is an
error naming the declared mode. The argument expression must be a
*caller-owned place*: reuse the predicate that already validates
`mut self` receivers, unchanged. That predicate accepts `let` bindings
(mutation through an explicitly marked operation is not rebinding), and
rejects temporaries, rvalues, `&T`/slice views, and `const` items. Do
not add an "immutable binding" rejection; it would break
`mut self ≡ inout`. Named arguments carry the mode with the
expression (`f(target: inout x)`); caller-place parameters may not have
defaults and may not be omitted, and `implicit` combined with `inout` or
`byref` is a direct declaration-site error (fixture
`err_inout_implicit_param.w`), not something left to fail at the
omission rule. **Evaluation order:** With's
named-argument sema normalizes the argument list into parameter order.
That normalization must not reorder side effects or reservation timing.
Keep a source ordinal on each argument; evaluate (and, for caller
places, reserve) in source order into temporaries/addresses, then
marshal in parameter order. Fixture: `f(other: mutate_index(), target:
inout xs[i])` vs. the reversed source order must select different
elements. Overload resolution treats mode as part
of the candidate signature and never coerces a bare expression into a
place argument. A `byref` parameter's type must satisfy
`is_bitwise_copyable` (rule B.4.11).

**Declaration contexts (enumerate; do not let parser reuse decide).**
Accept `inout`/`byref` on free-function and inherent-method non-receiver
parameters only. Reject with a specific diagnostic on: `extern fn` and
anything reaching the C ABI surface (`c_import` bindings, `@[export]`
if it exists), closure parameters, explicit `fn(...)` type syntax, and
trait method parameters (v1). The trait rejection keeps `ParamMode` out
of trait metadata, vtable function types, indirect-call lowering, and
interface matching for this campaign; lifting it is a self-contained
later stage. Fixtures: `err_inout_extern_fn.w`, `err_inout_c_import.w`,
`err_inout_closure_param.w`, `err_inout_fn_type.w`,
`err_inout_trait_method.w`.

**No new overloading.** Mode is in signature identity, but two same-name
declarations differing only in `T` vs `inout T` must be rejected exactly
where `T` vs `U` would be. Verify against the current free-function and
method declaration rules before P1 lands: if With turns out to permit
signature-only overloading somewhere, the preserved link-name policy is
insufficient there and needs a separate decision. Fixture:
`err_inout_mode_only_overload.w`.

**Receiver alignment.** Document in code that `ReceiverMode.Mut` is the
receiver form of `ParamMode.Inout`; the two share the checking helpers
introduced in P3.

**Tests.** `err_inout_missing_callsite.w`, `err_inout_spurious_callsite.w`,
`err_byref_non_bitwise.w`, `err_inout_rvalue_arg.w` (`f(inout make_value())`),
`err_byref_read_view_arg.w`, `err_byref_const_item.w`,
`behav_inout_let_binding_ok.w`, `err_inout_param_default.w`,
`behav_inout_named_arg.w`,
`behav_inout_basic.w` (mutation visible to caller),
`behav_byref_same_arg_twice.w`.

**Done when.** Signatures with modes parse, resolve, mangle distinctly,
and reject mis-spelled call sites. No ABI change yet: temporarily lower
`inout` and `byref` both as today's `PM_INDIRECT_PLACE` so P1 can land
green before P2.

### P2. FnAbi alias contract; codegen attributes

**Where.** `FnAbi.w`, `Codegen.w` (`declare_function_from_sig`,
`apply_noalias_param_attrs_with_offset`), `CodegenDispatch.w`
(`mir_ref_arg_ptr` and the `push_call_arg` arm for indirect place),
`docs/with-abi.md`, `WITH_ABI_VERSION`.

**Descriptor.** Add an aliasing field to the per-arg ABI record:
`PA_EXCLUSIVE = 0, PA_MAY_ALIAS = 1`. `fn_abi_pass_mode` keeps returning
`PM_INDIRECT_PLACE` wherever it does today. The sibling classifier takes
the **access contract**, not just `ParamMode`:

```
fn_abi_alias_contract(receiver_mode, param_mode):
    ReceiverMode.Mut  or ParamMode.Inout  → PA_EXCLUSIVE
    ParamMode.Byref                        → PA_MAY_ALIAS
    ReceiverMode.Read passed by place      → PA_MAY_ALIAS   // NOT Exclusive
    anything else that is IndirectPlace    → PA_MAY_ALIAS   // default-safe
```

The default is `MayAlias`. Today's compiler uses `PM_INDIRECT_PLACE` for
non-`move` read receivers too (`SemaDecl.w`: non-`move` `self` remains
share-place), and `IndirectPlace` by itself only means "pointer to the
caller's place." A classifier of "not `byref` → `Exclusive`" would
retroactively promote every read receiver to `noalias`. Pin with an
IR-grep that a read-`self` method receives no `noalias` on `self`.
Keeping pass mode and alias contract as two fields matches the spec's
"transport vs. guarantee" separation and keeps the ABI diff small.

**Attrs.** `apply_noalias_param_attrs_with_offset` currently applies
`noalias` to indirect-place params. Two changes:

1. Consult the alias contract and *never* emit `noalias` for
   `PA_MAY_ALIAS`. This is the single most important line in Part B: if
   it is missed, LLVM will legally miscompile `legacy(byref r, byref r)`.
2. **Audit the `Exclusive` case rather than assuming it.** LLVM
   parameter `noalias` is stronger than With's exclusivity: it promises
   no access to the pointee during the call through *any* other
   provenance, including a global the callee names directly. With's
   rule only excludes other *arguments and live accesses at the call
   site*. So `fn f(a: inout Account): global_account.x = 1` called as
   `f(inout global_account)` violates LLVM `noalias` while satisfying
   the spec. Options: (a) extend the exclusivity check to reject a
   caller-place argument whose root is a `global var` that the callee
   (transitively) accesses, using the effect summaries; or (b) emit
   `noalias` only when the callee's effect summary shows no global-var
   access, no calls into unknown code, **no raw-pointer parameters or
   raw-pointer dereferences (including inside `unsafe` blocks), and no
   other provenance the analysis cannot exclude**. The raw-pointer case
   is a distinct path: `fn f(a: inout i32, p: *mut i32)` called as
   `f(inout x, &raw mut x)` writes the pointee through `p` during the
   call, which the caller-place checker cannot see. `noalias` is an
   optimization, so a false negative costs nothing and a single false
   positive is a miscompile; err on omission. (b) is the conservative
   backend-only fix and is what v1 should do; (a) is a later
   language-level tightening if the optimization matters. This audit
   applies to today's `mut self` `noalias` emission as well; it may be a
   pre-existing latent bug. Check before P2 lands.

The IR gate is therefore: **`byref` never gets `noalias`; `inout` /
`mut self` get it only when the LLVM contract is established** by (b).
Pin both halves with codegen corpus greps.

**Bundle-consumed declarations.** The proof in (b) requires the callee's
effect summary, which needs its body. A declaration consumed from a
bundle interface (body unavailable) gets **no `noalias` by default**.
The semantic alias contract (`Exclusive | MayAlias`) round-trips from
the signature via `ParamMode` and is a language fact; backend
optimization eligibility is a *separate* fact and must not be
regenerated from `ParamMode.Inout` alone. If it ever matters, the
interface can carry a dedicated, fingerprinted backend-proof row
(`BundleInterfaceEmit.w`), populated only by the producing compiler
after running (b). Fixture: a `.wo` consumer calling an imported `inout`
function; IR-grep that the call site and the imported declaration carry
no `noalias`.

**ABI doc.** Bump `WITH_ABI_VERSION`, add the alias field to the
descriptor table in `docs/with-abi.md`, regenerate `with-abi.sha256`.

**Tests.** IR-grep corpus tests for both contracts (`byref` absent;
`inout` present for a pure callee, absent for a callee touching a
global); behavior test where a `byref` callee writes through one alias
and reads through the other, compiled at `-O2`, asserting the read sees
the write; behavior tests for the `global_account` case and the
`f(inout x, &raw mut x)` raw-pointer case at `-O2`.

**Done when.** `byref` aliasing survives optimization; `inout` and
`mut self` receive `noalias` exactly when the LLVM contract is
established.

### P3. Borrow checker: exclusivity, byref class, no-move-out

**Where.** `SemaCheck.w` (the argument-conflict check that today rejects
arguments retaining access to a `mut self` receiver — generalize it),
`BorrowCfg.w` if liveness needs a new edge kind.

**Exclusivity (rule B.4.4/5).** At a call, collect the set of places
each argument designates or retains: `inout` → its place; `byref` → its
place; `&T` / slice / view args → their origin; `mut self` receiver →
its place; guards in scope → their places. For each `inout` place,
require no other collected place overlaps it (S3's query). For each
`byref` place, require that every overlapping collected place is also
`byref`. Heterogeneous `byref` overlap (rule B.4.6): if two overlapping
`byref` places have different static types, require both to be storage
projections of one root and both `AnyBitPattern`; otherwise error.

**No-move-out (rule B.4.3).** In the callee, an `inout`/`byref`
parameter's place is marked `NO_CONSUME`. Extend the owned-demand
resolution (the D22 machinery: `resolve_contextual_join`, owned-anchor
detection) so a `NO_CONSUME` place can satisfy an owned demand only via
the `Copy` materialization path. Any consuming use of a non-`Copy`
value at a `NO_CONSUME` place (passing to an owned param, `return`,
`let` without copy, `move`) is an error with the clone/assignment
suggestion. Assignment *to* the place is permitted and runs the old
value's drop — which for `inout` of a `Drop` type means the callee drops
the caller's old value in place; that is the intended semantics and
matches `mut self` field assignment today.

**Tests.** `err_inout_overlap_inout.w`, `err_inout_overlap_ref.w`,
`err_byref_overlap_inout.w`, `err_byref_hetero_outside_storage.w`,
`behav_byref_hetero_storage_ok.w`, `err_inout_move_out.w`,
`err_inout_return_owned.w`, `behav_inout_assign_replace.w`.

**Done when.** Every conflict shape in the spec's rule table has a
fixture and the receiver conflict check is a special case of the new
generalized check (no duplicated logic).

### P4. Reservation

**Where.** `SemaCheck.w` argument evaluation; `MirLower.w` argument
ordering.

**Model.** Introduce a liveness state `RESERVED(place)` created when a
caller-place argument's designator finishes evaluating and released at
invocation. While a place is reserved, later argument expressions are
checked against it with a *weaker* predicate than exclusivity: they may
read it and may perform completed mutations through it, but may not
(a) consume the root or any enclosing place, (b) drop or destroy it,
(c) rebind the root, or (d) invoke an operation classified as
*relocating* on any enclosing container.

**Invalidation classification.** This is the one new analysis fact,
and it is *relative to the reserved place*. It is a per-parameter
effect, `EFF_INVALIDATE_DESCENDANTS`, carried on a receiver or
caller-place parameter: passing a container through that parameter may
move, destroy, or shrink storage that lives *inside* the container
(`Vec.push`, `Vec.insert`, `Vec.remove`, `Vec.pop`, `HashMap.insert`,
... all set it on `self`). It applies only when the reserved place is a
descendant of the argument bound to that parameter:

```
f(inout xs, xs.push(v))       // root xs survives → admissible
f(inout xs[0], xs.push(v))    // xs[0] is inside xs → reject
f(inout r.a, r.b.clear())     // r.b is a sibling projection, not an
                              // enclosing container → admissible
```

An unconditional "relocates" bit would reject the first case and make
the implementation stricter than the spec.

The bit is a **per-parameter effect**, `EFF_INVALIDATE_DESCENDANTS`, on
the existing per-parameter effect summary (the P0 fixpoint / `escape_*`
/ `write` summaries referenced in `share_place_minimal_design.md`), not
a method-level property. A `mut self` receiver is one carrier; an
`inout` parameter is another:

```
fn grow(v: inout Vec[i32]): v.push(1)
f(inout xs[0], grow(inout xs))     // reject: grow's param carries the effect
```

Seed from std annotations on container mutators, propagate through the
call-graph fixpoint like the other effect bits (an `inout` param that is
passed on to a parameter carrying the effect acquires it). v1 seeds
conservatively: any `mut self` method on a growable container sets it
unless annotated otherwise. The reserved-place check consults the bit on
the parameter (or receiver) the enclosing container is passed to, and
only when the reserved place is a descendant of that argument. Fixture:
`err_inout_reservation_via_inout_callee.w` for the `grow` case.

**Single evaluation — the invariant.**

> A caller-place designator is evaluated exactly once. Reservation
> preserves the identity selected by that evaluation.

The designator (including any index expressions, e.g. `xs[i]`) is
evaluated in argument order and its physical address is materialized
*at that point*. Reservation then proves the address cannot become
stale before invocation. The compiler must never re-evaluate the
designator later; in `f(inout xs[i], change_i())`, where `change_i`
mutates `i` without relocating `xs`, the callee receives the element
selected by the *original* `i`. (The alternative, holding a symbolic
`ReservedPlace{root, evaluated index path, origin}` and resolving it to
an address at `push_call_arg`, is also correct provided the index values
are the ones captured at designator time; it is more machinery for no
semantic gain, so v1 materializes immediately.)

**MIR.** `mir_ref_arg_ptr` (the `IndirectPlace` marshal) takes the
address when the argument is lowered in sequence; confirm it does not
re-lower the designator at the call. The reservation check runs in Sema
between designator evaluation and invocation; MIR carries no reserved
state.

**Tests.** `behav_inout_reservation_len_ok.w`, `behav_inout_reservation_update_ok.w`,
`behav_inout_reservation_index_evaluated_once.w` (the `xs[i]` /
`change_i()` case: assert the callee saw the original element),
`err_inout_reservation_pop.w`, `err_inout_reservation_push.w`,
`err_inout_reservation_move.w`.

**Done when.** The five spec examples in rule B.4.7 behave as listed.

### P4b. Returned-view provenance across calls

**Where.** `SemaCheck.w` (`set_sig_param_view_origin`,
`check_returned_view_origins`, the call-site origin substitution that
already maps a returned view's declared parameter origin onto the actual
argument's origin).

**What.** A view returned from an `inout`/`byref` parameter is declared,
in the signature's view-origin summary, as originating from that
parameter. At the call site the existing substitution maps it onto the
*actual argument's* origin, so:

```
fn balance(r: inout Rec) -> &i32: &r.balance
let p = balance(inout rec)
rec.balance = 1        // ERROR while p is live
```

Verify the substitution handles caller-place arguments (it was written
for `&T` parameters and `self`); the argument is a place, and its origin
is the place's root plus (for storage projections) range. For `byref`,
keep escape provenance parameter-specific: `return &a` is summarized as
originating from `a` only, not from the whole may-alias class. The class
is consulted for intra-callee conflicts (P6); provenance is not widened
by it.

**Tests.** `err_inout_returned_view_conflict.w` (the example above),
`behav_inout_returned_view_ok.w` (view dropped before mutation),
`behav_byref_returned_view_specific.w` (a view returned from `a` does not
block mutation through an unrelated caller place that was passed as
`b`).

### P5. Restrictions: suspend, first-class, closures

**Where.** `MirSuspendCheck.w` (`suspend_body_calls_may_suspend` and the
per-body `may_suspend` bits), `SemaCheck.w` (function-value formation,
closure capture analysis).

- After `may_suspend` is computed, any body with a caller-place
  parameter and a set `may_suspend` bit is an error at the parameter.
  `async fn` / `gen fn` are rejected at declaration without waiting for
  the analysis.
- Taking a function with any caller-place parameter as a value: error at
  the use site, with the same wording as the existing mutating-method
  restriction; share the diagnostic.
- Closure capture of an `inout`/`byref` parameter: error, marked in the
  message as a v1 restriction.

**Tests.** `err_inout_async_fn.w`, `err_inout_may_suspend_transitive.w`,
`err_inout_fn_value.w`, `err_inout_closure_capture.w`.

### P6. Intra-callee byref may-alias

**Where.** `SemaCheck.w` view-origin tracking inside a function body.

**Model.** The callee cannot see argument provenance, so grouping is
by *type*, not by whether the parameter "is a storage projection": at
function entry, two `byref` parameters may alias iff they have the same
static type, or both types are admissible `AnyBitPattern` physical types
(some legal caller could pass overlapping storage projections of those
types, per spec rule B.4.6). `fn f(a: byref i32, b: byref u32)` groups
`a` and `b`. Assign each compatible group one *may-alias origin class*. When a view is derived from a `byref` parameter, its
origin is the class, not the individual parameter. A write through any
parameter in the class invalidates live views whose origin is the class.
This reuses the existing origin-mask invalidation; the only new piece is
that several parameters share a mask bit.

**Feeding the overlap query.** The may-alias class is not only a
view-origin fact. It must be consulted by S3's general overlap query so
that every derived-place check (nested call arguments, guards, mutating
receivers) sees `byref`-rooted places in one class as potentially
overlapping. The headline fixture:

```
fn inner(x: inout i32, y: inout i32): ...
fn outer(a: byref Rec, b: byref Rec):
    inner(inout a.x, inout b.x)     // ERROR: a and b may alias
fn owned(a: Rec, b: Rec):
    inner(inout a.x, inout b.x)     // OK: distinct owned roots
```

This exercises caller aliasing → `byref` → callee may-alias facts →
storage projection → attempted `inout` refinement across all three
layers at once.

**Tests.** `err_byref_intra_callee_view_conflict.w` (the spec's
`let r = &a; b = 42; r` example), `behav_byref_intra_callee_no_view_ok.w`
(write through `b` with no live view from `a` is fine),
`err_byref_nested_inout_refinement.w` and
`behav_owned_nested_inout_ok.w` (the pair above).

**Done when.** The checker never assumes disjointness for a pair of
places that the source semantics allow to alias, and the backend never
attaches an exclusivity promise to a `byref` parameter. (Two `MayAlias`
parameters need not be pairwise compatible; the invariant is one-
directional in each layer, not an equivalence.)

---

## Cross-cutting

### Self-host

Neither feature is used by the compiler's own source in this campaign, so
the seed → stage1 → stage2 chain is unaffected until std adopts them.
Do not use storage types inside `src/` before the fixpoint check is
green for two consecutive releases with the feature present.

### Bundle interfaces

`src/compiler/BundleInterfaceEmit.w` currently has struct/union-specific
emission (`kind_row = "union" | "struct"`) and no storage case. Public
storage types must round-trip through the bundle interface, so:

- **Emit:** a `storage` row carrying `N`, `align`, and every projection
  as `(name, type, offset, overlay_group)`. Overlay groups must be
  preserved, not just offsets, or a consumer re-checking S2's overlap
  rule would reject a legitimately overlaid layout.
- **Reconstruct:** `BundleInterfaces.w` rebuilds the `TypeDeclKind.Storage`
  decl from the row and re-runs S2's validation as a consistency check
  (declared layout is the contract; recomputation must agree).
- **Signatures:** parameter mode is already in interface signature
  identity (P1); the alias contract follows from it and needs no
  separate row.
- **Fingerprint:** `BundleFingerprint.w` must include the storage row so
  a layout change invalidates dependents.

Fixture: an end-to-end `.wo` test where module A exports a storage type
with an overlay plus one `inout` and one `byref` function, and module B
consumes all three; assert `sizeof`, an overlay read, and a caller-
visible mutation across the module boundary.

### `with migrate`

The C migrator (`CiMigrate.w`, `Migrate.w`) should *not* start emitting
storage types for C unions in this campaign; that is a separate
decision. Add a `// storage-type candidate` marker in emitted code where
a C union or explicitly-laid-out struct is encountered, so the census
tool can count them.

### Documentation

- Spec: new chapter after §4 for Part A; §9.1 gains parameter modes;
  §21 gains the exclusivity principle, reservation, and byref class;
  §16.4 gains one sentence pointing storage overlays elsewhere.
- `docs/with-abi.md`: alias contract field.
- `docs/with-idiomatic-guide.md`: when to use `inout` vs. returning a
  value; when `byref` is appropriate (almost never in new code; it
  records unproven aliasing).
- `docs/COBOL-migrate.md`: update the mapping table (`REDEFINES` →
  storage overlay, not anonymous union; `PIC X(n)` → `text[N, Enc]`, not
  `FixedString`; `CALL BY REFERENCE` → `byref`, refined to `inout`).

### Acceptance

- Every rule in the spec has at least one `compile_errors` or `behavior`
  fixture, listed in `test/coverage_manifest.txt` under a new
  `storage-and-places` section.
- `test/d_acceptance/` gains an end-to-end program: a storage record with
  overlays, passed `byref` to one function and `inout` to another,
  compiled at `-O2`, output compared to a golden file.
- The IR-grep tests for `noalias` presence/absence are red-build gates.

### Estimated shape

S1–S2 and P1 are mostly mechanical and can be parallelized. S3 and P3–P4
are the real work: they extend the borrow checker with range-overlap
places, a reserved-place state, and a shared may-alias class. P2 is
small but is the one change whose omission is a silent miscompile;
review it separately from everything else.
