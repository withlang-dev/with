# 16. FFI and C Interoperability

C interoperability is not a bolt-on feature. It is a **day-zero
requirement**. A systems language that cannot trivially use existing
C libraries — libc, OpenSSL, SQLite, Vulkan, POSIX, Win32 — is
not a systems language. It is a toy.

### 16.1 `c_import`: Automatic C Header Import

The primary mechanism for C interop is direct header import:

```
use c_import("SDL2/SDL.h")
use c_import("sqlite3.h")
use c_import("openssl/ssl.h", link: "ssl", "crypto")
```

`c_import` reads a C header file at compile time, parses it, and
makes all declarations available as With symbols. This includes:

- **Functions** → generated bindings; modeled-safe bindings are
  callable directly, raw/unmodeled ABI bindings stay explicit
- **Structs** → `@[repr(C)]` struct types
- **Enums** → integer constants or With enums
- **Typedefs** → type aliases
- **`#define` constants** → `const` values (integer and string literals)
- **Function-like macros** → not translated (warning emitted; see §16.2)

```
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    let threadsafe = sqlite3_threadsafe()   // modeled value call
    if threadsafe == 0:
        panic("SQLite must be built with mutex support")
    // Higher-level wrappers model handles, ownership, errors, and cleanup.
```

**Why no `unsafe` on every call?** The unsafe boundary is not
"foreign call." It is an unmodeled memory, ownership, or lifetime
contract. `c_import` is the opt-in for importing the C library, and
when the importer can model a function's contract sufficiently, the
generated binding is an ordinary With call. Wrapping those calls in
`unsafe {}` is ceremony without safety.

The importer's job is to import the raw ABI accurately, model every
contract it can infer, import, or prove into a safe With surface, and
refuse to present unmodeled danger as ordinary safe code. Value
parameters, value returns, safe handle wrappers, slice parameters for
buffers, `Option` for nullable returns, owned resource wrappers with
`Drop`, and `CStr`/`CString` for C string contracts are examples of
modeled surfaces that can be directly callable.

For APIs such as `memcpy`, `strcpy`, `free`, out-parameter fills,
borrowed pointer returns, ownership transfers, mutable buffers, or
other contracts the importer cannot model, the unsafe effect may be
at the call boundary. The answer is still not "all C calls are
unsafe." The answer is: generate a safe wrapper when the contract is
known, or keep the raw ABI surface explicit when it is not.

`unsafe` is still required for operations whose correctness depends on
facts the compiler cannot prove: raw pointer dereference, raw pointer
indexing that reads or writes, raw-pointer-to-reference/slice/view
conversion, allocation-relative pointer distance when same-allocation
facts are not proven, transmute, pointer-domain casts not specified as
safe validity-less raw conversions by the target model, unsafe calls,
and manual or unmodeled raw ABI calls. Raw pointer arithmetic, null
checks, raw address comparison and difference, pointer-to-address
observation, address-to-raw-pointer construction, same-domain raw
pointer relabeling, and raw-address-of operations that do not create
safe references are safe raw pointer computations; see §16.11. Calling
a modeled `c_import` binding with ordinary value arguments is just a
function call.

**Raw pointer access still needs `unsafe`:**

```
use c_import("my_lib.h")

// Modeled value call — no unsafe needed
let version = my_lib_version()

// Raw ABI call — unsafe may be needed at the call boundary
let handle = unsafe { my_lib_raw_handle() }

// Pointer dereference — unsafe required
let value = unsafe { *handle }

// Pointer arithmetic — no unsafe, because no memory is touched
let next = handle + 1
```

**Null-safe pointer conversion:** Raw pointers from C are
inherently nullable. The `.as_option()` method on raw pointers
converts them to `Option`, making null handling ergonomic:

```
// C function returns nullable pointer
let name_ptr: *const c_char = get_user_name(id)

// Convert to Option — null becomes None
let name = name_ptr.as_option()
    .map(p => CStr.from_ptr(p).to_str())
    .unwrap_or("unknown")

// Also works with ?? 
let name = ptr_to_string(name_ptr.as_option() ?? return default_name())
```

`.as_option()` is safe — it only checks for null, it doesn't
dereference the pointer. The resulting `Option[*const T]` or
`Option[*mut T]` still requires `unsafe` to dereference.

**Compiler-owned C parsing.** `c_import` uses With's compiler-owned
libclang bridge, not a random system C compiler. Release compilers
statically link the LLVM/Clang/lld SDK built by the With project, and
embed Clang's builtin resource headers. At compile time, the compiler
materializes those embedded resources to a cache and passes that
resource dir to libclang.

The normal `c_import` path parses the header with this embedded Clang
resource setup. It does not probe a system LLVM install, does not
depend on `llvm-config`, and does not invoke `cc -E` as the core
header-import mechanism.

**Target C headers are inputs.** Platform libc headers, operating
system SDKs, vendor headers, and package headers are part of the
target environment being imported. They may be supplied by the host
platform SDK, by package metadata such as `with get c.*`, by
`with.toml`, or by build target include paths. Those headers are
target inputs, not a dependency on an arbitrary host LLVM/Clang
installation.

**Cross-compilation.** The parser and Clang resource headers are
self-contained in the With compiler. Cross-target C interop requires
the target's headers, sysroot/SDK, and link libraries, but it does not
fundamentally require an external cross-compiler as a preprocessing
step. Any remaining shell-out to host tools for SDK discovery or
macro/preprocessor helper paths is an implementation gap, not a
language requirement.

**Build configuration:**

```toml
# with.toml
[c_import]
include_paths = ["vendor/include"]  # additional target header roots
```

Build targets can also contribute target-specific C import inputs:

```
target.include_path("vendor/include")
target.define("DEBUG=1")
target.link_system_lib("sqlite3")
```

**C vector types.** A `vector_size` or `ext_vector_type` type, and the
platform typedefs over them (`__m128`, `__m256i`, `float32x4_t`,
`_tile1024i`, …), import as `Vector[N, T]` (§4.3d) and print as the
alias — `__m128` as `f32x4`; `__m128i` by its definition's element type
(`i64x2` from `long long`). `ext_vector_type(3)` imports as
`Vector[3, T]`. A C mask typedef (`__mmask16`) is an integer in C and
imports as one.

### 16.2 Macro Handling

C macros that are simple constants are translated automatically:

```c
#define SQLITE_OK 0              // → const SQLITE_OK: i32 = 0
#define PATH_MAX 4096            // → const PATH_MAX: i32 = 4096
#define NULL ((void*)0)          // → recognized as null
```

Not every function-like macro can be translated automatically. C
macros are preprocessor token replacements — they do not exist in the
C AST that `libclang` parses. Translating function-like macros
requires heuristic token-stream analysis. The importer always
translates straightforward object-like `#define` constants:

```c
#define MAX(a,b) ((a) > (b) ? (a) : (b))
// → NOT translated. Compiler warning: untranslated macro MAX
// User must write: fn max[T](a: T, b: T) -> T: if a > b: a else: b
```

Complex macros (token pasting, stringification, variadic macros,
statement-expression macros) are not part of the modeled safe surface
unless the importer can prove an equivalent With expression. Users
wrap these in a thin C shim file, use the raw surface when one exists,
or write manual `extern "C"` bindings.

**Function-like macro translation:** Simple expression macros are
translated to generic functions:

```c
#define MAX(a, b) ((a) > (b) ? (a) : (b))
// → fn MAX[T](a: T, b: T) -> T: if a > b: a else: b

#define ABS(x) ((x) < 0 ? -(x) : (x))
// → fn ABS[T](a: T) -> T: if a < 0: 0 - a else: a
```

**Honest generated surface:** A generated `c_import` surface contains
only real bindings:

1. safely modeled bindings, callable as ordinary With APIs; or
2. raw ABI bindings per §16.1 when the C construct is ABI-expressible
   but not safely modeled.

An untranslatable construct is inexpressible even as a raw binding: for
example, a token-paste macro with no stable value or type meaning, a
compiler extension With cannot represent, or a type that cannot be
expressed in either the safe or raw surface. Such constructs are
omitted from the generated binding surface and recorded in the import
manifest with their name, source location, and reason. Dependent
bindings that require an omitted inexpressible construct are also
omitted and recorded with the same reason chain.

Generated bindings must never contain `comptime_error` placeholders or
any other callable/value stub that pretends an inexpressible C
construct is part of the usable With surface. `comptime_error` remains
a user-authored language feature, not a compiler-generated fallback for
failed C translation.

**Acknowledged omissions:** `allow_untranslated` names declarations,
macros, or other imported C entities that the project explicitly
accepts as unavailable. The compiler includes this allow-list in the
`c_import` cache key so changing it cannot reuse stale generated
bindings.

```
use c_import("complex_lib.h",
    link: "complex",
    allow_untranslated: ["WEIRD_MACRO", "PLATFORM_HACK"],
)
```

This is not a silent fallback. Allow-listed omissions are still omitted
and recorded as unavailable; they are not emitted as callable
placeholder APIs. Anything outside the allow-list that is
inexpressible must also be omitted and reported.

The requested surface of a bare `use c_import("h")` is the available
surface of that header under the selected platform and preprocessor
configuration. Inexpressible constructs in that surface are
partial-but-honest omissions: ordinary import reports every gap but
does not fail merely because such a construct exists. Referencing an
omitted symbol is a directional compile error that names the symbol,
why it could not be translated, and the alternative: use the raw
surface if this is a §16.1 unsafe/raw-modeling case, or accept that the
C construct has no With representation if it is genuinely
inexpressible.

Whole-import non-zero failure is reserved for:

- an explicit selective import request that names an inexpressible
  symbol;
- completeness mode (`with migrate`, or an explicit strict import flag)
  where incomplete translation is itself the error; and
- import failures such as a missing header, parse failure, unsupported
  target configuration, or toolchain crash.

**Constant expression evaluation:** `#define` macros with arithmetic
expressions, bitwise operations, casts, and references to other macros
are evaluated via the C compiler's constant evaluator:

```c
#define PAGE_SIZE 4096
#define PAGE_MASK (~(PAGE_SIZE - 1))     // → const PAGE_MASK: i32 = -4096
#define FLAGS (FLAG_A | FLAG_B | 0x10)   // → const FLAGS: i32 = evaluated_value
```

**Collision mangling:** When `c_import` encounters duplicate names
from transitive includes, numeric suffixes are appended: `name_2`,
`name_3`, etc.

### 16.2a Auto-Method Generation

When `c_import` translates a C header, the compiler detects naming
patterns like `structname_method(self, ...)` and auto-generates
method syntax so C APIs feel like native With APIs. This is sugar —
`table.insert("key", "val")` compiles to exactly
`g_hash_table_insert(table, "key", "val")`. Zero runtime cost.

```
// Raw c_import calls:
let table = g_hash_table_new(g_str_hash, g_str_equal)
g_hash_table_insert(table, "name", "Eric")
g_hash_table_destroy(table)
```

**Detection rules.** For each struct `S` from `c_import`, the
compiler converts the name to snake_case (`GHashTable` →
`g_hash_table_`) and checks if imported functions start with that
prefix. A function is a **method candidate** if its first parameter
is `*S`, `*mut S`, `*const S`, or `S`. A function is a
**constructor candidate** if it returns `*S` / `*mut S` without
taking self. The method name is the function name with the prefix
stripped:

```
g_hash_table_new       → GHashTable.new(...)      // constructor
g_hash_table_insert    → .insert(...)              // method
g_hash_table_lookup    → .lookup(...)              // method
g_hash_table_destroy   → .destroy()                // method candidate
```

**Constructor syntax.** If a type has a `.new` method, the type
name itself becomes callable: `GHashTable(args)` is sugar for
`GHashTable.new(args)`.

Auto-method generation is presentation (§16.2b.11). It groups imported
functions as methods and shortens prefixes; it establishes no ownership,
lending, destruction, dependency or lifetime fact, and it never inserts
cleanup or generates an owning wrapper. Owned C resources are modeled by a
facade (§16.2b). Name heuristics such as `prefix_free` or `prefix_unref` may
drive tooling suggestions and advisory diagnostics; they may not, by
themselves, mark a raw C value as owned.

**Opt-out.** Per-type: `use c_import("lib.h", no_methods: "Type")`.
Global: `use c_import("lib.h", no_methods: true)`. Flat C functions
are always available regardless.

**Ambiguity.** If multiple structs could claim the same function,
the longest prefix wins. If equal length, neither claims it.
User-written `impl` methods always take priority over auto-generated
ones.

### 16.2b Facades: Modeled C Ownership, Effects and Lifetimes

#### 16.2b.1 What a facade is

The raw C surface supplies ABI truth; a **facade** supplies semantic meaning.
Ownership, lifetime, mutation, retention, destruction, status, callback,
concurrency, presentation and foreign-state facts about imported C
declarations live in a facade: ordinary checked With source, scoped to the
declarations it describes.

```
use c_import("sqlite3.h", link: "sqlite3")

c facade sqlite:
    resource Database wraps *mut sqlite3
        from sqlite3_open(out param 1)
        drop sqlite3_close
        destroys sqlite3_close_v2
        ok SQLITE_OK
```

Everything after `c_import` is With syntax. Imported types are named by the
exact With spelling `c_import` gives them (`*mut sqlite3`, never `sqlite3*`),
and imported constants resolve through the ordinary imported namespace.

The `c facade` block is the scope in which imported identifiers resolve, the
provenance identity of every fact it states, the scope of convention-profile
adoption and of overrides, and the namespace of the resources and domains it
declares. Facade clauses do not occur outside a facade block.

A facade may be written in the importing project, shipped by a package,
fetched through `with get`, generated by tooling and then reviewed, and
supplemented by machine-readable header annotations and by convention
profiles. The toolchain does not accumulate knowledge of third-party
libraries; bounded knowledge of universal runtime facilities (the C standard
library) may be toolchain-owned where separately justified.

#### 16.2b.2 Evidence, precedence and provenance

Every modeled-C fact has a value and a provenance. ABI/header impossibilities
and compiler-proven contradictions constrain all modeling. Subject to those
constraints, explicit facade clauses override profile facts, which override
conservative defaults:

```
ABI/header facts and proven contradictions   (constrain everything)
explicit facade clause
        ↓
adopted convention profile
        ↓
conservative default
```

ABI and header facts are types, pointer structure, layout, calling
convention, imported constants, link identity, and machine-readable
nullability, ownership or lifetime annotations. An explicit facade clause
refines, overrides or suppresses a profile-derived fact. A facade cannot
override an ABI impossibility. A compiler analysis overrides a facade only
when it genuinely proves the asserted contract impossible, never merely
because it reached a conclusion of its own; where the compiler genuinely
proves a contract, the proof may grant capability.

**The asymmetry rule.** Without a facade clause or an adopted profile, the
compiler may infer only conclusions whose failure removes capability or
rejects a valid program:

```
unknown independence   -> dependent
unknown preservation   -> invalidating
unknown nullability    -> nullable
unknown encoding       -> bytes, not str
unknown thread ability -> creator-thread-bound
unknown domain detail  -> coarse library domain
recognizable naming    -> presentation sugar only
```

It never infers, from a name or a shape, a fact whose failure can make safe
code unsafe: construction, destruction, consumption, ownership, retention,
independence, static lifetime, a status convention, or send/share
capability. Heuristics may suggest such facts (§18.5, tooling); they do not
decide them.

**Provenance is mandatory.** Every effective fact records its source (ABI,
proof, facade clause, named profile rule, or conservative default) and its
facade identity. Diagnostics and `with analyze` report it:

```
error: Statement may outlive Database
  = dependency: conservative default from resource parameter 0
  = help: declare this producer `independent` if the C API guarantees independence
```

#### 16.2b.3 Resources

The fundamental ownership abstraction is the **resource**: a With ownership
type whose physical representation is foreign. Its ownership semantics are
distinct from the representation's C copying and layout semantics. A resource
is non-Copy unless the facade states semantic duplication separately.

A resource wraps one of three physical forms:

```
resource Database wraps *mut sqlite3          // opaque pointer
resource Texture  wraps Texture2D             // by-value token
resource InflateStream wraps z_stream         // in-place struct
```

A by-value C struct that is trivially copyable in C does not make the
resource Copy: moving `Texture` moves ownership of one GPU object.

An in-place resource has explicit states — storage allocated but not live,
live after a successful `init`, dead after destruction. Its storage begins as
`Representation.zeroed()` unless the facade names a `preinit` operation.
`Drop` is armed only when initialization establishes production; storage
existence alone never arms foreign destruction.

An in-place resource is **pinned**: its representation has one address from
the creation of the resource value until foreign destruction completes, and
moving the resource value does not move the representation. The facade may
declare an in-place resource `movable` when trusted evidence establishes that
no operation retains the representation's address; this is never inferred.
Raw and borrowed access to a pinned representation yields a pointer that
remains valid for the borrow regardless of moves of the resource value.
Pinning applies to the representation's own storage, not to memory it
references.

**Never half-model unsafely.** A partial model is acceptable when the missing
fact only removes capability: ownership known but status uninterpreted, a
child dependent until independence is known, a C string left as a borrowed
byte view. A partial model that could create unsafety is a compile error: a
resource with a producer and no valid destruction path; a resource with
`destroys` operations and no `drop` (a value dropped while live would leak;
the facade names the unary destroyer as `drop`); a destroying operation
callable as a borrow; a safe constructor with no destruction contract; a
returned pointer guessed to be owned. A destroyer parameter of type
`void *` accepts every object-pointer representation, as C itself converts
them; it accepts no function-pointer or by-value representation.

More than one resource may wrap the same representation (`InflateStream` and
`DeflateStream` over `z_stream`). When exactly one resource wraps a
representation, operations taking that representation may be associated with
it. When several do, an operation is callable through a resource only after
the facade assigns it (`of InflateStream`); an unassigned operation is
rejected on every candidate, naming them. Raw access remains available.

#### 16.2b.4 Production and status

A resource is produced by direct return, by pointer out-parameter, or by
in-place initialization. The facade states the shape:

```
from curl_easy_init                  // direct return
from sqlite3_open(out param 1)       // out-parameter
init inflateInit(self)               // in-place
```

**Production is not success.** For an out-parameter producer the compiler
initializes the slot to `NULL`, calls the function, and inspects the slot:
non-null means a resource was produced and ownership begins at once; null
means none was. This holds whether or not the status convention is known: for
a status-returning out-parameter producer, the low-level modeled result
remains `(status, Option[Resource])` when the status convention is unknown.

A producer may state its success condition with an imported compile-time
constant:

```
ok SQLITE_OK
ok SQLITE_ROW, SQLITE_DONE           // several success statuses
```

When `ok` lists several constants, any of them is success, and the `Ok` side
carries the status that matched alongside the produced value.

There is no rule that `0` means success, for C in general or for any library.
Without `ok`, the status is uninterpreted. A failed status does not imply that
nothing was produced: the compiler keeps the status, whether a resource was
produced, and ownership of any produced resource. A `Result`-shaped API is a
projection over this model, and a facade-specific error type may own the
failure-state resource where the C contract requires it.

When trusted evidence establishes that a pointer-returning producer signals
failure with `NULL`, its modeled result is `Option[Resource]` and no `ok`
clause is needed. This is not inferred from the return type alone.

When a producer states `ok`, its constructor returns `Result[R, RError]`,
where `RError` is an error type the compiler generates for the resource `R`
(`DatabaseError` for `Database`):

```
error DatabaseError =
    Failed(status: c_int)
    FailedWithResource(status: c_int, resource: FailedDatabase)
    NothingProduced(status: c_int)
```

`Failed` is a failed status with nothing produced. `FailedWithResource` is a
failed status that still produced the resource. The error owns it and
destroys it when the error is dropped, and `?` moves that ownership with the
error. `NothingProduced` is a success status with nothing produced: a
violated contract, reported as an error. A resource owned by an error admits
raw access only, unless the facade marks an operation as valid on the failure
state; it is carried as a distinct type (`FailedDatabase`) that has no
presented methods except those so marked. The mark is a clause on the
operation's fn item, and the operation is then presented on the failed type
as well:

```
fn sqlite3_errmsg
    returns borrow CStr from param 0
    valid on failed
```

A facade that declares or imports a type with the generated name is a
compile-time error naming both. When `ok` is stated, the
`(status, Option[Resource])` constructor is not generated.

An in-place producer with `ok` returns `Result[R, RError]` whose error has
only `Failed`, since a failed initialization produced nothing and a
successful one always did. On
failure its storage is released without the destroyer running; this is the
one case in which a pinned resource's heap cell (§16.2b.3) is freed with no
destruction call.

#### 16.2b.5 Parameter effects

Foreign resource parameters use one ownership vocabulary:

```
lend                                  // the default; may be stated to record review
consumes param 0
destroys                              // an operation that consumes and terminates
consumes param 4 destroyed_by param 8
retains param 1 by param 0
```

**Lend.** Once a resource is modeled, its facade-exposed operations borrow it
unless stronger evidence says otherwise. This default is not a compiler proof
or a conservative safety inference; it is the facade's assertion that the
foreign operation does not retain, consume, or destroy the argument. With
proves the resource is live,
unmoved and undestroyed, and that With discharges ownership per the contract;
it does not prove that foreign code honors borrowing. Lending is trusted
facade semantics. A facade that exposes a consuming or destroying operation as
a lend is unsound.

**Consume.** The argument moves into C; it cannot be used afterward and With
does not destroy it. Consumption is never inferred from a name.

**Destroy.** A destroying operation consumes and terminates ownership. A
resource names one destroyer as its automatic `drop`; other destroyers are
exposed as consuming methods. Every destroyer is consuming; none may be
callable as a lend, so "destroy through C, then `Drop` destroys again" is not
expressible in safe code.

**Consume with destroy callback.** Some APIs take caller-owned data and a
callback C later invokes to destroy it. `consumes param 4 destroyed_by
param 8` moves ownership into C, names the callback as its destruction path,
and requires the callback to be compatible with destroying that value. If
registration can fail without taking ownership, the contract must say when
transfer occurs; absent that, the caller keeps ownership.

**Retain.** Retention extends a borrow past the call while ownership stays
outside C: `retains param 1 by param 0` means the value in parameter 1 must
outlive the resource in parameter 0. A modeled unregister operation may
release the retention; otherwise it lasts until the retaining resource is
destroyed. This is the one retention system; §16.3c's `retains:` is a
projection of it.

**Parameter references.** A clause names a parameter by `param name`,
`param N` (zero-based), or `param type T`; a name must be unambiguous and a
type reference legal only when exactly one parameter matches. Because C
documentation numbers from one, every positional diagnostic prints the
resolved C parameter (`consumes param 4: void *pApp`).

**Discriminated variadic contracts.** A variadic C function stays variadic
(§16.3c: a variadic signature is an unmodeled contract and its direct call
is raw), but a facade may describe a closed set of typed call shapes
selected by an earlier parameter whose value is known at compile time:

```
fn curl_easy_setopt
    variadic param 2 selected by param option:
        case CURLOPT_NOSIGNAL: c_long
        case CURLOPT_URL: str
        case CURLOPT_WRITEFUNCTION: callback param 2 as curl_write_callback userdata param CURLOPT_WRITEDATA
```

Each case states the presented With type and contract of the variadic
argument for that selector value, from which the compiler lowers the actual
variadic ABI argument; the declaration remains variadic all the way to
backend lowering, never a fixed-arity redeclaration. Three rules: the
selector must be a compile-time constant at the call; a listed case renders
a safe presented call (`easy.setopt(CURLOPT_NOSIGNAL, 1)`); a selector that
is unlisted, or not known at compile time, is refused on the safe surface
with a note naming the case to add, and the raw variadic function remains
available under `unsafe`. A case whose C documentation says the pointed-to
data is not copied (curl's `CURLOPT_POSTFIELDS`) states its retention as
§16.2b.5 requires; a bare `str` case is a copied input string (§16.3c).

A callback case explicitly states its C callback type with `as T`, where
`T` is the imported callback typedef or an explicit C function-pointer type.
The variadic declaration does not supply that signature, and neither the
selector name nor the userdata pairing proves it. `userdata param CONST`
names the selector carrying the paired userdata in another call; the
callback type and userdata pairing must agree across those calls, with
retention and lifetime requirements enforced as for other modeled callbacks.

A callback case that states `retains by param N` retains its callback and,
with it, the paired userdata; the userdata setter for the selector that
`userdata param CONST` names is implied by the pairing and needs no second
`case` line, while the retention itself is stated, never inferred. The
userdata is `&U`, the borrow the resource holds (§16.2b.9 "Retained
borrows"). When `U` is a callable, the retention holds its captured places
under that callable's capture views (§12.4): a mutate capture makes the
retention exclusive for its window. The retained userdata is never a copy
or an owned cell.

`ok CONST` on a variadic operation is its status contract (§16.2b.4) for the
listed cases alone: the evidence model of §16.2b.8 applied to status.
Presentation is unchanged — the status is still returned as the C
declaration states it — and the compiler reads a comparison of that status
against the constant as the success or failure edge of the setter. Unlisted
cases stay raw, as above.

**Variadic definitions.** A function defined with a trailing `...` parameter
has the C calling convention and is `unsafe` to call. Its body reads the
variable arguments through `var ap = va_start()`, which yields the target's
`c_va_list`, and `ap.arg[T]()`, which the compiler lowers for the target; the
list ends with its scope. The C migrator translates a variadic C definition to
this form. The type of a variadic C function as a value is `extern "C" fn(A,
..., ...) -> R`: calling through it is raw and its `unsafe` is implied, only an
`extern "C"` function type may end in `...`, and a variadic and a fixed-arity
function type are distinct types that never coerce to one another.

The type of a variadic C function as a value is `extern "C" fn(A, B, ...) -> R`,
where `A, B` stand for its fixed parameters and the trailing `...` is the
literal variadic token: calling through it is raw and its `unsafe` is implied,
only an `extern "C"` function type may end in `...`, and a variadic and a
fixed-arity function type are distinct types that never coerce to one another.

#### 16.2b.6 Borrowed returns, dependency and independence

An operation may return a borrowed resource:

```
fn sqlite3_db_handle
    returns borrow Database from param 0
```

The result has no `Drop`, cannot outlive the named origin, and cannot be
consumed or destroyed. A nullable borrowed return is `Option` of the borrowed
value.

**Borrowed record views.** The same clause applies to any imported record
type, with a resource parameter or a foreign-state domain (§16.2b.7) as the
origin:

```
c facade curl:
    domain version_info process
    fn curl_version_info
        returns borrow curl_version_info_data from domain version_info
```

presents `Option[&curl_version_info_data]`: a view whose lifetime is its
origin's, whose scalar fields are readable, that has no `Drop` and cannot be
stored beyond its origin. Which pointer wins which lifetime is the whole
spelling: a foreign pointer with an owner borrows from the resource; a
pointer into foreign global state borrows from the domain; only genuinely
immortal, immutable data is `static` (§16.2b.7), and `static` is never the
default for "C stored this globally" (curl's version record may change until
`curl_global_init`). A pointer-typed *field* of a borrowed record is not
modeled by the record's lifetime alone: it stays a raw pointer until a
field-level facade fact states its contract (the spelling is a later
ruling); text meant for printing comes through an operation whose return is
modeled (`curl_version()` is `returns static CStr`).

**Unknown independence means dependency.** When a producer receives modeled
resources and produces another, the result is dependent on each candidate
parent unless the facade states `independent`. A facade may make the
relationship precise:

```
resource Statement wraps *mut sqlite3_stmt
    from sqlite3_prepare_v2(out param 3)
    drop sqlite3_finalize
    borrows param 0
```

A resource may depend on several parents and is valid only while all remain
valid. Dependencies use With's ordinary origin and ephemeral-value analysis:
a dependent resource cannot outlive a required parent, prevents the parent's
invalid move or destruction, is destroyed before it, cannot be stored where
the relationship cannot be preserved, and cannot escape through a return. No
reference counting or generation check is introduced for C interop.

A layout such as `type App { db: Database, stmt: Statement }` is invalid when
`stmt` borrows from `db`; the compatible patterns are a statement cache owned
by the connection, or stable handles into owner-managed storage.

#### 16.2b.7 Origins, foreign-state domains and preservation

Borrowed foreign memory always has a real origin: a modeled resource, a
foreign-state domain, static lifetime, or the callback scope. With does not
invent a lifetime, and does not allocate a copy to hide an unknown one.

**Resource-backed memory** borrows from the resource, and later operations
that invalidate the resource invalidate the view through ordinary
view-liveness rules.

**Foreign-state domains** give ownerless C storage an origin: the process
environment, locale, `errno`, diagnostic buffers, library caches.

```
c facade libc:
    domain errno thread
    domain environ process
```

A domain is `process`, `thread`, `resource` or `static`. The default coarse
domain of a library is its link identity; a facade may split it or merge
domains from separate imports that name the same state. A view borrowed from
a thread domain inherits the thread restriction. Static data does not
participate in invalidation.

**Preservation.** For every origin an operation touches, its view effect is
`invalidate` or `preserve`; **unknown effect means invalidate**. A facade may
state `preserves param 0` or `preserves domain environ`. C `const` is
evidence for diagnostics, profile rules and suggestions; it does not by itself
establish preservation, and non-const does not establish invalidation.

**Static lifetime** grants capability and is never inferred from the absence
of a visible owner. `returns static CStr` states it.

#### 16.2b.8 Foreign strings, buffers and nullability

The modeled NUL-terminated foreign string type is `CStr`; it makes no UTF-8
claim. A nullable borrowed foreign string is `Option[&CStr]`, borrowing from
the resource, domain or static origin the facade establishes. Conversion to
With text is explicit:

```
cstr.to_str()          // validates UTF-8; does not repair
cstr.to_str_lossy()    // repairs, explicitly
cstr.to_owned()        // allocates an owned copy, explicitly
```

No `char *` becomes `str` silently.

**Buffers.** A C pointer parameter and the integer parameter that carries its
length are one slice when the facade pairs them; the pairing and count unit are
stated, never inferred from the C types, because a wrong pairing hands C a
wrong length:

```
fn compress
    buffer param source len param sourceLen          // one input []u8
    buffer param dest capacity param destLen inout   // one writable []mut u8
fn tally_total
    buffer param values len param count elements     // int * + count: []i32
```

`buffer param P len param L` renders `P` and `L` as one `[]u8` parameter; the
compiler supplies the pointer and the byte length from that one value.
`buffer param P capacity param L inout` renders `P` and `L` as one `[]mut u8`
parameter whose length is the capacity C receives on entry; the length C
writes back is bounds-checked against that capacity before it becomes a
With value, and it is presented as the operation's `usize` result — the
caller's slice is not modified. Whether the copied-back length is meaningful
after a failed call is decided by the operation's status contract (§16.2b.4);
it is presented only on success. Without a qualifier the length counts bytes
and the clause renders `[]u8` or `[]mut u8`.

An explicit `elements` qualifier changes the count unit to elements:
`buffer param P len param L elements` renders a typed `[]T`, and
`buffer param P capacity param L inout elements` renders `[]mut T`, where
`T` is the C pointer's element type. The compiler derives the pointer and
element count from that slice. Conversion of the slice length or capacity to
the C count type is checked before calling C; an unrepresentable count fails
instead of truncating. A copied-back element count is checked against the
original element capacity before it becomes the `usize` result. The caller's
slice remains unchanged, and the same status contract governs whether
copy-back is valid. Neither the C pointer type nor a parameter name establishes
the count unit: the facade must state `elements` when that is the contract.

A raw pointer parameter that
no clause pairs is not a buffer, and a `lend` or presentation clause on such
a function is refused rather than rendering a call without a bounds contract.

```
let n = compress(out, src)?        // no pointer, no length, no unsafe
```

Caller-owned returned memory is a resource:

```
resource SqliteString wraps *mut c_char
    from sqlite3_mprintf
    drop sqlite3_free
```

It exposes a borrowed `CStr` view; the foreign allocator/deallocator pairing
stays intact, and With never substitutes its allocator except through an
explicit copying conversion. The same applies to any foreign-owned buffer.

**Nullability.** `NULL` is information. Machine-readable nullability is used
directly. Otherwise `nullable -> Option`, `nonnull -> direct value`, and
unknown nullability is represented as nullable or otherwise restricted; it
never silently becomes non-null. Out-resource production keeps its own
NULL-inspect rule.

#### 16.2b.9 Callbacks

A value C passes into a With callback is borrowed for the callback's scope;
it does not become owned because C passed a pointer, and it cannot escape the
callback without stronger evidence (transfer, a longer-lived origin, or
static lifetime).

**Callback-scope handles.** A foreign representation that exists only for a
callback's invocation (`sqlite3_context`, `sqlite3_value`) is declared as a
handle: nothing produces or destroys it, it has no `Drop`, and it is borrowed
for the callback's scope and cannot outlive it. Operations on it are its
methods, stated with `of` as for a resource:

```
handle Context wraps *mut sqlite3_context
handle Value wraps *mut sqlite3_value
fn sqlite3_result_int
    of Context
fn sqlite3_value_int
    of Value
```

A clause on the registering function may present a callback's argument
vector as a slice of a callback-scope handle (`argv paired with argc as
&[Value]`) and its registered user data as the value the facade boxed
(`user_data as &U`). The compiler generates the wrapper; both are valid for
the callback's invocation only.

A callback used only during one foreign call needs no retained lifetime. A
callback C keeps is modeled with `retains`, and its userdata likewise. A
callback receives ownership only through explicit evidence (`callback
consumes param N`); this is never inferred. A callback named by
`destroyed_by` (§16.2b.5) is the modeled eventual destruction path of
ownership already transferred into C: the value is live in C until that
callback runs, and With destroys it through no other path.

**Reentrancy.** A foreign operation that may invoke a callback is treated as
affecting the origins the callback captures, according to the captures'
allowed operations: immutable captures contribute reads, mutable captures
contribute invalidation, owned captures follow ownership and retention. A
facade states `callbacks none` on an operation only when verified foreign-library
evidence guarantees that the operation cannot invoke applicable callbacks.
This is capability-granting trusted evidence, never a warning suppression;
absent it the call is conservatively reentrant.

**Pairs configured across calls.** The callback and userdata pair belongs to
the resource. Its state includes the foreign defaults, replacements, and
setter failures; merely calling both setters does not establish compatibility.
An operation that could invoke an incomplete or incompatible pair is refused.
Two-call setup also requires evidence that callbacks cannot run concurrently
between the calls.

**Retained borrows.** A retained userdata is a borrow the resource holds
(§16.2b.5 "Retain"): `&U`, and when `U` is a callable, its capture views
(§12.4) are held with it — shared where the callable reads a captured
place, exclusive where it mutates one. A collector's sink is captured
mutably by the callable the handle holds, so the sink is exclusively held
for the window. The retention is the same borrow that view-liveness models
for any other borrow,
held by the resource, and it ends at a modeled reset or unregister, at the
resource's destruction, or after the last callback-capable operation that
can reach it. Under an exclusive retention the program cannot touch the
borrowed place inside that window: reading a collector's sink back after
the final `perform` is fine; reading it between the setter and `perform` is
a use of an exclusively borrowed place and is refused. A resource holding a
retained borrow is itself ephemeral for that window: it cannot be moved into
longer-lived storage or returned while the retention lasts. This is the
property that makes the two-call surface safe without a second type.

Destruction is checked as an actual operation, including cleanup on early
return and `?`. Leaving a lexical scope is not itself forbidden: a destroy
path that cannot invoke the affected callback may safely destroy a partially
configured resource. A callback-capable destroy path must satisfy the same
pair and lifetime requirements as any other callback-capable operation.

The facade must model a safe way to abandon partial setup. A resource names
it:

```
resource Easy wraps *mut CURL
    from curl_easy_init
    drop curl_easy_cleanup
    abandon curl_easy_reset
```

The named operation must be one of the resource's own modeled operations
and itself `callbacks none`, so the abandonment path cannot invoke the
incomplete pair; an `abandon` naming any other operation is refused. The
compiler runs the abandon operation before the destroyer on every drop path
whose pair state is not proven callback-free — early return and `?`
included — so a spurious reset costs one call and a missed one cannot
happen. If the first setter succeeds, the second fails, and the function
returns an error, cleanup must remain safe and release the retained state
exactly once. A partial-setup error must not trap the programmer without a
safe cleanup path. A per-operation statement of which callbacks a
destroyer cannot invoke is not a facade fact: it is name-shaped inference,
and `callbacks none` stays whole-operation.

#### 16.2b.10 Thread capabilities

A modeled resource is `thread creator` by default: operations and destruction
occur on the creating thread and ownership does not cross threads. The
capabilities are `send`, `share` and `drop_any_thread`; none is inferred from
representation. With v1 does not marshal destruction back to the creator
thread; therefore `send` requires `drop_any_thread`, a creator-thread-bound
resource is not sendable, and a facade granting `send` without
`drop_any_thread` is a compile error. `share` is independent of `send`.

A retained callback executes on the registering thread unless the facade
states `callback_thread any`, in which case captured With state must satisfy
the corresponding send/share constraints.

#### 16.2b.11 Presentation

Method grouping, prefix shortening and namespace presentation are not safety
semantics, and With may apply recognizable naming conventions to them
silently: `sqlite3_prepare_v2(db, …)` may be presented as `db.prepare(…)`.
Presentation never establishes ownership, lending, consumption, destruction,
dependency, independence, retention, preservation, thread safety or static
lifetime; the underlying semantics must already be valid.

A facade may rename, regroup or suppress presented methods:

```
fn sqlite3_prepare_v2
    of Database
    rename prepare
```

Explicit presentation overrides the automatic convention. Where automatic
grouping is ambiguous the sugar is omitted and the operation remains
available under its imported name.

**Fixed arguments.** A facade may bind a C parameter to a literal and remove
it from the presented signature:

```
fn sqlite3_prepare_v2
    param nByte fixed -1
    param pzTail fixed null
```

The presented `prepare(sql)` always passes those literals; the raw operation
stays available for any other value. A fixed argument is a stated facade
fact, never an inference from the C type, and it is not an optional argument
a caller may override.

#### 16.2b.12 Convention profiles

A convention profile is a versioned package of facade rules that another
facade adopts explicitly:

```
c facade gtk:
    use convention gobject.v1
```

Adopting a profile makes it trusted foreign-contract evidence for the API it
applies to; a profile may therefore infer from names (`*_unref -> destroying`)
what core With never does. Every capability-granting profile match is
**unique-or-nothing**: zero candidates contribute nothing, exactly one
contributes evidence, several contribute nothing, and the compiler never
chooses among matches. Explicit facade clauses override profile facts.
Profiles are packages, never compiler knowledge, and are versioned.

#### 16.2b.13 Verification and versioning

The compiler verifies every mechanically checkable facade statement: the
referenced declaration exists; the representation resolves; parameter
references resolve uniquely; a destroyer accepts the representation; a
producer's return or out-parameter matches; a status constant is a
materialized compile-time value; a callback parameter is callable;
`consumes` refers to a compatible value; a domain exists; a profile rule
resolves uniquely; the thread-capability combination is legal. A referenced
constant that is missing, ambiguous or not compile-time is a compile error.
Verification does not prove semantic facts that require trusting the foreign
API; a structurally valid but false facade is a trusted-boundary bug.

A facade describes an API version or compatible range and is validated
against the imported declarations on every build. ABI compatibility does not
imply semantic compatibility.

#### 16.2b.14 The runtime is not exempt

Runtime foreign calls are described by an internal facade or equivalent
audited contract data. Hidden runtime behavior must not invalidate a foreign
view that safe user code is permitted to hold; a runtime change that begins
mutating a domain supporting live safe views is caught by audit.

Process-global C state over which no safe view is presented (signal
disposition and mask, the current directory, the file-descriptor table,
resource limits, process groups and children, the stdio stream objects) is an
effect the runtime audit records, not a domain. It becomes a domain the first
time a facade presents a safe view whose validity it decides.


### 16.3 Manual Declarations

For cases where `c_import` is insufficient or when fine-grained
control is needed, manual declarations are supported:

```
extern "C" {
    fn puts(s: *const u8) -> i32
    fn custom_fn(ctx: *mut c_void) -> i32
}
```

Manual `extern "C"` declarations are raw ABI declarations. A call to a
value-only manual extern function is safe when the signature carries no
raw pointer, slice, callback, variadic, ownership, lifetime, or other
unmodeled safety contract. A manual extern call that does carry such a
contract requires `unsafe` unless it is wrapped by a safe With API that
models the memory, ownership, and lifetime contract. An `unsafe` block
around a value-only manual extern call is still permitted as an explicit
raw-ABI-boundary acknowledgement; it is not required.

`@[link_name("symbol")]` on an `extern fn` sets the exact foreign
symbol name used for linking while keeping the With declaration name
available for local overload avoidance, curation wrappers, or naming
conventions. It does not change the function type or safety contract.

`@[import_module("ns")]` on an `extern fn` names the WebAssembly import
namespace the symbol is imported from; without it the namespace is `env`.
It applies only to the wasm32 target and does not change the function type
or safety contract.

### 16.3b External Variables

Global variables defined in C libraries can be declared with
`extern var` (mutable) or `extern let` (read-only):

```
extern var errno: i32
extern var stdin: *mut c_void
extern let sys_nerr: i32
```

**Semantics:**
- No initializer — the symbol is resolved at link time.
- `extern let` produces a compile error if assigned to.
- `extern var` is mutable — assignment stores to the global.
- The type must be concrete (no generics, no inference).
- Access does not require `unsafe` (the declaration is the opt-in).

`c_import` emits `extern var` for C globals with non-const types
and `extern let` for const-qualified globals.

**The `c_void` type:** C's `void*` maps to `*mut c_void` (or
`*const c_void`) in With. `c_void` is an opaque, zero-sized type
defined in `std.ffi` that cannot be instantiated — it exists only
to be pointed at. `void` is not a keyword or built-in type in With
(the unit type is `Unit`). `c_import` automatically translates C's
`void*` parameters to `*mut c_void`.

### 16.3c Contract-Driven Coercion at `c_import` Boundaries

C APIs use strings, byte buffers, mutable buffers, and `void*` through
contracts that are not fully present in the C type spelling. With keeps
those APIs ergonomic by modeling the contract in the binding and
generating the correct bridge. It does not reinterpret values from type
spelling or receiving context alone.

The compiler may auto-coerce at a `c_import` boundary only when the
compiler or binding models the full contract needed for that
conversion: sentinel, length or capacity, lifetime and retention,
nullability, mutability, ownership, allocation, cleanup, and copy-back.
If those facts are missing, the operation stays on the raw surface.

**Contract metadata sources.** The facts that make a binding modeled are
facade evidence (§16.2b): an explicit clause in a `c facade`, a fact from a
convention profile the facade adopts, machine-readable header annotations, or
a compiler proof, in the precedence §16.2b.2 gives; anything else is a
conservative default. A facade may be written locally or come as a package.
The toolchain's own knowledge is bounded to the C standard library (the
curated libc facade), which is a standard deliverable. A library without a
facade still receives whatever modeling ABI and header facts alone establish
(machine-readable nullability, header ownership or lifetime annotations,
conservative defaults); everything beyond that imports as the raw surface
until a facade is supplied. An overlay supplies evidence, never exemptions —
it cannot weaken the rules below.

```
// Modeled input C string contract:
fopen(path, mode)        // compiler supplies call-scoped C strings

// Modeled byte-buffer contract:
write(fd, data)          // compiler supplies data.ptr and data.len together

// Raw surface when the contract is unknown:
raw_register_callback(name_ptr as *const c_char)
```

Binding evidence governs what With receives from C. An argument With lends
to C for the duration of a call needs none: a `c_import`ed `const char *`
parameter accepts a `str`, passed as NUL-terminated input text. A string
literal is passed directly; any other `str` is passed through call-scoped
storage that stays readable if the callee retains it.

**`str` → input C string (`*const c_char`).** A `str` may be passed
automatically to a `*const c_char` parameter only when the binding
establishes all of these facts:

1. the parameter is a read-only, NUL-terminated input string;
2. the value has no interior NUL, or the conversion handles one loudly;
3. the C callee does not retain the pointer after the call.

If the argument is a string literal or another value the compiler can
prove already lives in valid NUL-terminated storage, the compiler may
pass it directly. Otherwise it generates a call-scoped
NUL-terminated temporary and frees it when the call returns.

**Retention (`retains:`).** Retention is stated in the facade with
`retains param … by param …` (§16.2b.5), which is the canonical form:
retention participates in callbacks, ownership and origins, not only in
C-string inputs. The `retains:` import attribute is a compatibility spelling
of the C-string case, accepted during migration and deprecated in favour of
the facade vocabulary. Parameters are borrowed by default. A
`c_import` contract may annotate a parameter as retaining the pointer:
`use c_import("…", retains: ["fn(idx)"])` declares that `fn`'s parameter
`idx` keeps the C-string pointer past the call (violating condition 3
above). Such a parameter is still a modeled C-string input — it is
callable without `unsafe` and accepts a pointer into caller-owned
storage — but a `str` (which would coerce to a call-scoped temporary
freed on return) is a compile error. The caller must pass a pointer into
storage it keeps alive, e.g. `let c = s.to_cstring()?` then
`fn(c.as_cstr().ptr())`. (#602.)

Interior NUL is never silently truncated. A proven interior NUL is a
compile error; a dynamic interior NUL is checked at runtime and
reported according to the binding's error model. The conversion passes
the `str` bytes unchanged and does not silently transcode.

When the binding cannot prove non-retention, or knows that C stores the
pointer, a call-scoped temporary is forbidden. The safe surface must
require caller-managed storage such as `CStr`, `CString`, or a
generated wrapper with a suitable lifetime, or the API remains raw.

**`str` → byte buffer (`*const u8`).** A safe byte-buffer binding must
convey both the data pointer and its paired length or equivalent bound.
`str` may be adapted to C APIs such as `write(fd, data.ptr, data.len)`
when the binding models that pair. Passing only `data.ptr` to an
unbounded C reader is raw pointer interop.

**`str` → mutable C string or writable buffer (`*mut c_char`).** There
is no implicit `str` to `*mut c_char` conversion with a hidden
caller-must-free allocation. A writable C buffer requires a modeled
buffer contract: a caller-provided `mut` slice or buffer with known
capacity, a generated owned buffer type whose `Drop` handles cleanup,
or a generated wrapper that defines allocation, capacity, initialized
length, mutation behavior, cleanup, and whether contents copy back into
With.

**`void*` and opaque pointers.** `*mut c_void` and `*const c_void` are
opaque. Expected-type context does not prove pointee type, lifetime,
ownership, nullability, or validity. A `void*` may be converted
automatically only when trusted binding metadata or a generated wrapper
proves what it represents. Otherwise it remains `*c_void`; using it
requires the raw surface or an explicit cast.

In particular, `void*` to `str` is never generated merely because the
receiving context is `str`. Calling `strlen` on an arbitrary `void*`
is an unsafe memory read based on a guess. It is allowed only when the
binding proves the pointer is a valid NUL-terminated string with known
lifetime and nullability.

**Nullability.** Null is information. A nullable C string return is modeled
as `Option[&CStr]` borrowing from its origin (§16.2b.8); a nullable pointer
return as `Option` of the borrowed or owned modeled value. `None` and
`Some("")` are distinct unless the C contract states that null means empty.

**Always raw unless modeled:** arbitrary `void*`, retained or
unknown-lifetime string pointers, mutable C buffers without a modeled
contract, pointer-only byte buffers with no bound, explicit pointer
casts, and any API whose lifetime, ownership, or nullability cannot be
proven.

No safe conversion may silently truncate at an interior NUL, allocate
hidden caller-owned memory, pass a call-scoped temporary to an API that
retains it, silently transcode string bytes, erase nullability, call
`strlen` on an unproven pointer, or reinterpret a `void*` from expected
type alone.

### 16.3d `@[effect]` — Declared Effect Contracts

Parameter effects (read, write, consume, escape) are normally
**inferred** from function bodies (§3.8, §21.1). Some declarations
have no body to infer from: `extern` functions, intrinsic-backed
stdlib stubs, and raw ABI bindings. For these, `@[effect]` declares
the contract explicitly:

```
@[effect(dst: write, src: read)]
extern "C" fn memcpy(dst: *mut c_void, src: *const c_void, n: usize) -> *mut c_void

@[effect(handle: consume)]
extern "C" fn close_handle(handle: *mut c_void)
```

Recognized effect names: `read`, `write`, `consume`, `escape_value`,
`escape_view`.

**Scope rules:**

1. `@[effect]` is **required information** only where no body exists
   (extern, intrinsics). Bindings without it stay on the raw surface
   for the affected parameters.
2. On an ordinary function with a body, `@[effect]` may optionally
   **pin** the inferred summary at a `pub` boundary (§4.6
   explicitness): if inference disagrees with the pin, that is a
   compile error — the pin is a checked contract, not an override.
3. `@[effect]` is library-author surface (stdlib, FFI bindings,
   contract overlays §16.3c). Ordinary application code never needs
   it; requiring it there would be annotation ceremony (§1.7). For
   c_imported declarations the facade vocabulary (§16.2b.5) states these
   effects. `@[effect]` remains valid for hand-written `extern`
   declarations, which have no imported facade namespace to attach to: it
   is the raw, manual analogue of facade evidence, and a one-off extern
   needs no facade block.

*§16.3e ABI Boundary Signatures Are C-Representable moved to `docs/spec/abi/abi-boundary-signatures.md`.*

*§16.4 Layout Control moved to `docs/spec/abi/layout-control.md`.*

*§16.5 Exporting to C moved to `docs/spec/abi/exporting-to-c.md`.*

*§16.6 Function Pointers moved to `docs/spec/abi/function-pointers.md`.*

### 16.7 Callback Pattern

```
@[repr(C)]
type Callback {
    func:    extern "C" fn(ctx: *mut c_void, arg: i32) -> i32,
    ctx:     *mut c_void,
    destroy: extern "C" fn(ctx: *mut c_void),
}
```

Standard library provides helpers for boxing/unboxing closure context.

### 16.8 Link Directives

Libraries to link are specified either in `c_import` or in `with.toml`:

```toml
# with.toml
[link]
libs = ["sqlite3", "ssl", "crypto"]
search_paths = ["/usr/local/lib"]
```

Or inline:

```
use c_import("sqlite3.h", link: "sqlite3")
```

The `with build` command passes these to the linker.

### 16.9 Opaque Types

```
type FILE = opaque
type DIR = opaque
```

Opaque types have unknown size and layout. They can only appear as
pointer targets (`*mut FILE`, `*const FILE`). Any attempt to create
a value, copy, `sizeof`, or access fields of an opaque type is a
compile error. `c_import` emits `type Name = opaque` for forward-
declared C structs (no body) and structs with bitfields.

### 16.10 Null Pointer Literal

```
let p: *mut i32 = null
if p == null:
    print("null pointer")
```

`null` is a typed null pointer constant. Its type is inferred from
context — it requires a pointer type annotation. Using `null` without
type context is a compile error. `null` is not the same as `0`.
Dereferencing `null` is undefined behavior (caught by `unsafe`).

### 16.11 Raw Pointer Operations and `unsafe`

```
fn use_ptr(p: *mut i32, end: *mut i32):
    let q = p + 2              // raw pointer arithmetic is safe
    let at_end = q == end      // raw pointer comparison is safe
    let addr = p as usize      // address observation is safe
    let r = addr as *mut i32   // validity-less raw pointer construction
    let bytes = q as *mut u8   // same-domain raw pointer relabeling

    unsafe:
        let val = *q           // raw pointer dereference
        let val2 = p[2]        // raw pointer indexing that reads
        p[0] = 42              // raw pointer indexing that writes
        let ref = q as &i32    // raw pointer to safe reference
        let s = slice(q, 2)    // raw pointer to safe slice/view
```

Certain operations in With can violate memory safety if misused.
These operations are permitted only within an `unsafe` context:
the body of an `unsafe fn`, the scope of an `unsafe:`/`unsafe {}` block,
or the narrow `unsafe *p` / `unsafe p[i]` raw-access prefix.

The boundary is:

> Address computation, comparison, and same-domain raw-pointer
> relabeling are safe. Memory access or validity assertion is unsafe.

`unsafe` is not a tax on foreignness, and it is not a tax on pointers.
It marks the operation whose safety the compiler cannot prove. Pointer
arithmetic computes an address. Pointer comparison compares addresses.
Same-domain raw-pointer casts relabel raw pointer values. None of these
operations reads memory, writes memory, creates a safe reference, or
proves bounds, alignment, liveness, initialization, ownership,
uniqueness, permissions, or provenance.

The operations that require an unsafe context are:

- Raw pointer dereference (`*p` for read or write)
- Raw pointer indexing (`p[i]` for read, `p[i] = v` for write)
- Raw-pointer-to-reference conversion (`p as &T`)
- Raw-pointer-to-slice/view conversion (`slice(p, len)` or equivalent)
- Allocation-relative pointer distance when same-allocation facts are
  not proven
- `transmute`, or reinterpretation into a non-raw value, safe
  reference, safe memory abstraction, or other type whose invariants
  safe code will trust
- Pointer-domain casts not specified as safe validity-less raw
  conversions by the target model
- Calls to `unsafe fn`
- Calls to manual `extern` functions with raw/unmodeled safety
  contracts, or raw/unmodeled ABI bindings
- Any operation whose correctness depends on the pointer being valid,
  live, aligned, initialized, in bounds, dereferenceable, owned,
  uniquely writable, carrying the required permissions, or carrying the
  required provenance
- Other operations explicitly marked as unsafe in their definition

For the common raw-memory access case, `unsafe` may be used as a
narrow prefix over one contiguous raw access chain:

```
let x = unsafe *p
let y = unsafe p[i]
let z = unsafe **pp
let item = unsafe *(p + 1)

unsafe *p = 42
unsafe p[i] = 42
```

The prefix does not wrap arbitrary expressions. `unsafe *p + 1`
means `(unsafe *p) + 1`; a second raw access must be marked
separately or placed in an unsafe block. Use `unsafe { ... }` or a
newline `unsafe:` block for unsafe calls, transmutes, asm, and
compound unsafe expressions.

**Raw stores do not drop.** A store through a raw pointer (`*p = v`,
`p[i] = v`) is a raw write: the old pointee is not dropped, because the
compiler cannot prove it is a live value (it may be uninitialized or
already moved out). To replace a live pointee, move it out and drop it
explicitly: `let old = *p; drop(old)` then store. Drop-on-reassignment
(§2.2) applies only to safe places — bindings, `&mut` derefs, and
fields, including a field projected through a raw deref
(`(*p).f = v`), where projecting asserts a live pointee.

The following operations involving raw pointers are safe and do not
require an unsafe context:

- Raw pointer arithmetic (`p + n`, `p - n`)
- Raw pointer offset calculation
- Raw pointer equality comparison
- Raw pointer null checks
- Raw address ordering/comparison (`p < q`, `p >= q`, etc.)
- Raw address difference, when specified as integer address subtraction
- Pointer-to-address/integer observation (`p as usize`)
- Integer/address-to-raw-pointer construction of a validity-less raw
  pointer value (`n as *T`)
- Same-domain raw-pointer-to-raw-pointer casts that relabel the pointee
  type or source-level mutability qualifier
- Raw-address-of operations that do not materialize a safe reference

These operations compute, compare, observe, or relabel raw pointer
values only. They do not read memory, write memory, create a safe
reference, create a slice/view, or assert that the resulting pointer is
valid to use.

**An explicit borrow cast to an integer type is a compile error.**
`&place as <integer-type>` is rejected: under the contextual-Copy demand
(D22 §6.2, cast target) the `&` would be an unnecessary character that
only misleads — the value spelling is `place as u64`, and the address
spelling is `&raw const place as u64`. The diagnostic offers both
intents as fix-its. Integer address observation belongs to raw pointers
(`p as usize`, above); a safe borrow never converts to an integer.
D22 §6.2 stays intact for every other cast target — a named view or an
explicit borrow under a non-integer owned cast target still materializes
per the contextual-Copy ruling, and `&place as *T` remains the blessed
address-taking pointer spelling. (D31.)

For typed pointer arithmetic, `p + n` means address computation scaled
by the pointee size: conceptually `addr(p) + n * sizeof(T)` under the
target raw-pointer model. Under the flat-address default, both the
scaling and the address addition use deterministic wrapping arithmetic
over the target pointer-address width. The result is still only a raw
pointer value, not a validity claim.

An overflowing raw pointer offset produces a raw pointer value by
deterministic wrapping address computation under the flat-address
default. It does not produce an implicit validity claim. The resulting
pointer may be invalid to dereference, but computing it is defined.

Raw pointer difference is safe only when it is specified as
address-value subtraction. If an operation instead claims
same-allocation element distance, then same-allocation provenance and
bounds are being asserted. That stronger operation is safe only when
proven; otherwise it belongs behind `unsafe` or on the raw surface.

A raw-pointer-to-raw-pointer cast is safe when it relabels the pointee
type or source-level mutability qualifier (`*const` <-> `*mut`) without
changing the pointer's domain or representation. Such a cast relabels
the raw pointer value. It is not the value-bit transmute of the unsafe
list, and it asserts nothing about the new pointee type. Alignment,
validity, initialization, aliasing permission, and provenance for the
new type are asserted only when the pointer is dereferenced or
converted to a safe abstraction, which already requires `unsafe`.

Changing the source-level mutability qualifier is a relabel, not a
capability grant. Casting `*const T` to `*mut U` constructs only a raw
mutable pointer value; it grants no write capability, uniqueness,
ownership, or validity, and any write through the result remains unsafe
under the ordinary raw-pointer access contract.

A **pointer-domain cast** changes the pointer's address space,
capability class, segment class, function/data-pointer class,
host/device domain, hardware or capability permission bits, or
representation. It is not an ordinary relabel. Which such casts exist
and how they behave is governed by the target raw-pointer model. A
pointer-domain cast is safe only if the target model specifies it as a
validity-less raw pointer conversion; otherwise it requires `unsafe` or
is rejected through an explicit target-defined cast form rather than the
ordinary `as` relabel.

The source-level mutability qualifier is not a permission in this
target-model sense. Hardware or capability permission bits, such as
CHERI load/store/execute permissions, are target-defined facts;
manufacturing or stripping them is a pointer-domain cast, not a
same-domain relabel.

Converting a raw pointer into a safe memory abstraction is also an
unsafe access boundary. A reference, slice, view, span, or similar safe
type asserts validity, bounds, alignment, lifetime, initialization, and,
where applicable, provenance. That assertion must be made in an unsafe
context at the conversion site; it is not deferred until later safe code
uses the converted value.

Passing a raw pointer to a function is not unsafe by itself. The
obligation, if any, lives in the callee's signature or wrapper contract.
A function that dereferences, retains, mutates through, converts, or
otherwise relies on caller-guaranteed validity of a raw pointer
parameter has a safety precondition that the raw pointer type does not
encode. Such a function is an `unsafe fn`, unless the compiler or
binding wraps the contract into a safe surface.

For in-language functions, the compiler may prove that the function
does not rely on the pointer's validity: it never dereferences, retains,
mutates through, converts to a safe reference/view, or passes the
pointer to a contract that relies on validity. A function proven not to
rely on the pointer's validity may be safe, and passing a raw pointer to
it is safe.

For foreign functions, the compiler cannot infer that contract across
the boundary. A foreign function that takes raw pointers is unsafe by
default unless the binding declares the pointer contract safe, or
generates a safe wrapper that validates and models the relevant
nullability, bounds, lifetime, ownership, retention, mutation, and
permission rules.

Indexing must distinguish address calculation from memory access. If
`p + i` computes the address of element `i`, it is safe. If `p[i]`
reads or writes element `i`, it is unsafe. If the language provides an
address-only form such as `&raw p[i]` or equivalent, that form is safe
only if it is specified to compute a raw address without materializing a
safe reference. A form that creates `&T` from a raw pointer is unsafe,
even if the reference exists only transiently.

If With's memory model carries pointer provenance, the safe/unsafe
split remains the same. Raw pointer arithmetic computes a raw pointer
value without asserting that the pointer has the provenance required for
any future access. Integer-to-pointer conversion constructs a raw
pointer value without asserting valid provenance. Same-domain raw
pointer casts relabel the raw pointer value without asserting provenance
for the new pointee type.

The unsafe dereference, raw-pointer-to-reference conversion,
raw-pointer-to-slice conversion, or unsafe call is where the programmer
asserts that the pointer has the required validity and provenance. This
section defines that constructing, computing, comparing, and relabeling
raw pointer values is safe, while relying on them as memory requires
`unsafe`. It does not decide which integer-derived or relabeled pointers
are actually usable under With's memory model.

Under an exposed/permissive-provenance model, a later unsafe access may
be valid when the programmer upholds the contract. Under a
strict-provenance model, some integer-derived pointers may remain
invalid to dereference regardless of `unsafe`. That determination
belongs to the memory-model section. Provenance does not move the unsafe
boundary to arithmetic or relabeling; it is part of what the unsafe
access or conversion asserts.

On capability, segmented, or otherwise non-flat-address targets, the
target-specific raw-pointer model governs and overrides the flat-address
default. Such a target must specify how safe raw pointer arithmetic
behaves: preferably by producing a deterministic validity-less,
narrowed, untagged, or otherwise invalid raw pointer value whose later
use is where failure occurs; or, if the hardware or ABI genuinely
requires arithmetic itself to trap, by documenting that target-defined
trapping behavior explicitly. A backend for such a target is not
required to fabricate flat wrapping semantics it cannot provide, but it
must specify its raw-pointer model and keep the safe/unsafe boundary
honest for that target.

**Backend obligation:** Safe raw pointer arithmetic, comparison, address
difference, and same-domain raw-pointer relabeling must lower as raw
address operations. The compiler must not introduce undefined behavior,
poison, trapping behavior, or optimizer assumptions unless the
corresponding fact has been proven, subject to the specified target
raw-pointer model.

For these operations the backend must not attach or imply in-bounds,
in-range, dereferenceability, alignment, no-overflow,
allocation-membership, provenance, ownership, uniqueness,
write-permission, or lifetime assumptions unless those facts are
proven. For LLVM backends, ordinary raw pointer arithmetic must not be
lowered with `inbounds` or `inrange` GEP, or equivalent metadata, unless
those facts have been proven. It also must not use `nuw`/`nsw`-style
assumptions for address arithmetic unless overflow has been proven
impossible. Absent such proof, arithmetic lowers to the target's
specified raw address computation, which is deterministic wrapping
arithmetic under the flat-address default.

Raw pointer comparison must lower to address-value comparison without
range, provenance, allocation-membership, dereferenceability, or
lifetime assumptions. LLVM pointer `icmp` or target-approved
integer-address comparison may be used when it preserves With's raw
address comparison semantics. C relational pointer comparison is not an
acceptable lowering for arbitrary raw addresses, because C imposes
restrictions on relational comparison of pointers from unrelated
objects.

Raw address difference carries the same obligation as comparison: it
must lower to integer subtraction of the address values, with no
same-allocation, provenance, or allocation-membership assumption. It
must not be lowered as C pointer subtraction, whose result is defined
only for pointers into the same object. Allocation-relative element
distance is a distinct, stronger operation and is lowered only where the
same-allocation facts have been proven.

A same-domain raw-pointer relabeling cast lowers to a no-op, bitcast, or
target-approved raw pointer cast that preserves the raw pointer value
without adding alignment, dereferenceability, provenance, address-space,
capability, permission, or lifetime assumptions for the new pointee
type. Pointer-domain casts lower according to the target raw-pointer
model.

This does not forbid optimization. If the compiler has proven a stronger
fact, such as a checked slice index being in bounds, it may use a
stronger lowering for that proven case. The rule forbids assuming those
facts for arbitrary raw pointer arithmetic, comparison, difference, or
relabeling.

### 16.12 Intrinsics

**`sizeof` and `alignof`:**

```
let size = sizeof[i32]()      // 4
let align = alignof[f64]()    // 8
```

Built-in generic functions that return the size (in bytes) and
ABI alignment of a type at compile time. Required for allocator
implementations, C interop buffer sizing, and packed struct
calculations.

**`transmute`:**

```
let bits: u32 = unsafe { transmute[u32](3.14f32) }
```

Reinterprets the bits of one type as another. Both types must have
the same size (compile error otherwise). Requires `unsafe` context.

### 16.13 Inline Assembly

The `asm` expression embeds target-specific assembly instructions.
It requires `unsafe` context.

```
let sp: u64 = unsafe:
    asm("mov %sp, {out}" : out("x0") -> u64)

unsafe:
    asm("dmb sy" ::: "memory")
```

**Full syntax:**

```
asm(template : outputs : inputs : clobbers)
```

Each section is optional. A trailing `:` section can be omitted.

**Template:** A string literal containing assembly instructions.
Register placeholders use `{name}` syntax, where `name` matches
an output or input binding.

**Outputs:** Comma-separated list of `name(constraint) -> type`.

```
asm("mrs {out}, CNTPCT_EL0" : out("x0") -> u64)
```

**Inputs:** Comma-separated list of `name(constraint) value`.

```
asm("add {out}, {a}, {b}"
    : out("x0") -> i32
    : a("x1") val_a, b("x2") val_b)
```

**Clobbers:** Comma-separated list of registers or `"memory"` /
`"cc"` that the assembly modifies but that are not outputs.

```
asm("syscall"
    : out("rax") -> i64
    : a("rax") syscall_num, b("rdi") arg1
    : "rcx", "r11", "memory")
```

**Volatile:** Marks the assembly as having side effects that the
optimizer must not eliminate:

```
asm volatile("wfe" :::)
```

Assembly is inherently non-portable. The `@[target("aarch64")]` or
`@[target("x86_64")]` attribute can guard architecture-specific
blocks.

---
