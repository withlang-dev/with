# Package bundles: a program that imports a package does not recheck it (#3401)

**Status:** design, rewritten 2026-11-20 on Eric's rulings of that day.
Nothing here is implemented.

**The rule (Eric).** An importer reads the interface, never the body; the
interface records what was inferred.

## The problem

A program that imports a large package for one function has every body of
that package checked, lowered and generated on each build. The compiler's own
tests had this cost (a 31-line test that says `use Sema` spent 34 s in Sema);
a tree bundle removed it (`internals-tests` 260 s to 16 s, #3393). A user's
program with a large dependency still pays it.

## What exists

- **A stored bundle** (`.wo`, wo_bundles.md): object, interface (`.wi`),
  manifest. Level 0: no initializer, private copies of the std functions it
  reaches and never of their globals, `pub` declarations only. Used for the
  migrated corpora and the runtime.
- **A tree bundle** (#3351): the same three files for one checkout's own
  directories, read only by the compiler that wrote it in the same build. It
  may carry an initializer, the package's private view, and carried globals.

A package bundle is the stored form plus what a user's package needs and
Level 0 forbids: an initializer and globals. No third format.

## Rulings this design is built on

| Question | Ruling (Eric, 2026-11-20) |
|---|---|
| What crosses the boundary | The interface, never the body. The interface records what was inferred. |
| A generic's private callees | Compiled into the bundle and linked by the instance. |
| The standard library | After user packages. |
| A `pub` function with an inferred return type | The inferred type is printed into the interface; a changed interface is detected and importers are rechecked. |
| Other inferred facts (origins, effects, suspension) | The same: printed into the interface. |
| D178 (written field paths) | Unchanged: within a package a `mut` call mutates the paths the callee writes; across packages it mutates the whole place. |
| An interface change nobody typed | Reported to the author when the package is built (below). |

## The design

### 1. The unit is a package

A package is what D100 calls one: the directory of a `with.toml`, or a
dependency `with get` fetched. A workspace member is a package. The program
being built is never bundled; its dependencies are.

### 2. One bundle per (package inputs, compiler generation, target)

- **Where:** beside the other per-user caches, never in the project tree and
  never committed. A user does not name it, see it or clean it.
- **Key:** the digest of the package's source files and its `with.toml`, the
  compiler's generation (D132), the target, and the *interface* digests of
  the packages it imports. No timestamp and no path (D49, D50).
- **Built by:** the build, on first use. A missing or stale bundle is rebuilt.
- **A fetched dependency** is immutable once pinned, so its bundle is built
  once per compiler generation and target.

### 3. The interface records what was inferred

The importer reads the `.wi` and never the sources. For each `pub`
declaration the interface carries its signature as written, and beside it
every fact a caller reads that the compiler inferred from the body:

| Fact | Printed as |
|---|---|
| Return type, when not written | the type |
| Parameters a returned view comes from, when there is no `from` | the origin parameters, and for each whether the view points into its own storage or only into what it views |
| Globals a returned view comes from | the globals |
| Parameter effects | escapes by value, escapes by view, raw-pointer validity |
| A callable parameter invoked more than once | per parameter (§12.4) |
| Suspension | whether the function may suspend |
| Reads and writes of `pub` globals | the declared write contract (§21.1 rule 1) |
| Creation of a task that must not escape | per function |

Written field paths are not printed: across a package a `mut` call mutates
the whole place (D178).

**The measurement behind this (2026-11-20, non-generic `pub` functions):**
`lib/` has 1,933 and `examples/` 97. Of those, 50 rely on an inferred return
type, 46 return a view with no `from` and none has two possible origins, 26
have an inferred escape effect, 15 invoke a callable parameter more than
once, 7 may suspend. Refusing inference would have meant about 95
annotations stating what the compiler knows.

### 4. Generics and `comptime` travel as source

A generic function or type is the importer's to instantiate. The interface
carries its declaration's source text, and the importer checks and
instantiates it as today. A `comptime` function the importer may call
travels the same way.

A generic body's private callees are compiled into the bundle, and the
instance links to them. The bundle is private to one compiler generation,
so those symbols are not a lasting ABI.

The saving is the non-generic bodies. A package that is mostly generic
saves little; that is this design's limit.

**What "a `comptime` function the importer may call" means (Eric,
2026-11-21).** A compile-time call that crosses a package boundary reaches
only a `comptime fn` (§17.1). So the bodies a bundle carries for the
evaluator are exactly those of its `pub comptime fn`s and of every function
of the package they reach. A `comptime fn` whose compile-time answer the
compiler supplies (the runtime's target queries) crosses as a declaration
without a body.

**The build and compiler APIs.** They need no marker: they run under
driver-minted capabilities (§17.1b) and the capability registry states
which functions they are. A user's `build.with` is evaluated at compile time
and calls them, so once the standard library is a bundle their bodies must
still reach the evaluator. This design's answer: **they cross the boundary
with their bodies**, exactly as a `comptime fn` does, and the registry is
the list of them. The alternative, the driver supplying them natively,
would need a native twin of every registry function kept in step with its
source, and a build file would then run different code when evaluated
against a bundle than against source. One mechanism keeps "a program built
with bundles and one built from source accept and reject the same
programs" true for build files too. This is to be confirmed before
standard-library bundling (step 6) starts.

**The question is wider than the registry (Eric, 2026-11-21).** The rule
does not apply in the capability-bearing mode at all: a build file or a
tool may call any function of any package (`env`, `print`, a helper
package's functions). So in that mode the evaluator may need the body of
any function in any package, not only the registry's, and a bundle built
for importers that only check and link carries none of them. Still open:
how the evaluator gets those bodies when packages are bundles. The
candidates are that a build file's dependencies are read from source (a
build file's imports are few, and a fetched package's source is on disk
beside its bundle), or that every bundle carries every body for this mode.
The first keeps bundles small and is this design's proposal; it is to be
decided with the question above.

### 5. Globals and initialization

- A package's globals are storage in its bundle, initialized by the
  bundle's initializer. The program's main wrapper runs the initializers of
  the bundles it links, in dependency order, before its own.
- A program links one copy of each package bundle, so a package's global
  has one instance.
- A `pub` function's writes of `pub` globals are declared and cross; writes
  of private globals do not appear.

### 6. What invalidates what

- An edit that leaves the interface text unchanged rebuilds that package's
  bundle and relinks its importers. They are not rechecked.
- An edit that changes the interface, typed or inferred, rechecks the
  importers that name what changed. This is why an importer's key holds each
  dependency's interface digest and not its source digest.

### 7. Telling the author about an interface change they did not type

Under the rule, editing a body can change a `pub` function's interface: its
inferred return type, its origins, an effect, whether it may suspend. For
the author's own tree that costs a recheck. For a package other people
depend on it is a breaking change nobody saw.

- **What is compared.** The interface the build just produced for the
  package against the interface of the previous build of the same package
  for the same target, kept beside the bundle in the per-user cache. Only
  inferred facts are compared here; a signature the author edited is a
  change they typed.
- **Where it is printed.** In the build's own output, once per package, as a
  note after that package is built:

  ```
  note: package `shapes`: 2 inferred facts in its interface changed
    area(s: &Shape): return type i32 -> i64
    first(xs: &List[Tag]): now may suspend
  ```

- **First build.** With no previous interface there is nothing to compare,
  and nothing is printed.
- **A published package.** The step that publishes a package should compare
  against the last *published* interface instead of the last local build,
  and print the same lines. No such step exists yet; whether a change must
  be acknowledged before publishing belongs to its design, not this one.
- It is a note, never an error: the program is correct, and the author is
  the only one who can say whether the change was meant.

## What it does not do

- It does not change which programs are accepted. A program built with
  bundles and one built from source accept and reject the same programs.
- No new file format, no new user command, nothing in `with.toml`.
- It does not bundle the program under construction.

## Order of work

1. The interface printer for a user package: `pub` declarations with their
   inferred facts, generics as source. Checked by compiling an importer
   against the `.wi` alone and comparing with a from-source check: the same
   programs accepted, the same diagnostics.
2. The package bundle build and its key, for a workspace member.
3. Initializers for more than one bundle, in dependency order.
4. The inferred-change note (item 7), against the previous local build.
5. Fetched dependencies (`with get`), after D212: they are built from
   source, so the same build produces their bundle.
6. The standard library.
