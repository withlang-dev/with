# `with test` — Test Subcommand Design

Similar to `go test`. Backed by `lib/test` (Unity adapter).

---

## What It Does

`with test` compiles the current package with test
instrumentation, links against Unity, runs the resulting
binary, and reports results. The test binary is temporary
and discarded after the run.

```
$ with test
PASS
ok      my-project    0.034s
```

That's the normal output. One line per package. If everything
passes, you see almost nothing. Like Go.

---

## How It Works

```
1. Scan all .w files in the package for @[test], @[before], @[after]
2. Generate a test main:
   - Calls UnityBegin()
   - Calls UnityDefaultTestRun() for each @[test] function
   - Maps @[before] → setUp, @[after] → tearDown
   - Calls UnityEnd()
3. Compile the package + generated main + Unity (cdep)
4. Run the resulting binary
5. Parse Unity output, report results
6. Delete the test binary
```

The compiler does steps 1–3. `with test` orchestrates the
rest.

---

## CLI

```
with test [flags] [filter]
```

### Flags

```
-v              Verbose: print each test name and result as it runs.
                Without -v, only failures are printed.

-run PATTERN    Run only tests matching PATTERN (substring match,
                not regex — keep it simple).

-count N        Run each test N times. Default 1.

-timeout D      Timeout for the entire test run. Default 10m.
                Format: 10s, 5m, 1h.

-short          Set the testing.short flag. Tests can check this
                and skip expensive work.

-failfast       Stop after the first failure.

-shuffle        Randomize test execution order. Default: file order.
                -shuffle=SEED for reproducible order.

-list           List matching tests without running them.

-bench PATTERN  Run benchmarks matching PATTERN (not yet — future).

-cover          Print coverage summary (not yet — future).
```

### Examples

```
$ with test                     # run all tests
$ with test -v                  # verbose
$ with test parser              # only tests containing "parser"
$ with test -run parser -v      # same, verbose
$ with test -short              # skip slow tests
$ with test -count 100          # stress test: run everything 100x
$ with test -failfast           # stop at first failure
$ with test -shuffle            # random order (catch order dependencies)
$ with test -list               # show test names, don't run
$ with test -timeout 30s        # fail if tests take > 30s
```

---

## Output

### Default (quiet)

```
$ with test
PASS
ok      my-project    0.034s
```

Only shows the summary. Failures print details:

```
$ with test
--- FAIL: test_parser_edge (0.002s)
    src/parser.w:42: assert_eq failed
      left:  3
      right: 5
FAIL
FAIL    my-project    0.034s
```

### Verbose (-v)

```
$ with test -v
=== RUN   test_add
--- PASS: test_add (0.001s)
=== RUN   test_sub
--- PASS: test_sub (0.001s)
=== RUN   test_parser_basic
--- PASS: test_parser_basic (0.003s)
=== RUN   test_parser_edge
--- FAIL: test_parser_edge (0.002s)
    src/parser.w:42: assert_eq failed
      left:  3
      right: 5
FAIL
FAIL    my-project    0.034s
```

Same format as `go test -v`. Each test gets `=== RUN` and
`--- PASS`/`--- FAIL`. Unity's native output is parsed and
reformatted into this shape.

### List (-list)

```
$ with test -list
test_add
test_sub
test_parser_basic
test_parser_edge
test_parser_unicode
test_lexer_keywords
test_lexer_strings
```

---

## Test Functions

### Basic

```with
@[test]
fn test_add:
    assert_eq(add(2, 3), 5)
```

No parameters. No return value. The `@[test]` annotation is
the only marker. The function name is the test name.

### With Result

```with
@[test]
fn test_file_parse -> Result[Unit, str]:
    let data = std.fs.read_file("testdata/sample.json")?
    let parsed = json.parse(data)?
    assert_eq(parsed.len(), 3)
```

If it returns `Err`, the test fails with the error message.
The generated runner wraps it:

```with
fn test_file_parse_wrapper:
    match test_file_parse()
        Ok(()) -> ()
        Err(e) -> test.fail("returned Err: {e}")
```

### Short Mode

```with
@[test]
fn test_full_corpus:
    if testing.short():
        test.skip("skipping in short mode")
    // expensive work...
```

`testing.short()` returns `true` when `-short` is passed.
`test.skip()` calls Unity's `TEST_IGNORE_MESSAGE` — the test
is marked ignored, not failed.

---

## setUp / tearDown

Per-file, not per-test. Like Go's `TestMain` but simpler.

```with
var db: Database

@[before]
fn setup:
    db = Database.open(":memory:")

@[after]
fn teardown:
    db.close()
```

`@[before]` runs before each test. `@[after]` runs after each
test, even if the test fails. They map directly to Unity's
`setUp()` / `tearDown()` convention.

Only one `@[before]` and one `@[after]` per file. Multiple is
a compile error. If a file has no `@[before]`/`@[after]`, the
generated `setUp`/`tearDown` are empty.

---

## Test Discovery

The compiler finds tests, not the runner. At compile time:

1. Walk all `.w` files in the package.
2. Collect every function annotated `@[test]`.
3. Collect `@[before]` and `@[after]` (at most one each per file).
4. Apply `-run` filter (if given) — only emit matching tests.
5. Generate test main.

No file naming convention. No separate test directory. Tests
live anywhere in the package — next to the code they test,
at the bottom of the file, wherever.

---

## Generated Main

For a package with these tests:

```with
// src/math.w
@[test]
fn test_add: ...

@[test]
fn test_sub: ...

// src/parser.w
@[before]
fn parser_setup: ...

@[after]
fn parser_teardown: ...

@[test]
fn test_parse_basic: ...

@[test]
fn test_parse_edge: ...
```

The compiler generates:

```with
use test.runner

fn setUp:
    // dispatch per-file setup
    // (only parser tests need it — compiler tracks which file each test comes from)

fn tearDown:
    // dispatch per-file teardown

fn main -> i32:
    runner.begin()
    runner.run_test("test_add", test_add, "src/math.w", 5)
    runner.run_test("test_sub", test_sub, "src/math.w", 9)
    runner.run_test("test_parse_basic", test_parse_basic, "src/parser.w", 12)
    runner.run_test("test_parse_edge", test_parse_edge, "src/parser.w", 18)
    runner.finish()
```

When `-run parse` is passed, the compiler omits `test_add`
and `test_sub` from the generated main entirely. They're not
compiled, not linked, not present. This is better than
runtime filtering — dead code elimination kicks in and the
test binary is smaller.

When `-shuffle` is passed, the compiler randomizes the order
of `run_test` calls in the generated main.

---

## Exit Code

| Condition | Exit code |
|-----------|-----------|
| All tests pass | 0 |
| Any test fails | 1 |
| Compilation fails | 2 |
| Timeout | 2 |

`with test` returns 0 or 1. CI checks `$?`. Like Go.

---

## testdata Directory

Files in `testdata/` are available to tests but not compiled:

```
my-project/
├── src/
│   ├── parser.w
│   └── parser_test_data/    # also fine, any name works
├── testdata/                # convention, not enforced
│   ├── sample.json
│   └── corpus/
└── with.toml
```

Tests access fixtures with relative paths from the project
root. `with test` sets the working directory to the project
root before running.

---

## Comparison With Go

| `go test` | `with test` | Notes |
|-----------|-------------|-------|
| `func TestFoo(t *testing.T)` | `@[test] fn test_foo:` | Annotation, not naming convention |
| `t.Error("msg")` | `test.fail("msg")` | Unity underneath |
| `t.Fatal("msg")` | `assert(false)` | Panics = Unity FAIL |
| `t.Skip("reason")` | `test.skip("reason")` | Unity IGNORE |
| `t.Log("info")` | `println("info")` | Just print |
| `testing.Short()` | `testing.short()` | Same idea |
| `TestMain(m)` | `@[before]` / `@[after]` | Per-file, simpler |
| `-run ^TestParse$` | `-run parse` | Substring, not regex |
| `-v` | `-v` | Same |
| `-count N` | `-count N` | Same |
| `-timeout 30s` | `-timeout 30s` | Same |
| `-short` | `-short` | Same |
| `-shuffle` | `-shuffle` | Same |
| `-failfast` | `-failfast` | Same |
| `-cover` | `-cover` | Future |
| `-bench .` | `-bench .` | Future |
| `go test ./...` | `with test` (all by default) | Single package, no `./...` needed |

### What We Skip From Go

**No `testing.T` parameter.** Go passes `*testing.T` to every
test function so tests can call `t.Error`, `t.Log`, `t.Skip`.
With doesn't need this — assertions are free functions that
talk to Unity directly. No `t` to thread through. This is
cleaner.

**No `testing.B` for benchmarks.** Future work. When we add
it, it'll be `@[bench]` functions with a loop count parameter,
not Go's `b.N` approach.

**No `testing.F` for fuzzing.** Future work.

**No `_test.go` file convention.** Go requires test files to
end in `_test.go`. With doesn't care — `@[test]` functions can
be anywhere. The annotation is the marker, not the filename.

**No subtests.** Go has `t.Run("sub", func(t *testing.T){...})`.
With doesn't. If you want subtests, write separate test
functions. Table-driven tests use a loop:

```with
@[test]
fn test_add_cases:
    let cases = [
        (2, 3, 5),
        (-1, 1, 0),
        (0, 0, 0),
    ]
    for (a, b, expected) in cases:
        assert_eq(add(a, b), expected)
```

If one case fails, the assertion shows which values failed.
Good enough.

---

## Full Example Session

```
$ with new my-lib --lib
$ cat src/lib.w
pub fn add(a: i32, b: i32) -> i32: a + b
pub fn sub(a: i32, b: i32) -> i32: a - b

@[test]
fn test_add:
    assert_eq(add(2, 3), 5)

@[test]
fn test_sub:
    assert_eq(sub(5, 3), 2)

@[test]
fn test_add_commutative:
    assert_eq(add(3, 7), add(7, 3))

$ with test
PASS
ok      my-lib    0.012s

$ with test -v
=== RUN   test_add
--- PASS: test_add (0.001s)
=== RUN   test_sub
--- PASS: test_sub (0.001s)
=== RUN   test_add_commutative
--- PASS: test_add_commutative (0.001s)
PASS
ok      my-lib    0.012s

$ with test -list
test_add
test_sub
test_add_commutative

$ with test add
=== RUN   test_add
--- PASS: test_add (0.001s)
=== RUN   test_add_commutative
--- PASS: test_add_commutative (0.001s)
PASS
ok      my-lib    0.008s
```