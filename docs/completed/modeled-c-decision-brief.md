# Decision brief: opaque C handles as owned With values

**Status:** for deliberation. Nothing here is ruled. No spec wording is proposed;
wording comes after the rulings, and only Eric blesses it.
**Date:** 2026-09-20.
**Prepared for:** Eric and the architect.

---

## 0. How to read this

Four decisions, each with the same five parts: the question, what the seven
reference languages do, what real C headers say, the full list of reasonable
options, and how each option sits against the mission statement and against
rulings already made. A recommendation and a prediction close each one.

Reference claims were verified in the vendored trees under `.reference/` and
carry a path and line. Where a tree had no evidence it says **not found in
tree**; anything from general knowledge is marked **(unverified)**. Two of my
own earlier claims did not survive verification and are corrected in §3.

Three of the four recommendations I gave verbally on 2026-09-20 are changed or
weakened by what the research found. §9 lists the changes.

---

## 1. The problem

Today a user of any real C library writes this:

```
var db: *mut sqlite3 = null
let rc = unsafe { sqlite3_open(path, &raw mut db) }
let changed = unsafe { sqlite3_exec(db, sql, null, null, null) }
unsafe { sqlite3_close(db) }
```

`:user-programs-safe` fails on it, by Eric's ruling (D47: "an application
developer never writes `unsafe`"). Hiding the `unsafe` in a wrapper module is
the Rust idiom and was rejected on 2026-09-20 ("that's the reason for the rule
- to prevent you from papering this over"). The goal:

```
let db = sqlite3.open(":memory:")?
let rows = db.prepare("SELECT name FROM users")?
while rows.step() == SQLITE_ROW:
    print(rows.column_text(0) ?? "?")
```

**Why `unsafe` is demanded today.** `SemaDecl.w` (~735-765) marks a
c_imported function *raw* when any parameter or the return is a pointer, with
two exceptions (`const char *` inputs since D47; a short curated libc list). It
is a test on type spelling, not a safety analysis. Nearly every real C function
takes a pointer, so nearly every real C function is raw.

**What is genuinely unknowable from a header.** `sqlite3_step(stmt)` is
memory-unsafe only if `stmt` is null, already finalized, or not a statement.
The header says `sqlite3_stmt *` and nothing else. If safe code could hold a
loose `*mut T` and pass it to C, safe code could pass a dangling pointer; that
breaks "exactly as safe as Rust".

**Why that does not require `unsafe`.** The user holds a raw pointer only
because the binding handed them one. If `sqlite3_stmt` is an owned, non-null,
non-Copy With value whose `Drop` calls `sqlite3_finalize`, single ownership
proves the handle is live, by the same proof With uses for its own types.
What the compiler must be told is a small set of *facts about the library*. The
four decisions are about which facts, and where they come from.

**Implementation state.** Two half-built mechanisms in `src/CImport.w` never
met:
- The #357 curated owning wrapper (`ci_emit_owning_wrapper`, ~1608): a
  `COwned_<ctor>` type whose `Drop` calls the destructor. Its evidence is a
  hardcoded libc table (`fopen` → `fclose`), and it emits its own constructor
  as `unsafe fn`.
- §16.2a auto-methods: `Counter(40)`, `c.add(2)` by name prefix. The
  constructor is safe; the methods demand `unsafe`; **no `Drop` is generated,
  so the handle leaks**. With calls a leak a defect (mission ¶5).

---

## 2. The mission, numbered for reference

From `docs/mission.md`, verbatim, numbered here only so options can cite them.

- **M1.** "an ergonomics-first systems language: close to the machine, native
  by default, exactly as safe as Rust, and built to remove the suffering."
- **M2.** "Every character the program has already determined is a compiler
  failure if the programmer still has to write it."
- **M3.** "When exactly one meaning is forced — by types, by scope, by a
  header, by an ABI, by a proof — With infers it, imports it, fetches it, binds
  it, proves it, generates it, links it, migrates it, wraps it, or makes it
  safe."
- **M4.** "When two meanings remain, the programmer spells the choice. That
  spelling is a guardrail, not ceremony."
- **M5.** "A documented default may stand in for the choice only when the
  alternatives are representations of the same meaning ... a default never
  selects between meanings."
- **M6.** "C interop is first-class, not an escape hatch ... without making the
  programmer become the build system."
- **M7.** "With pays compiler complexity to remove ceremony without removing
  guardrails. Raw C stays explicit; modeled C becomes humane."
- **M8.** "Rust calls leaking safe; With calls it a defect. Leaking memory must
  take deliberate, visible effort ... If the creators of the language can leak
  by accident, the design is wrong, not the programmer."

M3, M4 and M5 together are the test every option is put to: *is the meaning
forced, or do two meanings remain?* If forced, infer. If two remain, the
programmer spells it, and no default may pick.

---

## 3. Rulings already made that constrain the options

- **D47** (2026-09-20). "Evidence governs what With receives from C", lending
  needs none. Its *alternatives weighed* section already rules on three things
  that recur below:
  - "Per-library contract data: the per-package upkeep Eric rejected for
    `with get` (D46)."
  - "Inference from parameter names: unsound."
  - "Proof from C source when `with get` built it: a later refinement."
- **D46** (2026-09-19). "we cant be writing special case code for every conan
  package"; per-package port files were written and deleted the same night.
- **D45** (2026-09-19). "A copy is never implicit unless it is O(1); an
  allocating copy is spelled." Bears on Decision 4.
- **D4** (2026-07-05). `use c_import("…", retains: ["fn(idx)"])` is accepted
  precedent for stating a C contract *in the import, in the user's source*.
- **§16.2a** already promises the owning wrapper "when ownership evidence
  exists". **§16.3c** already says a nullable C string return "is modeled as
  `Option[str]`", and lists three evidence sources "in priority order:
  explicit annotations in the importing project, curated contract overlays
  shipped with the toolchain, and package-supplied binding metadata
  (`with get c.*`)".

**A tension to resolve while ruling.** §16.3c names package-supplied binding
metadata as an evidence source. D46 and D47 record per-package upkeep as
rejected. Either the spec sentence describes something narrower than "per
package files we maintain" (metadata a package author ships of their own
accord), or one of the two needs to change. This brief does not assume which.

**Two corrections to what I said on 2026-09-20.**
1. I said Swift's Core Foundation import infers ownership from names (the
   "Create rule"). **Not found in the Swift tree.** Greps of
   `lib/ClangImporter` for "create rule" and any `Create`/`Copy` name match
   return nothing; Swift reads an attribute Clang has already computed
   (`ImportType.cpp:2344-2348`). The inference lives in Clang, which is not
   vendored **(unverified)**, and is opt-in per header region there.
2. I recommended per-*type* destructor inference by name suffix. Real headers
   refute it; see §4.2.

---

## 4. Decision 1 — How the compiler learns what destroys a C handle

### 4.1 The question

For `typedef struct sqlite3 sqlite3;`, which function releases it, and how does
the compiler come to know? Everything else (safe methods, `Drop`, no leak)
follows from this one fact.

### 4.2 What real headers say (run against the actual files)

I applied the rule I had proposed — *a function taking exactly one `X *`,
returning void or int, whose name ends in `_free`, `_destroy`, `_close`,
`_finalize`, `_delete`, `_release`, `_finish`* — to the headers on this machine.

| Library | Handle | Candidates found |
|---|---|---|
| sqlite3 | `sqlite3` | **two**: `sqlite3_close`, `sqlite3_close_v2` |
| sqlite3 | `sqlite3_stmt` | `sqlite3_finalize` |
| sqlite3 | `sqlite3_blob` | `sqlite3_blob_close` |
| sqlite3 | `sqlite3_backup` | `sqlite3_backup_finish` |
| sqlite3 | `sqlite3_str` | `sqlite3_str_finish` — **not a destructor**: it returns the built `char *` |
| sqlite3 | `sqlite3_value` | `sqlite3_value_free` — but a `sqlite3_value *` is usually **borrowed** (callback arguments); only `sqlite3_value_dup` results are owned |
| curl | `CURL`, `CURLM`, `CURLSH`, `CURLU` | `curl_easy_cleanup`, `curl_multi_cleanup`, `curl_share_cleanup`, `curl_url_cleanup` — suffix **`_cleanup`**, not in my list |
| curl | `struct curl_slist` | `curl_slist_free_all` — suffix `_free_all` |
| zlib | `z_stream` | **three**: `deflateEnd`, `inflateEnd`, `inflateBackEnd` — which one depends on which `*Init` created it |
| raylib | `Texture2D`, `Image`, `Shader`… | `UnloadTexture`, `UnloadImage`… — a **prefix**, and the structs are passed **by value** |
| raylib | `FilePathList` | **two**: `UnloadDirectoryFiles`, `UnloadDroppedFiles` — which one depends on which function produced it |

Four findings:
1. **Every library has its own vocabulary.** A suffix list is a list of the
   libraries we happened to look at.
2. **The main handle of SQLite has two candidates.** The rule fails on the
   first library anyone will try.
3. **The destructor belongs to the constructor, not to the type.** zlib has one
   type and three destructors; raylib's `FilePathList` has two. Ownership is a
   fact about *which function produced the value*.
4. **A type can be owned in one place and borrowed in another**
   (`sqlite3_value`). A per-type rule would attach `Drop` to borrowed values
   and double-free.

Finding 3 is what Swift encodes and I had missed: it puts
`SWIFT_RETURNS_RETAINED` / `SWIFT_RETURNS_UNRETAINED` on each *function*, in
addition to naming retain/release on the *type*.

### 4.3 What the reference languages do

| Language | How the destroy function is known | Calling C gated? |
|---|---|---|
| **Swift** | **Stated by annotation on the header**, per type *and* per function | no, unless `-strict-memory-safety` |
| **Rust** | **Written by hand**: newtype + `impl Drop` | every call is `unsafe` |
| **Go** | **Written by hand** at each use: `defer C.free(...)`, a `Close` method | partial (`unsafe.Pointer` for conversions) |
| **Zig** | **Written by hand** at each use: `defer x.deinit()` | no `unsafe` concept at all |
| **Mojo** | **Written by hand**: struct with `__deinit__` | no (`unsafe_` naming convention only) |
| **Scala 3** | No C interop in tree. Nearest: `Releasable[R]` typeclass names the release function for JVM resources | n/a |
| **Vale** | **Written by hand**, but the compiler **enforces that a destructor is called** | no (`unsafe` is an inert token) |

Details and citations:

- **Swift.** `SWIFT_SHARED_REFERENCE(retain, release)` expands to
  `swift_attr("retain:incRef")` / `swift_attr("release:decRef")`
  (`docs/CppInteroperability/UserManual.md:22-25`). Per function:
  "`SWIFT_RETURNS_RETAINED` means the FRT is returned as an owned object (+1)",
  "`SWIFT_RETURNS_UNRETAINED` ... unowned (+0)"
  (`userdocs/diagnostics/foreign-reference-type.md:16-17`). The compiler
  **hard-errors** on bad evidence: "cannot find %select{retain|release}0
  function", "multiple functions '%1' found; there must be exactly one",
  "must have exactly one argument of type '%2'"
  (`include/swift/AST/DiagnosticsClangImporter.def:266-278`). When ownership
  of a return cannot be established it warns: "cannot infer ownership of
  foreign reference value returned by" (`:298-300`). Its own docs concede:
  "Currently reference types must be immortal (never deallocated) or have
  manually managed lifetimes" (`UserManual.md:9`). Sidecar `.apinotes` with
  ownership keys: **not found in tree** (the two vendored files carry only
  names, availability, nullability); I believe newer Clang supports
  `SwiftRetainOp`/`SwiftReleaseOp` there **(unverified)**.
- **Rust.** `OwnedFd` / `BorrowedFd<'fd>` is std's own answer to "a raw handle
  as a safe owned value": "A type that owns its file descriptor should usually
  close it in its `drop` function" (`library/std/src/io/mod.rs:243-249`);
  "a safe function that takes a regular integer, treats it as a file
  descriptor, and acts on it, is *unsound*" (`:258-260`). `impl Drop for
  OwnedFd` calls `libc::close` by hand (`os/fd/owned.rs:200-220`). Taking
  ownership is `unsafe fn from_raw_fd` with a prose precondition
  (`:180-194`). Nomicon FFI chapter, `bindgen`, the `-sys` convention:
  **not found in tree** (unpopulated submodules).
- **Go.** "It is the caller's responsibility to arrange for it to be freed,
  such as by calling C.free" (`src/cmd/cgo/doc.go:277-285`). Finalizers are
  not an answer by Go's own account: "There is no guarantee that finalizers
  will run before a program exits" (`src/runtime/mfinal.go:370-379`), and they
  caused a real use-after-close bug class (`:407-415`).
- **Zig.** "It is the Zig programmer's responsibility to ensure that a pointer
  is not accessed when the memory pointed to is no longer available"
  (`doc/langref.html.in:6548-6552`); ownership is "the documentation for the
  function should explain who 'owns' the pointer" (`:6553-6558`). `fopen` and
  `fclose` are two unrelated adjacent lines in `lib/std/c.zig:10652-10653`.
  One useful detail: translate-c renders a pointer to an **opaque** type as
  `?*T`, not `[*c]T` (`translate-c/src/Translator.zig:1242-1250`) — opaque
  pointee is a real, header-derived signal that the value is a handle.
- **Mojo.** "C has no origins, no ownership, and no type information Mojo can
  read ... That makes you the type checker" (`docs/manual/c-ffi.mdx:608-615`).
  `OwnedDLHandle.__deinit__` is a hand-written `dlclose`
  (`stdlib/std/ffi/__init__.mojo:319-324`). It offers the Higher-RAII
  analogue: `Deinitable where False` disables implicit destruction, and "The
  compiler verifies that a deinitializer is called for each explicitly
  destroyed value" (`docs/manual/lifecycle/death.mdx:329-332`).
- **Scala 3.** No Scala Native, Panama or JNI in the tree. `Releasable[-R]`
  with `def release(resource: R): Unit` (`library/src/scala/util/Using.scala:440-455`)
  is the only *declarative, compiler-resolved* "this is the destructor for this
  type" in any of the seven trees — and it is not for C.
- **Vale** (closest to With's ownership model). The handle is an integer field
  in a hand-written struct (`stdlib/src/command/command.vale:9-13`) and the
  destructor is a hand-written consuming method:
  `func join(self Subprocess) int { ... destroy(self.handle); ... }`
  (`:195-199`). What is unique is **enforcement**: when an owned value leaves
  scope the typing pass resolves `drop` and **fails compilation if none
  exists** (`Frontend/TypingPass/.../DestructorCompiler.scala:42-48`).
  `Subprocess` deliberately has no `drop`, so it cannot be discarded silently:
  that is Higher RAII, observable in the code (the term itself is **not found
  in tree** as prose). Vale's own notes concede the boundary is weak: "The
  programmer has to manually track the lifetimes anyway"
  (`docs/old/Externs and Regions.md:312-314`).

**Reading.** Six of seven write the destructor by hand, at every use or once
per wrapper. Only Swift states it declaratively next to the C API and gets
user code that needs no `unsafe`. **No reference language infers it.** Swift's
failure mode is permissive (unannotated ⇒ leak or `Unmanaged`); Rust's is
closed (there is no import path that skips the wrapper). Vale alone makes
"you must destroy this" a compile error.

### 4.4 The options

**1A. Infer per type, by name suffix.** *(my original recommendation)*
The compiler picks the one function matching a suffix list.
- For: zero characters for the user (M2).
- Against: §4.2 refutes it on the first library. A name is not one of M3's
  forcing sources ("types, scope, a header, an ABI, a proof"); it is a
  convention. D47 already calls inference from names "unsound". A wrong guess
  makes `Drop` call the wrong function, silently. Attaches `Drop` to borrowed
  values (`sqlite3_value`). **Fails M3 and M5.**

**1B. Stated once in the import, as a constructor → destructor pairing.**
In the user's source, beside `retains:`, e.g.
`owns: ["sqlite3_open -> sqlite3_close", "sqlite3_prepare_v2 -> sqlite3_finalize"]`.
- For: two meanings remain (which destructor; owned or borrowed), so M4 says
  the programmer spells it, once per library. D4 is accepted precedent for
  this exact place and shape. Pairing by *constructor* fits zlib and raylib.
  Verifiable like Swift: the compiler can hard-error if the named function does
  not exist, is ambiguous, or does not take exactly that handle.
- Against: every library costs the user a line per handle kind until someone
  shares it. Strings inside a list are stringly typed. The user must read the
  C docs (they must anyway; M6 is about the *build system*, not the API).
- **Passes M3/M4/M5.** Costs some M2.

**1B′. The same facts as a With declaration instead of strings.** e.g.
```
use c_import("sqlite3.h", link: "sqlite3")
handle sqlite3      from sqlite3_open       drop sqlite3_close
handle sqlite3_stmt from sqlite3_prepare_v2 drop sqlite3_finalize
```
- For: checked syntax, named in diagnostics, go-to-definition works; reads as
  a statement about the library. Same mission fit as 1B.
- Against: new surface syntax, which is a larger spec change than a new key on
  an existing attribute. Spelling is entirely open.

**1C. Read annotations from the C header when present** (Swift's route:
`__attribute__((swift_attr("release:…")))`, or a With-specific attribute).
- For: M3 literally says "forced … by a header". Zero user characters when a
  vendor has done it. Composes with any other option as an extra source.
- Against: no C library ships With annotations, and almost none ship Swift's.
  We do not own `sqlite3.h`. On its own it solves nothing today.

**1D. Sidecar evidence shipped by the toolchain or by `with get` packages.**
- For: zero user characters; Swift's apinotes and GObject-introspection are
  precedents **(unverified)**; §16.3c already lists it as a source.
- Against: D46 and D47 record this as rejected upkeep ("we cant be writing
  special case code for every conan package"). Someone has to write and
  maintain it per library; if that someone is us, it does not scale; if it is
  nobody, it does not exist. See the tension flagged in §3.
- A narrower form survives: the **curated libc overlay** already exists and is
  a bounded, one-time list (C standard library only).

**1E. Prove it from the C source**, when `with get` built the library from
source (D46 builds from source; D47 names this "a later refinement"). The
compiler analyses `sqlite3_close`'s body: does it free its argument?
- For: the only option where ownership is "forced … by a proof" (M3) with zero
  user characters, and M7 says With pays compiler complexity to remove
  ceremony.
- Against: unavailable for binary-only and system libraries (the macOS SDK's
  SQLite, anything prebuilt). Whole-program C analysis through function
  pointers, custom allocators and reference counts (`sqlite3_close_v2`) is a
  research-grade effort. It cannot tell "frees" from "frees unless still in
  use". Could not be the only source.

**1F. Infer when the pairing is structurally forced; state otherwise.**
A hybrid: inference is allowed only when the *header's structure*, not its
names, leaves one answer — for example the type is opaque (Zig's signal),
exactly one function produces an `X *` and exactly one function takes an
`X *` and nothing else. Otherwise 1B applies and the diagnostic prints the
line to write.
- For: recovers M2 for small, clean libraries without leaning on names.
- Against: "takes exactly one `X *`" also matches `sqlite3_step`,
  `sqlite3_reset`, `sqlite3_changes`. Without names there is rarely exactly
  one candidate, so in practice this rule almost never fires, and when it does
  it is still a guess about meaning (M5). I could not make it both useful and
  principled.

**1G. No modeling: the user writes the wrapper.** (Rust, Go, Zig, Mojo, Vale.)
- Against: ruled out on 2026-09-20. Listed so the record is complete.

**Fallback, common to every option: fail closed.** Where no evidence is
established the type stays raw, exactly as today. Swift does the same: when a
lifetime dependence cannot be established the importer adds an implicit
`@unsafe` rather than guessing (`lib/ClangImporter/ImportDecl.cpp:4596-4608`).
**And never half-model**: a safe constructor with no `Drop` (today's §16.2a
state) is an accidental leak, which M8 forbids. Either a handle has a known
destructor and is fully owned, or it is raw.

### 4.5 Shapes this decision does not yet cover

The headers show three handle shapes. The options above are about the first.
1. **Opaque pointer** (`sqlite3 *`, `CURL *`, `FILE *`): constructor returns
   or out-params a pointer; destructor takes it.
2. **Caller-allocated, initialized in place** (zlib `z_stream`): the user owns
   the struct's storage; `inflateInit(&s)` … `inflateEnd(&s)`. The "handle" is
   a struct the user declares, and the destructor depends on the initializer.
3. **By-value struct wrapping a resource id** (raylib `Texture2D`): Copy in C,
   yet it names a GPU object that `UnloadTexture` releases.
Shapes 2 and 3 need their own rulings later. A pairing keyed on the
*constructor* (1B/1B′) extends to them; a rule keyed on the *type* does not.

### 4.6 Recommendation and prediction

**Recommend 1B now, with 1C as an additional source, and 1B′ as the syntax
question to settle separately.** State the pairing once per library in the
import; verify it as strictly as Swift does; fail closed otherwise. Keep the
curated libc overlay (the bounded part of 1D). Treat 1E as a later refinement,
as D47 already does.

I withdraw 1A. It is the option I recommended verbally, and the header survey
and D47's own words both reject it.

**Prediction (70%).** Eric takes 1B's substance and dislikes the string list,
pushing toward 1B′ or something shorter. The risk to my prediction: he may
hold that *any* per-library line violates M6/M2 and want 1E pursued first.

---

## 5. Decision 2 — Constructors that return a status and hand back the handle through an out-parameter

### 5.1 The question

`int sqlite3_open(const char *path, sqlite3 **out)`. The handle arrives through
the last parameter; the return value is a status. How does With surface this,
and how does it know which status means success?

### 5.2 What real libraries do

- SQLite: `0` (`SQLITE_OK`) is success — but `sqlite3_step` returns `100`
  (`SQLITE_ROW`) and `101` (`SQLITE_DONE`), both non-zero and neither an error.
- SQLite hands back a **non-null handle on failure**, which must still be
  closed.
- POSIX: `-1` means failure and the code is in `errno`. pthreads: `0` is
  success and the return value *is* the error code. `getaddrinfo`: its own
  code space. (See Rust below: std needs a separate adapter for each.)
- Many constructors return the handle directly and signal failure with `NULL`
  (`fopen`, `curl_easy_init`).

### 5.3 What the reference languages do

| Language | Which integer means success | Out-parameter handling |
|---|---|---|
| **Swift** | **Stated per function** (`swift_error(...)`), two values **defaulted from the return *type*** | only for `NSError **`; plain `T **` stays a raw pointer |
| **Rust** | **Hand-picked per call site** among several hard-coded adapters | `MaybeUninit`, by hand |
| **Go** | **Stated by hand** at the call site; errno offered as a sidecar | `&var`, by hand |
| **Zig** | **Stated by hand**, one exhaustive `switch` per function | `[*c][*c]T`, by hand |
| **Mojo** | **Stated by hand** (`!= 0`, `< 0`) | `Pointer(to=local)`, by hand |
| **Scala 3** | not found in tree | not found in tree |
| **Vale** | **Stated by hand**; and Vale has **no out-parameters across FFI at all** | returns the handle, `0` as sentinel |

- **Swift** has the only declarative mechanism, and it is instructive in both
  directions. The four conventions, verbatim
  (`docs/CToSwiftNameTranslation.md:425-430`): `swift_error(nonnull_error)`;
  "`swift_error(null_result)` (default for Optional return types)";
  "`swift_error(zero_result)` (default for `BOOL` and `Boolean`)";
  `swift_error(nonzero_result)`. **The two defaults are keyed on the return
  *type*, not on a guess about a plain `int`** — for an `int` return the
  attribute is written (`test/Inputs/clang-importer-sdk/usr/include/errors.h:47,49`).
  And the whole mechanism applies only to a trailing `NSError **`: the
  importer literally compares the class name
  (`lib/ClangImporter/ImportType.cpp:1504-1507`). A `sqlite3_open`-shaped
  function gets no help: **not found in tree**.
- **Rust** shows why one default cannot work. std carries at least four
  adapters, chosen by hand at each call: `cvt` — "*-1 means error is in
  `errno`*" (`library/std/src/sys/pal/unix/mod.rs:238-242`); `cvt_nz` — "Zero
  means `Ok()`, all other values are treated as raw OS errors. Does not look
  at `errno`" (`:259-261`); `cvt_gai` for getaddrinfo
  (`sys/net/connection/socket/unix.rs:36`); and an `IsNegative` variant on
  Hermit (`sys/pal/hermit/mod.rs:107`). Nothing checks the pick.
- **Go** states the trap outright: "the C errno value may be non-zero, and
  thus the err result may be non-nil, even if the function call is successful.
  Unlike normal Go conventions, you should first check whether the call
  succeeded" (`src/cmd/cgo/doc.go:212-221`).
- **Zig**: `grep -c "switch (errno(" lib/std/posix.zig` → **46** hand-written
  switches, each beside a hand-written error set (`posix.zig:540-561`).
- **Vale**: `handle = launch_command(...)`; `if handle == 0i64 { return Err(...) }`
  (`stdlib/src/command/command.vale:70-76`), and a hand-written code table that
  `panic`s on an unknown code (`stdlib/src/path/path.vale:251-259`).

**Reading.** Nobody infers the success value. Nobody defaults it for a plain
integer. The one language that defaults at all does so only where the return
*type* already carries the meaning (`BOOL`, Optional).

### 5.4 The options

**2A. `Result[X, i32]` with `0` assumed to mean success, overridable.**
*(my original recommendation)*
- For: shortest surface; true for sqlite, curl, zlib, pthreads.
- Against: success versus failure are two *meanings*, and M5 says "a default
  never selects between meanings". False for every `-1`/errno API, and false
  inside SQLite itself (`sqlite3_step`). Rust's four adapters are direct
  evidence that no single default holds. A wrong default turns an error into a
  success silently. **Fails M5 by its own words.**

**2B. Success is stated with the constructor evidence.** The same line that
pairs constructor and destructor says what success is:
`"sqlite3_open -> sqlite3_close, ok: SQLITE_OK"`.
- For: M4 — two meanings remain, the programmer spells it, once. It names the
  library's own constant rather than a magic number. No new mechanism: it
  rides on Decision 1's evidence. Matches Swift's per-function statement.
- Against: more to write per constructor. A constructor whose line omits `ok:`
  must then be one of 2C or raw; that fallback needs choosing too.

**2C. No interpretation: surface both values.** The constructor returns the
status and the handle together; the user compares.
- For: never wrong; no evidence needed beyond Decision 1.
- Against: the handle may be null on failure, so the handle's type would have
  to be `Option[X]`, and every constructor call grows a two-step check — C's
  ceremony reproduced in With (M1, M2). For SQLite the failed-but-non-null
  handle must still be closed, which ownership handles correctly.

**2D. Infer success from the header's constants** (the one macro/enum named
`*_OK` / `*_SUCCESS`).
- Against: name inference again (D47: "unsound"; M3 does not list names). Says
  nothing about `-1`/errno libraries, which define no `OK` constant.

**2E. Use null-ness of the handle as the failure signal, ignore the integer.**
- Against: wrong for SQLite, which returns a non-null handle on failure; the
  error code, which is the information the user needs, is discarded.

**2F. A library-wide status convention**, stated once:
"in this header, an `int` return is a status and `SQLITE_OK` is success".
- For: one line per library instead of one per function.
- Against: `sqlite3_step`'s `SQLITE_ROW`/`SQLITE_DONE`, and every function
  whose `int` is a count (`sqlite3_changes`, `sqlite3_column_count`). A
  library-wide rule misreads them. It would need an exception list, which is
  per-function statement by another route.

**2G. Leave status-returning constructors raw; only pointer-returning
constructors are modeled.**
- Against: the out-parameter form is the common one (§5.2); the user is back
  to `unsafe` for the first call of nearly every library. Violates D47.

**Independent of the choice: the out-parameter itself.** That a trailing
`X **` on a function paired as a constructor *is* the produced handle is
forced by Decision 1's evidence (the function was named as the constructor of
`X`). That part is M3, not M5, and needs no separate statement.

### 5.5 Recommendation and prediction

**Recommend 2B.** I withdraw 2A: the mission text rules it out in so many
words, and Rust's standard library is a working demonstration of why.
With 2B, a constructor paired without an `ok:` is modeled as 2C (both values)
rather than guessed.

**Prediction (75%).** Eric takes 2B. The open part is the fallback for a
constructor with no stated success value: 2C, or refuse to model it at all.

---

## 6. Decision 3 — A child handle must not outlive its parent

### 6.1 The question

A prepared statement must not outlive its connection. How is that expressed?

### 6.2 Established by running it (not by reasoning)

With already expresses this completely. With
`type Stmt = ephemeral { db: &Db, n: i32 }` and `Drop` on both, the installed
compiler:
- drops children before the parent (`finalize stmt 20`, `finalize stmt 10`,
  `close db 1`);
- rejects returning a child past its parent: "returned ephemeral value may
  outlive its origin 'db'";
- rejects moving the parent while a child lives: "implicit drop of `s` uses
  `&db` after `db` is destroyed (§21.1 Rule 7)";
- rejects storing the child in an ordinary struct: "ephemeral type 'Stmt'
  cannot be stored in non-ephemeral struct".

So no new language is needed. The decision is only **how the compiler learns
that one handle depends on another**, and what that costs the user.

### 6.3 What the reference languages do

| Language | Enforcement | How it is expressed |
|---|---|---|
| **Rust** | **compile time** | lifetime parameter + `PhantomData<&'a Parent>`, **written by hand** |
| **Swift** | **compile time**, experimental | `~Escapable` + `@lifetime`, **stated by annotation** in the header |
| **Scala 3** | **compile time**, experimental | capture checking (`T^`); not for C |
| **Mojo** | **compile time *if* the origin is written**; otherwise programmer's job | `Pointer[T, origin_of(parent)]` |
| **Go** | **run time** | hand-written refcounts, mutexes, sentinel errors |
| **Vale** | **run time** | generation check at every dereference |
| **Zig** | **programmer's responsibility** | documentation prose |

- **Rust.** `pub struct BorrowedFd<'fd> { fd: ValidRawFd, _phantom:
  PhantomData<&'fd OwnedFd> }` (`library/std/src/os/fd/owned.rs:48-54`): "This
  has a lifetime parameter to tie it to the lifetime of something that owns
  the file descriptor" (`:30-32`). Notably std makes `ReadDir` and
  `ChildStdin` **owned, not borrowed** (`fs.rs:216`, `process.rs:314-316`): it
  uses a lifetime only where the child truly cannot outlive the parent.
- **Swift.** "functions require a `@_lifetime` annotation when they return a
  non-Escapable type" (`docs/ReferenceGuides/LifetimeAnnotation.md:7`); from
  C++ the source is `[[clang::lifetimebound]]`
  (`test/Interop/Cxx/class/nonescapable-lifetimebound.swift:60`). **It fails
  closed**: an unannotated nonescapable return is imported `@unsafe`
  (`lib/ClangImporter/ImportDecl.cpp:4596-4608`). Still experimental:
  "lifetimebound not yet supported by stable feature-set"
  (`lib/ClangImporter/SwiftifyDecl.cpp:730`).
- **Scala 3.** The rejected program and its error are in
  `docs/_docs/reference/experimental/capture-checking/basics.md:39-71`; the
  docs draw the Rust analogy themselves (`scoped-capabilities.md:443-448`).
- **Mojo** has the exact C case: "When a C function returns a pointer into its
  own library, the return type must borrow from the handle, as in
  `Pointer[c_char, lib_origin]` ... Declaring `ImmStaticOrigin` compiles, then
  reads freed memory once the handle closes the library"
  (`docs/manual/c-ffi.mdx:671-676`). Enforcement exists only if the programmer
  writes the right origin.
- **Go.** `Stmt` holds `db *DB`; misuse is a returned error:
  `errors.New("sql: statement is closed")` (`src/database/sql/sql.go:2727-2731`).
  The library pays for this with hand-written mutexes and a `parentStmt`
  back-reference (`:2624-2630`, `:2943-2956`).
- **Vale.** `buildCheckGen` emits a comparison and an assert at each
  dereference, aborting with "Invalid generation, from the future!"
  (`Backend/src/region/common/common.cpp:192-209`). This is the sharpest
  difference from With: Vale proves *destroyed exactly once* at compile time
  and *not used after destruction* at run time. With proves both at compile
  time.
- **Zig.** `doc/langref.html.in:6548-6552`, quoted in §4.3.

### 6.4 The options

**3A. Infer the parent from the constructor's signature.** A constructor that
takes an owned handle `P` and produces an owned handle `C` makes `C` ephemeral
over `&P`. *(my original recommendation)*
- For: zero user characters; the dependent reading is the safe one; the
  compile-time proof already works.
- Against: two meanings do remain. `sqlite3_prepare_v2(db, …)` produces a
  **dependent** child; `curl_easy_duphandle(CURL *)` produces an
  **independent** handle. Inferring "dependent" for both is a default between
  meanings (M5). It is wrong *safely* — it over-restricts rather than
  corrupts — but it would forbid a legitimate program with no way to say
  otherwise unless an override exists.

**3B. Stated in the evidence.** The constructor's line names the parent:
`"sqlite3_prepare_v2 -> sqlite3_finalize, in: sqlite3"`.
- For: M4. Independent constructors simply do not say `in:`. Handles with two
  parents (`sqlite3_backup_init(dest, …, src, …)`) are expressible.
- Against: one more clause to write; forgetting `in:` yields an *unsound*
  independent child — the unsafe direction. So the default when unstated must
  not be "independent".

**3C. Infer dependent, state independence.** 3A as the rule, plus an explicit
way to say a produced handle is independent of a handle argument.
- For: the unstated case is the safe one; the programmer spells only the
  exception (`curl_easy_duphandle`). Forgetting costs a compile error, never
  memory safety.
- Against: still a default between two meanings (M5), though arguably of the
  kind every safe language makes: absent evidence, assume the restrictive
  reading. It needs Eric to say whether "the safe reading when a meaning is
  unstated" counts as a forbidden default. Swift's fail-closed precedent is the
  same move.

**3D. Run-time check** (Vale's generations, Go's "statement is closed").
- Against: With has already chosen compile-time proof for its own types; a
  check per call is a cost and turns a compile error into a crash (M1).

**3E. The child keeps the parent alive** (hidden reference count);
`sqlite3_close_v2` exists for exactly this in garbage-collected languages.
- Against: hidden reference counting is one of the things With rules out; the
  parent's `Drop` would no longer run where the source says.

**3F. No relation; trust the library.**
- Against: unsound for nearly every library. SQLite's `sqlite3_close` refuses
  with `SQLITE_BUSY` while statements remain, and the handle then leaks (M8).

### 6.5 A cost that every compile-time option carries

An ephemeral child cannot be stored in a long-lived struct. The natural
application shape —

```
type App { db: Database, insert: Statement }   // rejected
```

— is self-referential and With forbids it, as Rust does. This is a real
restriction users will meet on day one: caching prepared statements is the
most common SQLite pattern. The Rust ecosystem's answer is a statement cache
owned *by the connection* **(unverified)**. With's answer would be the same
idea or handles into the connection (§7 of the primer: "Relationships are
handles"). It does not block the ruling, but it should be ruled on with eyes
open, and the example must show the idiom.

### 6.6 Recommendation and prediction

**Recommend 3C**, and ask Eric to rule explicitly on the M5 question it
raises. If he holds that M5 forbids it, the answer is **3B with the unstated
case refusing to model the constructor** (fail closed), never "independent".

**Prediction (65%).** Eric accepts 3C on the ground that the restrictive
reading is not a *choice between meanings* the user cares about but the absence
of a proof, consistent with how With treats views everywhere else. The lower
confidence reflects that M5 is recent text and he may read it strictly.

---

## 7. Decision 4 — A `char *` that C returns

### 7.1 The question

`const char *sqlite3_errmsg(sqlite3 *)`. Today a pointer return makes the
whole function raw. What does With hand the user: a copied `str`, a borrowed
view, or a raw pointer? And how is `NULL` represented?

### 7.2 What real libraries do

- `sqlite3_errmsg(db)`: valid until the next call on `db`. Borrowed, tied to a
  handle.
- `sqlite3_column_text(stmt, i)`: `const unsigned char *`, valid until the
  next `step`/`reset`/`finalize`; `NULL` for a NULL column — `NULL` is
  *information*.
- `getenv`, `strerror`: no handle at all; the result is static or library
  storage.
- `sqlite3_mprintf(...)`: **non-const** `char *` the caller must release with
  `sqlite3_free`. `strdup`: released with `free`.
- The bytes are not guaranteed to be UTF-8.

So there are at least four distinct cases: *borrowed from a handle argument*,
*static or library-owned*, *owned by the caller with a named deallocator*, and
*not text at all*.

### 7.3 What the reference languages do

| Language | Copy or borrow | Gate | `NULL` |
|---|---|---|---|
| **Swift** | import is a raw pointer; `String(cString:)` **copies**, explicitly | not `unsafe` by default | `Optional` only if the header says `_Nullable`; **unannotated ⇒ implicitly-unwrapped, a nil is a runtime trap** |
| **Rust** | `CStr::from_ptr` **borrows**; `to_str` borrows; owning is explicit | `unsafe` | not representable in `CStr`; checked by hand |
| **Go** | `C.GoString` **copies**, implicitly | none | **`NULL` silently becomes `""`**, undocumented |
| **Zig** | `std.mem.span` **borrows**, no copy | none | not in the type; `span` **asserts non-null** |
| **Mojo** | `String(unsafe_from_utf8_ptr=)` **copies**, explicitly; `Span` borrows | `unsafe_` naming only | `Optional[Pointer[...]]` |
| **Scala 3** | not found in tree | — | — |
| **Vale** | **copies always**, both directions, by design | none | not specified |

- **Swift.** Unannotated pointers become `UnsafePointer<T>!`
  (`docs/HowSwiftImportsCAPIs.md:508-512`), and "Unwrapping a `T?` or a `T!`
  optional that contains nil is a fatal error" (`:440-442`). Swift explains
  why: "C APIs do not provide this information in a machine-readable form"
  (`:444-450`). `String(cString:)`: "Creates a new string by copying the
  null-terminated UTF-8 data" (`stdlib/public/core/CString.swift:19-20`);
  ill-formed UTF-8 is **repaired** with U+FFFD (`:22-24`), with a validating
  variant at `:185`.
- **Rust.** `CStr::from_ptr`'s `# Safety` section
  (`library/core/src/ffi/c_str.rs:195-213`) requires a valid terminator,
  validity for reads, a single allocation, "`ptr` must be non-null even for a
  zero-length cstr", and no mutation for `'a`. **The lifetime is stated by
  nobody**: "The lifetime for the returned slice is inferred from its usage.
  To prevent accidental misuse, it's suggested to tie the lifetime to whichever
  source lifetime is safe in the context" (`:215-220`). Taking ownership of a
  C-allocated string "is likely to lead to undefined behavior or allocator
  corruption" (`library/alloc/src/ffi/c_str.rs:361-362`).
- **Go.** "A few special functions convert between Go and C types by making
  copies of the data" (`src/cmd/cgo/doc.go:277-278`). The copy is in
  `src/runtime/string.go:377-385`; `findnull` returns 0 for nil (`:488-491`),
  so `C.GoString(nil)` is `""` — indistinguishable from an empty string.
- **Zig.** `span`: "`[*c]` pointers are assumed to be non-null and
  0-terminated" (`lib/std/mem.zig:902-906`), enforced by `assert(value !=
  null)` (`:1116`), which is compiled out in unsafe build modes.
- **Mojo.** `"# Copy the data."` in the constructor itself
  (`stdlib/std/collections/string/string.mojo:557-578`); the `getenv` example
  wraps the return in `Optional` (`docs/manual/c-ffi.mdx:563-570`): "A Mojo
  `Pointer` can't be null, so wrap any 'maybe null' return in `Optional`"
  (`:553-555`).
- **Vale.** "We could only copy things to and from the outside world. This
  makes Vale immune to any problems in C land"
  (`docs/old/Externs and Regions.md:353-364`). Strings cross as a
  length-prefixed `ValeStr`, never as `const char *`
  (`Backend/builtins/ValeBuiltins.h:9-10`).

**Reading.** The field splits: Go and Vale copy implicitly; Swift and Mojo
copy explicitly; Rust and Zig borrow. **Every language that borrows leaves the
lifetime unstated**, and Rust's own docs call that a hazard. Go and Zig show
what goes wrong when `NULL` is not in the type: Go loses it, Zig crashes on it.

### 7.4 The options

**4A. Copy implicitly into `Option[str]`.** *(my original recommendation)*
- For: the user never meets a lifetime; §16.3c already says a nullable C
  string return "is modeled as `Option[str]`"; safe for every one of the
  borrowed and static cases in §7.2.
- Against: it allocates, and D45 says "an allocating copy is spelled". Whether
  a boundary conversion is the kind of copy D45 means is Eric's to say: D45's
  reasoning is cost visibility ("close to the machine"), which applies here
  too. A loop over `column_text` allocates per row invisibly. It also forces a
  UTF-8 decision at the boundary (see 7.5).

**4B. A borrowed view tied to the handle argument.** A function that takes a
modeled handle and returns `const char *` returns a view whose origin is that
handle. The user spells the copy when they want to keep it:
`db.errmsg()?.to_str()`.
- For: zero-cost, D45-consistent, and With can do what Rust cannot: its
  view-liveness analysis already invalidates a view when its origin is
  mutated, which is *exactly* SQLite's contract ("valid until the next call").
  The lifetime that Rust leaves unstated is stated by the signature.
- Against: depends on Decision 1 (there must be a modeled handle to borrow
  from). Whether each later call on the handle counts as a mutation needs the
  methods' receiver modes to be right (`mut fn` versus `fn`), which the header
  does not say either — `const sqlite3 *` versus `sqlite3 *` is a hint, not a
  proof. Says nothing about functions with no handle (`getenv`).

**4C. Borrow where there is a handle to borrow from; copy where there is
none.** `errmsg(db)` is a view of `db`; `getenv(name)` copies.
- For: each case gets the cheapest sound answer.
- Against: two behaviours for one C type; the user must know which they got
  (the type says so: a view versus a `str`). The no-handle copy still meets
  D45.

**4D. Stay raw; the user calls `CStr.from_ptr` in `unsafe`.** (Today, after
PR #1232.)
- Against: violates D47's "an application developer never writes `unsafe`".

**4E. Owned C text with a named deallocator.** For a non-const `char *` the
caller must free (`sqlite3_mprintf` → `sqlite3_free`), state the pairing with
Decision 1's machinery; the result is an owned value whose `Drop` calls the
library's deallocator.
- For: reuses Decision 1; covers the case every other option leaves raw;
  prevents the leak (M8) and the allocator mismatch Rust warns about.
- Against: only as good as Decision 1's evidence; a non-const `char *` with no
  stated deallocator must stay raw.

**4F. Text versus bytes is stated, never assumed.** A `const char *` return is
text only if evidence says so.
- Against: almost every `const char *` return *is* text; this makes the common
  case cost a line. But see 7.5: "is it UTF-8" is the real question hiding
  here.

### 7.5 Two sub-questions any option must answer

1. **`NULL`.** All evidence points one way: it must be in the type
   (`Option`). Go's silent `""` and Zig's assert are the cautionary cases, and
   Swift's trap-on-nil default exists only because C headers lack nullability
   information. §16.3c already says "Null is information". I treat this as
   settled and not a decision.
2. **Bytes that are not UTF-8.** A With `str` is UTF-8. C text need not be.
   Swift repairs silently; Rust's `to_str` returns a `Result`; §16.3c already
   forbids With to "silently transcode". A borrowed `CStr` view makes no UTF-8
   claim, and the conversion to `str` is where validation happens — another
   point in favour of 4B/4C, where that conversion is a visible call.

### 7.6 Recommendation and prediction

**Recommend 4C plus 4E**, with `NULL` always `Option`. I withdraw 4A as the
default: D45 is a standing ruling against an invisible allocating copy, and
With's view-liveness makes the borrow *sound*, which no reference language
achieves. The spec sentence in §16.3c ("modeled as `Option[str]`") would then
need Eric's attention, since it describes 4A.

**Prediction (60%).** Eric takes the borrowed view for the handle case. My
uncertainty is whether he judges a boundary copy to fall under D45 at all; if
he says it does not, 4A stands and the spec already says so.

---

## 8. How the four fit together

- **One evidence statement per constructor** carries everything: what it
  produces, what destroys it (D1), what success is (D2), what it depends on
  (D3). A deallocator for returned text (D4E) is the same statement.
- **One normative home.** §16.2a today describes the owning wrapper and
  §16.3c describes evidence sources; the rulings should land as one rule, not
  two.
- **Fail closed, and never half-model.** No evidence ⇒ the type stays raw.
  Evidence ⇒ fully owned with `Drop`. The current in-between state leaks.
- **Verification.** Evidence is checked the way Swift checks it: the named
  function must exist, be unique, and have the right shape, or it is a compile
  error. `with analyze` should print the evidence table in force, so a user
  can see what the compiler believes about a library.

**What is *not* being decided here:** the surface syntax (1B string list versus
1B′ declaration), borrowed handles returned by C (`sqlite3_db_handle`), the
in-place and by-value handle shapes (§4.5), and method receiver modes for
imported functions.

---

## 9. What changed from my verbal recommendations

| Decision | I said | I now recommend | Why it changed |
|---|---|---|---|
| 1 | infer by name suffix when one candidate | **state the constructor → destructor pairing once in the import** | SQLite's main handle has two candidates; curl, zlib and raylib each use different vocabulary; the destructor belongs to the constructor, not the type; D47 already calls name inference unsound |
| 2 | default `0` means success | **state success with the constructor** | M5: "a default never selects between meanings"; Rust's std needs four adapters; `sqlite3_step` returns 100 and 101 on success |
| 3 | infer the parent from the signature | **infer dependent, state independence** — and rule on M5 | `curl_easy_duphandle` is an independent child; the unstated case must be the safe one |
| 4 | copy into `Option[str]` | **borrow from the handle where there is one; copy otherwise; owned text with a named deallocator** | D45; With's view-liveness makes the borrow sound, which no reference achieves |

I also told Eric that Swift's Core Foundation import infers ownership from
names. That is not in the vendored Swift tree (§3).

---

## 10. After the rulings

1. I draft the exact §16.2a / §16.3c wording for what was ruled; Eric blesses
   or rewrites the words. Nothing lands before that.
2. The blessed text lands as the ruling, and the compiler is non-compliant
   until it conforms.
3. Implementation unifies the two mechanisms in `src/CImport.w` (§1) into one.
4. `examples/c-interop` comes off its parked branch (`c-interop-example`) and
   is rewritten with no `unsafe`; the 28 `unsafe` uses in the zlib, bzip2,
   sqlite3 and libcurl release UAT fixtures go the same way, and
   `:user-programs-safe` goes green.

Already in flight and independent of these rulings: PR #1231 (the
`SQLITE_TRANSIENT` miscompile) and PR #1232 (five defects the example
exposed). Filed: #1229, #1230.
