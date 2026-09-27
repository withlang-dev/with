# D66 retained variadic pairs (#1652): implementation notes

Execution notes, subordinate to D51, the D66 amendments in the specification
(§16.2b.5, §16.2b.9) and the decision log. This file grants no
foreign-library facts.

## The ruling, in one paragraph

A callback case of a variadic contract states its C type (`as T`), names the
selector carrying its userdata (`userdata param CONST`) and states its
retention (`retains by param 0`, never inferred); the userdata setter is
implied by the pairing and takes `&U`, the borrow the resource then holds.
`ok CONST` on the variadic operation is the setters' status contract:
presentation unchanged, the compiler reads a comparison of the returned code
against it as the setter's success or failure edge. A resource names its safe
abandonment path with `abandon <op>`; the op must itself be `callbacks none`,
and the rendered Drop runs it before the destroyer. Every callback-capable
operation (anything not `callbacks none`, including the other cases of the
same setter) is refused where the pair is not proven compatible; a retained
userdata cannot die or move while held; a retaining resource cannot be
returned or stored.

## Owners of facts (D65)

- **Parser** records the case's callback type, paired selector and retaining
  parameter, and the `abandon` clause (Ast.w FACADE_CLAUSE_VARIADIC_CASE,
  FACADE_CLAUSE_ABANDON).
- **Sema** resolves a case into a `ForeignVariadicSlot` (resource, retaining
  parameter, C callable, its one `void *` position, the paired selector and
  its value), implies the userdata case, verifies `abandon` (own operation,
  one parameter, `callbacks none`), accepts `ok` on a variadic operation, and
  registers a `FacadePairOp` for every operation of a resource with a pair
  under the concrete signature MIR records on the call
  (`facade_index_pair_ops`; setters per specialization through
  `facade_note_pair_op_sig`, with the `U` read off the specialized
  signature). A callback-only setter binds `U` from the callback argument's
  own signature (`facade_bind_pair_callback_u`).
- **Renderer** emits `mut fn <base>__<CB>[U](…, value: <typed callback>)`
  and `mut fn <base>__<UD>[U](…, value: &U)`, and a Drop that runs the
  abandonment path before the destroyer (compiler/FacadeRender.w).
- **MIR** (`MirForeignPairs.w`, after lowering, before codegen) runs the
  `ForeignPairState.w` place flow over each body: `APPLY` at the receiver of
  every pair operation, `BORROW`/`MOVE` for references and moves of the
  resource, `EXPIRE` where a retained origin dies or moves, `ESCAPE` where a
  resource moves into the return place, a projection or an aggregate,
  `DESTROY` at drops (callback-capable unless `abandon` or a `callbacks none`
  drop), `UNKNOWN` after an unmodeled call that receives the resource. A
  `status == OK` / `status != OK` branch on a setter's result refines its
  success edge. Violations become diagnostics at the call or statement.
- **Codegen** transports the values the setters already selected.

## What the flow does not model (conservatively refused, not unsound)

- Helper calls: a call the facade does not describe that receives the
  resource is checked as callback-capable and leaves the pair `UNKNOWN`
  until a modeled reset. Interprocedural summaries are a later phase.
- Closure arguments to a callback setter: `U` is bound from a named fn's
  signature; a closure literal has no parameter types to bind from without
  an expected type. Pass a named fn (the tally idiom).
- A retained pointer case (`<type> retains by param N`, curl's
  CURLOPT_POSTFIELDS) stays refused: the caller's storage would have to
  outlive the resource as a C string (§16.3c).
- Reading a chunk's bytes inside a write callback: the `char *` parameter
  stays raw until a callback buffer clause is ruled; counts are safe today.

## Foreign evidence recorded in lib/facades/libcurl.w

`curl_easy_setopt` is `callbacks none` (no listed option's page describes a
callback, and a transfer starts only at `curl_easy_perform`), `ok CURLE_OK`.
`curl_easy_reset` is the abandonment path, `callbacks none` bounded to the
modeled option set: libcurl's reset frees MIME parts through their
`freefunc` (`easy.c` → `Curl_freeset` → `Curl_mime_cleanpart`), an option
this facade does not list; a MIME case must revisit that line.
`curl_easy_cleanup` is never `callbacks none` (it may invoke progress and
header callbacks while closing connections).

## Tests

- `test/behavior/behav_libcurl_facade_callback_pair.w`: the pair over the real
  library, a `file://` transfer driving the callback (no network).
- `test/behavior/behav_libcurl_facade_callback_pair_failure.w`: the required
  acceptance case with the real variadic ABI — first setter succeeds, the
  second fails (a test facade pairs the callback with `CURLOPT_LASTENTRY`),
  the function returns an error, Drop resets then cleans up.
- `test/behavior/behav_c_facade_variadic_callback_pair_check.w`: accepted
  shapes over a declared setter (either order, reset between runs, a helper
  handed a proven pair, a sink read between the setter and the run).
- `test/compile_errors/err_c_facade_variadic_callback_*.w`,
  `err_c_facade_abandon_invokes.w`: the refusals.
- `test/internals/foreign_pair_*_test.w`: the abstract domain.
