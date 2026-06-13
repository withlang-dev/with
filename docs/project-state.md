# Project State

Status: active checkpoint for agents. Update this file when phase status,
blockers, or the next work queue changes.

Last updated: 2026-06-12.

Read this file immediately after `AGENTS.md`. It exists so long-running build
system and bootstrap work does not have to be reconstructed from git history or
conversation context after compaction.

## Current Focus

#387 is implemented and verified. Sema now records whole-program concurrency
evidence from async constructs, `std.thread.spawn_os`, `@[c_export]`, and
extern C callback coercions, records global reads/writes after body checking,
and enforces §9.1c with E0921 when a bare mutable global access depends on a
single-thread proof that has failed. Never-mutated globals and implemented
atomic globals remain safe; std/runtime internals are excluded from this
user-facing rule until their translated low-level globals are cleaned up
separately. Unsafe global accesses count as proof-dependent unsafe operations:
they satisfy the unsafe-use checker, require no diagnostic when concurrency is
present, and warn in user code when the current single-thread proof covers
them. Focused coverage includes async mutation/read E0921 cases, single-thread
mutation, never-mutated reads in async-enabled programs, atomic globals, and a
self-host warning check; existing async cancellation fixtures now spell their
intentional global witness access with `unsafe`. Full verification passed on
2026-06-12: `with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green`. Remaining Phase 4 issue: #402.

#373 is implemented and verified. Definition-site effect finalization now
rejects by-value parameters whose returned view is derived from that consumed
parameter, with a §22.3-style diagnostic naming the function, parameter,
by-value origin, escaping expression, and `&T` remedy. Read effects are now
recorded for ordinary identifier use and normalized away when stronger effects
such as write/consume/escape are present, preserving existing `@[effect]`
contracts while enabling the conservative read-only by-value warning. Call-site
returned-view origin recording no longer treats by-value parameters as valid
borrow anchors. Focused coverage includes explicit-return, tail-expression, and
nested-field dangling-view errors, a borrowed-parameter positive spec case, the
read-only warning plus `&T`/Drop exemptions in CLI edge tests, and the
`behav_effect_pin.w` normalization regression. Full verification passed on
2026-06-12: `with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green`.

#458 is implemented and verified. The no_std tier model now rejects std-only
module imports from the resolved module graph, so `std.io`, `std.fs`,
`std.net`, `std.sync`, and other OS/runtime-backed std modules cannot leak
through `use` declarations under `--no-std`. Async syntax and async function
declarations now diagnose `requires std/fiber runtime` in no_std user code,
and constructed alloc-backed builtins such as `Vec[T]`, `HashMap[K, V]`,
and pending `Vec.new()`/`HashMap.new()` receivers are gated before falling
through to unknown-type or unresolved-symbol paths. Focused coverage includes
core no_std rejection for Vec, HashMap, async fn, and await; alloc no_std
allowing Vec while still rejecting async and std-only imports; and existing
core/alloc no_std positives. Full verification passed on 2026-06-12:
`with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green`.

#457 is implemented and verified. `std.fixed_string` now exposes
`FixedString[N]` through all preludes, including `prelude_core`, with compiler
support that maps `FixedString[N]` to stack storage and lowers `new`, length,
capacity, `clear`, `push_byte`, `push_str`, `as_view`, and `equals` without
heap allocation or string-runtime calls. Positive coverage exercises normal
use and the `core`/`--no-std` surface; negative coverage rejects dynamic and
mismatched type-level lengths. The no-std object check has no forbidden
allocator/string symbols. During verification, MIR moved-value ownership was
tightened so `async scope s.track(task)` consumes the raw `Task` owner without
leaving a second detached cleanup, while `Task.cancel()` still preserves the
required cleanup await for `no_suspend` diagnostics. After rebasing onto the
§3.8 by-value consume flip, build action/helper APIs were conformed so
`ActionCtx`, `BuildCtx`, `ToolFs`, argv vectors, and action result structs are
borrowed at read-only helper boundaries while stored action callbacks remain
the bootstrap-compatible `fn(ActionCtx) -> i32` shape. Full verification
passed on 2026-06-12: `with build`, `with build :fixpoint`, `with build
:test`, and `with build :test-green`.

#567/#573/#574/#575/#576/#577 are implemented locally and verified. The generic
template lowering skip now handles blanket-impl generic functions before MIR
lowering (#576/#577); comptime eval now writes evaluator Sema state back to the
caller instead of dropping type-table mutations (#574); chained/pipeline/in
method receivers reuse the already-checked receiver type (#573); raw pointers no
longer participate in view-origin escape tracking and the spec documents that
they are not views (#575); and the method-argument distinct-base carve-out is
removed, backed by de-distincted compiler-internal `NodeId`/`TypeId` aliases
and explicit `BlockId` casts at real MIR boundaries (#567). The build driver
was also conformed to the full by-value rule by borrowing read-only action
contexts, tool filesystem handles, command argument vectors, and result
records. Full verification passed on 2026-06-12: `with build`,
`with build :fixpoint`, `with build :test`, and `with build :test-green`.

#437 is implemented locally and focused tests pass. `std.alloc` now has real
region `Arena` allocation with mark/reset watermarks, `FrameArena` with
external reset and high-water tracking, and a fixed-block `Pool`/
`PoolAllocator` that reuses freed slots. `ArenaScope` now uses the real arena
watermark model. Borrowed-allocator container virality is covered by
ephemeral `ArenaVec[T]` plus unsafe raw-pointer helper functions; storage in a
non-ephemeral struct is rejected. The codegen generic-call binder now infers
type parameters nested under pointer/reference/slice/array wrappers, with
`behav_generic_pointer_binding.w` pinning the regression. Builtin `Vec.new_in`
ABI/runtime work remains tracked separately in #570, and broader generic
constructor/method limitations are recorded on #391. Focused coverage for
arena region reuse, frame reset/high-water behavior, pool reuse, ArenaVec local
use, ArenaVec storage rejection, ArenaScope, TempArena, no_alloc arena
approval, and generic pointer binding passes.

Phase 4 is in progress. #350 is implemented and verified. Task values now
follow the §14.7 position-based disposition contract: statement-position task
creation detaches only after must-observe and detach-safety gates pass, bound
task handles must be used before scope exit, `let _ = <Task>` is rejected as a
discard spelling, and mentioning an existing task handle as a statement is not
detachment. MIR lowering records accepted detached task statements and emits a
non-canceling `with_fiber_detach` runtime handoff; explicit `Task.cancel()`
continues to lower through the canceling handoff. Focused coverage includes
positive detach behavior, must-observe rejection, detach-safety rejection,
`let _` rejection, unused bound handles, explicit cancellation, no_suspend task
cleanup, and the unsafe ephemeral-task assertion path. Full verification
passed on 2026-06-12: `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green`.

#411 is implemented and verified. `std.alloc` now exposes public `Arena` and
`ArenaScope`; `Arena.scope()` creates a `@[no_await_guard]` ephemeral scope
that records allocations, frees them on `reset()`/drop, and supports
`alloc`, `alloc_zeroed`, and `allocation_count` for the interim TempArena-style
semantics until #437 replaces the internals with real region allocation.
Focused coverage pins allocation smoke behavior, explicit drop before await,
`with arena.scope() as mut` ending before await, and E0701 rejection for plain
bindings, may-suspend calls, and `with` blocks that hold an ArenaScope across
suspension. Full verification passed on 2026-06-12: `with build`,
`with build :fixpoint`, `with build :test`, and `with build :test-green`.

#361 is implemented and verified. `@[no_alloc]` is now a
function attribute recorded in AST metadata and registered by Sema. Sema keeps
deterministic allocation-site metadata (AST node, construct kind, enclosing
function symbol, and elision bit), propagates a per-function may-allocate
summary, and rejects hidden/ambient allocation in `@[no_alloc]` contexts with
construct-specific diagnostics. Current attribution covers f-strings,
comprehensions, owned string literals unless deterministically elided, async
task/fiber creation, `Vec.new()`/`with_capacity`, direct allocator APIs,
allocating callees, and explicit `ArenaScope`/`TempArena` capability methods.
Focused coverage includes negative f-string, comprehension, owned literal,
async fn, async block, Vec constructor, and allocating-callee cases, plus
positive `&str` static literal, direct-return owned-literal elision, and
explicit arena-approved allocation cases. Full verification passed on
2026-06-12: `with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green`.

#362 substrate work is implemented locally and
focused tests pass. Binding-level provenance is now carried in a single
`BindingProvenance` record per scope binding, replacing the previous split
task-ephemerality vector and binding-view maps while preserving the existing
query helpers. Let/var bindings and assignments now propagate value-level
ephemerality explicitly, Drop-bearing values record view provenance through
struct literals, and focused coverage pins local `Vec[ephemeral]` use,
nested generic field rejection (`Option[Ephemeral]`), and ephemeral Task
assignment propagation into generic-container storage. Full verification is
complete: `with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green` passed on 2026-06-12. The first full-suite run hit a
transient Conan/raylib package download failure; `cli-selfhost-project-tests`
passed on rerun before the final clean full-suite pass. #362 is now closed:
its named Phase 4 consumers #378 and #355 have both landed on top of this
substrate.

#378 is implemented and pushed. Returned-view provenance now poisons surviving
bindings when any possible stack origin leaves scope, then rejects the first
later use with the §21.1 Rule 6 / §22.3 diagnostic contract: the diagnostic
labels the view assignment, the origin scope that ended, and the later use, and
includes a copy-or-outer-scope remedy. The expression-origin query now derives
dependencies from recorded call effects as well as direct reference/value-node
fallbacks, so reassigned views through helper calls are handled the same way as
direct `&origin` assignments. Focused coverage includes three negative
use-after-origin-death cases, including a >31-parameter conservative-origin
regression, a positive case where the last use precedes origin death, and the
existing returned-local-reference and two-origin view tests.
Full `with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green` passed on 2026-06-12 for #378.

#477 is implemented and pushed. Stdlib synchronization guards
(`MutexGuard`, `MutexGuardMut`, `RwReadGuard`, `RwWriteGuard`), borrowed-data
iterators (`VecIter`, `VecIterPlace`, `MapIter`, `FilterIter`, `TakeIter`,
`ZipIter`, `FlatMapIter`), and scoped borrowed handles (`VecSlot`,
`SlotMapSlot`, `HashMapEntry`) are now declared `ephemeral`. Focused coverage
rejects guard/iterator/handle storage in non-ephemeral structs and escaping
closure capture of a live iterator, while positive tests keep guard locals,
guarded `with` blocks, concrete iterator returns, iterator parameters, and
pipeline adapters working. Existing `with` slot/entry, iterator borrowing, and
§7 `with` block regressions pass. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-12 for
#477.

#355 is implemented and pushed. By-value ephemeral `Task` arguments now require
proof that the callee consumes the task in scope; unproven ordinary callees are
hard errors instead of warnings, extern callees remain hard errors even inside
`unsafe`, and explicit `unsafe` on ordinary unproven callees records the
operation as the programmer's assertion. The narrow deterministic summary is
memoized per function/parameter, cycle-conservative, and proves direct
`await`, direct `cancel`, and forwarding to another proven-consuming callee.
Task parameters are also recognized by type for `.await`, fixing the existing
gap where `fn consume(t: Task[T]): t.await` was rejected. Focused coverage
includes consuming and transitive-consuming callees, by-reference passing,
unsafe assertion, ignored/returned/unproven-forwarded escapes, and the existing
extern/container storage errors. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-12 for
#355. During the work, #569 was filed for the separate backend failure where
`Task.is_done()` on a `Task` parameter reaches an unhandled generic-call path.

#444 is implemented and verified.
Drop-implementing bindings now record concrete view dependencies from their
initializers and reassignments, including references stored inside struct
literals. Scope exit treats the implicit destructor call as a use under §21.1
Rule 7: if a Drop value still retains a borrow of a binding that is being
destroyed first, Sema emits a dedicated diagnostic with labels for the Drop
value and the destroyed origin. Focused coverage includes a negative
`err_implicit_drop_use_after_origin.w`, a positive same-scope declaration-order
case, and the existing Drop prelude use-after tests. Full verification is
complete: `with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green` passed on 2026-06-12 for #444.

#478 is implemented and verified.
The MIR tailrec contract verifier now carries a small Drop-local liveness
state alongside the existing syntactic tail-position and active-defer checks.
Recursive edges in a `@[tailrec]` SCC now reject when a Drop-implementing local
is still live across the call, while explicit `drop(local)` and `let _ = local`
end that local before the edge. Focused coverage includes a new negative
`err_tailrec_drop_local_live.w`, a positive explicit-drop tailrec spec test,
and the existing self, mutual, non-tail, and defer-cleanup tailrec regressions.
Full `with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green` passed on 2026-06-12 for #478.

#430 is implemented and verified. Expression
temporaries that own non-Copy values are now registered in deterministic
statement frames and dropped at the end of the enclosing statement, with
condition temporaries flushed before branch dispatch. Ownership handoff through
assignment, returns, `let _ =`, and by-value call arguments cancels pending
caller-side drops so moved values are not double-dropped. Conditional moves of
Drop locals are rejected loudly until drop-state flags exist, avoiding the
former false-path leak. Focused coverage pins discarded call temps,
field/method-chain temps, auto-ref temps, by-value temp arguments, reverse
creation-order temp drops, named move handoff, discard handoff, returned values,
partial moves from Drop temporaries, and conditional Drop moves. Full
`with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green` passed on 2026-06-12 for #430.

Phase 3 is complete. #544 is implemented and pushed: `panic`, `todo`,
and `unreachable` are ordinary `std.builtins` functions returning `Never`,
user calls no longer lower to raw LLVM `unreachable`, and backend-generated
unreachable terminators now call the runtime panic path before ending the
block. LLVM and emit-C type lowering both treat `Never` as a void ABI type.
Focused behavior and compile-error tests cover explicit panic, default/custom
`todo` and `unreachable` messages, `Never` use in value positions, argument
arity, named-argument rejection, and non-string messages. Direct
`await_first([])` behavior coverage is blocked by newly filed #558, where the
existing `impl IntoIter[Task[T]]` generic signature leaks unresolved `T`
during std.task checking.

#545 is implemented locally and verified. `Option.unwrap`, `Result.unwrap`,
`Option.expect`, and `Result.expect` now carry call-site locations through MIR
and guard their success discriminants before extracting payloads. Failure paths
panic through `with_panic` with source location, `None` messages, and
Debug-formatted `Err` payloads. The emit-C backend mirrors the guard for
payload enums, nullable pointers, and legacy encoded option values; aggregate
Err debug formatting fails loudly instead of emitting an unchecked extraction.
Focused behavior tests cover `None`/`Err` runtime panics and source locations,
compile-error tests cover bad `expect`/`unwrap` arity and message types, the
§10.6 spec test now covers successful `expect`, and `emit-c-smoke` compiles and
runs a generated-C `Result.expect` panic case. Full `with build`,
`with build :fixpoint`, `with build :test`, and `with build :test-green`
passed on 2026-06-11 for #545.

#438 is implemented and verified. Runtime f64 formatting now classifies
NaN/inf/signed zero from IEEE-754 bits instead of numeric thresholds, formats
finite default-display values through the shared deterministic decimal path,
and preserves special values as `nan`, `inf`, and `-inf`. Exponent float
literals are parsed by the runtime parser so large/small finite regression
tests exercise the intended values. New behavior coverage pins ordinary
default display (`3.14`, `10`, `1.5`, `0.5`, `0.001`), debug-display parity,
`1e308`, `1e-308`, signed zero, and NaN/+/-inf handling. Full `with build`,
`with build :fixpoint`, `with build :test`, and `with build :test-green`
passed on 2026-06-11 for #438.

#440 is implemented and verified. `with_fmt_f64_spec` now honors float mode
bytes from f-string specs: `:f` uses fixed-point with default precision 6,
`:e` uses scientific notation with default precision 6, `:g` uses general
display, and precision-without-mode continues to mean fixed-point. NaN/inf
classification is shared across modes, and the emit-C direct formatting path
now passes the mode argument to the five-argument runtime formatter API.
Behavior coverage pins explicit fixed/scientific/general modes, bare `:f` and
`:e`, width/sign/zero padding, and NaN/+/-inf under float modes; existing
compile-error tests cover invalid float/integer mode combinations. Full
`with build`, `with build :emit-c-smoke`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-11 for
#440.

#428 is implemented and verified. Native MIR codegen now emits debug-mode
bounds checks for fixed arrays, slices, strings, and Vec indexing while leaving
raw pointer indexing unchecked. Array and slice range expressions lower through
an explicit `RK_SLICE` MIR rvalue, with debug checks for negative starts,
end-before-start, and end beyond length before constructing the `{ptr, len}`
slice value. The parser now accepts leading-open ranges such as `arr[..]`,
slice `.len()` is recognized in Sema/MIR/C lowering, and the emit-C backend
emits first-class slice structs plus `slice.ptr[i]`/`slice.len` operations
instead of treating slices as arrays or integers. Behavior coverage includes
in-bounds array/slice/Vec use, array load/store out-of-bounds panics, negative
array indexes, slice element out-of-bounds panics, and slice-range
out-of-bounds panics. Generated C for the in-bounds slice test emits and
compiles to an object. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-11 for
#428.

#422 is implemented and verified. Integer bit-manipulation methods now have a
comptime evaluator path matching the existing runtime intrinsic surface:
`rotate_left`, `rotate_right`, `swap_bytes`, `popcount`, `clz`, `ctz`, and
`bitreverse` operate on fixed-width bit patterns for integer receivers.
Rotations normalize counts by width, `swap_bytes` is identity for 8-bit
integers, `popcount`/`clz`/`ctz` return `i32`, and zero `clz`/`ctz` return the
declared integer width. Signed receivers are evaluated through their declared
width bit pattern before being converted back to the receiver type where
appropriate. Behavior coverage pins representative comptime results for u8,
u16, u32, and signed i8 values, including oversized and negative rotate counts,
zero count operations, byte swapping, bit reversal, and signed popcount. A
compile-error test covers invalid comptime arity. Full `with build`,
`with build :fixpoint`, `with build :test`, and `with build :test-green` passed
on 2026-06-11 for #422. Follow-up #565 tracks the separate bug where pipeline
syntax for primitive intrinsic methods works at runtime but is rejected inside
`comptime`.

#446 is implemented and verified. `Int` and `UInt` are registered as prelude
primitive aliases for the canonical `i64` and `u64` TypeIds in both primitive
name registration and string-to-primitive fallback resolution; diagnostic type
names remain canonical (`i64`/`u64`). Focused behavior coverage exercises the
aliases in annotations, casts, generic type arguments (`Vec[Int]` and
`HashMap[str, UInt]`), and integer method dispatch. A negative compile-error
test proves `Int` uses the i64 literal range rather than u64 or pointer-width
rules. The alias behavior test also exposed and fixed a native LLVM verifier
bug for 64-bit `popcount`/`clz`/`ctz` results: count intrinsics now zext
sub-32-bit results, keep i32 as-is, and truncate i64 results to their specified
i32 return type. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-11 for
#446. The first full-suite run hit a transient Conan Center/raylib package
lookup failure; the project self-host target passed on rerun before the final
clean full-suite pass.

#546 is implemented and verified. `Unit` is now the only user-facing unit type:
the `"void"` primitive registration and fallback lookup were removed, unknown
source `void` now diagnoses with guidance to use `Unit` or `c_void`, and all
compiler/runtime/stdlib/test With source annotations were converted to `Unit`.
C interop keeps `c_void` for C `void*`; `c_import` and C migration translate C
`void` returns to source `Unit` instead of emitting With `void`. The migration
printer now keeps explicit `-> Unit` on translated C `void` definitions so
discard-only C statements cannot become inferred value returns. During this
cleanup, a native MIR cleanup bug was found and fixed: `with` guard cleanup
calls now write their Unit result to a fresh temporary instead of overwriting
the enclosing function return slot on early returns. Focused coverage includes
Unit/c_void public-surface behavior, rejection of source `void`, and a
Unit-returning guarded-with early-return regression. Full `with build`,
`with build :fixpoint`, `with build :test`, and `with build :test-green` passed
on 2026-06-11 for #546.

#460 is implemented and verified. `null` no longer defaults to `*const i8`;
it requires a contextual pointer-like target type. Raw
pointers, extern function pointers, and nullable pointer `Option` types remain
accepted, explicit `null as *T` casts now supply the cast target as context,
and safe references/integer contexts are rejected with directional diagnostics.
Comparison checking now types `p == null` and `null == p` from the non-null
operand while rejecting `null == 0`. Focused coverage includes §16.10 positive
pointer, optional-pointer, extern-function-pointer, argument, and comparison
cases plus negative tests for bare null, integer binding, `null == 0`, and
reference binding. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-11 for
#460. The first full-suite run hit a transient Conan Center/raylib dependency
fetch failure; `cli-selfhost-project-tests` passed on rerun before the final
clean full-suite pass.

#463 is implemented and verified. Opaque layout/value misuse now fails in Sema
before MIR/codegen: `sizeof[Opaque]()` and
`alignof[Opaque]()` reject unknown layout, local opaque value declarations
reject zero-initialized by-value storage, field access uses the shared opaque
diagnostic path, and existing function parameter/return checks are covered by
regressions. Pointer-to-opaque remains valid, including null initialization and
calls through unsafe pointer-taking functions; `c_void` remains pointer-only
and cannot be declared by value. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-11 for
#463.

#539 is implemented and verified. `transmute[T](value)` now requires unsafe,
exactly one value argument, a resolvable target type, known source/target
layouts, and equal source/target byte sizes during Sema. Size mismatch
diagnostics include both type names and byte counts. Codegen also has a
defensive tripwire for unchecked transmute size mismatches. The implementation
exposed and fixed the type-layout model for With `fn` values: closure/function
values are two-pointer records, while `extern fn` remains one pointer. Focused
coverage includes same-size integer transmutes, `fn` value to raw two-pointer
record transmute, unsafe-required, arity, opaque target, and size-mismatch
negative cases. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-11 for
#539.

Release UAT gates are implemented in With build actions, not shell scripts.
`with build :release-uat` now groups release artifact smoke, fresh project,
C migration, zlib, bzip2, sqlite3, OpenSSL, libcurl, install-layout, raylib
spiral, and one-liner gates. The zlib and bzip2 gates do in-memory
compress/decompress round trips. The sqlite3 gate opens an in-memory database
and verifies `CREATE TABLE`/`INSERT`/`SELECT`. The OpenSSL gate computes
SHA-256 of `"abc"` through the EVP API. The libcurl gate initializes curl,
sets an option, checks version metadata, and cleans up without network access.
Adding these gates also fixed root c_import/package issues: Conan metadata now
ignores OpenSSL provider modules that are not `-l` libraries, libcurl metadata
adds its Darwin framework link requirements, and c_import now keeps C tag/type
emission separate from value names so `struct timezone` is not hidden by the
global `timezone` variable. The raylib gate creates a fresh initialized project,
runs `with get c.raylib`, writes the spiral app to `src/main.w`, runs it, and
fails if raylib framebuffer readback does not find the rendered spiral. The
one-liner gate feeds stdin fixtures directly through `ProcessRunner` and checks
exact stdout for the `seq 100 | with -n ...` and `cat names.txt | with -p ...`
flows plus regex capture, numbered transform, semicolon transform, and `--`
argument cases. Full `with build`, `with build :fixpoint`, `with build :test`,
`with build :test-green`, `with build :last-green`, and `with build :release-uat`
passed on 2026-06-11 for the expanded C-package gate slice.

Phase 2 parser/control-flow work is complete. #461, #443, #445, #448,
#447, #462, #375, #382, #401, #543, #459, #371, #372, and #384 are
implemented, pushed, and closed.
`loop` is now expression-valued through `break expr`, plain `break`
contributes Unit, break values unify per loop, non-loop value breaks are
rejected, and no-break loops type as `Never`. Unreachable-code detection now
covers `goto`, true `Never` calls/expressions, and std process-exit APIs while
preserving goto target labels and labeled-block fallthrough through
`break 'label`. Unannotated function return inference now distinguishes
caller-visible provisional Unit signatures from body-local inferred
`return expr` and bare `return` results. Negated membership now follows
§9.9: `not x in y` parses as `not (x in y)`, both non-idiomatic negated
membership spellings emit the non-fatal `prefer-not-in` lint, and
idiomatic `x not in y` stays clean. `Result` is no longer hardcoded as
`@[must_use]`, so partial statement-position matches on `Result` are legal
no-ops for unmatched variants; user `@[must_use]` types and `Task` keep the
exhaustiveness rule. Generic enum instantiations such as `Result[T, E]` still
use their enum base for expression-position exhaustiveness. Full `with build`,
`with build :fixpoint`, `with build :test`, and `with build :test-green`
passed on 2026-06-11 for #543, #459, #371, #372, and #384. The `move x`/`copy x`
acknowledgment gate for consuming arguments is removed: plain `f(x)` is legal
when the signature consumes `x`, later uses still error, and `move`/`copy`
remain optional explicit spellings. The implementation also records consume
effects for plain parameter moves and fixed compiler/build helper APIs whose
signatures were accidentally owning read-only state. #384 adds the opt-in
`[lint] partial_statement_match = true` project setting, which emits a coded
`partial-statement-match` warning for non-exhaustive statement-position
bool/enum/sealed-trait matches while keeping the default partial-match behavior
silent and preserving expression-position and `@[must_use]` hard errors.
Follow-up bug #549 tracks value-position `if` branch type mismatches discovered
during the #382 audit.

#347, #356, #358, and the first #357 safety slice are implemented.
`c_import` now separates modeled-safe bindings from raw ABI-shaped bindings:
raw pointer/variadic C functions and function-like macro wrappers that call
them are emitted as `unsafe fn`, while ordinary expression macro wrappers stay
safe. Failed macro/inline/function translation no longer emits callable
`comptime_error` placeholders, extern fallbacks, or silent stubs; inexpressible
symbols are omitted, recorded in the generated import manifest comments, and
diagnosed directionally if user code references them. Implicit broad
`str`/pointer and `void*` coercions were removed; explicit `str as *const u8`
still lowers to the string data pointer, runtime/compiler C-string boundaries
now use `c"..."`, and `void*` only relabels in the safe direction supported by
the raw pointer model. Heuristic C destructor auto-defer was removed; the
completed design note now treats name-based destructor discovery as suggestions
only, with future cleanup expressed through proven owning `Drop` wrappers. The
C migrator now fails loudly on truly untranslated function bodies while still
emitting honest `extern fn` declarations for declaration-only prototypes.
During verification, the build seed resolver was also corrected so normal
bootstrap builds no longer implicitly prefer stale `out/release/bin/with` over
the configured seed/PATH compiler. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-09 for this
checkpoint.

#352 and the first raw-pointer safety cluster are implemented. Bitwise
`& | ^` now use bit-pattern rules: untyped integer literals adopt the typed
operand by width-fit, typed operands may widen only within the same signedness,
and mixed signedness requires an explicit `as`. Raw pointer arithmetic,
comparison, and difference remain safe address computations, with LLVM and
emit-C lowering using raw address operations rather than allocation-relative
semantics. Raw pointer dereference/indexing and raw-pointer-to-reference/slice
conversions require `unsafe`; safe functions that rely on caller-guaranteed raw
pointer validity are rejected unless declared `unsafe fn` or wrapped into a
modeled safe contract. The runtime/compiler-owned ABI surfaces touched by this
rule were made explicitly unsafe where they take raw out-pointers. The C
migrator now marks local raw-pointer-parameter functions unsafe and wraps calls
so migrated C keeps the raw ABI contract loud instead of generating dishonest
safe wrappers. A follow-up issue, #370, tracks the missing unsafe
function-pointer/callback type surface found during the fixture audit. Full
`with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green` passed on 2026-06-09 for this checkpoint.

#299 is implemented. With now has a distinct `extern "C" fn(...) -> T` type
node and `TY_EXTERN_FN` sema type for raw C ABI function pointers, while
ordinary `fn(...) -> T` remains With's context-carrying callable value. The
slice parses optional parameter names in function pointer types, makes the raw
type pointer-sized and Copy, accepts matching named functions and
non-capturing closures, rejects capturing/suspending/ephemeral-task callbacks,
lowers raw callbacks as LLVM pointers, and teaches c_import to emit C function
pointer typedefs as `extern "C" fn` instead of `*const fn`. The migrator now
preserves C `(void)expr` discard statements without turning pure discards into
With tail expressions, and emits a bare `return` for translated void functions
whose body lowers to no statements. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-05.

#335 is implemented. The policy baseline is encoded in AGENTS.md/CLAUDE.md:
`@[c_export]` is foreign ABI only, not compiler-internal linkage. The first
implementation slice added `with build :compiler-no-c-export`, a budgeted audit
that scans compiler-owned With sources (`src/`, `rt/`, `lib/std/`) and fails on
new actual `@[c_export]` attributes while allowing the current removal budget to
shrink. The budget is now zero: actual `@[c_export]` declarations in
compiler-owned source are hard errors. `with build` depends on this audit before
stage1. `Link.w` also now recognizes direct LLVM/libclang undefined symbols,
not only `wl_*`, as compiler static-link triggers.

The LLVM and Clang bridge slice is complete. `rt/llvm_bridge.w` and
`rt/clang_bridge.w` moved to `src/compiler/LlvmBridge.w` and
`src/compiler/ClangBridge.w`, the bridge wrappers are normal `pub` With module
functions instead of `@[c_export]` ABI exports, and `Codegen.w`/`CImport.w`
use explicit bridge globs for this large internal API. `EmbeddedClangResource`
is also called as an ordinary compiler module: CImport materializes the
embedded clang resource dir and passes it into ClangBridge through
`with_cimport_set_resource_dir`. The C migrator calls the same preparation path
before its direct bridge parses, which fixes the previous `stdarg.h` lookup
regression. Full `with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green` passed on 2026-06-04 for this slice.

The runtime-object bootstrap substrate is in place. In module-object mode,
runtime source files (`rt/*.w` and generated `out/gen/compat_runtime.w`) now
preserve raw link names only for runtime ABI-shaped symbols (`with_*`, `rt_*`,
`wl_*`, and the few current non-prefixed shims) while private runtime helpers
remain path-mangled to avoid cross-object collisions. Those runtime ABI symbols
also bypass whole-program internalization when runtime files are compiled as
standalone objects. `@[weak]` applies independently of `@[c_export]`. Full
`with build`, `with build :fixpoint`, `with build :test`, and
`with build :test-green` passed on 2026-06-04 for the initial naming slice and
for the internalization half. The runtime removal slice removed all actual
runtime `@[c_export]` declarations from `rt_core.w`, platform runtime files,
fiber stubs/runtime, channel runtime, regex runtime, panic runtime, compat
runtime, and c_import stubs while keeping the same runtime ABI spellings as
normal function names. Full `with build`, `with build :fixpoint`,
`with build :test`, and `with build :test-green` passed on 2026-06-04 for the
runtime removal slice. General import semantics were not changed as part of
#335. Bare `use Foo` vs `use Foo.*` semantics and ClangBridge/CImport constant
deduplication remain separate follow-up slices.

#260 and #271 are implemented as the first scoped-concurrency substrate.
`async scope s => ...` now returns scope-owned `ScopedTask[T]` handles
from `s.track(Task[T])`; they are awaitable like `Task[T]`, exempt from
unused-task diagnostics, and ephemeral so they cannot escape the scope
result or be stored in ordinary data. Async-scope cleanup is represented
as a scheduled MIR drop for early exits and as an explicit fallthrough
cleanup; scope drop kinds are cancellable so normal fallthrough does not
double-run cleanup. Non-async `scope s => ...` now supports scoped
OS-thread workers via `s.spawn(fn() -> i32) -> ScopedJoinHandle`, with
`.join() -> i32` and automatic join/destroy at scope exit. The new scope
surface supports inline, colon, and braced bodies. Focused behavior and
compile-error coverage exists for scoped task await/drop, scoped thread
spawn/join, block forms, method misuse, and escape/storage rejection. Full
build, fixpoint, and test passed on 2026-06-04 for this checkpoint.

#334 is implemented, then tightened: non-`then` `if` chains now require a
normal body introducer after every arm, including final `else` (`else: expr`
or `else { ... }`, not bare `else expr`). `else if` remains a chain
continuation. The spec, parser fixture, behavior coverage, and compile-error
coverage were updated; full build, fixpoint, and test passed on 2026-06-04
for the original #334 checkpoint.

#252 and #253 are implemented as the first generator vertical slice.
`gen fn f(...) -> T` now semantically returns a compiler-generated state
struct with a synthetic `.next(mut self) -> Option[T]`, supports direct manual
`.next()` calls and `for` iteration, preserves parameters and locals across
yield points, and rejects `async`/`await` inside generator functions. Yielded
local references are rejected with a loud diagnostic while owned values may
cross yield. The generator MIR transform preserves block statement contiguity
while inserting resume-state saves and `Some`/`None` returns, and the state
field collector now follows documented AST child layouts instead of recursing
through symbol fields. Full build, fixpoint, test, last-green, update-seed,
and install-user passed on 2026-06-04 for this checkpoint.

#284 tier substrate is implemented for the user-facing compiler surface.
`std = false` / `--no-std` now selects the core prelude by default,
`alloc = true` / `--alloc` selects the alloc prelude, and
`--prelude=alloc` is a first-class prelude mode. Core prelude no longer
exports allocation-backed collections or owned-string helpers; alloc prelude
adds those back without enabling OS/fiber/std features. Sema enforces direct
no_std tier errors for std-only printing/regex, alloc-only containers, owned
string literals in core no_std, missing `@[panic_handler]`, missing
`@[entry]`/`@[no_main]`, and missing `@[global_allocator]` when alloc is
enabled under no_std. no_std codegen skips the normal runtime `main` wrapper,
so a minimal `@[entry]` no_std binary links as a direct `main` without
`with_runtime_*` symbols. Full build, fixpoint, test, last-green, and
install-user passed on 2026-06-03 for this checkpoint.

#221 and #331 core `@[no_await_guard]` enforcement is implemented as
deterministic MIR dataflow: direct guard locals and derived references/views
live across scheduler-yielding suspension points now produce E0701, while
last-use-before-await, owned snapshots, and explicit drop-before-await with no
live derived view are accepted. #332 is implemented: `no_suspend:` /
`no_suspend { ... }` is an expert assertion block that typechecks like its
body while rejecting direct awaits/select awaits, transitive `may_suspend`
calls, async-scope await-all, and implicit ephemeral-task cleanup awaits with
E0702. #333 is implemented: `with test --help` prints test-specific usage,
and explicit multi-file or directory test invocations run each listed target
in order instead of silently ignoring everything after the first file.

Build and release flow now treats `with build` as canonical. Compiler artifacts
are split by role: bootstrap binaries under `out/bootstrap/bin`, intermediate
stage binaries under `out/stage/bin`, and the release compiler under
`out/release/bin`. `with build :test` records
`out/.build-state/test-green.json` after the full suite passes. `with build
:last-green` consumes current fixpoint and test evidence without rerunning the
test suite, records the seed used for stage1, writes
`out/.build-state/last-green.json`, and archives verified
`out/release/bin/with` under `out/seed-archive/` with a five-seed retention
window. `with build :update-seed` copies the verified final compiler
(`out/release/bin/with`) to `src/main`, and `with build :install-user` installs
the same verified final compiler to `~/.local/bin/with`. `with build :prune` is
a dry-run report for stale build artifacts; `with build :prune-apply` removes
stale temporary dSYM bundles, runtime archive wrappers, stale build state,
stale retained test-graph compiler copies, stale issue61 regression fixture
directories, old seed archives, and versioned `out/release/` byproducts beyond
the five most recent release versions, without touching `.deps/`, current
unversioned release binaries, `install.sh`, or platform SDK archives.

Phase C extraction work is complete. Pre-Phase-D preparation is complete
through P9, including the follow-up source-location diagnostic gap. Phase D
D1 through D8 are complete. The evaluator supports
true OS-thread execution for multi-workspace `parallel(workspaces)` calls by
planning workspaces on the evaluator thread, compiling each plan on its own OS
thread, and materializing `BuildResult` values back on the evaluator thread in
input order. Fresh intercepted workspaces are supported by queueing their
independent message streams after the parallel compile joins; partially
consumed intercepted workspaces fail loudly.

Phase E is complete. The shell-string audit is recorded in
`docs/audits/phase-e-shell-audit.md`. `src/compiler/Compilation.w` is clean of
shell command strings and raw runtime extern declarations: output directory
creation fails loudly through typed runtime filesystem primitives, cleanup uses
typed runtime filesystem primitives, and `dsymutil` runs through typed argv
capture. `src/compiler/Runtime.w` is the explicit raw-runtime boundary for the
compiler module slices that have been migrated so far. `src/compiler/Link.w`
is also clean of shell command strings and raw runtime extern declarations:
link execution, `nm -u` capture, archive creation, and cleanup use typed
runtime process/filesystem wrappers. Darwin archive creation uses
`libtool -static`, not `ar`, because ld64 rejects unaligned Mach-O members in
archives produced by direct `ar rcs`. The orphan `with_system` declaration in
`src/CImport.w` has been removed. `src/compiler/ProjectConfig.w`,
`src/compiler/Backend.w`, and `src/compiler/Zcu.w` now route runtime access
through `src/compiler/Runtime.w` instead of declaring raw `with_*` externs.
`src/compiler/Frontend.w` now does the same for file IO, diagnostics,
environment reads, timing, string hashing/cloning, argv access, and nanosleep.
In `src/main.w`, CLI `run`/one-liner binary execution and binary artifact
cleanup now use typed runtime wrappers instead of shell command strings. Test
stdout/stderr capture and benchmark execution also use typed runtime process
wrappers, so `src/main.w` no longer depends on `with_system`.
`src/compiler/ConanClient.w` now talks to ConanCenter v2, resolves omitted
package versions to the newest available recipe (for example `c.raylib` →
`raylib/6.0` on 2026-05-27), downloads packages through typed `curl` argv
capture, extracts Conan archives through typed argv capture, records transitive
dependency metadata, and routes runtime access through `src/compiler/Runtime.w`.
`lib/std/process.w` no longer exposes shell-string execution: `Command` stores
argv entries, `.arg(...)` appends arguments, and command execution goes through
typed argv runtime process execution.
`rt/clang_bridge.w` no longer uses `popen`: SDK discovery and `cc -E`
preprocessing use typed argv capture, and LLVM resource directory discovery
uses direct directory enumeration.
`rt/compat_runtime.w` no longer exports shell execution helpers:
`with_system`, `with_extract_tgz`, and the shared `/bin/sh -c` runner have
been removed.
The unused tracked `src/main_emit_temp.w` legacy entry snapshot has been
removed from the source tree and from compiler source generation.
The only remaining Phase E shell scan hits are the documented PCRE2 upstream
`RunTest` `/bin/bash` argv boundary and the `shorthand` filename false
positive. Makefile shell usage remains out of Phase E scope while Make still
exists.

Phase F is complete. The path containment audit is recorded in
`docs/audits/phase-f-path-audit.md`. Every target dispatched through
`build_graph_dispatch_standard_target` now passes
`build_graph_validate_target_containment` before any operation runs.
Non-install targets reject absolute, `..`, `$`-prefix, and control-char
paths in output and extra_output fields. Install targets accept only
recognized install prefixes (`$HOME/`, `$INSTALL_BINDIR/`,
`$INSTALL_LIBDIR/`) or project-relative paths. Command and corpus test
targets are allowed absolute entry paths (executables).
`PromoteTreeIfVerified` now uses byte-by-byte staleness detection: fresh
files are skipped and stale files are reported. Process argument validation
diagnostics now name the target, field index, and rejected value.

Build graph support modules have been moved out of the repository root. The
root keeps `build.w`; support source now lives under `build/` and is imported
through dotted modules such as `build.compiler` and `build.selfhost`.
LLVM bridge link metadata now records direct linker metadata (`llvm_ld` and
`llvm_ld.rsp`) in addition to the legacy clang-driver files. Source `Link.w`
uses `ld64.lld` metadata directly for LLVM/static-bridge links instead of
invoking clang with `-fuse-ld=lld`; release compiler links require
`libclang.a` and include the Clang component archives from the pinned static
LLVM SDK.

The Darwin arm64 static LLVM SDK has been built locally from LLVM 22.1.6
under `.deps/llvm-22.1.6-darwin-arm64`. A fresh compiler build against that
SDK links no dynamic LLVM/Clang, zlib, zstd, or libxml2 libraries; `otool -L`
shows only `/usr/lib/libSystem.B.dylib` and `/usr/lib/libc++.1.dylib`.
Emit-C/bootstrap compilation now uses `WITH_EMIT_C_CC`, then `CC`, then `cc`;
Zig is no longer the default or required C compiler.

Linux x86_64 bootstrap support is active and verified on Ubuntu 22.04 at
`quixi@192.168.86.211`. The Linux runtime backend, fiber assembly backend,
direct `ld.lld` link path, static LLVM SDK inputs, and emitted-C C compiler
link path all build without requiring Zig or the `clang` executable in the
normal With build path. The latest checkpoint passed `with build`,
`with build :fixpoint`, `with build :test`, and forced
`with build :emit-c-fixpoint` on macOS
Darwin arm64 and Ubuntu Linux x86_64.

Release packaging now treats Linux x86_64 as a first-class platform asset:
`with-linux-x86_64`. Seed download paths are host-aware, the installer selects
the Darwin or Linux asset from the host platform, and compiler version source
generation declares `WITH_VERSION` plus the current Git ref as build inputs so
release binaries do not reuse stale generated version text after commits.

Completed D1 sub-slices:

1. Shared capability registry used by Sema, plus a reserved capability value
   kind for evaluator dispatch.
2. Comptime function values and function-field calls, needed for evaluating
   `Build.action(..., action_fn)` targets without generated runner binaries.
3. Comptime struct field assignment, needed to preserve `Target.action` and
   other build-record mutations during direct `build.w` evaluation.
4. Evaluator-owned capability records, handle validation, and initial
   capability receiver dispatch for `BuildCtx.project_info()` and
   `ProjectInfo` accessors.
5. Evaluator handlers for `BuildCtx.new_build()` and BuildCtx child
   capabilities: diagnostics, source emitter, ToolFs, and ProcessRunner.
6. A typed `ComptimeValue(Build)` to `BuildGraph` materializer substrate,
   including a driver-only action function reference on `BuildGraphTarget`.
7. Build-time evaluator handlers for `Diagnostics.warn/error`,
   `SourceEmitter.generated_source`, and `ToolFs` filesystem operations used
   during direct `build(ctx)` evaluation.
8. The normal `build.w` graph-load path now compiles an evaluator wrapper,
   evaluates `build(ctx)` in-process, and materializes the typed returned
   `Build` value directly into `BuildGraph`.
9. Action targets now execute in-process through the evaluator with a minted
   `ActionCtx`; generated action runner source files and binaries are no
   longer part of the normal action path.

Completed D2 work:

1. Added typed build option structs to `std.build`: `BuildOptions`,
   `BuildGraphOptions`, `TestOptions`, and `MigrateOptions`.
2. Added driver-side structured build option parsing for `with build`.
3. Routed direct `with build` source builds and build graph execution through
   `BuildCommandOptions` instead of long positional option lists.
4. Added `Compilation.configure_options` as the typed compilation option
   boundary.
5. Added focused build-options API and CLI compatibility coverage.
6. Updated the Phase D design and language specification with canonical
   capability-bearing comptime syntax:
   `comptime with BuildCtx as ctx:`, with `comptime with BuildCtx:` as the
   standard default-binding shorthand.

Completed D3 work:

1. Parser support for `comptime with Capability as name:` and standard
   default-binding shorthand.
2. Build entry points written as `comptime with BuildCtx as ctx:` or
   `comptime with BuildCtx:` lower to the existing explicit `build(ctx)`
   entry shape used by the evaluator-backed driver.
3. Sema allows trusted `std.build` and `std.compiler` implementation-boundary
   functions to be called from capability-bearing comptime functions while
   preserving the normal restriction against arbitrary runtime calls.
4. Focused selfhost coverage proves canonical build entry points, shorthand
   default binding, and duplicate default-binding diagnostics.
5. Sequential `Workspace` capability skeleton, including
   `BuildCtx.create_workspace`, `BuildCtx.current_workspace`, source-file and
   source-string inputs, typed `BuildOptions`, `Workspace.compile`, and typed
   `BuildResult` / `Artifact` values.
6. Focused selfhost coverage proves workspace file compilation, workspace
   source-string compilation, BuildResult artifact construction, and the
   `current_workspace()` failure diagnostic before a workspace exists.
7. `ActionCtx` can mint workspaces for action-local compilation, and the fast
   emit-C smoke action now emits `test/hello.w` to C through
   `Workspace.compile()` instead of spawning `with build --emit-c`.
8. `Workspace` is an ephemeral capability handle, so storing it in ordinary
   long-lived structs is rejected by Sema. The compile-error suite covers this
   with `err_workspace_ephemeral_struct_field.w`.

Remaining D3 work: none.

D4 may start after this D3 checkpoint lands and passes the same
build/fixpoint/test baseline.

Completed D4 substrate work:

1. The comptime evaluator can represent payload enum values and match on
   payload enum patterns. This is required before `CompilerMessage` can use the
   tagged-union shape specified by `docs/completed/phase-d-design.md` instead
   of a flat message struct. Focused build-w selfhost coverage exercises
   payload enum construction and payload binding during direct `build(ctx)`
   evaluation.
2. Enum type collection resolves payload types before writing enum layout rows
   into `type_extra`, so generic payload resolution cannot interleave unrelated
   type metadata into an in-progress enum layout. Behavior coverage protects an
   enum with a generic payload followed by a variant whose name matches its
   payload type.
3. `std.build` exposes the public D4 message data surface:
   `DeclSummary`, `CompilerPhase`, `LinkCommand`, `CompilerMessage`, and
   `CompilerMessageEnvelope`. The build-w selfhost payload-enum fixture now
   constructs and matches a public `CompilerMessage.Typechecked` value through
   the real `std.build` import path.
4. `Workspace.begin_intercept`, `wait_for_message`, and `end_intercept` have
   evaluator-backed lifecycle support for synchronous `Workspace.compile()`.
   Intercepted compilation now delivers phase markers through codegen,
   `CompilerMessage.Typechecked(Vec[DeclSummary])` from the real sema snapshot,
   produced artifacts, then the terminal phase marker and terminal payload.
   Cooperative suspension, link-phase coverage, and `set_link_command` remain
   the next D4 work.
5. Tool build/action evaluation now rejects unfinished workspace interceptions
   at the evaluator boundary. A build script that returns with an active
   intercept and no delivered terminal message fails loudly instead of
   materializing a graph.
6. Intercepted `Workspace.compile()` now queues the terminal phase marker and
   terminal payload as separate messages: `Phase(complete)` followed by
   `Complete(BuildResult)`.
7. `Workspace.end_intercept()` now rejects attempts to end an interception
   while terminal messages are still unread, so build scripts cannot hide an
   abandoned message queue by closing the intercept before returning.
8. The build-w selfhost workspace message fixture covers closed-queue
   semantics: after `Complete(BuildResult)` is consumed, the next
   `wait_for_message()` returns `CompilerMessage.Error(1, "Workspace message
   queue is closed", unknown_span)`.
9. Successful intercepted `Workspace.compile()` calls now queue one
   `CompilerMessage.Artifact(Artifact)` for each produced build artifact
   before the terminal `Phase(complete)` / `Complete(BuildResult)` pair.
10. Successful intercepted `Workspace.compile()` calls now queue
   `Phase(typechecked)` followed by `Typechecked(Vec[DeclSummary])` before
   artifact messages. The summaries are materialized directly from the
   compiler's typed declaration snapshot and include function/type names,
   module names, public flags, source spans, return type text, and parameter
   counts.
11. Successful intercepted `Workspace.compile()` calls now queue the
   non-link phase markers currently available on the synchronous path:
   `pre_parse`, `parsed`, `pre_typecheck`, `typechecked`,
   `lowered_to_mir`, `pre_codegen`, `codegen_done`, `pre_link`, and `linked`.
12. The primary link path now constructs an internal typed argv command
   (`LinkStageCommand`) and executes it through `with_exec_argv` instead of
   assembling shell command strings. This is the substrate for exposing
   `CompilerMessage.PreLink(LinkCommand)` and accepting validated
   `Workspace.set_link_command` replacements.
13. `Compilation` now retains the last link command and link rc for successful
   binary build attempts. The data is still internal, but it gives the
   evaluator a real command object to materialize into `PreLink`/`Linked`
   messages instead of re-planning or parsing textual command output.
14. Successful intercepted binary `Workspace.compile()` calls now queue
    `Phase(pre_link)`, `PreLink(LinkCommand)`, `Phase(linked)`, and
    `Linked(LinkCommand, rc)` before artifact and terminal messages. Link
    replacement through `Workspace.set_link_command` is still pending.
15. The link layer now has an internal planning boundary:
    `link_stage_link_object_to_binary_plan` constructs the typed command
    without executing it, and the existing result path executes the plan.
    This is the next substrate needed for validating and applying
    `Workspace.set_link_command` replacements before link execution.
16. `Compilation.finish_binary_from_pool` is now split into
    `prepare_binary_link_from_pool` and `execute_binary_link_plan`. Binary
    compilation can produce the object file and typed link command before
    executing the command, giving the workspace message loop a compiler-level
    pause point to expose as `PreLink`.
17. Binary link-plan execution is factored into
    `compilation_execute_binary_link_plan`, so the future workspace pre-link
    continuation can execute a validated replacement command through the same
    cleanup/profile/dSYM path as normal binary compilation.
18. Intercepted workspaces now have the first real wait-driven compile path:
    when `wait_for_message()` is called on an empty active interception, the
    evaluator advances compilation to `PreLink`, queues messages through
    `PreLink(LinkCommand)`, and stores the pending link command. A subsequent
    wait executes the pending command through the shared link-plan executor.
    `Workspace.set_link_command` validates same-linker replacements that
    preserve declared outputs before updating the pending command.
19. Focused build-w selfhost coverage now proves `Workspace.set_link_command`
    rejects linker executable changes and replacements that drop declared
    outputs. The positive workspace message fixture also appends a harmless
    linker argument before replacement, proving the accepted command is the one
    executed.
20. `Workspace.set_link_command` now accepts `LinkCommand.cwd` and
    `LinkCommand.env` replacements. The internal link command stores cwd/env,
    link execution applies replacement env vars around the child process, and
    a new runtime `with_exec_argv_cwd` primitive runs argv commands from a child
    cwd without mutating the parent process cwd.

Completed D5 generated-source work:

1. Workspace interceptions now track the last delivered compiler phase. This
   lets capability methods reject source-set mutation at phases where Phase D
   has no safe re-entry semantics yet.
2. `Workspace.add_string` during `PRE_LINK` or later now fails loudly with
   `Workspace.add_string during PRE_LINK is not supported in Phase D` instead
   of accepting source text that cannot affect the pending link. Focused
   build-w selfhost coverage protects the diagnostic.
3. The frontend and `Workspace.compile()` path now compile every in-memory
   source unit collected through `Workspace.add_string`, not just the first.
   Extra generated source units receive their own file ids, declaration source
   paths, and in-memory source text mappings for diagnostics. Focused build-w
   selfhost coverage builds one generated source that calls a function declared
   in a second generated source.
4. `Workspace.add_string` after a delivered `TYPECHECKED` message now creates a
   new workspace generation, clears stale downstream messages from the prior
   generation, and forces the next `wait_for_message()` to re-enter compilation
   from parse/typecheck before link. Focused build-w selfhost coverage observes
   generation 1 typechecking, adds a generated source, then observes generation
   2 typechecking with the new declaration before linking.

Completed D6 parallel-workspace work:

1. `std.build` exposes the public `parallel(workspaces: Vec[Workspace]) ->
   Vec[BuildResult]` API as a driver-evaluated capability function.
2. The evaluator handles `parallel([ws])` by compiling the single workspace
   through the existing workspace compilation path and returning a
   `Vec[BuildResult]` in input order.
3. The initial multi-workspace loud failure protected the API until
   per-workspace state isolation and the OS-thread substrate were implemented.
   Later D6 slices replaced that guard with true multi-workspace execution.
4. Focused build-w selfhost coverage proves single-workspace behavior,
   multi-workspace execution, independent intercepted queues, and failed
   workspace identity diagnostics.
5. Atomic intrinsic lowering now handles global `Atomic[T]` receivers by
   recovering the receiver storage type from MIR/Sema when LLVM cannot report
   an allocated type for a global pointer. Native codegen coverage protects
   global atomic load/store/swap.
6. The With runtime allocator now serializes its process-global small-allocation
   freelists and slab pointer behind a global atomic spin lock. This is a
   prerequisite for true OS-thread workspace execution; it is not full D6
   parallelism.
7. `std.thread.spawn_os` now uses real OS threads for `fn() -> i32` workers,
   with the platform backend owning the Darwin pthread calls and `rt_core`
   owning the public `with_thread_*` ABI. This provides the first real
   OS-thread substrate for D6; it does not yet run workspaces in parallel.
8. The LLVM bridge C-string scratch buffer is now split into per-OS-thread
   slots selected by `pthread_self`, with a short atomic metadata lock and a
   loud abort if the fixed slot table is exhausted. This removes one
   process-global race before parallel workspace codegen.
9. `std.thread.spawn_os` preserves captured closure contexts when entering the
   OS thread. The runtime reconstructs the fat function value with the original
   closure environment and calls it through the function-value ABI, so both
   top-level functions and closures work as D6 worker substrates.
10. Darwin OS threads are created with an explicit 16 MiB stack instead of the
    platform default. MIR lowering and codegen use stack frames large enough
    that default secondary-thread stacks faulted immediately under parallel
    workspace compilation.
11. `parallel(workspaces)` now supports multiple workspaces. The evaluator
    validates handles and builds compile plans serially, runs the independent
    `Compilation` work on OS threads, joins all workers, and then constructs
    the public `Vec[BuildResult]` in input order without mutating
    evaluator-owned value storage from worker threads.
12. `c_import` expansion is serialized behind a frontend lock. The C import
    and clang bridge code still contains process-global mutable session state,
    so parallel workspaces may compile ordinary With code concurrently while
    C import work remains correctness-first and single-threaded until the
    session-state refactor happens.
13. LLVM target initialization in the With LLVM bridge is protected by a
    one-time process lock. Parallel workspace codegen creates one LLVM context
    per worker thread, but the `LLVMInitializeAArch64*` target registry calls
    mutate LLVM process-global state and must not run concurrently.
14. The build-w selfhost workspace API suite includes a six-workspace
    `parallel(workspaces)` stress fixture. This keeps the known parallel
    workspace races covered by the default test target instead of relying only
    on ad hoc direct loops.
15. Evaluator-backed `ProcessRunner` capability calls clear the driver
    capability environment before spawning child processes, matching the
    stdlib/generated-runner path. Explicit `ProcessEnv` overrides are applied
    only after the driver variables are cleared and are restored before the
    driver variables are restored.
16. Fresh intercepted workspaces inside `parallel(workspaces)` are supported.
    After worker joins, the evaluator queues each workspace's messages back on
    the owning workspace record, preserving independent message streams and
    workspace identities. Partially consumed intercepted workspaces remain a
    loud failure because Phase D has no cross-thread pre-link continuation
    semantics inside `parallel`.
17. Failed workspaces in `parallel(workspaces)` now emit an evaluator-side
    diagnostic naming the workspace and exit code after worker joins. The
    build-w selfhost suite covers one successful workspace alongside one
    failing workspace and verifies the failed workspace identity appears in
    stderr while the build script can still inspect `BuildResult.rc`.

Completed D7 project-action workspace migration work:

1. The fast emit-C smoke action emits `test/hello.w` to C through
   `Workspace.compile()` instead of spawning the current compiler.
2. Compiler source emission for the primary emit-C compiler test uses a
   workspace when the current compiler is the intended compiler.
3. The final `pcre2-build` compilation of `pcre2test.w` uses
   `Workspace.compile()` instead of spawning `out/bin/with build`.
4. The migrator directory/shared-defs implementation no longer shells out to
   `find`, `rm`, or a self-reinvoked `with migrate` process. It lists files
   through the runtime filesystem primitive and merges shared fragments
   in-process.
5. `Workspace.compile()` supports typed `MigrateOptions`, and the build-w
   selfhost suite covers a build script that migrates C source through a
   workspace and inspects the generated With source.
6. `pcre2-migrate` and `pcre2-migrate-smoke` use the workspace migration path
   instead of spawning `with migrate`.
7. Remaining ProcessRunner uses are intentional boundaries: external tools
   (`curl`, `tar`, the configured C compiler, upstream PCRE2 corpus runners), stage-chain or
   emitted compiler binaries, CLI selfhost fixtures, and current diagnostic
   scans that deliberately exercise CLI output.

Completed D8 DeclSummary-driven tooling work:

1. `BuildOutputKind.Check` supports workspace typecheck-only compilation
   through `Workspace.compile()` without materializing a public artifact.
2. PCRE2 generated-module validation now creates in-process workspaces,
   compiles synthetic modules in check mode, and inspects
   `CompilerMessage.Typechecked(Vec[DeclSummary])` instead of spawning
   `out/bin/with check` and parsing CLI diagnostic text.
3. The stable DeclSummary v1 fields used by the PCRE2 tooling integration are
   `DeclSummary.kind`, `DeclSummary.name`, and `DeclSummary.source.file`.
4. Remaining PCRE2 ProcessRunner calls are explicit external-tool or corpus
   runner boundaries, not self-invoked compiler diagnostic scans.

D1 architectural boundary: the evaluator must return a typed std.build `Build`
value. The driver materializes that value directly into `BuildGraph`.
`Build.emit_graph()` remains a debug/export compatibility facility and must not
be the evaluator-to-driver transport.

Completed quality-of-life slices:

1. `855594b` Add persistent project state checkpoint.
2. `9186a59` Add build debugging helper scripts.
3. `f078129` Add action `--no-deps` build flag.
4. `5f81dca` Run external build tests in parallel batches.

## Verification Baseline

The original P9 pre-D1 baseline is recorded in
`docs/audits/pre-d1-baseline.md`. The current verified checkpoint is the commit
containing this project-state update:

```text
Use DeclSummary workspace checks for PCRE2 generated modules
```

Commands passed:

```sh
out/bin/with check src/main.w
out/bin/with check build/pcre2.w
out/bin/with check build/selfhost.w
git diff --check
with build
out/bin/with build :pcre2-build --no-deps
out/bin/with build :pcre2-check-generated --no-deps
out/bin/with build :c-migrator-pcre2-prep-tests --no-deps
out/bin/with build :cli-selfhost-build-w-tests --no-deps
with build :fixpoint
with build :test
with build :install-user
```

The previous verified checkpoint also passed:

```sh
with build
out/bin/with build :cli-selfhost-build-w-tests --no-deps
out/bin/with build :build
out/bin/with build :fixpoint
out/bin/with build :test
out/bin/with run test/behavior/behav_std_build_options_api.w
out/bin/with build test/hello.w -o /tmp/with-d2-hello
out/bin/with build test/hello.w --emit-c -o /tmp/with-d2-hello.c
out/bin/with build test/hello.w --emit-obj -o /tmp/with-d2-hello.o
out/bin/with build :cli-selfhost-edge-tests --no-deps
out/bin/with test test/behavior/behav_build_w_basic_invocation.w
out/bin/with test test/behavior/behav_action_capability_filesystem.w
out/bin/with test test/behavior/behav_action_capability_process.w
out/bin/with test test/behavior/behav_action_crash_diagnostic.w
out/bin/with test test/behavior/behav_action_no_deps_isolation.w
out/bin/with build :cli-selfhost-smoke-tests
out/bin/with build :c-migrator-core-tests
out/bin/with build :pcre2-reference
out/bin/with build :test
with build :fixpoint
with build :test
```

Full `:emit-c-test` remains a manual release/emit-C-feature verification
target. Do not run it for normal compiler, stdlib, or build-system slices; the
default `:test` target includes the fast emit-C smoke.

Recent Phase D/pre-D commits:

- current checkpoint: Use DeclSummary workspace checks for PCRE2 generated modules.
- previous checkpoint: Add workspace check output mode.
- previous checkpoint: Use a workspace for pcre2-test-smoke's With compile.
- previous checkpoint: Use workspaces for emit-C compiler source emission.
- previous checkpoint: Fix emit-C lowering for Atomic and payload options.
- previous checkpoint: Report failed parallel workspace identity.
- previous checkpoint: Cover intercepted workspace parallel rejection.
- previous checkpoint: Clear driver env for evaluator ProcessRunner.
- previous checkpoint: Add parallel workspace stress coverage.
- previous checkpoint: Serialize LLVM target initialization.
- previous checkpoint: Serialize c_import expansion for parallel workspaces.
- previous checkpoint: Compile parallel workspaces on OS threads.
- previous checkpoint: Fix std.thread captured closure entry.
- previous checkpoint: Make LLVM bridge cstr scratch thread-aware.
- previous checkpoint: Back std.thread with OS threads.
- previous checkpoint: Synchronize runtime allocator state.
- previous checkpoint: Support single-workspace parallel API.
- previous checkpoint: Re-enter workspace compilation after generated source.
- previous checkpoint: Compile all workspace source strings.
- previous checkpoint: Reject add_string during pre-link interception.
- previous checkpoint: Support link command cwd and env replacements.
- previous checkpoint: Test link command argv replacement.
- previous checkpoint: Support payload enum values in comptime evaluation.
- previous checkpoint: Make Workspace an ephemeral capability.
- previous checkpoint: Use workspaces for emit-C smoke compilation.
- previous checkpoint: Implement workspace compile capability skeleton.
- `5e5674a` Unify build CLI parsing with BuildOptions.
- `2cba39a` Execute build actions in-process.
- `f5cc0c5` Evaluate build.w graphs in-process.
- previous checkpoint: Implement source-location magic constants.
- `617aecd` Reconcile Phase D design with pre-D artifacts.
- `db64d01` Isolate generated action runner dispatch.
- `6d1b052` Add pre-D build action behavior regressions.
- `366b681` Design BuildOptions and CLI integration.
- `af5a756` Design capability dispatch for Phase D.
- `0ebdcd2` Survey build scripts before Phase D.
- `3e10eed` Audit parallel compiler state before Phase D.
- `1cbc348` Audit comptime evaluator before Phase D.

Recent Phase C and hardening commits:

- `c993471` Extract compiler generators to build actions.
- `8f47830` Extract compiler build targets to build actions.
- `7ead507` Preserve action runner output while capturing diagnostics.
- `d852d2c` Lower binding initializers before binding locals.
- `3242741` Add host existence checks to ToolFs.
- `765c0d0` Extract emit-C targets to build actions.
- `862a510` Preserve HashMap key types in emitted C.
- `9ec2148` Materialize copy let bindings in MIR.
- `d9116c2` Fix emit-C enum and scalar lowering.
- `5f81dca` Run external build tests in parallel batches.
- `f078129` Add action `--no-deps` build flag.
- `9186a59` Add build debugging helper scripts.
- `855594b` Add persistent project state checkpoint.
- `54ecd97` Consolidate emit-C call inference caches.
- `7c40e67` Add emit-C smoke to default tests.
- `c47ee60` Decode string escapes in emitted C.
- `237b498` Add PCRE2 test smoke to default tests.
- `d4be079` Add PCRE2 migrate smoke to default tests.
- `bd0b85f` Make ProcessEnv set fluent.
- `6719ad4` Run migrator selfhost smokes in default tests.
- `de87372` Make Vec.push composable in pipelines.
- `f21002e` Record value-ref ABI parameters in Sema.
- `eb01bed` Add selfhost regressions for emit-C receivers and switch scope
  migration.

## Build Plan Status

The authoritative plan remains `docs/build-plan.md`; the final architecture is
specified in `docs/build-spec.md`. Completed Phase D implementation history is
archived in `docs/completed/phase-d-design.md`; completed pre-D preparation is
archived in `docs/completed/pre-phase-d-plan.md`.

Completed at a high level:

- Build actions and capability plumbing exist.
- Scoped `ToolFs` writes and declared extra outputs exist.
- Default `with build :test` does not run PCRE2 targets. PCRE2 migration,
  generated-module checks, and corpus tests are manual-only and should be run
  when intentionally migrating or validating a PCRE2 version.
- Action targets support `--no-deps` for focused iteration.
- External-compiler build graph test targets run in parallel batches.
- Several repository-specific build targets have moved to project-local action
  modules.

Build system completion:

- All phases (A through I) are complete.
- `with build` is the canonical build interface. Make is legacy compatibility,
  not the source of truth for build or release procedure.
- All build logic lives in `build.w` and project-local modules under `build/`.
- All obsolete shell scripts have been deleted. Only
  `scripts/generate_wl_stubs.sh` remains (for cross-compilation).
- CI and release verification should use `with build`, `with build :fixpoint`,
  and `with build :test` directly.
- `with build` (no target) runs the default build target.

## Phase C Extraction Status

Completed Phase C-style extractions include:

- `issue61-regression`
- `compat-runtime-source`
- `cli-selfhost-smoke-tests`
- `cli-selfhost-one-liner-tests`
- `cli-selfhost-object-symbol-tests`
- `cli-selfhost-project-tests`
- `cli-selfhost-edge-tests`
- `cli-selfhost-parallel-tests`
- `c-migrator-pcre2-prep-tests`
- `pcre2-reference`
- `pcre2-build` / `pcre2-test`
- `pcre2-check-generated` / `pcre2-promote`
- `seed-download`
- `emit-c-test` / `emit-c-fixpoint` / `emit-c-roundtrip`
- `compiler-sources`
- `bootstrap-llvm-link-metadata` / `llvm-link-metadata`
- compiler build / compiler IR targets

No Phase C extraction areas remain. All old 1000-series repository-specific
graph kinds are reserved as removed-kind diagnostics.

Before adding new repository build policy, re-check `src/BuildGraphKinds.w`,
`src/main.w`, `docs/completed/phase-c-inventory.md`, and the current git log.
New repository-specific behavior should go into project-local build modules,
not a new compiler-dispatched project graph kind.

## Open Blockers And Follow-Ups

- Phase D is complete. The next major direction is not selected in this file.
- The D8 PCRE2 generated-module check currently creates one workspace per
  generated module and retains substantial compiler state during the action.
  It passes, but future performance work should consider a batched or reusable
  workspace shape before expanding the pattern to larger generated-module
  scans.
- Preserve the pre-D behavior tests during D1:
  `behav_build_w_basic_invocation`, `behav_action_capability_filesystem`,
  `behav_action_capability_process`, `behav_capability_token_mismatch`,
  `behav_action_crash_diagnostic`, and `behav_action_no_deps_isolation`.
- Decide whether in-process build graph test targets should also move to
  external parallel execution, or remain serial for diagnostic fidelity.
- Keep PCRE2 targets manual-only; do not wire PCRE2 migration, generated-module
  checks, corpus tests, or smokes into `with build :test`.
- Run full `:emit-c-test` only for release verification or emit-C-specific
  work. For ordinary changes, rely on `with build :test`'s emit-C smoke.
- Keep project-specific build policy in project-local modules and avoid adding
  new compiler-dispatched project graph kinds.
- Phase E is complete. New compiler, migrator, runtime, stdlib, and build
  internals should use typed process/filesystem APIs rather than shell command
  strings.
- Phase F is complete. All build graph targets pass project-root containment
  validation at dispatch time. Install targets require recognized install
  prefixes. PromoteTreeIfVerified uses staleness detection.
- `with get c.raylib` installs the ConanCenter `raylib/6.0` binary package on
  Darwin arm64, and the issue #288 repro with `use c_import("raylib.h")` now
  checks successfully, including raylib `CLITERAL(Color){...}` color macros
  such as `RAYWHITE` and `LIGHTGRAY`.

## Local State

Phase 1 build/configuration work is in progress. Issue #424 is implemented
locally in the current worktree: `copy_warn_threshold` is parsed from
`with.toml`, propagated into sema, and used to emit a non-fatal large-`Copy`
warning after Copy safety validation. Verification passed with:

```sh
WITH=$PWD/out/bin/with ./out/bin/with build
WITH=$PWD/out/bin/with ./out/release/bin/with build :cli-selfhost-project-tests
WITH=$PWD/out/bin/with ./out/release/bin/with build :fixpoint
WITH=$PWD/out/bin/with ./out/release/bin/with build :test
WITH=$PWD/out/bin/with ./out/release/bin/with build :test-green
```

Issue #476 is implemented locally after #424: `lib/std/os.w` now provides the
Layer 1 platform wrapper boundary, including portable wrappers over the
compiler-owned platform ABI plus explicit POSIX c_import wrappers. Focused
and full verification passed with:

```sh
WITH=$PWD/out/bin/with ./out/bin/with build
WITH=$PWD/out/bin/with ./out/release/bin/with test test/behavior/behav_std_os.w
python3 scripts/check-spec-inventory.py
WITH=$PWD/out/bin/with ./out/release/bin/with build :fixpoint
WITH=$PWD/out/bin/with ./out/release/bin/with build :test
WITH=$PWD/out/bin/with ./out/release/bin/with build :test-green
```

At the time of this update, Phase F is complete. The Phase F code changes
passed the standard verification sequence:

```sh
out/bin/with check src/main.w
with build
with build :fixpoint
with build :test
```

Phase F changes are in `src/BuildGraphSupport.w`, `src/BuildGraphDispatch.w`,
`src/BuildGraphOps.w`, and `build.w`. The full audit is in
`docs/audits/phase-f-path-audit.md`.

The full emit-C test is intentionally not part of this verification pass per
the manual-only policy above.

Always run `git status -sb` before editing; this file is a checkpoint, not a
substitute for inspecting the current worktree.

## Environment Notes

- Stale `/tmp/openjai_test_*` directories and build artifacts can consume
  large amounts of disk after interrupted runs. Use `with build :prune` to
  inspect project-local leftovers and `with build :prune-apply` to remove the
  recognized stale artifacts.
- If link errors mention missing regex runtime exports, inspect
  `out/lib/regex_runtime.o`; a disk-full interruption once left it truncated and
  required regenerating the object.
