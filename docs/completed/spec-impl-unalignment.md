# Spec ↔ Implementation Unalignment Survey

Date: 2026-06-09 · Revised: 2026-06-10 (positions re-derived against
the mission statement and BDFL philosophy; see "Operating model" and
the per-item recommendations)
Spec: `docs/with-specification.md` v7.0
Method: six parallel source audits over `src/`, `lib/std/`, `rt/`,
`test/` at commit 1373e453+, covering the spec surface NOT already
handled by `docs/completed/spec-feedback.md` (whose findings became
spec v7.0 and issues #371–#386).

---

## Operating model

Two development modes are both legitimate here:

- **Spec-first** — rulings land in the spec, issues track the
  implementation delta. Gives design coherence.
- **Groove-first** — implementation runs ahead when momentum is good
  (`with migrate` was built before it was fully spec'd), and the spec
  is back-filled from reality. Gives rules that survived contact —
  the §16.2 honest-surface doctrine came out of PCRE2 experience, not
  the other way around.

The enemy is neither mode; it is **silent divergence** — the third
state where spec and implementation disagree and *nobody decided*
(share-place was the canonical case). The obligation is
**reconciliation, not prevention**: every delta becomes visible and
gets resolved deliberately.

**Detection asymmetry (important):** the requirements.md test
campaign auto-detects *spec-ahead* gaps — a requirement with no
implementation produces a failing test → skip → issue. It is **blind
to implementation-ahead** features: no spec text → no requirement →
no test → nothing fails. `global`, regex-in-normal-code, `@[effect]`,
and `std.crypto` would all sail through a green requirements suite.
Implementation-ahead surface needs its own detector — most of it
lives in enumerable inventories (lexer keywords, parser attributes,
CLI commands/flags, stdlib modules) that a build-gate script can diff
against the spec's tables (same shape as
`scripts/check-requirements-informative.py`). See Plan, Phase 4.

## The respec/track principle

Used throughout the recommendations below:

- **Respec** only when the spec text **misleads about semantics or
  guarantees** — promises users would build on that won't hold.
  (v7.0 examples: growable-stack reference fixup, the deterministic
  elision rule, the Err-cancellation story.)
- **Keep-and-track** when the spec is **unshipped inventory** —
  surface that is simply not built yet. That is what the
  spec-leads-with-delta-issues workflow exists for. Shrinking the
  spec over unshipped inventory is spec-retreat and is wrong here.

---

## A. Aspirational spec — specified but not (fully) implemented

### A1. Language features (high impact)

| Item | Spec | Evidence | Confidence |
|------|------|----------|------------|
| Named arguments (`connect(port: 8080)`) | §9.1a | `test/spec/spec_ss09_1a_named_arguments_and_implicit_context.w:14` — "blocked: named arguments". Default parameters DO work. | High |
| Implicit parameters + `with name(expr):` contexts | §7.3a, §9.1a | Same test: "blocked: implicit context". `lib/std/context.w` has the `Context` type but no `implicit` modifier resolution. (`NK_WITH_IMPLICIT` parses; resolution absent.) | High |
| `let ... else` | §9.7 | `test/behavior/behav_let_else.w:4` — "not yet implemented" | High |
| `while let` | §9.7 | No tests, no parse evidence found | Medium ⚠ |
| Match in pipelines (`\|> match:`) | §9.7 | No tests found | Medium ⚠ |
| Set/map comprehensions | §30.5 grammar only (informative; no normative body text) | List comprehensions fully work; `{x for ...}`/`{k: v for ...}` absent | High — this is a *spec bug*: the appendix invents forms §13.6 never defines |
| `break expr` (value-carrying break from `loop`) | §13.5c claims it; §13.5a reserves the labeled form | `test/compile_errors/err_break_value.w` — "break with a value is not supported" | High — spec also internally inconsistent (§13.5a vs §13.5c) |
| `loop` construct has no defining section | used in examples; §29.13 list | implemented (`behav_loop_stmt.w`) but never formally defined (no §30.4 production, no semantics section) | High — spec gap, impl fine |
| User `Deref` trait | §3.7 | Auto-deref hardcoded to `&T`/Box/Arc/Rc (`SemaCheck.w:5448`) | High |
| User `Try` trait / `ControlFlow` | §10.2, §11.7 | No Try trait, no ControlFlow type; `?` is Result/Option-only | High |
| `MultiIndexMut`; tensor slicing `t[2:5, :, newaxis]`, `...`, `IndexSpec` | §11.7 | `MultiIndex` partial (trait + intrinsic, `behav_multi_index.w`); `MultiIndexMut` absent; slice/ellipsis/newaxis syntax unverified | High for Mut-absence; ⚠ for slicing syntax |
| Right-side operator dispatch | §11.7 | No test/evidence found | Medium ⚠ |
| `??` early-exit forms (`?? return e`, `?? break 'l`, `?? continue`) | §10.4 | Basic `??` works; early-exit forms untested | Medium ⚠ |
| Box[dyn Trait] consuming-receiver shim | §11.3 | Unverified | Medium ⚠ |
| Async methods in traits via dyn dispatch | §11.5 | No test found | Medium ⚠ |
| Associated type defaults | §11.6 | Basics work; defaults unverified | Medium ⚠ |
| Generic `extend` blocks | §9.5 | `examples/ecs/src/storage.w`: "compiler does not yet support generic extend blocks" | High |

### A2. Stdlib surface gaps

**Resolution under the principle: keep-and-track, all of it.** These
tables are unshipped inventory, not misleading guarantees — they stay
in the spec and the delta gets issue-tracked and priority-ordered.
(The earlier draft of this survey proposed roadmap-marking the long
tail; withdrawn — that was spec-retreat.)

Inventory (high confidence; `Mir.w:130-140` + `lib/std/collections.w:114-131`):

- **Iterator adapters:** have map, filter, flat_map, take, zip.
  Missing: `filter_map`, `flatten`, `drop`, `take_while`,
  `drop_while`, **`enumerate`**, `chain`, `peekable`, `chunks`,
  `windows`, `dedup`, `unique`, `intersperse`, `scan`, `step_by`,
  `zip_with`.
- **Consumers:** have reduce, fold, sum, count, partition, join(Vec).
  Missing: `product`, `min`/`max`, `min_by`/`max_by`, `find`,
  `position`, `any`/`all`/`none`, `for_each`, `sorted`/`sorted_by`,
  `group_by`, `unzip`. `collect` is **Vec-only**.
- **Iterator constructors:** `Iter.empty/once/repeat/unfold/from_fn` absent.
- **Option:** missing `zip`, `unzip`, `flatten`, `cloned`, `inspect`.
- **Result:** missing `ok`, `err`, `inspect`, `inspect_err`,
  **`context`/`with_context`** (`ContextError` type exists,
  `lib/std/result.w:21`; methods don't ⚠ verify).
- **HashMap:** `entry` unverified ⚠; `append` absent.
- **SlotMap.for_each** not found.
- **Sync:** `Condvar`, `Barrier`, `Once` absent. `Atomic[T]` spec'd
  generic; only `AtomicI64` shipped (see C2).
- **`std.testing`** module absent (asserts live in builtins);
  `require`/`check` unverified ⚠.
- **CString/CStr method surface** unverified ⚠.

**Priority tier 1 (flagships hit these in week one):** `enumerate`,
`find`, `position`, `any/all/none`, `min/max`, `for_each`, `product`,
`collect[HashMap/HashSet/String]`, `Option.flatten/inspect`,
`Result.ok/err/inspect/inspect_err/context/with_context`, `windows`,
`chunks` (Crux tiling / Weld batching), `chain`, `peekable`
(parser-shaped code), `Once`. Tier 2: the rest.

**Architecture decision (load-bearing):** everything today is a
compiler intrinsic. Expanding the stdlib as ~20 more intrinsics is
working around the known sema generic-type-erasure bug at scale —
forbidden by the root-cause doctrine. **Fix generic instantiation
first, then write the adapters as plain With generics**; the stdlib
becomes the generics test suite (the proven self-hosting pattern).
`Atomic[T]` sequences behind the same fix.

### A3. Derive gaps (§11.8)

Implemented: Copy (opt-in), Clone, Eq, Debug. Reported absent:
`Default`, `Hash`, `Ord`, `Display` (`Sema.w:85-87` DeriveReq enum) —
⚠ medium confidence, verify against `ComptimeTransform.w` before
filing. `@[derive(all)]`, `@[derive(Builder)]`, user-defined derive
targets: unverified ⚠. Resolution: keep-and-track; `Builder` stays
spec'd (it is also the forcing function for user-defined comptime
derives, §17.3, which nothing else exercises).

### A4. Config & misc

- `copy_warn_threshold` (§2.3): not implemented. Keep-and-track (low).
- **`[runtime]` with.toml keys (§14.19)**: presented as real, not
  parsed. This one IS misleading-guarantee territory (a user who sets
  `fiber_stack_size` silently gets nothing) — **respec now** to
  "implementation-defined configuration; the reference implementation
  currently uses a fixed 64 KB" + delta issue for the keys.
  (Self-inflicted during the v7.0 edit.)
- no_std attributes (`@[panic_handler]`, `@[entry]`, `@[no_main]`,
  `@[global_allocator]`, `FixedString`): unverified ⚠, likely absent.
  Phase 0 verify, then keep-and-track.
- `extern let` assignment rejection (§16.3b): unverified ⚠.

---

## B. Implementation ahead of spec — shipped but unspecified

### B1. `global` declarations — biggest unspecified surface

`global` keyword (`Token.w:156`) with real syntax and tests
(`behav_globals.w`: `global var g: i32 = 0`, `global X: T`). The spec
has **no section on globals at all** — mutability, initialization
order, borrow-checker interaction, Send/Sync obligations. (§18.7's
no_std example even uses a `static` keyword that doesn't exist.)

**Recommended ruling (needs BDFL):** layered, applying
raw-stays-explicit / modeled-becomes-humane to globals —

1. `global` (immutable, const-init): safe, free.
2. `global var` of Sync-safe types (Atomic, Mutex-wrapped): safe, free.
3. Bare `global var`: **safe in programs the compiler proves
   single-threaded** — decidable whole-program because With has
   exactly one concurrency source (Invariant 3: no `async`, no
   `thread.spawn_os`, no `@[c_export]` re-entry surface ⇒ no
   threads). Past the proof, mutation requires `unsafe`.

Smallhold's single-threaded game loop writes globals with zero
ceremony; concurrent programs get told exactly why and offered the
Atomic fix. Migrated C globals land on the raw surface until modeled
— consistent with §16.1. **Open question for the ruling:** ship the
proof-based rule in v1, or ship unsafe-fallback first and add the
proof as a precision upgrade.

### B2. Regex — flagship feature hiding in a CLI appendix

Regex literals `/pattern/flags` (`Lexer.w:722`, `Parser.w:3422`),
`=~`/`!~` (`Token.w:137-138`), capture expansion, and the full
PCRE2-migrated `std.regex` API all work in normal code; the spec
defines regex only inside §18.5b one-liners.

**Recommendation (high confidence): bless and promote.** Spec regex
literals + `=~`/`!~` (precedence row) as language surface; spec
branch-scoped `$captures` as an if-let-family refutable-binding
condition form — exactly the rule §18.5b.6 already states ("capture
bindings are created only for direct positive regex conditions").
The `$` sigil is the right call, not Perl nostalgia: captures live in
a separate namespace, so the no-shadowing rule (§29.8) can never
collide with them. Add `std.regex` to the §18.6 module map and
libstd-spec. The one-liner appendix turns out to have been the regex
design all along; it just needs promoting.

### B3. Attributes accepted by the parser, absent from the spec

`@[effect(...)]` (parameter effect pinning, `Parser.w:600-649` —
load-bearing for the §3.8 call-mode model), `@[compiler_hook]`,
`@[bench]`, `@[stack_size]`, `@[noinline]`, `@[callconv]`, plus
parser-recognized `@[biased]`, `@[TypeOf]`, etc.

**Recommendation:** per-attribute ruling: spec it / mark
compiler-internal / remove. For `@[effect]` specifically: **spec it
narrowly** as the explicit effect spelling for exactly the places
where no body exists to infer from (intrinsic-backed stdlib stubs,
`extern` declarations, optional `pub`-boundary pinning per §4.6) —
documented in the FFI/stdlib-authoring sections, never presented as
general user surface.

### B4. CLI surface (§18.5 lists ~8 entries; main.w implements ~25)

Unspecified commands: `check`, `ir`, `ast`, `tokens`, `init`,
`migrate`, `version`, `help`. Unspecified flags: `--emit-c`,
`--emit-obj`, `--dump-*` family, `--deterministic`, `-O0..-O3`,
`--alloc`, `--overflow=<mode>`. `with migrate` is referenced by
§13.5b yet has no CLI entry. **Recommendation:** a CLI appendix
table; document the user-facing set, mark the `--dump-*` family
implementation-internal.

### B5. Stdlib modules missing from the §18.6 module map

Exist, unmapped: **`std.regex`**, **`std.json`**, **`std.http`**,
**`std.crypto`** (13 submodules), `std.libc`, `std.component`,
`std.sysinfo`, `std.str_abi`, `std.stackify`, `std.internal/*`, plus
`std.build` and `std.context` (mentioned, no API coverage).
Mapped but hollow: `std.signal` (2 lines), `std.testing` (absent).
**Recommendation:** refresh the map; route API detail to
`docs/libstd-spec.md` per the existing convention.

### B6. Concurrency API detail

`chan[T](capacity)` + `Sender`/`Receiver` (`lib/std/channel.w`);
`thread.spawn_os` + `ScopedJoinHandle`. Spec uses them in examples
without API definitions. **Recommendation:** spec the surfaces
(§14.15/§14.14 expansions or libstd-spec).

### B7. Already-tracked

`=` body introducer (issue #385). `spawn` keyword (issue #381).

---

## C. Divergent — both exist and disagree

1. **`break expr`**: §13.5c claims it, implementation rejects it,
   §13.5a reserves the labeled form. **Recommendation: implement,
   loop-only** — the alternative is mutable-flag ceremony (a value
   the compiler already knows, spelled by hand). Labeled-block values
   stay reserved exactly as §13.5a says. Implementing makes §13.5c
   true and resolves the internal inconsistency in one move.
2. **`Atomic[T]` vs `AtomicI64`**: keep the spec'd generic surface
   (Crux wants it); implement after the generics fix (A2
   architecture decision); interim concrete ops are implementation
   steps, not spec text.
3. **`collect[C]()`**: spec'd multi-target, implemented Vec-only.
   Keep-and-track; tier 1.
4. **Box[dyn] consuming shims**: possibly silent divergence; Phase 0
   verify.
5. **Stale in-repo claims**: `test/spec/spec_ss09_7_pattern_matching.w`
   says "slice patterns not yet supported" while they pass elsewhere.
   Test-comment hygiene; cheap fix.

---

## D. Confirmed aligned (for the record)

Copy/Drop rules (minus size warning), defer/errdefer + E0901,
auto-deref (builtin set), dyn coercion, disjoint fields + disjoint
closure capture, record update + drops, default field values, struct
literal forms, get_disjoint (Vec + SlotMap), overflow modes + ops
(`+%`/`+|` + compound), bitwise rules (0030c685), bit methods +
std.crypto.endian, chained comparisons, widening/narrowing, fixed
arrays + no-decay, bitpacked + sub-byte ints, enum auto-accessors,
@[specified]/from_int, distinct types, tuples + unit elision,
implicit Ok wrapping, ephemeral declarations + propagation, partial
application, `it` closures, pipelines, list comprehensions, §13.6a
for-comprehensions, labels/goto/do-while, slice patterns (match),
`in` patterns/operator + Contains, chained if-let, parameter
patterns, three body forms + raw/triple/byte literals, f-string spec
grammar + validation matrix, `++` str-only, extern var/let + c_void,
repr(C)/packed/union/@[align], extern "C" fn pointers, opaque/null,
sizeof/alignof/transmute, inline asm (fully implemented), unsafe
forms + unnecessary-unsafe error, comptime core + TypeInfo + magic
constants + src()/embed_file + capability-comptime with-clauses,
min/max/abs/mul_add, error declarations + `from` conversion,
sequence/traverse, where clauses, blanket impls + overlap, `:?`
debug formatting, operator dispatch (left-side), IndexGet/IndexPlace.

---

## E. Consolidated recommendations

Re-derived 2026-06-10 against the mission statement and BDFL
philosophy. "Proposed" = ready to execute on sign-off; "Needs ruling"
= genuinely open.

| # | Item | Recommendation | Status |
|---|------|----------------|--------|
| 1 | `global` declarations | Layered rule; bare `global var` safe under whole-program single-thread proof, `unsafe` mutation past it (B1) | **RULED 2026-06-10**: spec B, conservative implementation first. Executed: spec §9.1c (v7.1), §19.4 proof-dependent amendment, issue #387 |
| 2 | Regex | Bless: literals, `=~`/`!~`, branch-scoped `$captures` as binding form; promote to real spec section + module map | **EXECUTED** (v7.1 §15.8; #396) |
| 3 | Named arguments | Implement as spec'd; add "pub parameter names are API surface" sentence | **EXECUTED** (spec sentence v7.1; #397) |
| 4 | Stdlib tables | Keep spec; tier-1/tier-2 priority; **generics fix first, adapters as With generics, no new intrinsics** | **EXECUTED** (#391 generics, #392 tier-1, #393 combinators, #388 collect) |
| 5 | Atomic[T] | Keep spec'd generic; implement after generics fix | **EXECUTED** (#394) |
| 6 | Tensor indexing | Core multi-index + range slices before the Weld demo; `...`/`newaxis`/index-writes phased behind | **EXECUTED** (#404) |
| 7 | `break expr` | Implement, loop-only; labeled-block values stay reserved | **EXECUTED** (v7.1 §13.5d + §13.5a; #401) |
| 8 | User Deref | Keep spec'd (consistency with the iter_of_self ruling: no stdlib-only ergonomics); delta issue + style guidance | **EXECUTED** (#407) |
| 9 | User Try | Keep spec'd; low-priority delta | **EXECUTED** (#408) |
| 10 | derive(Builder) | Keep spec'd; low priority; forcing function for user comptime derives | **EXECUTED** (#409, with Default/Hash/Ord/Display/all) |
| 11 | @[effect] | Spec narrowly (no-body contexts + pub pinning); never general user surface | **EXECUTED** (v7.1 §16.3d; #402) |
| 12 | Set/map comprehensions | **RULED 2026-06-10 (A2a):** one bracket comprehension family, expected-type targets, `[k: v ...]` map form; map literals `[k: v]`/`[:]`; Scala-inspired target polymorphism, no brace forms | **EXECUTED** (v7.1 §13.6 + §4.3c + §30.5; #389, #390, #388) |
| 13 | let...else, while let | Implement (spec leans on them) | **EXECUTED** (#399, #400) |
| 14 | Condvar/Once/Barrier | Keep-and-track; Once and fiber-aware Condvar tier 1.5, Barrier tier 2 | **EXECUTED** (#395) |
| 15 | `[runtime]` toml keys | Respec to implementation-defined now (misleading-guarantee); delta issue for config | **EXECUTED** (v7.1 §14.19; #403) |
| 16 | CLI/attributes/module map | Documentation sweeps + per-attribute keep/internal/remove | **EXECUTED** (v7.1 §18.5, §18.6, §29.14; internal: bench/stack_size/callconv/compiler_hook) |
| 17 | `loop` section | Write the missing normative section | **EXECUTED** (v7.1 §13.5d) |

Also executed in the v7.1 batch: match-in-pipelines delta (#406),
generic extend blocks (#405), implicit contexts (#398), `vec![...]`
spec examples replaced with §4.3c literals, integrated-collections
framing note in §13.3 (Scala target-polymorphism + lodash-grade
operation vocabulary), and the inventory gate (#410) from the
Operating model. Remaining open: Phase 0 ⚠ verifications (folded
into #393/#396/#400/#402/#406/#409 as verify-first steps where
applicable; Box[dyn] shims, `??` early-exit, right-side dispatch,
no_std attributes, CString methods still need a pass).

---

## F. The plan

**Phase 0 — Verify the ⚠ items.** Absence-of-test ≠ absence-of-
feature. Priority: derive targets, `??` early-exit, `context()/
with_context()`, while-let, right-side dispatch, CString methods,
entry API, no_std attributes, Box[dyn] shims, extern-let rejection.

**Phase 1 — The two open rulings.** (1) `global var` rule shape;
(2) map-comprehension comeback policy. Everything else in §E is
executable on sign-off.

**Phase 2 — Spec batch (v7.1).** Regex promotion, `global` section,
`loop` section, `@[effect]` text, CLI + attribute appendix tables,
§18.6 map refresh, `[runtime]` reword, §30.5 set/map deletion,
channel/thread API text, named-args API-surface sentence. Delta
issues per the convention for everything implement-side.

**Phase 3 — The sequencing milestone: generics before stdlib.**
Fix sema generic instantiation (the TY_GENERIC_INST erasure debt),
then land tier-1 stdlib as With-generic library code, then Atomic[T].
This single ordering decision prevents ~20 intrinsics of workaround
calcification.

**Phase 4 — Standing invariant: the inventory gate.** A build-gate
script (shape of `check-requirements-informative.py`) diffing lexer
keywords, parser attributes, CLI commands/flags, and `lib/std/`
modules against the spec's corresponding tables; build fails on
undocumented surface. This closes the detection asymmetry — the
requirements campaign catches spec-ahead automatically; the gate
catches implementation-ahead automatically; groove-mode stays cheap
("implement freely; when the gate trips, write the section while
it's hot or file a `spec-delta` issue").

**Phase 5 — Requirements regeneration (#386) and the test
campaign.** Positive/negative tests per requirement; failures →
skip + issue. Run after Phases 1–3 shrink the known-unaligned set,
so the campaign doesn't open hundreds of issues that a handful of
rulings would have collapsed.
