# Plan: `with bench` — Benchmark Runner

## Design Decisions

### Reference implementations

**Go** (`go test -bench`): Discovery by naming convention (`BenchmarkXxx`).
User gets `*testing.B` with `b.N` auto-calibrated. Reports ns/op, MB/s,
allocs/op. Benchmarks run serially. Sub-benchmarks via `b.Run()`.

**Rust** (`cargo bench`): Discovery by `#[bench]` attribute. User gets
`&mut Bencher`, calls `b.iter(|| ...)`. Auto-calibrates iterations,
collects 50 samples, reports median ns/iter with deviation. Benchmarks
run after all tests, serially.

**Zig**: No built-in benchmark command. Users write standalone programs
using `std.time.Timer` and `std.mem.doNotOptimizeAway`. Convention only.

### Design for With

Follow Go's model (simplest, most practical) adapted to With's existing
test infrastructure:

- **Command**: `with bench <file|dir>` (separate command, like `cargo bench`)
- **Discovery**: `@[bench]` attribute + `bench_*` naming convention
  (mirrors existing `@[test]` + `test_*` pattern)
- **Function signature**: `fn bench_foo(b: &mut Bench)` — takes a `Bench`
  parameter (like Go's `*testing.B`)
- **User API**: `for _ in b: ...` loop — the body is the measured code
- **Calibration**: Go-style ramp-up (run increasing N until ~1s elapsed)
- **Output**: `name    N    ns/op    [MB/s]`
- **Execution**: Same synthesized-main approach as `with test`

### What we are NOT doing (yet)

- Statistical analysis (Rust's 50-sample + median/MAD) — overkill for v1
- Parallel benchmarks (Go's `b.RunParallel`) — not needed yet
- Sub-benchmarks (Go's `b.Run`) — not needed yet
- Memory allocation tracking — no allocator instrumentation yet
- `black_box` / `doNotOptimizeAway` — requires compiler intrinsic, defer

---

## Implementation Plan

### Phase 1: Parser — `@[bench]` attribute

**File:** `src/Parser.w`

Add `@[bench]` attribute parsing, mirroring `@[test]`.

1. Add `pending_bench: i32` field to Parser struct (like `pending_test`)
2. In attribute parsing (around line 303), handle `bench` keyword:
   set `pending_bench = 1`
3. Define `FN_FLAG_BENCH` constant (next available bit after AFTER=16384,
   so BENCH = 32768)
4. In fn flag assembly (around line 649), OR in BENCH bit if
   `pending_bench != 0`
5. Reset `pending_bench = 0` after each declaration

**Verify:** `make build && make fixpoint`

---

### Phase 2: Bench type in stdlib

**File:** `lib/test/bench.w` (new)

Provide the `Bench` type that users interact with:

```
use std.time

type Bench {
    target_ns: i64,      // target duration per calibration run (1_000_000_000 = 1s)
    n: i64,              // current iteration count
    elapsed_ns: i64,     // total elapsed nanoseconds for last run
    bytes_per_op: i64,   // user-settable: bytes processed per iteration
    done: bool,          // true when calibration is complete
}

fn Bench.new() -> Bench:
    Bench {
        target_ns: 1_000_000_000,
        n: 0,
        elapsed_ns: 0,
        bytes_per_op: 0,
        done: false,
    }

fn Bench.set_bytes(self: &mut Bench, b: i64):
    self.bytes_per_op = b

fn Bench.ns_per_op(self: &Bench) -> i64:
    if self.n == 0:
        return 0
    self.elapsed_ns / self.n

fn Bench.run(self: &mut Bench, f: fn()):
    // Phase 1: single iteration probe
    let start = time.now_ns()
    f()
    let ns_single = time.now_ns() - start

    // Phase 2: estimate N for ~1s
    if ns_single == 0:
        self.n = 1_000_000_000
    else:
        self.n = self.target_ns / ns_single

    if self.n < 1:
        self.n = 1

    // Phase 3: calibration loop (Go-style)
    // Run increasing N until elapsed >= target_ns
    while not self.done:
        let t0 = time.now_ns()
        for _ in 0..self.n:
            f()
        self.elapsed_ns = time.now_ns() - t0

        if self.elapsed_ns >= self.target_ns:
            self.done = true
        else:
            // Go's predictN: grow by observed ratio, +20%, cap at 100x
            let prev_n = self.n
            if self.elapsed_ns > 0:
                self.n = self.target_ns * self.n / self.elapsed_ns
                self.n = self.n + self.n / 5   // +20%
            if self.n > prev_n * 100:
                self.n = prev_n * 100
            if self.n < prev_n + 1:
                self.n = prev_n + 1
            if self.n > 1_000_000_000:
                self.n = 1_000_000_000
```

Uses `time.now_ns()` from Phase 6 (`with_clock_nanos` runtime function).

**Verify:** Compile a test program that uses `Bench`.

---

### Phase 3: Result formatting

**File:** `lib/test/bench.w` (continued)

Add result formatting, following Go's output format:

```
fn Bench.report(self: &Bench, name: str):
    let ns = self.ns_per_op()
    if self.bytes_per_op > 0:
        let mb_s = self.bytes_per_op * 1000 / ns
        println(f"{name}\t{self.n}\t{ns} ns/op\t{mb_s} MB/s")
    else:
        println(f"{name}\t{self.n}\t{ns} ns/op")
```

---

### Phase 4: Discovery in the test runner

**File:** `src/main.w`

Extend `discover_test_functions` to also discover benchmarks.

1. Add `bench_names: Vec[str]` to the `TestDiscovery` struct
   (or create a parallel `BenchDiscovery`)
2. In the discovery loop, check for:
   - `FN_FLAG_BENCH` bit in fn_meta flags (like `FN_FLAG_TEST` check)
   - Name starts with `bench_` (like `test_` convention)
3. Add `discover_bench_functions()` or extend existing function

---

### Phase 5: `with bench` command

**File:** `src/main.w`

Add the `with bench` command handler, mirroring `run_test_command`.

1. Add CLI routing: `if cli_command(argc) == "bench": return run_bench_command(argc)`
2. Implement `run_bench_command`:
   - Parse args: file/dir path, `--filter`, `-v`, `-q`
   - For each target file, call `run_bench_file()`
3. Implement `run_bench_file`:
   - Discover benchmark functions (Phase 4)
   - Synthesize main that:
     - Creates a `Bench` for each benchmark function
     - Calls `b.run(bench_fn)` for each
     - Calls `b.report(name)` for each
   - Compile the combined source
   - Run the binary once (all benchmarks run sequentially in-process,
     unlike tests which run as separate processes — benchmarks need
     process-level warmth)
   - Parse and display results
4. Support `--filter` (substring match, like tests)

### Synthesized main structure

```
fn main():
    let filter = with_getenv_str("WITH_BENCH_FILTER")
    // For each discovered benchmark:
    if filter == "" or with_str_contains("bench_sorting", filter):
        let b = Bench.new()
        b.run(bench_sorting)
        b.report("bench_sorting")
    // ... repeat for each benchmark
```

Key difference from tests: benchmarks all run in **one process invocation**
(not one process per benchmark). This avoids cold-start overhead and matches
Go/Rust behavior.

---

### Phase 6: Time primitives

**Status: Runtime function exists, just needs stdlib exposure.**

`with_clock_nanos()` already exists in `runtime/helpers.c` (line 1913):
```c
int64_t with_clock_nanos(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (int64_t)ts.tv_sec * 1000000000LL + (int64_t)ts.tv_nsec;
}
```

**File:** `lib/std/time.w` — add:
```
extern fn with_clock_nanos() -> i64

pub fn now_ns() -> i64:
    with_clock_nanos()
```

`lib/std/time.w` currently has `with_time_now()` (seconds since epoch)
and `clock()` (CPU ticks) but no monotonic nanosecond timer exposed.

**Verify:** `make build && make fixpoint`

---

## Implementation Order

Execute in this order (each step: build + fixpoint):

1. **Phase 6** (time primitives) — check what exists, add if needed
2. **Phase 1** (parser `@[bench]`) — small, mechanical
3. **Phase 2 + 3** (Bench type + formatting) — stdlib, no compiler changes
4. **Phase 4** (discovery) — extend existing test discovery
5. **Phase 5** (command wiring) — bring it all together

---

## Verification

After all phases:

1. Write `examples/bench_demo.w`:
   ```
   fn do_work():
       let mut sum = 0
       for i in 0..1000:
           sum = sum + i

   @[bench]
   fn bench_sum_1000(b: &mut Bench):
       b.run(do_work)
   ```

2. Run: `./out/bin/with-stage2 bench examples/bench_demo.w`

3. Expected output:
   ```
   bench_sum_1000    500000    2000 ns/op
   ```
   (actual numbers will vary)

4. `make build && make fixpoint`

5. Write `test/behavior/behav_bench_discovery.w` to verify both
   `@[bench]` attribute and `bench_*` naming convention are discovered.

---

## Future Work (not in this plan)

- `black_box()` compiler intrinsic to prevent dead-code elimination
- Memory allocation tracking (allocs/op, bytes/op)
- Statistical output (multiple samples, median, deviation)
- Sub-benchmarks (`b.run("sub", fn)`)
- Parallel benchmarks
- Comparison mode (`with bench --base=<old> --new=<new>`)
- JSON output (`--format=json`)
