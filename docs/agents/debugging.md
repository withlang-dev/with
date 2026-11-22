# Debugging: principles, routes and tools

Moved verbatim from AGENTS.md (#2374). Nothing here was reworded.

## Core Principles

**We own every bug.** Nothing is "pre-existing." If a bug exists, we fix it —
never defer, never work around.

**Root cause, always.** Run a 5 Whys: trace the failure to its deepest credible
cause and fix that, not the symptom.

**Build is verification, not experimentation.** A build takes 5 minutes. Before
`with build`, state the question you're answering and what each outcome tells
you. If `grep`, `nm`, `otool`, `lldb`, or reading code can answer it, do that.

**Use the debugger.** One `lldb` breakpoint answers in seconds what
print-and-rebuild takes minutes to. The installed `with` has full debug info:
`~/.local/bin/with.dSYM` beside it (`:install-user` installs stage2's dSYM,
the release's; released assets stay stripped). Any question about what the
installed compiler does — a wrong diagnostic, an ICE, a hang, a bad value in
Sema or MIR — starts with `lldb` on `~/.local/bin/with`, before a trace print
or a rebuild (recipes: Stage Debugging > LLDB). For source you changed, debug
`out/bootstrap/bin/with-stage1` (after `with build :dev`; it has a `.dSYM`
too). A program any compiler builds carries debug info for its own code and
the runtime.

**"Root cause" means the exact line** — the exact function, branch, and
condition producing the wrong state, observed in `lldb` or the debug allocator.
Output tables, run counts, raw `--dump-mir`/`--dump-drop-state` greps, and trace
prints are hypotheses, not proof; never propose a fix or deferral from a
characterization alone. Deferring is valid only after locating the bug at the
instruction level and showing the fix needs foundation work you can point to.

**Every bug has a route, and you state it.** `docs/spec/toolchain/deep-debugging-tools.md`
orders the tools by bug class; every recipe in it was run as written
(2026-10-05). Open it at the start of a hunt and follow the route's recipes as
printed; improvising flags is how a hunt stalls (an unknown flag is refused,
#2198). Before the first edit, name the route and run its first steps:
- drop, free, leak, use-after-free: the debug allocator, `WITH_ALLOC_NO_REUSE`,
  the address trap (`WITH_DEBUG_ALLOC_TRAP_FREE`, under lldb: outside it the
  address changes every run), and the runner's own binary — never `grep` or a
  trace print;
- a wrong variant (wrong arm, `unwrap` of a `Some` panics, `?` takes the error):
  `WITH_DEBUG_PERMUTE_TAGS=1 with-stage1 test test/behavior` and
  `WITH_TRACE_VARIANT_FALLBACK=1`; corpora run under
  `out/bootstrap/bin/with-stage1 test <dirs>`;
- a wrong view origin: `with analyze repro.with 'explain:origin:<fn>[:<binding>]'`
  (works on a failing program), then `WITH_DEBUG_BORROWS=1`;
- a generic-instance `BUG:`: `WITH_TRACE_INST=1`;
- codegen reading a value as the wrong type (wrong formatter, comparison, ABI):
  `with analyze repro.with audit:resolution`, whose operand-type check names the
  expression whose MIR type Sema did not give it.
A fix commit cites the tool output that proves the exact line: the allocator
report and backtrace, the `matrix` row, the validator error, the IR of the
block.

**A tool that stayed silent is a bug.** If a validator said ok, a dump said
skip, an audit passed, or a reducer converged on noise while the bug existed,
the tool is wrong and is fixed or filed in the same batch as the bug
(`validate-all: ok` over a garbage drop is the model: the drop-state driver
joined only lower-numbered predecessors).

**Three-action trip-wire.** If your last three actions were edit, compile,
read output and you cannot name the exact wrong line, stop and switch to the
route's next tool: a breakpoint, an allocator verdict, `with reduce`,
`--trace-place`, `--explain-mir-origin`, `--trace-ownership`,
`--dump-drop-plan`, `--trace-cleanup-edge`, `--validate-all`, `nm`/`otool`,
or a smaller checked repro. Do not start a fourth.

**Tools are products.** When a hunt needs a capability that does not exist
(`--keep-binary`, a first-free site in the ledger, a test-mode reducer), file
it during the hunt and prefer building it over a workaround when the workaround
is a race or a manual lldb session. Before building, grep the runtime and the
doc for the flag that already exists — the address trap sat unmentioned in
`rt_core.with` for a month.

**One owner per fact (D65).** Sema decides *what* (declaration, type,
place/value/view category, origin, effect, capture semantics, call target,
acceptance); MIR decides *where and when* (CFG, storage, path-sensitive move
state, drop points, cleanup edges); codegen decides *how* (layout, `PassMode`,
LLVM representation). A downstream stage may propagate, materialize and verify
a fact; it never reconstructs or overrides it from syntax or representation: no
LLVM-type → passing-mode inference, no MIR-local-lookup → name-meaning
inference, no AST-spelling → callee inference after Sema. MIR that finds Sema's
constraints unrealizable reports the contradiction; it never picks a different
meaning. Post-Sema invalid MIR is a compiler bug: its ICE names the body, and
`--dump-mir` / `--explain-mir-origin` read the refused statement. When you fix
a bug, move its answer to the owner — never add a second derivation. `with
analyze … audit:resolution` (#1647) is the mechanical check; the smell test: if
deleting a downstream heuristic could change which programs are accepted, the
boundary is wrong.

**Deep compiler bugs.** If the repro isn't minimal, run `with reduce` with the
failing command as the predicate. For MIR lowering, ownership and codegen bugs,
reach for the `with check` trace/dump flags (Stage Debugging) before trace
prints. For fixpoint failures, run `with build :fixpoint-diff` first.

**Memory bugs.** Any drop/lifetime/double-free/use-after-free/leak bug starts
with the native debug allocator: `--debug-alloc` or `WITH_DEBUG_ALLOC=1`
(`docs/spec/toolchain/debug-allocator.md`), then `tools/debug_drop.with` /
`tools/debug_drop*.lldb` to turn its verdict into alloc/free sites, the
`--dump-drop-state`/`--trace-ownership`/`--dump-drop-plan` dumps for MIR
ownership state, then `lldb` on the branch that emitted the bad drop. Allocator
= which memory was mishandled; dumps = which places the compiler thinks are
live and scheduled; debugger = why codegen emitted it.


## Stage Debugging

`with` below is the installed compiler; it runs every dump, trace, `analyze`,
`reduce` and allocator recipe. For source you changed, use
`out/bootstrap/bin/with-stage1` (`with build :dev`); lldb works on either.
`out/stage/bin/with-stage2` exists only after a full build. The full catalog:
`docs/spec/toolchain/deep-debugging-tools.md`.

### Quick repro
```
out/bootstrap/bin/with-stage1 check src/main.with
```

### Deep compiler tools (before edit/compile/trace loops)
```
with reduce repro.with --contains "diagnostic" -- with check {file}
with check repro.with --trace-place main:_1
with check repro.with --explain-mir-origin main:_1
with check repro.with --trace-ownership main:_1
with check repro.with --dump-drop-plan | --dump-place-map | --dump-abi | --dump-drop-state
with check repro.with --trace-cleanup-edge 'main:bb0->bb1'
with check repro.with --validate-all | --validate-ownership
with build :fixpoint-diff
```

### Integrated compiler analysis (`with analyze`)

Use this **before** standalone scanners, debug prints or a rebuild when a
problem crosses AST/Sema/MIR/ABI/codegen. One compilation joins facts from the
live `Sema`, `MirBody`, diagnostics and real LLVM codegen branches, and audits
its own marshalling coverage — an uninstrumented call path is a failure, not a
blind spot.

```sh
with analyze repro.with audit:all | audit:storage | summary | contract | move-sites
with analyze repro.with 'matrix:name~function_name'
with analyze repro.with 'select:stage=sema,kind=parameter,name~function_name'
with analyze repro.with 'explain:call:function_name' | 'explain:origin:function_name' | 'explain:effect:Type.method:self'
with analyze repro.with 'select:kind=operator,detail~fn:function_name'
with analyze repro.with 'path:call:caller:callee' | 'closure:call:root_function'
with analyze repro.with 'lldb:kind=call,name~function_name'
```

- `facts` / `snapshot`: stable TSV facts for fixtures or a text diff — all AST
  function declarations (incl. generic/uninstantiated methods), finalized
  signatures/effects/receiver modes, specializations, MIR bodies/locals/places
  /calls, diagnostic provenance, LLVM parameter shapes, caller marshalling,
  callee binding, source identity with exact byte `start`/`end`; MIR
  call-argument facts join lowered operands to Sema's canonical AST nodes.
- `select:` / `summary[:]` / `matrix:`: comma-separated `field=value`,
  `field!=value`, `field~substring` predicates (`with analyze file.with help`).
- `contract` / `audit:contract`: the modeled foreign contract of every `c
  facade` (ruling §63) with provenance and the suspicious-configuration audit.
- `audit:resolution`: D65 — every MIR callee and argument count agrees with
  Sema's resolution (#1635; phase 1 of
  `docs/spec/implementation/mir-sema-hardening.md`), and every expression's MIR
  operand has the type Sema gave it (the D97 class).
- `audit:calls|effects|storage|methods|mir|returns|receivers|receiver-surface|phase|pool-views|contract|resolution|codegen|trait-tables|all`:
  hard invariants (`all` covers typed/ownership validators, receiver contracts,
  fixed-point effects, freeze/eager-cache/specialization, frozen-phase
  re-entry, LLVM declaration ABI, marshalling, aliasing, instrumentation
  coverage, AST-indexed storage bounds, trait-table/vtable agreement).
  `audit:storage` permanently checks the resolved-call table that once
  overflowed past 32767/65535 node IDs.
- `path:call` / `closure:call` operate on the live MIR call graph; use them
  instead of source-text reconstruction. `lldb:<query>` emits breakpoints from
  matching facts and refuses to invent one.

Also a reducer predicate: `with reduce repro.with --exit-code nonzero -- with
analyze {file} audit:all`. Do not start a full build to test an ABI/ownership
hypothesis: first require the focused repro's `audit:all` to pass and inspect
its `matrix`; a build is the final repo-wide verification. There are no
source-scanner semantic fallbacks — if analysis can't reach the needed phase,
reduce the repro or attach LLDB. Source rewrite tools may use the Lexer to
apply byte edits, but selection and contracts come from `compiler_analyze_file`
facts: `tools/annotate_receivers.with`, `tools/migrate_receivers.with`, `with
migrate-receivers` (built in, `src/ReceiverMigration.with`; `--report`, `--list`,
`--apply`), `tools/migrate_method_arg_moves.with`. The removed
receiver/frozen/closure/diagnostic-map tools must not be recreated.

`--dump-abi` prints, per signature, each parameter's ownership/ABI
classification — effect flags, `value_ref_abi`, the physical passing verdict.
It answers "is this borrow or owned parameter lowered consistently at caller
and callee?" — dump it, don't infer it. A legacy `SHARE-PLACE` label is
implementation terminology for `IndirectPlace`, not permission to reinterpret
a consuming `T` as a borrow.

For drop-exactly-once across (value shape × control flow × ownership op ×
receiver mode), run `with build :drop-audit` (`tools/drop_audit.with`; candidate =
the fresh release binary, baseline = the verified seed) before and after ANY
change to drop scheduling, ownership or receiver lowering. One bad cell means
the whole region is untested; a cell is red only when the verdicts DIFFER
(#693's enum cells and #608's POD-leak pins read as `same`).

### LLDB (preferred)
The compiler's objects name their sources under `/with-src` (D50), so map it
to a checkout of the commit the binary was built from: for
`~/.local/bin/with`, the tree you reseeded from (`:install-user` prints its
green commit; `~/with` once fast-forwarded). A different checkout lists the
wrong lines.
```
lldb -o "settings set target.source-map /with-src $PWD" -- out/bootstrap/bin/with-stage1 check src/main.with
(lldb) run
(lldb) bt all
```
The installed compiler, scripted (verified 2026-10-19). Breakpoints take
With's dotted names (`Type.method`, or a free function's name);
`frame variable` shows a frame's locals and `source list` its code:
```
lldb --batch -o "settings set target.source-map /with-src $HOME/with" \
  -o "b Sema.source_path_text" -o run -o "bt 8" -o "frame variable" -o kill \
  -- ~/.local/bin/with build repro.with -o repro
lldb --batch -o "image lookup -n Sema.source_path_text -v" -- ~/.local/bin/with   # where a function lives
llvm-dwarfdump --uuid ~/.local/bin/with ~/.local/bin/with.dSYM   # the dSYM is this binary's (UUIDs equal)
```
Everything is built at `-O1`, so some locals read `<variable not
available>`; step to where the value is used, or read the argument in the
caller's frame (`frame select 1`). lldb does not expand `~` in a
source-map path: spell `$HOME`. `llvm-dwarfdump` is the SDK's
(`.deps/llvm-<ver>-<host>/bin`). A hang: `lldb -p <pid>` then `bt all`.

### Native Debug Allocator
```
with run --debug-alloc repro.with
with run --debug-alloc --debug-alloc-filter=non-root repro.with
with check repro.with --dump-drop-state | --dump-drop-plan | --trace-ownership main:_1
with build :debug-alloc-tests
./out/release/bin/with build tools/debug_drop.with -o out/debug-alloc-tests/debug_drop
out/debug-alloc-tests/debug_drop run ./out/release/bin/with repro.with
lldb --batch -o "settings set target.env-vars WITH_DEBUG_ALLOC=1" -o run -- ./bin   # learn the addr (stable only under lldb)
lldb --batch -s tools/debug_drop_sites.lldb \
  -o "settings set target.env-vars WITH_DEBUG_ALLOC=1 WITH_DEBUG_ALLOC_TRAP_FREE=<addr>" \
  -o run -o "bt 24" -o quit -- ./bin                            # backtraces at each trap hit and the double-free reporter
```

### Heap corruption and leaks
The malloc tools see only malloc zones; With's allocator is its own, so without
`WITH_ALLOC_SYSTEM=1` they report a clean heap whatever happened:
```
WITH_ALLOC_SYSTEM=1 MallocScribble=1 MallocGuardEdges=1 out/bootstrap/bin/with-stage1 check src/main.with
WITH_ALLOC_SYSTEM=1 leaks --atExit -- out/bootstrap/bin/with-stage1 check src/main.with
```
First choice for leaks is the debug allocator (`WITH_DEBUG_ALLOC=1`, it names
the block and origin). If stacks are nonsense, suspect seed corruption and
replace the seed with a known-good binary.


## AST Node Layouts

```
NK_LET_DECL (4)       d0=name  d1=value  d2=flags (bit0=mut, bit1=pub)
NK_LET_BINDING (33)   d0=name  d1=value  d2=flags (bit0=mut)
NK_IF_EXPR (31)       d0=cond  d1=then   d2=else
NK_FOR (37)           d0=binding d1=iterable d2=body  (body is d2, not d1)
NK_WHILE (35)         d0=cond  d1=body   d2=label
NK_MATCH (40)         d0=subject d1=extra_start d2=arm_count
NK_MATCH_ARM (110)    d0=pattern d1=body  d2=guard
NK_BLOCK (30)         d0=extra_start d1=stmt_count d2=tail
NK_RETURN (32)        d0=value
NK_STRUCT_LIT (43)    d0=name  d1=extra_start d2=field_count
```

There is **no `NK_VAR_DECL`**: mutable variables use the mut flag on
`NK_LET_DECL`.
