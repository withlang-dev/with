# D234 — A `main` that declares a `Result` and returns an `Err` ends the program as `?` in main does (delegated)

**Laws:** 7 (fail loudly or do the work; never produce a plausible wrong
thing: an exit status of 0 for a program that returned an error is one).

**Date:** 2026-11-24. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Found under:** #3128.

**Context.** §10.2 (D190) says what an `Err` that `?` meets in a `main` with
no declared return type does: the error's `Debug` form after `error: ` on
stderr, exit status 1. It says nothing of a `main` that declares
`-> Result[T, E]`, which the compiler accepts and `examples/nebula` uses
(`async fn main -> Result[Unit, AppError]`). Measured on main a784b4222:

- `fn main -> Result[Unit, i32]: Err(3)` built, printed nothing and exited
  with status 0: the entry wrapper discarded the value.
- `fn main -> Result[Unit, str]: …` (a `Result` returned through a
  caller-provided slot) failed in code generation: "main must take either
  zero parameters or argc/argv" over invalid LLVM.

**Decision.** A `main` that declares `-> Result[T, E]` and returns an `Err`
ends the program exactly as D190's `?` does: the error's `Debug` form after
`error: ` on stderr, exit status 1. Its defers and drops run first, since
it is a return. An `Ok` exits with status 0 and its payload is discarded.
The same holds for `async fn main`. A `?` inside such a `main` propagates
by the ordinary rule and meets the same end at the return.

**Why delegated.** Not C interop, ownership or safety; a revert restores
the old behaviour; and the laws leave one meaning: an `Err` reaching the
end of the program is the program's failure, and D190 already fixed how a
program reports one. Prediction that Eric would rule this way: 90%.

**Not decided here.** What other declared return types of `main` mean
(`-> Option[T]` is accepted and its value discarded; `-> i32` is the exit
status). That is a separate question for Eric.

**Implementation.** `MirBuilder.emit_main_result_return_check` (before each
return of `main`), `Codegen.main_sret_type` (the entry wrapper provides the
return slot). Tests: `behav_main_returns_err`, `behav_main_returns_ok`,
`behav_main_returns_small_err`, `behav_async_main_returns_err`.
