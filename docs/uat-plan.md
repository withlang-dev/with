# UAT plan — scenarios a person can read, a runner that executes them

Status: PLAN (2026-09-25, Eric: "if I was gonna write UATs by hand, no AI,
it'd be with some set of verbs and nouns"). Replaces the hand-coded actions
in `build/release_uat.w` with scenario files plus a small interpreter.
Sequenced after the libcurl campaign (the last `:user-programs-safe` red)
and before, or alongside, STC phase 3; it is build-layer + tooling work and
batches freely.

## 1. What is wrong with what we have

`build/release_uat.w` is a **runner** with the scenarios baked into it:
nine `run_release_<x>_uat_action(ctx) -> i32` functions, each an imperative
script (prepare a dir, spawn the compiler, capture, `ruat_expect_*`, return
1 at the first miss), a third of it path/argv plumbing. What a UAT is for —
"a user does these things and sees this" — exists only as the call sequence,
so:

- the promise cannot be reviewed apart from the mechanism, and coverage
  cannot be enumerated without reading With;
- steps are not shared (the C-package cases were factored into
  `ruat_run_c_package_uat`, the rest re-implement "fresh project → get →
  build → run → compare");
- policy hides in helpers (copying `lib/facades/<lib>.w` into the fresh
  project as `src/facades/<lib>.w`, §16.2b.1, is a language rule living in
  test code);
- a missing precondition (no OpenGL on the macOS runner, #1375; no network)
  reads as a failure, not as "not applicable here";
- the human expectation ("colored balls moving on a field of black") has no
  home, so the raylib UAT asserts only "exited 0".

What is right and is kept: end-to-end against the release binary in a fresh
directory with a real package fetch; exact captured output; the fixture
programs as contracts (the `unsafe` gate, "never edit a UAT to go green");
gating on last-green; the process/capture code.

## 2. The scenario format

One file per scenario, plain text, one step per line, `#` comments. The
verbs are the ones a person writes by hand; there is no Given/When/Then
ceremony.

```
scenario: sqlite3 from a fresh project
requires: network, lib sqlite3
platforms: darwin, linux, windows

new directory
run: with init
run: with get c.sqlite3@3.53.4
write src/main.w from fixtures/sqlite3_main.w
copy facade sqlite3                     # §16.2b.1: the project's own until the package ships it
run: with run
expect exit: 0
expect stdout: sqlite3 UAT passed
```

```
scenario: raylib spiral
requires: display, opengl
platforms: darwin, linux, windows

new directory
run: with init
run: with get c.raylib
write src/main.w from fixtures/raylib_spiral_main.w
run: with run -- --frames 60 --capture frame.png
expect exit: 0
expect image: frame.png ~ fixtures/raylib_spiral_frame.png
expect (human): colored balls moving on a field of black
```

Grammar (whole thing):

```
FILE      := HEADER STEP*
HEADER    := 'scenario:' TEXT NL ('requires:' NAME (',' NAME)* NL)? ('platforms:' NAME (',' NAME)* NL)?
STEP      := 'new directory' NL
           | 'run:' COMMAND NL                        # argv; `with` = the release binary under test
           | 'run (fails):' COMMAND NL                # the command is expected to exit non-zero
           | 'write' PATH 'from' FIXTURE NL           # copies uat/fixtures/<FIXTURE> into the project
           | 'write' PATH ':' NL INDENTED_BLOCK        # inline text (docs, config; not programs — see §4)
           | 'copy facade' NAME NL                     # lib/facades/<NAME>.w -> src/facades/<NAME>.w
           | 'env' NAME '=' TEXT NL
           | 'stdin:' NL INDENTED_BLOCK                # for the next `run:`
           | 'expect exit:' INT NL
           | 'expect stdout:' TEXT NL                  # exact, trailing line endings trimmed
           | 'expect stdout contains:' TEXT NL
           | 'expect stderr contains:' TEXT NL
           | 'expect file' PATH 'contains:' TEXT NL
           | 'expect file' PATH 'exists' NL
           | 'expect image:' PATH '~' FIXTURE NL       # similarity against a reference image (§5)
           | 'expect (human):' TEXT NL                 # recorded, printed to the release checklist, never executed
```

`requires:` names come from a fixed vocabulary the runner can probe:
`network`, `display`, `opengl`, `lib <name>` (pkg-config / a link probe),
`tool <name>` (on PATH), `env <NAME>`. An unmet requirement makes the
scenario **skipped with the reason**, a verdict distinct from pass/fail.
`platforms:` restricts where it runs at all.

## 3. The runner

`build/uat.w` (With, build layer): a parser for the grammar above, an
interpreter, a report. Steps map onto the existing process/capture helpers
in `release_uat.w` (`ruat_run_capture_cwd`, `ruat_expect_*`), which move to
`build/uat.w` as the step library; the nine actions are deleted once their
scenarios pass (§7). Each `run:` writes `stdout`/`stderr` capture files under
`out/uat/<scenario>/<step-N>.{stdout,stderr}`, exactly as today's labels do.

The report is per scenario × step:

```
uat: sqlite3 from a fresh project ............ pass  (7 steps, 4.1s)
uat: raylib spiral ............................ skip  (requires display: none)
uat: libcurl from a fresh project ............. FAIL  step 6 `run: with run`: exit 1
        stderr: error: ...                      (out/uat/libcurl/step-6.stderr)
uat: 8 scenarios: 6 pass, 1 skip, 1 FAIL; 2 human checks recorded (see below)
human checks for the release host:
  raylib spiral: colored balls moving on a field of black
```

Skips are listed with their reason in the release runbook's output; a
scenario that is skipped everywhere is a lane bug, not a pass.

## 4. Files and the contract rule

```
uat/
  README.md                 the grammar (§2) and the verbs' meaning
  *.uat                     scenarios
  fixtures/*.w              user programs — the contracts (moved from build/release_uat_fixtures/)
  fixtures/*.png            reference images
```

`uat/fixtures/*.w` keep every rule `build/release_uat_fixtures/` has today:
they are what an application developer writes; no `unsafe`; a spec change
updates them in the same change and says so; a compiler/stdlib change that
breaks one is a defect in the change. `with build :user-programs-safe`
re-points its input to `uat/fixtures` (and `examples/`). Programs are
referenced from scenarios, never inlined, so those gates stay mechanical
and the program stays a normal `.w` file that `with check` and the migrator
see. Inline `write … :` blocks are for non-program files (a `with.toml`
line, a data file).

`copy facade <name>` is a verb precisely so the policy is a visible line in
the scenario; when packages ship facades (§16.2b.8, B.8) the line is deleted
from the scenarios and nothing else changes.

## 5. Human and visual expectations

`expect (human):` is not executable. It is recorded: the runner prints every
human check of every scenario that ran on this host into the report and
into `out/uat/human-checks.txt`, and `docs/with-release-runbook.md` requires
the release host to walk that list. It exists so the promise "colored balls
moving on a field of black" is written where the scenario is, not in a
runbook paragraph nobody diffs against the test.

`expect image:` is the mechanical proxy for the same promise where one is
possible: the program is run with a capture flag it supports (the spiral
gets `--frames N --capture PATH`, written into the fixture program as a
normal option — it is what a developer would add to make their own program
testable), and the runner compares against a reference image with a
tolerance (mean absolute pixel difference under a threshold; the comparison
is With over the PNG decoder already in `std`). A first version may support
only exact size + threshold; a reference image is regenerated deliberately
by a documented command, never by the runner.

## 6. build.w wiring

One action target `uat` (kept name: `release-uat`, so the runbook, the
`package-<platform>` dependency and CI lanes do not change) whose action
parses every `uat/*.uat`, runs those applicable on the host, and writes
`out/release-uat/<scenario>.passed` / `.skipped` outputs plus the report.
Inputs: the release binary, `uat/`, `lib/facades/`. Per-scenario targets are
not needed — the graph cache keys on the inputs; the action prints per-
scenario timing. `WITH_UAT_ONLY=<scenario>` runs one. The `require-last-green`
gate stays.

## 7. Migration (one batch, one battery)

| today's action | scenario file |
|---|---|
| `release-artifact-smoke-uat` | `uat/artifact_smoke.uat` (run the platform-named binary, `--version`, a one-liner) |
| `release-fresh-project-uat` | `uat/fresh_project.uat` |
| `release-migrate-uat` | `uat/migrate_c.uat` (write a tiny C source, `with migrate`, build, run) |
| `release-zlib-uat`, `-bzip2-`, `-sqlite3-`, `-libcurl-` | `uat/zlib.uat`, `uat/bzip2.uat`, `uat/sqlite3.uat`, `uat/libcurl.uat` |
| `release-install-layout-uat` | `uat/install_layout.uat` (`expect file … exists` lines) |
| `release-raylib-spiral-uat` | `uat/raylib_spiral.uat` with `requires: display, opengl` and the human line |
| `release-one-liner-uat` | `uat/one_liners.uat` (`stdin:` blocks + `run: with -n …`) |

Order: (1) `build/uat.w` parser + interpreter + report with the step library
moved from `release_uat.w`; (2) the nine scenario files, byte-for-byte the
same expectations as today; (3) `build.w` re-wired, `release_uat.w` deleted,
`build/release_uat_fixtures` moved to `uat/fixtures`, `user-programs-safe`
input re-pointed; (4) runbook updated (human checks, skips); (5) `expect
image:` for the spiral — separate PR, needs the capture flag in the fixture
program under the "spec change updates the example" rule (it is a program
change, so it says so in the commit). One audited battery for (1)–(4);
`:release-uat` itself is the acceptance.

## 8. Acceptance

- `uat/README.md` grammar; every scenario in `uat/` parses; a planted bad
  scenario is a parse error naming the line.
- `with build :release-uat` runs the nine scenarios with the same verdicts
  as before the migration on the release host, and on the macOS CI runner
  reports `raylib spiral: skip (requires display: none)` instead of red
  (#1375 closes).
- The report lists scenarios × verdicts and the human checks; the runbook
  points at it.
- `build/release_uat.w` is gone; no scenario logic lives in With outside
  the step library.
- `:user-programs-safe` is green over `uat/fixtures` + `examples`.

## 9. Not in this plan

Property-style or randomized UATs; running UATs against an installed
`with` other than the release binary under test; a Windows-specific verb
set (the runner's platform probes cover `.exe` suffix and the
`WITH_UAT_OPENGL32_DLL` placement the spiral needs, as environment, not
verbs); Gherkin compatibility.
