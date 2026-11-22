# Language design rulings and ceremony

Moved verbatim from AGENTS.md (#2374). Nothing here was reworded.

## Language Design Philosophy

**Don't make the user write anything the compiler already knows, could figure
out, or that doesn't matter.** The single principle behind With's surface
syntax; apply it pervasively. It is why a function returning `i32` needs no
trailing `0`; you never write `Ok(())` or `Ok(value)` — `?` handles the sad
path; return types are inferred when the body makes them obvious; `fn main:`
not `fn main -> i32:`; enum variants are `.Variant` when the type is known.

**Never force ceremony for something that doesn't matter.** Requiring
`let _ = expr` to discard a value whose discard has no effect is the clearest
violation: a dropped `Result` does nothing, so a "must-use Result" diagnostic is
**forbidden**. (A dropped `Task` *cancels* it, so an explicit choice there is
acceptable.) Before adding any rule, error or required annotation, ask: does
this make the user state something the compiler already knows, can infer, or
that has no consequence? If yes, don't. A diagnostic earns its place only by
catching a real mistake the compiler can't otherwise resolve.

**Vale, not Rust, is the closest reference for the ownership model.** We take
the best of Vale (single ownership, consuming destructors / Higher RAII,
generational references, regions). "Exactly as safe as Rust" is a safety
*bar*, not a design compass — we are allergic to Rust's tiresome syntax. A Rust
idiom we must adopt is confined to the library-maintainer tier. For
ownership/drop/lifetime semantics, check `.reference/Vale` first; reach for Rust
only when Vale can't meet the bar.

**The signature states parameter ownership mode — load-bearing.** For free
functions, `&T` borrows and plain `T` consumes. Auto-referencing removes
call-site ceremony: `peek(x)` when `peek` takes `&T`; `take(x)` when `take`
takes `T`. The signature is authoritative, so a body edit never silently
changes ownership, destructor timing or the calling convention. `move x`,
`copy x`, `&x` remain explicit spellings of intent, but a consuming signature
never requires a redundant call-site `move`. Don't infer a borrow because a
plain-`T` parameter is currently read-only. A function that observes takes
`&T`; one that retains a borrowed input makes the lifetime valid; one that
needs an independent value clones explicitly. The compiler may diagnose a
legacy read-only `T` with an exact `&T` fix-it, but never silently reinterprets
the declared type. See specification §3.8 and
`docs/meetings/2026-07-05-D5-historical-share-place-free-parameter-design-superseded.md`.

**A parameter's mode is what the callee does with it (D110, Eric
2026-10-08).** Stores the argument → ownership transfers; only reads it → the
argument is observed. `get`, `contains`, `remove` take their key as a probe and
observe it; `insert` stores its key and takes it; `increment`/`decrement`
observe the probe and copy the key only on the insert path. Modes come from
signatures, once: builtin container methods have declared signatures (`fn
remove(key: &K) -> Option[V]`), and Sema's move checking, MIR lowering and drop
emission all read them. A builtin never has a second ownership system — no hand
list of "observed" or "consumed" intrinsic arguments in any stage.

**Copy-or-move is decided by identity, not representation (D111, Eric
2026-10-08).** Values have no identity (integers, floats, strings, keys):
passing one copies it. Resources have identity (files, tasks, sockets, handles,
buffers being filled): passing one transfers it. A heap buffer does not make
something a resource. `str` is a value: passing a `str` always copies, code
using `str` never sees "use of moved value" and never needs `.clone()`. The
implementation is an immutable, shared, reference-counted buffer (atomic count
— `str` is `Send`; literals immortal): a copy is a pointer plus a count
increment, the last holder frees, and a variable's last use is a move with no
count traffic (the drop plan's last-use facts). Built or edited text goes
through a builder that produces a `str`.

**Receiver modes are separate.** `fn`/`&self` reads, `mut fn`/`mut self`
mutates the receiver place in place, `move fn`/`move self` consumes it.
Retiring free-parameter SHARE-PLACE doesn't change `mut fn` receiver semantics
or D21's place-threading pipeline rule.

**D22 has one canonical, complete source: `docs/meetings/d22-Eric-Ruling.md`.**
Any document, comment, test, TODO, plan or behavior that conflicts with it is
non-conforming. Don't edit, reinterpret, narrow or broaden it;
`docs/proposals/d22-implementation-plan.md` is a derivative plan that can't
amend it. **D22 map-view and contextual-Copy is implemented.** `HashMap[K,
V].get` and `BTreeMap[K, V].get` uniformly return `Option[&V]`; `remove`
transfers and returns `Option[V]`. Copy-ness never changes a lookup signature.
A `&T` stays a reference during inference and pattern projection, including
when `T: Copy`; it materializes an independent `T` only once an owned-value
demand is established. `Option`, `Result`, patterns, `?`, `??` and eliminators
are transparent to view origins. Don't restore conditional `get` returns, teach
new code that lookup owns/copies, or treat a lost origin through `unwrap` as
precedent. Specification §§3.4, 3.8, 9.7, 10, 13.3, 21.1 and
`docs/meetings/README.md` D22 are conforming projections.

**D27 extends the doctrine to positional collections: element access
observes; `remove` transfers.** `xs[i]` denotes the element place; a positional
collection has no `get` (D71): `xs[i]` is the one spelling and panics
out-of-range (`Option` is for keyed maps); a binding names what's there, an
annotation demands what it says. The element-view campaign is done
(`docs/proposals/d27-implementation-plan.md`); the interim #715 element gate and
the #730 unannotated-let field gate are retired. Serialize/Deserialize
signatures are correct as declared (`JsonView` is a Copy view token); don't
"fix" the threaded sink into a borrow.

**D44 extends it to map traversal: traversal observes; consuming iteration
transfers; nothing makes a second owner.** `for (k, v) in map` is `map.iter()`
and binds `&K`/`&V`; `keys()`, `values()` and `iter()` return ephemeral view
iterators; `remove`, `drain` and `into_iter`/`into_keys`/`into_values`
transfer; an owned collection is `m.keys() |> map(it.clone()) |>
collect[List]()` and a typed binding never collects. §2.3: transport is not
duplication — the compiler never produces a second live value from one unless
the type is `Copy`, intrinsics and runtime helpers included (#1158, #1159,
#1187). Don't add callers of `keys()`/`values()`/`items()` as `List`s or
byte-copy a non-`Copy` element out of a container.

**D51 has one canonical, complete source:
`docs/meetings/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md`.**
Don't edit, reinterpret, narrow or broaden it; the spec and decision log
conform to it and `docs/proposals/modeled-c-implementation-plan.md` can't
amend it. Its test for every C-interop inference: *what happens if this
inference is wrong?* Infer silently only what can at worst remove capability
or reject a valid program (dependency, invalidation, nullable, thread-bound,
coarse domain, presentation sugar); never infer what can create unsafety
(ownership, destruction, consumption, retention, independence, static lifetime,
success, thread crossing) — those come from an explicit `c facade` clause, an
adopted convention profile, or a proof, never from a name. Never half-model: a
safe constructor with no destruction contract is a leak (§65). Ordering (§66):
the SQLite facade is written first and compiles against the real header before
any example, release UAT, blog sample or documentation example is rewritten.
Until the facade language lands the compiler is NON-COMPLIANT: don't add safe
c_import constructors, wrappers or method sugar that grant ownership, and don't
teach new code that a name proves a destructor.

**`FnAbi` is the single ABI source of truth — never re-derive call ABI
per-path.** Every signature has ONE `FnAbi` (per-parameter `PassMode`:
`Direct`/`Indirect`/`IndirectPlace`/`Fat`/`Ignore`), computed ONCE by
`compute_fn_abi(sig)` and read by both the callee prologue
(`declare_function`) and every call site (`push_call_arg`). When adding a
call-lowering path, receiver shape or parameter kind, extend
`compute_fn_abi`/`PassMode` in ONE place — never a fresh per-path "value vs
address vs byval" decision (that is the transparent `T*`/`T**` divergence bug).
`PassMode::IndirectPlace` is a physical mode for compiler-modeled borrowed
places such as in-place receivers; an explicit `&T` is a reference value with
that reference's ABI; a plain consuming `T` is owned even when its ABI is
indirect. See
`docs/meetings/2026-07-06-D6-fnabi-is-the-single-abi-source-of-truth-compute-once-both.md`
and `docs/spec/abi/fn_abi_descriptor_design.md`.


## Ceremony is a design defect, not a user error

Code that exists only to satisfy the compiler is evidence the language is
wrong somewhere; your job is to notice and raise it, not write more of it.

**The test.** For any token: *would a person reading this think it means
something?* If it's there because the compiler requires it, it is ceremony.

**Signals that always trigger the test:** `.clone()`, `copy`, `move`, an
explicit `&`, an `as` cast, `Some(...)`, `let _ =`, or a type annotation
written only to compile; an error on code a person would call obviously
correct ("use of moved value" on a lookup key, a cast on `len()` used as an
index); a rule explained by "how X is represented" rather than "what the
program means"; the same fact encoded in two or more places; a comment
explaining a workaround for the language; a fix that leaves something to
remember.

**What to do.** Stop and raise it before writing more in that pattern. A
ceremony report is always welcome, even mid-task. Give: the code as a person
reads it; why it exists (the rule or representation); which law it violates;
how many times the pattern occurs in the tree (count it); what the code would
look like if the language were right and what would have to change. Never copy
a ceremonial pattern from neighboring code because it is local precedent —
precedent measures how long the defect went unraised. Writing the same
workaround a second time is a report.

**Integer width (D114).** No code depends on `isize` being 32 or 64 bits, and a
value whose range isn't bounded by memory is written with a fixed width:
timestamps, file sizes and offsets, hashes, IDs, money, anything serialized or
crossing into a C struct. Supported targets today are 64-bit hosts and wasm32;
other widths must stay possible without a redesign.

**The backstop: the ceremony census.** `tools/ceremony_census.with` counts the
known patterns. The bar is main's own counts (`:install-user` publishes them to
the green store on reseed, so a cleanup lowers the bar once merged). `src/main
build :ceremony-census` (in the gate) measures a tree against the bar: a count
that falls passes; one that rises fails unless the PR grants it in
`build/ceremony-allowances.tsv` (pattern, area, the bar, the new ceiling, why)
and says why in its description. A report that identifies a new pattern adds it
to the census.
