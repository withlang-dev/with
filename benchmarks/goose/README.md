# Goose benchmark port

Sixteen With workloads translated from the implementation in `.reference/goose/bench`, pinned at `35368105e3d50341b79a4cb873cc0261e82dfa42`. The [manifest](suite.manifest) retains every upstream C++ idiomatic/expert and safe Rust comparison row, every Goose benchmark row, and all three upstream sizes. With adds one safe, ordinary-library implementation per workload. Source algorithms, input streams, error counts and complete stdout are the comparison contract.

Run from repository root:

```sh
GOOSE_EXE=out/benchmarks/goose/compiler/goose with run -O1 benchmarks/goose/run.w smoke all 1
GOOSE_EXE=out/benchmarks/goose/compiler/goose with run -O1 benchmarks/goose/run.w small all 3
GOOSE_EXE=out/benchmarks/goose/compiler/goose with run -O1 benchmarks/goose/run.w medium strlist,words,respond 3
```

Arguments are size, selector (`all` or comma-separated names), and measured repetitions. All sixteen ports can also be checked or run directly, at their default upstream small sizes. `common.w` supplies the exact unsigned xorshift sequence and modulo mapping; this benchmark adapter intentionally preserves upstream modulo bias. It is not a replacement for `std.random`.

The With runner uses `std.process.run_to_files` for argv execution, timeouts and per-child peak RSS. It compiles outside timing, discards two warmups, and records the best whole-process wall time and worst measured RSS. Input generation, allocations, output and destruction are included. Every warmup and measured run must produce identical stdout, and each implementation must match the first successful C++/Rust reference. Failures preserve build logs and stdout in `out/benchmarks/goose`; they return status 1. An unset `GOOSE_EXE` produces explicit pending rows and status 2. A complete run returns 0. Missing compilers are failures, not silently omitted comparisons.

With is built at `-O1`, as required by this repository. C++ and generated Goose C use upstream `-O2`; Rust uses upstream `-O -C codegen-units=1`. Consequently these are current shipping/configuration comparisons, not an experiment controlling optimizer settings across languages. Small runs include a substantial process-startup floor. The report contains raw per-row measurements and toolchain/host identities; it makes no aggregate speedup claim. Do not interpret a small time difference as a language advantage.

Build the reference Goose compiler if needed (optional multimedia and JIT dependencies are unnecessary):

```sh
cmake -S .reference/goose -B out/benchmarks/goose/compiler \
  -DCMAKE_BUILD_TYPE=Release \
  '-DCMAKE_CXX_FLAGS_RELEASE=-O1 -DNDEBUG' \
  '-DCMAKE_C_FLAGS_RELEASE=-O1 -DNDEBUG' \
  -DCMAKE_EXE_LINKER_FLAGS= -DCMAKE_SHARED_LINKER_FLAGS= \
  -DGOOSE_LIBTCC=OFF -DGOOSE_GFX=OFF -DGOOSE_AUDIO=OFF \
  -DGOOSE_PHYSICS=OFF -DGOOSE_UI=OFF
cmake --build out/benchmarks/goose/compiler --target goose -j 4
```

The runner passes the checkout's stdlib explicitly. Generated Rust/Goose input copies substitute only the marked benchmark size; upstream source files are untouched. Generated foreign sources remain ignored build artifacts; the new runner and ports are With.

## Representation and ceremony census

The [token census](census.md) is regenerated with `with run -O1 benchmarks/goose/census.w`. It counts casts, clone calls and typed local bindings with the compiler lexer; the table below records what those spellings mean. Declaration counts alone do not distinguish required contracts from avoidable ceremony.

| Workload | With representation | Relevant comparison / visible obligation |
|---|---|---|
| sum | Growable `Vec[i32]`, eight scans | Ordinary unreserved vector; upstream Rust `collect` reserves exactly. |
| push | `Vec[Item]`, retained `i64` indices | Matches index-based safe Rust, not Goose's pointers surviving growth. |
| strlist | Owned `Vec[str]` from split text | `.clone()` retains each observed word; includes the current split/clone costs before D111. |
| records | Fixed enum with owned `str` payload | Compare Rust's enum and Goose's fixed control before attributing packed-variant differences to dispatch. |
| tree | `Vec[Node]`, signed 32-bit child indices | Arena comparison, not a per-node owning-pointer port. Mutating build is a receiver method. |
| interp | Fixed enum arena with 32-bit links | `match` dispatch; compare arena rows. Goose's variable enum has a different density. |
| graph | Two-pass CSR | Matches the CSR rows, not linked or nested-vector builds. |
| words | Owned word list, `HashMap[str, i32]` | `.clone()` retains words and map keys; typed lookup establishes an owned Copy demand under D22. Goose/Rust view keys differ. |
| particles | Six `f32` fields per record, scalar updates | Matches scalar AoS; floating-to-integer checksum conversions are intentional. |
| sexp | Fixed enum arena, owned symbols, `Result` errors | Reverse sibling chain; slice materialization owns text; preserved error path propagates with `?`. |
| lru | `HashMap[i32, i32]`, index-linked arena and freelist | Matches safe Rust's HashMap/arena shape, not Goose's custom open-addressing map or stale-reference contract. |
| scene | Arena, fixed four-child array, copied transforms | Similar to Rust arena; With count is `i64`, Rust's count is `u8`; passing a world transform copies it. |
| calc | Per-input fixed enum arena, borrowed input, `Result` | Keeps Paren nodes, malformed-input categories and wrapping unsigned evaluation. Pool drops on failure. |
| bintrees | A fresh owned arena per tree | Compare arena rows; ordinary scope destruction frees its storage. No arena reuse across independent trees. |
| respond | Owned response DTO and local JSON builder | Compare DTO rows; streaming rows deliberately omit DTO construction. Includes quote/backslash escaping. |
| blur | Flat byte images; mutating destination receiver | Matches flat-index rows; preserves original border bytes and ping-pong order. |

Ordinary safe integer widening and literal shift counts need no casts; those redundant `as i64`/`as u32` spellings were removed and checked. Remaining conversion categories are (1) fixed-size record/index representations, (2) the adapter's fixed result type, (3) byte generation, unsigned wrapping arithmetic and a computed shift count, and (4) numerical float checksums. Category 2 is a library defect, filed as [#2279](https://github.com/withlang-dev/with/issues/2279): generation should produce the requested type with contextual inference. No RNG fix is included here. The remaining `.clone()` and typed Copy-demand bindings are visible baseline ceremony, not an endorsement against D111 or an amendment of D22.

The string-heavy `strlist`, `records`, `words`, `sexp` and `respond` sources should stay algorithmically stable across D111. Record runtime and peak RSS before and after, then separately record which clone spellings become unnecessary under the ruling. Do not obtain a better result by changing owned storage into borrowed offsets without adding a distinct comparison row.

## Evidence

The initial smoke run checked all sixteen ports against every C++ and Rust variant with zero checksum mismatches. The [small-size baseline](baseline-small.md) records the subsequent full comparison, including Goose. These are measurements on one host; medium/large runs and a full storage/drop verification campaign remain separate work. Source-level arena ownership and checksum equality alone do not prove absence of every leak or redundant copy.
