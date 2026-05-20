# ComptimeEval Audit

Status: P2 pre-Phase-D audit. Source evidence captured before D1.

This audit answers the three ComptimeEval questions in
`docs/pre-phase-d-plan.md`. It is source-level evidence for the Phase D
capability-bearing comptime design.

## Summary

The current evaluator can invoke ordinary comptime functions with ordinary
arguments, including struct values that look like capability handles. It does
not have a compiler-internal capability dispatch path. Current build and
compiler-hook capabilities work by compiling generated runner source into a
native helper binary, setting environment tokens, and letting ordinary With
methods call runtime `extern fn` operations from that binary.

There is no suspension/resume mechanism in the current evaluator. D1 can
proceed only after adding capability-aware evaluator dispatch for method calls.
D4 owns cooperative suspension for the message loop.

## Files Read

- `src/ComptimeEval.w`
- `src/ComptimeValue.w`
- `src/ComptimeTransform.w`
- `src/Sema.w`
- `src/SemaCheck.w`
- `src/MirLower.w`
- `lib/std/build.w`
- `lib/std/compiler.w`
- `src/main.w`
- `src/compiler/Compilation.w`

## Q1: Can ComptimeEval invoke functions with capability-typed parameters?

**Answer: partially.** The evaluator can invoke direct comptime functions with
ordinary values, and capability-shaped structs can be represented as
`ComptimeValueKind.CV_STRUCT`. However, this is only value interpretation; it
does not grant effectful capability behavior.

Evidence:

- `src/ComptimeEval.w:28-48` defines `ComptimeEvaluator` as an interpreter
  with local slots, extra value storage, active function tracking, step budget,
  and diagnostic state. There is no capability table or driver callback state.
- `src/ComptimeEval.w:147-177` constructs an evaluator and runs `eval_root`
  for try/force evaluation. The entry points take `Sema`, `AstPool`, and
  `InternPool`; no driver capability context is passed in.
- `src/ComptimeEval.w:1320-1434` handles direct function calls. It requires a
  direct identifier callee, checks that the symbol is a comptime function,
  evaluates argument expressions, binds each parameter name to a
  `ComptimeValue`, evaluates the function body, and returns the final value.
  The loop at `src/ComptimeEval.w:1385-1405` binds parameters generically; it
  does not inspect parameter type.
- `src/ComptimeValue.w:5-16` includes `CV_STRUCT`, and
  `src/ComptimeValue.w:116-125` defines struct values as a type id plus an
  extra-value range.
- `src/ComptimeEval.w:797-841` evaluates struct literals by resolving the
  struct type, evaluating field expressions, and storing field values into
  `extra_values`. This is enough to represent token-carrying structs in the
  evaluator if sema permits construction.
- `src/ComptimeEval.w:891-913` evaluates field access on `CV_STRUCT` by
  indexing into the struct's extra-value range.

Limitations:

- `src/SemaCheck.w:2860-2872` defines which functions count as comptime.
  `src/ComptimeEval.w:1352-1357` rejects non-comptime functions and generic
  comptime functions. D1 cannot invoke arbitrary `build(ctx)` unless the
  driver marks or treats it as a capability-bearing comptime entry point.
- `src/SemaCheck.w:101-123` recognizes current tool capability types by stdlib
  path and hardcoded type names, then rejects ordinary struct literal
  construction unless the current module can access tool internals.
- `src/SemaCheck.w:3671-3682` applies that construction rejection to struct
  literals. So user code cannot simply create a `BuildCtx`/`ActionCtx` value
  for evaluator testing without driver privilege.
- `src/SemaCheck.w:6859-6862` rejects direct calls to `Type.__driver_new` for
  tool capability types outside driver-visible code.

Concrete extension plan:

- D1 must add a driver entry for capability-bearing comptime calls. That entry
  should create `ComptimeValue` handles for driver-minted capabilities and bind
  them to capability parameters exactly like ordinary parameters are bound at
  `src/ComptimeEval.w:1385-1405`.
- Sema must treat `pub fn build(ctx: BuildCtx) -> Build` and action functions
  as driver-invoked capability-bearing comptime entry points even if explicit
  `comptime fn` syntax is not present yet.
- Capability construction remains forbidden to user code. The driver mints
  capability values directly in evaluator state rather than routing through
  public struct literals.

Slice ownership:

- D1 owns driver invocation of capability-bearing comptime functions.
- D1 owns evaluator representation of driver-minted capability values.

## Q2: Can the evaluator dispatch effectful operations from inside evaluation?

**Answer: no, not for tool capabilities.** The current evaluator has a few
hardcoded effectful-ish comptime operations such as `embed_file`, but current
tool capability operations execute through generated native runner binaries.

Evidence for evaluator-native special cases:

- `src/ComptimeEval.w:753-759` handles `src()` directly inside the evaluator.
- `src/ComptimeEval.w:761-773` handles `embed_file()` directly inside the
  evaluator by calling `with_fs_file_exists` and `with_fs_read_file`, declared
  at `src/ComptimeEval.w:9-10`.
- `src/ComptimeEval.w:487-683` hardcodes known comptime collection operations
  for `Vec` and `HashMap`.
- `src/ComptimeEval.w:1323-1344` method-call evaluation dispatches only static
  type methods, `Vec` methods, and `HashMap` methods. Any other receiver method
  fails with `"method '...' is not comptime-evaluable yet"`.

Evidence for current tool-capability native-runner path:

- `lib/std/build.w:166-184` validates capabilities using
  `WITH_TOOL_CAPABILITY_TOKEN` and constructs `BuildCtx` in
  `BuildCtx.__driver_new`.
- `lib/std/build.w:186-208` implements `BuildCtx` capability methods as
  ordinary With methods that validate the token and return stored fields.
- `lib/std/build.w:528-560` implements `ActionCtx` methods the same way.
- `src/main.w:774-785` generates With source for a build runner. That source
  imports `std.build`, calls `BuildCtx.__driver_new`, calls `build(ctx)`, and
  either emits the graph or runs one action.
- `src/main.w:802-871` implements action execution by writing generated runner
  source, compiling it to a binary, setting `WITH_TOOL_CAPABILITY_TOKEN` and
  `WITH_BUILD_ACTION_NAME`, executing the binary with capture, replaying
  output, and validating declared outputs.
- `src/main.w:873-910` uses the same generated-runner pattern for build graph
  construction.
- `lib/std/compiler.w:78-92` validates compiler-hook capabilities with
  `WITH_TOOL_CAPABILITY_TOKEN` and constructs `Diagnostics`/`SourceEmitter`
  through `.__driver_new`.
- `src/compiler/Compilation.w:499-529` generates compiler-hook runner source
  that calls hook functions with constructed capability values.
- `src/compiler/Compilation.w:555-610` writes, compiles, and executes the
  compiler-hook runner binary, then reads diagnostics and emitted source from
  capture files.

Conclusion:

`ctx.fs().read_text(path)` cannot be made effectful by the current evaluator.
If evaluated today, it would enter `ComptimeEvaluator.eval_call`; because the
callee is a field access, non-Vec/non-HashMap receivers hit
`src/ComptimeEval.w:1344` and fail as not comptime-evaluable. The current
working path is native execution of generated runner code, where `ToolFs`
methods call runtime `extern fn` functions from `lib/std/build.w`.

Concrete extension plan:

- D1 must introduce capability method declarations that sema can identify and
  the evaluator can route to compiler-internal handlers.
- The evaluator needs a dispatch table keyed by capability type and method
  name. The dispatch point is `src/ComptimeEval.w:1323-1344`, before the
  generic "method is not comptime-evaluable" failure.
- Capability methods should not execute their With bodies in D1. Their public
  declarations should be intrinsic stubs or compiler-recognized declarations;
  the compiler-internal dispatch handler performs the effect.
- Token validation must move from environment-variable checks in generated
  native runners to driver-owned capability handles validated by each
  dispatcher call.

Slice ownership:

- D1 owns capability dispatch and the replacement of generated build/action
  runners.
- Compiler hooks may initially continue using the runner path unless D1's
  final scope explicitly includes them; the same dispatch mechanism should
  support hooks when they move in-process.

## Q3: Can the evaluator suspend and resume with a caller-provided value?

**Answer: no.** The evaluator is currently a recursive interpreter that runs a
call to completion and returns a `ComptimeControl`. It has no yield state,
continuation object, or caller-provided resume value.

Evidence:

- `src/ComptimeEval.w:15-20` defines the complete control kinds:
  value, return, break, continue, and error. There is no suspended/yielded
  control state.
- `src/ComptimeEval.w:179-191` runs `eval_expr` to completion in `eval_root`
  and converts escaped control flow into errors.
- `src/ComptimeEval.w:206-213` has a step budget, but the only behavior on
  exhaustion is an error. It is not a cooperative yield mechanism.
- `src/ComptimeEval.w:1485-1552` dispatches expression evaluation
  recursively. No case returns a resumable continuation.
- `src/SemaCheck.w:1904-1908` rejects `await` inside comptime.
- `src/SemaCheck.w:1944-1946` rejects `async` inside comptime.
- `src/SemaCheck.w:1964-1966` rejects `spawn` inside comptime.
- `src/SemaCheck.w:1973-1975` rejects `yield` inside comptime.
- `src/ComptimeTransform.w:919-930` force-evaluates a comptime expression and
  immediately materializes the resulting value back into AST. That transform
  assumes evaluation terminates with a value or error.
- `src/MirLower.w:5812-5818` treats `NK_COMPTIME` as already transformed or
  unwraps the inner expression; MIR lowering does not preserve a resumable
  comptime frame.

Concrete extension plan:

- D4, not D1, owns cooperative suspension. D1-D3 can run capability-bearing
  calls to completion.
- D4 must introduce an explicit evaluator state object or equivalent
  continuation representation. Recursive call frames, current AST node,
  local slots, scope stack, active function stack, and pending receiver/method
  call state must become resumable data.
- `Workspace.wait_for_message` is the first suspension point. If a workspace
  message is available, its dispatcher returns immediately. If no message is
  available and interception is active, the dispatcher returns a suspended
  evaluator state to the driver.
- Resume feeds a `CompilerMessage` value back into the suspended call and
  continues evaluation until the next suspension, completion, or error.
- Sema can continue rejecting language-level `yield`, `await`, `async`, and
  `spawn` in comptime. Message-loop suspension is an evaluator capability
  intrinsic, not user-level generator syntax.

Slice ownership:

- D4 owns evaluator suspension and resume.
- D4 also owns incomplete-interception errors, because the driver can detect a
  returned evaluator state or returned function while a workspace intercept is
  still active.

## D1 Readiness

D1 cannot proceed with the current evaluator unchanged. It requires:

1. Driver entry points for capability-bearing comptime functions.
2. Driver-minted capability `ComptimeValue` handles.
3. Sema recognition of capability-bearing comptime entry points.
4. Capability method declarations and a compiler-internal dispatch table.
5. Evaluator dispatch from capability method calls to native compiler
   handlers.

D1 does not require:

- cooperative suspension;
- message-loop APIs;
- parallel workspaces;
- generated-source generations;
- native compilation of comptime functions.

Those belong to later D slices as described above.
