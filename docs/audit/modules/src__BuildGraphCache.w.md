# Primary verification — `src/BuildGraphCache.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `40a22f64557e1d26ca424934aee0f8f18e4e34a599befbee26a3251897b6c246`  
Source examined: all 943 lines

## Scope examined

The complete module was read inline. It owns target-state path construction,
file and compiler fingerprints, graph-source and action-source hashes, test
success and per-file verdict records, target signature/input/output identity,
freshness validation, effect-ledger storage, and evaluated-build-graph
serialization.

The codebase-memory graph was queried first. Its `.w` extraction did not expose
these symbols, so Tilth was used to enumerate the production importers and call
sites. The complete source of `BuildGraphTests.w`, `BuildGraphDispatch.w`, and
`BuildGraphOps.w` was read. Relevant execution and representation paths in
`main.w`, `BuildGraphSupport.w`, `BuildGraphMaterialize.w`, `BuildGraphModel.w`,
`ComptimeEval.w`, and `lib/std/build.w` were traced to the exact values consumed
by the cache.

Direct production importers are:

- `src/main.w`, which loads the evaluated graph, asks the cache whether every
  cacheable target is fresh, executes stale targets, and records new state;
- `src/BuildGraphTests.w`, which consumes the per-file verdict API; and
- `tools/debug_sema_layout.w`, whose broad import set exists only to inspect
  compiler layout.

Applicable overview targets examined: 8–9, 12–14, 18–19, and 21–24. The module
does not itself decide MIR ownership, ABI, suspension, or drop behavior.

## Contract boundary

`docs/with-build.md:191-196` promises that build state lives below
`out/.build-state` and that a compiler-binary change makes compiled targets
stale. The repository's production rules require correct output, complete
input identity, loud failure instead of false success, and source/executable
evidence beyond a green build. The cache therefore has one correctness
contract: it may return `fresh` only when rerunning the target or graph
evaluation would observe the same inputs, configuration, tools, and output
paths, and every promised output still exists with the recorded contents.

## Artifact and optimization evidence

The primary agent ran:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

The command exited 0. The stage was `fresh`; its explicit source list included
`src/BuildGraphCache.w`, selected the seed compiler, and carried `-O1`.

All retained executable helpers and fixture programs were compiled or invoked
with the current stage1 compiler and `-O1`. No production file was changed and
no broad build, full test battery, fixpoint, packaging, or non-Linux run was
performed.

## Working controls

- The valid baseline in `docs/audit/probes/build_cache_graph_parser.w` was accepted
  before malformed variants were tried.
- `docs/audit/probes/build_cache_missing_action_output` declares an action output,
  returns success without creating it, and correctly exits nonzero with
  `did not produce declared output`. This reaches the guard at
  `main.w:1503-1510` and proves action execution does not silently accept a
  missing declared output when the action actually runs.
- `docs/audit/probes/build_cache_install_output` deleted an installed destination
  under a fixture-local `DESTDIR`; the next invocation reran the install and
  recreated the file. This is an over-invalidation control, not a cache hit.
- Every false-fresh probe was rerun after deleting only the relevant state file
  or evaluated-graph cache. Each then produced or detected the changed value,
  isolating cache reuse from the action, compiler, comparison, and filesystem
  operations themselves.

## BGC-001 — evaluated graph cache omits real graph dependencies and never validates recorded effects

Classification: **Confirmed false-fresh build-graph defect; partly covered by open #649**  
Severity: **Critical**  
Blast radius: every project whose `build.w` graph shape or generated-source
contents depend on imported build modules outside the hard-coded paths,
environment reads, ToolFs reads/listings, or process results  
Confidence: **Very high**

Four independent retained probes changed one graph-producing input between two
otherwise identical invocations:

1. `docs/audit/probes/build_cache_env_graph` reads
   `WITH_AUDIT_GRAPH_VARIANT` through `BuildCtx.env_input` and chooses target
   `app-A` or `app-B`. The first `A` invocation produced `app-A`; a second
   invocation with `B` still loaded `app-A`.
2. `docs/audit/probes/build_cache_toolfs_graph` reads `variant.txt` through
   `ctx.fs().read_text`. Changing `A` to `B` left `app-A`; deleting only
   `out/.build-state/build-graph.cache` produced `app-B`.
3. `docs/audit/probes/build_cache_process_graph` obtains the same byte through
   `ProcessRunner`. Changing the file left `app-A`; deleting only the graph
   cache produced `app-B`.
4. `docs/audit/probes/build_cache_import_graph` imports root-level `config.w` from
   `build.w`. Changing only that imported module left `app-A`; deleting only the
   graph cache produced `app-B`.

The exact source chain is:

1. `build_cache_hash_build_graph_sources`, `BuildGraphCache.w:366-370`, hashes
   only root `build.w`, recursive `.w` files under `build/`, and the disk
   `lib/std/build.w`. It does not receive the compilation's actual imported
   source closure.
2. `build_cache_graph_key`, lines 774-775, combines that approximation with the
   current compiler fingerprint, `with.toml`, target kind, and strict-effects
   flag. It contains no graph-evaluation input/effect manifest.
3. `load_build_graph_from_build_w`, `main.w:1523-1527`, returns the serialized
   graph immediately when that key matches, before build evaluation can repeat
   or validate an env, filesystem, or process observation.
4. Evaluation records environment and process effects
   (`ComptimeEval.w:2054-2060,2162-2172`), and
   `build_cache_record_build_effects`, `BuildGraphCache.w:713-721`, writes them
   to `build.w.effects`. No graph-cache read path reads or validates that file.
5. ToolFs graph reads at `ComptimeEval.w:5487-5609` return glob, existence,
   file contents, hashes, and listings without calling `record_effect`, so even
   a future validator has no complete record to check.

Five Whys:

1. The old graph is returned because its static key still matches.
2. The key still matches because it approximates source dependencies and has no
   dynamic-input identity.
3. Dynamic effects are written only as an informational ledger, not consumed as
   cache validity evidence.
4. ToolFs observations are not entered in that ledger at all.
5. A value computed by an effectful evaluation was persisted across invocations
   as though “serializable” also meant “pure.”

Proper repair boundary: establish one complete dependency/effect record for
graph evaluation. The preferred #921-shaped architecture is to cache the
compiled graph runner by its real source/compiler closure but execute it once
per top-level invocation, sharing the resulting graph only within that
invocation. If evaluated values remain persistent, the cache hit must first
validate every imported source, declared environment value, ToolFs observation,
process specification/result dependency, tool identity, manifest option, and
generated input. Missing, malformed, unresolvable, or untracked evidence must be
a cache miss. ToolFs reads need effect recording at the read boundary.

Issue relationship: open #649 explicitly requires declared environment reads
in graph construction and actions to invalidate the correct node; the env probe
shows its graph-construction acceptance claim is not currently true. Closed
#360 established the effect-ledger/tool-identity intent and is regressed at this
read boundary. Closed #683 introduced the serialized evaluated graph; #931's
reseed smoke test deliberately deletes it because reuse suppresses evaluation.
Open #921 is adjacent replacement architecture. No exact existing report was
found for imported non-`build/` modules, ToolFs reads, or process-derived graph
shape.

## BGC-002 — cache and executor disagree about the effective output set

Classification: **Confirmed false-success artifact defect; candidate unreported**  
Severity: **Critical**  
Blast radius: all executable, library, object, and archive targets using default
outputs or CLI `-o`; install targets using `$INSTALL_BINDIR`/`$INSTALL_LIBDIR`
are affected in the opposite, always-stale direction  
Confidence: **Very high**

`docs/audit/probes/build_cache_default_outputs` exhausts the four compiled,
cacheable public product kinds with implicit outputs. The first run created:

```text
out/bin/exe
out/lib/liblibrary.a
out/obj/object.o
out/lib/libarchive.a
```

After deleting exactly those artifacts, all four second invocations exited 0,
reported no target execution timing, and left all four files absent.

The pre-existing `docs/audit/probes/target_spec_cli_project` supplies the second
public path. After one successful build, changing only CLI `-o` returned success
from cache while the newly requested output did not exist.

The exact mismatch is:

- `build_cache_collect_output_paths`, `BuildGraphCache.w:545-553`, records only
  raw `target.output` plus `extra_outputs`; empty `target.output` means no
  primary output at all.
- `build_graph_output_path`, `build_graph_library_output_path`, and
  `build_graph_object_output_path`, `BuildGraphSupport.w:10-35`, instead choose
  CLI `-o`, then declared output, then a kind-specific default.
- The execution branches use those resolved paths at
  `main.w:1939-1998`, but freshness runs earlier at `main.w:1785-1790` without
  receiving `options.output_path`.
- `build_cache_compute_signature`, `BuildGraphCache.w:503-533`, likewise sees
  raw `target.output`, not CLI `-o` or the effective default.

The install control reveals the same missing path authority without false
success: installation expands `$INSTALL_BINDIR`/`$INSTALL_LIBDIR` in
`BuildGraphOps.w:551-573`, while the cache fingerprints the unexpanded
`root/$INSTALL_BINDIR/...` path. It therefore sees the output as missing and
reruns forever.

Five Whys:

1. A deleted or newly requested artifact is not produced because the target is
   declared fresh before execution resolves its real path.
2. Freshness records only storage fields, not the executor's effective output.
3. CLI/default/install expansion occurs in separate kind-specific helpers.
4. Cache identity and execution do not consume one canonical action descriptor.
5. Output resolution was treated as presentation/execution detail even though
   it is part of incremental correctness.

Proper repair boundary: compute the concrete effective output and extra-output
set once, after CLI/default/install resolution and containment validation, and
pass that descriptor to both freshness and execution. The signature must also
include the effective paths. A cache hit requires every promised output to
exist and match; a path change must miss. Do not add kind-specific guesses to
`BuildGraphCache`.

## BGC-003 — semantic and absolute target inputs are not resolved by the same rules as execution

Classification: **Confirmed false-fresh input defect; candidate unreported**  
Severity: **High**  
Blast radius: binary/fixpoint comparisons and every target declaring an
absolute input path  
Confidence: **Very high**

`docs/audit/probes/build_cache_compare_right` declares
`Build.binary_compare("compare", "left.bin", "right.bin")`. The first equal
comparison passed. After only `right.bin` changed, the second build skipped and
exited 0. Deleting only `compare.state` caused the unchanged comparator to run
and exit nonzero at byte zero.

`lib/std/build.w:1920-1929` stores the left path in `entry` and the right path
in `args[0]`. `build_cache_collect_input_paths`,
`BuildGraphCache.w:535-543`, fingerprints only `entry` and `inputs`; it cannot
know that the right argument is a semantic input for kinds 10 and 11.

`docs/audit/probes/build_cache_absolute_input` declares an absolute input to a
command target. The first run copied `A`; changing the input to `B` left output
`A` because the target skipped. Deleting only its state reran the command and
produced `B`. Execution preserves absolute paths through
`build_graph_resolve_project_path`, `BuildGraphSupport.w:37-40`; the cache
unconditionally constructs `root ++ "/" ++ input` at lines 539-542 and hashes
a different, absent path.

Proper repair boundary: every target kind must expose one canonical resolved
input set derived from its semantic operands. Cache and execution must share
that set. Absolute/relative resolution and containment policy must be applied
once; comparison operands cannot be hidden in undifferentiated argv.

## BGC-004 — action freshness omits observable action configuration

Classification: **Confirmed false-fresh action defect; candidate unreported**  
Severity: **High**  
Blast radius: custom actions whose result depends on working directory,
environment, timeout, network permission, write scopes, action function, or
parallel execution configuration  
Confidence: **Very high for the root; working-directory path directly executed**

`docs/audit/probes/build_cache_action_config` has an action in `build/actions.w`
that writes `ctx.working_dir()` to its declared output. The first configuration
wrote `A`. Changing only root `build.w` to configure working directory `B`
refreshed the graph but did not change the imported action source closure; the
target skipped and the output remained `A`. Deleting only
`write-context.state` reran the action and wrote `B`.

`build_cache_compute_signature`, `BuildGraphCache.w:503-533`, includes kind,
name, entry, raw output, optimization, target kind, args, defines, includes,
libraries, compiler, and action-source hash. It omits `cwd`, `env`,
`timeout_ms`, `network`, `parallel`, `write_scopes`, and `action_fn`. In
contrast, `main.w:1485-1487` passes those values into the action evaluator, and
the serializer preserves them at `BuildGraphCache.w:798-812`. Switching between
two action functions in one unchanged imported module can therefore retain the
same source hash while changing behavior.

Proper repair boundary: a custom action needs one canonical execution identity
containing its function identity, reachable source closure, all observable
configuration, resolved inputs, outputs, and effective capabilities. Both
execution and cache signature must consume that value. Tests must mutate each
field independently and prove exactly one miss followed by a stable hit.

## BGC-005 — live external-tool identity is not part of target freshness

Classification: **Confirmed false-fresh tool-identity defect; regression of #360 intent**  
Severity: **High**  
Blast radius: command targets using PATH-resolved executables and actions whose
subprocess tools change without their stored effect text changing  
Confidence: **Very high**

`docs/audit/probes/build_cache_tool_identity` contains two same-named `-O1`
compiled helpers in separate PATH directories; one writes `A`, the other `B`.
The first command-target run through PATH A produced `A`. Repeating with PATH B
skipped and left `A`. Deleting only the target state caused PATH B to execute
and produce `B`.

The module has a PATH resolver at `BuildGraphCache.w:151-175`, but only uses it
to fingerprint the current compiler at lines 177-185. A standard command's
`entry` is included as text in the signature and then treated as
`root/entry` by the generic input collector; the executable selected from PATH
is never fingerprinted. Action process effects do record a tool identity at
`ComptimeEval.w:2162-2172`, but target freshness at
`BuildGraphCache.w:651-656` merely hashes the stored `.effects` file against
the hash stored in `.state`; it does not recompute the live tool identity.

Proper repair boundary: resolve the executable under the effective environment
at record and check time, fingerprint its file identity/content, and compare it
as a first-class target input. For action effects, parse and revalidate the
effect record rather than checking only that two old files agree with each
other. Resolution failure is a miss or loud execution failure, never a hit.

## BGC-006 — unchecked target names are used as state-file paths

Classification: **Confirmed state-containment defect; candidate unreported**  
Severity: **High**  
Blast radius: all per-target `.state`, `.effects`, `.test-pass`, and
`.test-verdicts` writes and reads  
Confidence: **Very high**

`docs/audit/probes/build_cache_target_name` declares a harmless response-file
target named `../escaped`. The build succeeded and wrote cache state at
`out/escaped.state`; no state appeared at
`out/.build-state/escaped.state`. The one-level fixture deliberately remained
inside its project.

`BuildGraphMaterialize.w:114-119` rejects only empty and duplicate names.
`BuildGraphCache.w:38-48,435-436` concatenates the raw name into four state
paths. Dependency/default lookup also uses the name as an identifier, so
silently sanitizing it would create collisions or broken graph references.

Proper repair boundary: define and enforce one target-name grammar during
materialization (reject path separators, dot segments, control bytes, and any
platform-specific path syntax), then encode the already-validated identifier
when constructing storage paths. Add containment assertions at the filesystem
boundary. Invalid names must fail before any target or state write.

## BGC-007 — malformed serialized graphs are accepted as valid cache hits

Classification: **Confirmed malformed-state acceptance defect; candidate unreported**  
Severity: **Medium**  
Blast radius: interrupted, externally modified, old, or otherwise malformed
`out/.build-state/build-graph.cache` files  
Confidence: **Very high**

The retained direct probe imports the real parser and writes a valid baseline
plus four malformed variants. Its `-O1` build passed and execution printed:

```text
bad-separator accepted=true
bad-target-count accepted=true
negative-target-count accepted=true
trailing-data accepted=true
```

The exact parser defects are:

- `bcg_parse_i64`, `BuildGraphCache.w:827-840`, returns a partial number (or
  zero) at the first non-digit and has no validity result or overflow check;
- `BcgReader.read_str`, lines 856-867, advances over the separator byte without
  requiring it to be a newline;
- list, target, and generated-source counts are not constrained nonnegative, so
  negative counts execute zero loop iterations (`875-878,897-898,933-934`);
- the seven target integers reuse the permissive parser (`902-912`); and
- success sets `graph.ok = true` without requiring end of input
  (`939-943`).

The writer also writes directly to the final path at lines 818-819, so a torn
write is a normal state the reader must reject.

Proper repair boundary: return a checked integer result, validate every prefix,
separator, count, enum/range, list length, and arithmetic bound, require exact
end of input, and write atomically through a temporary file plus rename. Any
parse or version failure must discard the whole graph and trigger evaluation;
partial data must never become `ok`.

## BGC-008 — fingerprint length narrows from `i64` to `i32`

Classification: **Source-proven large-input boundary defect; candidate unreported**  
Severity: **Medium**  
Blast radius: any single cache framing-plus-payload value larger than
`i32::MAX`, including sufficiently large binaries, directories serialized as
one combined string, or generated graph text  
Confidence: **High from exact types; direct 2 GiB allocation intentionally not performed**

`build_cache_sha256_framed`, `BuildGraphCache.w:92-107`, computes allocation and
copy length as `i64` but passes `total as i32` to `sha256_hash`. The called API
accepts `i32`; `sha256_update`, `lib/std/crypto/sha256.w:104-108`, adds that
possibly negative value to its unsigned count and executes `while off < len`.
Once the narrowing becomes negative, payload bytes are not consumed and the
length state is nonsensical. The same library API also narrows ordinary string
lengths (`sha256.w:149-152`).

This was not executed because allocating and copying more than 2 GiB would add
resource pressure without changing the type-level proof. Proper repair is an
`i64`/`usize`-safe streaming SHA-256 update API and bounded chunks; cache hashing
must not concatenate or allocate a second whole payload. Boundary tests should
use a streaming synthetic source so they do not require a multi-gigabyte
resident buffer.

## Super-low cleanup observation — write-only aggregate test marker

`build_cache_record_test_success`, `BuildGraphCache.w:415-421`, writes
`<target>.test-pass`. Exhaustive exact-text search found the constructor,
writer, and caller at `main.w:1936`, but no reader of that suffix or manifest.
The per-file `.test-verdicts` store is the live cache and has both read and write
paths. The aggregate marker currently has no internal effect and both its mkdir
and write results are ignored. This is retained as dead-state/documentation
cleanup, not a correctness finding; it should either gain an explicit consumer
and checked write contract or be removed when production changes are
authorized.

## Test-coverage audit

Exact searches under both `test/` and `tests/` found no import or occurrence of
`BuildGraphCache`, `build-graph.cache`, `.build-state`, or `freshness`. The file
named `src/BuildGraphTests.w` is the native external-test executor and verdict
consumer, not a cache test suite. Current coverage therefore reaches caching
indirectly through repository builds, which did not catch any of the confirmed
single-input mutations above.

## Required regression matrix

- Graph cache: every imported source location; env present/absent/value change;
  ToolFs file contents, existence, directory listing, glob membership and file
  hash; process argv/env/cwd/tool/result dependencies; manifest and target-kind
  options; missing/corrupt effect evidence; worker sharing versus a new
  top-level invocation.
- Outputs: explicit, CLI, default, absolute, install-expanded, and extra outputs
  for every cacheable kind; change path, delete file, change contents, and
  change target count around `-o`.
- Inputs: relative and absolute paths; both operands of binary and fixpoint
  compare; command executable plus argv-declared semantic files; directories,
  symlinks, permission/execute-bit changes, absent-to-present transitions, and
  discovered dependencies.
- Actions: independently mutate `action_fn`, source closure, cwd, environment,
  timeout, network, parallel flag, write scopes, args, inputs and outputs; prove
  one miss and then a stable hit for each.
- Tools: absolute, relative, and PATH-resolved executables; PATH order changes;
  same path with changed contents/mode; missing and replaced tools; action and
  ordinary command paths.
- State format: truncated at every field boundary, wrong separator/prefix,
  empty/partial/overflow/negative counts and integers, invalid enum values,
  excessive lengths, duplicate/unknown records, trailing bytes, old version,
  and interrupted writes. Every case must become a whole-cache miss.
- Names: empty, duplicate, slash/backslash, `.`, `..`, nested dot segments,
  control bytes, Unicode, maximum length, and platform-specific reserved forms;
  prove every state path remains contained.
- Fingerprints: zero, block-boundary, `i32::MAX`, `i32::MAX + 1`, and multi-
  chunk lengths without a second whole-payload allocation.
- Keep the missing-action-output control, and add direct cache tests that fail
  if a skipped target leaves any effective output absent.

## Issue relationship summary

The upstream tracker was searched during this audit. Open #649 directly covers
the graph-environment portion of BGC-001. Closed #360 is the prior effects and
tool-identity contract whose intent is not enforced by current graph/target
reads. Closed #683 introduced evaluated-graph serialization; closed #931 works
around its suppressed evaluation in a reseed test. Open #921 is the planned
compiled graph-runner architecture. Closed #700 and #717 are adjacent stale or
hybrid artifact histories with different demonstrated causes.

No exact report was found for imported/ToolFs/process graph dependencies,
effective default/CLI outputs, the right comparison operand, absolute inputs,
omitted action configuration, PATH-swapped command tools, target-name state
containment, permissive graph parsing, or large-length fingerprint narrowing.
No issue was filed during this report-only audit.

## Completion statement

The primary agent examined all 943 source lines, every production importer, all
public record/read/freshness paths, the kind-specific execution consumers, and
the applicable build/effect/path producers. The finite four-kind implicit
output matrix, both compare operands, environment, ToolFs, process, imported
source, action configuration, tool identity, relative/absolute resolution,
state-name containment, valid/malformed serialization, and missing-output
control were verified inline. Every retained executable finding was isolated
by removing only its cache record and observing the correct changed result.
The unexecuted large-length boundary is explicitly marked source-proven rather
than runtime-proven. This evidence supports marking `src/BuildGraphCache.w`
complete while retaining its confirmed defects for prioritization.
