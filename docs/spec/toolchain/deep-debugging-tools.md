# Deep Debugging Tools

Status: implemented. Audience: compiler/runtime contributors.

These tools exist to stop edit/compile/trace loops. This page is ordered by
the kind of bug you are holding, not by tool: each route says which tool
proves what, and what it cannot prove. The catalog of every command follows
the routes.

Every recipe here was run as written on 2026-10-05 against main efb765c8b
(macOS arm64), except the native Windows section, last run on #1081. A
recipe that does not work as written is a defect in this page or in the
tool; fix it or file it.

## Which binary

`with` in the recipes is a compiler; pick the one the question needs. Any
of them refuses a flag it does not know on `check`, `ir` and `run`
(`error: unknown option \`--x\` for \`with check\`; did you mean …`,
exit 2, #2198): a misspelled or removed flag never reads as a clean run.

- **`with` on PATH** (`~/.local/bin/with`, installed from main): every
  dump, trace, `analyze`, `reduce` and allocator recipe, and lldb on the
  compiler when the bug is on main: `:install-user` installs
  `~/.local/bin/with.dSYM` beside it (the release link's dSYM; stamping
  keeps the Mach-O UUID), so dotted names resolve and frames show source
  lines and parameters. An install from an SDK without dsymutil says so and
  leaves no dSYM; then lldb finds functions only by regex
  (`breakpoint set -r 'Codegen\.marshal_mir_call_arg$'`; the symbol is
  `__wcu$N$Codegen.marshal_mir_call_arg`). `ls ~/.local/bin/with.dSYM`
  answers which.
- **`out/bootstrap/bin/with-stage1`** (after `with build :dev`; has a
  `.dSYM`): the compiler built from your tree. Use it for anything about
  source you have changed, and for lldb on that compiler: dotted names
  resolve (`breakpoint set --name Codegen.marshal_mir_call_arg`) and frames
  show source lines and parameters.
- **`out/stage/bin/with-stage2`** (after a full `with build`) and
  **`out/release/bin/with`**: the same, one stage on.

A program you build with any of them carries debug info for its own code
and the runtime, so lldb on the *program* resolves `rt_core.w` lines
(`dbg_report_double_free`, `with_panic_core`) whichever compiler built it.

## Routes by bug class

### A drop, double free, invalid free, use-after-free, or leak

1. **Native debug allocator first.** `with run --debug-alloc repro.w` (or
   `WITH_DEBUG_ALLOC=1` on any binary). It names the block, its size, and
   the drop-origin tag of the first free (`first_drop=drop#struct
   __drop_struct_551` names a type's drop glue, the number varies by
   program; `<untagged>` is a raw `rt_free` caller such as a collection's own
   free). The tag is the first real clue:
   a str drop freeing a block another owner also frees means a str aliases
   that owner's buffer, or a str value is garbage.
2. **`WITH_ALLOC_NO_REUSE=1`** on the same run. A plain double free still
   reports; a report that disappears means the second free came through a
   stale pointer whose address was reused, or the "str" was uninitialized
   stack (the #729 class: a temp dropped on a path that never created it).
   The ownership range tables grow without bound (mmap-backed, doubling),
   so this verdict is trustworthy on a compiler-sized run. It was not
   before #1081: a fixed 8192-region cap made a no-reuse run's table
   "incomplete" and the invalid-free check then passed every pointer
   silently, so the double free "vanished" under no-reuse while a
   three-line repro still reported it. A runtime older than that prints
   nothing at all when it stands down.
3. **Get the exact failing binary.** A fixture that fails only under
   `with test` fails in the runner's own artifact
   (`out/<dir>/<stem>.test.<pid>.<nanos>`, built from the synthesized test
   main); a `with build` of the file has no test main. A red run keeps that
   artifact and prints `test binary kept: <path>` plus one
   `rerun: WITH_TEST_FILTER=<test> <path>` line per failure — the exact
   environment the runner gave the child (#1013). `with test --keep-binary`
   keeps it on a green run too, and `--verbose` names it for every run. Run
   the rerun line as printed — if it fails standalone, every later step
   works on it without the runner.
4. **Resolve the second free's site**: `lldb --batch -o "settings set
   target.env-vars WITH_TEST_FILTER=<test> WITH_DEBUG_ALLOC=1" -o
   "breakpoint set --name dbg_report_double_free" -o run -o "bt 24" -o quit
   -- ./bin`. One hit, seconds. Do **not** put unconditional breakpoints on
   `rt_alloc`/`rt_free` with backtraces — that is thousands of stops and
   times out on a four-test fixture.
5. **Resolve the first free and every touch of the block** with the
   allocator's own trap. **Run it under lldb**: outside lldb macOS
   randomizes the heap, so the address changes every run and a trap set
   from an earlier run never hits. Under lldb (ASLR off) the address is the
   same run to run, with or without `WITH_DEBUG_ALLOC`:
   ```
   lldb --batch -o "settings set target.env-vars WITH_DEBUG_ALLOC=1" -o run -- ./bin
       # read addr= from the DOUBLE FREE line
   lldb --batch -s tools/debug_drop_sites.lldb \
       -o "settings set target.env-vars WITH_DEBUG_ALLOC=1 WITH_DEBUG_ALLOC_TRAP_FREE=<addr>" \
       -o run -o "bt 24" -o quit -- ./bin
   ```
   The trap prints `trap-alloc hit=` / `trap-free hit=` for every alloc and
   free of that payload; `tools/debug_drop_sites.lldb` adds a backtrace at
   each hit and stops at the double-free reporter. To stop on the n-th free
   instead, `WITH_DEBUG_ALLOC_TRAP_FREE_HIT=<n>` panics there, and a panic
   is an ordinary exit: add `-o "breakpoint set --name with_panic_core"`
   before `run`, or lldb only reports `exited with status = 1`. A hardware
   watchpoint on the payload (`watchpoint set expression -w write -s 8 --
   <addr>`) is the other fast tool. #1014 asks for the first
   free's site to be recorded by default so the plain report names both.
6. **Read the function's IR or disassembly at the join block.** `with ir
   fixture.w` prints the module as codegen built it (stdout, before the
   LLVM pipeline); `WITH_DUMP_LLIR_PRE=1` / `WITH_DUMP_LLIR_POST=1` on a
   `with build` print it to stdout either side of the pipeline, which is
   the only view of the attributes codegen attached (`captures(none)`,
   `noalias`, `sret`) and of what the pipeline did with them; neither runs
   after a failed function verify, whose report shows only the invalid
   function — `WITH_DUMP_LLIR_ON_INVALID=1` prints the module as it stands
   then, with every callee's and thunk's declaration; a
   multi-unit build keeps each `<obj>.u<k>.gen.bc` under
   `WITH_KEEP_BITCODE=1` for `llvm-dis`. Or disassemble the one function:
   `lldb --batch -o "disassemble -n Type.fn" -- bin`. (There is no
   `--emit-llvm`.) Two
   unconditional drop calls after a `switch` merge, with no drop-flag test,
   is the whole diagnosis for the #729 class.
7. **Confirm with the drop-state view** (`--dump-drop-plan`,
   `--dump-drop-state`, `--validate-ownership`, below) and fix the lowering.
   For this class the validator is the reducer: `with reduce` deletes lines,
   and deleting lines changes the stack garbage (#1015).

### A wrong receiver mode, effect, or ownership verdict

`analyze file 'explain:effect:<fn>[:<param>]'` prints the provenance chain
down to the seed that first set the bit. Then `matrix:name~<fn>` to see the
first layer (AST, Sema, ABI, MIR, codegen) where the facts diverge. Never
bisect by neutralizing code: the #691 escalation cascade was one misattributed
seed, a one-query answer with provenance.

For a wrong view-origin verdict (a use-after-free accepted, a valid view
refused), start with `with analyze repro.w 'explain:origin:<fn>[:<binding>]'`
(below): per parameter, whether a returned view comes from its own storage
or only through what it views, and the node that first made it so; per
view binding, its origins, storage origins and dependencies each time
they were set. It runs on a program that fails to compile. Then
`WITH_DEBUG_BORROWS=1 with check repro.w` prints every view
binding with its dependency count and the borrow table at each read and
mutation check: a binding whose dependency is itself, or a local where a
parameter was expected, names the lost origin in one run (#2187).

### A `with build :fixpoint` failure

`with build :fixpoint-diff`, then `cat out/fixpoint-diff/report.txt`. The
report names the first differing byte; `llvm-nm`/`otool` attribute it to a
symbol. Nondeterminism is a codegen bug (unordered-map iteration, address-
dependent ordering); never an excuse for `-O0`.

### A lowering, MIR, ABI, or codegen bug on a compilable input

`with reduce` to a minimal input, `analyze repro.w audit:all` as the proof
gate (it must pass on the reduced repro before any build), `matrix` for the
diverging layer, `lldb:<query>` for breakpoints from real facts, then lldb
on the compiler branch. `--dump-abi` answers "is this parameter lowered
consistently at caller and callee" — never infer that from MIR.

When codegen picked the wrong formatter, comparison or ABI for a value (a
`BUG: … no registered :? formatter`, floats compared where a key
projection should be, a wrapper passed as its inner type), run
`analyze repro.w audit:resolution` first: its operand-type check names the
exact expression whose MIR operand has a type Sema did not give it, with
both types, before any debugger session. Then
`analyze repro.w 'select:kind=operator,detail~fn:<fn>'` shows how codegen
lowered each binary operator in that function: the route it took and the
operand types it saw (below).

### A wrong variant: the wrong arm, `unwrap` of a `Some` panics, `?` takes the error

A variant read through the wrong tag or index. Measure which code assumed
the representation instead of asking Sema, before reading any of it:

1. **`WITH_DEBUG_PERMUTE_TAGS=1`** on the compile (`WITH_DEBUG_PERMUTE_TAGS=1
   with-stage1 test test/behavior`). Every plain enum takes its tags in
   reverse declaration order; meaning is unchanged, so a program that
   differs from its normal run, or a typed-MIR ICE, is code that assumed a
   tag ("`Some` is 0", "the tag is the index"). The failing tests name the
   shapes; `--dump-mir` on one shows the switch value or downcast that
   assumed. Its first corpus runs (2026-10-05, `test/behavior/*.w`) went
   from 402 failures to 13 to the expected ones as each assumption was
   fixed: MIR switches comparing a discriminant with an index (the success
   switch, optional chains, `ControlFlow`), codegen's own tag table, Option
   and Result tags built as indices, the niche's "null is 1". Two fixtures
   differ under it by design, because they print the tag itself:
   `behav_1770_payload_enum_as_int` (`r as i32`, §4.4a) and
   `behav_comptime_type_info` (the reflected discriminant). Any other
   difference is a bug.
2. **`WITH_TRACE_VARIANT_FALLBACK=1`**: MirLower answering a variant lookup
   from the variant's name alone because the type does not declare it
   (`[variant-fallback] index of \`Some\` in type Result[…] fn \`total\``).
   Any line is a type-blind answer: a `Result`'s `Some` took Option's index
   and `?` treated `Err` as success (D97 reorder). Ask Sema's per-type
   answer (`sema.enum_variant_index_for_type`) instead.
3. The typed MIR validator's ICE names the body and the payload types
   (`enum payload read declares ty=549 but the variant's payload is ty=554
   in \`total\``); `--dump-mir` shows the `switchInt` value and the
   `<as vN>` downcast it chose.

### Run a corpus with the compiler you just built

`out/bootstrap/bin/with-stage1 test test/behavior` (any files or
directories) runs every fixture with its `//! expect-*` headers under
stage1: the corpus check a change needs before the battery, without the
release build `:behavior-tests` waits for. Add a debug switch in front
(`WITH_DEBUG_PERMUTE_TAGS=1`) to run the whole corpus under it.

Pass `test/behavior/*.w`, not the directory: `test/behavior/lib/` holds
helper modules, which fail as tests. Set `WITH_TEST_COMPILER` to the same
stage1 for the fixtures that spawn a compiler. Eight fixtures fail under
any stage1 (main's too, measured 2026-10-05) and pass under the release
binary: the comptime snapshot memory limit, the rt-in-unit check lane, the
build-action and RSS-budget fixtures and the raw-pointer effect order
(`behav_1944_comptime_snapshot_memory`, `behav_rt_in_unit_check_lane`,
`behav_action_absolute_paths`, `behav_action_binary_read_errors_strict`,
`behav_action_binary_read_errors_strict_read_binary`,
`behav_1899_build_store_undeclared_read`, `behav_build_rss_budget`,
`behav_sema_raw_pointer_effect_order`). Compare against main's stage1 in a
worktree before calling one of yours.

### A re-migrated corpus fails its own test suite

Never a file-by-file bisect of the fresh output (#2230: six files, fifteen
sites, three rebuilds, and the failure was not in the text). The order:

1. **What ran.** Every corpus test action prints `<target> ran <sha256>
   <path>` for each binary before it runs it and appends the same lines to
   `out/corpus/<stem>-test/provenance.txt` (`corpus_provenance`,
   build/corpus.w). Compare the sha with a second run: a different binary
   from identical sources is a build defect (the native runner's partial
   attempt before a 97 fallback, a stale bundle), not a migration defect.
2. **What the migrator changed, as MIR.** The migration differential:

   ```sh
   with run tools/migrate_diff.w lib/std/re out/pcre2_migrated pcre2test.w re
   ```

   lays each side out as `lib/std/<subdir>/` under `out/tmp/migrate-diff/`,
   checks `<main.w>` with `--dump-mir --bundle-corpus std/<subdir> --no-prelude`
   (the corpus on its source: the embedded interface would answer every
   `use std.<subdir>.X` and the dump would hold no corpus body; the prelude
   off, as the bundle builds, or its std.regex reaches the checkout's
   lib/std/re beside this tree), splits the dump per function and
   compares the statements with every id normalized (`symN`, `_N`, `bbN`,
   `tyN`, `.fN` are positions, not meaning). It names each function whose
   lowering differs and prints the statements present on one side only;
   exit 1 when any differ. Under each differing function it names the
   migrator rules applied to it: a directory migration writes `rules.tsv`
   beside its output (`rule<TAB>function<TAB>detail`, one line per
   distinct site — D101's `T.zeroed()` rewrites, D107's nullable-by-evidence
   parameters and the NULL-compare folds they license; never promoted into
   a corpus), and a function that differs with no rule recorded is a
   difference that is not a migrator rewrite (#2230). On #2214 it reported four functions, each with
   exactly `aggregate(... const 0 ...)` → `const zst(ty)` or a `with_memset`
   call → `_.* = const zst(ty)`: the rewrite and nothing else, which points
   the hunt at the build. A difference it shows that is not the intended
   rewrite is the bug's function. (Naming the migrator rule behind each
   site is the open half of #2230.)
3. **The compiler alone.** Run the corpus test on the checked-in corpus
   with the new compiler (facade-one-owner's `with build :pcre2-test`
   shape): a failure there is the compiler's, not the output's.

### A hot loop reloads a struct's fields after every store

The compiler's own optimized IR (`WITH_DUMP_LLIR_POST=1`) says why. Two
causes so far, both diagnosed there and neither visible in disassembly: a
runtime declaration or a `&T` parameter without `captures(none)`, so LLVM
must assume a loaded pointer can alias the caller's stack value (bench
nbody, 3x); and drop glue passing an aggregate's field address to a call,
which keeps the aggregate in memory and, past ~100 explored uses, defeats
LLVM's capture tracker outright (bench ecs, 1.8x). The test that separates
"attribute missing" from "address taken" is `opt -O3` on the pre-pipeline
module with `-capture-tracking-max-uses-to-explore=4096`: if the reloads
vanish, the address is being taken; fix the glue, never the knob.

### The compiler crashes or aborts on an input

An internal `BUG:` line, a SIGTRAP (exit 133), or exit 134 is a compiler
defect regardless of what the input did. Reduce it (`with reduce --exit-code
nonzero -- with check {file}`), then lldb on the compiler: LLVM frames in the
backtrace mean invalid IR construction, pure With frames mean a With-side
abort (#653's `switch undef` class). File it with the reduced input. A
`BUG:` about a generic instance (`generic-inst payload miss`, a field cache
miss after freeze) is a type created or reflected in the wrong phase:
`WITH_TRACE_INST=1` prints every instance as it is added and as the eager
pass preregisters it, so the missing step shows (#2188).

## Integrated Compiler Analysis

`with analyze` is the primary cross-layer debugging surface. Unlike a standalone
scanner, it reads the compiler's live AST declarations, finalized Sema signatures
and effects, concrete specializations, `MirBody` tables, diagnostic provenance,
and the actual LLVM marshalling/prologue branches used for production codegen.

```sh
with analyze repro.w audit:all
with analyze repro.w audit:storage
with analyze repro.w 'matrix:name~target_fn'
with analyze repro.w 'path:call:main:target_fn'
with analyze repro.w 'closure:call:main'
with analyze repro.w 'lldb:kind=call,name~target_fn'
with analyze repro.w contract
with analyze repro.w audit:contract
with analyze repro.w 'select:stage=sema,kind=global-effect'
```

The global-effect view reads recorded writes, calls and their expanded targets,
live-view checks, cached user-drop decisions and dynamic-drop target resolution.
Its `drop-target` rows retain the lookup context and the actual enqueue/skip
branch; inspecting the graph does not resolve names or expand it again.
Signature rows include the canonical declaration and name-based declaration
lookup, with unsafe status read by the same Sema helper as acceptance checks.

`contract` (D51 stage 10, ruling §63; `src/AnalysisContract.w`) prints the
effective modeled foreign contract of every `c facade` block the program
sees: per resource its production, status, destroy paths, dependencies,
thread capabilities, the views borrowed from it and the operations that
invalidate or preserve them; per fn item each parameter's effect, the
result's origin, invalidation and presentation; per callback parameter its
role and thread; per domain its scope, views and invalidators; and each
`use convention`. Every row ends in its provenance — the facade clause with
file and line, or `default:` with the conservative rule — and the same rows
are the `foreign-contract` facts of `select:kind=foreign-contract`.
`audit:contract` (in `audit:all`) is the ruling's suspicious-configuration
list: a producer with no destroy path, a destroyer presented as a lend, a
retained parameter with no lifetime owner, an illegal thread combination,
and the advisory — a name and shape that resemble a destroyer, exposed as a
lend, silenced by an explicit `lend`. Each violation names the clause, its
line and the clause that resolves it; nothing it reports changes a verdict.
Both read Sema's snapshot, so they run when a facade clause was refused too.
The profile checks (ambiguous match, shadowed fact) fire only once stage 11
resolves a convention profile. Fixtures: `test/contract/`
(`with build contract-view-tests`).

`audit:resolution` (D65, #1647; `src/AnalysisResolution.w`, in `audit:all`)
checks that every MIR call agrees with Sema's resolution of the call it
lowers — Sema decides *what* a call invokes, MIR materializes it, and a
callee MIR re-derived from an AST spelling is the #1635 class (`let r =
c.run; r(21)` lowered to a GENERIC_CALL to a function named `r` with the
argument dropped; every validator stayed silent, #1639). Phase 1 covers
callees and argument counts. For each MIR call terminator it gathers Sema's
answer for the call's own node (`get_sig`, `generic_fn_node_for_symbol`,
`call_callable_types` — the callable type Sema recorded for an indirect
call — `call_callee_is_builtin`, `resolved_call_sigs`) and compares: a
`const fn` callee must be a declared signature, a generic template (under
its GENERIC_CALL mark), a builtin Sema classified, or a body of the module;
a place callee must be a call Sema resolved through a callable value; the
argument count must equal that same fact's parameter count (a variadic
signature or an extern fn type states none); a call node Sema resolved to
one signature must not lower to another; and a call Sema resolved inside a
lowered body must have a MIR call fact carrying its node. A call with any
other intrinsic mark is recognized by its kind and not judged, and so is a
GENERIC_CALL carrying the machinery-dispatch mark MirLower's one contract
decision point sets on a Task/ScopedTask/channel/Atomic method, `track`,
`spawn` or `join` (codegen dispatches those by name and receiver; phase 5
moves that classification into Sema, and the mark retires with it). Each
violation names the body, the node's `path:line:column`, MIR's answer,
Sema's answer and the rule (`select:kind=invariant,detail~resolution:` has
the same rows). Nothing here is decided from a name: the builtins come from
Sema's own classification, snapshotted into the MIR module
(`sema_callable_syms`) for the typed-MIR validator, which refuses a
`const fn` callee outside the snapshot with no body and no intrinsic mark
(`--validate-all`, #1639). Planted fixtures: `test/internals/
analysis_resolution_test.w` (the comparison over a hand-built body and a
hand-built Sema answer) and `test/internals/mir_unknown_callee_test.w`
(the validator); the clean corpus is `audit:all` on the contract, closure
and c_facade fixtures and on `build.w`. Phases 2–5 (codegen mode
provenance, places and origins, effects, MirLower cleanup):
`docs/spec/implementation/mir-sema-hardening.md`.

**Operand types.** `audit:resolution` also judges every expression MIR
lowers: the operand `MirBuilder.lower_expr` returns for a source node has
the type Sema gave that node in this body's instance (MIR records the pair,
`MirBody.expr_operand_*`; the operand's type is the place's recorded type,
never re-derived). Sema's own adjustments are its type: a contextual copy
is not judged, a splat or lane conversion (§4.3d) is judged against the
adjusted type, and a pass-through form (grouping, a block, `comptime`,
`unsafe`) is judged through its inner node. A violation reads
`an expression lowered to an operand of another type (MIR M, Sema f64,
node kind 27)` at the node's `path:line:column`. It would have caught both
of D97's bugs before codegen: a distinct's `.value` lowered with the
wrapper's type, and `TotalF64(1.0)` folded to a bare `f64` constant, so
the f-string formatter and `==` read the wrong type. The note line
`expression-operands judged=N disagree=0` reports the count.

**Operator facts.** `select:kind=operator` (a `select` that names codegen
facts runs the backend) lists one fact per binary operator codegen
lowered, with `detail` in `key:value` words so a query can filter it
(`detail~fn:main`, `detail~route:float`, `detail~lhs:TotalF64`):

```
route:key-projection fn:main span:429 lhs:TotalF64 rhs:TotalF64 llvm-lhs-kind:3 llvm-rhs-kind:3
```

`route` is the branch of `Codegen.mir_build_bin_op` that produced the
instruction: `int`, `float`, `str`, `str-order`, `str-view`,
`key-projection`, `structural`, `view-pointee`, `aggregate-bytes`,
`pointer-arith`, `pointer-null`, `pointer-address`, `shift`, `concat`.
`span` is the statement's source offset. "Why did these compare as
floats" is `route:float` on a type with a key projection: one query, no
trace print (D97's `TotalF64 ==` was exactly that). An operator spelled
as a method (`<` through `cmp`) is a call and appears under
`kind=codegen-argument` instead.

`audit:all` is the proof gate before an expensive build. It validates MIR shape,
types, and ownership; receiver declaration coverage and finalized contracts;
effect-flow fixed point; frozen caches and specialization bodies; frozen-phase
mutable-Sema calls; LLVM declaration pass modes; caller argument marshalling;
callee place aliasing; and the analyzer's own coverage of reachable ordinary
calls. It also runs `audit:storage`, which checks AST-indexed table bounds,
parallel start/count storage, canonical argument-node validity, and non-colliding
64-bit keys across the former 16-bit AST-node boundary. The command exits nonzero
on any violation.

`audit:pool-views` (also in `audit:all`, #1323) finds a reference into a
growable pool that is still read after the pool may have grown — the
`let name = intern.resolve(sym)` … `intern.intern(…)` … `name ++ …` shape that
segfaulted the release compiler. `InternPool` lives behind a Copy `*mut`
handle, so the ordinary view-invalidation check cannot see the aliasing; the
audit derives every role from the live MIR instead of names: a *pool field* is
the `F` in `<place>.F[i]` whose element some body returns a `ref` to (through
`copy` chains to `_0`); a *producer* is that body or any body whose result is
a producer's result (`InternPool.resolve_symbol`, `resolve`,
`Sema.pool_resolve`, …); a *grower* is a body that passes a place ending in a
pool field as the receiver of a `mut fn` or mutating container intrinsic
(`symbol_texts.push`) or assigns the field, plus everything that reaches one
over the MIR call graph; a *hit* is a local holding a producer's result that is
read, passed, or written through after a call to a grower with no reassignment
in between, on any CFG path. Each violation names the function, the binding,
the producer, the source line, the call that poisons the view and the direct
grower it reaches. Fix by owning the text at the binding
(`intern.resolve(sym).clone()`) or finishing with the view before the call. Not
covered: a view stored into an aggregate, a view from a builtin (`Vec.get`),
and a view into a container the function itself owns (`&Vec[str]` parameter).

Cost: instant on a repro; on the compiler itself (`analyze src/main.w
audit:all`, the batch-tier step) about 170 s and 20 GB resident at 12033103.
It is a batch-tier gate, not a per-edit one.

Use `matrix:<query>` for root cause. A call matrix places AST/Sema/ABI/MIR and
Codegen facts in one stable table, making the first diverging layer visible. Use
`facts` or `snapshot` for the complete stable TSV schema, `summary` for counts,
and `select:<query>` for narrow machine-readable slices. Query operators are
`=`, `!=`, and `~` (substring), joined by commas.

Source-bearing facts include the source-file ID, byte `start`/`end`, line/column,
path, and declaration owner. MIR `call-argument` facts join the lowered operand,
type, effects, and ownership kind back to Sema's canonical AST argument node; for
methods the analyzer accounts for the implicit receiver argument. AST node IDs are
snapshot-local: rerun the query after any source change before using
`explain:node:<id>`.

`lldb:<query>` emits breakpoints on the **compiler's** branches that
handled the matching facts (`Codegen.marshal_mir_call_arg`,
`MirBuilder.lower_call_arg`), not on the program: save them and run lldb on
stage1 compiling the repro:

```sh
with analyze repro.w 'lldb:kind=call,name~take' > take.lldb
lldb --batch -s take.lldb -o run -o "bt 6" -- out/bootstrap/bin/with-stage1 build repro.w -o /tmp/repro
```

On the installed `with` the dotted names stay `pending` (see Which binary).

The live MIR graph backs `path:call:<from>:<to>` and
`closure:call:<root>`. Prefer these over parsing source text. There are no legacy
semantic scanner fallbacks. If compilation stops before the needed snapshot, use
`after-mir:<request>` when available, reduce the input, or attach LLDB to the exact
compiler branch that stopped it.

Use an analysis audit directly as a reduction predicate:

```sh
with reduce repro.w --exit-code nonzero -- \
  with analyze {file} audit:all
```

## Ownership Transfer Classification

`analyze <file> move-sites` classifies every call site where a plain non-Copy
argument binds an OWNED (consume/escape_value) parameter — the sites the
"takes ownership" diagnostic reports. It is a semantic-snapshot request: it
runs from the live Sema state even when the check fails, which is its primary
use (partitioning an error worklist, e.g. the #691 flip's, before deciding
which sites get a `move` keyword and which need design work).

```sh
with analyze src/main.w move-sites
```

One TSV row per site:

```
file:line:col  root  shape  spellable  liveness  loop  callee  param
```

- `shape` — `ident` (bare binding), `field` (field-path place), or `other`.
- `spellable` — whether `move <arg>` is expressible today (`ident` and
  `field` are; `other` needs the temp-local dance or a spelling extension).
- `liveness` — `last-use` when the call is the final use of the root in the
  enclosing body (a `move` cannot introduce use-after-move), `live-after`
  when later uses exist (a DESIGN site: adding `move` blanks a value the
  flow still reads — Backend.w's take-and-return class), or `unknown`.
- `loop` — `in-loop` when the call sits inside a loop body; such sites are
  conservatively design-flagged regardless of textual liveness (a
  next-iteration use is not textually "after").

The verdicts come from the checker's own use tracking, not source scanning.
`last-use` is proof the keyword is safe; `live-after` is a reading
assignment, not a verdict that the design is wrong.

## Ownership Seam Inventory

`analyze <file> seam-sites` inventories the latent aliasing/blanking seams
behind the #691-flip double-free/leak family, from live MIR operand and place
facts — before a test or the allocator trips over them at runtime. Like
`move-sites` it is report-mode: it always exits 0 and its output is a
burn-down worklist for facts-driven migrators and the future #715/§15.6/#718
gates (the gate and the query share the predicate; the gate is this report
flipped to a diagnostic once the inventory is clean).

```sh
with analyze src/main.w seam-sites
```

Every row carries a **tier**, and the summary counts both:

- **actionable** — the copy is RETAINED (`store-assign`, `store-aggregate`,
  `call-arg-owned`) or the operand is a move. Only then does a second owner
  drop it, which is what makes the seam a latent double-free. Moves are
  always actionable: they blank a place another owner still drops.
- **observed** — a `read`-position copy: an operand of a non-storing rvalue
  (a length read, a comparison) that never drops. Reported for completeness,
  not for burn-down. Without this split the inventory read 1176 findings when
  5 were real, and a report that cries wolf gets ignored.

Burn down the actionable tier; treat a rising actionable count as the
regression signal.

One TSV row per deduped `(fn, class, place)`; classes:

- `move-through-ref` — a move of a subplace behind a `&T` root: blanks
  storage the borrow's owner still drops (the `let zcu = self.zcu` class).
- `move-raw-deref` — a move through a raw-pointer root: blanks the pointee
  behind the compiler's back (`*sema_ptr` handoffs).
- `copy-elem-drop` — a copy of a Drop, non-Copy value through an index
  projection: an aliasing element copy; stored copies double-free, plain
  locals leak (#715, the `BuildGraphTarget` filter class).
- `copy-view-drop` — a copy of a Drop, non-Copy value through a `&T` root
  (the capability-record derivation class).
- `copy-raw-deref-drop` — same through a raw-pointer root.
- `escape-view-consume` — `EFF_ESCAPE_VIEW` on a consuming plain-`T`
  parameter: a returned view of a place that dies with the call (#718).

Findings are seams, not automatic bugs — a `copy-view-drop` may be a
deliberate leak-class read — but every double-free root-caused in the D22
batch (docs/completed/handoff.md, D22 Stage 6 era, §3 roots 15, 18, 19) matches
exactly one of these rows.
Burn the list down with clones/views (see the `bg_clone_str_vec` /
`&vec[i]` idioms), or classify a row as intended where the disposition is a
known pinned leak.

## Effect Provenance

`analyze <file> 'explain:effect:<fn>[:<param>]'` prints WHY a parameter
carries each ownership-forcing effect (consume/escape_value/write), as a
chain from the queried parameter down to the seed that first set the bit —
either a direct source construct (a struct-literal move, a returned place, a
call argument) or an effect-flow edge into a callee parameter, followed
recursively until a direct seed is reached.

```sh
with analyze src/main.w 'explain:effect:Zcu.clear_stage_outputs:self'
```

A method is `Type.method`; a free function its name. A generic function's
body is checked per specialization, under a mangled name
(`iter_collect__sema__411:3428:163=17:364=320`): `explain:effect:` on the
plain name says `no signature matched`, and
`select:stage=sema,kind=signature,name~iter_collect` lists the real one.

An `escape_view` line reads `origins=[…] through=[…]`, parameter indices
both: `origins` are the parameters the returned view may come from, and
`through` the subset whose result views only what that parameter views,
never the parameter's own storage. A parameter in `origins` and not in
`through` is one the result points into, so the caller's argument must
outlive the result.

Provenance is recorded at first-set during body checking and the effect
fixpoint; the chain names each hop's source location. Use this instead of
neutralize-bisection when a receiver demands a stronger mode than expected —
the 57-method escalation cascade in #691 was exactly one misattributed seed
plus transitive root edges, a one-query answer with provenance and an
afternoon of bisection without it. Also a semantic-snapshot request: works
on erroring inputs.

## View Origins

### The thing that compiled was not the thing under test

Every compiler a build action spawns is named in the action log:
`[compile] <target> ran <digest> <binary> <argv>` (lib/std/build.w
`tool_compile_provenance`, hashed once per binary per driver run), and a
Workspace compile prints `[driver-compile] <workspace> compiler=<path>
files=…` — that compiler is `WITH_BUILD_COMPILER`, the DRIVER, the pinned
seed when the battery drives. A Workspace compile of a std corpus module or
its harness is refused outright: those are compiled by the compiler under
test as a subprocess with `--bundle-corpus` (`corpus_compile_binary`,
`corpus_check_every_module`). Before this, pcre2's cohesive check read the
embedded interface instead of the migrated tree and zlib's harness was built
by the seed, and no line said so (#2247, #2249). `WITH_DEBUG_IMPORTS=1`
on the compiler itself prints every module file it registers.

### A nameless runtime panic, in one generation only

A panic prints its backtrace in-process (`rt_backtrace_print`: Darwin walks
the unwind tables through libSystem's `backtrace`, Windows through
`RtlCaptureStackBackTrace`), innermost first, with the mangled
`__with_mod_…` names; `atos -o <binary> <addr>` gives the line. A panic
in stage2 only, right after a "now a view" change, is a view that escaped
a temporary — and the temporary-view checker should have refused it
(§21.1; fix the checker in the same batch).

### A pass that runs past its timeout

The runner samples the child before killing it: on a timeout the runtime
runs `/usr/bin/sample <pid> 2` into `/tmp/with-timeout-<pid>.sample` and
prints the path on stderr (`timeout: child N sampled to …`). The top frames
name the hot loop; two migrations ran twenty minutes each before one was
sampled by hand (an exponential resolver walk, #2249).

### Two compiler generations disagree

```sh
with run tools/gen_diff.w out/bootstrap/bin/with-stage1 out/release/bin/with repro.w
with run tools/gen_diff.w out/bootstrap/bin/with-stage1 ~/.local/bin/with repro.w explain:modules
```

runs `analyze <file> <query>` under both binaries (default
`select:kind=declaration`, which a failed compilation still answers),
normalizes the ids that shift between builds and the std path spelling
(`lib/std/` and `<embedded-std>/std/` are one module), and prints the lines
only one side produced; exit 1 when they differ. #2248's bare `Target` was
the declarations stage1 loads through a corpus and the release never does.

### A name resolves on one compiler generation and not the other, or a std helper stops resolving

Visibility is three walks, a gate of rules and a fallback bridge; a 0 out
of them says nothing. `with analyze file.w 'explain:visible:<name>'` lists
every declaration the name could mean from the root module — values,
types and displaced identities (#1350) — with its module, package, engine
id, prelude-closure and corpus-private marks, then the verdict and every
rule and walk edge it passed through (`skip … (corpus boundary: engine 1
-> 0)`, `not reached from …`, `cached verdict`), and the fallback bridge's
own reasoning. `explain:modules` says why each module is in the
compilation: its marks and the modules that import it, the chain that
pulled it in. Run both under each generation (`out/bootstrap/bin/with-stage1`
and `out/release/bin/with`) and diff: #2248 was a module stage1 loads through
a corpus and the release never does; #2249 was a bridge that required an
engine twin to be ambient after the corpus boundary made no corpus ambient.
A rule toggled and rebuilt to see what changes is the bisect this replaces.

**A name accepted in one spelling and refused in another.** Write the
name three ways in one program — a runtime use (`let t = X`), a comptime
subject (`comptime match X` or `comptime if X.is_copy()`), a type position
(`let v: X`) — and run `explain:visible:X`. The verdict is Sema's gate; a
spelling that disagrees with it did not ask the gate. #2248's second half
was two of them: the evaluator found every module's `let` by name
(`ComptimeEval.find_module_let_decl`) and read the flat type table
(`static_type_expr`), so `comptime match HIDDEN` through a module never
imported printed a value while `print(HIDDEN)` beside it was refused, on
every generation. The fix routes the lookup through the gate
(`decl_node_visible_from_current`, `lookup_named_type_visible`); the
fixtures are `test/compile_errors/err_2248_comptime_*_not_transitive.w`.

```
explain:visible is_alnum
  from module test/behavior/behav_1362_std_helper_resolves_unimported.w (package <program>)
  value declared in lib/std/re/defs.w (package <std>, pub=1, engine=1, prelude-closure=0, corpus-private=0)
    gate: … not an enumerated prelude name; engine=1 prelude-closure=0 corpus-private=0
      no-prelude walk: skip <embedded-std>/std/prelude.w (the synthetic prelude edge)
      refused: an engine or prelude-closure module needs an explicit import path
    verdict: 0
  displaced value (#1350) declared in <embedded-std>/std/string.w (… prelude-closure=1 …)
    verdict: 0
    bridge: 1 non-engine std module(s) declare it; engine twin lib/std/re/defs.w
  fallback bridge: resolves the bare name to <embedded-std>/std/string.w
```

`analyze <file> 'explain:origin:<fn>[:<binding>]'` prints what Sema recorded
about the views of `<fn>` (a generic function by its plain name: every
specialization matches), even when the check fails:

```
explain:origin at_match
  at_match param[0]: a returned view may come from it, only through what it views (origins=[0] through=[0])
    first view at repro.w:12 (node 579952)
  binding `v` bind at repro.w:12: origins=[0] storage=[0] deps=[s]
```

Per parameter that a returned view may come from: whether from the
parameter's own storage (the caller's argument must outlive the result) or
only through what it views, and the node that first put it in the
origins and in the storage set. Per view binding (`:<binding>` narrows to
one name), a row each time its origins were set or merged: `bind` (a
`let`, a pattern, a parameter alias), `store` (a view pushed into it),
`loop` (a `for` binding); `origins` and `storage` are parameter indices,
`deps` the locals it depends on. A binding whose `deps` names itself, a
local where a parameter was expected, or a `first storage` row on a value
that should only be viewed through, is where the origin went wrong. Sema
records these as it checks (`Sema.view_fact_*`, `param_view_fact_*`); the
binding table itself is gone once a body is checked, which is why this
existed only as trace prints before (#2187's two-hour hunt).

## Repro Reduction

`with reduce` minimizes a single-file repro by deleting source lines while a
predicate still holds.

```sh
with reduce repro.w \
    --contains "undefined variable" \
    -- with check {file}
```

Options:

- `--out <path>` writes the reduced repro somewhere specific.
- `--contains <text>` requires predicate stdout/stderr to contain the text.
- `--exit-code <n|nonzero>` requires an exact exit code or any non-zero exit.
- `--test <name>` replaces the `--` predicate with the test runner: each
  candidate goes through `with test {file} --filter <name>` (the runner sets
  `WITH_TEST_FILTER=<name>` for the child exactly as `with test` does), and
  the reduction holds while `<name>` still fails in the stage the original
  failed in (build vs run) and, with `--contains`, with the same text. The
  binaries a red run keeps (#1013) are discarded per candidate; run
  `with test` on the reduced file to get one.

```sh
with reduce fixture.w --test test_needs_two_lines
```

The source path must immediately follow `reduce`. Use `{file}` in the predicate
argv for the candidate path; without it, the candidate path is appended.

The reducer keeps the smallest file the predicate still accepts, whatever
else is wrong with it: `--contains "mismatch"` on a type error reduced a
seven-line program to one orphaned indented line. Make `--contains` the
exact diagnostic you are chasing.

What it cannot reduce: a layout-dependent bug. A drop of uninitialized stack
garbage (the #729 class) changes with every deleted line, so the predicate
flips on noise and the reducer converges on nothing (#1015). That class is
not a line-deletion problem: go to the drop-state view (`--dump-drop-state`,
`--validate-ownership`) and the allocator instead — there the validator is
the reducer.

## The drop-state view (one dataflow, several views)

One analysis backs all of these: a per-body dataflow over every place the
MIR can name (locals and projected places, interned per body), joined at
every predecessor to a fixpoint — including back edges and join blocks that
are numbered before the arms that feed them, which the pre-12033103 single
sweep silently skipped. States: `Uninit`, `Init`, `Moved`, `Maybe`, and
`MaybeGarbage` (some path never touched the place: a drop there frees
stack garbage, the #729 class).

```sh
with check repro.w --dump-drop-state
with check repro.w --dump-drop-plan
with check repro.w --trace-ownership main:_1
with check repro.w --trace-cleanup-edge 'main:bb0->bb1'
with check repro.w --validate-ownership
with check repro.w --validate-all
```

Each dump covers every body in the module, the standard library's
included (189 functions for a ten-line program): find your function by
`(name)` in its header line, `fn sym366(f) {`. A place argument such as
`f:_1` names a MIR local, and `_1` is the first local, often a parameter:
read the local's number from `--dump-mir` first.

- `--dump-drop-state` prints every block's in/out state.
- `--dump-drop-plan` prints each MIR drop site with the state before it and
  an `action` (`drop`, `drop-conditional`, `skip`). **Read `action` as the
  analysis's verdict, not as what codegen does**: there are no runtime drop
  flags (a conditional move resets its place to the empty value, §2.5.2, or
  clears its hidden liveness byte, D72), and codegen emits every `drop`
  statement, so a `skip` on an `Uninit` place is a drop of garbage at
  runtime. Making that a hard `check` error rather than an opt-in validator
  is the intended end state.
- `--trace-ownership <fn:place>` prints the before/after state at every
  statement or terminator that touches the place (empty place: all places).
- `--trace-cleanup-edge <fn:from->to>` prints the state across one CFG edge.
  Quote the argument; `>` is a shell redirection.
- `--validate-ownership` rejects a drop of a `MaybeGarbage` place and
  reports the first error; `--validate-all` runs every MIR validator.
- `--dump-place-map` lists each MIR place with base local, type id, and
  projection list, for when `_N.fK` does not mean what the source seemed
  to say.
- `--dump-drop-flags` is gone: it dumped the runtime drop flags, and those
  were removed with the rest of the M7 drop-flag machinery (63e351af6,
  2026-06-30) once the niche reset handled every conditional move. The
  drop-state and drop-plan views above are what it pointed at.

These show what MIR believes. They now believe the right thing about joins,
but still use `lldb` on the lowering or codegen branch to prove *why* a
statement is where it is.

## Source Rewrite Clients

Semantic selection stays in the compiler. The remaining source tools are thin
clients of `compiler_analyze_file`; they may use the compiler Lexer only to verify
and apply byte splices inside compiler-proven spans:

- `tools/annotate_receivers.w` applies finalized Sema receiver requirements.
- `tools/migrate_receivers.w` removes explicit receivers only from declarations
  Sema identifies as valid impl methods with matching modes.
- `with migrate-receivers` (built into the compiler, `src/ReceiverMigration.w`;
  `--report|--list|--apply <entry.w>`) relocates only Sema-identified top-level
  instance methods and verifies one semantic fact per structural rewrite.
- `tools/migrate_method_arg_moves.w` consumes structured diagnostic facts and
  exact spans; it never parses rendered stderr.

All clients preflight the complete file/path and fail before writing on missing,
duplicate, ambiguous, or mismatched facts. The removed receiver/frozen/closure,
AST-metadata, diagnostic-map, and receiver-flip scripts must not be recreated.

A purely lexical class of rewrite (`.get(i as i64)` → `v[i]`, `byte_at(i)`
→ `s[i]`) is a `with -p` regex or a balanced-paren With script, run tree-wide
in one pass; the type checker is the safety net, and the two traps are map
receivers (a HashMap `.get` is a lookup, not an index) and build-driver files,
which must stay compilable by the installed seed.

## Instruction-Level Root Cause

`with analyze lldb:<query>` generates breakpoints from live facts, but LLDB is
still the authority for the exact failing instruction and runtime condition. Stop
at the function/branch, inspect registers and the backtrace, and disassemble when
source-level stepping hides an inlined checked operation.

The resolved-call storage failure is the model: LLDB proved that
`resolved_call_arg_key(call_node, idx)` shifted an `i32` node by 16 bits and hit
checked overflow at node 37418; even without the panic it would collide above
65535. The repair separated start/count maps and changed default-argument keys to
an `i64` 32/32 representation. `audit:storage` now preserves that proof. A trace
count or error table would only have characterized the failure; the debugger named
the exact function, instruction, operands, and invalid capacity assumption.

### Batch LLDB on compiler binaries (proven recipes)

Hard-won specifics for `lldb --batch` against `-O1 -g` With binaries:

- Symbol names are dotted: `breakpoint set -n Codegen.gen_module`, not
  `gen_module`, on a binary with debug info (stage1, stage2, release). A
  bare-name breakpoint, or any dotted name on the installed `with`, reports
  `no locations (pending)` and the run proceeds uninstrumented: check the
  `Breakpoint 1: where = …` line before reading the result. A regex
  (`breakpoint set -r record_pattern_view`) matches either.
- A breakpoint command list is a `DONE` block:
  ```
  breakpoint command add
  thread backtrace -c 12
  continue
  DONE
  ```
  Repeating `--one-liner` keeps only the last command, so the backtrace
  never prints (the debug_drop scripts had exactly this until 2026-10-05).
- Function-body breakpoints on our `-O1` binaries can resolve yet never fire
  (line-table skew); LLVM C API symbols (`LLVMAddFunction`,
  `LLVMTargetMachineEmitToFile`, `LLVMBuildAlloca`) are reliable anchors with
  ABI-stable argument registers.
- Parameters have variable info: at a breakpoint `frame variable` prints
  them (`(int) node = 494`). `self` and locals the optimizer kept in
  registers read `<unavailable>`; read those from the entry registers at a
  non-inlined symbol entry, and treat `[inlined]` frame line attributions as
  unreliable. A regex breakpoint (`breakpoint set -r record_pattern_view`)
  finds a method without spelling its owner.
- `register read` transcribes inside breakpoint command lists;
  `memory read` with a `$reg` address does not — do memory dumps at the
  final stop from the `-o` command stream instead.
- To classify an `llvm::Type*` without expression evaluation:
  `memory read -s1 -fx -c 4 '$x1+8'` — the byte at +8 is the TypeID
  (7 = void on LLVM 22). `CreateAlloca` of a void type is what a
  `DataLayout::getTypeSizeInBits` `brk #1` under an alloca backtrace means.
- A silent SIGTRAP (exit 133, no output) is either an LLVM release-build
  `brk` or a `switch undef` miscompile detonating; the backtrace
  discriminates in one run — LLVM frames mean invalid IR construction,
  pure With frames mean the silent-undef class (#653).
- Conditional breakpoints (`--condition '$x0 == <addr>'`) on hot runtime
  entry points evaluate an expression per hit and are effectively hangs on
  real programs. Use a reporter breakpoint or a hardware watchpoint instead.
- Set the environment with `settings set target.env-vars A=1 B=2`, not `env`.

### Native Windows, no debugger (proven on #1081)

A native Windows box may have no lldb, cdb or windbg (the LLVM SDK ships
none; VS Build Tools ships none). The route still closes, because the
runtime carries the two things the debugger was for:

- **Every panic prints a backtrace** (`rt_backtrace_print`,
  rt/windows_x86_64.w): Win64 unwind tables let
  `RtlCaptureStackBackTrace` walk the stack with no frame-pointer chain,
  and dbghelp symbolizes against the PDB the link wrote. So
  `WITH_DEBUG_ALLOC_TRAP_FREE_HIT=<n>` stops ARE the call chain of the
  n-th free, and the invalid-free panic names the second free's frames by
  itself. Frames are `_wcu$NNN$fn+0xNN`; inlined callees are attributed
  to the caller (#1081's str drop sat in `win_list_append`, reported as
  `win_list_files_walk+0x143`) — pair the frame with `--dump-drop-plan`
  of the callee to name the statement.
- **The invalid-free panic prints forensics**: the slab or large range
  holding the header, the offset, and the header word. A slab address or
  0 there is a freelist link — the block was already free, so this is a
  double free before any trace runs.

Making the address stable across runs, since lldb's ASLR-off is not
available:

```
copy out\bootstrap\bin\with-stage1.exe with-stage1-noaslr.exe
editbin /DYNAMICBASE:NO with-stage1-noaslr.exe      # MSVC Build Tools; bottom-up VirtualAlloc is deterministic without ASLR
```

Then the address depends only on the allocation sequence, and two things
change that sequence between a learn run and a trap run: the environment
block (add the trap variables to the LEARN run too, zero-padded —
`WITH_DEBUG_ALLOC_TRAP_FREE=000000000 WITH_DEBUG_ALLOC_TRAP_FREE_HIT=00000`
— then substitute digits) and any path the program builds from its
arguments (an output label of a different LENGTH moved #1081's address by
one 64 KB granule; a listing of a directory whose contents changed moves
it too). Keep both byte-identical between runs; the trap run's own panic
line shows whether the address held.

A `with test` that reports `exit code -2` at the run stage with no child
output, or a `with run` / `with -e` that exits with no output, is the
spawner, not the program: `-2` is `-ERROR_FILE_NOT_FOUND` from
`CreateProcessW`, which does not resolve a RELATIVE forward-slash program
path (`out/tmp/x.exe`) from the command line. Compilers older than the
argv[0] backslash fix in `win_build_command_line` (#1081) hit it on every
compiler-built binary; a probe through `std.process.run` with the three
spellings (relative `/`, relative `\`, absolute) tells them apart in one
run. Running the kept binary by hand always worked, which is the tell.

## Fixpoint Diff

When `with build :fixpoint` fails, generate a focused byte-level report:

```sh
with build :fixpoint-diff
cat out/fixpoint-diff/report.txt
```

Or run it directly:

```sh
with fixpoint-diff \
    out/stage/bin/with-stage2-fixpoint.o \
    out/stage/bin/with-stage3-fixpoint.o
```

The report names file sizes, whether the size differs, the first differing byte
offset, and a small byte window around the mismatch. It does not yet attribute
the difference to an object symbol; use `llvm-nm`, `otool`, or `lldb` after the
byte offset narrows the search.

## Declaration-Order Independence

A function body's facts and diagnostics must not depend on which other
bodies were checked first, except where the spec orders them (D43: a
return type inferred from a body declared later is not known at an
earlier call). `--sema-body-order-reverse` (or
`WITH_SEMA_BODY_ORDER=reverse`) checks top-level bodies last to first;
comparing a program's output with and without it shows a dependence:

```sh
with check file.w
with check --sema-body-order-reverse file.w
```

`with build :sema-order-check` runs the comparison over every
`test/compile_errors` fixture (tools/sema_order_check.w) and fails on a
difference outside `test/sema_order_allowlist.txt` (#1941).

## Debug Allocator

The native debug allocator remains the first tool for drop, lifetime,
double-free, use-after-free, and leak bugs:

```sh
with run --debug-alloc repro.w
with run --debug-alloc --debug-alloc-filter=non-root repro.w
WITH_DEBUG_ALLOC=1 ./bin                          # any binary
WITH_DEBUG_ALLOC=1 WITH_ALLOC_NO_REUSE=1 ./bin    # never reuse a freed address
```

The report names the block (address, size), the drop-origin tag of the
first free, and whether the second was tagged. `WITH_ALLOC_NO_REUSE=1`
distinguishes a genuine double free (still reported) from a stale pointer
into reused memory or an uninitialized value that happened to hold a live
address (report disappears). Without `WITH_DEBUG_ALLOC` the production
allocator still refuses a double free, as `panic: invalid free: pointer is
not an allocated payload start` with slab forensics, but names no origin.

Then trap the address, under lldb so it is the same from run to run (see
route step 5):

```sh
lldb --batch -o "settings set target.env-vars WITH_DEBUG_ALLOC_TRAP_FREE=<addr>" -o run -- ./bin
    # every alloc/free of it, with drop origins
lldb --batch -o "settings set target.env-vars WITH_DEBUG_ALLOC_TRAP_FREE=<addr> WITH_DEBUG_ALLOC_TRAP_FREE_HIT=<n>" \
    -o "breakpoint set --name with_panic_core" -o run -o "bt 12" -- ./bin
    # stop on the n-th free
```

The trap works without `WITH_DEBUG_ALLOC` (the allocation pattern under
test is unchanged), and values may be zero-padded so the environment block
keeps the same length across learn/trap runs (set the trap variables with
dummy values on the learn run, and keep every argument the same length —
see the native Windows recipe). The plain report does not record the first
free's site by itself yet (#1014). The ledger holds 4M slots; if it still
prints `ledger full, tracking truncated`, the double-free verdict for that
run is void — do not read a silent run as clean. (The ownership range
tables the invalid-free check reads are growable, so that check never
stands down.)

Leak filters:

- `all` shows every live allocation.
- `non-root` suppresses allocations marked as process-lifetime roots.
- `roots` shows only marked roots.

Runtime code can mark an allocation as an intentional root with
`with_debug_alloc_mark_root(ptr, reason_ptr, reason_len)`. Debug-allocator
fixtures can set `//! debug-alloc-filter: non-root` to assert the non-root leak
view instead of raw process-lifetime noise.

The tools around the allocator:

- `tools/debug_drop.w` drives it: `debug_drop run <with> <repro.w>` prints
  the verdict lines; `debug_drop check <with> <fixture.w>…` asserts each
  fixture's `//! expect-debug-alloc:` and `//! expect-stdout:` lines (the
  `:debug-alloc-tests` lane). Build it with
  `out/release/bin/with build tools/debug_drop.w -o out/debug-alloc-tests/debug_drop`.
- `tools/debug_drop_sites.lldb` resolves the sites: breakpoints on the trap
  checks (`dbg_trap_free_check`, `dbg_trap_alloc_check`) and on the
  double-free reporter, each with a backtrace, used with
  `WITH_DEBUG_ALLOC_TRAP_FREE=<addr>`. It finishes in seconds. (Its first
  version broke on every alloc and free and never finished; that version is
  gone, the file is not.)
- `tools/debug_drop_fields.lldb` breaks on the struct field-drop recursion
  and both drop paths with hit counts while the compiler *builds* a leaky
  repro (#606, an inline-drop field skipped).

The allocator's own switches, all read by the runtime of the program under
test (details in `debug-allocator.md`):

| Switch | What it does |
|---|---|
| `WITH_DEBUG_ALLOC=1` | the ledger: double free, invalid free, leaks at exit |
| `WITH_DEBUG_ALLOC_FILTER=all\|non-root\|roots` | which leaks the report lists |
| `WITH_DEBUG_ALLOC_SCRIBBLE=1` | poison freed payloads: a use-after-free crashes at the read (off by default: it turns a double drop into a crash before the ledger reports it) |
| `WITH_DEBUG_ALLOC_TRACE=1` | every allocation request, freed or not (`with run --trace-alloc` sets it for the child) |
| `WITH_ALLOC_NO_REUSE=1` | never hand out a freed address again |
| `WITH_ALLOC_ZERO_CLASS=1` | zero a recycled block's whole size class: a failure that vanishes here but not under no-reuse read a block's stale tail |
| `WITH_ALLOC_SYSTEM=1` | allocate through the system malloc, so tools that walk malloc zones (`leaks`, `MallocScribble`) see the heap; the payload-start check stands down |
| `WITH_DEBUG_ALLOC_TRAP_FREE=<addr>` | print every alloc and free of one payload address, with drop origins |
| `WITH_DEBUG_ALLOC_TRAP_FREE_HIT=<n>` / `WITH_DEBUG_ALLOC_TRAP_ALLOC_HIT=<n>` | panic on the n-th free / alloc of that address |
| `WITH_MEMORY_LIMIT_BYTES=<n>` | a committed-memory ceiling: a runaway allocation fails loudly |

## Trace and Dump Switches

The compiler's own traces, by layer. Each prints to stderr and changes
nothing it observes. A trace is a characterization, not proof (AGENTS.md):
use one to pick the breakpoint, then confirm in lldb or with a validator.

CLI dumps (`with check <file> <flag>`):

| Flag | Prints |
|---|---|
| `--dump-tokens`, `--dump-ast`, `--dump-resolved`, `--dump-typed` | the lexer's tokens, the AST, resolution, and Sema's types per node |
| `WITH_DEBUG_PERMUTE_TAGS=1` | compiler | plain enums get reversed tags, meaning unchanged: any behavior change is code that assumed a tag (route: a wrong variant) |
| `WITH_TRACE_VARIANT_FALLBACK=1` | compiler | each variant lookup MirLower answered by name in a type that does not declare the variant |
| `--dump-mir`, `--dump-async-mir` | the lowered MIR bodies (synchronous, and after the async transform); every dump and trace flag reads `--bundle-corpus <corpus>` as `check` does, so a corpus module dumps from its source rather than vanishing behind its embedded interface; also when the typed validator refused one (`internal compiler error: invalid MIR before codegen … in \`Type.fn\``): the ICE names the body, and `--dump-mir` / `--explain-mir-origin '<fn>:_N'` read the invalid statement |
| `--dump-place-map`, `--dump-drop-state`, `--dump-drop-plan`, `--dump-abi` | see the drop-state view and `--dump-abi` above |
| `--trace-place`, `--explain-mir-origin`, `--trace-ownership`, `--trace-cleanup-edge` | one place's history, where a MIR local came from, its ownership states, one CFG edge |
| `--validate-ownership`, `--validate-all` | the MIR validators |
| `--dump-project-info` | the project the compilation resolved for the file |
| `--sema-body-order-reverse` | check bodies last to first (see Declaration-Order Independence) |

`with build --explain <target>` prints a build target as the graph holds
it: its kind, entry, output, dependencies and inputs. `with uat --keep` keeps an acceptance scenario's work directory.

Environment switches (set on the compiler's run unless noted):

| Switch | Layer | Prints |
|---|---|---|
| `WITH_PROFILE=1` | frontend, Sema | one `[profile]` line per phase with its time |
| `WITH_DEBUG_STAGE1_TRACE=1` | Sema | each unknown type name with what lookup saw |
| `WITH_DEBUG_IMPORTS=1` | frontend | every module file the loader registers, the key it dedups on and the identity a std module is one source under (two files under one identity is the refused "loaded from two files" case) |
| `WITH_TRACE_INST=1` | Sema | every generic instance added, and the eager pass's preregistration |
| `WITH_DEBUG_BORROWS=1` | Sema | each view binding's dependencies and the borrow table at every read and mutation check |
| `WITH_DEBUG_MOVE=1` | Sema | move state per binding (`[state]`) and non-Copy classifications |
| `WITH_D32_DEBUG=1` | Sema | the D32 implicit-field-move arm and the field type it saw |
| `WITH_DEBUG_DEREF=1` | Sema | the auto-deref steps recorded for an expression |
| `WITH_DEBUG_SUBST=1` | Sema | value-ref ABI decisions per parameter of a specialization |
| `WITH_DEBUG_BOXSYM=1` | Sema | whether a type symbol is `std.box`'s `Box`, and why |
| `WITH_SEMA_BODY_ORDER=reverse` | Sema | same as `--sema-body-order-reverse` |
| `WITH_TRACE_COMPTIME=1`, `WITH_TRACE_TLL=1` | comptime | method calls the evaluator carries back to a receiver; top-level lets it evaluates |
| `WITH_DUMP_FACADE=1` | frontend | each rendered `c facade` text, as the parser sees it (`<facade NAME>:line:col` points into it) |
| `WITH_TRACE_SCOPES=1`, `WITH_TRACE_RESETS=1` | MIR | drop-scope pushes and pops; every move operand created |
| `WITH_DEBUG_BOXWALK=1` | MIR | the auto-deref walk through boxes to a field |
| `WITH_DUMP_PAIR_FLOW=1` | MIR | the foreign callback-pair analysis and its findings |
| `WITH_MIR_AUDIT=1` | MIR, codegen | `[mir-lower-fail] kind=<node kind> fn=… span=…`: which node a failed lowering could not lower |
| `WITH_DEBUG_MIR_CODEGEN=1` | codegen | which body codegen takes from MIR, and each function symbol it resolves |
| `WITH_DUMP_INIT_MIR=1` | codegen | codegen-synthesized MIR bodies (a module with a global initializer: `__with_init_const_<name>`), which `--dump-mir` never sees; nothing for a module without one |
| `WITH_DUMP_MIR_CLEANUP_FN=<fn>\|*` | codegen | one function's LLVM IR before and after codegen's per-function cleanup (`===== PRE MIR CLEANUP f =====`, `POST`) |
| `WITH_DUMP_LLIR_PRE=1`, `WITH_DUMP_LLIR_POST=1`, `WITH_DUMP_LLIR_ON_INVALID=1`, `WITH_KEEP_BITCODE=1` | codegen | the LLVM module (see the drop route above) |
| `WITH_DEBUG_CALL_COERCE=1` | codegen | a call argument whose value did not match the parameter type |
| `WITH_DEBUG_LOCAL_FLOW=1` | codegen | each local bound to its stack slot |
| `WITH_DEBUG_METHOD_DISPATCH=1` | codegen | the receiver of a method call that failed to dispatch |
| `WITH_DEBUG_DTM=1` | codegen | each trait-method thunk as it is built |
| `WITH_DEBUG_TYPE_LAYOUT=1` | codegen | each struct field's resolved type as the layout is built |
| `WITH_DEBUG_POOL_FLOW=1` | codegen | the AST and symbol pool sizes handed to the backend |
| `WITH_TRACE_CMP=1` | codegen | each integer `==`/`!=` with its operand types and signedness |
| `WITH_TRACE_VECDROP=1` | codegen | each Vec drop and whether its elements need dropping |
| `WITH_TRACE_CARGS=1` | C backend | each extern call's signature and argument count |
| `WITH_ANALYZE_TRACE=pool-views` | analyze | `audit:pool-views`'s per-body walk |
| `WITH_TRACE_GRAPH=1` | build | the build graph as it materializes |
| `WITH_MIGRATE_TRACE_PORT=1`, `WITH_MIGRATE_RAW_STATS=1`, `WITH_MIGRATE_TRACE_LIBC_CONSTANTS=1` | migrator | each ported declaration; raw-pointer statistics; each libc constant candidate and its value |

Codegen that meets MIR it cannot lower (an id out of range, a place with no
address, a kind with no lowering, a noalias walk past a function's
parameters) stops with ``error: code generation failed: BUG: <what> in
`<function>` ``; there is no switch to turn it on (#2199 retired
`WITH_DEBUG_FALLBACK`, which decided whether the `undef` it emitted was
reported at all). The named function is where to start `--dump-mir`.

The same holds for the typed MIR validator's ICE (`invalid MIR before
codegen: … in \`CiGotoCfgContext.emit_switch_dispatch\``): the invalid
module is kept for the dumps, so `--dump-mir` shows the refused statement
(`_14 = copy _6.state`) and `--explain-mir-origin` its locals. A compiler
that lowers its own source wrongly shows it as `check src/main.w` failing
under stage1 while the build succeeded: the release binary is then built
from invalid MIR, so reproduce with stage1, not the release binary.

## Verification Targets

```sh
with build :deep-debug-tool-tests
with build :debug-alloc-tests
with build :drop-audit
with build :move-audit
with build :sema-order-check
with build :fixpoint-diff
```

The full `with build :test` target includes `:deep-debug-tool-tests`; run the
focused targets while developing changes to these tools.
