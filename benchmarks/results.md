# Benchmark results

Host: Darwin arm64, Apple M5 Max  
Runs per cell: 3 (median for times, max for memory)  
Levels: debug and release

## Toolchains

- With: with v0.15.2.1
- Rust: rustc 1.97.1 (8bab26f4f 2026-07-14)
- C: Apple clang version 21.0.0 (clang-2100.3.34.2)
- Go: go version go1.26.5 darwin/arm64
- Zig: 0.16.0

## buffers

Buffers: chunked-I/O shaped churn of 8 to 64 KiB blocks, 32 live at once. Timed region: everything. Checksum: wrapping sum of the words written.

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.163s (4.30x) | 120 KB | 4.018s | 3.925s | 2.2 MB | 4020458503892964864 |
| With | O3 | 0.148s (3.90x) | 104 KB | 3.659s (32.84x) | 3.540s (33.10x) | 2.2 MB | 4020458503892964864 |
| Rust | O0 | 0.075s (1.99x) | 367 KB | 1.016s | 1.012s | 4.0 MB | 4020458503892964864 |
| Rust | O3 | 0.085s (2.23x) | 350 KB | 0.159s (1.42x) | 0.154s (1.44x) | 2.4 MB | 4020458503892964864 |
| C | O0 | 0.038s (1.00x) | 33 KB | 0.370s | 0.366s | 2.5 MB | 4020458503892964864 |
| C | O3 | 0.047s (1.24x) | 33 KB | 0.111s (1.00x) | 0.107s (1.00x) | 2.3 MB | 4020458503892964864 |
| Go | debug | 0.089s (2.35x) | 2.2 MB | 4.492s | 4.486s | 25.4 MB | 4020458503892964864 |
| Go | release | 0.093s (2.44x) | 2.3 MB | 3.742s (33.59x) | 3.681s (34.41x) | 45.0 MB | 4020458503892964864 |
| Zig | Debug | 0.787s (20.78x) | 1.4 MB | 33.737s | 33.685s | 5.3 MB | 4020458503892964864 |
| Zig | ReleaseFast | 3.084s (81.41x) | 328 KB | 0.128s (1.15x) | 0.123s (1.15x) | 2.7 MB | 4020458503892964864 |

## ecs

ECS update: structure-of-arrays storage, bitmask queries, 1M entities. Timed region: 1000 ticks of movement, damage, and cleanup systems.

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.170s (4.19x) | 120 KB | 10.961s | 10.894s | 25.6 MB | 35005460314.37 |
| With | O3 | 0.171s (4.22x) | 120 KB | 1.232s (1.26x) | 1.181s (1.23x) | 25.6 MB | 35005460314.37 |
| Rust | O0 | 0.083s (2.05x) | 367 KB | 18.569s | 18.333s | 25.6 MB | 35005460314.37 |
| Rust | O3 | 0.114s (2.81x) | 350 KB | 1.241s (1.27x) | 1.189s (1.24x) | 25.6 MB | 35005460314.37 |
| C | O0 | 0.041s (1.00x) | 33 KB | 3.465s | 3.427s | 25.4 MB | 35005460314.37 |
| C | O3 | 0.057s (1.41x) | 33 KB | 1.041s (1.07x) | 1.034s (1.08x) | 25.4 MB | 35005460314.37 |
| Go | debug | 0.095s (2.35x) | 2.2 MB | 5.702s | 5.686s | 29.2 MB | 35005460314.37 |
| Go | release | 0.106s (2.61x) | 2.3 MB | 1.808s (1.86x) | 1.792s (1.86x) | 29.2 MB | 35005460314.37 |
| Zig | Debug | 0.806s (19.91x) | 1.5 MB | 9.033s | 8.957s | 25.6 MB | 35005460314.37 |
| Zig | ReleaseFast | 3.259s (80.47x) | 328 KB | 0.975s (1.00x) | 0.961s (1.00x) | 25.4 MB | 35005460314.37 |

## grow

Grow: push-built vectors inside a struct, 800 rounds of 100k rows each. Timed region: everything. Checksum: wrapping fold over the rows.

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.163s (4.20x) | 120 KB | 1.271s | 1.250s | 4.0 MB | 3200399544523229 |
| With | O3 | 0.151s (3.88x) | 104 KB | 0.539s (2.79x) | 0.535s (2.83x) | 4.0 MB | 3200399544523229 |
| Rust | O0 | 0.070s (1.79x) | 367 KB | 1.614s | 1.609s | 9.9 MB | 3200399544523229 |
| Rust | O3 | 0.095s (2.44x) | 350 KB | 0.193s (1.00x) | 0.189s (1.00x) | 6.4 MB | 3200399544523229 |
| C | O0 | 0.039s (1.00x) | 33 KB | 0.678s | 0.674s | 5.2 MB | 3200399544523229 |
| C | O3 | 0.046s (1.18x) | 33 KB | 0.196s (1.01x) | 0.192s (1.01x) | 6.9 MB | 3200399544523229 |
| Go | debug | 0.087s (2.23x) | 2.2 MB | 1.142s | 1.137s | 15.4 MB | 3200399544523229 |
| Go | release | 0.090s (2.33x) | 2.3 MB | 0.742s (3.84x) | 0.737s (3.90x) | 22.8 MB | 3200399544523229 |
| Zig | Debug | 0.770s (19.84x) | 1.5 MB | 3.410s | 3.406s | 10.1 MB | 3200399544523229 |
| Zig | ReleaseFast | 3.185s (82.08x) | 328 KB | 0.255s (1.32x) | 0.251s (1.33x) | 5.2 MB | 3200399544523229 |

## hello

| Language | Level | Compile | Size | Output |
|---|---|---:|---:|---|
| With | O0 | 0.156s (4.05x) | 103 KB | ok |
| With | O3 | 0.133s (3.46x) | 103 KB | ok |
| Rust | O0 | 0.058s (1.51x) | 334 KB | ok |
| Rust | O3 | 0.060s (1.57x) | 334 KB | ok |
| C | O0 | 0.039s (1.00x) | 33 KB | ok |
| C | O3 | 0.039s (1.02x) | 33 KB | ok |
| Go | debug | 0.085s (2.22x) | 2.1 MB | ok |
| Go | release | 0.090s (2.33x) | 2.3 MB | ok |
| Zig | Debug | 0.756s (19.64x) | 1.4 MB | ok |
| Zig | ReleaseFast | 3.092s (80.27x) | 328 KB | ok |

## nbody

N-body: five-body gravitational integration in f64, 50M steps. Timed region: the integration loop. Checksum: final system energy.

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.169s (4.49x) | 120 KB | 13.904s | 13.899s | 1.6 MB | -0.169059907 |
| With | O3 | 0.162s (4.31x) | 120 KB | 1.595s (1.80x) | 1.591s (1.80x) | 1.6 MB | -0.169059907 |
| Rust | O0 | 0.076s (2.02x) | 367 KB | 10.453s | 10.447s | 1.6 MB | -0.169059907 |
| Rust | O3 | 0.103s (2.74x) | 350 KB | 0.914s (1.03x) | 0.909s (1.03x) | 1.6 MB | -0.169059907 |
| C | O0 | 0.038s (1.00x) | 49 KB | 4.500s | 4.496s | 1.4 MB | -0.169059907 |
| C | O3 | 0.056s (1.50x) | 49 KB | 0.913s (1.03x) | 0.909s (1.03x) | 1.4 MB | -0.169059907 |
| Go | debug | 0.088s (2.33x) | 2.2 MB | 4.862s | 4.858s | 4.3 MB | -0.169059907 |
| Go | release | 0.094s (2.49x) | 2.3 MB | 1.644s (1.85x) | 1.639s (1.86x) | 4.2 MB | -0.169059907 |
| Zig | Debug | 0.766s (20.37x) | 1.4 MB | 6.522s | 6.517s | 1.6 MB | -0.169059907 |
| Zig | ReleaseFast | 3.132s (83.27x) | 328 KB | 0.888s (1.00x) | 0.883s (1.00x) | 1.5 MB | -0.169059907 |

## trees

Binary trees: allocation-heavy recursive tree build and check, depth 18. Timed region: everything. Checksum: sum of all node counts.

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.162s (4.17x) | 104 KB | 1.401s | 1.378s | 67.1 MB | 68332206 |
| With | O3 | 0.147s (3.78x) | 104 KB | 1.044s (1.38x) | 1.023s (1.37x) | 67.1 MB | 68332206 |
| Rust | O0 | 0.072s (1.85x) | 367 KB | 1.852s | 1.841s | 17.8 MB | 68332206 |
| Rust | O3 | 0.083s (2.13x) | 350 KB | 1.052s (1.39x) | 1.044s (1.40x) | 17.8 MB | 68332206 |
| C | O0 | 0.039s (1.00x) | 33 KB | 1.104s | 1.100s | 17.5 MB | 68332206 |
| C | O3 | 0.045s (1.15x) | 33 KB | 1.011s (1.34x) | 1.007s (1.35x) | 17.5 MB | 68332206 |
| Go | debug | 0.088s (2.25x) | 2.2 MB | 1.416s | 1.410s | 42.3 MB | 68332206 |
| Go | release | 0.091s (2.35x) | 2.3 MB | 0.756s (1.00x) | 0.746s (1.00x) | 41.4 MB | 68332206 |
| Zig | Debug | 0.770s (19.76x) | 1.4 MB | 3.075s | 3.071s | 17.8 MB | 68332206 |
| Zig | ReleaseFast | 3.131s (80.40x) | 328 KB | 0.997s (1.32x) | 0.990s (1.33x) | 17.6 MB | 68332206 |

## words

Words: string building, hashing, and map lookup over 30M generated words. Timed region: everything. Checksum: order-independent FNV mix of the counts

| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |
|---|---|---:|---:|---:|---:|---:|---|
| With | O0 | 0.172s (4.30x) | 120 KB | 2.357s | 2.351s | 7.1 MB | 9968765420461722795 |
| With | O3 | 0.169s (4.22x) | 120 KB | 1.875s (5.66x) | 1.866s (5.71x) | 7.1 MB | 9968765420461722795 |
| Rust | O0 | 0.100s (2.51x) | 400 KB | 8.410s | 8.404s | 11.1 MB | 9968765420461722795 |
| Rust | O3 | 0.119s (2.97x) | 367 KB | 1.171s (3.54x) | 1.166s (3.57x) | 11.1 MB | 9968765420461722795 |
| C | O0 | 0.040s (1.00x) | 33 KB | 0.732s | 0.727s | 6.4 MB | 9968765420461722795 |
| C | O3 | 0.049s (1.23x) | 33 KB | 0.331s (1.00x) | 0.327s (1.00x) | 6.4 MB | 9968765420461722795 |
| Go | debug | 0.087s (2.18x) | 2.2 MB | 1.891s | 1.885s | 15.7 MB | 9968765420461722795 |
| Go | release | 0.093s (2.32x) | 2.3 MB | 1.235s (3.73x) | 1.229s (3.76x) | 16.0 MB | 9968765420461722795 |
| Zig | Debug | 0.791s (19.77x) | 1.5 MB | 3.830s | 3.823s | 8.2 MB | 9968765420461722795 |
| Zig | ReleaseFast | 3.230s (80.77x) | 328 KB | 0.418s (1.26x) | 0.413s (1.26x) | 7.9 MB | 9968765420461722795 |

Ratios are relative to the best release-level cell in the same column. Compile time is a cold build of the program with the toolchain's caches already warm. Hot loop is the program's own timer around its core work; Run is the whole process.
