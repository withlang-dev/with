# Deep Debugging Tools

Status: implemented. Audience: compiler/runtime contributors.

These tools exist to stop edit/compile/trace loops. This page is ordered by
the kind of bug you are holding, not by tool: each route says which tool
proves what, and what it cannot prove. The catalog of every command follows
the routes.

## Routes by bug class

### A drop, double free, invalid free, use-after-free, or leak

1. **Native debug allocator first.** `with run --debug-alloc repro.w` (or
   `WITH_DEBUG_ALLOC=1` on any binary). It names the block, its size, and
   the drop-origin tag of the first free (`first_drop=drop#struct
   __drop_struct_16` is the str drop glue; `<untagged>` is a raw `rt_free`
   caller such as a collection's own free). The tag is the first real clue:
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
   allocator's own trap, no debugger needed:
   `WITH_DEBUG_ALLOC_TRAP_FREE=<decimal addr> ./bin` prints every alloc and
   free of that payload address with its drop origin (it works without
   `WITH_DEBUG_ALLOC`, so the heap layout is unchanged), and
   `WITH_DEBUG_ALLOC_TRAP_FREE_HIT=<n>` panics on the n-th free so lldb
   stops on that call chain. `tools/debug_drop_sites.lldb` puts backtrace
   breakpoints on those trap checks and on the double-free reporter. A
   hardware watchpoint on the payload (`watchpoint set expression -w write
   -s 8 -- <addr>`) is the other fast tool; lldb runs with ASLR off, so an
   address from one run is stable in the next. #1014 asks for the first
   free's site to be recorded by default so the plain report names both.
6. **Read the function's IR or disassembly at the join block.** `--emit-llvm`
   on the fixture, or `otool -tV bin | awk '/^_fn:/,/^_next:/'`. Two
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

### The compiler crashes or aborts on an input

An internal `BUG:` line, a SIGTRAP (exit 133), or exit 134 is a compiler
defect regardless of what the input did. Reduce it (`with reduce --exit-code
nonzero -- with check {file}`), then lldb on the compiler: LLVM frames in the
backtrace mean invalid IR construction, pure With frames mean a With-side
abort (#653's `switch undef` class). File it with the reduced input; `map[k]`
on a HashMap aborting in `validate_generic_call_contracts` (#1012) is the
current example.

## Integrated Compiler Analysis

`with analyze` is the primary cross-layer debugging surface. Unlike a standalone
scanner, it reads the compiler's live AST declarations, finalized Sema signatures
and effects, concrete specializations, `MirBody` tables, diagnostic provenance,
and the actual LLVM marshalling/prologue branches used for production codegen.

```sh
./out/stage/bin/with-stage2 analyze repro.w audit:all
./out/stage/bin/with-stage2 analyze repro.w audit:storage
./out/stage/bin/with-stage2 analyze repro.w 'matrix:name~target_fn'
./out/stage/bin/with-stage2 analyze repro.w 'path:call:main:target_fn'
./out/stage/bin/with-stage2 analyze repro.w 'closure:call:main'
./out/stage/bin/with-stage2 analyze repro.w 'lldb:kind=call,name~target_fn'
```

`audit:all` is the proof gate before an expensive build. It validates MIR shape,
types, and ownership; receiver declaration coverage and finalized contracts;
effect-flow fixed point; frozen caches and specialization bodies; frozen-phase
mutable-Sema calls; LLVM declaration pass modes; caller argument marshalling;
callee place aliasing; and the analyzer's own coverage of reachable ordinary
calls. It also runs `audit:storage`, which checks AST-indexed table bounds,
parallel start/count storage, canonical argument-node validity, and non-colliding
64-bit keys across the former 16-bit AST-node boundary. The command exits nonzero
on any violation.

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

The live MIR graph backs `path:call:<from>:<to>` and
`closure:call:<root>`. Prefer these over parsing source text. There are no legacy
semantic scanner fallbacks. If compilation stops before the needed snapshot, use
`after-mir:<request>` when available, reduce the input, or attach LLDB to the exact
compiler branch that stopped it.

Use an analysis audit directly as a reduction predicate:

```sh
./out/stage/bin/with-stage2 reduce repro.w --exit-code nonzero -- \
  ./out/stage/bin/with-stage2 analyze {file} audit:all
```

## Ownership Transfer Classification

`analyze <file> move-sites` classifies every call site where a plain non-Copy
argument binds an OWNED (consume/escape_value) parameter — the sites the
"takes ownership" diagnostic reports. It is a semantic-snapshot request: it
runs from the live Sema state even when the check fails, which is its primary
use (partitioning an error worklist, e.g. the #691 flip's, before deciding
which sites get a `move` keyword and which need design work).

```sh
./out/stage/bin/with-stage2 analyze src/main.w move-sites
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
./out/stage/bin/with-stage2 analyze src/main.w seam-sites
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
batch (docs/handoff.md, D22 Stage 6 era, §3 roots 15, 18, 19) matches
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
./out/stage/bin/with-stage2 analyze src/main.w 'explain:effect:Zcu.clear_stage_outputs:self'
```

Provenance is recorded at first-set during body checking and the effect
fixpoint; the chain names each hop's source location. Use this instead of
neutralize-bisection when a receiver demands a stronger mode than expected —
the 57-method escalation cascade in #691 was exactly one misattributed seed
plus transitive root edges, a one-query answer with provenance and an
afternoon of bisection without it. Also a semantic-snapshot request: works
on erroring inputs.

## Repro Reduction

`with reduce` minimizes a single-file repro by deleting source lines while a
predicate still holds.

```sh
./out/stage/bin/with-stage2 reduce repro.w \
    --contains "undefined variable" \
    -- ./out/stage/bin/with-stage2 check {file}
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
./out/stage/bin/with-stage2 reduce fixture.w --test test_needs_two_lines
```

The source path must immediately follow `reduce`. Use `{file}` in the predicate
argv for the candidate path; without it, the candidate path is appended.

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
./out/stage/bin/with-stage2 check repro.w --dump-drop-state
./out/stage/bin/with-stage2 check repro.w --dump-drop-plan
./out/stage/bin/with-stage2 check repro.w --trace-ownership main:_1
./out/stage/bin/with-stage2 check repro.w --trace-cleanup-edge 'main:bb0->bb1'
./out/stage/bin/with-stage2 check repro.w --validate-ownership
./out/stage/bin/with-stage2 check repro.w --validate-all
```

- `--dump-drop-state` prints every block's in/out state.
- `--dump-drop-plan` prints each MIR drop site with the state before it and
  an `action` (`drop`, `drop-conditional`, `skip`). **Read `action` as the
  analysis's verdict, not as what codegen does**: drop flags are retired and
  codegen emits every `drop` statement, so a `skip` on an `Uninit` place is
  a drop of garbage at runtime. Making that a hard `check` error rather than
  an opt-in validator is the intended end state.
- `--trace-ownership <fn:place>` prints the before/after state at every
  statement or terminator that touches the place (empty place: all places).
- `--trace-cleanup-edge <fn:from->to>` prints the state across one CFG edge.
  Quote the argument; `>` is a shell redirection.
- `--validate-ownership` rejects a drop of a `MaybeGarbage` place and
  reports the first error; `--validate-all` runs every MIR validator.
- `--dump-place-map` lists each MIR place with base local, type id, and
  projection list, for when `_N.fK` does not mean what the source seemed
  to say. `--dump-drop-flags` reports runtime drop flags; today it prints
  `<no drop flags>` for every module.

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
- `tools/relocate_methods.w` relocates only Sema-identified top-level instance
  methods and verifies one semantic fact per structural rewrite.
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
  `gen_module`. A bare-name breakpoint reports `no locations (pending)` and
  the run proceeds uninstrumented.
- Function-body breakpoints on our `-O1` binaries can resolve yet never fire
  (line-table skew); LLVM C API symbols (`LLVMAddFunction`,
  `LLVMTargetMachineEmitToFile`, `LLVMBuildAlloca`) are reliable anchors with
  ABI-stable argument registers.
- Our DWARF has no variable info (`frame variable` fails with "no variable
  information"); read entry-register args at non-inlined symbol entries, and
  treat `[inlined]` frame line attributions as unreliable. Fixing variable
  info would strengthen every recipe on this page more than a new query
  verb would.
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
./out/stage/bin/with-stage2 fixpoint-diff \
    out/stage/bin/with-stage2-fixpoint.o \
    out/stage/bin/with-stage3-fixpoint.o
```

The report names file sizes, whether the size differs, the first differing byte
offset, and a small byte window around the mismatch. It does not yet attribute
the difference to an object symbol; use `llvm-nm`, `otool`, or `lldb` after the
byte offset narrows the search.

## Debug Allocator

The native debug allocator remains the first tool for drop, lifetime,
double-free, use-after-free, and leak bugs:

```sh
./out/stage/bin/with-stage2 run --debug-alloc repro.w
./out/stage/bin/with-stage2 run --debug-alloc --debug-alloc-filter=non-root repro.w
WITH_DEBUG_ALLOC=1 ./bin                 # any binary
WITH_ALLOC_NO_REUSE=1 ./bin              # never reuse a freed address
```

The report names the block (address, size), the drop-origin tag of the
first free, and whether the second was tagged. `WITH_ALLOC_NO_REUSE=1`
distinguishes a genuine double free (still reported) from a stale pointer
into reused memory or an uninitialized value that happened to hold a live
address (report disappears). Then trap the address:

```sh
WITH_DEBUG_ALLOC_TRAP_FREE=<decimal payload addr> ./bin        # print every alloc/free of it, with drop origins
WITH_DEBUG_ALLOC_TRAP_FREE_HIT=<n> WITH_DEBUG_ALLOC_TRAP_FREE=<addr> ./bin   # panic on the n-th free
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

`tools/debug_drop_sites.lldb` (breakpoints on every alloc/free with a
backtrace) is retired in favor of the reporter breakpoint and the
watchpoint: it did not finish within five minutes on a four-test fixture.

## Verification Targets

```sh
with build :deep-debug-tool-tests
with build :debug-alloc-tests
with build :fixpoint-diff
```

The full `with build :test` target includes `:deep-debug-tool-tests`; run the
focused targets while developing changes to these tools.
