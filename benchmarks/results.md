# Benchmark results

Host: Darwin arm64, Apple M5 Max  
Runs per cell: 3 (median for times, max for memory)  
Levels: debug and release

## Toolchains

- With: with v0.15.2.1
- Rust: rustc 1.97.1 (8bab26f4f 2026-07-14)
- C: Apple clang version 21.0.0 (clang-2100.3.34.2)
- Go: go version go1.26.5 darwin/arm64

## ecs

ECS update: structure-of-arrays storage, bitmask queries, 1M entities. Timed region: 1000 ticks of movement, damage, and cleanup systems.

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.233s (5.75x) | 120 KB | 12.025s | 11.960s | 25.5 MB | 35005460314.37 |
| With | O3 | 0.202s (4.99x) | 104 KB | 2.001s (1.83x) | 1.962s (1.88x) | 25.5 MB | 35005460314.37 |
| Rust | O0 | 0.087s (2.16x) | 367 KB | 18.987s | 18.923s | 25.6 MB | 35005460314.37 |
| Rust | O3 | 0.112s (2.76x) | 350 KB | 1.239s (1.13x) | 1.210s (1.16x) | 25.6 MB | 35005460314.37 |
| C | O0 | 0.041s (1.00x) | 33 KB | 3.455s | 3.444s | 25.4 MB | 35005460314.37 |
| C | O3 | 0.051s (1.25x) | 33 KB | 1.092s (1.00x) | 1.044s (1.00x) | 25.4 MB | 35005460314.37 |
| Go | debug | 0.107s (2.65x) | 2.2 MB | 5.826s | 5.772s | 29.3 MB | 35005460314.37 |
| Go | release | 0.101s (2.48x) | 2.3 MB | 1.818s (1.67x) | 1.787s (1.71x) | 29.1 MB | 35005460314.37 |

## hello

| Language | Level | Compile | Size | Output |
|---|---|---:|---:|---|
| With | O0 | 0.177s (4.58x) | 87 KB | ok |
| With | O3 | 0.161s (4.17x) | 87 KB | ok |
| Rust | O0 | 0.059s (1.51x) | 334 KB | ok |
| Rust | O3 | 0.062s (1.60x) | 334 KB | ok |
| C | O0 | 0.039s (1.00x) | 33 KB | ok |
| C | O3 | 0.040s (1.04x) | 33 KB | ok |
| Go | debug | 0.089s (2.31x) | 2.1 MB | ok |
| Go | release | 0.090s (2.33x) | 2.3 MB | ok |

## nbody

N-body: five-body gravitational integration in f64, 50M steps. Timed region: the integration loop. Checksum: final system energy.

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.192s (5.01x) | 120 KB | 14.035s | 14.031s | 1.6 MB | -0.169059907 |
| With | O3 | 0.188s (4.92x) | 103 KB | 2.881s (3.12x) | 2.844s (3.09x) | 1.6 MB | -0.169059907 |
| Rust | O0 | 0.078s (2.04x) | 367 KB | 10.744s | 10.710s | 1.6 MB | -0.169059907 |
| Rust | O3 | 0.119s (3.12x) | 350 KB | 0.931s (1.01x) | 0.927s (1.01x) | 1.6 MB | -0.169059907 |
| C | O0 | 0.038s (1.00x) | 49 KB | 4.649s | 4.645s | 1.4 MB | -0.169059907 |
| C | O3 | 0.056s (1.48x) | 49 KB | 0.925s (1.00x) | 0.921s (1.00x) | 1.4 MB | -0.169059907 |
| Go | debug | 0.090s (2.36x) | 2.2 MB | 4.961s | 4.953s | 4.4 MB | -0.169059907 |
| Go | release | 0.093s (2.43x) | 2.3 MB | 1.665s (1.80x) | 1.652s (1.79x) | 4.3 MB | -0.169059907 |

## trees

Binary trees: allocation-heavy recursive tree build and check, depth 18. Timed region: everything. Checksum: sum of all node counts.

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.190s (4.70x) | 104 KB | 2.562s | 2.517s | 2076.7 MB | 68332206 |
| With | O3 | 0.173s (4.28x) | 103 KB | 2.333s (3.07x) | 2.285s (3.04x) | 2076.7 MB | 68332206 |
| Rust | O0 | 0.073s (1.79x) | 367 KB | 1.952s | 1.867s | 17.7 MB | 68332206 |
| Rust | O3 | 0.084s (2.07x) | 350 KB | 1.088s (1.43x) | 1.072s (1.43x) | 17.8 MB | 68332206 |
| C | O0 | 0.041s (1.00x) | 33 KB | 1.106s | 1.101s | 17.5 MB | 68332206 |
| C | O3 | 0.048s (1.18x) | 33 KB | 1.044s (1.37x) | 1.031s (1.37x) | 17.5 MB | 68332206 |
| Go | debug | 0.088s (2.17x) | 2.2 MB | 1.454s | 1.438s | 41.6 MB | 68332206 |
| Go | release | 0.092s (2.26x) | 2.3 MB | 0.760s (1.00x) | 0.751s (1.00x) | 42.2 MB | 68332206 |

Ratios are relative to the best release-level cell in the same column. Compile time is a cold build of the program with the toolchain's caches already warm. Hot loop is the program's own timer around its core work; Run is the whole process.
