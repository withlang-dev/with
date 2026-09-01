# Decision Log

Architecture/design decisions and *why* we made them. Newest first. Each entry
records the decision, the context, the alternatives weighed, and the reasoning —
so a future maintainer (or agent) does not re-litigate a settled call, and can
tell whether a later fact should reopen it.

Format per entry: a short ID + title, date, status, and the reasoning. When a
decision supersedes an earlier one, say so in both.

---

## D35 — Compound self-assignment `.=` and inclusive ranges `..=`

**Date:** 2026-09-02
**Status:** Ruled by Eric in the D34 follow-on conversation. Verbatim:
`.=` — "line = line.replace(...) becomes line.=replace(...)" (wanted);
`..=` — "i want a ..= too. 1..=100 should include 100 where 1..100
should not include 100." Raku precedent for `.=` (the only shipped
implementation); Rust/Swift precedent for inclusive ranges. Design
pins recorded on #924/#923: `.=` is statement-position, receiver
evaluated once, desugars to `x = x.f(args)`; `..=` must NOT lower to
end+1 (type-max overflow — loop form lowers to a <= comparison,
reified ranges carry an inclusive flag). Spec wording pending Eric.
Synergies: `.=` removes a D22 view-liveness contortion class (atomic
self-replacement) and marks D34-C in-place-growth sites statically.

---

## D34 — String accumulation without ceremony: `++` gets the builder's efficiency; demand-site finalization for wrapper types

**Date:** 2026-09-02
**Status:** Ruled by Eric on the `to_str()`-ceremony brief (the trigger:
a declared `-> str` return forced an explicit `.to_str()` on a
StringBuilder tail — "extra ceremony is a literal bug"). Two rulings,
verbatim: "ok we want both A and C. A should apply to all Builder
patterns (or maybe something grander, maybe any form of 'wrapper' like
an Option or a Promise). and C absolutely if we can make ++ as
efficient as StringBuilder we should do it and remove complexity."

**C (ruled, unconditional):** `s = s ++ x` / accumulation on `str`
itself becomes amortized-efficient when the base is uniquely owned —
the ownership model statically proves the in-place-growth condition
that forces Rust and Go into a separate builder type. Consequences:
the loop-accumulator lint is DELETED (the natural spelling becomes the
fast spelling — a lint that herds users from the ergonomic form to a
ceremonial one is the anti-pattern named in the mission), and
StringBuilder retires from the user surface. Interim engineering
(bulk-memcpy push_str, zero-copy to_str) lands first since C subsumes
it.

**A (ruled for builders; grander scope needs its own design ruling):**
a value of a finalizable wrapper type satisfies an owned demand for its
built type at demand sites (return position, typed binding, argument)
— StringBuilder satisfies a `str` demand without `.to_str()`. Eric's
"maybe something grander — any form of 'wrapper' like an Option or a
Promise" opens a general demand-driven elimination design (the D22/D27
"an annotation demands what it says" doctrine extended to eliminators);
its Option arm implies implicit unwrap-panics and its Promise/Task arm
implies implicit await — semantics heavy enough that the general trait
design goes back to Eric as a brief before any implementation beyond
the builder case. Transfer-is-explicit tension noted and accepted for
finalization: consuming a builder at a demand site is the builder's
purpose.

---

## D33 — Consuming iteration: §13's `into_iter()` reaffirmed as the surface; observe-by-default stands; the iterator owns the tail

**Date:** 2026-08-31
**Status:** Ruled by Eric on the #724 brief. Satisfies D23's deferral
("#724 needs its own design ruling") — the ruling is that §13 (normative
since 2026-02-24) and D27 already compose the answer, so the spec text
stands unchanged. Supersedes nothing; #712's borrow-default iteration is
reaffirmed alongside it.

**Ruling (verbatim):**

> §13 reaffirmed as the ruling — into_iter() is the consuming surface;
> D23's deferral is satisfied by the D27 composition. Campaign per §5
> approved. B deferred as possible future sugar over A, not a competing
> surface. Trait rename: bring me the naming pair before it lands. Add
> a moved-iterator fixture to acceptance.

Where: "§5" is the brief's implementation campaign (below); "A" is
`into_iter()` as spec'd; "B" is a hypothetical `for x in move xs:`
keyword spelling — deferred as possible future *sugar over*
`into_iter()`, never a competing mechanism.

**The rule.** D27 composed at loop granularity: access observes,
transfer is explicit. `for x in collection:` borrows — always, per
#712; the collection outlives the loop. `collection.into_iter()` is the
explicit whole-collection transfer — a `move fn` that consumes the
collection and returns an iterator that *owns* it, yielding elements by
move. Early exit (`break`, `?`, return) drops the iterator; its drop
releases the un-yielded tail and the buffer exactly once — ordinary
Higher RAII, no special loop semantics.

**Context.** #724: `await_all` owns its collection but #712 routed all
iteration through borrow dispatch, so `pending.push(task)` bit-copied
Tasks through views — two owners, invalid free at runtime (ss14_11 ×2
pinned as evidence). Pre-#712 owned iteration consumed soundly; #712
rightly retired it for borrows and owned-element transfer went with it.
The gap: no way at all for an owned collection to yield elements by
move. Meanwhile spec §13 had normatively listed
`for item in my_vec.into_iter():   // consuming (moves elements)` since
2026-02-24 while D23 called the design open — this ruling resolves that
collision by reaffirming the spec text.

**Alternatives weighed.** Keyword-only `for x in move xs:` — reads
with-y post-D32, but needs new for-loop lowering, yields no iterator
value for combinators, and would require respelling §13 anyway;
deferred as future sugar. No-consuming-iteration (concrete
`remove`-loop / `Vec`-typed APIs only) — taxes every owned-collection
user with clone-or-drain ceremony and forces async combinators onto
concrete types; rejected.

**Campaign (approved).** `VecIntoIter[T]` (owning, non-ephemeral) +
`move fn into_iter()` on `Vec` + `Iter` impl; the existing borrow-only
`IntoIter[T]` trait is misnamed (it is Rust's `&Vec` impl wearing the
owned impl's name) — rename it and introduce a genuine consuming trait,
**naming pair goes to Eric before it lands**; `await_all`/`await_first`
respelled onto consuming iteration (the double-own dies structurally);
ss14_11 pins removed as acceptance; `--debug-alloc` fixtures for
full-consume, break-early tail drop, error-path drop, and — per the
ruling — a **moved-iterator** fixture (the iterator value itself moved,
then driven; drop-exactly-once).

**Naming ruling (2026-08-31, Eric: "I bless A").** The pair: a trait is
named by the method it promises. **`IntoIter[T]`** = consuming
(`move fn into_iter() -> VecIntoIter[T]`); **`Iterable[T]`** = borrowing
(`fn iter(self: &Self) -> VecIter[T]`, the former misnamed `IntoIter`).
Internally consistent with the -ator-less house scheme: trait `Iter` /
type `VecIter` :: trait `IntoIter` / type `VecIntoIter`. Alternatives
declined: `IntoIterable`/`Iterable` (name drifts from its own method),
`AsIter` (Rust-ese, not English).

---

## D32 — STRICT field moves: implicit is an error everywhere; explicit `move place.field` through a mutable path is the one vacate

**Date:** 2026-08-30
**Status:** Ruled by Eric ("I rule for STRICT") on the #782 receiver-arm
brief and its three-option cost comparison (MOJO / STRICT / VALE).
Normative from the §2.2 sentence landing with this entry. Supersedes the
§2.4 Drop/non-Drop partial-move conditional (uniform rule replaces it),
and supersedes the arm-1 conditional trigger recorded on #782 (implicit
field move erred only on a later whole-use of the base; now it errs at
the move site unconditionally — arm 1's flow machinery is retirable).
The explicit-move sanction (arm 1's `move x.f` pin,
behav_move_field_then_whole_transfer) is retained and extended to `mut`
receivers. D17's field-take blank semantics are unchanged — reached only
through the explicit spelling now.

**Ruling (blessed wording):**

> STRICT costs a medium one-time migration (mechanically bounded,
> precisely countable before committing) and buys the smallest permanent
> system: one sentence in the spec, one site-local check in the
> compiler, one error shape for users, the flow machinery retirable, and
> zero silent shapes left. It spends nothing on new surface because the
> explicit spelling already exists and is already the tree's idiom.

The rule: a field never moves out implicitly — anywhere, in any
context. The only vacate is the explicit `move place.field`, and only
through a mutable path (`var` base or `mut fn` receiver); through a read
path it is an error (a vacate is a write). Whole values decompose whole
(destructuring, record update). Errors fire at the move site with
fix-its for both intents (`move` to vacate; `.clone()` to keep whole).

**Context.** #782's family: implicit field moves blank their source
(§2.5.1 — memory-safe by construction) and the blanks were read back
silently — the capability `mkdir '/out/bin'` incident, blanked tuple
storage, and the receiver arm found via #783 (`5 0` cross-call reads; a
read `fn` blanking the caller's field). Arm 1 caught the owned-local
whole-use shapes; the receiver shapes are cross-call and can only error
at the move site — which exposed that a site-local rule subsumes the
flow-conditional one entirely.

**Alternatives weighed.** MOJO (extend arm 1's conditional to
receivers): cheapest to land, most complex to carry — four interacting
rules, two error timings, one silent shape left (implicit move with no
later whole-use), and the checker keeps its subtlest machinery forever.
VALE (no field move-out at all, per Vale's unconditional
CantMoveOutOfMemberT): purest single rule, but requires designing a
`take()`/`swap()` surface plus struct destructuring patterns (absent
today) before migrating, outlaws the 83-site explicit-move idiom for an
equivalent spelling, and buys no safety reset-on-move doesn't already
guarantee.

**References (verified in-tree).** Rust: field moves out of borrows are
E0507 absolutely (`rustc_borrowck/src/borrowck_errors.rs:275`); owned
locals move implicitly with E0382 flow-tracking (the famously confusing
late-fire diagnostic); the take is library `mem::replace/take`
(`core/src/mem/mod.rs:955`, `Default`-bounded). STRICT is stricter than
Rust on owned locals and looser on mutable borrows — both deltas replace
Rust's owned-vs-borrowed axis and flow analysis with one local question
(did you write `move`?), made sound by §2.5.1's valid-empty blank, which
Rust lacks. Vale: `CantMoveOutOfMemberT` unconditionally
(`TypingPass/…/LocalHelper.scala:177`). Swift: borrowed-cannot-consume +
used-after-consume + partial-consume restrictions
(`DiagnosticsSIL.def:871/896`). Mojo: explicit `^` transfer sigil,
uninitialized-until-reinit (`ownership.mdx:287-289`) — the landed arm-1
polarity was already Mojo-shaped; STRICT keeps its explicit half and
drops its flow half. Zig/Go: no move semantics; N/A. C-migrated code is
unexposed (its string fields are Copy raw pointers).

**Reopen if** the migration count reveals an implicit-move idiom class
whose explicit respelling is genuinely worse than the rule (surface to
Eric with the sites), or if a future decomposition surface (struct
let-patterns) motivates revisiting VALE's function-spelled take.

---

## D31 — `&place as <integer-type>` is a compile error; fix-it offers both intents

**Date:** 2026-08-30
**Status:** Ruled by Eric ("I bless the decision") on the #888 brief.
Normative from the §16.11 spec sentence landing with this entry. Carves out
of D22 §6.2's cast-target owned-value demand for exactly one case; D22 §6.2
stays intact for every other cast target.

**Ruling (blessed wording):**

> Error on `&place as <integer-type>`, fix-it offering both intents
> (`&raw const place as u64` for the address, `place as u64` for the
> value), D22 §6.2 untouched everywhere else.

**Context.** #888 was filed as an "-O1 miscompile: raw store dropped." The
IR disproved it: the repro's `&target[0] as u64` materialized the Copy
pointee per D22 §6.2 (cast target = owned-value demand) and stored the byte
value 65 as a pointer — conforming behavior, catastrophic intent mismatch.
The same trap crashed std.http's recv loop (str punned over a stack buffer).

**Alternatives weighed.** (a) Keep the D22 value reading and document —
rejected: under the value reading the `&` is an unnecessary character
("every unnecessary character is a compiler failure"), and the spelling's
only plausible intent is address-taking, which it silently is not. (b) Make
`&place as <int>` mean the address (C's reading) — rejected: it would fork
D22's transparency doctrine and make one cast target semantically special.
(c) Error with fix-its — accepted: catches a real mistake the compiler
cannot otherwise resolve, costs zero legitimate programs (the value intent
is shorter without the `&`; the address intent has two blessed spellings).

**References.** Rust rejects `&T as u64` (E0606; must go through
`as *const T as usize`). Zig requires `@intFromPtr`. Mojo (verified
in-tree) has no borrow-to-integer path at all: address-of is a named
construction (`Pointer(to=x)`), pointer-to-int is an explicit conversion
(`Int(ptr)`). C is the lone divergent and reads the ADDRESS — so a C
migrant is exactly who the silent value reading burns. The migrator is
unaffected: it already emits `&raw const … as …` spellings.

**Reopen if** a target model ever defines a safe borrow-to-integer
observation, which would get its own ruling.

---

## D30 — Retire the internal runtime ABI; remaining boundaries speak C; §16.3c call-site coercion is the ergonomic dual

**Date:** 2026-08-09
**Status:** Ruled by Eric ("approved, blessed, condoned, and ratified") on the
#761 brief. Normative from the §16.3e spec sentence landing with this entry.
The implementation is deliberately NON-COMPLIANT until the retirement lands
(sequenced after the 747-flip merge/reseed; the seed-built out/lib interim,
747-flip `ad053bea`, bridges until then). Supersedes in part D18's extern
`-> str` ownership-contract bullet (annotated there). The transitional
`with_*` guidance in CLAUDE.md remains operative until the retirement lands
and is marked accordingly.

**Ruling (blessed wording):**

> The `with_*` runtime seam was a C-bootstrap fossil kept for build economy,
> not a semantic necessity; #761 showed a boundary with independently-derived
> ownership contracts corrupts silently. The runtime compiles in-unit like
> the embedded stdlib; codegen lowers to ordinary module functions;
> pre-compiled runtime objects are permitted only as a cache keyed by
> compiler version and target, where a hit is byte-identical to the in-unit
> result. Remaining boundaries face genuinely foreign code and speak C
> (§16.3e); §16.3c call-site coercion is the ergonomic dual that makes the
> prohibition free. Reopen only if a With-to-With dynamic-library ABI is
> ever designed — that surface gets its own ruling.

**Context and reasoning.** #761's root cause: the codegen-emitted str
intrinsics' ownership convention was derived twice — the emitter assumed
caller-owns, while the callee side fell out of whichever compiler built the
rt object (seed-built bodies freed nothing; flip-built bodies dropped their
consuming-`str` params — disassembly-proven on 42 functions). Nothing tied
the sides together, so which rt a binary linked decided whether it worked.
Alternatives weighed and rejected: a runtime-ABI tier default reinterpreting
plain `T` (a signature that lies by tier — against D5's authority sentence);
per-function `@[effect]` pins (ceremony restating what inference knows, and
an unmarked-wrong default for the next function); Swift-style ownership
conventions in `FnAbi` and a Rust-style raw-parts ABI (both regulate a seam
this ruling deletes — and Rust's own runtime fleeing Rust's rules is the
cautionary tale, not the pattern). The dissolving move: the seam exists for
history and build economy only; make the runtime ordinary With code and the
defect class becomes unrepresentable. Objects as cache: allowed. Objects as
boundary: retired.

**Boundary prohibition (§16.3e).** After the retirement, every surviving ABI
surface (`extern fn`, `@[c_export]`, `c_import` decls) faces a side that
cannot see With's types; With-managed types there are hard errors (Zig's
stance — `zig/src/Sema.zig:8615`; deliberately not Rust's `improper_ctypes`
lint, which makes the guardrail opt-out). The prohibition costs nothing at
call sites because §16.3c's modeled coercion (call-scoped NUL-terminated
temporaries; `retains:` refusing `str` with `to_cstring` named, #602/D4)
carries the ergonomics. Cross-links: D5 (signatures authoritative), D6
(`FnAbi` remains the single descriptor for the boundaries that remain),
D18 (leak-freedom; superseded in part here), D24 (independent builds),
D13 (version metadata post-link — the cache-key design must respect both).

---

## D29 — Name resolution: implicit std availability as a lowest-priority fallback tier; #750 resolved by staged conformance

**Date:** 2026-08-01
**Status:** Ruled by Eric ("BDFL has spoken."), verbatim directive below.
Normative from the spec update landing with this entry (§18.2). The spec is
deliberately ahead of the implementation: it describes the destination (the
fallback tier), while the implementation reaches it in stages (work items
below). Supersedes the flat injection of lib/std names that #750 documented;
extends D28's chain toward the roundtrip.

**Ruling (verbatim):**

> The destination design is implicit standard-library availability. Every
> public declaration of std is available by its unqualified name as the
> lowest-priority resolution tier. Fallback declarations retain canonical
> module identity — this tier is a lookup fallback, never injection into the
> module's declaration table. Precedence order: lexical bindings and generic
> parameters, current-module declarations, explicit imports/aliases, prelude,
> unique std fallback. A user-controlled declaration is never shadowed,
> merged, or impl-captured by this tier. Fallback matching is exact — no
> fuzzy matching, ever. Two or more std candidates for one name is a hard
> ambiguity error, with each candidate offered as an insertable-import
> fix-it; candidate ranking may order suggestions but never resolves. In
> impl and extend headers, a non-prelude std name may not resolve through
> fallback alone — explicit import or qualified path required. Compatibility
> invariant: a std addition may turn a unique fallback resolution into an
> ambiguity, but may never rebind an existing resolution. Engine packages
> are ordinary explicit dependencies and are never ambient; a public
> re-export from std is deliberate promotion into the ambient vocabulary.
> The prelude's enumerated list is retained; its role narrows to (a) names
> permitted bare in impl/extend headers and (b) the --no-std core. Do not
> add HashMap/HashSet or anything else to it.

**Work items (staged):**

1. **#750 unblock — scaffolding, the roundtrip gate.** Option A narrowly,
   labeled *scaffolding* in every commit message and doc comment: remove
   flat injection of lib/std declarations into user modules; enforce the
   §18.2 prelude exactly as enumerated with §18.1 precedence (user wins);
   std internals resolve their own names via the existing tier machinery;
   ship a fix-it inserting the missing `use` for any unresolved name
   uniquely matching a public std declaration, applied automatically by the
   migrator to its own output; migrate the affected behavior tests via the
   fix-it, not by hand, forking (not overwriting) the import-free originals
   into a quarantined suite named as the D acceptance corpus. Acceptance:
   roundtrip output compiles; `type Regex { r: i32 }` resolves to the
   user's type; `impl Copy for CString` attaches to the user's type; the
   string.w module-drop probe no longer rebinds Display impls; all 935
   behavior tests green post-migration.
2. **B campaign (filed, not started):** canonical module-qualified identity
   for every declaration, carried through impl attachment, trait
   resolution/coherence, generic instantiation, MIR, comptime, all
   backends, and the migrator — no short-name re-resolution after initial
   lookup, anywhere. Sequenced after the #747 str flip unless Eric
   re-orders.
3. **D activation (filed, blocked on B):** enable the fallback tier per the
   ruling; impl/extend-header restriction; ambiguity diagnostic with
   insertable-import fix-its and context-aware ranking; `with update`
   records prior fallback resolutions and inserts pinning imports as a
   reviewable migration (ships with or before the tier — hard requirement);
   `with explain-name` / resolved-path-on-hover observability;
   migrator/formatter removes `use` lines that become redundant, including
   the ones item 1 inserted; un-quarantine the D acceptance corpus as the
   activation test; migrator targets std shims where coverage exists,
   otherwise emits explicit engine dependency + qualified calls, logging
   emitted engine paths as the shim-priority worklist.

**Rejected (do not build, do not re-propose):** option C or any
migrate-only/lean-prelude build mode; prelude-list expansion; fuzzy or
ranked resolution; any "surprising symbol" lint or second curation surface
in tooling; flat injection in any form.

**Escalate, don't decide:** any change to the ruling text; any new
normative spec wording; anything making fallback resolution order- or
ranking-dependent; the shim naming policy for common nouns
(Connection/Config/Error) when it first bites.

---

## D28 — str flips owned+Drop; view tokens lose Copy interim; ephemeral view-structs are the token shape; roundtrip migrate pins its cap until the flip

**Date:** 2026-07-31
**Status:** Ruled by Eric ("your predictions are both correct. Proceed with my
blessing.") on the two-ruling #744 brief. Answers D27's reopen clause and the
audit note it left open ("the #691 str flip must decide what `Copy` means for
str-bearing structs").

**Ruling 1 — str is owned and drops; Copy-with-str-fields ends with the flip.**
§2.3 rules 1–3 and §15.1 already classify `str` (= `String`) as owning+Drop
and recursively exclude it from `Copy`; the flip makes the text true at
runtime. The shipped Copy-with-str tokens (`JsonView`, `Package`,
`ProjectInfo`, `Diagnostics`) lose `Copy` as interim conformance — boundaries
borrow, and D5 auto-referencing keeps every call site spelled identically.
The remaining `impl Copy` sites (~95) are audited for str-bearing fields in
the flip campaign. Rejected: Swift-style CoW/ARC str (hidden refcount per
implicit copy — invisible cost) and Vale-style shared-immutable str (Vale
classifies `StrT` as `ShareT`/`ImmutableT` — verified in
`.reference/Vale/Frontend/TypingPass/src/dev/vale/typing/Compiler.scala:1655`
— a share-managed memory doctrine that forks "every allocation is owned...
its owner's scope releases it").

**Ruling 2 — ephemeral view-structs are the view-token mechanism's new
shape.** §3.3 bans reference fields, so a token cannot respell `str` fields
as `&str`; D27 ruling 1's reopen clause anticipated exactly this ("mechanism,
not intent"). Destination: extend the existing `ephemeral` type marker
(`ScopedJoinHandle` precedent; §3.4 propagation) to structs with view
fields — such a struct is itself second-class (param/local/return only, no
heap storage, no escape) and may opt into `Copy`. When it lands, `JsonView`
re-acquires by-value Copy and D27 ruling 1's declared signatures stand
unchanged. Separate campaign; normative spec wording goes to Eric before it
lands.

**Ruling 3 — the roundtrip's migrate step pins its memory cap until the
flip.** Per-step `WITH_MEMORY_LIMIT_BYTES=0` in `emitc_migrate_compiler_c`
only, with the revert condition named in the code (delete with the str
flip). Grounded in the #608/#693 pin doctrine: a gate red for one known,
scheduled cause stops discovering everything queued behind it (#746 was
invisible until migration could complete). The cap stays live for every
other step. Measured basis: 68.4 GB peak migrating the 48 MB compiler C,
entirely transient strings pending the flip (#744 investigation).

**Reopen if:** the flip audit finds a de-Copy'd site that breaks a shipped
surface D5 auto-ref cannot absorb (surface to Eric; do not narrow), or
ephemeral view-struct origin tracking proves irreconcilable with §3.4's
propagation chains.

---

## D27 — Element access observes; bindings name, annotations demand; JsonView is a Copy token

**Date:** 2026-07-30
**Status:** Ruled by Eric ("My will be done. Enshrine the doctrine. Purge any
dissent.") on the three-brief presentation of the parked questions from #715/
#730/#737 close-outs. Three rulings, one doctrine. Extends D22 beyond its §2.2
scope carve-out; partially supersedes D26 (see below). Implemented by the E1–E4
element-view campaign in `docs/d27-implementation-plan.md` (#740).

**Ruling 1 — Serialize/Deserialize signatures stand; JsonView opts into Copy.**
`fn serialize(self: &Self, out: JsonWriter) -> JsonWriter` and
`fn deserialize(input: JsonView) -> Self` are correct as declared. The sink is
genuinely consumed (thread-and-return, the same take-and-return idiom the
compiler itself uses); §15.1 bans the `&mut` sink every other reference uses,
and Go's `TextAppender` proves the threading shape sound. `input` stays owned
because `JsonView` is a view token — it opts into `Copy` (the D25 execution
pattern: `ReceiverMode`, `AstFileId`, `CancellationToken`). No trait-impl
churn. Docs spelling `out: &mut Writer` are dissent and were repaired. Audit
note: the #691 str flip must decide what `Copy` means for str-bearing structs;
JsonView joins Package/ProjectInfo on that list.

**Ruling 2 — Element access observes; `remove` transfers.** Normative text
landed beside the operator-trait table in the specification. `xs[i]` denotes
the element place (view on read, `IndexPlace` mutation on write — receiver
chains included); `xs.get(i)` returns `&T`, read-only, panicking on
out-of-range (absence is a bug for positional access; keyed maps keep
`Option[&V]` per D22 because absence is normal there); `remove(i) -> T` is
the transfer op. Copy elements materialize at owned demands; non-Copy owned
demands are rejected per D22 §13.6. Reference basis, verified in-tree: Vale
(`List.get -> &E`, `a[i]` is an AddressExpression, `UseP` loads a borrow,
move-out unexpressible) and Rust (`Index -> &Output`, E0508) — the only two
references with ownership + destructors both chose this; the shape-dependent
copy semantics we shipped instead produced the #715/#726 double-free class in
our own compiler ~45 times. Consequences the campaign must land: the interim
element gate (D26) is SUPERSEDED, not layered, when views land;
mutation-through-`get` chains (issue64 pins) are respelled to the `[i]` place
form — `get` chains observe only.

**Ruling 3 — A binding names what's there; an annotation demands what it
says.** Unannotated `let` binds the view unchanged (D22 rule 2); a typed
binding establishes an owned-value demand (D22 §6.2) — uniformly for field
projections and element access. Two implementation divergences to repair: the
#730 field gate fires at unannotated lets (over-broad — retained DELIBERATELY
as the safe conservative stand-in until origins-through-bindings can catch a
let-bound view consumed later; retire it with the ruling-2 campaign, not
before), and typed lets of elements were not gated (closed immediately —
annotation present means demand established).

**Supersession.** D26's "let is not a demand" holds for unannotated lets and
is now grounded in the ruling's own §6.2 text; its blanket exclusion of ALL
let sites from the element gate is superseded for typed bindings. D22 §2.2's
"does not restandardize Vec indexing or lookup" is superseded by ruling 2 —
that carve-out was scope discipline, not a semantic choice, and this ruling
fills it with the same doctrine D22 applied to keyed maps.

**Reopen if:** the #691 str-flip audit finds Copy-with-str untenable for view
tokens (ruling 1's mechanism, not its intent, would need a new shape); or the
element-view campaign finds receiver-chain place semantics for `[i]`
irreconcilable with view-liveness (§3.2) — surface to Eric, do not narrow the
doctrine unilaterally.

---

## D26 — #715 element-copy gate fires at owned demands only; a let binding is not an owned demand

**Date:** 2026-07-28
**Status:** Done as an interim projection, then superseded in implementation by
D27's uniform element-view campaign (#740).

**Decision.** Sema rejects a non-Copy, Drop-bearing element reached via
`vec.get(i)` / `vec[i]` when it must satisfy an owned demand: a by-value call
argument, an assignment into an owned place, or a struct-literal field. A plain
`let` binding of such an expression is NOT gated.

**Why let is excluded.** Two proofs, one from the ruling and one from shipped
behavior. The D22 ruling: a view "materializes an independent `T` only when an
owned-value demand has already been established" — binding does not establish
one. And the issue-64 behavior pins (`issue64_receiver_shape_matrix` et al.)
assert `let item = inners.get(0); item.tags.push(99)` mutates the vec's element
in place — the binding is a place-chain alias today, and gating it would outlaw
a shipped, pinned surface. The first gate draft treated let as an owned demand
and broke exactly those pins; the narrowing is conformance, not retreat.

**Known residuals, on purpose.**
- A let-bound element that is *later* consumed escapes the gate (the gate keys
  on the get/index expression, not on bindings). The cure is D22's uniform
  view semantics for element access (plan line 334), under which the binding
  IS a `&T` and any later owned demand is checked structurally. Do not try to
  patch this by data-flow-tracking bindings in the interim gate.
- Whether a let binding is an owned demand for *field* projections through an
  explicit borrow (#730's gate currently says yes at let sites) is the same
  question and should get one uniform answer when Vec-element view semantics
  land. Surfaced to Eric with the #715 close-out.
- `Vec[i32][1, 2]` spells a collection literal (type-level index base); the
  gate must consult `index_expr_is_type_level`, as `check_index` does, or it
  misreads the literal as an element read.

**Reopen if:** Eric rules that binding a view to a name is itself an owned
demand, or D22's element-access-as-view implementation lands (which subsumes
this gate and should replace it).

---

## D25 — D5's supersession is implemented: the classifier is gone

**Date:** 2026-07-27
**Status:** Done — executes Eric's D5-overruled ruling; supersedes D5's
implementation notes wherever they described the effects sweep.

**Decision.** `Sema.assign_share_place_abi` (the effects-based free-parameter
share-place classifier) is deleted. A free parameter's ownership mode comes
only from its declared type: `&T` borrows (plain call spelling auto-refs),
plain `T` is owned by the callee. Receiver share-place (D12) is untouched and
is now the only inference — gated to parameter 0 (#732) and matched by
canonical type-name text.

**Execution calls worth not re-litigating.**
- 199 read-only free params across src/ and lib/std were migrated to `&T` by
  tools/migrate_shareplace.w (live Parameter facts + Lexer splices). Types
  that are only ever a discriminant opted into Copy instead of borrowing:
  ReceiverMode, AllocConstructKind, std Order, the Analysis enums, AstFileId.
- eff=[read] is NOT proof a param only reads: field-moves and consuming calls
  through a share-place param were invisible to effect analysis (#730's
  family). Five such fns keep plain owned params — the restore_* state
  transfers, store_workspace_record — because their bodies move out of the
  parameter.
- The sweep had been silently repairing real holes it now can't: generic
  receivers never classified via the declared path (NK_TYPE_GENERIC d0 is the
  base SYMBOL, not a node), per-module symbol identity split owner matching,
  and callee drops for owned generic params exposed missing eager caches and
  unterminating recursive-enum drop emission (fixed: rescue backfill at
  codegen's field queries; `__drop_enum_<tid>` outlining).
- Bootstrap rule for signature migrations: callee-side `T`→`&T` in lib/std is
  seed-compatible (owned args auto-ref), but a caller-side view flowing into a
  std signature the seed's embedded stdlib predates is not — those couple
  only after the next reseed (CImport.return_current was the instance).

**What would reopen this:** nothing short of Eric reversing the D5 ruling.
Free-parameter ownership inference does not come back for convenience.

---

## D24 — Independent builds never share an address space

**Date:** 2026-07-26
**Status:** Accepted — BDFL ruling.
**Deciders:** Eric (BDFL)

**Decision.** A build is a process boundary. `parallel(workspaces)` in a
build.w runs each workspace compile as its own `with __workspace-compile`
child process: the plan crosses as a serialized file, the result comes
back the same way, and the children share no memory with the evaluator or
each other. The former implementation — worker threads handed raw interior
pointers into a shared job vector — is deleted and must not return in any
form. An intercept-active workspace still runs in-process (its message
stream needs the live Compilation), sequentially.

**Context (#729).** The thread fan-out was the site of a multi-layer
double-free hunt: share-place-classified params retaining vec handles,
whole-job element copies, and hand-rolled `jobs.ptr + i` arithmetic —
every layer invisible to the ownership analyses because raw pointers and
threads opt out of them. The ruling ends the class structurally instead
of patching its instances: "we claim Rust-level safety; builds have no
business sharing a single process." The build pool (#683) already used
processes for pooled targets; this aligns comptime parallelism with it.

**Reopen if:** never for safety reasons; only revisit the mechanism if
plan serialization becomes a genuine bottleneck, and then only with an
isolation-preserving design (e.g. immutable shared mappings), not shared
mutable memory.

---

## D23 — Known-issue test disposition: expected-red is committed, loud, and bidirectional

**Date:** 2026-07-26
**Status:** Accepted — BDFL ruling.
**Deciders:** Eric (BDFL)

**Decision.** A test fixture documenting an open bug carries
`//! known-issue: #NNN <one-line why>` as its first directive. The runner
tolerates that fixture's red (printing `[known-issue #NNN] <file> red as
expected` while the underlying failure output stays visible) and FAILS the
fixture if it passes, so a fixed issue forces the directive's removal in the
same change. A red without the directive fails the lane as before. Test-green
therefore means "no unexplained red," not "no red."

**Context.** The reseed evidence gate (`:test-green` → `:update-seed`)
requires fresh lane-pass markers. After #714, the spec lane carried six reds
that Eric's own rulings keep red (4× #723 pre-existing spec debt, red on the
seed too; 2× ss14_11 held as #724 evidence), hard-blocking reseed while the
seed aged past 600 commits. Alternatives weighed: fixing all six first
(#724 needs its own design ruling; #723's four are separate root-cause
campaigns), silently bypassing the marker (forbidden — weakening the check),
runtime skips à la Go `T.Skip` (hides the red and carries no issue binding).
The adopted model is Rust compiletest's `known-bug: #NNNNN`
(`src/tools/compiletest/src/directives.rs`), which binds every tolerated red
to an issue and re-fails when the bug is fixed.

**Reopen if:** the directive count grows past a handful — expected-red is a
disposition for ruled, filed debt, not a parking lot; every entry must cite
an open issue that someone intends to close.
## Enum discriminant resolution is enum-scoped; no bare-name fallback

**Date:** 2026-07-25
**Status:** Accepted
**Deciders:** Rob O'Callahan

**Decision.** `enum_variant_discriminant_for_type` and
`type_reflection_variant_discriminant` trust `disc_values` **only** through the
qualified `Enum.Variant` key. When the qualified key is absent they fall through
to the variant `index` (for payload enums) rather than to the bare variant-name
key.

**Context.** `disc_values` is populated only for DiscEnums (`enum X: i32: A =
0`), keyed by BOTH the bare variant-name sym and the qualified `X.A` sym. Payload
enums (`enum Option[T] { Some(T) | None }`) never register `disc_values`; their
discriminant is the declaration index. The bare key is therefore shared across
every enum that declares a variant of that name. The compiler's own `enum
CliOneLinerMode { None = 0 }` set `disc_values["None"] = 0`, and the old bare
fallback made `enum_variant_discriminant_for_type(Option[..], None)` return 0
instead of 1. For a niche-encoded `Option[&V]` (the D22 map-view type), codegen's
`RK_DISCRIMINANT` computes `None = (ptr == null) = 1`, so `x.is_none()` lowered
to `discriminant == 0` (i.e. `is_some`) — every niche `is_none` was inverted,
sending `None` into `unwrap` (`unwrap on None` abort). This is why head
self-hosting aborted at `CodegenDispatch.mir_indirect_value_local_ptr`: the
niche `Option[&i64]` returned by `mir_local_types.get(..)` never crashed on a
tiny program (no other enum named a `None` variant), only inside the full
compiler.

**Alternatives weighed.** (a) Register `disc_values` for payload enums too — but
the bare key still collides, so it only papers over the lookup; the bare entry
stays ambiguous. (b) Make codegen's niche path derive the discriminant from the
semantic disc — insufficient, because the bug is that the semantic disc itself
was resolved through a colliding global name key. (c, chosen) Never consult the
bare `disc_values` key: both enum kinds register their qualified variant in
`variant_lookup`, so `qualified_enum_variant_sym` always yields the genuine
`Enum.Variant` key for a valid enum decl; DiscEnums resolve via that qualified
`disc_values` entry, payload enums fall through to `index` (== their implicit
discriminant). No enum's discriminant is ever read through a name another enum
can shadow.

**Reopen if** a variant discriminant is ever needed without a resolvable owning
enum type; then it must be stored per-enum, never under a bare global name.

---

## D22 — Keyed-map lookup returns a uniform view; Copy materializes only under owned demand

**Date:** 2026-07-23
**Status:** Accepted — BDFL ruling. A new decision has been made, but
implementation is still in progress; the compiler/stdlib are NON-COMPLIANT
until the D22 requirements and pins pass.
**Deciders:** Eric (BDFL)

**Authority:** `docs/d22-Eric-Ruling.md` is the canonical and complete D22
ruling. This entry is only a compact index and rationale summary; any omission
or conflict here is false and must be repaired in favor of Eric's ruling.

**Decision.** `HashMap[K, V].get` and `BTreeMap[K, V].get` return
`Option[&V]` for every `V`. Their return shape never depends on whether `V` is
`Copy`. Lookup observes map-owned storage; `remove` transfers ownership and
returns `Option[V]`. The view from `get` originates only in the receiver, not
the transient key.

A `&T` remains a reference during inference, unannotated binding, inferred
return, pattern projection, and closure capture. When `T: Copy`, it may satisfy
an independently established owned demand: an explicit/declared target, a
resolved by-value argument/component/receiver, a resolved operator contract,
or an owned branch-join result. The compiler copies the pointee at that demand
boundary and then applies ordinary value coercions. Raw pointers do not
participate, and this is not a receiver-ABI change.

Patterns are structural projections, not owned-demand positions. `Some(v)` on
`Option[&V]` binds `v: &V` in every instantiation; nested projection through a
reference produces reference subviews. `unwrap`, `expect`, and `?` likewise
preserve the exact payload type. `??`, `unwrap_or`, and `unwrap_or_else` use the
general join rule: all-reference paths preserve the reference and union their
origins; an enclosing expected owned type or any independently-owned reaching
expression anchors an owned result and compatible `&Copy` paths materialize.
The rule is independent of arm order. Removing the last owned anchor may
change an inferred result back to a reference; an explicit target type pins
the intended result.

Origins follow semantic values through `Option`, `Result`, tuples, patterns,
branches, and compiler-generated elimination. Wrapper spelling never erases a
view origin. A contextual Copy read, explicit clone, or consuming ownership
transfer ends the origin only for the independent owned result. D22 also
standardizes `Option[&T].copied() -> Option[T]` for `T: Copy` and
`Option[&T].cloned() -> Option[T]` for `T: Clone` as explicit ownership
boundaries.

**Diagnostic contract.** If a later error depends on a join's owned anchor,
the diagnostic identifies that anchor and the relevant materialized arms. A
view-invalidating mutation explains that the binding views its collection and
offers an owned type annotation for `Copy` pointees. A non-`Copy` `??` mismatch
explains the borrowed-success/owned-default split and suggests `.cloned()`, a
borrowed default, or `remove` only when each remedy is actually applicable.

**Why this is the With answer.** Rust and Vale give keyed lookup one borrowed
shape. Zig keeps two uniformly typed operations (`get` by value and `getPtr`
by address); Go and Swift return values because their value/GC models make
that safe. None makes `get` itself change shape by generic instantiation. With
keeps that uniform contract and spends compiler complexity at the place where
the programmer's intent becomes knowable: an owned-value demand. Python/Mojo
users get `counts.get(k) ?? 0` and ordinary arithmetic without sigils; Rust
users get a stateable borrowing API; C/C++ users retain native, explicit
ownership. Reference identity and lifetime remain real information until an
owned context deliberately spends them.

**Alternatives rejected.** Copy-or-view lookup was rejected because a method's
public return shape would vary by instantiation and forwarding generic APIs
could not state one contract. Uniform borrow with only explicit dereference or
`.copied()` was safe and pure but imposed Rust-shaped ceremony on the common
Copy case. Eager materialization at `unwrap` or pattern binding merely moved
the conditional return shape to every elimination spelling and made generic
patterns unstable. Ambient `&Copy -> Copy` inference was rejected because an
unannotated binding would silently discard identity and origin information.

**Supersedes.** This reverses §3.8's former call-site-only boundary for Copy
pointee reads and retires
`test/compile_errors/err_ref_copy_no_return_coercion.w` as a language
requirement. The fixture remains temporarily as a marked NON-COMPLIANCE pin
until implementation converts it to a must-compile test. D22 also supersedes
every active statement that `HashMap.get` or `BTreeMap.get` returns
`Option[V]`. No decision-log rationale for the old call-site-only boundary was
found; this record does not invent one.

`Vec`, string, array, and slice indexing/lookup signatures are not
restandardized here. D22's general expression, pattern, join, and origin rules
apply to their existing signatures; changing those signatures is a separate
D23-candidate ruling. `SlotMap.get` already has the required uniform
`Option[&T]` contract.

**Required pins.** Origin survives `unwrap`; origin survives pattern/`if let`;
origin survives `?`; two borrowed `??` paths union origins; an annotated Copy
snapshot remains usable after map mutation; a removed owned value remains
usable after mutation; and mutation after the final view use remains accepted
as the NLL precision control. A mixed five-arm match pins one owned anchor,
four materialized view arms, arm-order independence, and an explicit result
annotation that stabilizes later edits. Non-`Copy` `??` diagnostics pin every
applicable remedy and never recommend an unavailable clone or invalid borrow.

**Implementation sequencing.** Doctrine lands first. The excluded
`test/non_compliant/d22/` matrix versions the acceptance criteria without
weakening the green battery. Transparent-carrier origin propagation lands
before contextual Copy reads and join materialization; implementation design
is a separate follow-up and must preserve the one ABI descriptor rule.

**What would reopen this.** Evidence that contextual Copy materialization
cannot be defined as one expected-type operation across calls, returns,
operators, and joins without changing inference or ABI unpredictably; or a
uniform alternative that preserves map API contracts, Copy ergonomics, view
identity, and generic forwarding with less language machinery. Implementation
inconvenience alone does not reopen it.

---

## D21 — Unit-returning mutator pipelines thread the receiver place; `mut fn` cannot duplicate receiver ownership

**Date:** 2026-07-22
**Status:** Accepted — BDFL ruling; implementation is NON-COMPLIANT pending the
compiler/stdlib follow-up.
**Deciders:** Eric (BDFL)

**Decision.** A pipeline stage that resolves to a `mut fn` whose resolved
concrete return type is `Unit` performs the ordinary mutating call and continues
with the same receiver place. The test is static after return inference,
overload resolution, and generic substitution; it is not restricted to a
literal `-> Unit` annotation. A `mut fn` stage with any other return type
continues with its returned value. `Never` diverges under the ordinary rules and
has no continuation.

A named receiver remains its original place. An rvalue receiver is materialized
as a statement temporary. If that place remains the pipeline's final value, an
ordinary value context may move it out; if a non-Unit stage switches the
pipeline to another value, the receiver temporary is dropped at statement end.
All argument evaluation, exclusivity, view-liveness, aliasing, and mutation
ordering are exactly those of the corresponding ordinary calls — pipelines do
not mint a second place-mutation regime.

The receiver contract and the return contract remain distinct. A `mut fn` may
return useful values, including a Copy result, a tracked view, a fresh owned
value, or ownership moved from a projection whose source is reset under D17.
It may not return the non-Copy receiver itself, or duplicate ownership of
storage the receiver still owns, because the caller retains the receiver place.
Receiver-returning fluency is a consuming contract and is spelled `move fn`.

**Supersedes.** This reverses the receiver-returning `Vec.push` design shipped
in `b99fd86c` and recorded by
`docs/feature_plans/stdlib-fluent-builder-blocker.md` and the historical
`docs/completed/build-plan.md`. It also supersedes the receiver-return/move-out/
reinitialize field-chain model in `docs/completed/drop-move-ownership.md` for
Unit mutators. `Vec.push`, `Vec.clear`, and `Vec.set_i32` are Unit-returning
in-place mutators; their pipeline fluency comes from place-threading, never from
an owned copy of the receiver.

D16 and D17 remain the ordinary ownership laws beneath this ruling: D16 governs
explicitly moved rvalue roots and statement-temporary destruction; D17 permits
a sound projection transfer only because reset-on-move removes that ownership
from the receiver. Neither permits the duplicated whole-receiver ownership this
ruling rejects.

**Why this is the With answer.** Vale's `List.add` has two overloads: a borrowed
receiver returning void and an owned receiver returning the List; its compiler
borrows a named local receiver and preserves ownership for a non-local
expression. That proves the ownership split is coherent, but Vale's fluent form
is a dot chain, not With's pipeline. Rust `Vec::push`, Swift `Array.append`, and
Zig `ArrayList.append` are Unit/void in-place mutators; Go's `append` returns a
new slice header and requires assignment. With already knows both facts needed
to remove the ceremony safely — the receiver is a place and Unit carries no
information — so the compiler threads the place only in that information-free
case.

This follows the mission literally: compiler complexity replaces programmer
ceremony without weakening ownership. It also preserves meaningful results:
`v |> try_push(x)` carries the returned bool, and `v |> pop() |> unwrap()`
carries the returned Option while leaving `v` alive and mutated.

**Alternatives rejected.**

- *Keep one universal pipeline rewrite and add Vale-style `mut`/`move`
  overloads.* This preserves `x |> f(a) == f(x, a)` as a single law and keeps
  value-category intelligence local to overload selection. Rejected because a
  natural chain works for a temporary but breaks on a named place after its
  first Unit result, forcing statements or `(move v)` where the compiler already
  knows how to preserve the place.
- *Thread the place after every `mut fn`, regardless of return type.* Rejected by
  `let succeeded = v |> try_push(x)`: it would bind/move `v` and silently discard
  the bool the API deliberately returned. With already has receiver-only builder
  semantics in `with ... as mut`; pipelines continue with meaningful results.
- *Let a `mut fn` return its non-Copy receiver.* Unsound: the caller retains the
  receiver place while the return creates a second owner of the same storage.
  Resetting or zeroing one side merely moves or destroys the caller's value and
  does not make the declared `mut` contract truthful.

**Required pins.** Named-place Unit chains; rvalue-rooted Unit chains; ordinary
assignment-move capture; generic resolved-Unit vs resolved-non-Unit stages; a
named mixed chain (`push` then `pop`) that returns the element while leaving the
receiver live and mutated; the rvalue mixed chain whose returned Option arrives
and whose hidden Vec drops exactly once at statement end; `Never` divergence;
ordinary argument-independence acceptance/rejection; and a compile error for a
`mut fn` that duplicates its non-Copy receiver into an owned return. Moved-out
projection, Copy, view, and fresh-owned returns remain accepted controls.

**What would reopen this.** A pipeline model that can carry both receiver place
and method result without ambiguity or new ceremony, or an ownership model that
can truthfully return a receiver while the caller retains its place without
creating two owners. Implementation inconvenience does not reopen it.

---

## D20 — The spec leads; spec changes are solemn

**Date:** 2026-07-22
**Status:** Accepted.
**Deciders:** Eric (BDFL)

**Decision.** The specification leads the implementation: a spec change is a
ruling that the product is NON-COMPLIANT until the implementation catches
up. There is no implement-first-spec-after, no holding spec text until code
lands, and no syncing the spec to the implementation. And spec changes are
solemn: only Eric authors or blesses normative spec text — the exact words
(D16 precedent). Agents draft and propose; a mission directive or agreed
direction is not approval of wording.

**Context.** During the #691 flip an agent added a §2.5.1 ownership
paragraph on the strength of the D18 mission directive plus the
spec-first sequencing rule — conflating sequence authority with authoring
authority, and then offering to "revert the spec until the code lands,"
which inverts the entire model. The spec is the bible: it moves first, by
ruling, and reality is measured against it.

**What would reopen this.** Nothing.

---

## D19 — Verification cost scales with blast radius; batteries bless batches

**Date:** 2026-07-22
**Status:** Accepted.
**Deciders:** Eric (BDFL)

**Decision.** The full battery blesses a BATCH of commits, not each commit;
per-change verification is the iterate tier (`with check` / `:dev` +
targeted tests). Only ownership/drop, codegen-determinism, and ABI changes
must sit alone in their batch (with the drop audits). Corollary for the
build system itself: a request must cost what it names — installing a
blessed artifact is a manifest check plus a file copy, never a graph
evaluation (the `:update-seed`/`:install-user` fast path), and evidence is
written once by the step that produces it, only read thereafter.

**Why.** Battery-per-change grew from real incidents, but at ~20–40 min per
battery it made a day of small commits cost hours of redundant
recompilation of the same 160k lines (#684 measures the constant). Process
is a resource with the same failure mode as memory: obligations allocated
per incident and never freed. Verification depth now follows risk, and the
gates themselves must not re-derive what the battery already proved.

**What would reopen this.** A regression that a batched battery localized
too slowly to bisect — that argues for faster builds (#684), not more
batteries.

---

## D18 — Leak-freedom is a language invariant, not an optimization target

**Date:** 2026-07-22
**Status:** Accepted (mission-level ruling; mission.md amended).
**Deciders:** Eric (BDFL)

**Decision.** Making a memory leak must take deliberate, visible effort.
Every allocation is owned from the moment it is made — by the handle that
holds it, not by virtue of what it contains — and its owner's scope releases
it, compiler-proven. This supersedes the *provisional* status of A5/#608
("POD-element buffers leak by design"): that state was always scheduled to
end with #691, but as an optimization/scheduling matter; it is now a
mission violation with the flip as its first (not final) installment.

**The conceptual root cause (recorded so it cannot recur).** The 2026-07-22
memory campaign (issues #701–#703) traced every observed leak class — POD
Vec/str buffers, `++` rebuild-and-abandon chains, extern-returned strings,
per-call interpreter frames, ~890 concurrent accumulation ladders in the
build runner — to one chain of design errors:

1. *Reclamation was coupled to the wrong predicate.* One flag
   (`type_needs_drop`) answered two orthogonal questions: "does dropping
   this have user-observable effects?" and "does this value own heap?"
   Ownership was derived from a value's CONTENTS (POD elements ⇒ no drop)
   instead of from the HANDLE (it allocated; it owns). A `Vec[i32]` owns a
   buffer no matter how trivial its elements are.
2. *The obligation had inverted polarity.* Sound RAII makes "every
   allocation has an owner charged with freeing it" the default and makes
   opting out explicit. With made obligation the exception (Drop impls)
   and leak the default for everything else. Dead values from
   reassignment (`s = s ++ x`) had no scheduled release at all.
3. *Allocation paths existed outside the model.* Extern fns returning
   heap values (`with_fs_read_file -> str`) recorded no ownership fact;
   nobody was ever charged with the free. The runtime's own primitives
   must live under the same discipline (vec_grow already frees its
   superseded buffer — the discipline is achievable at every layer).
4. *Nothing forced the provisional state to end.* Leaking is memory-safe,
   so no gate tripped: the allocator was invisible to platform tools, the
   debug ledger truncated at scale, and there was no leak gate in the
   battery. A "temporary" decision with no forcing function is permanent.
5. *The mission bar was borrowed, not derived.* "Exactly as safe as Rust"
   imported Rust's frame — and Rust defines leaking as safe (mem::forget
   is safe). The invariant that IS this language's identity — the `with`
   scope releases what it holds — was never written down, so every
   downstream decision could trade it away without contradiction. Vale,
   our chosen ownership reference, gets this right: linear values MUST be
   consumed; there is no silent forget. We adopted Vale's machinery and
   initially skipped the one property that guarantees leak-freedom.

**Consequences.**
- #691 (the flip) is the first installment: heap-owning handles get
  scope-end release regardless of element POD-ness, and reassignment
  releases the superseded value.
- Extern signatures returning heap values must carry an ownership
  contract; an extern `-> str` means caller-owned with a scheduled drop,
  or must be spelled borrowed. No allocation path outside the model.
  [Superseded in part by D30/§16.3e: an extern `-> str` (or `str`/`&str`
  param) is now a hard error at ABI boundaries — With-managed types do
  not cross them at all. The leak-freedom reasoning stands; the ownership
  contract lives in the §16.3c binding model, never in a `str`-spelled
  boundary signature.]
- Deliberate leaking gets a loud spelling (explicit forget/arena types
  with named scopes), never a silent default. Long-lived memory is owned
  by a named scope (`with arena:` …), which is the language's own idiom.
- The battery gains a leak gate (debug-alloc leak count = 0) once the
  flip lands, and the #702 8GB runner budget is the flip's acceptance
  test. Observability keeps the invariant honest: WITH_ALLOC_SYSTEM=1
  (leaks/Instruments visibility) and #703 (scalable ledger with site
  attribution) exist so a leak is always one command away from a name.

**What would reopen this.** Nothing short of a mission change. Performance
work may batch or arena-ize releases (an arena is an owner with a named
scope) but may not reintroduce ownerless allocations.

---

## D17 — Consuming a field writes the root; `move` applies to a place

**Date:** 2026-07-21
**Status:** Accepted for projection transfers. D21 supersedes any
receiver-returning extrapolation from this rule.
**Deciders:** Eric (BDFL)

**Decision.** Ownership-forcing effects (consume/escape_value) do not cross
a NON-COPY projection: a callee that consumes a FIELD of a place blanks the
field (reset-on-move, §2.5.1) and leaves the root's place valid-but-changed
— a WRITE on the root, never a consume of it. A `mut fn` receiver therefore
suffices for methods that hand a field to a consuming callee; the
`move fn` escalation cascade (#691's 57 blocked methods, the promotion
`audit_receiver_projection_origins` already branded incorrect) is gone.
Alongside it, `move` applies to a place: `f(move self.r)` is the explicit
spelling; the field is blanked through whatever pointer reaches the base
(#697 machinery), so the caller's later drop skips it. POD-field moves are
plain copies. Under §3.8 a plain-`T` parameter consumes without an extra
call-site `move`; explicit `move self.r` remains a legal intent spelling.
Section 2.4's partial-move ban for Drop-impl owners is unchanged.

**D21 boundary.** "A field transfer writes the root" does not mean "a mutable
borrow may return an owned copy of the root." A transferred non-Copy projection
remains valid only because reset-on-move blanks that projection. D21 supersedes
any broader reading that would let a `mut fn` return the whole non-Copy receiver
or storage whose ownership the receiver retains; the sound projection-transfer
rule above remains in force for `pop`, `remove`, `take`, and equivalent APIs.

**The Copy-projection distinction (load-bearing).** A COPY-typed projection
(raw pointer, handle) keeps the old promotion: escaping it captures the
root's CONTENT by aliasing — nothing is blanked, so demoting to write would
be unsound for lifetime reasoning. std/thread.w's `@[effect(worker:
escape_value)]` pin on spawn_os caught exactly this during implementation
(the transmuted fn value escapes via a Copy fn_ptr field) — the effect-pin
feature enforcing its contract as designed.

**Alternatives weighed.** Keeping the promotion forces `move fn` on every
method that consumes any field, transitively — Rust-shaped virality that
made the compiler's own driver API unusable under the #691 flip. Weakening
without the Copy guard breaks aliasing-escape contracts (the pin caught
it). Threading `&mut`-style out-params instead is forbidden by §1.4/§3.3.

**Enforced by:** the m-probe matrix in the D17 commit, `--dump-abi`
verdicts (field-consuming `mut fn` receiver: eff=[write], by-place), drop-audit
field_take cells, and the #697/#698 debug-alloc fixtures. Would reopen on:
per-field effect summaries (which could carry field-precise consume without
promotion), or a change to reset-on-move that makes field blanks
observable.

---

## D16 — `move x` is rvalue-uniform: it always moves, callee-independent

**Date:** 2026-07-21
**Status:** Accepted; D21 relies on this statement-temporary rule and does not
change explicit `move` semantics.
**Deciders:** Eric (BDFL)

**Decision.** `move x` at a call site always moves: the value is materialized
as a statement temporary and the source binding is reset immediately. An owned
(plain `T`) callee consumes the temporary through the call; a borrowing (`&T`)
callee borrows the temporary, which is destroyed at the end of the enclosing
statement (§2.4's temporary rule). `move x`'s caller-visible contract is
therefore callee-independent: after the statement, the binding is invalid and
the value is gone. Plain `T` already declares consumption and needs no
call-site acknowledgment; there is likewise no diagnostic for `move` into a
borrowing callee — it is meaningful early destruction, not noise.

**Context.** Before this ruling, `f(move x)` into a borrowing param
borrowed: the binding was statically invalidated but the value silently lived
until the caller's scope exit — a deferred-drop lie (a lock/fd moved into a
consumer for deterministic release stayed held). Found while grounding
#697/#691. The later D5 supersession made the borrowing mode explicit as `&T`;
the rvalue-uniform temporary rule remains the same.

**Alternatives weighed.**
- *Make it illegal* (`move` iff callee consumes; Rust/Vale make the construct
  inexpressible by typing): fails the no-ceremony diagnostic bar — after this
  ruling the construct has a well-defined, harmless meaning, and an error
  would force interaction about nothing (the same test that forbids must-use
  Result ceremony). Also an instantiation-dependent legality cliff for generic
  forwarders (effects are inferred per specialization), and callee body edits
  (consume → read) would break every `move` caller.
- *Warning*: post-ruling the operation does something (early destruction);
  warning on meaningful code is noise.
- *Status quo*: a silent RAII-timing surprise.

**References.** Swift is the only reference language with the exact construct
and chose the same semantics (OwnershipManifesto: `move(x)` yields an rvalue
and leaves the variable uninitialized; reinit heals a `var`; a temporary
passed to a borrowing parameter dies at end of the full expression). Rust's
`Operand::Move` passes call arguments "in-place — the callee might just get a
reference to this place" with the source set to uninit: uniform pointer ABI,
ownership follows the contract (D6 stays intact). The implementation may later
elide the temporary copy by aliasing the source storage; this entry fixes the
semantics, not the materialization strategy.

**Enforced by:** test/debug_alloc/da_move_into_shareplace_timing.w (legacy
fixture name; timing),
drop-audit cell move_into_borrow/bare (exactly-once). Would reopen on: a
borrowing ABI change that makes borrowing a doomed temporary unsound.

---

## D15 — One loop back-edge carried-move predicate; `break` is a separate edge

**Date:** 2026-07-20
**Status:** Accepted.
**Deciders:** Eric (BDFL)

### The decision

The move checker's "is this binding used moved on the next iteration?" test is
computed by a single pure predicate — `is_loop_carried_move(entry_state,
cur_state, needs_drop)` = `entry==LIVE && cur==MOVED && needs_drop` — that BOTH
loop back-edges call: the fall-through (`finalize_loop_move_state`) and the
`continue` (`check_loop_continue_carried_move`), including their
`WITH_TRACE_MOVE` verdict lines. Re-inlining the condition per edge is
forbidden.

`break` (`capture_loop_break_move_state`) is deliberately NOT folded into this
predicate. It is an **exit** edge: it propagates the current move-state *out* of
the loop into the post-loop state (any binding MOVED at a break is MOVED after
the loop). It has no `entry==LIVE` guard because that is correct — it is not a
carried-move error, it is a different operation. A future maintainer should not
"unify" break with the back-edge predicate; that would be wrong.

### Context / why

#696: the `continue` back-edge check had drifted from the fall-through check —
it fired on `cur==MOVED` alone, dropping the `entry==LIVE` guard, so a value
moved *before* a loop with a `continue` was wrongly flagged as moved *inside*
it. It shipped in #613 with zero tests. Root cause was per-edge re-derivation of
one predicate — the same failure mode D6 forbids for call ABI ("`FnAbi` is the
single ABI source of truth — never re-derive call ABI per-path"). The instance
fix (give continue the loop-entry snapshot) is not enough on its own: with the
condition still inlined at two sites, a third back-edge could reintroduce the
divergence. So we make the guard structural — a caller cannot invoke the
predicate without supplying the entry state.

### Alternatives weighed

- **Leave both sites inlined (instance fix only).** Rejected: that is what let
  #696 exist; nothing stops the next edge from drifting.
- **Also unify `break`.** Rejected as incorrect — break is an exit edge, not a
  back-edge; it has different (correct) semantics.

### What guards it / would reopen it

`tools/move_audit.w` (`with build :move-audit`) is the behavior matrix over
(edge × move-timing × shape); it proved this refactor neutral (15/15 cells) and
would catch a future re-divergence. See D6 (single-source-of-truth ABI) and
D14 (battery tiering).

---

## D14 — Verification tiering: iterate on one stage; battery gates commit batches

**Date:** 2026-07-17
**Status:** Accepted — maintainer-directed ("fix this issue deeply").
**Deciders:** Eric (BDFL)

### The decision

- **Iterate tier:** while developing, verify with `with check` and/or
  `with build :dev` (seed → stage1, ONE self-compile, ~3.5 min to a testable
  binary at `out/bootstrap/bin/with-stage1`) plus targeted test files. No
  battery per edit.
- **Commit tier:** the full battery (build, fixpoint, `audit:all`, `:test`,
  `:test-green`, `:last-green`) gates every commit batch. `audit:all` and
  `:test` may run **concurrently** — they share no outputs (audit needs
  stage2, tests need the release binary), and audit's ~6 min hides inside the
  test leg.
- **Batch rule:** independent, low-risk build-layer changes (build.w,
  build/*.w, docs, non-semantic executor changes) may share ONE battery and
  then land as separate per-change commits. Anything touching language
  semantics, codegen, ownership/drop scheduling, or ABI keeps the strict
  battery-per-change rule.
- **Fixpoint stays in the commit tier unconditionally.** The references argue
  convergence from cache keys (Go) or defer the byte-diff to release CI
  (Zig); With's per-commit byte-fixpoint is stronger and has caught real
  nondeterminism. The waste was repeating it per *edit*, not having it.

### Context / why

Measured 2026-07-17 (`out/.build-state/build-times.tsv`, first data from the
D-instrumented executor): stage1 175.9s + stage2 174.3s + link-compiler
173.0s = 77% of an 11.4-min `with build`; the full battery was ~30-40 min.
Three consecutive ~30-min batteries were spent landing three independent
build-graph changes where one batched battery carried identical evidence —
~1 h of pure ceremony in a single session. Every reference compiler tiers
verification (Rust `x build` = stage 1 by default; Zig's dev loop is one
self-compile with fixpoint in release CI only; Go primes its cache for
iteration). See `docs/build-perf-reference-study.md` for the evidence trail.

### What would reopen this

A regression that a batched battery passed but per-change batteries would
have isolated (and that bisection could not); or a recurring bug class that
`check` + stage1 misses and only stage2 exposes, making the iterate tier
untrustworthy.

---

## D13 — Commit-derived compiler versions are post-link metadata, never compiled inputs

**Date:** 2026-07-17
**Status:** Accepted — implementation tracked by #650. **Deciders:** Eric (BDFL)

### The decision

The compiler's commit-derived version is provenance metadata. It must never be
substituted into generated source, object code, or any other hashed input of the
native compiler stage/link chain. The expensive compiler build embeds a stable,
fixed-width sentinel and produces `with.unstamped`; a separate cheap `build`
action tracks `.git/HEAD`, its resolved ref, and `WITH_VERSION`, patches the
real version plus NUL into a distinct final `with` output, and fails loudly if
the slot is missing, truncated, or too small.

The stage chain depends only on the commit-independent generated main source.
Versioned bootstrap/version artifacts live behind a separate target: a target
that tracks HEAD cannot be a stage dependency even when its relevant output is
byte-identical, because the build cache deliberately invalidates a target when
any dependency rebuilt.

On macOS, patching invalidates the linker's enforced ad-hoc code signature, so
the patch action must ad-hoc re-sign the final binary after writing and chmod.
Linux and Windows do not run that signing step.

### Context / why

The cache was already content-addressed, but every commit changed
`out/gen/main.w` by substituting `v<base>-g<commit>` before compilation. That
made documentation-only commits rebuild the full self-hosted compiler. Keeping
the generated main byte-stable was necessary but not sufficient: the original
combined source-generation action still tracked HEAD, and
`build_cache_freshness_reason` treats a rebuilt dependency as stale, so stage1
would still rebuild after every commit. Separating stable and versioned source
generation removes both invalidation paths.

The version suffix does not affect compiler semantics, fixpoint identity, or
artifact correctness; it is late-bound provenance. Post-link stamping preserves
the exact user-visible version while keeping semantic build inputs truthful.

### Protection / the rule going forward

- Never restore version substitution in `out/gen/main.w` or another native
  compiler input.
- Keep the unstamped link output separate from the patched output; modifying a
  target's own cached output in place makes that target perpetually stale.
- Do not attach HEAD/version inputs, directly or through a rebuilt dependency,
  to the stage chain or `link-compiler`.
- Preserve the loud slot bounds/sentinel checks and the macOS re-sign step.

---

## D12 — `mut fn` mutates in place on every owner type; receiver MODE decides by-place semantics (primitives and str included)

**Date:** 2026-07-17
**Status:** Accepted — BDFL ruling. **Deciders:** Eric (BDFL)

### The decision

A `mut fn` receiver borrows the caller's place and mutates it in place for
**every** owner type — scalar primitives (`i32`, `u64`, `f64`, `bool`,
`char`, …), `str`, distinct/newtypes over them, and aggregates alike.
`extend i32: mut fn bump(): self += 1` works: `x.bump()` on a `var x`
mutates `x`. The lowering is a receiver-mode `PassMode::IndirectPlace`
(a pointer to the caller's slot) computed once by `compute_fn_abi` (D6) —
the same ABI aggregates already use — so no new mechanism is introduced;
the previous restriction to STRUCT/GENERIC_INST/ENUM owners was an
incompleteness, not a design.

**The governing principle: the receiver MODE decides by-place behavior, the
owner's type does not.** `i32` is `Copy`, but `mut fn` still borrows in
place, because mode wins over Copy-ness — exactly as it already does for
Copy structs. `f(x)` (by-value param) copies; `x.bump()` (`mut fn`
receiver) borrows. `move self` stays consuming/owned (not share-place);
plain `fn`/`&self` on a Copy scalar may pass by value (read-only, no
observable difference).

**Idiom:** the blessed use is domain verbs on distinct/newtypes
(`Health.damage(n)`, `Money.add(m)`), not bare `i32.bump()` — when there
is no domain meaning, prefer the operator (`x += 1`). The spec examples
lead with distinct-type domain modeling (the app-dev audience).

Rejected: **Option B** (keep rejecting `mut fn` on primitive/str owners
with an honest diagnostic + a §9.5 carve-out). B bends the spec to a
current ABI limitation — backwards from spec-leads-compiler — and denies
app devs an ergonomic the two closest references ship in their own
standard libraries.

### Context / why

`extend i32: mut fn bump(): self += 1` compiled to a callee-copy mutation
that never reached the caller; after D7 enforcement it became a loud but
MISLEADING compile error ("cannot assign to immutable variable"). Root
cause is one gate: `SemaDecl.w:1086 fn_param_uses_value_ref_abi` excludes
`str` (line 1089) and restricts IndirectPlace to aggregate owners
(line 1093), so primitive/str receivers fall through to by-value.

Reference filter (verified in .reference/ checkouts): **Swift**
`Integers.swift:327 public mutating func negate()` ships a mutating
method on a primitive in the standard library — and `extension Int {
mutating func }` is the near-exact twin of With's `extend i32: mut fn`.
**Rust** `core/num/mod.rs:720 pub const fn make_ascii_uppercase(&mut
self)` ships a `&mut self` mutating method on a primitive in `core`.
**Go** (`time.go:226 func (t *Time) stripMono()`) mutates via
pointer-receiver on a named type. Unlike D11's 3-2 split, this is
effectively unanimous that the mutation must reach the caller: every
reference that lets you attach a mutating method to a value/primitive
receiver makes it work.

Mission filter: §9.5 already promises "mut self mutates in place"
generically with no primitive carve-out — so this is spec-leads-compiler
(the spec is right, the impl was incomplete). Ergonomics-first wants
`hp.damage(30)` over `hp = Health(hp.value - 30)`. "Safe as Rust" is a
bar, not a compass — a by-place mutable receiver on a primitive is exactly as
safe (the borrow is exclusive for the call); nothing becomes silently wrong.

Builds on D6 (`FnAbi`/`PassMode` single source) and D7 (receiver-mode
keywords). It is independent of D5's now-superseded free-parameter default.
Sibling of D11 (both are
core-type surface rulings taken in-scope for v0.16.0 rather than
deferred).

### Scope / implementation

In v0.16.0 (maintainer: "do it right, now" — NOT deferred). Two shapes,
tracked as implementation issues under umbrella #644:
1. Scalar primitive owners → IndirectPlace (`i32*`-style): **#677**.
2. `str` / fat-pointer owners → IndirectPlace over the `{ptr,len}` fat
   pointer (distinct ABI shape; own drop/lifetime audit cell): **#678**.
Both gated on the `/drop-audit` matrix (value shape × control flow ×
ownership op × receiver mode) per the receiver-ABI-change rule.

### What would reopen this

A drop/lifetime cell that cannot be made sound for an exclusive by-place scalar
or fat-pointer receiver.

---

## D11 — Collection length is signed: len() -> Int (i64); no Option wrapper; C's -1 conventions stay at the binding layer

**Date:** 2026-07-17
**Status:** Accepted — BDFL ruling. **Deciders:** Eric (BDFL)

### The decision

`.len()` on every collection (Vec, HashMap, HashSet, BTreeMap, BTreeSet,
str, slices, arrays, SlotMap, VecRange) returns **`Int` (i64)**, not
`usize`. Length is never wrapped in Option. C conventions that encode
absence or failure in a size (null container pointers, `ssize_t -1`)
are translated at the modeled-C binding layer, never inherited by the
core container types. The narrowing family stays: `len32()`/`ulen32()`
panic on overflow as before; `len64()` becomes an identity alias of
`len()` and remains for compatibility.

This supersedes the §18.6 usize contract (the 28d6343c len-family
design). The BTreeMap/BTreeSet `len() -> i64` declarations, previously
a spec violation, become the conformant shape.

### Context / why

`v.len() - 1` on an empty Vec panicked with an unsigned-underflow trap
(#630) — the famous Rust `0..v.len()-1` wart, imported wholesale. The
maintainer's first design instinct (Option[usize], None = nonexistent
container) was run through the standard filter and rejected on the
mission's own clause: With's ownership + init rules make a null
container unrepresentable in safe code, so an Option wrapper forces
every call site to unwrap a case the compiler already proved impossible
— unnecessary characters by definition. Zero of five reference projects
wrap length in Option.

Reference filter (verified in .reference/ checkouts): **signed** — Go
(`builtin.go:179, func len(v Type) int`; Go's own spec prose writes
`len(a)-1`), Swift (`Array.swift:821, var count: Int`), Vale
(`str.vale:24, HashSet.vale:84 — int`). **Unsigned** — Rust
(`vec/mod.rs:2931 usize`), Zig (`array_list.zig usize`). The split
falls exactly along declared values: the ergonomics-first languages
chose signed; the explicitness-philosophy languages chose unsigned and
knowingly accepted the trap. Vale is our designated ownership
reference; Rust is the explicit ergonomics anti-reference.

Mission filter: "built to remove the suffering" (the trap is a named
suffering); "safe as Rust" is a bar, not a compass — signed lengths
clear it with zero loss (overflow and bounds stay runtime-checked; no
real machine holds 2^63 elements, so the lost bit is free); "raw C
stays explicit; modeled C becomes humane" assigns -1-as-error to the
binding layer (the with_net -errno precedent), keeping it out of the
core types. The runtime already stored lengths as i64 (with_vec.len,
with_hashmap_len) — only the sema surface said usize.

### Scope / implementation

Signed applies to the whole length/count/index-of family, so the surface
stays consistent: `len()` and the collection len methods, iterator
`count()` (a length), and `position()`'s index (`Option[Int]`). **`size`
/ `align` type-layout methods stay `usize`** — those are memory-layout
constants for FFI, a different category, deliberately excluded.

Spec-ahead-of-implementation: §18.6 now says `Int`; the sema surface
(`SemaCheck.collection_len_method_return_type`, the `count`/`position`
/`capacity` sites, and lib/std BTree decls) still says `usize` until
**#630** lands the flip (the implementation vehicle). This is the normal
spec-leads-compiler posture — **do not "fix" §18.6 back to usize to match
the compiler; the compiler is what changes.** #630 carries a self-host
flip sweep (#629 protocol: length typing threads through the compiler's
own sources) and the full battery.

### What would reopen this

A concrete C-interop boundary where translating size_t at the modeled
layer is shown to be impossible or pervasively costly, or a real
program that needs > 2^62 elements.

---

## D10 — Channel termination: recv() -> Option[T]; None means closed and drained; Receiver is for-iterable

**Date:** 2026-07-16
**Status:** Accepted — BDFL ruling. **Deciders:** Eric (BDFL)

### The decision

`Receiver.recv()` returns `Option[T]`. Buffered messages are always
delivered first (`Some`); `None` means the channel is closed AND drained —
Rust's semantics in Swift's spelling. `Receiver` is directly for-iterable:
`for msg in rx:` receives until termination and falls out with zero
ceremony (desugars through recv's Option). CHAN_RECV codegen consumes the
runtime status (previously discarded — a closed-drained recv returned an
uninitialized value).

### Context / why

Closed-and-drained is the normal termination signal of every
producer/consumer pipeline, not an error. Panic (option A) converts
routine teardown into the error machinery and taxes the most common
channel idiom with try_recv/side-channel choreography — manufactured
suffering. A Go-style zero-value sentinel (option B) is silent wrong data
— the guardrail-removal the mission forbids — and is mechanically
unavailable anyway (With has no universal default for arbitrary T).
Option C prices honesty at one `?`/unwrap, which the language's own
happy-path doctrine already declared cheap, and the compiler proves every
consumer decided what shutdown means. Reference survey: Rust
(Result::Err after drain) and Swift (AsyncStream -> nil terminates
for-await) — the two memory-safe references — chose the type-honest
signal independently; Go's sentinel needed the `, ok` form and range
special-casing to patch; Zig and Vale ship no channels. The for-iterable
Receiver is the Swift lesson: termination-as-None makes iteration simply
end, deleting the loop's residual `Some` ceremony entirely.

Known residuals, deliberately left: `try_recv` remains specified-but-
unimplemented, and its `None` will conflate "empty now" with "closed" —
needs a three-state answer or documentation when implemented. Drop-bearing
payload ownership through the for-loop binding follows the current
provisional ownership state (#608 world).

Reopen if: channels grow a select-integrated recv arm whose binding shape
conflicts with Option (spec's select examples currently show both `msg =`
and `opt_msg =` spellings — reconcile when select-over-channels lands).

---

## D9 — E0921 concurrency evidence for async fns is usage-based (call/reference sites), not declaration-based

**Date:** 2026-07-15
**Status:** Accepted

### The decision

The global-data-race proof (§9.1) treats an `async fn` as concurrency
evidence at the sites where a fiber can actually come from it — direct
calls, generic calls, method calls (plain, generic, dyn-trait), and
references that coerce the fn to a callable value — not at the bare
declaration. Async blocks/scopes, `thread.spawn_os`, `@[c_export]`, and
extern-"C" callback coercions keep their existing evidence points
(`@[c_export]` stays declaration-based: presence *is* the external-caller
hazard).

### Context / why

`check_bodies` recorded evidence for every checked non-generic async fn
declaration. When #489 added `async fn task_cancel_point` to prelude-merged
`std.task`, every ZCU — including the compiler's own stage builds and every
user program with a mutable global — failed E0921 despite never creating a
fiber (offset-proven to lib/std/task.w:27 across the stage2 stderr). The
same defect already shipped: `use std.time` alone (uncalled `async fn
sleep`) poisoned any program with a mutable global. §9.1's obligation is
"the program *uses* no async construct"; its example labels a call site
("program creates fibers here"), and it explicitly classifies precision
improvements as compiler quality work, never a semantic change.

Alternatives weighed: exempting std-implementation decls from evidence
(unsound — `std.time.sleep(d)` called from user code creates concurrency
with zero user-side async decls); making `task_cancel_point` generic or
respelling the cancel edge (dodges the imprecision, leaves the prelude
landmine armed for the next non-generic async std fn).

Coverage was verified by matrix: uncalled decls (own and std) are clean;
direct/generic/method/dyn/fn-value routes, async blocks, and instantiated
combinator internals all still fail the proof. `test/compile_errors/
err_global_*` fixtures now call their async fn so the concurrency they
assert is real. Speculative overload probes (`generic_overload_match_score`)
never run call checking, so discarded candidates record no evidence.

Reopen if: a new fiber-creation route bypasses the hooked resolution
points (e.g. async fn values become spellable through paths other than
`check_ident`'s visible-sig coercion), or the runtime gains a way to start
fibers without any call/block/scope construct.

---

## D8 — Stores through raw pointers do not drop the old pointee

**Date:** 2026-07-12
**Status:** Accepted

### The decision

Assignment through a raw-pointer deref or index (`*p = v`, `p[i] = v` with
`p: *const T` / `*mut T`) is a **raw store**: the compiler does not emit
drop-before-overwrite for the old pointee. Replacing a live pointee is the
programmer's job in unsafe code: `let old = *p; drop(old)` then store.
Safe places — `var` bindings (§2.2), `&mut` derefs, fields — keep
drop-before-overwrite. A **field** store through a raw deref
(`(*p).f = v`) also keeps it: projecting a field asserts a live pointee,
so the old field value is provably live.

### Context / why

`Box.new`, `Rc.new`, `Mutex.new/set`, `RwLock.new/write`, and the
ScopedMut write-backs all store through raw pointers into memory that is
either freshly allocated (uninitialized) or already moved out. The niche
model's justification for drop-on-reassign (§2.5.1: every source is a live
value or a blanked one) does not hold there — fresh heap bytes are neither.
The emitted guarded drop then runs `Drop` on garbage whenever the allocator
returns non-zero recycled memory: observed as `State.drop` firing at
`box_ctx` time (spec_ss16_7) and `Mutex.set`/`RwLock.write` dropping the
replaced payload twice (spec_ss14_17_*, "oldold" traces). Every raw-store
site in the stdlib/runtime was audited: none relies on the old drop
semantics; `sync.w` already drops the old value explicitly before storing.

Alternative weighed: keep Rust's rule (`*p = v` drops; add a
`ptr::write`-style no-drop primitive). Rejected: it silently invokes drop
glue on memory the compiler cannot prove initialized (UB-by-default in the
common fresh-allocation case), contradicts every existing stdlib site, and
adds a primitive the mission says the programmer shouldn't need. "Raw C
stays explicit": a raw store stores.

Reopen if: With grows an initializedness proof for raw pointees, or a
`ptr::write`/`ptr::replace` surface makes the explicit-drop idiom obsolete.

---

## D7 — Eliminate `self`: the receiver mode is a `fn` prefix keyword; `self` and its type are never written (Swift-style)

**Date:** 2026-07-07
**Status:** Accepted — BDFL ruling. Plan: `docs/eliminate-self.md`. Spec: §2.4, §9.5. **Deciders:** Eric (BDFL)

### The decision

A method's receiver is expressed by a keyword on the declaration, not by a
parameter. `self` is never declared and its type is never spelled:

- `fn m()` inside `impl`/`extend`/`type` — instance, **read borrow** (`self: &Self`)
- `mut fn m()` inside a type — instance, **by-place mutable borrow** (`mut self: Self`)
- `move fn m()` inside a type — instance, **consuming** (`move self: Self`)
- top-level `fn Type.name()` — **associated**, no receiver (no `static` keyword)

**Instance vs. associated is decided by *location*, not a keyword:** inside an
`impl`/`extend`/`type` the receiver is synthesised; at top level there is none
(a `mut`/`move` prefix at top level is an error). This is Rust/Zig/Go's
presence-of-receiver rule with `self` implicit. `self` remains an implicit
binding in instance-method bodies; the receiver's type is always the enclosing
type. Implemented as a **parser desugar** to the existing (verified-working)
receiver-param shapes, so sema/MIR/codegen are unchanged.

**Trait declarations are the carve-out (part of the same ruling):** a trait
body must express both instance contracts and associated contracts
(`Default.default`, `Try.from_break`), and location cannot discriminate inside
the block. So in a `trait` body only the unambiguous keyword forms synthesise
(`mut fn` / `move fn`); a plain `fn` keeps today's explicit spelling — with a
receiver parameter it is an instance contract, without one it is associated.
Trait authoring is library-maintainer tier, so the residual ceremony lands on
the right audience. The end state for `lib/std/traits.w` is therefore: keyword
forms for mut/move/destructor contracts (`move fn drop()` is the only Drop
receiver, §2.4), explicit `self: &Self` on read instance contracts, plain
no-receiver `fn` for associated contracts. Do not re-open this by flipping
trait plain-`fn` to implicit-instance; that makes associated contracts
unspellable.

### Context / why

The mission's first law — *"every unnecessary character is a compiler failure;
if With can infer it, the programmer should not have to spell it out"* — applies
directly: a receiver's type is **always** the owner type, so `: Self` is pure
ceremony, and the mode is one bit that belongs on the declaration, not smeared
across a `self` parameter. The prior form `fn m(mut self: Self)` forced the user
to write the value (`self`), its mode, and its (inferable) type.

This ruling also **dissolves** four open issues instead of patching them: #646
(unflagged `self: ConcreteType` escapes the mode check — no annotation to
escape), #645 part 2 (`mut` discarded on a param — `mut` now only prefixes
`fn`), #644 (mut-self on a primitive owner — mode is uniform, type inferred),
and the bare-`mut self` codegen failure (bare receiver forms cease to exist at
the surface).

### Alternatives weighed

- **Keep `mut self: Self` (status quo).** Rejected: maximal ceremony; the spec
  even called it "canonical," contradicting the mission's first law. The clause
  is superseded here.
- **Bare `mut self` (drop only `: Self`, Rust shorthand).** Rejected as the
  end-state: still writes `self`. Eric's ruling: if `self` can be avoided, avoid
  it. (Bare `mut self` is nonetheless the internal desugar target's cousin — the
  desugar emits `mut self: Self` with a literal `Self` node.)
- **Swift `mutating`/`consuming` spelling.** Rejected the *words*: we reuse
  existing `mut`/`move` keywords (fewer characters, Rust-adjacent, no new
  reserved words).

### Reference consensus

Swift is the model: `SelfAccessKind` (`include/swift/AST/Decl.h:262` —
`NonMutating`/`Mutating`/`Consuming`/`Borrowing`) is a **decl** property and
`self` is a compiler-synthesised `getImplicitSelfDecl()`. `mutating ⇒ inout
self` (OwnershipManifesto) is verbatim With's by-place receiver mode (D12). Swift threads a
persisted `SelfAccessKind`; we take a cheaper route (parser desugar to shapes
sema already handles). Rust's `&self`/`&mut self`/`self` shorthand and Swift's
implicit `self` both confirm "no receiver type annotation" as the ergonomic
norm; Go/Zig write the receiver type and are explicitly the more-ceremony pole
we reject.

### What would reopen it

Evidence that implicit `self` cannot express a needed method shape (verified by
running, not reasoning), or that the location discriminator (inside a type vs.
top level) creates an ambiguity the desugar cannot resolve. Supersedes the §2.4
"canonical receiver is `move self: Self`" wording (now `move fn drop()`).

---

## D6 — `FnAbi` is the single ABI source of truth: compute once, both sides read it, never re-derive per call path

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

## D5 — Historical SHARE-PLACE free-parameter design — SUPERSEDED

**Date:** 2026-07-05
**Status:** Superseded. The current BDFL ruling is specification §3.8:
`&T` borrows and plain `T` consumes; the signature states the mode.
**Historical design:** `docs/completed/mutability.md` · **Deciders:** Eric (BDFL)

### Supersession

Free-function SHARE-PLACE is retired. A read-only or view-producing parameter
is declared `&T`; a plain `T` is owned by the callee and is consumed without a
redundant call-site `move` annotation. Body-inferred effects remain analysis
facts, but they do not reinterpret a declared ownership mode or silently move
destructor timing between scopes. Auto-ref preserves the ergonomic call surface:
callers write `peek(x)` for `peek(x: &T)` and `take(x)` for `take(x: T)`.

This supersession does **not** change receiver modes. `mut fn` still mutates its
receiver place in place, `move fn` consumes it, and D21 pipeline place-threading
remains current. `PassMode::IndirectPlace` remains an ABI mechanism for
compiler-modeled borrowed places such as in-place receivers, never a
source-level default for plain `T`; explicit `&T` has the ABI of its reference
value.

### Historical record — not current doctrine

D5 previously made a plain non-`Copy` free parameter an inferred shared-place
alias. The caller retained ownership, body effects selected borrowing versus
transfer, and the design sought Python-shaped mutation without call-site
reference syntax. That was an accepted design at the time and explains legacy
effect summaries, `SHARE-PLACE` diagnostics, tests, and ABI comments.

That design is now void for free parameters. No instruction, protection,
restoration task, or “canonical” claim from the former D5 text remains active.
Do not restore it from history. The only retained lesson is provenance: source
ownership must follow the current declared signature, while receiver modes and
view-origin analysis continue under their own current rulings.

---

## D4 — #602: `retains:` c_import contract, enforced check-time via cstr_in modeling

**Date:** 2026-07-05
**Status:** Accepted
**Issue:** #602 · **Spec:** §16.3c · **Deciders:** Eric (BDFL)

### Decision

A c_import param can be annotated `retains: ["fn(idx)"]` — the callee keeps the
passed C-string pointer past the call. Such a param is a **modeled** C-string
input (`cstr_in`: callable without `unsafe`, a pointer into caller-owned storage
is accepted), but a call-scoped `str` temporary is **rejected** at check time
with guidance to pass `to_cstring()?.as_cstr().ptr()`. Params are borrowed by
default; only `retains:` marks retention.

### Why this shape (the "unreachable" detour)

A first pass built the store + enforcement but found it *unreachable*: the
`str→*const c_char` coercion only fires for `cstr_in`-modeled functions, and
`cstr_in` modeling came exclusively from the hardcoded `ci_overlay_cstr_in_param_count`
list — all borrowed, none retaining, not user-extensible. The fix was NOT to
defer but to make the finding the design: **`retains:` itself is the cstr_in
evidence.** A retained `const char*` param becomes a modeled cstr_in param (so
`ci_function_requires_raw_abi` no longer marks it raw) whose retention is
enforced at the coercion site (SemaCheck) — rejecting the `str`, accepting an
owned pointer. This makes the whole feature reachable and testable with pure
user code, no dependency on a real retaining libc function.

### Reasoning

- **Go cgo** documents a pointer-retention contract and enforces it dynamically
  under `cgocheck`; **We** enforce it statically at the coercion boundary
  (compile-time, zero runtime cost) with the `dbg_scribble` debug allocator as
  optional runtime teeth. Adopted the contract-with-teeth idea; rejected Rust's
  docs-only unsafe (no guardrail) and Zig's fully-manual approach.
- Mission "modeled C becomes humane, with guardrails": the annotated surface
  stays zero-ceremony for the borrowed common case; the guardrail appears only
  when a param actually retains.

### Consequences

- Sema `retained_extern_params` (name_sym → retained-param bitmask), populated by
  a reader over c_import `retains:` records.
- `ci_function_requires_raw_abi` treats a retained const-c-string param as a
  modeled cstr_in param.
- Enforcement at the SemaCheck c-char coercion site.
- The curated overlay is the `retains:` clause itself (user-extensible); a real
  retaining libc function can be seeded there if one is identified.

---

## D3 — Friendly aliases are shadowable; `Unit`/`Never` stay reserved (split of option D)

**Date:** 2026-07-05
**Status:** Accepted
**Issue:** #627 (substrate) · **Spec:** §4.1, §29.8 · **Deciders:** Eric (BDFL)

### Decision

The friendly convenience aliases `Int`, `UInt`, `String`, `StrView`, `CStr`
become prelude-scoped, user-shadowable names: a `type` declaration of the same
name in a user module wins over the builtin alias. The core primitives
(`i8`…`u128`, `f32`/`f64`, `bool`, `str`, `usize`, `isize`) **and** `Unit` and
`Never` stay compiler-reserved (not shadowable).

The original option-D ruling (2026-07-04) demoted all seven friendly names
*including* `Unit`/`Never`. Scoping revealed `Unit` has ~331 uses across the
compiler sources (`Never` ~15) — it is a core type in every `-> Unit`
signature, not a convenience alias — and `Unit`/`Never` are not cleanly
spellable as an alias RHS (no `()`/`!` type syntax). Demoting them is a
high self-host-flip-risk change out of proportion to any benefit, so they are
excluded. Eric ruled for the split.

### Implementation note

Shadowing was already *almost* free: `register_prim` records these names as
empty-path (prelude-tier) entries, and `lookup_named_type_visible` returns a
visible user declaration before the empty-path fallback. The only thing forcing
the builtin was four resolution-first hardcodes in `primitive_type_by_sym`
(SemaDecl.w) for `Int`/`UInt`/`String`/`StrView` — dead when unshadowed (the
named-types path returns first), fired only to override a user shadow. Removing
those four lines enables shadowing with zero self-host impact (the compiler
never shadows these; unshadowed resolution is byte-identical). `CStr` was
already a plain named struct, not resolution-first. This also unblocked the
`StrView`-collision that obstructed probing #625/#626.

### Reasoning

Matches Go's universe-block predeclared identifiers and Rust's prelude — both
shadowable — while keeping the truly foundational names reserved (Zig-style)
where user override would be a footgun with no upside. "Don't make the user
write ceremony / don't block a safe user choice" (mission) argues for
shadowable conveniences; "never risk the self-host build for a cosmetic win"
argues for keeping `Unit`/`Never` reserved.

---

## D2 — #625: containers of ephemerals use a viral-ESCAPE model, not an annotation ban

**Date:** 2026-07-04
**Status:** Accepted (supersedes the "ban outright" framing of the D-day
soundness ruling and the §5.2 narrowing in commit 6f9160e3)
**Issue:** #625 · **Spec:** §5.1, §5.2 · **Deciders:** Eric (BDFL), informed by
reference-implementation review

### Decision

A heap container whose element type is ephemeral (`Vec[View]`, `Box[View]`,
`HashMap[K, View]`, …) is **itself ephemeral** and is **allowed** as a local or
a by-value parameter. What is rejected is the **escape**: returning it where the
return type is not ephemeral, storing it in a heap container or a non-ephemeral
struct field, or boxing it. This is enforced by **borrow-origin tracking** —
storing an element into a container propagates the element's stack view-origins
onto the container binding, so the existing ephemeral-escape checks fire on a
later return/store — **not** by banning the container type at its annotation.

### Context / how we got here

The first implementation (this cycle) followed the literal "ban outright"
ruling: reject an ephemeral element type at every annotation, push, and literal
site. It built and fixpointed, but broke two capability tests because the stdlib
itself uses `parallel(workspaces: Vec[Workspace])` (build.w:627) — the *only*
container-of-ephemeral in the whole stdlib.

Investigating that failure surfaced three facts that reframed the ruling:

1. **`ephemeral` is used here overwhelmingly as a linearity/capability marker,
   not a borrow marker.** All 28 ephemeral stdlib types (every iterator, lock
   guard, `Workspace`, `Context`, task/join handles) have all-owned or
   raw-pointer fields; none has a `&`/slice field.
2. **The compiler cannot structurally tell a dangling ephemeral from a safe
   one.** `StrView = ephemeral { ptr: *const u8, len }` (the exact freed-memory
   type in #625) and `Workspace = ephemeral { token: str, id }` are structurally
   identical — both raw-pointer/owned fields. A refinement that banned only
   `&`/slice-containing types would let the actual bug type slip through
   (verified).
3. **`str` is owned** (spec §), so `Workspace{token: str}` carries no live stack
   view-origin. The origin-tracking machinery therefore *already* distinguishes
   `Vec[Workspace]` (no origin → safe to return) from `Vec[View]` (borrows
   `&local` → escape caught) — the distinction is "does the value carry a live
   stack view-origin," exactly Rust's lifetime model.

### Alternatives weighed

- **A — viral-escape (chosen).** Allow the container; catch the escape via
  origin tracking. Fixes the `return Vec[StrView]` freed-memory bug; keeps
  `parallel(Vec[Workspace])` working; needs origin propagation through
  container stores (the bounded new work).
- **B — blanket annotation ban (the first impl).** Simplest, strictest. Bans
  memory-*safe* batching; forces refactoring `parallel()` and forbids any future
  batch API of linear handles. Rejected: bans safe code and reads as "safe by
  ceremony," which the mission forbids.
- **C — blanket ban + opt-in `@[storable]`.** Adds a type-author attribute to
  exempt safe markers. Rejected: leaks the borrow-vs-linear distinction into a
  type author's vocabulary for no safety gain.

### Reasoning

- **Reference review was unanimous** (Eric asked for it before ruling). Every
  reference language that *has* the concept allows the container and controls
  the escape, none bans the annotation:
  - **Rust:** `Vec<&str>` / `Vec<&[&str]>` are normal types (in the stdlib
    docs); the lifetime parameter bounds the container and the errors are all
    escape errors (E0515 return-ref-to-local, E0521 borrow-escapes, E0716
    temp-dropped-while-borrowed). This *is* the viral-escape model.
  - **Vale** (our ownership design compass): containers of region refs are
    allowed; **regions** (static) + **generational references** (runtime)
    control escape — never an annotation ban.
  - **Zig:** `ArrayList(*T)` allowed; dangling is UB, the programmer's job.
  - **Go:** GC + escape analysis; no borrow concept — n/a.
- **Mission fit.** "Exactly as safe as Rust" is a *bar*; here we can meet it with
  Rust's *own* model. Banning `Vec[Workspace]` — which is memory-safe — is
  "ceremony for something that doesn't matter," which the mission explicitly
  forbids. Vale, the design compass, points the same way.
- **The issue author's own suggested model was escape-based** ("locals fine,
  stores rejected, returns propagate"), not annotation-based.

### Consequences

- §5.2 restored to full virality ("any generic `F[T]` is ephemeral"), enforced
  at the escape rather than the annotation — reverting the 6f9160e3 narrowing.
- Origin tracking extended: a container store (`push`/`insert` on a local)
  unions the element's view-origins onto the container binding
  (`add_binding_view_deps`); container literals recurse their elements in
  `collect_expr_view_deps`.
- `Vec[Workspace]` and friends compile; `return`/store/box of a container that
  borrows a stack local is a compile error.
- The "safe by construction beats viral tracking" note added to §5.2 in
  6f9160e3 is withdrawn: the reference review showed viral tracking is the
  standard and the construction ban was unsound-adjacent (false negatives on
  raw-pointer ephemerals, false positives on owned-field markers).

---
