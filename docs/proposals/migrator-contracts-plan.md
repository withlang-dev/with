# Migrator contracts: safe signatures where a migrated function's body proves them (D159)

Status: PLAN (2026-10-24), derivative of D159 (`docs/meetings/2026-10-24-D159-*.md`,
ruled and amended by Eric the same day). This plan cannot amend the ruling;
where they disagree the ruling wins. Campaign issue: #2615.

## The ruling, restated as work

Every migrated function is emitted `pub unsafe fn` today when a raw pointer
crosses it (`ci_migrate_fn_is_unsafe_to_call`). D159 lets the migrator emit a
safe signature where the function's own body proves the contract, with
exactly these inferences, each one D51-safe (a wrong inference can at worst
reject a valid program):

| | Proof from the body | Spelling in the output |
|---|---|---|
| (a1) | the first parameter is a pointer to a corpus record (the engine handle) and the body mutates through it, directly or through a corpus callee proven to | a `mut self` receiver method on that record (the presentation Eric named) |
| (a2) | a later pointer parameter the body writes through on **every** returning path, the function returning `void` or a status, the written record plain data | the parameter removed and returned: `T`, or `(status, T)` |
| (b) | a pointer argument the body stores into the engine's storage **and** a destroyer in the same corpus frees it along that path | an owned parameter (`T`, transfer) |
| (c) | a returned pointer the body derives from a parameter | `-> &T from <param>` (a view with that parameter's origin) |

Anything short of the proof keeps `pub unsafe fn`, and the generated comment
names the unproved point: "out-parameter written conditionally", "stored,
ownership unknown", "mutated through a second pointer", "passed to
`<callee>`, which no unit defines". A read-only first pointer parameter is
not in the ruling's list and stays as it is (a raw pointer, `unsafe fn`):
proving "never mutates" needs the same transitive walk as (a1), and the
ruling did not grant it; it can be a follow-up ruling once (a1) is in.

Two conditions attached to the ruling shape the design:

1. **(b) needs both halves.** Store alone is "stored, ownership unknown".
   TommyDS's intrusive links and user-data pointers are stored and not owned.
2. **Body-derived facts need a visible record.** The inferred contracts are
   an artifact of their own; the drift lane diffs them, and a change is red
   until a human has looked (the §3.4 origin-inference lesson).

## What exists

The evidence is already computed, for `with get`'s facades-by-evidence
(D121): `CiMigrate.record_fn_evidence` runs `ci_body_ownership_evidence`
(`src/CImport.w`) over each definition's C AST and records per function
`ret:<source>`, `localsrc:`, `localstore:`, `localsink:<local>:<callee>:<i>`,
`paramstore:<i>` lines plus `param_sinks` (`field;`, `global;`,
`<callee>:<i>;`); `CiFacadeDraft.resolve_ownership` turns them into retain
and destroy verdicts with reasons (`fd_retain_reason`, `fd_destroy_reason`,
`fd_propagate_destruction`, `fd_destroyers_of`). The §21.1 `writes` clause
shows the shape of a whole-corpus post-print pass: `ci_migrate_writes_mark`
places a marker in each emitted signature and `ci_migrate_apply_writes_clauses`
replaces it once every unit is printed, with a transitive fixpoint over
corpus callees. The libclang bridge (`src/compiler/ClangBridge.w`) gives the
walk `with_ci_child`, `with_ci_cursor_kind`, `with_ci_cursor_references_parameter`,
`with_ci_cursor_type`, `with_ci_binary_op`, `with_ci_unary_op`.

D159 is that evidence applied to the corpus's own signatures.

## Steps

**Step 1 — the contracts artifact, no signature change.** A pass after the
scan (`CiMigrateProject`, where `record_fn_evidence` has run for every
definition) computes one verdict per function parameter and return:

- `receiver mut` (a1): parameter 0 is `*mut R` with `R` a record the corpus
  defines, and the body assigns through it (`ci_body_assigns_to`-class
  facts on `(*p).f`, `p->f`, `*p`) or passes `p` to a corpus callee whose
  verdict is `receiver mut` at that position (fixpoint, as the writes
  clause does).
- `out <i> <T>` (a2): parameter `i > 0` is `*mut T`, every `return`
  statement's path writes `*p` before it (a dominance walk over the body:
  the write is in every path from entry to each return; a write under a
  condition the return does not share is "conditional"), nothing reads `*p`
  before the first write on that path, and `T` is plain data (no pointer
  field; the record's copy class is a bit-copy). The function returns
  `void` or an integer status.
- `owned <i>` (b): `paramstore:i` or a `field;` sink **and** a destroyer in
  the corpus (`fd_destroyers_of` the record the field belongs to, or a
  corpus function whose body frees that field) frees what was stored;
  otherwise `stored-unknown <i>`.
- `ret from <i>` (c): the `ret:` source is `param:i` or a local whose
  source is `param:i` (`fd_local_alias_param`), and the return type is a
  pointer.
- `unproved: <reason>` otherwise, per parameter.

`with migrate --emit-contracts <path>` writes them as TSV, one line per
function, sorted: `name<TAB>verdict[,verdict…]`, verdicts with their reasons.
The corpus pipeline writes it as `<corpus>/contracts.tsv` beside
`corpus.stamp` at promotion, and `wo-drift` diffs it: any changed line is
red with the diff printed. Basic tests (`build/selfhost.w`,
`bs_check_migrate_contracts_*`) cover each verdict and each refusal with a
small C fixture: a handle mutated directly, mutated only through a callee,
read-only; an out-parameter written on every path, written under a status
guard, partially filled, holding a pointer; a stored pointer with and
without a corpus destroyer; a returned parameter, a returned local alias of
a parameter, a returned allocation. Gate: `c-migrator-basic-tests` green;
every promoted corpus produces a `contracts.tsv` in a fresh migration
(`corpus-migrator-gate`) that the test prints and checks for the known
STC/M*LIB/TommyDS shapes (`stc_slot_stack_push` → `receiver mut, owned 1`
once (b) proves the destroyer; `tommy_list_insert_tail` → `stored-unknown`).

*Step 1 status (2026-10-24, branch `migrator-contracts`):* landed as the
`--emit-contracts` artifact, the `contracts.tsv` beside each promoted
corpus, the drift report's line diff and `bs_check_migrate_contracts`. A
fresh STC migration (775 defined functions) proves 277 mutating receivers,
1 out-parameter and 9 borrowed returns; every slot `push`/`insert` is
`stored-unknown` (STC's `i_keydrop` is a no-op: the facade owns the slot,
exactly as D148 built it); 0 `owned`; the 427 unproved rows are mostly
read-only handles (`_at`, `_top`, `_get`, `_size`, the destroyers), which
the ruling left out and which a follow-up brief can take up (a `&self`
receiver, a consumed receiver for a destroyer). #2618 filed on the way.

**Step 2 — emission.** With the artifact green and reviewed, the printer
reads the verdicts:

- (a1): the function is emitted as `pub mut fn <method>(…)` inside an
  `impl <Record>:` block the unit prints per record (grouped at the end of
  the unit, sorted by name); the method name is the C name with the
  record's prefix removed when the C name starts with it (`stc_slot_stack_push`
  on `stc_slot_stack` → `push`), the whole C name otherwise. Its body's
  references to parameter 0 become `self`. Call sites inside the corpus
  (`f(p, …)`) are printed as `(*p).method(…)` / `p.method(…)`; the migrated
  tests and the drift harness compile unchanged in meaning.
- (a2): the parameter is removed; the body's writes to `*p` write a local
  the function returns (`T`, or `(status, T)` when the C function returned
  a status); the result record is bit-copied out.
- (b): the parameter type is the pointee's owned With type; the body moves
  it where C stored the pointer.
- (c): `-> &T from <param>`; the body's return of a raw pointer becomes the
  view.
- Every other parameter stays as it was; a function with any unproved
  pointer parameter stays `pub unsafe fn`, and the generated comment above
  it names the unproved point.

A function proved on every pointer it takes is `pub fn`. The bundle
interface (`rt.wi`-style `.wi`) carries the new signatures; a facade calling
a proved function needs no `unsafe`. Basic tests check the emitted text and
`check` it; the corpus drift harness (`stc`'s `examples/strings/replace.c`,
TommyDS's `check.c`, M*LIB's multimap example) runs with the new shapes.

*Step 2 status (2026-10-25, branch `migrator-contracts-2`):* landed as
written for (a1), (a2) and (c), with these refinements the corpora forced:
the body is not rewritten to `self`; the method binds the C parameter name
to `self` cast back to its raw type in a one-line prologue and prints the
body unchanged in a safe context (every raw operation carries its own
`unsafe`), an out-parameter is a raw pointer to the local `__ci_out` the
method returns (`return __ci_out` is added where a C void body falls off its
end), and (c) is emitted only for `return self` (a pointer loaded from a
field, or arithmetic on one, may be NULL or point anywhere; the artifact
also refuses `ret-from` when a NULL is returned on some path, which the
ownership proof skipped). A method's `self` is never NULL, so a handle the
body accepts as NULL (`if (ctx == NULL) return PCRE2_ERROR_NULL`) or that a
corpus caller passes as NULL is `unproved: NULL is an accepted argument`.
A unit's own `static` function, a header no single unit owns, a variadic
function, a corpus keeping C linkage, and two functions that would share a
method name (`method-collision:` in the artifact) keep the raw signature; a
header-owned inline definition (STC's templates) is published and so is a
method. Call sites print as `(*p).m(a)`; an out-argument is assigned from
the return (`let r = (*p).m(a); *o = r.1; r.0` beside a status). (b) is not
emitted: an owned parameter stored into a raw-pointer field needs the record
to hold the owned value, a representation change for a brief. Fresh
migrations, every corpus lane green: STC 176 methods in 36 `impl` blocks (of
276 mutating receivers; `stc_word_stack` has `push`, `pop`, `reserve`),
pcre2 15, zlib 19, TommyDS 19, c-algorithms 18, M*LIB 26. Found on the way:
pointer arithmetic now carries its pointer type (a field through it printed
without `unsafe`), and the pcre2 cohesive check and build lanes placed the
fresh units under `lib/std/re`, where their imports fell back to the
promoted corpus (fixed: the import path's layout).

**Step 3 — generation bump and the first re-promotion.** The migrator
generation (`--generation`, D112) moves; the promote guard's trigger is
`migrator-pin:#2615` for a corpus that re-promotes to take contracts. Under
D112 no promoted corpus is touched for the bump itself. The STC corpus is
the first to re-promote (the facades it feeds are the hot path the ruling
named): `lib/std/collections/{stack,queue,linked_list,deque,priority_queue,
ordered_set,ordered_map,unordered_set,unordered_map,bit_set}.w` and
`std.algorithms` call the proved methods without `unsafe`; the ceremony
census records the fall. The `unsafe` left in a facade is the slot-lifetime
step that crosses an ownership boundary the engine never sees.

*Step 3 status (2026-10-25, branch `migrator-contracts-3`):* the migrator
generation is a hash of its sources (D112), so it moved with step 2; the STC
corpus and its test programs were re-promoted under `migrator-pin:#2615`. The
first promotion found two more refusals the ruling needs: a handle the body
indexes or steps (`refs[i]`, `p + k`), itself or through a corpus callee, is
an array of records and no receiver (`std.algorithms` calls
`stc_slotrefs_sort(refs, n)` over n records: a method on one would write past
it), and an iterator record's functions are named after it
(`stc_word_stack_next` on `stc_word_stack_iter` is `next`). The facades call
the methods — `self.words.push(w)`, `self.slots.pop()`, `cursor.next()` —
and 47 engine-call `unsafe` blocks are gone (370 → 323 across
`lib/std/collections`). What stays `unsafe` is what the ruling left out: the
read-only surface (`size`, `top`, `at`, `front`, `begin`, `drop`; a `&self`
receiver is the follow-up brief) and the slot pushes, which store a pointer
the engine never frees (`stored-unknown`: the facade's slot lifetime).

**Step 4 — the contract diff is a gate.** `wo-drift` red on a changed
`contracts.tsv` until a human marks the new contracts reviewed (the promote
rewrites the file; the lane compares the promoted file against the fresh
migration's, exactly as it compares the modules).

*Step 4 status (2026-10-25, branch `migrator-contracts-4`):* the gate is the
promotion itself, which D112 already makes a deliberate, human act with a
stated trigger: the promoted `contracts.tsv` is in git, so the PR shows every
proof that moved, and the promote now prints those lines (`+`/`-` per
function) before it copies, beside the trigger. The artifact is under the
stamped modules hash (`corpus_dir_listing`), so a hand edit of it fails the
corpus's integrity check exactly as an edited module does; the integrity
target takes it as an input. The drift report prints the same diff for a
fresh migration against the promoted artifact (it never gates, D112: a
migrator change alone never re-promotes a corpus, so a red there would be
permanent). Corpora promoted before the artifact existed carry none and
hash as before; STC was re-stamped under the rule. The two follow-ups the
ruling left open were briefs, ruled as Amendment 2 (Eric, 2026-10-25): the
read receiver is step 5; owned fields are a proposal of their own.

**Step 5 — the read receiver (Amendment 2).** A pointer-typed first
parameter is presented as a `&self` receiver (`pub fn <m>`) when the body
proves it is never written through: no store through the handle or any
local aliasing it (`mutparam:`, `mutlocal:` against the `localsrc:`
aliases); every callee that receives it, or a part of it, is a corpus
function proved read-only at that position (the mutation fixpoint
inverted: a greatest fixed point over `param_sinks`, `localsink:` and
`memberarg:`) or a non-corpus function on the explicit pure list
(`memcmp`, `memchr`, `strlen`, `strcmp`, `strncmp`; never a name's
guess); it is never stored (`param_stores`), never freed in part
(`freesmember:`), never cast away from `const` (`castaway:`), never
indexed, never NULL-accepting. A read receiver that returns a pointer
needs inference (c) on the same function or stays `unsafe fn`
("returns a pointer the receiver's view cannot carry"); (c) itself is
tightened to what is a part of the parameter for certain — the parameter
(`return self`) or the address of one of its members (`&self->f`,
`retaddr:`) — a pointer loaded from a field (`self->data`, `retload:`)
may be NULL or point anywhere and keeps the function raw. The STC read
surface that pays off at once: `size`, `is_empty`, `capacity`, `begin`,
`end`, `index` (no pointer return); `at`, `top`, `front`, `back` return
`self->data + k` and stay raw until a non-NULL proof exists (a brief if
the facades need it; today they read through `unsafe fn place`; the
human form is `docs/proposals/claims.md`, tier 1: a cited facts line that
makes the return `-> &u64 from self`).
Inference (b)'s three rows (c-algorithms) keep `pub unsafe fn` with
"stores an argument; ownership not modeled" in the generated comment; the
owned-field design is its own proposal.

*Step 5 status (2026-10-25, branch `migrator-contracts-5`):* landed as
written; every corpus lane green on fresh migrations. Fresh counts: STC 179
read receivers (121 `pub fn` methods beside 181 `pub mut fn`), pcre2 26,
zlib 27, TommyDS 35, c-algorithms 30, M*LIB 34; refused for a pointer
return without (c): STC 58, TommyDS 18, c-algorithms 29, M*LIB 20; refused
for a callee that may write or is off the pure list: pcre2 14, STC 12. One
more call-site rule the corpora forced: a corpus call to a method whose
return became a view hands the C site the raw pointer it expects (`&T as
*const T`, then the declared type). STC re-promoted under
`migrator-pin:#2615`; the facades call the read methods (`self.words.size()`,
`self.set.begin()`, `self.bits.test(i)`) and lost 34 more `unsafe` blocks
(319 → 285). What stays `unsafe` in a facade now: the loaded-pointer reads
(`at`, `top`, `front`, `back`, `get`, which need a non-NULL proof), the
destroyers (`drop` frees a part of the record: consuming, not a receiver),
the slot pushes and the keyed `insert`/`erase` (a second pointer parameter),
and the slot-lifetime steps the facade owns.

## What is deliberately not inferred

- A read-only first pointer that returns a loaded pointer (`front`, `at`):
  the view would need a non-NULL proof the body does not give.
- A second pointer the body reads and writes in place, an input/output
  pointer, an array the body mutates: unproved (the ruling's "everything
  else").
- Ownership from a name (`_free`, `_destroy`): never (D51); only a body that
  frees proves destruction.
- A callee no unit defines (libc beyond the observer list, another corpus):
  the proof stops there and the parameter is unproved with the callee named.
- Anything in a `c_import` facade: D51/D121 own that path; this plan is the
  migrated corpus's own signatures only.

## Done means

The contracts artifact exists for every corpus and the drift lane diffs it;
each inference and refusal has a basic test; the STC corpus re-promoted
under the new generation compiles its facades without engine-call `unsafe`
and every facade fixture, complexity row, drop-audit cell and benchmark
row is unchanged in verdict; the ceremony census's `unsafe` counts in
`lib/std/collections` fall and the fall is recorded in this plan; #2615
closes with that evidence.
