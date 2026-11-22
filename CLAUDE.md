# AGENTS.md — With Compiler

Rules for AI agents in this repo. The With compiler is **self-hosting**:
small mistakes corrupt the stage chain, so strict discipline is required.

---

## Mission

(Summary; canonical: `docs/mission.md`.)

With is an ergonomics-first systems language: close to the machine, native by
default, exactly as safe as Rust, built to remove the suffering. Every
character the program has already determined is a compiler failure if the
programmer still writes it — when one meaning is forced, With infers, imports,
fetches, binds, proves, generates, links, migrates, wraps, or makes it safe;
when two remain, the programmer spells the choice, and that spelling is a
guardrail. Defaults pick representations, never meanings. C interop is
first-class: raw C stays explicit, modeled C becomes humane, and the programmer
never has to become the build system.

Named for the `with` scope: a resource lives in its scope and is released when
the scope ends. Memory is the first resource, proven the same way safety is.
Stricter than Rust: leaking is a defect and must take deliberate, visible
effort.

---
---

## How to read this file

This file is tier one: the rules that win any conflict. Every session reads
all of it. The annex (`docs/agents/`) holds the detail and the case law;
read the annex file for the situation you are in **before** you act in it.

| When you are about to… | Read |
|---|---|
| hunt a bug, or touch drops, ownership, MIR or codegen | `docs/agents/debugging.md` |
| write With code, or design language surface | `docs/agents/language-rulings.md` |
| call something done, or change a check, test or example | `docs/agents/conduct.md` |
| touch `rt/`, `lib/std`, C interop, a text transform or a script | `docs/agents/runtime-and-toolchain.md` |
| build, run a battery, reseed, release, or use another host | `docs/agents/build-seed-release.md` |
| change the spec, bring a decision, or file a bug | `docs/agents/spec-and-decisions.md` |
| edit, commit, stack, or work as an agent in a worktree | `docs/agents/workflow.md` |

## The test before any brief

**Declare the guarantees that must remain stable; infer what can safely
improve the programmer's experience (D172).** Apply it before bringing a
question: if the laws and this test decide it, it is not a ruling. Do the
work and say so in one line.

A question stops for Eric only when it changes what safe code may do,
touches a contract program (UAT fixture, example, published code), or needs
normative spec words. It arrives as a finished brief (what the others do,
what the spec says, mission fit, one committed prediction) while other work
continues. A question that is not C interop, ownership or safety, is easy
to reverse, and has a prediction of 75% or higher is delegated (D98):
implement it, spec words included, and record it in the decision log as
delegated. That is the one case in which an agent lands normative words;
Eric vetoes by revert.

The stop list wins: a question on it is never delegated, even when a law
seems to decide it. Delegated words state a rule the laws already decide;
writing them is not editing the spec to match the code.

## Bugs

- **We own every bug.** Nothing is "pre-existing". Fix it; never defer or
  work around.
- **Root cause means the exact line**: the function, branch and condition
  that produce the wrong state, observed in `lldb` or the debug allocator.
  Dumps, greps and trace prints are hypotheses.
- **Every bug has a route** (`deep-debugging-tools.md`). Name it before the
  first edit. After three rounds of edit, compile, read with no exact line,
  switch tools.
- **A tool that stayed silent is a bug**, fixed or filed with the bug.
- **A build is verification, not experimentation.** State the question a
  build answers before starting it.

## Honesty about the work

- **No silent fallbacks.** When code cannot be generated correctly, fail
  loudly and exit non-zero. Never a placeholder, a stub or a dropped clause.
- **"Done" requires evidence.** The output is correct, noticed edge cases
  have tests, and anything unsolved is filed or fails loudly. Did the work
  make the success condition true, or was the condition redefined?
- **Verify by running, not by reasoning.** Spell it and run it. Enumerate a
  small answer space in one pass.
- **Never weaken a check** to pass it.
- **Never edit a user program to make it pass.** UAT fixtures, `examples/`
  and published code are contracts. A skipped UAT is not green.
- **An application developer never writes `unsafe`.** If a user program
  needs it, the compiler is wrong.
- **Never `git stash`.** Use a worktree.

## The language

- **Don't make the user write what the compiler knows, could figure out, or
  that doesn't matter.** Ceremony is a design defect: stop and raise it,
  never copy it from neighboring code. Defaults pick representations, never
  meanings.
- **The signature states ownership.** `&T` borrows, `T` consumes; a
  parameter's mode is what the callee does with it (D110). Copy or move is
  decided by identity, not representation; `str` is a value (D111).
- **Access observes; `remove` transfers; nothing makes a second owner**
  (D22, D27, D44).
- **One owner per fact (D65).** Sema decides what, MIR where and when,
  codegen how. A later stage never re-derives an earlier stage's answer.
  `FnAbi` is the one source of call ABI.
- **C interop infers only what can at worst reject a valid program.**
  Ownership, destruction, retention and lifetime come from a contract
  clause, a profile or a proof, never from a name (D51).
- **Vale, not Rust, is the reference for ownership.** "Exactly as safe as
  Rust" is a bar, not a compass.

## The specification

- **The spec leads.** A spec change makes the implementation non-compliant
  until it conforms; the spec is never edited to match the code.
- **Only Eric authors or blesses normative words**, the exact words,
  except a delegated decision (D98). Agreement on a direction is not
  approval of wording. Status notes
  ("implemented", "not yet") are the agent's to keep true.
- A disagreement between spec and compiler is a compiler bug or a question
  for Eric, never a quiet workaround.
- Consult the decision log (`docs/meetings/README.md`) before reopening a
  question; record a judgment call there.

## The toolchain

- **Not a line of non-With code**, tooling and one-off scripts included.
  Never `sed`, `awk`, `cut`, `perl` or Python: `with -p`, `with -n`,
  `with -e`, or a With script.
- **Whose action is it? (D171)** A user's action (`with get`, their build,
  a UAT scenario) may use host tools. The compiler, runtime, build and
  corpora may not: they are bootstrapped from our own sources and SDK.
- **Never trust a system LLVM.** We build and embed our own.
- **Always `-O1`, never `-O0`.**
- **User programs use the language and `std.*`.** `with_*` and `rt/` are
  the compiler's own; `@[c_export]` is foreign ABI only.
- **A migrated corpus is never edited and never re-migrated by anything
  routine** (D112, D206). Never take an idiom from one.

## Building and landing

- **The fixpoint holds:** stage2 == stage3. A broken build is the top
  priority.
- **The pinned seed (`seed.lock`) drives the battery**, never the installed
  compiler. A feature the build layer needs raises the seed; the surface is
  never reverted to suit an old one.
- **Never install a compiler from uncommitted or unverified sources.** If
  the seed, the installed compiler and the releases are all broken, the
  compiler cannot be recovered.
- **Tiers.** Per change: `with check`, `with build :dev`, the targeted
  tests. Per layer: `src/main build :gate`. Per stack: one battery
  (`with run tools/battery.with`) on its top commit. Before a seed cut or a
  release: `:release-checks`.
- **Changes land by pull request**; dependent ones are a `gh stack`. A PR
  is a draft until its battery is green. CI is not a merge signal (D56).
- **Other hosts are for platform-specific work only;** when you build
  there, the same rules apply, and leave nothing running.
- **Commits are authored by the human who drove the work.** Never an AI
  author, co-author or trailer.
- One logical change at a time. Re-read a file before editing it after a
  long session.
- **When the path is clear, proceed and report.** A green battery, posted
  on the PR, is the authority to mark it ready and merge; do not ask
  first. It does not replace a ruling.

## The commands every task uses

- **Where:** a worktree under `~/.local/with-staging/`, branched from
  `origin/main`; `with build :seed` once in a fresh one. Repros and
  scratch files never sit in a source directory.
- **Which compiler:** `with` (installed) for `with check`, `with build
  :dev`, `with run`, and every dump, `analyze` and `reduce`;
  `out/bootstrap/bin/with-stage1` (from `:dev`) for source you changed;
  `src/main` (the pinned seed, `WITH=$PWD/src/main`) for `:gate` and the
  battery.
- **Tests:** `test/behavior/behav_*.with` (`//! expect-stdout:`) and
  `test/compile_errors/err_*.with` (`//! expect-check-fail:`); read one of
  the same kind first. Run with `out/bootstrap/bin/with-stage1 test
  <files>`. Show a new test failing before its fix.
- **Results:** read a gate or battery with `with run tools/verdict.with
  <log>`, never by eye.
- **Debugging routes:** `docs/spec/toolchain/deep-debugging-tools.md`.
- **A bug you find is fixed, not filed**; an issue is for what must wait.

## Repository Layout

```
src/        compiler source (.w)        lib/std/   standard library (.w)
rt/         runtime + platform backends  runtime/   platform assembly (fiber_asm_*.s)
test/       test suite                   build.with    build system
out/bin/    compiler binaries            out/lib/   compiled runtime objects
docs/       specifications
```

Source directories must never contain build artifacts.

---

