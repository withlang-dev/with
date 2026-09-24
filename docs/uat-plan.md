# UAT plan — `with uat`: scenarios a person writes, a runner every project has

Status: PLAN (2026-09-25; Eric: "if I was gonna write UATs by hand, no AI,
it'd be with some set of verbs and nouns" … "make sure it's written in a
way that users can use too … `with init` should set up their project with
an example UAT"). This is a **product feature of the toolchain**, not a
compiler-repo test harness: `with uat` runs a project's acceptance
scenarios the same way `with test` runs its tests, and `with init` creates
one. The With compiler's own release UATs (today `build/release_uat.w`) are
just the first user of it. Sequenced after the libcurl campaign; tooling +
build-layer work, batches freely; the spec words in §8 need Eric's
blessing before the command lands (CLI commands are inventoried, §18.5).

## 1. What a user gets

```
my-app/
  with.toml
  src/main.w
  test/main_test.w          # unit tests: with test
  uat/
    README.md               # the verbs, one page
    hello.uat               # the scenario `with init` wrote
    fixtures/               # files a scenario writes into the project, reference images
```

```
$ with uat
uat: hello ....................................... pass  (4 steps, 0.8s)
uat: 1 scenario: 1 pass
```

A scenario is what a person does at a terminal and what they expect to see,
one step per line. There is no framework vocabulary to learn beyond the
verbs, no Given/When/Then, no step-definition code: the verbs are the
runner's.

## 2. The scenario written by `with init`

`uat/hello.uat`:

```
scenario: the program prints its greeting

run: with build
run: ./out/bin/my-app
expect exit: 0
expect stdout: Hello, world!
```

`uat/README.md` (also written by `with init`) is the one-page grammar of §3
with three worked examples: this one, one with `stdin:`, and one with
`expect (human):`. `with init` puts the app's own name into the `run:` line.

## 3. The format

One file per scenario in `uat/`, plain text, one step per line, `#`
comments. Every line is a verb a person would say.

```
scenario: sqlite3 from a fresh project
requires: network, lib sqlite3
platforms: darwin, linux, windows

new directory
run: with init
run: with get c.sqlite3@3.53.4
write src/main.w from fixtures/sqlite3_main.w
run: with run
expect exit: 0
expect stdout: sqlite3 UAT passed
```

```
scenario: spiral
requires: display, opengl

run: with run -- --frames 60 --capture out/frame.png
expect exit: 0
expect image: out/frame.png ~ fixtures/spiral_frame.png
expect (human): colored balls moving on a field of black
```

Grammar, complete:

```
FILE      := HEADER STEP*
HEADER    := 'scenario:' TEXT NL
             ('requires:' REQ (',' REQ)* NL)?
             ('platforms:' NAME (',' NAME)* NL)?
REQ       := 'network' | 'display' | 'opengl' | 'lib' NAME | 'tool' NAME | 'env' NAME
STEP      := 'new directory' NL                      # a fresh temp directory becomes the cwd
           | 'run:' COMMAND NL                       # argv; exit 0 expected unless `run (fails):`
           | 'run (fails):' COMMAND NL
           | 'write' PATH 'from' FIXTURE NL          # copy uat/fixtures/<FIXTURE> to PATH
           | 'write' PATH ':' NL INDENTED_BLOCK       # inline text (config, data)
           | 'copy' PATH 'to' PATH NL
           | 'env' NAME '=' TEXT NL                  # for the rest of the scenario
           | 'stdin:' NL INDENTED_BLOCK               # for the next `run:`
           | 'expect exit:' INT NL
           | 'expect stdout:' TEXT NL                 # exact, trailing line endings trimmed
           | 'expect stdout contains:' TEXT NL
           | 'expect stderr contains:' TEXT NL
           | 'expect file' PATH 'exists' NL
           | 'expect file' PATH 'contains:' TEXT NL
           | 'expect image:' PATH '~' FIXTURE NL      # similarity to a reference image (§5)
           | 'expect (human):' TEXT NL                # recorded and reported, never executed
```

Semantics that matter:

- The cwd starts as the project root; `new directory` moves it to a fresh
  temporary directory (deleted on pass, kept and named in the report on
  fail). `with` in a `run:` line is the running toolchain binary (so the
  compiler's own release UATs can point it at the release artifact with
  `WITH_UAT_WITH=<path>`; a user never needs that).
- An `expect` applies to the most recent `run:`. Expectations are exact
  unless the verb says `contains`; output is compared after trimming
  trailing line endings, the same rule `with test` uses.
- `requires:` names things the runner can probe. An unmet requirement makes
  the scenario **skipped, with the reason** — a third verdict beside pass
  and fail, printed in the report. `platforms:` restricts where a scenario
  runs at all. A scenario skipped on every host it is asked to run on is
  reported as such (a suite where everything skips is not green).
- `expect (human):` is never executed; §5.

## 4. `with uat` — the command

```
with uat                       # every uat/*.uat applicable on this host
with uat <name>                # one scenario (file stem)
with uat --list                # scenarios, their requires/platforms, and whether they apply here
with uat --keep                # keep the temporary directories of passing scenarios too
```

Exit status: 0 when nothing failed (skips do not fail); the report goes to
stdout; captures to `out/uat/<scenario>/step-<N>.{stdout,stderr}`; the
human checks to `out/uat/human-checks.txt`. Report shape:

```
uat: sqlite3 from a fresh project ............ pass  (7 steps, 4.1s)
uat: spiral ................................... skip  (requires display: none)
uat: libcurl from a fresh project ............. FAIL  step 6 `run: with run`: exit 1
        stderr: error: …                        (out/uat/libcurl/step-6.stderr)
uat: 3 scenarios: 1 pass, 1 skip, 1 FAIL; 1 human check recorded
human checks for this host:
  spiral: colored balls moving on a field of black
```

Implementation: `src/Uat.w` in the compiler (the parser, the interpreter,
the report), `with uat` dispatched like `with test`; the step library is
the process/capture code that `build/release_uat.w` has today, moved into
the compiler so users get it. The build layer's `:release-uat` target calls
the same code (§7); nothing about UATs lives in `build/` afterwards.

## 5. Human and visual expectations

`expect (human):` records a promise the machine cannot check and prints it
wherever the scenario ran — on a developer's terminal, in CI logs, and on
the release host's checklist — so "colored balls moving on a field of
black" is written next to the steps that produce it, not in a runbook
paragraph nobody diffs against the test. It never passes or fails.

`expect image:` is the mechanical proxy where the program can capture a
frame (a normal `--capture PATH` option the developer adds to their own
program): the runner decodes both PNGs (`std` has the decoder) and passes
when sizes match and the mean absolute pixel difference is under a
tolerance (default 2%; `~` may be followed by `within N%`). Reference
images are regenerated by a deliberate `with uat --record-images <name>`,
never by a normal run.

## 6. The compiler's own UATs

`uat/` at the repo root holds the nine scenarios that replace
`build/release_uat.w` (table below) and `uat/fixtures/` holds what
`build/release_uat_fixtures/` holds today, with every rule those files have:
they are what an application developer writes, no `unsafe`, a spec change
updates them in the same change and says so, a compiler or stdlib change
that breaks one is a defect in the change; `with build :user-programs-safe`
re-points to `uat/fixtures` + `examples`. Programs are referenced from
scenarios, never inlined, so those gates stay mechanical. The release-only
policy step "copy `lib/facades/<lib>.w` into the fresh project as
`src/facades/<lib>.w`" (§16.2b.1, until packages ship facades) becomes a
visible `copy lib/facades/sqlite3.w to src/facades/sqlite3.w` line that is
deleted when B.8 lands.

| today's action | scenario |
|---|---|
| `release-artifact-smoke-uat` | `uat/artifact_smoke.uat` |
| `release-fresh-project-uat` | `uat/fresh_project.uat` |
| `release-migrate-uat` | `uat/migrate_c.uat` |
| `release-zlib-uat` / `-bzip2-` / `-sqlite3-` / `-libcurl-` | `uat/zlib.uat`, `bzip2.uat`, `sqlite3.uat`, `libcurl.uat` |
| `release-install-layout-uat` | `uat/install_layout.uat` |
| `release-raylib-spiral-uat` | `uat/raylib_spiral.uat` (`requires: display, opengl`, the human line) |
| `release-one-liner-uat` | `uat/one_liners.uat` (`stdin:` blocks) |

## 7. build.w wiring

One action target, still named `release-uat` (the runbook, the
`package-<platform>` dependency and the CI lanes do not change), whose
action runs `with uat` from the repo root with `WITH_UAT_WITH=<release
binary>` and writes `out/release-uat/<scenario>.passed|.skipped` plus the
report; inputs: the release binary, `uat/`, `lib/facades/`. The
`require-last-green` gate stays. The macOS CI runner then reports
`raylib_spiral: skip (requires display: none)` instead of red — #1375
closes at the right layer.

## 8. Spec words (for Eric's blessing; §18.5 and §18.8)

§18.5 toolchain list, one line:

```
with uat [<scenario>]                        # run the project's acceptance scenarios (uat/*.uat)
```

§18.8 command table: `with init` row becomes "Create new project with
`with.toml`, `src/main.w`, `test/`, and `uat/hello.uat` (§18.5d)".

New §18.5d, proposed text:

> **18.5d Acceptance scenarios.** A project's `uat/` directory holds
> acceptance scenarios: plain-text files, one per scenario, each a header
> (`scenario:`, optional `requires:` and `platforms:`) followed by steps a
> person would perform at a terminal — `new directory`, `run:`, `write …
> from …`, `stdin:`, `env`, and `expect …` lines for the exit status, output,
> files and images. `with uat` runs every scenario that applies on the host,
> skips with a reason the ones whose `requires:` are unmet, and reports one
> verdict per scenario and one line per failed step. `expect (human):`
> records a check a person performs; the runner prints it and never fails
> it. Programs a scenario writes into the project come from `uat/fixtures/`
> and are ordinary source files. `with init` writes `uat/hello.uat` and
> `uat/README.md`.

## 9. Order of work (one batch, one battery)

1. `src/Uat.w`: parser, interpreter, report; `with uat`, `--list`, `--keep`,
   `WITH_UAT_WITH`; `requires:` probes; tests under `test/uat/` (planted
   scenario files: one per verb, one per verdict, a parse error naming the
   line).
2. `with init` writes `uat/hello.uat` and `uat/README.md` (the templates
   generated the way `src/InitTemplates.w` is, so the README is the same
   text as this plan's §3); `cli-selfhost-project-tests` asserts the
   scaffold runs green under `with uat`.
3. Spec words (§8) landed once blessed; `spec-inventory-check` row.
4. The nine scenarios, byte-for-byte the same expectations as today;
   `build/release_uat_fixtures` → `uat/fixtures`; `:release-uat` re-wired;
   `build/release_uat.w` deleted; `user-programs-safe` re-pointed; runbook
   updated (skips, human checks).
5. `expect image:` and the spiral's `--capture` option — separate PR under
   the "spec change updates the example" rule.

## 10. Acceptance

- A fresh `with init` project runs `with uat` green with the scaffolded
  scenario; `with uat --list` shows it.
- `test/uat/` covers every verb and verdict; a bad scenario fails to parse
  with the line named.
- `with build :release-uat` yields the same verdicts as before the
  migration on the release host, and `skip (requires display: none)` on the
  macOS runner.
- `build/release_uat.w` is gone; no scenario logic lives in the build layer.
- `:user-programs-safe` green over `uat/fixtures` + `examples`.

## 11. Not in this plan

Gherkin compatibility; property/randomized scenarios; a step-definition
plugin API (the verbs are the runner's — a project that needs a new verb
files an issue, the way it would for `with test`); Windows-specific verbs
(the runner's platform probes cover the `.exe` suffix and the
`WITH_UAT_OPENGL32_DLL` placement as environment).
