# Goose implementation study: ideas for With

Research proposal, 2026-10-08. Primary evidence: the implementation in
`.reference/goose`, at commit `35368105e3d50341b79a4cb873cc0261e82dfa42`.
This is a reference study and proposed sequencing, not a language ruling.

## Decision addendum: With's current questions

The survey below is reference material. This brief starts from active With decisions; its recommendations take precedence over the survey's earlier priority ranking. D111 and “item 3” refer to Eric's rulings/questions supplied in this discussion; no local D111 entry was found. Mechanism claims below come from source inspection; the later benchmark port adds explicitly recorded execution evidence.

**D111 — strings as values: keep the ruling.** Goose's [`ImplicitCopy` / `ImplicitCopyError`](../../.reference/goose/src/typecheck_exprs.h) reject a non-fixed lvalue or reference at an owned destination, directing the caller to `copy(x)` or a reference. Own-local returns are exempt; fixed values and varint scalar reads are exempt. This exposes the size-dependent copy rather than hiding it. With's shared immutable string buffer removes that reason for call-site ceremony: duplicating a string value can retain the buffer in O(1), while preserving independent value semantics. Goose is the relevant counterexample, not supporting precedent. **Action:** retain D111; verify independent values, lifetime after either value is released, and absence of an O(n) byte copy on value duplication. Refcount traffic and overflow remain implementation obligations.

**Item 3 — should value-typed map lookup read out a value? Goose supports the direction, but does not settle the API.** [`CheckValue`](../../.reference/goose/src/typecheck_exprs.h) without an expected type calls `DecayRef` unless inference is preserving a non-fixed reference; `IsNonFixedRef` tests the pointee's size class. [`dictionary.get`](../../.reference/goose/stdlib/dictionary.goose) returns a nullable reference. Thus its inferred fixed-size read can become the pointee value without changing the lookup signature. This is working code for transparent readout, but fixed size is not With's “value with no identity” criterion. **Action:** use this in the item-3 brief to separate two choices: the declared `get` result and materialization at its use. It strengthens the case for value readout; it does not justify conditional `get` signatures or silently overriding [D22](../meetings/d22-Eric-Ruling.md), which preserves inferred references today. Eric must rule the exact boundary, including generic forwarding and Option elimination.

**Length width — add bounded fixed `i64` as the third option.** [`BCE::LENMAX`](../../.reference/goose/src/bce.h) grants `0 <= len <= 2^48`; [`runtime.h`](../../.reference/goose/src/runtime/runtime.h) rejects a stack reservation above that ceiling, and generated headers use signed lengths. This combines stable width with a non-negative length invariant; it is not a new integer type and does not refine every ordinary `i64`. **Action:** compare `isize`, unrestricted `i64`, and target-bounded non-negative `i64` lengths. Prefer the third if With enforces the invariant at every producer: it preserves signed difference arithmetic while making conversion to target `size_t` value-preserving. The 48-bit ceiling alone is insufficient for 32-bit `size_t`; constrained targets need a tighter bound. Check FFI conversions and derived byte counts, not just element counts.

**vx — processor identity alone is an incomplete reuse argument.** [`FnSpec::narrowedenv` / `envreads`](../../.reference/goose/src/ast.h) and [`EnvIs` / `EnvUnchanged`](../../.reference/goose/src/typecheck_calls.h) make outer-variable assignment, provenance, contents, and narrowing state part of specialization reuse eligibility. The reuse loop rejects changed environments. **Action:** qualify [vx's `(fn, processor)` key](vx.md): retain existing generic/type inputs and either key checked bodies on relevant captured facts, or check a context-independent body and discharge explicit obligations at each call. A processor selects lowering; it does not freeze captured placement or view state. Test the same helper on the same processor before and after a captured value changes space or origin. Do not reuse an earlier acceptance proof merely because its processor matches.

**Crux — use images for transfer, not primarily persistence.** [`VerifyFn` / `EmitVerifyLink`](../../.reference/goose/src/codegen_types.h) validate internal offsets; [`EmitFromBytes`](../../.reference/goose/src/codegen_builtins.h) materializes a verified copy. Relocation preserves internal links without host-pointer fixups. **Action:** pilot an immutable tokenizer table or structured KV-cache metadata image through [vx's consuming transfer](vx.md) for [Crux](../demo_plans/ml/crux/crux-design.md): validate once, transfer the contiguous payload to HBM, and access it relative to the destination base. Keep tensor storage/layout separate; ordinary flat KV tensors need no graph verifier. Device-compatible alignment, offset width, accessors, completion, and ownership are additional work. Acceptance: one payload copy per direct hop, identical host/device lookup, no host addresses, and no view published before transfer completes.

**Cheapest tooling adoption — `--roundtrip`.** [`CheckRoundtrip`](../../.reference/goose/src/main.cpp) reparses the dumped source, dumps again, compares exactly, and reports the first differing line. **Action:** add the equivalent invariant to With's canonical source printer and parser corpus; begin with existing printable forms. This tests printer/parser stability, not semantic equivalence. It needs no ownership or new-language ruling.

## Findings and evidence standard

The most useful thing to borrow from Goose is its treatment of storage as something the compiler can reason about explicitly: where construction happens, which operations preserve addresses, what a reference may point into, and which mutations invalidate a proof. Those mechanisms can improve With without adopting Goose's restrictions on independently owned dynamic values or its lack of destructors.

This study is based primarily on reading function bodies, branches, data structures, and emitted-code templates. Tests are supporting evidence of intended coverage; their existence is not a claim that they passed in this session. Neither Goose nor a modified With compiler was built or benchmarked. Consequently, “implemented” below means a concrete implementation path exists and was inspected, not that its correctness has been established by execution. Documentation was used to locate mechanisms and compare them with With's controlling decisions, not to establish performance or safety claims.

Several qualifications emerge directly from code:

* **Queues allocate.** `gs_qput` allocates a node plus payload with `malloc`, copies the payload, then locks the queue. Goose's ordinary language values use data stacks; that does not make its runtime allocation-free.
* **Destination construction has adaptation costs.** `EmitSlidePrefix` emits `memmove` to remove a length prefix. `EmitFvCall` allocates temporaries when the body's representation differs from its destination. “Built in place” should not be conflated with “no bytes ever move.”
* **Handle generations are finite.** `ui_table_add` computes `gens[i] % 4095 + 1`. `ui_table_find` checks index, occupancy, and generation, but an old handle can match again after sufficiently many reuses of that slot. Generation checking is a mechanism with a wrap policy, not an unconditional identity guarantee.
* **Compact layout is deliberate.** `LayoutFields` sums field sizes without automatic alignment between ordinary fields; explicit padding changes that. Compactness has target and FFI consequences.
* **Some attractive designs have no implementation.** The column-array document explicitly describes an unimplemented proposal. It is excluded from the main recommendations as evidence about what Goose actually does.

Sources: [`gs_qput`](../../.reference/goose/src/runtime/runtime_threads.h), [`EmitSlidePrefix` and `EmitFvCall`](../../.reference/goose/src/codegen_calls.h), [`ui_table_add` / `ui_table_find`](../../.reference/goose/src/ui/ui_core.c), [`LayoutFields`](../../.reference/goose/src/codegen_types.h). The [column-array proposal](../../.reference/goose/docs/design/soa.md) is secondary context only.

## Survey index: reference mechanisms

| Survey rank | Opportunity | Implementation evidence | Possible With action |
|---|---|---|---|
| 1 | Make construction destinations explicit across calls | `Dst`, `EmitPush`, `EmitCallInto`, `EmitFvCall` | Audit and strengthen destination lowering; define guarantees narrowly |
| 1 | Explain and test bounds-check proofs | `BCE::Flow`, `ComputeEffects`, `VerifyAnnotations`, `IndexLoc` | Extend compiler analysis with proof reasons and regression expectations |
| 1 | Keep origin alternatives and storage identity distinct | `RootAlt`, `Roots::Add`, `FitsAt`, `CheckLoopPasses` | Apply to D22/D65 conformance, not a new surface feature |
| 2 | Safe append-only storage with stable element addresses | `EmitPush`, `AllocStk`, `EmitRestores`, `CheckGrowShrink` | Explore a library contract supported by verified effects |
| 2 | Compact, validated, relocatable images | `EmitRelStoreAt`, `VerifyFn`, `EmitVerifyLink`, `EmitFromBytes` | Start with explicit image types and generated validators |
| 3 | Packed streams of variable-size records and variants | `FixedSize`, `EmitVerifyWalk`, construction and size walkers | Explore dedicated packed collections after image validation |

The first three opportunities mostly improve mechanisms With already needs. The remaining ones require individual ownership, safety, representation, or API decisions before implementation. No new syntax in this document is asserted to work in today's compiler.

## 1. Construction destinations should survive abstraction boundaries

### What the implementation does

[`EmitPush`](../../.reference/goose/src/codegen_builtins.h) distinguishes three materially different cases. A fixed element is evaluated with `Snapshot` before claiming its slot, because its initializer may itself append to the receiver. A bytes-class element is constructed at the stack top through `GenConstruct`. An element containing relative references also uses construction at its actual location, since an offset cannot be finalized before that location is known. Limited-capacity arrays use a checked element lvalue instead.

The emitted code preserves that ordering explicitly. For resizable storage it captures the element address, emits construction or a store, then increments the count. This is a more useful model than hoping a later optimizer removes an intermediate object.

[`EmitCallInto`](../../.reference/goose/src/codegen_calls.h) passes destinations for multiple return values. [`EmitFvCall`](../../.reference/goose/src/codegen_calls.h) emits a checked function block directly into its destination when compatible, but switches to a fixed local, resizable temporary, or bytes temporary for adaptation. [`EmitSlidePrefix`](../../.reference/goose/src/codegen_calls.h) exposes one important remaining cost: converting a prefixed array value into an element run slides its bytes.

### Inspiration for With

Make “the destination is known” an explicit lowering fact through aggregate construction, returned aggregates, nested calls, collection insertion, formatting, and consumer blocks. The user should be able to write ordinary value-returning helpers without turning the program into out-parameter plumbing.

This is an audit target first: the source study does not establish how much With already does. Sema must settle meaning, ownership demand, and evaluation order; MIR must represent initialization and failure cleanup; codegen must consume the one `FnAbi` descriptor. A destination optimization must never silently turn a consuming parameter into a borrow or make a second live owner.

**Critical difference:** Goose restores data-stack watermarks. With must drop every successfully initialized non-Copy field exactly once if a later initializer fails. Reserving a collection slot must not publish an incomplete value. Address stability and observable destructor timing also constrain which moves can disappear.

**Acceptance experiment:** one nested record containing strings, a large array, and an observable Drop value, returned through several helpers and inserted into a collection. Check generated IR and allocator evidence for temporary storage and byte movement; execute success and failures at each field boundary. Include an initializer that modifies the same destination collection. A correct fast path must preserve evaluation order and cleanup, not merely reduce allocations.

**Recommendation:** pursue early. Promise specific construction paths only after they are verified. Report representation adaptation separately from ownership moves.

## 2. Bounds-check elimination should be a visible compiler product

### What the implementation does

[`BCE`](../../.reference/goose/src/bce.h) has concrete `Base`, `Fact`, `Term`, and `Flow` structures. A base contains kind, identity, and generation; facts express `l <= r + c`. `AddFactB` retains the stronger duplicate fact and discards an old fact when the 200-fact budget is reached. This makes analysis resources explicit rather than assuming unlimited inference.

`VarBase` and `LenBase` refer to the current generation. The mutation machinery can invalidate current facts while retaining facts about earlier snapshots. `UltOf` distinguishes owned storage, static storage, and opaque provenance; an inexact lifetime bound is not treated as storage identity.

`ComputeEffects` iterates summaries to a fixpoint. Body-less functions conservatively mark reference parameters as potentially affected. `RunAll` computes those effects before analyzing live bodies in caller-first order. This supports preserving a length fact across a call that writes elements but does not resize their storage.

`VerifyAnnotations` checks `bce:elide` and `bce:keep` expectations against per-source-line counts. An annotated line with no recorded checks fails instead of passing vacuously. The driver exposes those counts through `--bce-lines`. [`IndexLoc`](../../.reference/goose/src/codegen_values.h) consumes the `nobc` decision; otherwise it emits `GS_IDX`.

### Inspiration for With

Expose why a check remains: unknown lower bound, possible resize through an alias, arithmetic overflow, unavailable interface effect, or analysis budget. Goose has counts; causal explanations are the With opportunity. User-level code should not need `unsafe` indexing or redundant assertions to obtain a proof the compiler already has.

Use D65's authoritative semantic effects rather than re-deriving call meanings in an optimization pass. Optimization may produce new physical facts after transformation, but must preserve the semantic facts it consumes. Do not import Goose's `LENMAX = 2^48` axiom without a corresponding enforceable With target contract.

**Acceptance experiment:** iterate a slice, index a row-major image, reduce an index with a mask, call a non-resizing helper, and call a resizing helper through an alias. Verify both removed and retained checks. Change a helper's effect and confirm invalidation. Include overflow and path joins. Required checks must still panic, and insufficient proof must preserve the check.

**Recommendation:** prioritize proof reporting and expectation tests alongside optimization. A count is useful evidence of a cost; it is not evidence that eliminating the check was sound.

## 3. Provenance should preserve alternatives, not collapse them into one convenient root

### What the implementation does

[`RootAlt`](../../.reference/goose/src/ast.h) carries a root, an `exact` identity bit, a source container, and read-back qualifiers. `Roots` stores alternatives. `Roots::Add` unions new roots; when two alternatives share a root it weakens exactness with logical AND and drops incompatible source-container information. `Same` compares sets rather than discovery order.

[`FitsAt`](../../.reference/goose/src/typecheck_exprs.h) checks every source alternative against each possible destination. For a value holding references it uses `ContentsOf(v)`, rather than mistaking the aggregate's storage for the pointee's storage. Writability and stores into grow-shrink storage receive separate checks.

[`CheckLoopPasses`](../../.reference/goose/src/typecheck_flow.h) joins the entry state with back-edge state and rechecks until stable. It has an explicit 16-pass failure, not permission to accept an unsettled result. The implementation also distinguishes discovery-only unknown roots from settled facts.

### Inspiration for With

This directly supports [D22](../meetings/d22-Eric-Ruling.md): retain each view's possible origins through wrappers, projections, eliminators, returns, and loops. Keep these questions separate:

1. What owner or scope bounds the reference's lifetime?
2. Which exact storage can it designate?
3. Which operations can invalidate that storage?
4. Has an authorized operation produced an independent owned value?

Equal scope depth does not prove equal storage. A shared bound does not prove two parameters alias, and different parameter spellings do not prove disjointness. An unannotated binding must not copy a Copy pointee merely to simplify provenance.

**Acceptance experiment:** a view selected from two maps, wrapped in Option and a struct, forwarded through a generic helper, rebound in a loop, and used after a candidate owner mutates. Test every origin, an unrelated third owner, and the final-use boundary. Reorder branches and declarations to expose accidental order dependence. The [Goose root-set fixture](../../.reference/goose/test/lifetimes/root_sets.goose) is a useful case generator, not a With oracle: its read-back conservatism and alias model differ.

**Recommendation:** borrow the data-structure discipline and convergence tests. Do not copy Goose's entire checker, its repeated typechecking architecture, or a fixed pass limit as With policy.

## 4. Stable append-only storage is a useful contract; a bump pointer alone is not one

### What the implementation does

`EmitPush` places growth at a data-stack top without reallocating existing elements. [`AllocStk` and `SaveBase`](../../.reference/goose/src/codegen_frames.h) assign storage to the surrounding scope; `EmitRestores` emits reverse-order restoration of saved tops. The runtime reserves address regions through [`VirtualAlloc` / `mmap`](../../.reference/goose/src/runtime/runtime_impl.h), with platform-specific protection and fault handling.

The checker matters as much as the allocator. [`CheckGrowShrink`](../../.reference/goose/src/typecheck_builtins.h) identifies the receiver's roots and delegates shrinking to `ShrinkThrough`; an unknown or temporary root is refused. “Grow-only” does not mean an unconditional absence of shrink operations in this implementation: shrink must pass its separate checks.

### Inspiration for With

A scoped append-only arena could let application developers build ASTs, graphs, indexes, and scene data without estimating capacity or replacing every link with an untyped integer. It needs an explicit guarantee that append preserves prior addresses and the appropriate views; ordinary Vec should not acquire that guarantee if its implementation cannot uphold it.

Stable addresses do not grant arbitrary mutable aliases. Extending a container while a view exists needs an effect narrower than general receiver mutation, with proof that the operation neither overwrites nor invalidates the observed element. With's ownership and alias rules remain authoritative.

Non-Copy elements with Drop still require destruction. Bulk reclamation can remove per-object allocator traffic; it cannot erase file closes or other effects. Region reset must reject live views or use an explicitly checked handle design. Independently closing editor buffers should retain ordinary independent owners rather than being forced into one never-shrinking region.

**Acceptance experiment:** build linked nodes while appending, retain a read view, attempt mutation/reset/removal, and exercise scope exits with observable Drop values. Measure reservation, committed pages, resident memory, and cleanup separately. Compare a segmented implementation with virtual reservation on native and constrained targets.

**Recommendation:** explore as an optional storage contract. With's [handles](../spec/006_handles.md) already cover dynamic removal; stable borrows and reusable handles solve different problems.

## 5. Narrow links should carry type and region meaning

### What the implementation does

[`FixedSize`](../../.reference/goose/src/codegen_types.h) gives a fixed-width relative reference the size of its encoded integer, rather than a pointer. [`EmitRelRangeCheck` and `EmitRelStoreAt`](../../.reference/goose/src/codegen_construct.h) encode links and emit width checks where storage bounds do not make them unnecessary. Pool-relative and self-relative forms use different bases; optionality affects the zero representation.

This is evidence of a real representation mechanism, not merely a tree example using small integer indices. Construction at the final field location is part of making self-relative encoding correct.

### Inspiration for With

Explore typed compact links inside an explicit region or image representation. Compiler AST storage is a plausible internal pilot. A link must retain its target type and region identity; width overflow must fail before truncation. Null must not collide with a valid target.

The main decision is relocation. Moving an entire self-contained image can preserve offsets; copying one linked record out of it generally cannot. An ordinary `&T` must never silently become a relative link that changes its lifetime or identity contract. Narrowing is representation only when all those meanings remain fixed.

With's generational arena direction is closer to Vale than to Goose's freely reused typed slots. The local [Vale linear-region implementation](../../.reference/Vale/Backend/src/region/linear/linear.cpp) is a follow-up reference for serialization/region boundaries; its existence does not establish equivalence to Goose's encoding.

**Acceptance experiment:** same-region forward/backward links, forbidden cross-region links, the narrowest and largest encodable distances, relocation of the whole image, and forbidden extraction of a linked record. Decide reuse and generation policy independently of width.

**Recommendation:** start within an explicit image/storage API; defer language-wide relative-reference syntax until a library cannot express the contract ergonomically.

## 6. Validated images are the strongest new storage opportunity

### What the implementation does

[`VerifyFn`](../../.reference/goose/src/codegen_types.h) caches a generated verifier per element type. Fixed-size elements can be framed and link-checked in one walk. Variable elements with links get a first walk that marks starts in a bitmap and a second walk that checks links.

`EmitVerifyWalk` bounds reads, rejects invalid booleans, uses bounded varint decoding, handles nested arrays and variant payloads, and walks only the appropriate live content. `EmitVerifyLink` checks a target is within the image and either a fixed-element boundary or a marked start. Variant targets additionally check the expected tag.

[`EmitFromBytes`](../../.reference/goose/src/codegen_builtins.h) requires a bounded length prefix to account for exactly the remaining bytes, applies a bitmap scratch limit, invokes the verifier, and copies the payload into the destination only on success. It publishes an empty array and false on rejection. [`TypeCheck::CheckBuiltin`](../../.reference/goose/src/typecheck_builtins.h) rejects unsupported result kinds and element types without a verifier. These are concrete front-end, verifier, and materialization paths.

### Inspiration for With

Offer a compiler-generated validator for an explicitly defined compact image type, yielding a read-only view whose lifetime belongs to the owning bytes or mapping. Also offer an owned decode path. Construction of a typed view from arbitrary bytes must go through validation; the bytes must remain immutable for the entire view lifetime.

Goose's inspected loader **copies** after validation. A zero-copy mapped With view would be additional work, including alignment, mapping lifetime, concurrent mutation, target byte order, and invalidation. It is not a capability proven by Goose's `from_bytes`.

An image needs explicit layout/version identity when used durably. Structural safety is different from checksums, authentication, schema compatibility, UTF-8 validity, acyclicity, and application invariants. A graph with safe links may contain cycles; recursive application traversal still needs its own bounds. Raw images must exclude destructor-bearing owners, process pointers, foreign handles, and padding that exposes uninitialized data unless a separate representation rule makes them safe.

This is adjacent to With's [storage-type proposal](storage-types-and-caller-places-spec.md), but not equivalent: byte-valid storage does not establish valid graph links or business invariants. Keep one canonical layout descriptor and derive encoding, checking, and access from it.

**Acceptance experiment:** use a small tree and a variable-record image. Corrupt lengths, tags, booleans, varints, link destinations, and variant targets; truncate and extend; test zero-size values, arithmetic extremes, cycles, and verifier scratch limits. Execute traversal of every accepted mutated image under memory diagnostics. Verify views cannot outlive or mutate the owning bytes.

**Recommendation:** high-value research after destination/origin foundations. Adopt generated verification and loud unsupported-type rejection; do not adopt raw-memory persistence as a universal default.

## 7. Variable-size records and variants can become dedicated packed collections

### What the implementation does

[`ClassOf` and `FixedSize`](../../.reference/goose/src/codegen_types.h) distinguish fixed, variable, and resizable representations. Fixed enum size uses the maximum variant payload plus a tag. Variable representations use generated size walks; `EmitVerifyWalk` dispatches by tag and walks that variant's payload. Construction emits fields into a bytes destination rather than embedding heap pointers for each dynamic field.

### Inspiration for With

Packed streams could store logs, syntax nodes, messages, and immutable query results in space proportional to their actual payloads. A normal enum and Vec should keep their established replacement, indexing, borrowing, and ownership semantics. A compact stream may need sequential iteration and an offset index for random access.

Begin with freeze/build operations for owned data, rather than making every user struct dynamically sized. Explicitly distinguish packed borrowing from ordinary references when unaligned fields cannot support the same operations. Changing representation is not merely a default if it removes indexing or changes mutation capabilities.

**Acceptance experiment:** mostly-small variants with a rare large string payload; compare ordinary storage, packed storage, and packed storage with an index. Measure full construction, traversal, lookup, and teardown at equal semantics. Include non-Copy fields and partial-build failure before claiming broader support.

**Recommendation:** exploratory. Source mechanisms justify investigating density; repository benchmark prose does not establish a speedup for With.

## Not now: survey items 8–13

These mechanisms remain useful reference material, but do not drive the current decisions.

- **8. UI protocols:** `ui_push_scope` / `ui_expect_scope` in [ui_core.c](../../.reference/goose/src/ui/ui_core.c) track begin/end nesting. Defer new UI bindings under D51’s SQLite-first sequence.
- **9. Static consumer blocks:** `CheckFunValCall` / `EmitFvCall` in [typecheck_calls.h](../../.reference/goose/src/typecheck_calls.h) and [codegen_calls.h](../../.reference/goose/src/codegen_calls.h) inline checked blocks. Reference for existing push generators; no separate campaign.
- **10. Isolated workers:** flatness checks and [queue runtime](../../.reference/goose/src/runtime/runtime_threads.h) combine isolated state with per-send malloc/copy. Defer a new actor API; Crux transfer is the immediate ownership boundary.
- **11. Shader embedding:** `EmbedShader` in [typecheck_builtins.h](../../.reference/goose/src/typecheck_builtins.h) maps composed source errors back to literals. Defer shader-specific work.
- **12. Offline audio:** [audio.c](../../.reference/goose/src/audio/audio.c) shares a mixer between device and offline paths. Keep as a testing pattern, not active language work.
- **13. Case functions:** `TryDispatch` / `EmitDispatch` check and lower exhaustive variant overloads. Defer new dispatch syntax until an active With case demands it.

## Boundaries With should preserve

Goose's implementation is most persuasive where it makes a cost or proof explicit. It is least suitable as a direct model for With where that simplicity depends on a weaker or narrower contract.

* **No destructor-free cleanup model.** `EmitRestores` is not sufficient for With's owned resources. The controlling text is [§2.1](../spec/002_ownership.md): “All values have a single owner. When a variable binding goes out of scope, its value is destroyed. Destruction is deterministic.”
* **No same-type stale-slot substitution.** `B_FREE` puts an in-range index on a freelist; slice reallocation uses `memmove`, and old references do not retarget themselves. Use scoped invalidation proofs or generation-checked handles with a deliberate wrap/exhaustion policy. Type-valid bytes do not establish object identity.
* **No inferred parameter ownership from body behavior.** With [§3.8](../spec/003_borrowing.md) says: “The parameter's declared type states the mode.” Goose's reference adaptation does not override that ruling.
* **No blanket adoption of packed ABI access.** `LayoutFields` and generated pointer casts need independent target/alignment scrutiny before use in With. Layout choices cannot reconstruct semantic types or passing modes downstream.
* **No unqualified zero-allocation or zero-copy claims.** Queue nodes, external resources, array-prefix slides, and adapted block results have explicit allocation/copy paths in the inspected source.
* **No C implementation transplant.** Goose emits C and implements native layers in C/C++. With's repository requires With implementations over native APIs. Borrow algorithms and contracts, not glue code.
* **No implicit long-distance escape adoption.** `EmitRfCheck` propagates `gs_rf` and restores intermediate scopes. With has destructor-bearing resources and established Result/`?` behavior. A new nonlocal escape would need a separate effects and cleanup ruling; simpler signatures alone do not justify it.

## Proposed execution order

**Do now.** Port the sixteen benchmarks first: preserve input streams and checksums, compare all idiomatic/expert C++ and safe Rust variants, record representation differences, and retain losses. This supplies performance evidence, a ceremony census and the pre-D111 string baseline. The [With port](../../benchmarks/goose/README.md), [census](../../benchmarks/goose/census.md) and [small-size baseline](../../benchmarks/goose/baseline-small.md) are now available: all 108 implementation rows match complete stdout, across sixteen workloads. This establishes equivalence of computed results, not identical storage or proven drop behavior. RNG result-width ceremony exposed [#2279](https://github.com/withlang-dev/with/issues/2279); the bug was filed, with no RNG fix. Next small tooling work is a parse/dump/reparse/dump lane, then per-line BCE kept/removed counts with reasons (unknown bound, alias resize, overflow, missing effect summary) and non-vacuous `bce:elide`/`bce:keep` expectations. These tooling changes are proposed, not implemented here.

**Rulings informed by Goose.** The [three-option length brief](length-width.md) recommends fixed `i64` with an enforced target bound; D11 already settles signedness. The value-readout brief should distinguish identity-free value reads from resource views and mutation places, using Goose's inferred fixed-value decay as evidence. `counts.get(k) ?? 0` should require no redundant programmer choice; D22 remains authoritative until the exact change is ruled. Keep D111: Goose's explicit non-fixed copies expose O(n) work, whereas With's shared immutable strings remove that reason for ceremony.

**Campaigns, in order.** (1) Trace aggregate, return and inserted-element construction destinations, including temporary copies and drop-on-failure at every field boundary; promise only verified paths. (2) Build stable append-only storage as an ordinary std type: append does not mutate existing elements, retained views survive growth, and destructor-bearing elements still drop. First customer: compiler AST/index tables; second: Crux's paged KV cache. (3) After [vx steps 1–3](vx.md), pilot validated read-only relocatable images for tokenizer tables, structured KV pages/metadata crossing host→HBM in one payload copy, and [vx-frontier's persistence tier](vx-frontier.md). Flat tensors remain a separate layout question. Image contents have no destructors. (4) Consider packed variable-size records/variants only when these benchmark workloads establish a worthwhile density win.

**Lessons for active work.** Before vx step 2, enumerate every caller-varying fact a per-processor check reads; include it in the instance key or prove it invariant. Goose's `FnSpec::envreads` and `EnvUnchanged` explain why. Use worklists for processor instantiation and #2213's fixed point: Goose's [`CheckSpecBodyOnce` / `StackLow`](../../.reference/goose/src/typecheck_calls.h) stop nested checking when its native stack reserve runs low. Preserve declared ownership/effect boundaries; With need not import Goose's closed-world repeated body analysis to obtain its conveniences.

**Explicitly not taken.** Destructor-free cleanup contradicts deterministic destruction; same-type stale-slot reuse needs generation-checked handles instead; `return E from f` adds a per-frame propagation mechanism where With already has Result/`?`; packed unaligned defaults cannot override C layouts; sealed-trait `match` (#1860) covers the case-function need; Euclidean `%` would change migrated C programs' meaning; global per-type queues erase channel identity. The deferred UI/shader/audio and other survey extensions stay in the short “Not now” list above.
