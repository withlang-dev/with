# D32 — STRICT field moves: implicit is an error everywhere; explicit `move place.field` through a mutable path is the one vacate

**Laws:** 5, 7 (docs/mission.md).

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
