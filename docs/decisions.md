# Decision Log

Architecture/design decisions and *why* we made them. Newest first. Each entry
records the decision, the context, the alternatives weighed, and the reasoning —
so a future maintainer (or agent) does not re-litigate a settled call, and can
tell whether a later fact should reopen it.

Format per entry: a short ID + title, date, status, and the reasoning. When a
decision supersedes an earlier one, say so in both.

---

## D68 — Float display follows C general formatting

**Date:** 2026-09-25. **Status:** BDFL ruling (Eric: "we need to match what C
does", resolving #1649's default-display question).

Default float display follows C `printf("%g")`: six significant digits,
notation chosen from the rounded exponent, and fractional trailing zeros
removed. Explicit `g` precision has C's significant-digit meaning, including
zero precision meaning one. This supersedes #1649's proposed shortest
round-trip default; correctly rounded literal parsing remains required.
Formatting remains locale-independent as With text requires.

The reference is C's general-conversion rule, including its rounding-dependent
notation choice: [WG14 DR 233](https://open-std.org/JTC1/SC22/WG14/issues/c99/issue0233.html).
Tests compare against the host C formatter as well as fixed boundary cases.

Credit: the correctly rounded literal parsing and the exact `:e` digits came
from Josh Hickson's #1649, which landed on main through #1683's squash
(a5c6f430) without his authorship; `docs/float-c-format-audit.md` records it.

---

## D67 — `with uat`: acceptance scenarios are a toolchain feature every project has; `with init` scaffolds one

**Date:** 2026-09-25. **Status:** BDFL ruling (Eric: "blessed" on the §18.5
line, the §18.8 `with init` row and §18.5d, after "make sure it's written
in a way that users can use too … `with init` should set up their project
with an example UAT"). Plan: `docs/uat-plan.md`.

**Decision.** Acceptance scenarios are plain-text files a person writes
with a fixed set of verbs (`new directory`, `run:`, `write … from …`,
`stdin:`, `env`, `expect …`), one per scenario under `uat/`, run by
`with uat` with three verdicts — pass, skip with the reason (`requires:`
unmet), fail — and `expect (human):` lines that are recorded and reported,
never executed. Programs a scenario writes into the project are ordinary
source files under `uat/fixtures/`. `with init` writes `uat/hello.uat` and
`uat/README.md`. The compiler's own release UATs (`build/release_uat.w`,
nine hand-coded actions) migrate onto it and the build layer keeps no
scenario logic.

**Why.** A UAT is a promise a person can read — what a user does and sees
— and the existing harness had only the mechanism: scenarios existed as
call sequences inside the build system, coverage was not enumerable,
preconditions (no OpenGL on the macOS runner, #1375) read as failures, and
the human expectation ("colored balls moving on a field of black") had no
home. Eric's own phrasing of a hand-written UAT is a list of verbs and
nouns; that list is the notation. Gherkin's Given/When/Then is ceremony the
mission dislikes; a step-definition API is deferred (the verbs are the
runner's, like `with test`'s). Making it a toolchain feature rather than a
repo harness is the same call as `with test`: the language ships the way
its programs are checked.

---

## D66 — Discriminated variadic contracts; borrowed record views from a resource or domain; `static` stays the strongest case

**Date:** 2026-09-25. **Status:** BDFL ruling (Eric, on the libcurl brief:
"(a) yes, existing law; (b) yes, with tighter semantics; (c) not `returns
static Record` as proposed"). §16.2b.5 "Discriminated variadic contracts"
and §16.2b.6 "Borrowed record views" carry the text.

**Decision.** (a) `curl_easy_init`/`cleanup` is a resource (`from`/`drop`);
no ruling. (b) A variadic C function stays variadic to the backend ABI —
never a fixed-arity redeclaration (on Apple arm64 variadic arguments go on
the stack; a fake prototype links and is wrong) — but a facade may model a
closed set of typed call shapes selected by an earlier compile-time-known
discriminator; each listed case states the presented type *and contract*
(a `long`, a copied `str`, a callback with its userdata pairing, a retained
pointer where curl documents "not copied", …), so the compiler can lower the
real variadic argument. Three rules: compile-time-known selector; a listed
case renders a safe presented call; unlisted or runtime selectors are
refused on the safe surface and the raw function stays available. This is
not "variadics are safe now": they stay raw unless the facade closes the
type hole for that discriminator. (c) Not `returns static Record`.
`curl_version_info` returns a pointer to a static struct that libcurl may
alter until `curl_global_init`, so "static address" is not "immutable
forever". The existing `returns borrow CStr from domain D` generalizes to
`returns borrow T from domain D` / `from param N` for any imported record:
a view with a real origin, no `Drop`, no lie about immutability. The
ladder: pointer with an owner → borrow from the resource; pointer into
global state → borrow from the domain; genuinely immortal immutable data →
`static`, the strongest case and never the default. A pointer field inside
a borrowed record is not modeled by the outer lifetime (pointer spelling
never establishes string semantics — the D51 rule everywhere else);
field-level facade evidence (`record … field version CStr from self`
-shaped) is a later ruling; the UAT reads a scalar field and gets
printable text from `curl_version()` under `returns static CStr`.

**Why.** All four of this week's facade extensions are one principle:
buffer clauses model relationships among fixed C parameters; fixed clauses
model hidden constant parameters; variadic cases model the relationship
between a discriminator and a vararg; borrowed record views model foreign
pointers whose lifetime comes from a resource or domain. The C ABI gives
the representation; the facade supplies the semantic relationship C's type
spelling cannot express. Rust/Zig/Mojo users hand-write per-option typed
wrappers over one variadic declaration; Go and Swift need C shims. Only
Rust (`&'static`) and Mojo (origins) can type the version record's
lifetime; With's domain origin says more (what may change it, and when).

**2026-09-25 amendment — explicit callback type (#1652).** Eric approved
`case CURLOPT_WRITEFUNCTION: callback param 2 as curl_write_callback userdata param CURLOPT_WRITEDATA`.
The `as` type supplies the C signature missing from the variadic header;
the userdata selector supplies the pairing across calls. Neither is inferred
from an option name. This closes the type hole in the original example
without changing D51's callback lifetime or retention requirements.

**2026-09-25 amendment — callback invocation and partial setup (#1652).**
Eric approved `callbacks none` as D51 §47's trusted assertion of a verified
foreign-library guarantee, never a warning suppression. Track callback/userdata
compatibility on the resource through defaults, replacements, and setter
failures. Refuse operations that could invoke an incomplete pair; separate-call
setup also requires that callbacks cannot run concurrently between the calls.
There is no blanket scope-exit ban: check the actual destroy path, including
early returns and `?`, for the callbacks it can invoke. A facade must provide
a modeled safe reset, unregister, or destruction path for abandoning partial
setup. Required acceptance case: first setter succeeds, second setter fails,
function returns an error, and cleanup safely releases retained state exactly
once. `curl_easy_cleanup` cannot be annotated unconditionally `callbacks none`:
it can invoke configured progress/header callbacks
([libcurl documentation](https://curl.se/libcurl/c/curl_easy_cleanup.html)).

---

## D65 — One authoritative producer per semantic fact: Sema decides what, MIR decides where and when, codegen decides how; no stage re-derives another's answer

**Date:** 2026-09-25. **Status:** architecture decision (Eric, endorsing the
boundary proposal with the amendments below; "adopt it"). Executable half:
`with analyze audit:resolution` (#1647). Rule text also in CLAUDE.md /
AGENTS.md ("One owner per fact").

**Decision.** Every semantic fact has exactly one authoritative producer:

- **Sema:** resolved declaration, resolved type, place/value/view category,
  view origin, operation effect (read / borrow / mutate / consume / escape /
  invalidate / preserve), closure capture semantics (mode, access,
  environment storage, call kind), call target and specialization, and
  whether the source program is accepted.
- **MIR:** the CFG, local storage and temporaries, path-sensitive
  initialization and move state, the exact drop points and cleanup edges.
- **ABI / codegen:** physical layout, direct/indirect passing (`PassMode`,
  D6), calling convention, the concrete LLVM representation.

Downstream stages may *propagate, materialize and verify* a fact; they may
not *reconstruct or override* it from syntax or representation. Forbidden
upward inferences, by name: LLVM type → semantic category or passing mode;
MIR local-table lookup → the meaning of a name; AST spelling → resolved
callee after Sema. **Authority vs verification:** MIR may find that Sema's
constraints cannot be realized consistently across the CFG (a consume on a
path where the place may already be moved); it reports the contradiction —
a program Sema wrongly accepted, or a lowering inconsistency — and never
invents a different semantic answer. After Sema succeeds, invalid MIR is a
compiler bug by default, and the validators are assertions between stages.

**Why.** Two weeks of Sema-vs-MIR-vs-codegen friction were the same
defect in different clothes: two layers independently deciding one fact.
#1635: Sema had resolved `let r = c.run` as a view binding; MirLower's
ident-callee dispatch asked its own `lookup_local`, got -1, and inferred a
function *named* `r` — a `GENERIC_CALL` with the argument dropped, which
killed the native build runner; three fixes in the wrong place changed
nothing because the re-derivation lived elsewhere. The `&fn` marshalling
crash: codegen decided "the value is already a pointer" from the LLVM type
and passed a bare function's code pointer where the callee expected the
address of a pair — the FnAbi rule (D6) already forbids per-path ABI
derivation; this generalizes it to every semantic question. D62/D63's
closure semantics were implemented as special cases in `lower_callable_expr`
and codegen's `spawn_os` path instead of one Sema-emitted
`{environment: Owned|Borrowed, call_kind}` record, which is where #1605 and
#1635 came from. Two validators stayed silent over exactly these MIRs
(#1639, the `audit:contract` `ok` over a refused program) because nobody had
said invalid post-Sema MIR is the compiler's fault.

**Amendments over the proposal.** (1) Ownership is path-sensitive, so Sema
legitimately reasons about control flow (let-else moves, loop-carried
captures); the rule is not "Sema never sees the CFG" but "Sema states
constraints per operation, MIR propagates state, and neither re-derives the
other's answer." (2) No new IR: the semantic tables already exist
(`typed_expr_types`, `resolved_call_sigs`, `expr_view_param_origins`, effect
summaries, `binding_closure_nodes`, the facade contract tables); the gap is
MirLower's ~150 AST-first / own-scope-first lookups, so this is a discipline
campaign plus an audit, not a representation change. (3) Enforce
mechanically now, not "socially first": `audit:resolution` joins Sema and
MIR/codegen facts per node the way `audit:calls`/`audit:mir` do, red on a
callee, place, effect or passing mode that disagrees with its producer.

**Smell test for reviewers.** If deleting or changing a downstream
heuristic could change the meaning of an already-successful Sema result,
the boundary is wrong. Changing MIR's drop-state representation or the
closure environment's physical shape must never change which programs are
accepted.

**Sequencing.** Decision now; every new change obeys it; every bug fixed
from now on moves its answer to the owner rather than adding a second
derivation; `audit:resolution` lands incrementally (callees, then codegen
mode provenance, then places, then effects); the wide MirLower cleanup is
deferred until after STC (`docs/stdlib_sourcing_plan.md` phase 3) —
architecture work must not displace what users feel first.

---

## D64 — Facade buffer pairing (`buffer param P len|capacity param L [inout]`) and fixed arguments (`param N fixed <literal>`)

**Date:** 2026-09-24. **Status:** BDFL ruling (Eric: "Yes to buffer pairing.
Yes to fixed/hidden facade arguments. But don't conflate those approvals
with caller-visible slice-length mutation."). §16.2b.8 "Buffers" and
§16.2b.11 "Fixed arguments" carry the text. Resolves #1621 and #1624.

**Decision.** The meaning was already ruled by §16.3c (safe coercion at a
`c_import` boundary only when the binding models the full contract —
length or capacity, copy-back — with `write(fd, data)` as its example);
what was missing was the normative spelling by which facade source proves
that two C parameters participate in that contract. Since guessing the
pairing could manufacture an out-of-bounds call, that spelling is safety
syntax, not parser plumbing, so it needed a ruling. Three tightenings over
the first draft: (1) zlib's `destLen` is **in/out** (capacity on entry,
produced length on exit), so the clause says `capacity … inout`, leaving
room for genuinely output-only lengths; (2) the caller's `[]mut u8` is
**not** modified — a `[]mut T` parameter is an exclusive borrow whose
caller binding survives unchanged, and an FFI call rewriting the caller's
fat-pointer descriptor would be a new With semantic, not modeling of C;
the bridge computes `capacity = dest.len`, calls C with `&capacity`,
bounds-checks the written value against the original capacity, and
returns it as `usize` (a narrowed view `[]mut u8` borrowing from `dest`
may come later); (3) the length **counts bytes** and renders `[]u8` — the
same syntax is not generalized to `T * + size_t` until it is decided
whether the integer means bytes, elements, code units or structs.
Copy-back validity after failure is the status contract's call (§16.2b.4):
the value is presented only on success. A raw pointer parameter no clause
pairs is not a buffer, and `lend`/presentation on such a function is
refused (the hole #1625 found: a bare `lend` on `compress` rendered a
safe call with no bounds contract).

**Fixed arguments.** `param N fixed <literal>` binds a C parameter to a
literal and removes it from the presented signature; the raw operation
stays available. Eric rejected `default`: it reads as an optional argument
callers may override (`prepare(sql, other)`), whereas the fact is "this
facade binds this C parameter to this literal". Between his two spellings
(`param N fixed …`, `bind param N = …`) the first was chosen: it sits in
the existing `param N …` clause family.

**What the others do.** No language declares the pairing in a binding:
Rust (`as_ptr()/len()` in `unsafe`, `improper_ctypes` forbids slices in
`extern`), Go (`&b[0]` + `C.size_t(len(b))`), Zig (`s.ptr, s.len`), Mojo
(`unsafe_ptr(), len(s)`) all split by hand; Swift alone generates a
buffer-taking wrapper, and only from a Clang `__counted_by` annotation
behind an experimental flag, with no out-length support; Vale passes its
own arrays and cannot call a `(T*, n)` API without a C shim. With's
answer is §16.3c's evidence model: an explicit clause is evidence of the
same standing as a header annotation.

**2026-09-25 amendment — explicit element counts (#1643).** Eric approved
the explicit `elements` qualifier: `buffer param P len param L elements`
and `buffer param P capacity param L inout elements`. These render typed
`[]T` and `[]mut T` using the C pointer's element type. The compiler checks
conversion of the slice count to the C count type before the call and checks
a copied-back count against the original element capacity before returning
it as `usize`. The caller's slice remains unchanged and copy-back is still
presented only under the status contract. Unqualified clauses continue to
count bytes; pointer types and names never select the unit. This replaces
the original decision's restriction against element slices, not its explicit
pairing or bounds requirements. Swift's checked-in `SwiftifyImport`
`CountedBy/NamedParams.swift` and `SizedBy/SimpleRawSpan.swift` likewise
distinguish element count from byte count and use exact integer conversion.

---

## D63 — One callable type: `fn(A) -> R` carries compiler-tracked environment ownership; not `Copy`

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric: "Rule (A) … environment
ownership is one more such property"). §12.4 "The callable type" carries the
text. Resolves the type question D62 left open (#1567).

**Decision.** A function, a non-`move` closure and a `move ||` closure all
have type `fn(A) -> R`; the compiler tracks which, as it tracks
`may_suspend` (§14). A non-`move` closure is ephemeral; a `move ||` closure
owns its environment (inline when every capture is `Copy`, otherwise a heap
cell owned by the value, freed on drop with captured `Drop` values
destroyed then) so a struct holding one has `Drop`; a consuming closure is
call-once. Four consequences written down so they are not improvised:
(1) `fn(A) -> R` is not `Copy`, bare functions included — `Copy` is a
property of the type, not of a value's provenance, or generic code cannot
reason about it; `.clone()` is free for bare/view callables and needs every
capture `Clone` for owned ones; calls through a binding or field do not
move; the use-after-move diagnostic suggests `.clone()` or calling through
the original. (2) Call-once crosses a signature: a consuming closure may
only go to a callee that invokes it at most once — proven from the body in
one compilation; across a bundle boundary the default is "any number of
times" and the closure is rejected until a `once` parameter annotation
exists (deferred; same cross-bundle shape as `-> &T` in §3.4). (3) Views
flow like `&T` parameters: a non-`move` closure argument is ephemeral in
the callee (Rule 8) — callable, passable, not storable/returnable/capturable
by a `move ||` closure; this closes §13.1's erasure hole. (4) Performance
is an optimizer commitment: a call through the pair is indirect unless the
compiler specializes, and it does when a closure literal reaches a
parameter within one compilation (Swift's devirtualization); only a
captureless closure coerces to an `extern "C"` pointer.

**Alternative rejected.** (B) A second spelling for owned closures
(`Closure[A, R]`, `own fn`, or a trait — Rust's shape with one trait
instead of three). It puts in the user's hands a distinction the compiler
learned from `move ||` two tokens earlier, and splits every higher-order
API table in the spec. Rust monomorphizes each closure as its own type;
Swift and Go have the one thick/fat type and pay with refcount/GC; With
keeps the one type and proves the environment's lifetime instead.

**Surprise to expect.** Rust makes fn pointers `Copy`; here `let g = f`
moves `f`. The §11/§13 callback examples (`f: fn(StrView)` parameters)
already conform; no spec example holds a callable in a struct field.

---

## D62 — Closure captures are by place regardless of `Copy`; `move ||` closures own their environment

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric, on #1586 and #1567:
"Copy captures are by place, always. Not only when the body writes" and
"`move ||` closures own their environment"). §12.4 carries the text.

**Decision.** A capture is by place whether or not the type is `Copy`; a
read through a capture of a `Copy` value copies it; `move ||` transfers
ownership, which for a `Copy` value is a copy. Captures are one of three
views of the place — read, mutate, consume — and a consuming capture makes
the closure callable once, leaving the place owned by its scope if never
called. A `move ||` closure is an ordinary value that owns its environment
(inline when every capture is `Copy`, otherwise a heap cell owned by the
closure value, freed when the closure drops, captured `Drop` values
destroyed then — never the caller's frame); it may be returned, stored, or
sent when every capture is `Send`. A non-`move` closure stays a view of its
frame and may not be returned; the diagnostic's fix-it is `move ||`.

**Why "always" and not "when the body writes".** A capture mode that flips
on the body means adding one `+= 1` inside a closure silently changes how
the outer variable is held, and the error appears at an unrelated site
(the caller's later use of `n`) — the same body-dependent hazard as origin
inference in §3.4, with nothing bought for it. One rule is simpler to
state and check, and it is what Go, Swift and Rust do (Rust borrows `Copy`
captures too; only `move` copies). The behavior that changes: mutating `n`
while a read-only closure over `n` is alive was allowed under by-copy (the
closure saw a stale value) and is now an exclusivity error — the correct
outcome; the snapshot is spelled `move ||`, which now says exactly that.
This retires the "assignment to a `Copy` capture" diagnostic proposed
under #1486 before it ever reached main: `count += 1` in a closure is what
the user meant.

**Why `move` closures own their environment.** The spec's own example
(`let h = move || owned.len()` — "owned is invalid after closure creation")
only makes sense if the closure took `owned` somewhere that outlives the
frame; putting a `move` environment in the caller's frame was the #1567
wrong code. Vale and Rust both give a moved closure an owned environment.

**Not decided here.** The type of a returned closure: `fn(i32) -> i32`
carries no environment, so whether the spelling is `impl Fn`-style, a
named `Closure[...]`, or a trait — and with it whether closures can be
trait objects — is its own brief before code.

---

## D61 — Debug (`:?`) is recursive, quoted and escaped; an explicit `impl Debug` is honored at every depth; maps print sorted

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric: option (a), "bless the
second as written, with one addition" — sort map keys — and the derive
question decided by the existing "Available for all types"). §15.4.7 and
§11.9 carry the text.

**Decision.** Every struct field, enum payload and collection element is
formatted with `:?`, so a value formats the same at every depth. A `str` is
quoted and escaped (`\"`, `\\`, C0 controls and DEL as `\n` `\t` `\r` `\0`
`\xHH`); printable non-ASCII appears as itself, so `"café"` reads `"café"`.
A type with an explicit `impl Debug` formats through its `debug_str` at top
level and nested alike; every other type uses the generated form. `:?`
needs no derive; `@[derive(Debug)]` provides the trait for `T: Debug`
bounds. `HashMap` entries print ordered by the Debug text of their keys;
`BTreeMap` in key order.

**Why.** Before this, `P { name: "x, y" }` printed `P { name: x, y }`,
`V("x, y")` and `W("x", "y")` printed identically, the top-level string
`q"t` printed `"q"t"`, and `Vec`/`HashMap` printed the placeholder
`<unsupported>` — a live no-silent-fallback violation. Rust's derived Debug
and Swift's `debugPrint` both format nested values in debug form; Go's `%v`
does not, and its `%#v` does. §11.9 said `:?` "does not dispatch through"
the Debug trait, which under recursion would make formatting depth-dependent;
it now honors an explicit impl everywhere. Maps sort because Debug is for
humans and diffs: a seeded hash order would make every snapshot of a map
flaky and break byte-identical fixpoint wherever a map is debug-printed
during self-hosting. Keys sort by their Debug text because a `HashMap` key
need not be `Ord`.

**Not decided here.** With has no `char` type (`'a'` is a `u8`), so there is
no `char` row and no `\'` escape; a character type is its own ruling.

---

## D60 — A tail assignment under a declared non-`Unit` return yields a read of its place; the implicit default applies only to a `Unit` tail

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric: option (a), with the
§4.10 narrowing and a wording change to §9.1; "blessed"). §9.1 and §4.10
carry the blessed text.

**Decision.** In `fn inc -> i32: g += 1`, the body yields a read of `g`
after the store, under the ordinary copy and move rules. §4.10's implicit
`T.default()` applies only when the tail's own type is `Unit`; a tail of any
other type must match the declared return type or is a type error.

**These are a pair.** Option (a) alone is the "returns 6" convenience
without the guard. The narrowing is what turns the next regression of this
shape into an error instead of a silent zero: #1319 (merged 2026-09-22
without a ruling) made a body-tail assignment discarded, and §4.10 then
substituted `T.default()`, so `inc()` returned 0 instead of 6 and `set()`
0 instead of 9 with no diagnostic. That change was a defect.

**Why "a read of `place`", not "the value just stored".** The latter
implies a second copy exists after the store: free for `i32`, a hidden
clone or an unstated move for `str`. The existing move rules already decide
it: `fn inc -> i32: g += 1` returns 6 because `i32` is `Copy`;
`fn f -> str: g += 1` is a type error; `fn f -> str: name = compute()`
with a global `name` is a move-out-of-global error, not a silent clone.

**What the others do.** Rust (`check_expr_assign` returns `()`), Swift
(assignment is `()`) and Zig (assignment is a statement) reject the
function; Go has no assignment expressions. With's assignment already has
the type of its place (§9.1), so their answer does not transfer.

**Reopens if** a tail read of a place proves to surprise more than it
helps.

---

## D59 — `ok` projects a producer to `Result[R, RError]`; the generated error owns a failed-but-produced resource

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric: 1(a), 2(A), 3 yes,
4 yes, with the refinements below; spec wording "blessed"); §16.2b.4 carries
the blessed text. Ruling §15–§19 (D51) left the projection's surface open:
"A high-level `Result` API is therefore a projection over the lower-level
production model. A facade-specific error type may itself temporarily own
the failure-state resource where required."

**Decision.** A producer with `ok CONST` returns `Result[R, RError]`, `RError`
a generated `error` declaration with `Failed(status)`,
`FailedWithResource(status, resource: R)` and `NothingProduced(status)`.
In-place producers get the same projection without `FailedWithResource`.
The low-level `(status, Option[R])` constructor exists only without `ok`.

**Why.**
- **Success with nothing produced** (SQLite's `sqlite3_prepare_v2` on empty
  SQL) is a violated C contract, so it is an error. It gets its own variant:
  `Failed(status: SQLITE_OK)` reads as a contradiction in a log line.
  `Result[Option[R], E]` would tax every caller for a case most producers
  cannot hit.
- **An `error` declaration, not a struct and not a named clause**, because
  D57 already gives errors their composition (`error AppError from
  DatabaseError`), and a clause makes the author write what is derivable.
- **The first error type with a destructor.** `FailedWithResource` owns the
  handle (SQLite requires closing a failed open), so the error has Drop, and
  `?` moves that ownership up through frames, never copies it.
- **The failed-state resource admits raw access only**, until the facade can
  mark operations valid on the failure state: `sqlite3_errmsg` is,
  `sqlite3_exec` meaningfully is not. The conservative default can be
  widened later.
- **In-place with `ok`** applies §16.2b.3's own rule ("Drop is armed only
  when initialization establishes production") to the failed branch. It
  closes a real hole: the destroyer ran on storage `z_init` never
  initialized. With pinning (D54), the failed branch frees the heap cell
  with no destruction call: the one such case.
- **One call surface per production form.** Libraries whose success codes
  are several constants (`SQLITE_OK`, `SQLITE_ROW`, `SQLITE_DONE`) are an
  argument for letting `ok` take a list, not for keeping the raw form.
- **The generated name collides loudly.** A declared or imported type with
  the generated name is an error naming both, the type-level form of D57's
  variant-collision rule.

**What the others do.** Rust std's `cvt_nz` maps 0 to `Ok` and carries the
code, never a handle. Swift's `swift_error(null_result)` covers only NSError
out-parameters. Go returns both values. Zig's error unions carry no payload.
None lets a "failed but produced" error own the resource; that part is With's
own (ruling §18).

**Naming.** The constructor is rendered under the imported C name
(`Database.sqlite3_open`) until presentation (§16.2b.11, plan stage 8)
shortens it (`Database.open`). Examples quoting the C name are not the final
spelling.

**Amended 2026-09-23** (Eric: "blessed"), from implementing it (#1426):
- **The failed resource is a distinct type, `FailedDatabase`, with no
  presented methods.** With `resource: Database`, a `match` moved the handle
  out as an ordinary `Database` with every method, so "raw access only"
  could not be enforced. The distinct type still owns the handle and runs
  the facade's `drop` once.
- **An in-place `ok` error has only `Failed`.** A successful in-place
  initialization always produced the resource, so `NothingProduced` could
  never occur there and every caller would have had to match it.

**Reopens if** a facade needs operations on the failure-state resource
(the marking clause), or `ok` needs several success constants.

---

## D58 — The `else` of `let ... else` takes a body or a same-line diverging expression

**Date:** 2026-09-22. **Status:** BDFL ruling (Eric: "b", then "blessed,
same-line only. if they want next line they MUST use colon."); §9.7,
§29.13 and §30.4 carry the blessed text.

**Decision.** `let PATTERN = EXPR else` is followed either by a body in any
of the three §29.13 forms (`else: stmt`, `else:` + indented block,
`else { ... }`) or by a single diverging expression on the same line
(`else return Err(.NotFound)`). Anything on the next line needs the colon:
`else` + newline + an indented block with no introducer is a parse error.
`VAR_STMT` takes a `PATTERN` like `LET_STMT` (it said `IDENT`, contradicting
§9.7's "all pattern forms are available in `let`/`var`"), and both take the
optional `LET_ELSE`.

**Why.** Eric: "I know purists will poo poo this. but this is
*quintessential* to With. We do right by the USER." The one-line guard —
bind or bail — is the most common let-else there is; making the programmer
type a colon there buys grammar uniformity, not a caught mistake.

**Context.** §9.7 wrote `else return …` with no colon while §29.13 required `:`
or `{` after every `else`; the grammar had no let-else at all. The
same-line bare expression is the shortest spelling of the common case
(Zig's `x orelse return err` is the precedent, `grammar.peg:334`); Rust
(`parse_block()` after `else`, `rustc_parse/src/parser/stmt.rs:406`) and
Swift (`guard … else` needs braces, `ParseStmt.cpp:2075`) require a block.
Allowing the bare form only on the same line keeps the no-introducer shape
an error everywhere else in the language: let-else is the single, visible
exception, and a multi-line branch looks like every other body.

**Alternatives.** (a) One form, `else` + BODY only (§9.7's examples would
gain a colon). (c) A bare expression only — rejected, it cannot express a
multi-statement branch. A next-line bare expression was offered and
refused: "if they want next line they MUST use colon."

**Reopens if** the same-line form proves to hide a real mistake the colon
would catch.

---

## D57 — An error type may both wrap other errors and declare its own variants

**Date:** 2026-09-22. **Status:** BDFL ruling (Eric); §10.9 carries the
blessed sentence.

**Decision.** `error E from A, B =` followed by variants joins §10.8 and
§10.9: the listed types get generated wrapper variants and `From`
conversions (so `?` converts), and the written variants are the type's own.
A written variant whose name equals a generated wrapper's name is a
compile-time error — the compiler never picks between two meanings.

**Why.** Before this, a type could either convert automatically or have
its own variants; a service error with both (`Validation`, `TimedOut`,
`Cancelled` beside wrapped `DbError`/`CacheError`) had to convert by hand
at every call site. Joining the two existing forms is the smallest change
and generates exactly what one meaning forces (mission.md). Zig merges an
own error set with others (`A || B`) the same way, without payloads; Rust
leaves it to hand-written `impl From` or the external `thiserror`.

**Held (option C).** A user-implementable `From` trait, for conversions
that are not plain wrapping (e.g. mapping one variant onto another), waits
until a real program needs one. `From` is not a user-writable trait today.

**Reopens if** such a program appears.

---

## D56 — CI is not a merge signal; the seed-driven battery on the maintainer machine is

**Date:** 2026-09-22. **Status:** ruled by Eric ("we either reduce it to 20
minutes or we ignore it as any kind of signal. You decide."); the choice
below is the agent's, from the measurements.

**Decision.** Pull requests are gated by the seed-driven battery
(`WITH=$PWD/src/main src/main build`, `:fixpoint`, `:test`, `:test-green`,
`:last-green`, plus `:move-audit`/`:drop-audit` for ownership changes) run on
the maintainer machine and posted on the PR; a PR is a draft until that
battery is green and is marked ready when it is. The GitHub lanes are not
run on pull requests or pushes at all; they run nightly and on manual
dispatch, as post-hoc evidence (Eric, 2026-09-22: CI was overzealous in
what it did on every push). The SDK is built only on release
(`sdk-release.yml`, dispatched against an existing release tag), never on
a push (Eric, 2026-09-22). No lane is a required status check.

**Why.** A lane cannot be a real-time signal: on the last green macOS run
the source-SDK build took 105 min, the compiler build 29 min, fixpoint 34
min and the battery 71 min — about four hours; even without the SDK build,
build+fixpoint+battery is ~2 h on a 4-core runner (the laptop is ~10×
faster; its battery is ~25 min). A signal that arrives two hours after the
decision is noise, and a lane that skips the battery to fit 20 minutes is
not a signal. Running lanes on every PR push therefore bought nothing and
cost runner time and false reds.

**What it costs.** A PR merged before its battery has finished puts an
unverified tree on main; the maintainer accepts that and it is cleaned up
afterwards (2026-09-22: #1301 merged early, `behav_fn_abi_async` red on
main, fixed forward). The draft/ready convention is the mitigation.

**Reopens if** runners get ~10× faster, or a lane can run the real
battery in ≤20 minutes.

---

## D55 — Six rulings of 2026-09-22: destructors are skipped only at the type's boundary; facade destroyers; examples track the spec; `Sender` is `Clone`; `print` over `Display`

**Date:** 2026-09-22. **Status:** BDFL rulings (Eric); spec sentences in
§2.5.1, §9.7, §14.15, §16.2b.3, §18.2; examples policy in CLAUDE.md/AGENTS.md.

1. **`void *` destroyer (facade §61).** "Accepts the representation" is C's
   own conversion rule: `void *` accepts every object-pointer
   representation, never a function pointer (they do not convert to
   `void *` in standard C) nor a by-value representation. It can only accept
   or reject a program that already has a destruction path; it never grants
   ownership.
2. **`destroys` without `drop`.** Compile error at the resource; the facade
   author names the unary destroyer as `drop` — one word. **Higher RAII**
   (a must-consume linear resource, for destroyers that take arguments) is
   the right long-term answer and is a *named future ruling*: it touches
   `match`, early return, panic unwinding and fibers, and nobody
   half-implements it in the interim.
3. **Destructuring a `Drop` value (#1272).** The Swift/Mojo shape: a
   struct/enum pattern on a `Drop` value is an error everywhere except
   inside the type's own `move fn` methods, where it is the visible disarm
   and must be **total** (every field bound or `_`; partial patterns leave
   fates unstated, which Swift's "cannot partially consume" exists to kill).
   One rule for `let`, `match`, `if let`. Rulings 2 and 3 are corollaries
   of one §2.5.1 sentence: the only way to skip a destructor is a spelling
   visible at the type's own boundary.
4. **Examples track the current spec.** "Examples are contracts" and "the
   spec moved" cannot both hold; a spec change that breaks an example
   updates the example in the same change; a compiler/stdlib change that
   does is a defect. `pub(package)` (97 errors in one example is a signal)
   is a separate argument, to be brought with data on how many `pub` marks
   the fixed examples needed.
5. **`Sender[T]` is `Clone`, never `Copy`** (semantic copies are spelled),
   retaining the runtime refcount; the channel closes when the last sender
   drops; `Sender[T]: Send` requires `T: Send`.
6. **`print[T: Display](v: &T)`** as a plain generic (the `&str` case a
   monomorphized instance); the `match` arms join under the `Display` bound
   where the checker already joins arms, not as a new demanded-argument
   feature; a mixed-arm match yields nothing joinable and the fix-it is
   `print(f"{x}")` — the idiom people should learn anyway. The reference
   fizzbuzz is the mixed-arm form and is updated under ruling 4.
## D54 — In-place foreign resources are pinned by default; `movable` is the facade's claim; a heap cell, never an immovable type

**Date:** 2026-09-22. **Status:** BDFL ruling (Eric); spec §16.2b.3 carries
the normative sentences. Extends D51; the D51 ruling document is not
amended (it is silent on address stability).

**Decision.** An in-place resource (a by-value C representation with
`init`) is pinned: the representation has one address from the creation of
the resource value until foreign destruction completes. The facade may
declare it `movable` only on trusted evidence that no operation retains the
representation's address — the same evidence weight as `ok`, never
inferred. The renderer implements pinning as a heap cell owned by the
resource value: the value stays an ordinary movable With value; every
`self` pointer handed to C points into the cell; on drop the destruction
operation runs first and the cell is freed after (the cell outlives the C
state, never the reverse); the zeroed/`preinit` states apply to the cell's
contents, and the cell exists from the construction of the resource value,
so an "allocated, not live" resource already has its stable address (zlib's
`inflateInit` keeps the address it is called with); raw and borrowed access
yields a pointer into the cell, valid for the borrow regardless of moves of
the value — a rule the checker enforces, not only the renderer. Pinning
covers the representation's own storage only: `z_stream.next_in`/`next_out`
point at user buffers, a dependency question (§16.2b.6), not an
address-stability one.

**Why pinned by default.** The compiler cannot infer whether `init` stores a
back-pointer, so the facade states it either way, and the costs are
asymmetric: a needlessly pinned resource costs one heap allocation; a
needlessly movable one is silent memory corruption after the first move. The
needs-pinning class is larger than zlib — `pthread_mutex_t` and
`pthread_cond_t` are UB to move after init per POSIX, `sqlite3_vfs`, libuv's
`uv_*_t` watchers keep loop and list pointers, some OpenSSL contexts — while
the movable class (hash contexts, stat buffers, `struct tm`) is mostly plain
data that is not a resource at all. "Never half-model unsafely" is met when
the unstated default is the safe one.

**Why a heap cell and not an immovable type.** "Constructed in its final
place and cannot be moved" would add an immovable type category to the
language; Rust's `Pin` took years and remains its most misunderstood API,
and With's pitch is one kind of value. One allocation per stream is what
`flate2` pays; zero-allocation placement (arena, struct field) can come
later as an optimization invisible to users, because the semantics are
already "address stable".

**Reopens if** a measured hot path needs placement without an allocation —
that is the invisible optimization above, not a change of rule.

---

## D53 — wasm32 is a freestanding target whose "libc" is the With runtime over WASI preview1, with an emitted JS host

**Date:** 2026-09-19. **Status:** implemented on the `wasm-target` branch
(fork); not yet a BDFL ruling. Design note: `docs/wasm-target.md`.

**Decision.** `--target=wasm32` compiles a pure-With program to a
WebAssembly module whose only imports are WASI preview1 system calls, plus
a generated `<prog>.js` host that serves them under node (real filesystem,
argv, env, stdio) or in a browser (in-memory filesystem, console). No
wasi-libc, no emscripten musl: `rt/wasm.w` implements the same `rt_*`
platform contract the Linux/Darwin/Windows backends implement over libc,
and additionally owns what a libc would (startup/exit, the page allocator
behind `rt_mmap` on `memory.grow`, `malloc`/`free`/`memcmp`, and
compiler-rt's `__multi3`). Pointer width is a target property
(`target_spec_ptr_bytes`, 4 on wasm32) read by `TypeLayout`. A `wasm64`
kind is reserved but refused until its runtime exists.

**Why WASI as the import ABI.** With's runtime is not libc-shaped, so
emscripten's patched musl has nothing to attach to; the platform contract
is already a thin syscall layer, and WASI preview1 is the one syscall ABI
every wasm host (wasmtime, node's `wasi`, browsers via a shim) speaks. The
emitted JS host is exactly what emscripten's JS runtime is: the userspace
that implements those imports. Using WASI names rather than a private
`env.*` set costs one attribute (`@[import_module]`, clang's
`import_module`) and buys every standalone host for free.

**Why no async.** WebAssembly has no stack switching; the fiber core is
context-switch assembly plus guard-page signal handling. A wasm program
links `fiber_stubs.o`; one that really spawns fails at wasm-ld with the
core-only symbols undefined. Stack switching (JSPI or the wasm
stack-switching proposal) reopens this.

**What it exposed.** wasm verifies call signatures, so two native
"works by luck" inconsistencies became hard failures and were fixed for
every target: `-> Unit` lowered to an `i32` result while an absent return
type lowered to `void` (ABI v5: a Unit result is always `void`), and the
HashMap runtime helpers were declared with a placeholder prototype. The
wasm link now runs with `--fatal-warnings` so this class cannot recur
silently.

**Alternatives weighed.** wasm64 first (keeps 8-byte pointers, avoids the
pointer-width audit) — rejected as the primary: browsers only recently
ship memory64 and every WASI host assumes wasm32; the pointer-width work
was small once `TypeLayout` was the single place. A private `env.*`
import set — rejected: it would make the module runnable only under the
emitted host. Silently linking the fiber stubs and trapping at spawn —
rejected: the link fails loudly instead.

**Reopens if:** a stack-switching primitive lands in engines With cares
about (async on wasm); the runtime retirement (D30) moves the platform
layer in-unit (then `rt/wasm.w` compiles like the embedded stdlib and the
cross-object directory goes away).

---

## D52 — A global is never moved out of; a `const` is a value, not a place

**Date:** 2026-09-21. **Status:** ruled — the §9.1c sentence below was
blessed verbatim the same day ("blessed") and landed (#1245); the compiler
enforces it (#1242).

**Decision.** Consuming a module global — binding it by value
(`let out = g`), passing it to a plain-`T` parameter, returning it (tail or
`return`), or calling a `move self` method on it — is a compile error when
its type needs drop: "cannot move out of global `g`: a global always holds a
value; clone it (`.clone()`) instead". Reading, viewing (`g.get(0)`,
`let v = g.field` as a D27 alias), mutating in place and reassigning stay
legal. A `const` is exempt: it desugars to a comptime value and every use
materializes it, so `return SOME_CONST` transfers nothing.

**Context.** `let out = g; g = Vec.new(); out` double-freed
(`debug-alloc: DOUBLE FREE ... origin=Vec`). MIR showed why: inside a
function the global read lowered as `_1 = copy _2` — a byte copy of a
non-Copy value with no blanking — so the reassignment's `drop(_2)` and the
returned value freed one buffer (§2.3: transport never produces a second
live value). In `main` the same spelling lowered as `move` plus
`_1 = const zst`, a blanked global that every other function still sees as
holding a value. And the checker's MOVED mark on a global is not
per-function: after `fn f(): let s = g`, every later body reported
"use of moved value" for `g`.

**Alternatives.** (a) Per-global drop flags: runtime state for a property
that cannot be decided statically across functions, and it would legalize
a global that is empty from some other function's point of view. (b) Blank
on move: the same empty-global hole, silently. (c) Treat `let x = g` as a
D27 alias of the global place: consistent with `let v = g.field`, but a
spec change (the ident form moves everywhere else) and it does nothing for
the argument, return and `move self` spellings. (d) Reject: the only
option under which "a global always holds a value" is true in every
function, and the fix-it is the one the programmer means (`.clone()`).

**§9.1c (blessed).** "A global always holds
a value: it is observed, mutated in place, or reassigned, never moved out
of; an owned copy is spelled `.clone()`. A `const` is a value, not a
place — each use materializes it."

**Reopens if** globals gain a statically tracked vacancy (a `global var`
of `Option[T]` already expresses "sometimes empty" without one).

---

## D51 — Modeled C: ownership, effects, conventions and foreign lifetimes live in a checked facade; one canonical ruling

**Date:** 2026-09-20. **Status:** ruled; specification projections blessed
the same day ("Canonized into law") and landed as §16.2b plus the
replacements in §16.2a, §16.3c, §15.3, §16.3d, §18.5 and §18.8
(`docs/modeled-c-spec-projection-draft.md` records the projection and its
traceability). The complete, controlling text is
`docs/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md`
(Eric's ruling, 69 sections). As with D22, that file is canonical: this entry
is a pointer, the specification carries conforming projections, and
`docs/modeled-c-implementation-plan.md` is a derivative execution plan that
cannot amend it. Any document, comment, test, TODO or behavior that conflicts
with it is non-conforming.

**Context.** `examples/c-interop` had been cut down to hand-written externs
(e0ce209b) and then rewritten as a Rust-style wrapper module with `unsafe` in
it; `:user-programs-safe` flagged it and Eric ruled that this is exactly what
the gate exists to prevent. The compiler marks a c_imported function raw on
type spelling alone (`SemaDecl.w` ~735-765), §16.2a's auto-methods construct
handles safely with no `Drop` (a leak), and the #357 owning wrapper emits its
constructor as `unsafe fn`. The brief that preceded the ruling, with the
reference-language evidence (all seven `.reference/` trees, cited) and a
survey of real headers, is `docs/completed/modeled-c-decision-brief.md`.

**The ruling, in its own governing sentences.**
> With uses the strongest reliable evidence available, including conventions
> where doing so is safe and useful.

> A convention may be inferred silently when being wrong can only remove
> capability or reject a valid program. A convention that can create memory
> unsafety must be explicit, strongly established, or deliberately trusted.

> Heuristics may suggest; they do not decide safety-critical semantics.

> With proves what it can, trusts what the facade asserts, exploits safe
> conventions where appropriate, refuses what none of those justify, and
> never pretends one category is another.

> A restrictive interpretation is the absence of a proof, not a choice between
> program meanings.

**Shape.** Semantic facts about C (ownership, destruction, consumption,
retention, dependency, independence, status, preservation, nullability,
callbacks, threads, presentation) live in a `c facade name:` block of ordinary
With syntax after `use c_import(...)`. The core abstraction is the *resource*
(opaque pointer, in-place struct, by-value token), never Copy, owning a
foreign representation with a designated `drop` and any alternate
`destroys`. Evidence precedence: explicit facade clause → explicitly adopted,
versioned convention profile → conservative default; ABI/header facts
constrain all; every fact carries provenance that `with analyze` and
diagnostics expose. Unknown independence is dependency; unknown preservation
invalidates; unknown status stays uninterpreted; no `0 == success` rule;
out-parameter production is NULL-initialize-then-inspect; a failed status may
still produce ownership. Strings are `Option[&CStr]` with explicit
`to_str()` / `to_str_lossy()` / `to_owned()`; no `char *` becomes `str`
silently. Foreign-state domains (`errno`) give ownerless C storage an origin.
Resources are creator-thread-bound; `send` requires `drop_any_thread` in v1.
Facades and profiles are versioned packages, never compiler tables.

**Supersedes / narrows.** D4's `retains:` attribute is subsumed by the
facade's `retains … by …` clause (one retention system). §16.2a's "proven
ownership cleanup" paragraph is replaced: name heuristics may shape
presentation only. §16.3c's evidence-source list is replaced by the ruling's
precedence; "package-supplied binding metadata" is a facade package, which
does not revive the per-package compiler tables D46 rejected.

**Non-compliance.** Every existing safe C auto-constructor without a
complete destruction contract (§65) reverts to raw or becomes fully modeled.
The compiler is non-compliant until the facade language is implemented.

**Ordering (§66).** The SQLite facade is written first, against the real
header, and must compile before any example, release UAT, blog sample or
documentation example is rewritten against the new surface: validation
artifacts test the rule, they do not define it.

**Reopen if** a facade-asserted contract class turns out to be unverifiable
in a way that makes safe application code unsound in practice, or a convention
profile is found to need compiler-owned knowledge to work.

---

## D50 — The build keys work on what it is made from: content of inputs and the producing tool, never a commit, a checkout or the build driver

**Date:** 2026-09-20. **Status:** ruled (Eric: "our entire build process is absolutely addicted to re-doing things it's already done"; after the survey and the reference comparison, "correct. please implement it").

**Context.** A survey of one battery (build 274 s, fixpoint 107 s, test 836 s) and the cache code found the redo had one shape: identity standing in for content. `:fixpoint` recompiled what `build` had just compiled; every action's key carried the orchestrating binary; the compiler named its checkout in DWARF, in module link-name hashes and in the linker's debug map, so nothing built in one worktree was usable in another; green evidence named a commit (D49).

**What the others do** (verified in `.reference/`). Go: action ID = content of inputs + the ID of the tool that produces the output; dependents hash a dependency's *content* ID, so a byte-identical rebuild stops there; `-trimpath` always; one per-user cache; test results cached on the binary plus what the test read. Zig: content digests + compiler version; byte-for-byte stage3/stage4 in CI release scripts only; manifests store prefix-relative paths. Rust: "uplifts" a later stage from artifacts an earlier one built (`compile.rs:1089`); `omit-git-hash` on by default for dev ("can cause a lot of rebuilds"); `remap-debuginfo`; `download-rustc = if-unchanged`. Scala 3: two compiles, API-hash early cutoff, `-sourceroot`. Bazel (Mojo's tree): content digests, hermetic, shared disk and remote caches. Vale: `sbt clean` and `rm -rf` every build — the counter-example.

**Decisions.**
1. `:fixpoint` compares the unit digests of the two compiles the build already does (`stage2`; `link-compiler`, which is a stage3). No extra compile, and the whole compiler: the old objects were `--emit-obj` module objects holding main.w alone. (#1224)
2. An action that names its compiler keys on the seed `WITH` names, not on the orchestrator; a workspace compile keeps the driver, which is its producer. The state records each signature component so a stale reason names what changed. (#1225)
3. `WITH_FILE_PREFIX_MAP=<from>=<to>` (clang's `-ffile-prefix-map`): the mapped root is what enters the DWARF compile unit, the module link-name hash and, with `-oso_prefix`, the debug map. The compiler's own build maps its root to `/with-src`. One commit built in two worktrees gives a byte-identical release compiler. Debuggers map back: `settings set target.source-map /with-src <checkout>`.

**Still to do, in order:** a per-user content-addressed artifact store (a known tree's compiler is fetched, not built: Rust's `if-unchanged`); early cutoff on a dependency's output content (Go's content ID); no commit stamp in dev builds (stamp at install/package); cacheable test lanes (Zig: a run step is cached unless it declares side effects). Withdrawn: a finer-than-whole-compiler test fingerprint — Rust's compiletest and Go both invalidate every test when the compiler changes.

**Reopen if** two builds of one identity are found to behave differently; fix the nondeterminism, do not re-key on identity.

---

## D49 — Green evidence is keyed on what was tested: git tree, pinned seed, host

*Amended 2026-09-20 (D50 applied):* the identity keys on the battery's
inputs, not the whole tree — `git ls-tree HEAD` without the `docs` entry and
without top-level `*.md`, as the object name `git hash-object` gives that
listing. A docs-only commit produced a tree with no green and `:install-user`
refused a compiler whose sources had passed; Eric: "best fix this
immediately". `GreenEvidence.w` and `build/retention.w` apply one rule;
`behav_green_identity_keys_on_inputs.w` pins it.

*Amended 2026-09-21:* the first amendment kept three docs files in the
identity because lanes read them (the specification, `with-abi.sha256`,
`with_for_ai.md`); a spec-only merge (#1245) then left main with no green
and forced a full battery. Eric: "build measures software not documents."
No file under `docs/` is an input; the lanes that read one still run on a
docs-only change (spec-inventory-check) and record nothing.

**Date:** 2026-09-20. **Status:** ruled (Eric: "it is moronic that we are testing what we already tested"; "proceed").

**Context.** #1222's battery passed in a staging worktree. It was squash-merged; main's tree was byte-identical to the tested head (`git diff` empty). `:install-user` still required a second full battery on main, 25 minutes, because `last-green` and the driver's install gate accept only the exact compiler binary that was tested (`compiler_sha256`), and the binary names its commit (`v0.15.2.1-g<hash>`, a post-link stamp) and, through debug info, its worktree. A squash-merge or another checkout of the same sources is a "different" compiler.

**Decision.** What a battery tests is its inputs. `:last-green` records the source identity — `git rev-parse HEAD^{tree}`, the digest of the pinned seed that drove and seeded the chain, and the host — and publishes it to a store every worktree reads (`$WITH_GREEN_DIR`, else `~/.local/with-green/green.tsv`). `require-last-green` and the driver's `:install-user` gate accept a compiler when either the local manifest names that binary (unchanged) or the worktree is clean, its stage chain was seeded by a compiler `seed.lock` pins, and its source identity has a published green. After a squash-merge of a tested branch the reseed is `git pull`, `build`, `:install-user`.

**What it trusts.** Same tree, same seed, same host: same compiler behavior. `:fixpoint` and the seed-driven battery already enforce that determinism. A dirty worktree has no identity (untracked paths under `examples/` excepted: a user's own programs are not build inputs), so uncommitted edits never borrow a green; any tree change, one byte, is a new identity.

**Alternatives weighed.** Stamping the binary with the tree hash, or keying on the unstamped binary: both still differ across worktrees (debug paths). Keeping the branch worktree until install: relies on a person not cleaning up, and did not survive its first day.

**Not done here.** The test cache is still keyed on the stamped compiler (`0 cached, N ran` after a merge); it needs no re-run for the reseed any more, but a developer who wants `:test` on main after a merge still pays for it.

**Reopen if** a nondeterminism is found that makes two builds of one identity behave differently; fix that, do not re-key on the binary.

---

## D48 — The specification does not catalogue `lib/std`

**Date:** 2026-09-20. **Status:** ruled (Eric: "I do not want the language
spec to care what we do in lib/std"). §18.6's Module Map table and the
`std.internal` paragraph removed; the `spec-inventory-check` stdlib arm
retired.

**Context.** Adding `std.zip` failed `spec-inventory-check`, which required
every top-level module under `lib/std` to have a row in the spec's Module Map.
That put Eric's exact-wording sign-off on every library addition.

**What the others do.** Go's spec names two packages, `main` and `unsafe`,
both compiler-known. Zig's langref uses `std` in examples and catalogues
none of it. Swift keeps the standard library in its own documents. Rust's
Reference disclaims the standard library (from memory; its tree is not
checked out in `.reference/`).

**Reasoning.** A specification says what programs mean; a module list says
what ships. The table was a second source of truth, so it drifted and needed
a gate. What stays normative is the library surface the language itself
depends on, each in its own section: the prelude, `Option`/`Result` and
`?`/`??`, the traits behind syntax (`Iter`, `Try`, `Drop`, `IndexGet`,
`IndexPlace`, `Contains`), what literals and comprehensions build, the regex
literal engine, and the collection ownership doctrine (D22, D27, D44). The
test: would a program's meaning change if this changed?

**Reopen if** a library module becomes something syntax depends on; it then
gets its own normative section, not a table row.

---

## D47 — Lending is not receiving: a `c_import`ed `const char *` parameter accepts a `str`; an application developer never writes `unsafe`

**Date:** 2026-09-20. **Status:** ruled (Eric: "there is no way this should
have to be declared unsafe. This flies in the face of the mission"; "no UAT
code should have `unsafe` in it … if 'normal' users are using unsafe - WE
forced them into a situation they shouldn't be in"). §16.3c sentence blessed
2026-09-20. Narrows #379 (a88df01a).

**Context.** 1e53f8aa (2026-06-11) modeled every `const char *` parameter of
a c_imported function as a string input; the raylib spiral on Eric's blog
dates from then. a88df01a (2026-06-17, #379) replaced that with a curated
libc overlay: outside the list, a string parameter made the function the raw
surface. That broke the spiral release UAT, which sat broken until
bd9683f0 (2026-09-07) rewrote the fixture to
`unsafe { InitWindow(900, 600, c"...".ptr) }` to go green, without Eric's
knowledge. By 2026-09-19 every release UAT fixture said `unsafe` (30 uses).

**Reasoning.** #379's rule is sound for the direction it was written for:
With never reads or frees C memory on a guess (`strlen` on an arbitrary
`char *`, ownership of a return). It was applied to the other direction,
where nothing is guessed: With hands C a valid NUL-terminated buffer it owns.
The header forces one meaning for a `str` argument to a `const char *`
parameter (mission: "forced … by a header"); c_import is the modeling step,
not raw C. The one hazard in lending is a callee that keeps the pointer,
which no spelling by the programmer resolves, so it is the compiler's: a
literal is static and cannot dangle; any other `str` goes through call-scoped
storage that stays readable, so a retaining callee reads stale text, never
freed memory. `retains:` remains the way to hand a keeping callee an owned
copy. A hand-written `extern fn` with raw pointers is still raw C.

**Alternatives weighed.** Assume non-retention (Swift's rule): a wrong guess
is a silent use-after-free. Per-library contract data: the per-package upkeep
Eric rejected for `with get` (D46). Inference from parameter names: unsound.
Proof from C source when `with get` built it: a later refinement.

**Process rules this produced** (CLAUDE.md): a UAT fixture, an example or
published code is a contract — a change that breaks one stops and goes to
Eric, and the program is never edited to pass; `with build
:user-programs-safe` fails on `unsafe` in those programs.

**Reopen if** a lent-string hazard appears that readable storage does not
cover.

---

## D46 — `with get` builds a C package from source from the recipe read as data; no per-package files; `with cc` is clang inside the binary

**Date:** 2026-09-19. **Status:** ruled (Eric: "with get must build c when
there's no binary for the package"; "we cant be writing special case code
for every conan package"; prerequisites "we need to expose them to the
user … user will need to take care of it"; "OpenSSL can't be a UAT").
Specification §18.5 and §18.8 blessed 2026-09-19. Implemented in #1208.

**Context.** Conan Center publishes no Linux armv8 binaries at all (zlib,
bzip2, sqlite3, openssl, libcurl, raylib checked 2026-09-18), so every
`with get c.X` on linux-aarch64 failed. The old fallback compiled every `.c`
in the tarball with the system `cc` and gave up on any recipe with patches or
a configure step — zlib already — and could not be locked.

**Decision.**
- *Compiler:* clang's driver is linked into `with` (`with cc`), as Zig does;
  the toolchain never trusts a system compiler. `clang_main` lives in the
  clang tool's own objects, archived into the SDK as `libclangMain`; one plain
  extern is aliased to the mangled name per linker. An SDK published before
  this links a stand-in and the compiler says it has no C compiler; a platform
  gains `with cc` when its SDK is republished.
- *Build knowledge:* the package's own CMake build, driven by `cmake` and
  `ninja` with `with cc`. What is package-specific comes from the recipe Conan
  Center already publishes, **read as data and never executed**: archive,
  digest, patches, requirements, and `tc.variables`, evaluated against the
  option defaults and the host under the `if`s that hold.
- *Prerequisites* (`cmake`, `ninja`, Perl for OpenSSL, …) are named and the
  build stops; installing them is the programmer's step. A release UAT may not
  require one, so OpenSSL is not a UAT.

**Rejected.** Per-package port files (written, then deleted the same night:
"special case code for every conan package"). Executing `conanfile.py`
(needs Python and Conan). pkg-config / system packages (apt ceremony, no
Windows story). Hosting our own binaries as the primary answer (moves the
gap). Detecting the stand-in by comparing function addresses (LLVM folds two
distinct function symbols to "not equal"; the stand-in was called).

**What would reopen it.** A class of popular packages whose recipes cannot
be read as data (logic the evaluator cannot follow), or Conan Center
publishing binaries for every platform With targets.

---

## D45 — A copy is never implicit unless it is O(1); an allocating copy is spelled

**Date:** 2026-09-19. **Status:** ruled (Eric: "unless copy is O(1) we
should[n't] even consider doing it by default"; "yes for now option A … that
lands regardless of what happens to str later"). Specification §13.6's
examples do not yet conform (they build owning collections of `str` from
views without a clone); the wording is Eric's to bless. Measurement that
could reopen this: #1211.

**Question.** `let words: HashSet[str] = [w for w in tokens]` — `tokens` is
observed (D44), so `w` is a `&str`. Does the comprehension clone it? Mission
¶2 argues yes (the target type forces exactly one meaning). The same question
covers `let s: str = w` and passing a view to a consuming parameter.

**Ruling.** An owned-value demand on a view `&T` materializes a `T` only when
`T: Copy` (D22). For a type whose copy allocates, the programmer writes
`.clone()`. A comprehension's element, key and value positions are
owned-value demands like any other; they get no exception. A view of a Copy
type stored by a comprehension materializes (it stored `&i32` before); a view
of a Drop-class value is an error that says to clone it.

**Why.** Meaning is one gate; cost visibility is the other ("close to the
machine"). Verified in `.reference/`: of go, mojo, rust, scala3, swift, Vale
and zig, none copies a string implicitly while paying an allocation for it.
Every implicit-copy language made the copy O(1) first — Mojo (refcount, COW,
small strings inline), Swift (ARC retain, skipped for small and immortal
strings), Vale (`str` is always a shared type), Go and Scala (shared immutable
bytes). Rust, whose `String::clone` allocates, spells it. Mojo 0.25.6 drew
this exact line: `Copyable` became explicit (`.copy()`), `ImplicitlyCopyable`
opt-in; `List`, `Dict` and `Set` lost implicit copy because theirs allocates,
`String` kept it because its copy is a refcount bump. With's `str` is an owned
`(ptr, len)` buffer and §15.2 already marks `&str → str` as "(allocates)".
Cloning silently would have made With the only one of the eight that hides a
per-element allocation.

**Rejected.** Implicit clone in a typed comprehension only (a second rule for
one position, and the same hidden cost). A separate cheap string type in the
library (the default type, the one in every example, still needs the clone).

**What would reopen it.** `str` becoming O(1) to copy — immutable shared bytes,
a refcount in the allocation header, immortal literals (#1211 measures whether
that pays, including deleting the per-free `rt_payload_start_is_owned`
lookup). Then D22 extends by one line, and the string clones this ruling
requires become redundant and are removed. If the numbers are bad, this is the
permanent answer and §13.6's examples iterate `move tokens`.

**Supersedes nothing.** Extends D22 (owned-value demand) and D44 (traversal
observes) to the positions a comprehension stores from.

---

## D44 — Map traversal observes; consuming iteration transfers; no operation on a map makes a second owner

**Date:** 2026-09-18. **Status:** ruled (Eric, "make it canon"); specification
§2.3, §13.3, §13.5, §4 (the iteration example) and §22.1 rule 7 blessed
verbatim the same day. The compiler is NON-COMPLIANT until the
implementation lands (list below). **Issues:** #1158, #1187.

**Ruling.** `for (k, v) in map` is `map.iter()` and binds `k: &K`, `v: &V`.
`keys()`, `values()` and `iter()` return concrete ephemeral iterator structs
(§13.1) yielding views whose origin is the map. Transfer has its own names:
`remove`, `drain`, `into_iter`, `into_keys`, `into_values`. An independent
collection is spelled where it is wanted — `m.keys() |> map(it.clone()) |>
collect[Vec]()` — because it allocates and needs `Clone`; a typed binding
never collects (`let ks: Vec[K] = m.keys()` is a type error). `items()` is
retired: `iter()` is the one traversal, and it is what `for` already names.

Underneath it, §2.3 now says **transport is not duplication**: the compiler
may move a value's bytes wherever ownership moves, and never produces a
second live value from one unless the type is `Copy` — a rule that binds
intrinsics, runtime helpers and generated code exactly as it binds user code.

**Why.** None of the seven references creates a second owner, and every
language without a collector hands out views with a separately named
transfer. (Verified in `.reference/`: Rust `keys(&self) -> Keys<'_>`,
`IntoIterator for &HashMap` yields `(&K, &V)`, `into_keys`/`drain` transfer;
Mojo `keys()/values()/items()` yield `ref[origin]` "as immutable references",
`take_items()` drains; Zig `Entry{ key_ptr, value_ptr }` and
`ArrayHashMap.keys() []K` into the backing array; Vale `values() ->
Array<mut, &V>` and keys only for `K Ref imm`; Scala 3 `keys:
Iterable[K]^{this}` — a view whose capture set names the map; Swift `Keys`
is "a view of a dictionary's keys"; Go `range` and `maps.Keys` copy, safely
only because a collector owns the memory.) With has no collector and no
transparent reference counts (§1.5), so a copy of an owning value is a second
owner — the defect the mission names.

**Context.** The built-in `HashMap`'s `keys()`/`values()`/`items()` byte-copied
their elements through `with_hashmap_{keys,values,items}_out`. For a non-`Copy`
element the returned `Vec` and the map owned the same buffers: the compiler's
own `sema_clone_str_str_hashmap` double-freed through `.keys()` while building
the OpenSSL UAT project (#1158; allocator verdict `DOUBLE FREE size=64`, second
free `with_hashmap_free` from `Zcu.compile_source_frontend_mode`), and a plain
run stayed "ok" while `WITH_DEBUG_ALLOC_SCRIBBLE=1` corrupted the map in all
three modes. `for (k, v) in map` lowered through the same `MAP_ITEMS`
intrinsic and left the map empty — `m.len()` printed 0, `m.get` segfaulted,
`with check` said ok (#1187) — against §13.5's "the collection remains valid
after the loop".

**Alternatives rejected.**
- *Snapshots clone, iteration observes (keep `keys() -> Vec[K]`).* Correct,
  and the stdlib's Vec-backed map already does it, but `m.keys()` would hide
  an O(n) clone behind a name that reads as "look", would need `Clone` to
  look at all, and would break the signature a second time when views land.
  The caller count made the break nearly free now: five call sites in `src/`
  (four on `i32` keys, one the crash site), none in `lib/`, `tools/` or
  `build/`, 23 in `test/`. D39 makes a shipped `.wi` signature a contract, so
  it only gets more expensive.
- *Clone everywhere.* Every pass over a `HashMap[str, V]` would allocate and
  free each key and value; contradicts §13.5 and D22/D27.
- *Collect by owned demand* (`let ks: Vec[K] = m.keys()` clones). §3.8
  materializes `Copy` because a copy is free; extending it to `Clone` would
  let an annotation cause an O(n) allocation.
- *`clone_keys()`-style names.* With already spells the three meanings:
  observe (`keys()`), collect (`|> collect[Vec]()`), consume (`into_*`, D33).
- *`keys() -> Vec[&K]`.* Not writable: the compiler rejects the bare spelling
  `Vec[&T]` even as a local.

**Mission fit (mission.md ¶2).** Looking, copying and taking are three
meanings; each has its own visible spelling, and nothing allocates unless its
name says so. "Memory is the first resource… owned from the moment it is
made": a second owner made by the compiler is the defect, whatever the API.

**Non-compliance to retire** (the implementation plan):
1. The intrinsics byte-copy non-`Copy` elements (§2.3). Fix first, as a
   defect, alone in its batch with `:move-audit`/`:drop-audit`.
2. `for (k, v) in map` empties the map and binds owned values; `for … in &m`
   and iteration over a `&HashMap` parameter leave the pattern variables
   unbound; `let a: &str = k` inside the loop is invalid MIR (#1187).
3. `keys()`/`values()` return `Vec`; `iter`, `into_*` and `drain` on maps do
   not exist; `items()` exists. The stdlib Vec-backed map changes in the same
   commit as the intrinsics so the two never disagree.
4. The compiler rejects `Vec[&T]` while accepting the equivalent
   `Vec[Wrapper{&T}]`; §22.1 rules 3 and 7 make both legal as ephemeral
   values. Separate fix; the `sorted` example in §13.3 depends on it.
5. The ownership audit and `--validate-all` passed all of the above (#1159).

**Reopen if** a real corpus shows `|> map(it.clone()) |> collect[Vec]()` is
written often enough to be ceremony; the answer then is a named collecting
form, not collection by demand.

## D43 — Unannotated tails infer only when every written arm unifies; a missing arm forces `Unit`; a mixed join of written arms is a failure to infer, not a `Unit` function and not an illegal `if`

**Date:** 2026-09-18. **Status:** ruled (Eric, "make it so"), implemented.
Specification §9.1 (inferred returns, assignment's type) and the §3.8
cross-reference were blessed verbatim by Eric the same day. Reopen if a real corpus shows the `-> Unit`
annotation on mixed tails is frequent enough to be ceremony rather than a
guardrail. **Issue:** #1178.

**Ruling.** A function or closure with no return annotation infers its
return type from its tail expression. When the tail is a branching
expression (`if`, `if let`, `match`):

- **A missing arm forces `Unit`.** An `if` / `if let` with no final `else`
  (including an `else if` chain with no final `else`), or a partial `match`,
  is never a value: §9.1 already requires `else` in expression position and
  §9.7 already requires an expression-position match to be exhaustive. The
  statement reading is forced by the construct's shape, not by its arm
  types, so the join is `Unit` and the written arms are statements.
  `fn f(p): if p: bump(1)` and `fn g(p): if p: seen = 1` are `Unit`
  functions with no annotation, as today and as §9.7 protects.
- **A written empty arm counts as missing.** `else: {}` and `_ => {}` hold
  no expression; they are the programmer spelling "nothing here". This is
  also what lets a `@[must_use]` subject, which §9.7 requires to carry a
  catch-all, stay annotation-free.
- **When every arm is written and non-empty**, inference succeeds only when
  they unify: the common type if all agree, with `Never`-typed arms
  (`return`, `panic`, diverging calls) joining with anything.
- **Explicit `return e`** on any path must unify with the tail under the
  same rule; a value on one path and fall-off on another remains §4.10's
  missing-return error.
- **Entry points do not infer.** `main` (explicit or implicit), `@[entry]`
  functions and `test_*` functions have return types fixed by the runtime
  contract; their tails are statement position.

"Cannot infer" arises only when every arm is present and they do not
unify. Then the compiler does not infer. It does not pick `Unit`; it does
not pick the first arm; it does not fabricate a value. The `if` is not
illegal — its arms keep their own types — the *question* "what does this
function return?" has two answers, and the diagnostic hands it back:

```
error: cannot infer return type
   fn f(x: bool):
       if x: 1 else: log()
             ^         ^^^^^
   if arms have types i32 and Unit
   add `-> i32` or `-> Unit`
```

For a closure, which has no return-annotation syntax, the diagnostic says
instead to give the closure an expected function type. (Closure return
annotations are a separate feature; D43 does not depend on them.)

Once `->` is present the existing rules apply: `-> i32` makes the tail a
demanded join and the `Unit` arm fails #549 at the arm; `-> Unit` makes the
tail statement position, the arms are two statements, and a discarded call
result is the user's business (§10.1).

**Demanded vs. undemanded.** A join is *demanded* if any enclosing context
supplies an expected type or consumes the value: a `let x: T =`, a `-> T`
tail, an argument position, an arm of an enclosing demanded join, a
contextual join (`resolve_contextual_join`, D22). Demanded joins are
unchanged; every arm is checked against the demand. A join is *undemanded*
only when its result reaches a statement boundary, an unannotated function
tail, or an unannotated closure tail with no contextual expectation. D43
applies only to the undemanded unannotated-tail case. `let y = if x: 1
else: log()` has a demand (the `let` consumes the value) and stays #549.

**Both spellings, one rule.** A single-statement body and a block body
whose last statement is the tail are the same case and get the same answer
(`docs/completed/three-block-types.md`: "Body forms do not affect type
checking, return type inference"). `check_fn_body_with_sig_at` and
`check_block` both ask the tail for its type under this rule and stop; there
is no second join at the function level.

**Context.** With combines three things no reference language combines:
assignment is a value (`a = b = 3`), named functions infer their return,
and statements have no terminator. Three code paths decided "is the tail a
value?" differently: a single-statement body was always a value (mixed arms
rejected), a block tail under an unannotated return was always a statement
(so `fn pick(x): seen = 0; if x: 1 else: 2` lowered as a `Unit` function
with both values dropped while Sema typed the call as printable — garbage
at the caller), and a statement-position match kept its first arm's type
(invalid MIR). `parse_if_let` additionally fabricated `else: 0`. The spec
said an omitted `->` returns `Unit` (§9.1) while §3.8 assumed "an inferred
function return"; neither defined the inference.

**Alternatives rejected.**
- *F — `Unit` absorbs at an undemanded join.* The compiler picks `Unit` for
  the user, the signature becomes a property of whether some reaching arm
  is `Unit`, and the mistake surfaces at a caller.
- *C — the `if` is illegal when arms disagree.* The only fixes for a leg
  are `let _ =` or a terminator, both refused; and `if p: bump(1) else:
  print("no")` mid-block is two statements and must compile.
- *B / E — unannotated means `Unit`; branching tails never infer.* `fn
  sign(x): if x < 0: -1 else: 1` and `fn shout(s: str): s ++ "!"` must
  infer; that is the documented style and one meaning is forced.
- *A least-upper-bound rule.* With has no top type; the join of `i32` and
  `Unit` does not exist.

**Mission fit (mission.md ¶2, refined in the same change).** Mixed written
arms are the case where two meanings remain; the programmer spells the
choice with `->`, a spelling they already own. `sign`, `shout`, and every
missing-arm tail have one forced meaning and stay annotation-free.

**References** (verified in `.reference/`). Rust: assignment is `()`
(`rustc_hir_typeck/src/expr.rs`), an omitted `fn` return is `()`
(`rustc_hir_analysis/src/collect.rs`), `;` discards. Swift: assignment is
`()` (`CSGen.cpp` `visitAssignExpr`); the *declared* result decides whether
a trailing `if`/`switch` is an implicit result, never for `Void`, and never
an assignment (`TypeCheckStmt.cpp` `addImplicitReturnIfNeeded`); an implied
closure result may convert to `Void` (`CSSimplify.cpp`
`getImpliedResultConversionKind`). Zig: statement-`if` is its own grammar
production whose arms are never joined, a return type is mandatory, and an
ignored non-void value is an error. Go: statements only. Mojo: `=` is a
statement, `:=` the expression form; an omitted return is `None`, no
inference. Vale: `set` is a value typed as its destination, like With;
every `if` reconciles its branches; `;` voids a block; a top-level function
with no return is void and only lambdas infer. None of the six has With's
combination. (Scala and Kotlin, from memory and not in `.reference/`: LUB
to a top type, and value-discard when `Unit` is expected.)

**Matrix** (both body spellings agree on every row):

| tail of an unannotated fn | result |
|---|---|
| `if let Some(v) = f(): assert(v == 7)` | missing arm → `Unit` |
| `if let Some(v) = f(): seen = v` | missing arm → `Unit`; no fabricated `0` |
| `if p: seen = 1` / `if p: bump(1)` / `if x: 1` | missing arm → `Unit` |
| `if a: 1 else if b: 2` | missing final arm → `Unit` |
| `match e: A => self.n = 1, B => self.name = "b"` (partial) | missing arm → `Unit` |
| `match e: A => self.n = 1, _ => {}` | empty arm counts as missing → `Unit` |
| `if x: 1 else: log()` | `i32` vs `Unit` → cannot infer |
| `if p: bump(1) else: print("no")` | cannot infer; `-> Unit` accepts |
| `if p: seen = 1 else: assert(p)` | cannot infer (follow-up: assignment as result) |
| `match p: true => seen = 1, false => assert(p)` | cannot infer; no invalid MIR |
| `if x: 1 else: "a"` | cannot infer; with a demand, #549 |
| `if x: 1 else: 2` / `match x: true => 1, false => 2` | `i32` |

**Rollout.** The `else: 0` desugar dies in the same batch (#1179), as do
the garbage return, the invalid MIR, and the silent validator (#1180). Sweep
`src/`, `lib/`, `tools/`, `test/` and the audit-probe generators first: an
unannotated function ending in an else-less `if let` with an assignment
body infers `i32` today (returning the value or a fabricated `0`) and
becomes `Unit`, so a caller consuming it stops compiling; a mixed written
tail becomes "cannot infer" and gets its `->`. **Measured 2026-09-18:**
2,861 files under `lib/`, `tools/`, `test/`, `examples/`, `build/` plus the
compiler source: two functions needed `-> Unit` (`MirCore.mark_place`, a call
arm against an assignment arm; `SemaCheck.demand_generic_iter_next`, `insert`
against `remove`), both in `src/`. That is the data point for the reopen
clause and for the assignment-as-result follow-up (one of the two).

**Follow-ups, not part of the ruling.**
- The demanded-join diagnostic names the `Unit` arm.
- Lint: `pub fn` without `->` (a bundle-interface signature should not
  depend on whether someone added an `else: log()`).
- Lint, scheduled: an effect-free expression in a discarded position
  (`v == 3` alone on a line; the `1` in `fn f(x): if x: 1`). It is the
  guardrail for the missing-arm shape. §10.1's discard rule is untouched.
- Candidate: assignment is never an implicit result (Swift). Decide on the
  sweep's count of `if p: x = 1 else: …` tails.

## D42 — Floating-point math functions are width-generic builtins: `cos(x)` and `x.cos()` for f32 and f64, no width suffix

**Date:** 2026-09-16. **Status:** ruled (Eric), implemented.

**Ruling.** `cos(x)` and `x.cos()` work for `f32` and `f64` with no width in
the name; the `*_f64` wrappers in `std.math` are deleted. Both spellings; the
full libm surface (specification §17.6a lists it); the intrinsic-vs-libm
split is hidden. Integer operands convert to the call's float type (the
float operand's width, else `f64`), as integers convert to floats anywhere
in With. A function of the same name defined in scope shadows the builtin;
an `extern fn` declaration of the name does not.

**Context.** With has no ad-hoc overloading, so `std.math` shipped
`cos_f64(x)` over an `extern fn cos(f64)`. That makes the user spell a type
the compiler already reads off the argument — the Go tax (`math.Cos` is
`float64`-only). Meanwhile `abs`/`min`/`max`/`mul_add` were already
width-generic builtins; only the transcendentals had been left out.

**References (verified in `.reference/`).** Zig: `math.cos(value: anytype)`
over `@cos`. Rust: `x.cos()` per float type over `cosf32`/`cosf64`
intrinsics. Swift: free `cos(_:)` per type; its `tgmath` splits functions
that have an LLVM intrinsic from those that do not — the exact split adopted
here. Go: `float64`-only, the outlier. Vale: one 64-bit `float`, so the
question never arises; With has real `f32`/`f64`, so it does.

**Mechanism.** One table, `src/MathBuiltins.w` (name, arity, LLVM name, libm
name). Sema types the call and records free calls in `math_builtin_calls`;
MirLower tags both spellings `MirIntrinsic.MATH_FN` with the row id at the
NK_CALL dispatch, before any call shape is chosen; each backend lowers from
the row (LLVM: `llvm.cos.f32/f64` or `tan`/`tanf`; C: `cos`/`cosf`). Single
source of truth (the D6 FnAbi rule): the three phases cannot drift.

**Precedence, and why externs yield.** D29 makes every `extern fn` globally
visible (one C symbol, one contract). The migrator emits `pub extern fn cos
(f64)` into every migrated corpus, and `std.re` is prelude-closure, so that
declaration was ambient in every program and would have shadowed the
builtin — returning `f64` for `cos(0.0f32)`. `check_call` therefore lets a
math builtin outrank an *extern* declaration of its own name, while a real,
non-extern definition still wins. Inside migrated C, `cos(double)` reaches
the builtin and lowers to the identical symbol. Removing the redundant
migrator decls is #1153.

**Reopens if.** With gains ad-hoc overloading or a `Float` trait, at which
point a stdlib generic could replace the compiler table.

---

## D41 — Comparison operators derive from one primitive per family: `Ord.cmp(&self, &other)` backs `<`/`<=`/`>`/`>=`, `Eq.eq(&self, &other)` backs `==`/`!=`; fixed-name methods are overrides

**Date:** 2026-09-13
**Status:** Ruled by Eric (verbatim: "I rule for one Ord.cmp(self: &Self,
other: &Self) -> i32 backing all four ordered operators (and Eq.eq(other:
&Self) for equality), keeping the fixed-name methods as optional overrides,
and amend §11.7"). The §11.7 wording was blessed verbatim ("lgtm",
2026-09-14) and landed in `docs/with-specification.md` §11.7; the
implementation conforms on branch `c-algorithms-phase1`.

**Context.** §11.7 dispatched every comparison to a fixed method name
(`lt`, `le`, `gt`, `ge`, `eq`, `ne`) while `Ord` carried only
`cmp(self: &Self, other: Self)` and nothing wired `cmp` to `<`. A type
with `Ord` alone had no `<`; a generic `T: Ord` body could not compare two
`&T` views (`cmp` took `other` by value, and D22 §13.6 forbids an owned
demand through a view of a non-Copy `T`); and two views of a type with no
`lt` silently compiled to an ADDRESS comparison (#1137). The Phase 1
facades (SortedVec, BinaryHeap) compare views inside their comparators
and surfaced all three.

**Alternatives.** (a) Keep six fixed methods and require `T: Ord` users to
write `lt`/`gt`… taking `&T` — six spellings of one fact, ceremony at the
character level. (b) `lt` as the single primitive (Swift's `<`), deriving
the other three — one method, but a three-way `cmp` is what sorting and
ordered containers consume, so `<` would be derived from `cmp` anyway.
(c) `cmp` as the primitive with `other: &Self`, overrides optional — one
method gives all four (and `eq` gives both equalities), both operands are
observed (D5: a function that observes takes `&T`), and a type that wants
a cheaper `<` keeps the override.

**References.** Rust (`PartialOrd::partial_cmp(&self, &Rhs)`, `lt`…
provided defaults), Swift (`Comparable` requires only `<` over borrowed
operands, the rest synthesized), Mojo (`__lt__` + `__eq__`, the rest
defaulted), Vale (operators are named functions over `&T`; `!=` derived
from `==`). None takes the right operand by value; none asks for four
separate methods.

**Consequences.** Sema: with no fixed-name method on either operand type,
`<`/`<=`/`>`/`>=` select `cmp` and `!=` selects `eq`
(`operator_method_derived`); MirLower lowers `cmp(...) <op> 0` and
`not eq(...)`, flipping the ordering's sign when the primitive lives on the
right operand's type. `traits.w`: `Eq.eq` and `Ord.cmp` take `other:
&Self`; every impl in the tree conforms. A view of a type with neither
primitive nor override stays a compile error (#1137), never an address
comparison. Reopen if a future ruling makes `Ordering` an enum (then `cmp`
returns it and the derivation compares against `Ordering.Less`, unchanged
in shape).

---

## D40 — Seed/release version numbering: `y` is a bootstrap-compatibility group; a bootstrap breakage bumps `y` and resets `z`

**Date:** 2026-09-04 (granted 2026-09-05)
**Status:** Accepted (Eric, 2026-09-05). The convention below is now the rule:
`Y` is a bootstrap-compatibility group; a bootstrap breakage bumps `Y` and
resets `Z = 0`. The digits of a release tag now carry this agreed meaning, and
the release runbook's version-bump step points here.

Applied retroactively (Eric, 2026-09-05). The str-index bootstrap breakage
went out as `v0.15.1.9`..`v0.15.1.13`, which this convention says should have
opened the `v0.15.2.x` group. Only one of those was actually pinned — the
Mac/Linux seed `v0.15.1.10` (7 CI pins + `seed.lock`) — so it was republished
as **`v0.15.2.0`**, the first seed of the new group (same commit `4fd309e3`,
byte-identical assets, so the pinned SHA-256 digests are unchanged; it
bootstraps from `v0.15.1.8`, the last seed of the old group). `seed.lock` and
every CI pin moved `v0.15.1.10` → `v0.15.2.0`. The unpinned transient chain
tags (`v0.15.1.9`, `.11`, `.12`, `.13`) and the superseded `v0.15.1.10` were
removed. `v0.15.1.8` stays as the old group's last seed (still the Windows
pin, pending #1081).

**The convention.** A published `with` seed/release is tagged `vW.X.Y.Z`:

- **`W.X`** — the product/language line.
- **`Y`** — the **bootstrap-compatibility group**. Every seed tagged `vW.X.Y.*`
  is *mutually* bootstrap-compatible: any `vW.X.Y.Z` seed can build the source
  tree at any other `vW.X.Y.Z'` tag in the same group. Equivalently, every
  commit released inside a group is bootstrappable by every seed of that group.
- **`Z`** — a sequential cut *within* a group. A new `Z` is a **non-breaking**
  release: bug fixes, or a compiler feature that is merely *added* (so the
  group's existing seeds can still bootstrap the tree because build-driver code
  does not yet *use* it).
- **A "breakage"** is a commit the current group's seeds *cannot* bootstrap —
  because build-graph / build-driver code (comptime-evaluated by the pinned
  seed at graph materialization, before any stage compiles) uses a language or
  compiler feature newer than those seeds. A breakage **must open a new group**:
  bump `Y`, reset `Z = 0`.
- **The seed chain never breaks.** The first seed of a new group, `vW.X.(Y+1).0`,
  must be bootstrappable from the **immediately-preceding** seed (the last
  `vW.X.Y.*`) — but it need *not* be buildable by the rest of the old group.
  So the seed *lineage* is an unbroken chain N→N+1 (you can always walk one hop
  forward from any published seed to head), while the *mutual*-compat guarantee
  is scoped to a single `Y`.

**Why.** Sharing `Y` is a *promise* of mutual bootstrap compatibility, and CI
relies on it: each self-host lane pins a seed and expects any group seed to
build any group commit. Numbering a breaking seed *within* the old group
silently breaks that promise — the old seeds stay pinned, the tree now needs a
feature they lack, and every pinned lane dies at graph materialization
(`comptime index requires an array, tuple, or vec` — exactly the #956 failure).
Resetting `Z=0` on a breakage makes the incompatibility legible in the number
itself: "a `.2.0` tree cannot be built by a `.1.x` seed" is readable without
archaeology. Keeping only the N→N+1 chain (rather than demanding whole-group
compat across the break) is the *minimum* constraint that keeps bootstrap
reproducible end to end.

This is the same shape used by bootstrapped toolchains elsewhere — rustc's
stage0 is always the *immediately* previous release, never an arbitrary older
one; Go's bootstrap toolchain is a specific prior version — and it is the
release-facing corollary of AGENTS.md's bootstrap invariant, *"if a change
needs a newer seed, tag a release to be that seed first."* SemVer governs the
`W.X` API line and is orthogonal; `Y`/`Z` describe *bootstrap* compatibility,
which SemVer has no concept of.

**Immediate application (the live case).** Comptime `str` indexing (`s[i]` where
`s: str`) landed in `af7db8ce` (#1017, "a str's element is its byte, u8") and is
then *used* in comptime-evaluated build-driver files by `0173d08e`. Seeds
`v0.15.1.3`–`v0.15.1.8` do **not** support comptime `str` indexing, so they
reject the materialized build graph of the tree at/after `0173d08e`. That tree
is therefore a **breakage** relative to the `v0.15.1` group. The str-index-capable
seed (cut from `af7db8ce`, buildable *by* `v0.15.1.8`) is the **first seed of a
new group** and must be tagged **`v0.15.2.0`**, not `v0.15.1.9`: `v0.15.1.8`
builds it (chain intact) while `v0.15.1.3`–`.7` cannot (correctly excluded —
they are the old group). Tagging it `v0.15.1.9` would assert membership in the
mutually-compatible `.1` group, which is false. If this convention is blessed,
`release/v0.15.1.9` (`61b6e574`, currently bumping `src/version` to `v0.15.1.9`)
should become `v0.15.2.0`.

## D39 — Bundle interfaces: a bundle-provided module is its `.wi`, and callable semantics are the declaration

**Date:** 2026-09-02
**Status:** Ruled by Eric. Verbatim:

> A bundle contains: object code; manifest; canonical textual module
> interfaces (.wi); interface fingerprint. Consumers resolve a
> bundle-provided module to .wi, not its source. .wi is ordinary With
> declaration syntax in an interface-only parser mode. Functions may omit
> bodies and storage-backed globals may omit initializers only in
> interface input. Bundle interface generation happens after full Sema,
> so the emitter works from finalized semantic declarations rather than
> syntactic source projection. Consumers perform ordinary
> declaration/type/layout Sema on .wi, but no function-body analysis or
> MIR generation occurs for bundle implementations.
>
> No body-inferred ownership/effect information is part of the bundle
> interface. Callable semantics are determined by the declared signature.
> If some information is necessary for a caller to safely typecheck and
> cannot be derived unambiguously from the signature, With's source
> declaration language must gain a way to state it explicitly.

**Declared semantics (verbatim).** "A declaration means what its
declaration says. T → consumed; &T → borrowed for the call; &mut T →
mutable borrow; move self → consume receiver; mut self → mutable receiver
semantics; raw pointers → no With ownership semantics beyond their
declared type; return references use deterministic lifetime/view
elision": the receiver if one exists, otherwise the single borrowed
parameter, otherwise ambiguous — a declaration error at bundle build
time, never at a downstream call (`pub fn choose(a: &Foo, b: &Foo) ->
&Foo` cannot produce a valid interface under the default rules). "If
`fn inspect(x: BigThing)` actually doesn't consume x, then the
declaration was wrong. It should have been `fn inspect(x: &BigThing)`.
The bundle boundary exposing that mistake is a feature." Otherwise
parameter ownership would be "partly specified by the signature and
partly by an invisible implementation-derived fact — precisely the sort
of semantic spooky action that becomes painful once separate compilation
exists." An explicit origin spelling (conceptually `pub fn choose(a:
&Foo, b: &Foo) -> &Foo from a`) is a future real language feature for
authors, never an interface-only annotation of inferred Sema facts: "If a
caller must know it for correctness, it belongs in the function's
contract. If Sema can infer it from a body today for convenience, great.
But before that function can cross a separate-compilation boundary, the
contract needs to be representable without its body." Discovering where
With relies on implementation inference more than its declared semantics
admit is healthy.

**Typed body state.** Not a special case threaded through every phase
but an explicit state early in the AST: `FnDecl { signature, body:
SourceBody(...) | InterfaceBody }` and `GlobalDecl { type, initializer:
Expr(...) | InterfaceProvided }`, with the invariant "Anything requiring
implementation information must reject or ignore InterfaceBody; anything
operating on declarations must work identically." Bodyless declarations
exist only in interface input — `pub fn foo(x: i32) -> i32` in ordinary
`.w` source stays an error — so the language never acquires
C-header-style forward-declaration semantics because the compiler needs
interfaces.

**Constants, globals, layouts.** A constant carries its canonical folded
value (`pub const X: usize = 67`, never `A * 4 + 3`), so interface
constants have no implementation dependencies and the consumer's
dependency closure stays tiny. A storage object carries only its
declaration (`pub let TABLE: [256]u8`); the object supplies storage.
Layouts are emitted as the actual declarations needed to reproduce them,
canonicalized, not source alias/import chains.

**Fingerprint invariant.** The bundle build proves that compiling every
exported module against its emitted `.wi` yields exactly the same
externally visible declaration model as compiling it from source: Sema
computes a canonical exported-declaration graph from both paths and
requires hash equality — type layouts, ABI-relevant field offsets, enum
discriminant values, parameter and return types, receiver mode,
declaration-level ownership and borrow modes, calling convention,
visibility, constant type and value, extern function-pointer signatures,
generic constraints when applicable. The fingerprint is recorded in the
manifest so interface N can never be paired with object N+1; a mismatch
is rejected before linking. An emitter bug is a build failure, not an
ABI corruption.

**Context.** Measured 2026-09-02: Sema on pcre2's 155k migrated lines
costs 6.06 s per program that imports it (hello world 0.03 s), and
`std.regex` is in the prelude. The declarations-only projection is 206
functions, 87 types and 3,052 table globals.

**Alternatives (rejected).** Embed the source and skip bodies in Sema:
every program parses 5.5 MB per corpus (~0.4 s and growing), the binary
carries ~100 MB of source at 30 corpora, and unchecked bodies invite
re-coupling. Hand-written facade declarations: duplicated signatures
whose drift is undetectable at link (the #761 class), does not scale,
and is the `with_*` seam respelled (retired by D30). Binary metadata
over Sema's tables (Rust `.rmeta`, Go export data): exact and fastest,
but a serialization format over the most-churning tables in a
three-month-old compiler; the textual interface upgrades to it if ever
needed. Lazy prelude loading and a faster Sema do not remove the
per-program cost at 30 corpora. Swift's `.swiftinterface` is the model;
Zig has no interface unit.

**Would reopen.** An API that cannot state its returned-view origin
under elision (the explicit-origin feature); a With-authored library
with generics crossing the boundary (`docs/abi_roadmap.md` Level 1).

Supersedes D38's "the interface is the source" wording; D38's key,
store, and embedding stand. Design: `docs/wo_bundles.md`.

**Spec projection landed** (2026-09-02, the words blessed by Eric): §3.4
gains the separate-compilation origin rule (declaration's receiver, else
the single reference parameter, else rejected at bundle build; the
explicit-origin spelling is a future language feature), §18.5c "Bundles
and interfaces" states the bundle, the `.wi` flavor, declaration-only
callable semantics, the Level 0 rule that a generic function stays
corpus-internal and is omitted from (and named in) the interface, and
the fingerprint proof; the §18.5 CLI line for `with version --abi-sha`
stands.

## D38 — Migrated corpora compile once into `.wo` bundles; the boundary is a versioned With ABI, never a C ABI

**Date:** 2026-09-02
**Status:** Ruled by Eric. Verbatim: "I do not wanna compile the migrated
code over and over when there's no changes to it. I wanna compile the
migrated code once and keep the .wo. The normal build cycle should *not*
recompile the migrated libraries."; "None of our compiler code should
have c_export. We are not exposing any C ABIs."; "Compiled user binaries
will need to embed those .wo's that they use. We should automatically do
this." Design: `docs/wo_bundles.md`.

**Decision.** Each migrated corpus is a `.wo` bundle: its With source
(the interface — generics, ownership modes, effects all visible to Sema),
its migrated tests, and one With-native object per target and ABI. The
object key is corpus content × target × sha256 of the ABI-defining
sources (`src/FnAbi.w`, `src/TypeLayout.w`; `docs/with-abi.sha256`) —
Go's toolchain-keyed cache applied to the ABI subset, after the reference
survey (2026-09-02: Go, Rust, Zig key artifacts on the whole toolchain
and recompile; only Swift promises cross-version stability, at the cost
of resilience). The compiler generation is not in the key, so a `.wo` is
rebuilt only when the corpus or an ABI rule changes, and no version
number has to be remembered. The longer road to Swift-level stability is
`docs/abi_roadmap.md` (Level 0 now, Level 1 frozen ABI at a release,
Level 2 library evolution as a campaign). The compiler embeds every
`.wo` and stays one standalone file; a user binary automatically links
the `.wo` objects it references and is standalone too. The boundary
convention is With's own (`FnAbi` pass modes, header types, mangling,
drop protocol), declared and versioned in `docs/with-abi.md`; a change
to an ABI-defining rule must bump the version, enforced by a battery hash
check. No `@[c_export]`, no C surface, anywhere in the compiler.

**Amended by D39 (2026-09-02).** The bundle's interface is its
*declarations* (`.wi`), not its source, and the compiler embeds
interfaces, never corpus sources. See D39.

**Context.** The container corpora (D37) will bring the compiler's
migrated dependencies to 20–30. Today each bootstrap stage recompiles
every corpus (pcre2's `regex_runtime.o` three times per build; zlib
in-unit on every program), and the cost scales linearly with the count.

**Alternatives.** Keying objects by compiler fingerprint (D30's cache as
it stands — correct, but rebuilds every corpus three times per compiler
build; rejected as the *normal* cycle, kept as the fallback when the ABI
version bumps); a platform-C-ABI boundary (rejected: exposes a C surface
from the compiler, which the runtime doctrine forbids, and is not
withy); dynamic libraries (rejected: loader, C symbol tables, versioning,
and multiple files).

**Reasoning.** "Compile once" across compiler generations requires a
stable boundary; the only boundary consistent with the mission is With's
own convention made deliberate — versioned, hash-enforced, and validated
by rebuilding each corpus and running its own tests against both objects
in the battery. Source as the interface keeps every With-ism intact and
avoids a metadata format. Reopen if the ABI version has to bump so often
that the normal cycle recompiles corpora anyway (the signal that pass
modes/layouts are not yet settled enough for the scheme), or if a corpus
needs a boundary the ABI document cannot express.

---

## D37 — Stdlib containers and algorithms come from C corpora migrated whole; `with migrate` is raw, the With-ness lives in the facade

**Date:** 2026-09-01
**Status:** Ruled by Eric. Verbatim: "we dont 'selectively migrate' — but
we do 'selectively facade'"; "with migrate should be raw / the Withyness
resides in the facade". Plan: `docs/stdlib_sourcing_plan.md`.

**Decision.** The stdlib's data structures and algorithms are sourced from
three C corpora migrated **whole** — c-algorithms, TommyDS, STC — plus a
surgical port of M*LIB's `m-bptree.h`; the With stdlib is a facade that
selects and exposes engines. `with migrate` produces a raw, faithful,
C-shaped transpile (one concrete copy per template instantiation the
corpus contains, `void*`/`elem_size`/callback genericity, raw pointers)
and adds no ownership modeling, generic lifting, or ergonomics. Every
With-ism — views, transfers, drops, generic surfaces, complexity
contracts — is the facade's. Native code is reserved for what migration
provenance cannot beat: graph algorithms, union-find, and SlotMap's free
list. The original native-Vec exception is superseded by the follow-on
selection below; With's `str` semantics remain the public contract.

**Follow-on selection (Eric, 2026-09-12).** The
[facade map](stdlib_sourcing_plan.md#facade-and-engine-selection--erics-ruling-2026-09-12)
selects STC for everyday containers and algorithms, including `Vec`,
`hmap`/`hset` for the default owning hash collections, and `smap`/`sset`
for `OrderedMap`/`OrderedSet`. STC's inline entries and compact Robin Hood
metadata fit an owning generic map. M*LIB's B+ tree supplies
`BTreeMap`/`BTreeSet`; c-algorithms supplies classical engines and
references; TommyDS supplies specialized indexing/storage. Corpus names
need not become public types. Benchmarks validate these selections and
compare alternatives; they no longer leave the default engine undecided.

**Context.** #936 (SlotMap O(n) insert, no free list) prompted a survey
that found the same species in BTreeMap/BTreeSet (#937, linear lookup,
O(n²) insert), consuming iteration (#938), HashMap delete (#939), and no
sort at all (#940). The containers had been written to pass fixtures with
nothing measuring complexity.

**Alternatives.** Native rewrites (rejected: repeats the failure mode and
forgoes decades of tuning); a C wrapper (rejected: a foreign boundary the
ownership model cannot see through; also not self-hosted); migrating
pieces of corpora (rejected: partial forks lose the shared machinery a
library evolved with, and the un-facaded code is coverage, alternates,
and a migrator bug corpus); lifting templates to With generics inside the
migrator (rejected: With-ness belongs in one place, the facade; the
migrator stays a transpiler whose correctness is checkable against the
upstream's own tests).

**Reasoning.** Migration is With's first-class path ("modeled C becomes
humane"), and this is its largest dogfooding: three real corpora, one of
them (STC) a deliberate macro-migrator hardening campaign. Keeping the
migrator raw keeps its oracle simple — the upstream's tests must pass
under With — and keeps every design choice about ownership and ergonomics
in the facade, where the drop audit and complexity fixtures can hold it.
Reopen if a corpus's raw form proves unusable behind any facade (the
signal would be a facade that cannot express its engine's ownership), or
if the STC instantiation-set question in the plan's Phase 3 has no
benchmark-backed answer.

---

## D36 — Build graph producer edges are inferred from consumed outputs, never demanded

**Date:** 2026-09-01
**Status:** Implemented (29212f97, #700). Agent judgment call under the
no-ceremony rule; reopen only if an inferred edge is ever wrong.

**Decision.** When a build.w target's `entry` or `.input()` names a path
that another target produces (`.output()` or an extra output), the graph
adds the producer edge itself (`build_graph_complete_edges`, once in the
materializer before the graph is emitted). Inferred edges are data edges:
the consumer reads the file, so they feed the `dep_rebuilt` staleness rule
exactly as a written `.dep()` does. Ordering-only edges — where nothing
is consumed — remain the author's to declare, and remain the only kind
that must never feed `dep_rebuilt` (D13).

**Context.** #700 demonstrated the consequence of a missing edge: not a
slow rebuild but a wrong binary — a stage1 assembled from pre-swap and
post-swap objects, differing from any tree that ever existed. The edge
audit already found every such edge and printed a note.

**Alternatives.** (a) Keep the note. (b) Make it a hard error — tried
first in this batch; it failed the selfhost `build-w` fixture on the
first battery, and would fail anyone using `compile_asm_object` or
`compile_c_object` on a generated source, since those helpers cannot
declare deps. (c) Infer. Ninja and Zig's build graph both derive the
edge from the produced path; Go's module graph is implicit.

**Reasoning.** The compiler had computed the producer in order to
complain about it. Demanding that the author repeat a fact the compiler
already holds is the exact ceremony the mission forbids; the fixture
failure made the cost concrete on the first run. Inference also removes
the declaration-order dependence rather than policing it.

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
and is marked accordingly. Status 2026-09-04: the regex seam
(`rt/regex_runtime.w`, `with_regex_*`) is retired — `std.regex` calls the
pcre2 bundle through its interface and the compiler's own regex-literal
validation goes through the facade (batch C4, docs/wo_bundles.md "Shim
retired"); the `with_*` runtime objects remain.

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
