# Primary verification — `src/Overflow.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Source SHA-256: `fae04783f4766405f612681e1892ed2454db959de307228589c64e0f5d379ee4`  
Source examined: all 262 lines

## Scope examined

The complete module was read inline. It defines the three overflow modes,
mode parsing and validation, integer-width normalization, signed and unsigned
truncation and bounds, exact unsigned multiplication, checked/wrapping/
saturating add/subtract/multiply, explicit-operator mode selection, unary
negation overflow, and the signed `MIN / -1` predicate.

The codebase-memory graph was queried first. Its current `.w` extraction did
not return the module's symbols, so Tilth was used to enumerate every direct
production import and relevant call site. Direct consumers are:

- `src/ComptimeEval.w` — comptime unary/binary arithmetic and nested workspace
  compile configuration;
- `src/CodegenTraits.w` — scalar module-constant evaluation;
- `src/Codegen.w` — runtime LLVM codegen configuration;
- `src/CCodegen.w` — C-backend overflow selection and emission;
- `src/Sema.w` — semantic overflow-mode state and integer type widths;
- `src/compiler/Compilation.w` — project/CLI configuration propagation into
  Sema and both backends;
- `src/compiler/Compilation/Config.w` — normalized compilation option storage;
- `src/compiler/DriverOptions.w` — command-line mode parsing; and
- `src/compiler/ProjectConfig.w` — `[build].overflow` parsing and defaults.

The `Ast.w` dependency and exact-integer helpers used by the module were also
read through the required definitions. `overflow_mode_name` currently has no
repository consumer; it is recorded as dead surface, not a correctness defect.

Applicable overview targets examined: 8, 12–14, 18–19, and 21–24. The module
does not allocate, own a runtime resource, suspend, call foreign code, or make a
platform choice itself.

## Normative boundary

Specification §4.2.2 promises arithmetic on `i8`–`i64` and `u8`–`u64`.
Section 4.2.3 requires ordinary integer overflow to panic unless the project
selects two's-complement wrapping or saturation; explicit `+%`/`-%`/`*%` and
`+|`/`-|`/`*|` override the project mode. The exposed `i128`/`u128` types are
currently outside that enumerated arithmetic promise, but open issue #914 makes
their end-to-end arithmetic a declared implementation campaign.

## Artifact and optimization evidence

The primary agent ran:

```text
./out/bootstrap/bin/with-stage1 build --explain stage1 :stage1
```

The build graph reported `fresh`, listed `src/Overflow.w` as a stage1 input,
and showed the stage argument `-O1`. Behavioral controls below used that pinned
stage1 compiler and `-O1` where the command accepts an optimization level.

## Working controls

The retained matrices established the following working behavior:

- `docs/audit/probes/overflow_explicit_matrix.w` passed `check --validate-all` and
  native execution. It covers signed and unsigned 8/16/32/64-bit explicit
  wrapping and saturating operations, both saturation directions, and const and
  runtime paths.
- The same explicit matrix was independently built and run under global
  `--overflow=wrap` and `--overflow=saturate`; both binaries printed
  `overflow-explicit-matrix: ok`. Explicit operators therefore keep their own
  semantics regardless of the global mode.
- `docs/audit/probes/overflow_panic_dispatch.w` passed validation. Its nonoverflow
  control exited 0, while all 17 selected overflow cases exited 134 with the
  expected operation-specific panic: unsigned add/subtract/multiply; signed
  high/low add/subtract/multiply; 8- and 64-bit negation; and 8- and 64-bit
  `MIN / -1` and `MIN % -1`.
- Separate 64-bit runtime matrices built and passed under global wrap and
  saturate, including signed add/negate/divide/remainder and unsigned add.
- The checked-overflow, unsigned-overflow/underflow, project-mode,
  explicit-mode, saturating-operator, and float-rejection repository tests were
  read and rerun; every selected positive or expected-failure test passed.
- Native execution of the C-wrap source passed before C translation. C-backend
  saturation failed loudly rather than emitting a placeholder.

These controls cover every mode branch and operation family in `Overflow.w` for
the specified 8–64-bit surface. No arithmetic-formula defect was retained in
the module itself.

## OVF-001 — CLI overflow mode is accepted but ignored outside `build`

Classification: **Confirmed integration defect; candidate unreported**  
Severity: **High**  
Blast radius: explicit-source `run`, implicit run, `check` and all its artifact
variants, source-targeted `test`, `bench`, and one-liner compilation  
Confidence: **Very high**

Primary differential evidence:

| Command path | Valid `--overflow` | Invalid `--overflow=bogus` |
|---|---|---|
| `build` | wrap/saturate matrices build with selected semantics | exit 1 with a value diagnostic |
| `run` | compile-time overflow still uses panic mode | exit 0; flag silently ignored |
| `check` | compile-time overflow still uses panic mode | exit 0 and `ok`; flag silently ignored |

The larger help screen lists `--overflow` under “General Options,” and `run`,
`test`, `bench`, and one-liners all build programs. Silently treating the
argument as program input or an inert compiler flag is not an acceptable
interpretation.

Exact source chain:

1. `src/compiler/DriverOptions.w:367-411` is the only public CLI parser that
   validates `--overflow`, and `parse_build_command_options` is its only caller.
2. `src/main.w:779-790` invokes that parser only for the `build` branch.
3. Explicit and implicit run call `run_run_command` without an overflow
   parameter (`main.w:775-805`); that function configures Compilation but never
   calls `set_overflow_mode` (`2425-2432`).
4. The ordinary check path and every check-artifact helper likewise receive no
   overflow value (`866-919`).
5. Source-targeted tests, benchmarks, and one-liners construct Compilation
   directly without setting the mode (`693-728`, `3400-3463`, `3465-3485`).
   The no-target test branch creates default build options rather than parsing
   the supplied flag.

Five Whys:

1. The selected mode has no effect because most compilation front doors never
   place it in `CompilationConfig`.
2. They cannot place it there because their signatures omit the option.
3. The option parser is coupled to the `build` subcommand rather than the shared
   CLI configuration boundary.
4. Unknown options are not rejected consistently by the other subcommands.
5. One semantic compiler option therefore has several independent, divergent
   propagation paths.

Repair boundary: parse common compiler options exactly once before subcommand
dispatch, reject invalid values consistently, and carry one normalized option
object into every path that compiles source. Project configuration should remain
the default and an explicit CLI value should override it through
`Compilation.set_overflow_mode`.

## OVF-002 — C wrapping mode emits signed-overflow expressions

Classification: **Confirmed backend correctness defect; candidate unreported**  
Severity: **Critical for C-backend users; High overall**  
Blast radius: C output for signed wrapping add/subtract/multiply, and global-wrap
signed negation/division/remainder overflow edges  
Confidence: **Very high**

Native execution of `docs/audit/probes/overflow_c_wrap.w` produced the specified
two's-complement results. `build --emit-c` emitted:

```text
_3 = (_1 + _2);
_3 = (_1 - _2);
_3 = (_1 * _2);
```

for `i64` `+%`, `-%`, and `*%`. Those operations overflow their signed C type;
the generated program therefore does not encode With's required
two's-complement result. The same source branch emits raw signed unary `-`, `/`,
and `%` for the global wrap mode, including the `MIN` edge.

Exact source chain:

1. `CCodegen.binop_token` maps ordinary, explicit-wrap, and saturating variants
   to the same raw C tokens (`CCodegen.w:3192-3197`).
2. `emit_rvalue` marks only ordinary add/subtract/multiply/divide/remainder as
   checked arithmetic (`3311`). Explicit wrapping operators skip checked
   lowering.
3. Global wrap deliberately skips checked lowering as well (`3316-3322`).
4. Unary negation uses raw signed negation in wrap mode (`3323-3332`).
5. In contrast, unsupported saturation calls `self.fail` and causes C emission
   to fail nonzero; its returned `"0"` is not shipped because the enclosing
   result is marked failed.

Five Whys:

1. Generated C has undefined signed-overflow behavior because the operation is
   performed in the signed type.
2. It is performed there because wrapping was treated as “omit checks,” not as
   a distinct lowering contract.
3. The backend collapses semantic operator variants into punctuation before it
   has encoded their result rules.
4. The C backend independently re-derives overflow semantics instead of sharing
   a backend-neutral arithmetic-lowering decision.
5. Native and C backends can consequently disagree while both compile.

Repair boundary: lower wrapping signed arithmetic through width-matched unsigned
operands and bit-preserving conversion back to the signed result, including the
negation and `MIN / -1`/remainder edges. The emitted C must express the semantics
without depending on implementation-defined or undefined signed overflow.

## OVF-003 — comptime i128/u128 arithmetic is clamped to 64 bits

Classification: **Confirmed exposed-surface defect; covered in scope by open #914**  
Severity: **High for the i128 campaign; outside the current §4.2.2 width list**  
Blast radius: comptime and scalar-global folding of all 128-bit arithmetic routed
through `Overflow.w`  
Confidence: **Very high**

`docs/audit/probes/overflow_i128_runtime.w` passed validation and execution for
`9223372036854775807i128 + 1i128`. The same expression in a typed const in
`docs/audit/probes/overflow_i128_surface.w` failed with `integer overflow in
comptime`, even though the result fits in `i128`.

Exact source chain:

1. Sema registers `i128` and `u128` as 128-bit integer types.
2. `ComptimeEval` and `CodegenTraits` pass the resolved integer width to the
   shared arithmetic evaluator.
3. `int_width_clamp` converts every width greater than 64 to 64
   (`Overflow.w:45-50`).
4. Every bound, truncation, arithmetic, unary-negation, and division-overflow
   helper calls that clamp.
5. Runtime LLVM lowering supports the wider value, producing the observed
   comptime/runtime mismatch.

Five Whys:

1. A fitting 128-bit const is rejected because it is checked against 64-bit
   bounds.
2. The width is narrowed by an unconditional clamp.
3. The arithmetic result carrier stores only one `i64`, while the AST's exact
   integer machinery already carries two words.
4. Adding exposed 128-bit types did not extend this shared evaluator contract.
5. Compile-time and runtime lowering consequently use different numeric
   domains.

Repair boundary: replace the one-word arithmetic result with the existing exact
two-word representation (or a typed wrapper over it), implement signed and
unsigned 128-bit bounds and operations there, and make invalid widths fail
loudly rather than narrowing. This belongs in #914's checked-overflow acceptance
matrix; #941 concerns a different migrated-C helper.

## OVF-004 — a valid i64 value is also the constant-evaluation failure sentinel

Classification: **Confirmed silent-miscompile defect; candidate unreported**  
Severity: **Critical**  
Blast radius: scalar module constants whose expression contains or produces
`-9223372036854775807`, including wrap-mode construction of `i64::MIN`  
Confidence: **Very high**

The wrap-mode value probe produced the correct `-9223372036854775808` for direct
`i64::MAX + 1`, but printed `0` for both wrapping negation and wrapping division
whose operand expression contains `-9223372036854775807`. Compilation succeeded;
the wrong constants reached the executable.

Exact source chain:

1. `CONST_EVAL_FAIL()` is the ordinary `i64` value
   `-9223372036854775807` (`CodegenTraits.w:1196`).
2. `try_eval_const_int_expected` returns raw `i64` and compares every recursively
   evaluated operand with that value (`2065-2122`). A valid program value is
   therefore indistinguishable from failure.
3. `try_eval_const_llvm` repeats the same comparison and returns a null LLVM
   handle on the collision (`2225-2235`).
4. `gen_module_constant` retries those two paths, then reaches the end without
   emitting a diagnostic or a scalar integer global (`2279-2455`).
5. The missing constant is subsequently observed as zero in the passing build,
   turning an internal status collision into a silent executable miscompile.

Five Whys:

1. The executable reads zero because constant codegen discarded a valid value.
2. It discarded it because the value equals an error sentinel.
3. Status and payload share one unrestricted `i64` channel.
4. The fallback chain treats “not folded” as permission to continue without a
   diagnostic for scalar constants.
5. A codegen failure can therefore become plausible output instead of stopping
   compilation.

Repair boundary: return a structured `{ ok, value }` result everywhere in the
constant folder and remove value sentinels. If a semantically valid const cannot
be emitted, `gen_module_constant` must diagnose the declaration and fail the
build; it must never fall off the end.

## OVF-005 — saturated u64 consts lose unsigned identity when embedded

Classification: **Confirmed comptime rematerialization defect; candidate unreported**  
Severity: **High**  
Blast radius: a comptime value with an unsigned result whose `i64` carrier has
the sign bit set; directly reproduced with saturated `u64::MAX`  
Confidence: **Very high**

The 64-bit runtime saturating matrix passed. Adding the equivalent typed module
const under `--overflow=saturate` failed compilation. The diagnostic identified
an integer literal with empty exact digits, raw value `-1`, and an expected
unsigned 64-bit type.

Exact source chain:

1. A `const` declaration is desugared to `NK_COMPTIME` by
   `Parser.parse_const_decl` (`Parser.w:2755-2775`).
2. `int_unsigned_add` correctly returns `int_unsigned_max(64)`, represented as
   the `i64` bit pattern `-1` (`Overflow.w:108-124`, `78-83`).
3. `ComptimeEval` retains the resolved result type in `ComptimeValue.type_id`
   and the bits in `data0` (`ComptimeEval.w:6726-6737`;
   `ComptimeValue.w:82-94`).
4. `ct_build_value_tree` rebuilds every `CV_INT` as an unsuffixed `NK_INT_LIT`
   using only `data0`; it discards `type_id` and creates no exact-literal sidecar
   (`ComptimeTransform.w:398-407`).
5. The second Sema pass checks that synthetic signed `-1` literal against the
   annotated `u64` and correctly rejects it (`Sema.w:4070-4081`).

Five Whys:

1. A valid saturated result is rejected because its reconstructed literal looks
   negative.
2. It looks negative because only the one-word bit pattern was copied.
3. The compile-time value's known integer type was not transferred to the new
   AST node.
4. The rematerializer treats integer values as untyped syntax rather than typed
   semantic values.
5. Compile-time evaluation and the post-transform Sema pass therefore disagree
   about the same value.

Repair boundary: preserve the typed integer value during rematerialization.
For unsigned values with the high bit set, create the exact digit/word sidecar
and explicit resolved type (or a dedicated typed-constant AST form); never
reinterpret the payload through signed decimal syntax. Apply the same rule
recursively to arrays, tuples, maps, structs, ranges, and comptime loop items.

## Issue relationship

The primary agent searched the live upstream tracker on 2026-09-02 for overflow
mode propagation, constant sentinels, u64 saturated comptime values, C-backend
signed wrapping, and related terms. No exact report for OVF-001, OVF-002,
OVF-004, or OVF-005 was found.

- Closed #339 established checked overflow and explicit modes, but does not
  report the current CLI propagation, constant-sentinel, or C-emission defects.
- Closed #522 added saturating-operator coverage and explicitly noted that the C
  backend failed loudly; it did not cover high-bit `u64` const rematerialization
  or wrapping C output.
- Open #914 is the correct existing campaign for OVF-003's 128-bit extension.
- Open #941 concerns migrated 128-bit C helper generation, not this evaluator.

No issue was filed during this report-only audit.

## Required regression matrix

- Mode parsing and precedence through `build`, explicit/implicit `run`, `check`
  plus every artifact variant, source/project `test`, `bench`, and one-liners;
  valid and invalid values must agree.
- Signed/unsigned 8/16/32/64-bit add/subtract/multiply in panic, wrap, and
  saturate modes at comptime, module-constant codegen, native runtime, and C
  runtime; include both signed overflow directions and nonoverflow controls.
- Unary `MIN` negation and `MIN / -1`/`MIN % -1` at every signed width in all
  global modes and both backends.
- Constants at `i64::MIN`, `i64::MIN + 1` (the former sentinel), `i64::MAX`,
  `u64::MAX`, and all nested-expression/operator forms; any folding failure must
  exit nonzero.
- Typed comptime rematerialization for unsigned high-bit values in scalars,
  arrays, tuples, ranges, structs, maps, and comptime loop items.
- The #914 i128/u128 boundary matrix for exact constants, ordinary and explicit
  overflow modes, signed/unsigned high and low edges, and comptime/runtime
  equivalence.
- Generated C inspection plus execution under optimization that would expose
  signed-overflow assumptions; saturation must either work or keep failing
  loudly.

## Completion statement

The primary agent examined the complete module, every direct production
consumer, the exact integer representation it depends on, every public mode and
operation branch, and the applicable specification. Working controls and each
retained failure were verified inline; all five findings name the exact branch
and repair boundary. Artifact inclusion, freshness, and `-O1` were independently
checked, and issue overlap was reconciled. No candidate in this module remains
unclassified, so this evidence supports marking `src/Overflow.w` complete while
retaining its confirmed integration defects for prioritization.
