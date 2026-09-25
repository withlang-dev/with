# Benchmarks

A small, honest comparison of With against Rust, C, Go, and Zig on the same
workloads, measuring what people actually ask about a native language:

| Measure | What it is |
|---|---|
| Compile | Wall-clock seconds to build the program. The toolchain's own caches (standard library, first-run setup) are warmed first; the program itself is never cached. |
| Size | Stripped executable size. |
| Run | Wall-clock seconds for the whole process, median of N runs. |
| Hot loop | The program's own timer around its core work, median of N runs. Excludes startup and setup. |
| Peak RSS | Maximum resident set size across the runs. |
| Checksum | Each program's result. Every language must print the same value, or the timings are not comparing the same work. |

## Running

```sh
./run.py                       # debug and release level for every language and workload
./run.py --full                # every optimization level each compiler offers
./run.py -w nbody -w trees     # a subset of workloads
./run.py -l with -l rust       # a subset of languages
./run.py -n 5 -o results       # five runs per cell; write results.md, .csv, .json
```

Toolchains are looked up on `PATH` and skipped when missing. On macOS the C
compiler is Apple's `/usr/bin/clang`, which carries the SDK sysroot. Zig is
`brew install zig` away if it is not present.

## Workloads

Each workload lives in `workloads/<name>/<name>.<ext>` with one file per
language. The implementations are written to do the same arithmetic in the
same order so their results match bit for bit, and each prints:

```
elapsed_ms <hot loop time>
checksum <result>
```

| Workload | Exercises | Work |
|---|---|---|
| `hello` | Startup cost, toolchain overhead, minimum binary size | Print one line. Compile time and size only. |
| `ecs` | Memory bandwidth, branchy loops over structure-of-arrays data | 1M entities with bitmask component queries; 1000 ticks of movement, damage, and cleanup systems. |
| `nbody` | Scalar floating point in a tight loop | Five-body gravitational integration in `f64`, 50M steps. |
| `trees` | Allocation and deallocation of many small objects, pointer chasing | Binary trees to depth 18: build, count, free. Go measures its garbage collector here; the others use `malloc` or the language's owning box. |

## Keeping the comparison fair

- **No fused multiply-add.** C is built with `-ffp-contract=off` and the Go
  sources wrap products in explicit conversions, because both will otherwise
  fuse `a*b+c` on arm64 and drift from the languages that never fuse. If a
  checksum disagrees, that is the first thing to suspect.
- **Same algorithm, same data layout.** No SIMD intrinsics, no threads, no
  language-specific tricks. Each file is plain, idiomatic code a working
  programmer would write.
- **Cold program, warm toolchain.** Every timed compile builds a fresh copy of
  the source with a unique trailing comment, so build caches (Go, Zig) cannot
  return a previous result, while their standard-library caches stay warm.
  Rust and With have nothing to warm; they compile the same way every time.
- **Release means release.** Ratios in the report compare against the fastest
  release-level cell (`O3`, `release`, or `ReleaseFast`). Debug rows are shown
  for the compile-time trade-off, not for speed.

## Known With gaps the results reflect

- **`trees` peak memory.** A `Box` held inside an `Option` payload is never
  freed ([withlang-dev/with#1535](https://github.com/withlang-dev/with/issues/1535)),
  so the With tree nodes leak and peak RSS scales with total allocations
  instead of the live set. The timing is still a fair allocation benchmark;
  the memory column is not, until that issue closes.

Two spots in the With sources work around compiler gaps and say so in a
comment. Both are filed upstream:

- `nbody.w` expresses float constants as functions because a `const` with a
  float initializer is not yet comptime-evaluable
  ([withlang-dev/with#1668](https://github.com/withlang-dev/with/issues/1668)).
- The With sources mutate through `mut self` methods on a wrapper type because
  `mut` is not a parameter modifier; that is the language design, not a gap,
  but it is why `nbody.w` has a `System` type where C has free functions.
