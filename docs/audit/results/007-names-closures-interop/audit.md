# Audit 007 — Names, closures, and C interop

## Disposition

This is a bounded source-of-truth audit of overview targets 10, 11, and 17. It
does **not** mark any of those modules complete. The pass found three confirmed
defects, one deliberate but important verification gap, and several
source-supported risks that need target-specific or broader dynamic coverage.

| ID | Finding | Severity | Blast radius | Confidence |
|---|---|---:|---|---:|
| A7-01 | An escaping capturing closure retains a pointer to stack capture storage | Critical | Every returned/stored/passed capturing closure; captured ownership and cleanup | High |
| A7-02 | Generated C owning wrappers may call a destructor on a null constructor result | Critical | Curated and user-declared nullable owning constructors | High |
| A7-03 | Native Linux x86_64 `c_longdouble` is emitted as `f64` although the host C ABI uses 16 bytes | High | Calls, callbacks, globals, aggregates, and variadics involving `long double` | High |
| A7-04 | `--dump-resolved` omits imported function bodies by construction | Medium verification gap | Cross-module resolution audits and debugging | High |
| A7-05 | Closure and indirect-call ABI is re-derived on several paths instead of read from one `FnAbi` | Critical structural non-compliance | Closures, function pointers, dynamic/trait calls, large aggregate arguments/returns, platform ABIs | High from source; cross-platform failures not reproduced here |

No silent C-import stub or silently dropped translated declaration was confirmed
in this bounded pass. The importer has explicit omitted-symbol plumbing and
strict-mode tests. That is not a completeness claim for the migrator.

## Provenance and method

- Source tree: `/home/shawn/workspace2/with`
- Source HEAD audited: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`
- Host: Linux x86_64
- Executable used for bounded probes: `out/release/bin/with`, reporting
  `with v0.15.1.7-gc83b13f66`
- The executable's stamped commit `c83b13f66` is not an ancestor of audited
  HEAD; their merge base is `c994145d593791aad85522244b627b732fb20ddd`.
  Therefore the probes establish behavior in the available installed artifact,
  while exact branch and line attribution below is to current HEAD. The same
  defect shapes are present in both observed behavior and current source, but
  this pass did not build HEAD and does not claim a same-revision binary proof.
- Discovery started with the repository knowledge graph. Its With-language
  coverage was insufficient for these paths, so source inspection continued
  with Tilth and narrowly scoped With search one-liners.
- Build was not used as experimentation. The pass used four small compiler/run
  discriminators and existing test/source evidence.

## A7-01 — Escaping closures point into a dead stack frame

### Exact source path

`src/SemaCheck.w:13915-13953` distinguishes non-escaping from escaping
closures and permits escaping captures, consuming non-Copy captured values where
required. Escaping is therefore an accepted semantic path, not rejected syntax.

`src/CodegenDispatch.w:17490-17510`, in `gen_closure`, builds the capture
struct with `create_entry_alloca(cap_struct_type)` and assigns that stack address
to `ctx_ptr`. `src/CodegenDispatch.w:17515-17523` then returns the fat closure
pair `{fn_ptr, ctx_ptr}`. No environment promotion, owned allocation, lifetime
extension, or environment drop glue occurs on this branch.

### Executable discriminator

The release artifact accepted and ran:

```with
fn make:
    let x = 41
    () => x + 1

fn stomp:
    let y = 999
    let g = () => y + 1
    g()

let f = make()
print_i32(stomp())
print_i32(f())
```

Observed output was `1000` followed by `1001`, exit zero. The second result must
be `42`. Calling `stomp` reused the returned closure's former stack storage, so
`f` read `y` through a dangling context pointer. A control that invoked `f`
without deliberately reusing the frame printed `42`, demonstrating why ordinary
happy-path tests can miss the defect.

### Five Whys

1. Why did `f()` return `1001`? It read the later `stomp` capture value.
2. Why could it see that value? Its context pointer addressed a reused stack
   slot from `make`.
3. Why did an escaping closure retain a stack pointer? `gen_closure` allocates
   every capture struct with an entry-block `alloca`.
4. Why was the environment not kept alive or destroyed later? The closure value
   is only a function/context pointer pair; it has no owned-environment lifetime
   or drop representation.
5. Why did semantic escape analysis not prevent this? Sema uses escape status to
   govern capture legality and moves, but code generation does not turn that
   status into an environment storage and cleanup policy.

### Correct repair boundary

This is not fixed by copying the stack bytes or by heap-allocating without a
destructor. The repair spans closure representation, Sema/MIR ownership,
codegen, and cleanup:

- non-escaping closure environments may remain stack/by-reference when proven;
- escaping environments need an owned lifetime (heap, caller-owned closure
  object, or another proved region);
- moved captures must be initialized once, moved with the closure correctly, and
  dropped exactly once;
- captured borrowed views must not escape their valid region;
- normal return, early return, panic/unwind, cancellation, and overwritten/moved
  closure paths need the same cleanup truth;
- indirect invocation must consume the same central `FnAbi` as its callee.

### Regression matrix

- zero, one, and multiple captures; Copy, non-Copy, and custom-Drop captures
- move and non-move closures; mutable captures and nested closures
- immediate call, returned closure, stored closure, argument/return round-trip,
  repeated call, closure move, and closure destruction
- rejected escaping borrow versus accepted owned capture
- normal, early-return, panic/unwind, and task/cancellation cleanup edges
- direct and indirect invocation with scalar and large aggregate args/returns
- debug allocator leak, double-free, invalid-free, and use-after-return verdicts
- Linux/Darwin/Windows and arm64/x86_64 ABI coverage

## A7-02 — Nullable C constructors create invalid owners

### Exact source path

`src/CImport.w:1388-1401`, in `ci_owned_return_destructor`, curates owning
return/destructor pairs including `fopen`/`fdopen`/`tmpfile` → `fclose`,
`opendir` → `closedir`, and `strdup`/`strndup` → `free`.

`src/CImport.w:1563-1600`, in `ci_emit_owning_wrapper`, emits a
`COwned_*` wrapper whose constructor stores the raw return pointer directly.
The emitted `Drop.drop` unconditionally invokes the paired destructor with
`self.handle`. There is no null check and no `Option`/`Result` construction
boundary.

### Executable discriminator

A unique inline C header declaration for `fopen`/`fclose` produced an owning
wrapper whose generated Drop called the destructor unconditionally. Opening the
known-absent path `/definitely/not/a/real/with-audit-file-0901` produced a null
handle (confirmed by printing `1` for `handle() == null`) and then exited with
status 139 at scope cleanup. That is the ordinary C failure path, not malformed
raw-pointer use by the With program.

### Five Whys

1. Why did a failed `fopen` crash at scope end? Generated Drop called
   `fclose(NULL)`.
2. Why could a generated owner contain null? The wrapper stored the constructor
   return without testing it.
3. Why was Drop unconditional? The generated ownership type assumes construction
   proves a valid resource.
4. Why does construction not prove validity? The overlay records only a
   constructor/destructor pairing, not the constructor's nullable/failure
   contract.
5. Why can the importer not choose a safe surface? Its ownership overlay schema
   lacks the success predicate/nullability needed to distinguish “owned
   resource” from “failed acquisition.”

### Correct repair boundary

The ownership-overlay schema and `ci_emit_owning_wrapper` both need the failure
contract. A defensive null guard in Drop prevents this crash, but is not the
complete ergonomic API: known nullable owning constructors should only create an
owner after a non-null success test and expose failure as the language-approved
`Option`/`Result` shape. User-provided `owns:` overlays need the same explicit
nullable/non-nullable contract and validation. Destruction must remain exactly
once across moves and abnormal exits.

### Regression matrix

- success and failure for curated `fopen`, `fdopen`, `tmpfile`, `opendir`,
  `strdup`, and `strndup` overlays
- equivalent explicit user ownership annotations
- nullable versus proven-non-null constructors
- destructor call count on normal scope exit, move, early return, and panic
- handle extraction/borrowing without duplicating ownership
- native crash detection plus debug allocator leak/double-free checks

## A7-03 — Host C `long double` layout is misrepresented

### Exact source path

`src/CImport.w:581-595` rejects non-native target use through
`target_spec_is_native`, but accepts the active host. `src/TargetSpec.w:24-27`
defines native as no active target or the host target. Once admitted,
`src/CImport.w:628-640` emits an explicitly “arm64 macOS” alias block on every
native host, including `type c_longdouble = f64`.

### Executable discriminator: confirmed host fact

On the audited Linux x86_64 host, an inline header exported Clang's
`__SIZEOF_LONG_DOUBLE__` and `__SIZEOF_LONG__`. The release artifact printed:

```text
16
8
8
8
```

Those are, respectively, C `long double`, With `sizeof[c_longdouble]()`, C
`long`, and With `sizeof[c_long]()`. Thus the active host C ABI reports a
16-byte `long double`, while c_import publishes an 8-byte `f64`. `long` happened
to match on this host.

### Five Whys

1. Why does With lay out C `long double` as 8 bytes on this host? The generated
   alias is `f64`.
2. Why is that alias emitted on Linux x86_64? The alias block is hard-coded for
   arm64 macOS but used for every admitted native target.
3. Why did the platform gate not reject it? The gate tests only native versus
   cross target, not whether the target has the assumed C data model.
4. Why is the actual C type model not used? Builtin C sizes, alignments,
   signedness, and calling classifications are not sourced from libclang/target
   metadata into one authoritative table.
5. Why is `f64` especially dangerous here? It lies about both numeric semantics
   and physical ABI, so downstream layout and call lowering cannot recover the
   lost type information.

### Correct repair boundary

C builtin facts must come from one target-derived C ABI model used by importer,
type layout, Sema, callback construction, and backend calling convention. If the
compiler cannot represent the target's extended floating type and LLVM ABI
classification yet, by-value `long double` declarations must fail loudly rather
than alias to `f64` or an ABI-inert byte blob. Pointer-only opaque access can be
separately modeled when safe.

### Confirmed fact versus cross-platform candidates

- **Confirmed on the actual host:** Linux x86_64 `long double` is 16 bytes and
  `c_longdouble` is 8 bytes.
- **Not executed here:** the same hard-coded block makes Windows LLP64 `long`
  (`i64` in the block) a likely ABI mismatch, and target-dependent plain-char
  signedness and `long double` formats are also at risk. These are source-derived
  cross-platform candidates, not runtime findings from a Windows artifact.

### Regression matrix

- compare Clang builtin size/alignment/signedness macros to every emitted C
  builtin type on each supported host/target
- parameters, returns, globals, callbacks, and variadic arguments
- direct fields, nested structs/unions, arrays, and packed/aligned aggregates
- Darwin/Linux/Windows; LP64/LLP64; arm64/x86_64
- explicit loud diagnostics for unsupported target C types

## A7-04 — Imported bodies are absent from the resolution dump

### Exact source path and observation

`src/Resolve.w:1-4` describes the resolver as scaffolding that does not replace
Sema. In its module walk, `src/Resolve.w:412-416` sets
`walk_bodies = module_id == 0` and passes that flag to function resolution.
Imported modules therefore contribute declaration/type information but their
function bodies are intentionally not walked.

Running `check test/behavior/issue59_imported_user_methods_dump_mir.w
--dump-resolved` succeeded but reported only imported-module signature uses for
module 2. Body uses visible in
`test/behavior/lib/issue59_queries/methods.w`—including `Counter`, member
accesses, and lookup calls—were absent.

This is not evidence of runtime mis-resolution: Sema remains a separate
authority. It is a verification defect because a dump named “resolved” cannot
establish prelude/import/alias/shadowing correctness across module bodies.

### Five Whys

1. Why are imported body uses missing? `walk_bodies` is false outside module 0.
2. Why is that allowed? Resolve is explicitly transitional scaffolding.
3. Why does compilation still work? Sema performs its own resolution.
4. Why is the dump misleading for an audit? It exposes only the partial Resolve
   graph, not Sema's full semantic bindings.
5. Why is this durable risk? Two resolution authorities can drift, and neither
   artifact alone proves all bindings consumed by later compilation.

### Repair boundary and matrix

Preferred boundary: one complete resolved-program graph, consumed by Sema/MIR,
covering root, imported, transitive, and generated code. If that foundation is
not yet ready, the partial artifact must be named/labeled as partial so it is not
used as proof. Test root/import/transitive/cyclic modules; prelude and explicit
imports; module aliases; local/parameter/member shadowing; overloads,
extensions, traits, and generated symbols; and private/unresolved/ambiguous
diagnostics with source spans.

## A7-05 — Closure and dynamic-call ABI has multiple authorities

The repository contract requires `FnAbi`/`PassMode` to be computed once and
consumed by callee and every call site. Current closure paths do not meet it:

- `src/CodegenDispatch.w:411-450`, `mir_build_closure_fn_type`, reconstructs a
  closure signature and special-cases direct returns.
- `src/CodegenDispatch.w:15030-15168`, `mir_emit_call`, rediscovers
  function-pointer/fat-closure shapes and independently chooses sret,
  by-value/address passing, and parameter-count behavior.
- `src/CodegenDispatch.w:17047-17206`, `gen_closure`, builds another LLVM
  signature, including a Win64 indirect-parameter branch.
- `src/SemaCheck.w:14791-14859` checks callable types and capture effects but
  does not hand these paths one physical ABI descriptor.

This is confirmed structural non-compliance and the repair boundary is the
central function-ABI descriptor, not another closure-specific condition. The
Linux escaping-closure failure in A7-01 is independently reproduced; this pass
did not reproduce a second platform-specific aggregate ABI failure. Large
aggregate closure calls, function pointers, may-suspend indirect calls, trait
objects, and dynamic dispatch remain high-priority executable matrix work.

## Target coverage notes and source-supported risks

### Names, imports, aliases, shadowing, and generated identity

The pass mapped `src/Resolve.w`, the candidate/import/visibility machinery in
`src/Sema.w:1150-1163` and `2512-2674`, the hard-coded prelude gate at
`src/Sema.w:1260-1289`, and qualified extension aliases at
`src/SemaCheck.w:14861-14915`. No executable name-resolution defect was
confirmed within the bound.

Two risks remain:

- `src/Sema.w:2666-2674` and nearby paths expose separate node-visibility and
  gated symbol-visibility decisions. Their equivalence under re-export,
  synthetic prelude, and aliasing was not exhaustively established.
- Closure/generic generated identity sometimes reconciles symbols by textual
  equality across pools (for example `src/CodegenDispatch.w:17094-17114`),
  rather than one canonical symbol identity. Collision and shadowing behavior
  needs adversarial generated-name tests before target 10 can close.

These are source risks, not confirmed wrong-code findings.

### Closures, dynamic calls, may-suspend paths, and cleanup

Parser and AST closure flags (`src/Parser.w:7185-7297`,
`src/Ast.w:1552-1574`), Sema capture analysis
(`src/SemaCheck.w:13660-13964` and `src/Sema.w:5548-5580`), and the principal
codegen paths were inspected. The existing `test/mut_move_closure.w` exercises
directly called closures despite describing escaping behavior; it does not
return or store a capturing closure and therefore does not cover A7-01.

Trait/dynamic dispatch, indirect may-suspend transitions, and all captured-value
cleanup edges were only mapped, not exhaustively executed. Target 11 remains
open even after A7-01 is repaired.

### C interop and migration boundaries

The pass inspected target admission/type aliases, owning overlays, ordinary
function translation, omitted-symbol recording, macro translation, and frontend
error propagation. Existing tests cover callbacks, raw pointers, structs,
macros, strings, and strict omitted-symbol diagnostics. No `long double` test or
nullable owning-constructor failure test was found in the inspected surface.

Callback ABI, variadics, link-name preservation, C-string lifetime/encoding,
record layout beyond the confirmed `long double` case, and migration of complex
headers remain incomplete audit cells. Unsupported translation must continue to
produce a named diagnostic and non-zero exit; emitting an extern, stub, omitted
clause, or semantic simplification as success is forbidden.

## Related issue references and likely unreported defects

Source comments reference #357 (ownership wrappers), #379 (buffer/C-string
overlays), #750/#751 (resolution work), #761 (copied global ownership), #799
(Windows C-import coverage), and #806 (call ABI). This bounded offline pass did
not query issue status and does not assert whether any finding is already filed.

The following need deduplication against the tracker before filing:

1. returned capturing closure retains stack environment (A7-01);
2. nullable owning constructor is unconditionally destroyed (A7-02);
3. native Linux x86_64 `c_longdouble` ABI/layout mismatch (A7-03);
4. resolved dump omits imported bodies and cannot prove cross-module resolution
   (A7-04).

## Recommended repair order

1. Stop or reject escaping capturing closures until an owned environment and
   complete cleanup model exists; then implement the full A7-01 boundary.
2. Prevent construction/destruction of null C owners and add nullable acquisition
   semantics for all owning overlays.
3. Fail loudly for unrepresentable host C builtins, then introduce a single
   target-derived C ABI type model.
4. Finish the central `FnAbi` migration for closure, pointer, trait/dynamic, and
   may-suspend call paths.
5. Make the resolution artifact complete and authoritative, or unmistakably
   partial, before using it as an audit oracle.

## Limitations and completion claim

- No full build, fixpoint, full suite, debugger session, sanitizer run, or
  debug-allocator campaign was performed.
- Runtime probes used the available stamped release artifact, not a fresh binary
  from audited HEAD.
- Only Linux x86_64 was executed. Darwin and Windows observations above are
  explicitly candidates unless labeled otherwise.
- Imported-name semantics, dyn-trait dispatch, may-suspend indirect calls,
  callbacks, variadics, C-string lifetime, link names, and complex C record
  layout were not exhausted.
- The test search was bounded; absence means “not found in inspected scope,” not
  proof that no test exists anywhere.

Accordingly, targets 10, 11, and 17 all remain open. This report is a defensible
finding set and repair map, not a module-completion certificate.
