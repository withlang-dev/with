# D66 — Discriminated variadic contracts; borrowed record views from a resource or domain; `static` stays the strongest case

**Laws:** 6, 4 (docs/mission.md).

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

**2026-09-25 amendment — retained variadic pairs (#1652).** Eric approved
four rulings on the brief, "all four are right", with two additions to (c)
and one debt. (a) A resource names its safe abandonment path with
`abandon <operation>`; the operation must itself be `callbacks none`, and
the compiler runs it before the destroyer on every drop path whose pair
state is not proven callback-free (a spurious reset costs a call; a missed
one is unsafe). Per-slot `callbacks none` on a destroyer is rejected as
name-shaped inference. (b) `ok CONST` on a variadic operation is the D64
evidence model applied to status: the success condition of its listed
cases, presentation unchanged; unlisted cases stay raw. (c) Retained
userdata is a borrow per ruling §25/§45: `&U`, and when `U` is a callable
its capture views (§12.4) decide the retention's mode — a mutate capture
makes it exclusive (why Rust needed its scoped `Transfer` type; With has no
in-place parameter mode on a free fn, so the mode is the capture's). The
retention is the ordinary view-liveness borrow, held by the resource, ending
at reset/unregister, destruction, or the last callback-capable operation;
inside that window the borrowed place cannot be touched, and the resource is
ephemeral (no move into long-lived storage, no return). (d) The paired
userdata setter is implied by the callback case; `retains by param 0` stays
explicit because retention is never inferred.

**Debt (D65).** Retained userdata now has two models: stage 9's owned box
(`retains param N by param 0` on a fixed-arity method boxes the value and
frees it after the destroyer) and the variadic borrow above. The borrow is
the target model and the box is the legacy form; no third model is to be
built, and the box is to migrate to the borrow when its fixtures are
revisited.

---
