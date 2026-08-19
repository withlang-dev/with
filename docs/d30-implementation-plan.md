# D30 Runtime Retirement Implementation Plan (#761)

## Authority and scope

This is a derivative execution plan for the D30 ruling recorded in
`docs/decisions.md` and the normative §16.3e spec text. It cannot amend
either. Where this plan and the ruling disagree, the ruling wins and this
plan is wrong.

Target, restated from D30:

- The runtime compiles **in-unit** like the embedded stdlib; codegen lowers
  runtime operations to **ordinary module functions** resolved through Sema
  and marshalled through `FnAbi` — never through name-string synthesis.
- Pre-compiled runtime objects survive **only as a cache** keyed by
  (compiler version, target), where a hit is **byte-identical** to the
  in-unit result. Objects as boundary: retired.
- Remaining ABI surfaces (`extern fn`, `@[c_export]`, `c_import`) face
  genuinely foreign code and **speak C** (§16.3e): With-managed types in
  such signatures are hard errors; §16.3c call-site coercion carries the
  ergonomics.

## Fact base (verified 2026-08-17, commit 830018de)

The seam being deleted is **three independent hand-maintained derivations
of the same ~134 symbols**:

1. **Codegen's synthesized LLVM decls** — ~125 live `with_*` symbols built
   from literal name strings across five mechanisms: the generic
   `ensure_internal_runtime_fn`/`call_internal_runtime_fn` path
   (`src/CodegenDispatch.w:2780,2820`, with its own Windows-only aggregate
   ABI re-derivation at `src/Codegen.w:4878`); per-family helpers with
   hardcoded name→type if-chains (`get_runtime_fn_type` at
   `src/CodegenDispatch.w:17997` defaults unmatched params to `i64`);
   single-symbol `ensure_*` helpers; **56 raw inline
   `wl_add_function(self.llmod, "with_…")` sites**; and a
   reuse-if-source-declared fallback (`call_runtime_str_fn`,
   `src/CodegenDispatch.w:2764`) under which one call site's ABI depends on
   whether a `lib/std` extern decl happened to be seen first.
2. **`lib/std` extern decls** — 222 `extern fn with_*` decls / 134 distinct
   symbols across 33 files, with heavy redeclaration (`with_free` ×11).
   15 are ambient in every unit via `std.builtins` in the prelude.
3. **`runtime/with_runtime.h`** — hand-written C prototypes for `--emit-c`,
   only partially synced to the `&str` flip (#785).

Nothing ties any of these to `rt/rt_core.w`'s definitions. The caller-side
doctrine `extern_param_is_bit_copy` (`src/SemaCheck.w:22868`) never
consults the parameter type — every extern `str` param is ruled
non-transferring regardless of what the callee body does. That is the
double-derived contract #761 proved corrupts silently.

Runtime source honesty: `rt/rt_core.w` has 247 pub fns — 51 `&str`-honest,
**39 plain-consuming-`str` holdouts, of which only 5 are reachable**
(`with_vec_str_join`, `with_str_concat`-family `*const str` callers,
`with_vec_push_str`, plus `with_panic` in `rt/panic_runtime.w`); the other
34 are orphans with no codegen emitter and no `lib/std` decl.
`rt/linux_aarch64.w:1029–1147` missed the compat `&str` flip; the net
family (`with_net_tcp_connect`/`udp_connect`/`send`) takes plain `str` on
all three platforms.

Build/link facts:

- All `out/lib` rt objects are **seed-built** under the loud `#747 INTERIM`
  block at `build.w:1725-1731` — the flip-built runtime frees every str
  operand it is shown; the seed pin is the bridge this plan retires.
- `rt/rt_core.w` compiles `--emit-obj --no-prelude` (no main); pub fns keep
  raw C names only via the hardcoded carve-out
  `codegen_preserve_runtime_link_name` (`src/Codegen.w:4107-4125`: path
  contains `rt/` AND name starts `with_`/`rt_`/`wl_`); everything else in
  the object is path-hash-mangled.
- `Link.w` decides which runtime to link by shelling `nm -u` and
  substring-matching undefined symbols (`src/compiler/Link.w:816-869`,
  `1021-1046`), then pushes `rt_core.o` first in all three link branches.
- The embedded-stdlib model to mirror: sources embedded as string data
  (`build/runtime.w:195-236` → `out/gen/compiler/EmbeddedStdlibData.w`),
  resolved under a synthetic path prefix (`<embedded-std>/`,
  `src/compiler/EmbeddedStdlib.w`), parsed into the **same AST pool** as
  user code (`src/compiler/Frontend.w:1476-1487`), one Sema, MIR-cost-based
  unit splitting. No per-module objects.
- Cache precedents: `build_cache_graph_key` (`src/BuildGraphCache.w:774`)
  is already keyed by compiler-binary sha256 + target kind;
  `EmbeddedClangResource.w` has the stamp-last + per-file identity-manifest
  discipline ("hit is byte-identical" verification, #312); the c_import fs
  cache (`src/compiler/Frontend.w:455-498`) has the torn-write-is-a-miss
  two-file entry.

## Staged execution plan

Ordering rules that govern every stage: the bootstrap protocol (runtime
files and `Link.w` never change in the same commit; every commit
independently passes `with build :fixpoint`), and the drop-class isolation
rule (any stage that touches ownership/callee-drop behavior is alone in
its battery batch with `:move-audit`/`:drop-audit`).

### Stage R1 — make the runtime sources honest (enabler) — **COMPLETE (9f531dc3, 2026-08-18)**

Landed: R1a deletions (13 dead exports + dead codegen type table), R1b
flips (native + emit-c + stdlib + tools + all three platform files; 23
plain-str observers deleted; remaining plain-str exports are the honest
set — with_vec_push_str disarms, with_panic never returns, weak stubs
unreachable), R1c seed-pin retirement with byte-identity proof
(stage2-built rt_core.o == seed-built bootstrap object).

R1a. **Delete the 34 orphan plain-`str` fns** in `rt/rt_core.w` and the
dead codegen references (the 11-name if-chain in `get_runtime_fn_type`,
the uncalled `gen_fmt_buf_write_str`). Where a `_ref` twin exists, the
orphan dies and the twin stays. No behavior change; shrinks the honesty
problem to the reachable surface.

R1b. **Flip the reachable holdouts to honest signatures**: the 5 live
plain-`str` rt fns, the 7 plain-`str` extern decls in `lib/std`
(`builtins.w:19` `with_panic`, `testing.w:3`, `process.w:21`, `net.w:7,8,12`,
`regex.w:16`), the `rt/linux_aarch64.w` compat stragglers, and the
`with_net_*` family on all platforms. Caller sides (codegen emitters,
`MirLower.w:13873`'s `with_panic` lowering) update in the same commit as
their decl — the decl and its emitter are one contract, not a
Link.w/runtime split.

R1c. **Retire the `#747 INTERIM` seed pin**: with rt sources honest,
`out/lib` rt objects build with the current stage compiler again
(`build.w:1732-1750`). Gate: disassembly spot-check of the former #761
poison set (`with_str_eq` & co. — no callee-side frees), full battery,
`:drop-audit`. This closes #761's interim and is the proof the sources are
both-worlds honest.

### Stage R2 — runtime joins the unit (the dissolving move)

Reference verdicts (tree-verified 2026-08-18): **Go** keeps a generated
signature table — `typecheck/builtin.go` is generated from
`_builtin/runtime.go` by `mkbuiltin.go`, so the compiler's view of
runtime signatures cannot drift from the source (the drift #761 proved
fatal); its runtime is still a separately compiled package. **Zig** is
the destination shape: start code analyzed lazily in-unit with the
program, and `compiler_rt` built per-target as its own job into the
global cache (`Compilation.zig:219-223`, `2477`) — objects as cache,
never as boundary. **Rust** ships precompiled sysroot rlibs, but those
carry full metadata+MIR, so the contract travels with the object — the
boundary D30 rejects is specifically a *bare* object with re-derived
contracts.

**R2b/R2d coupling discovered in R2a:** in-unit runtime definitions keep
raw `with_*` link names (`codegen_preserve_runtime_link_name` matches any
path containing `rt/`, which `<embedded-rt>/rt/…` does), so a program
that compiles the runtime in-unit AND links `rt_core.o` gets duplicate
strong symbols; the inverse (link change first) gets undefined symbols.
The stages therefore cannot land by flipping a default in one commit:
R2b lands **dark behind an internal mode flag** (in-unit parse +
link-suppression together, off by default), R2c retargets codegen
family-by-family against that mode's test lane, and the default flip +
Link.w cleanup is the final, separately-gated commit pair per the
bootstrap protocol.

R2a. **Embed rt sources** in the compiler binary exactly like the
stdlib — **COMPLETE (69f3d87a, 2026-08-18)**: `EmbeddedRuntimeData.w`
generated as a third output of compat-runtime-source with rt/*.w as
declared inputs; `EmbeddedRuntime.w` accessor under `<embedded-rt>/`;
the four source-read sites consult it; internals pin
`embedded_runtime_data_test.w`. No resolve-side behavior change yet —
the runtime has **no user-spellable module name** (resolver-internal
prefix only); giving it one is language surface and needs Eric (open
question 3).

R2b. **Parse the runtime module into the unit** — **LANDED DARK
(e186a816 + edb85f73 + 6b0ad8b4, 2026-08-18)**: `WITH_RT_IN_UNIT=1`
parses the runtime set into the prelude prefix; every rt/std decl/def
seam it exposed is fixed (libc `write` → `@[link_name]` rename; unsafe
honesty on fiber-take calls; six signature divergences including the
`with_panic -> Never` and bool fossils; `str_from_byte` visibility; the
vacuous `spawn_os` effect pin deleted — no single pin text can span
conservative-extern vs precise-body inference). #839 (bare-symbol
collision between a link_name extern and a same-named With fn) fixed
with the c_import multi-prototype carve-out. **Current lane state:
user-program `check` is green under the env; `run` stops at link** —
lazy fn emission defines nothing in-unit while eager module-global
emission already duplicates, so a half-in-unit binary cannot link from
either direction. Link-side object suppression therefore lands WITH R2c
rooting, keyed on the object actually defining the runtime (the first
env-keyed gate orphaned the fiber trio and was reverted). Remaining
transition-tail: compiling the compiler itself under the lane trips
`extern fn shadows prelude function` for the compiler's own `with_*`
decls — exactly the decls R2c deletes family-by-family. R2c also owes
the harness an env-directive test cell so the lane's green surface is
pinned. The `symbol_visible_from_current` `with_`-prefix bypass
(`src/Sema.w:2632`) still dies with the seam at the end of R2c.

**R2c substrate facts (probed 2026-08-19 on the lane):** MIR bodies exist
for the ENTIRE in-unit runtime (analyze shows `with_runtime_init/run/
shutdown` lowered); whole-program emission then prunes to a demand
closure rooted at main + module globals + panic/exit glue — the lane's
42 duplicate symbols are exactly that closure (allocator family, panic
chain, `rt_argc`), and crucially they prove **in-unit bodied defs win
resolution over the extern decls** (`with_ewrite` reached the closure
through `with_panic_ref`'s real body). The runtime entry points stay
out because only the post-hoc LLVM-level wrapper references them. So
R2c likely collapses from per-family retargeting to: (a) find the
exact whole-program emission gate (one lldb breakpoint on the Pass-2
skip path — note `with build -o` is module-object mode, a DIFFERENT
pipeline; probe with `run`), (b) sema-root the entry-point set
(`with_runtime_set_argv/init/run/shutdown/configure_fibers` + the #777
exit-drop callees) under the lane, (c) suppress the .w-derived rt
objects wholesale via a link-plan flag (the compiler knows what it
emitted — never an env probe; fiber_asm.o and the regex/cimport
archives stay), (d) grow behav_rt_in_unit_check_lane into a run-lane
cell. String-emitted codegen calls (`with_print_str` & co.) resolve at
LLVM-name level against the in-unit defs whose names are preserved —
verify with the str probe before trusting.

**R2c lane sweep results (2026-08-19, release at 7adc08e9):** baseline
behavior suite 0 failures; under `WITH_RT_IN_UNIT` 69/~490 fail, in
seven classes: (1) decl-shape divergences — `with_free`(13) /
`with_realloc`(9) / `with_memcpy` / `with_vec_len` / `with_ptr_get_i32`
declare `*mut c_void` where rt defs say `*mut u8` — mechanical
def-is-truth sweeps across std.mem/box/arena + tests; (2) `SIGBUS`(10)
constant shadowing — flat-namespace collision like the dirent constant;
(3) `symlink`(9) — bare libc extern name vs std.fs's pub fn, the
send/recv `@[link_name]` class; (4) vacuous-`unsafe`(4) +
unsafe-required(3) — extern calls rebound to safe in-unit defs make
user `unsafe {}` blocks vacuous, and vice versa (needs a rule: likely
"an unsafe block around a runtime-ABI call is never vacuous" during
transition); (5) `LLVM function verification failed after MIR cleanup
for *.debug_str`(5) — REAL codegen bug under the lane, root-cause
before any sweep; (6) 3 unclassified check failures; (7) singletons.
Also fixed en route: std.process decl shapes, `rt_exit`/`ExitProcess`
`-> Never` on all platforms. **Known flip-blocker recorded:** the
compiler-self-lane stops at flat-namespace capture of rt PRIVATE
helpers (root-tier `make_str` captures rt_core internals after the
tier merge decl-drops the rt def) — needs module-scoped fn identity
(#751 adjacency) or a full rt-private prefix sweep before the default
flip. Sweep driver: per-file `WITH_RT_IN_UNIT=1 with test <file>`
(never `with build` targets — the lane env poisons build.w's own
evaluation through the seed's embedded stdlib).

R2c. **Codegen lowers to ordinary module functions.** Family by family
(str, vec, hashmap/slotmap, fmt, panic, fiber/async, regex, misc), each
family alone in a drop-audit batch: replace the name-string synthesis with
a Sema-resolved callee (the runtime module's function symbol) marshalled
through `compute_fn_abi` — one ABI descriptor read by both sides, per D6.
The `ensure_*` helpers and the 56 raw sites shrink to a single
"resolve runtime fn by name through Sema" utility during the transition
and disappear when the last family flips. Delete each family's
`with_runtime.h` prototypes as it flips (the emit-c backend reads the same
in-unit decls; #785's partial sync becomes moot).

R2d. **Retire the object boundary**: once no user-program symbol resolves
to `rt_core.o`, drop the rt-object pushes from the pure-With and cc link
branches (`src/compiler/Link.w:1174-1216`, `1263-1311`) and the `nm -u`
runtime gating; delete the mangling carve-out
(`codegen_preserve_runtime_link_name`) so runtime internals mangle like
any module. `Link.w`-only commit, after the R2c commits, per the bootstrap
protocol. The compiler-build (lld) branch keeps its bridge objects — they
are genuinely foreign (LLVM/clang), not runtime.

### Stage R3 — the cache

Pre-compiled runtime objects return **only** as a cache: key =
compiler-binary sha256 (the `build_cache_current_compiler_fingerprint`
component) + target spec; entry discipline = stamp-last with a per-file
identity manifest (the `EmbeddedClangResource` pattern); torn write = miss
(the c_import-cache pattern). The hit condition is byte-identity with the
in-unit result — verified in CI by compiling one unit both ways and
comparing hashes (the `fixpoint-compare` machinery at `build.w:1691-1710`
already does exactly this shape of check). A runtime object built by a
different compiler fingerprint can never be linked, by construction of the
key. R3 is pure build-performance work; R2 must not wait for it.

### Stage R4 — §16.3e enforcement

Extend the C-representability gate from `validate_c_export_signature`
(`src/SemaCheck.w:2962`, today `@[c_export]`-only) to **all three**
surfaces: `extern fn` decls and `c_import` bindings included. Hard error
per the spec sentence; diagnostic names the §16.3c modeled coercion for
the call-site direction and the pointer-and-length spelling for the raw
direction. Sequencing within R4:

- R4a. Migrate the survivors: after R2, the remaining `extern fn` decls
  with With-managed types are tool-facing fossils
  (`with_fs_read_file(path: str)` in tools; tools move to `std.fs`) and
  any stdlib decl that outlived its family's R2c flip.
- R4b. Land the gate. `extern_param_is_bit_copy` stops being a str
  doctrine — with §16.3e in force there are no With-managed extern params
  left to rule on, and the predicate reduces to genuine C-type semantics.
- R4c. Retire the `sema_name_is_compiler_abi_extern` exemptions
  (`src/SemaCheck.w:160,185`) — nothing needs them once the seam is gone.

### Stage R5 — docs and doctrine

Retire the transitional `with_*` guidance in CLAUDE.md/AGENTS.md (marked
"operative until the retirement lands"), update the Runtime Architecture
section, close #761, and record the completion in `docs/decisions.md` D30's
status line.

## Open questions that need Eric (none block R1)

1. **Cold-compile cost tolerance between R2 and R3.** In-unit runtime adds
   rt compilation to every cold user compile until the cache lands.
   Options: land R3 before flipping the default, or accept the interim
   cost. (Predicted ruling: correctness first, performance chased — the
   #691/build-perf record says he will want R3 fast-followed, not
   sequenced ahead.)
2. **`--no-prelude`/`no_std` story.** Today `--no-prelude` programs can
   still link rt_core via the `nm` probe. Post-R2d, what do they get —
   nothing (fully freestanding) or an opt-in runtime module import?
3. **Runtime module namespace.** Is the in-unit runtime a named module
   users could theoretically spell (`std.rt`?) or resolver-internal with
   no user-spellable name? (Predicted: internal — `with_*` was never
   user-facing, D30 says boundaries that remain face foreign code.)

## Issue cross-links

#761 (the campaign issue), #785 (emit-c decl sync — subsumed by R2c),
#742 (self-audit violations — unrelated gate, tracks separately), #729
(release-only invalid free — retest after R1c since it implicates
generation divergence across the object boundary).
