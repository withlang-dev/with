# D66 retained variadic completion (#1652)

Execution notes, subordinate to D51 and the approved D66 amendments in the
specification and decision log. This file grants no foreign-library facts.

## Acceptance

The critical path is: first setter succeeds, second setter fails, the function
returns an error, and actual cleanup is safe with retained storage released
once. Check the corresponding `?` path. A callback-free destroyer may accept
an incomplete pair; a callback-capable destroyer requires compatibility or a
modeled reset/unregister before it. Scope exit alone is not an error.

Also cover defaults, either setup order, different resources, replacement,
failure during replacement, ignored status, joins, loops, moves and fields,
helper calls, borrowed userdata lifetimes, callback reentrancy, and thread
restrictions. Preserve the variadic C ABI.

## Owners of facts

- Parser records the explicit callback type, paired selector and retaining
  parameter. No callback signature or lifetime is inferred from an option name.
- Sema resolves those clauses and emits slot identities, concrete userdata
  types, operation effects, success conditions, and retained origins. The
  `callbacks none` clause carries its source location into the audit.
- MIR propagates those facts through actual calls, branches, moves and drops.
  It reports an unsatisfied invocation/lifetime requirement on a reachable
  path. Generated cleanup, early return and `?` use the same check.
- Codegen transports the already-selected ABI values. It neither guesses the
  slot type nor repairs an incomplete pair with an invented callback result.

## Work in progress

`ForeignPairState.w` contains the finite compatibility domain and CFG join.
An alternative includes callback type, userdata type/origin and the most
recent setter result that selected the alternative. Unknown failure effects
retain both possible userdata origins and mark compatibility unknown. A
failure is treated as preserving old installation only with explicit trusted
evidence. An unrelated branch must not filter alternatives.

The CFG test deliberately numbers cleanup before the error arms that reach
it, so acceptance cannot rely on a single forward sweep. A distinct absent
resource state keeps destruction separate from an unreachable CFG edge;
the construction/destruction loop test verifies storage reuse.

Sema now resolves retained-case declarations into `ForeignVariadicSlot`:
the resource/parameter, C callback type and userdata argument, and paired
selector value. It checks the actual C signature and distinct selectors.
The compiler still refuses the resulting safe surface. These declarations
are not yet specialized per call or propagated to MIR.

Still to wire: Sema's per-slot call descriptors, MIR place/alias transport and
success-edge refinement, retained-origin constraints (including helper-call
propagation), and the variadic renderers. The parser accepts the approved
spelling, but Sema still refuses these cases until the safety checks are
connected. Do not remove that refusal just to make rendering tests pass.

The safe abandonment operation needs an explicit trusted reset/release fact;
`callbacks none` alone only says the operation does not invoke callbacks.
It does not prove failure preserves the installation, reset releases a borrow,
or background callbacks are absent. A creator-thread callback contract plus
the library's serialized-use guarantee must justify separate-call setup.

## Foreign evidence and test fixture

`curl_easy_cleanup` can invoke progress/header callbacks, so no unconditional
`callbacks none` annotation belongs on it. `curl_easy_reset` restores option
defaults, but its implementation must be checked for applicable callbacks
before granting no-invocation evidence. Relevant source is also available in
`.deps/src/cmake-4.2.3/Utilities/cmcurl/lib/{easy,setopt}.c`; this is reference
material, not a runtime dependency.

Reset is not an unconditional no-callback operation across all libcurl
features either: this source's `easy.c:1110` calls `Curl_freeset`, whose
`url.c:198` calls `Curl_mime_cleanpart`; `mime.c:1127` invokes a configured
`freefunc`. The currently modeled closed option set excludes MIME, but a
future MIME extension must revisit any no-callback proof for that set.
The reset probe below establishes the tested write-only setup path, not
a universal guarantee for arbitrary easy handles.

The tiny inline variadic C fixture using `va_start`/`va_arg` is currently
omitted by c_import (#1678). Do not substitute a fixed-arity definition for
its variadic ABI. The required runtime failure test still needs a faithfully
modeled controllably failing setter; the abstract CFG test is not that proof.

`out/curl-pair-failure-probe.w` confirms a deterministic failure with the real
variadic ABI: install WRITEFUNCTION successfully, pass a userdata pointer to
the deliberately invalid LASTENTRY selector, receive UNKNOWN_OPTION, reset,
and clean up. It runs without a network transfer. This is a raw-library
fault-injection probe, not evidence that the safe surface or retained-value
cleanup works, and LASTENTRY must never enter the production facade.
