# zlib Migration Proposal

Migrate zlib to With using `with migrate`, providing native compression and decompression as `std.compress.zlib`.

---

## 1. What zlib Is

zlib is a general-purpose lossless data compression library. It implements the DEFLATE compression algorithm (RFC 1951) and the zlib (RFC 1950) and gzip (RFC 1952) data formats.

- ~15K lines of C (core library, excluding tests and examples)
- zlib license (permissive, no attribution required)
- Zero external dependencies
- Cross-platform: every operating system, every architecture
- The most widely deployed compression library in existence
- Created by Jean-loup Gailly and Mark Adler, maintained continuously since 1995

---

## 2. Why

zlib is infrastructure. It sits underneath everything:

- **git objects** are zlib-compressed. libgit2 cannot function without zlib. This migration unblocks the libgit2 proposal.
- **Package archives** (tar.gz, .zip) use DEFLATE. The package manager needs decompression to extract downloaded packages.
- **HTTP content-encoding** uses gzip/deflate. The compiler's HTTP client (BearSSL-backed) needs decompression for compressed responses from package registries.
- **PNG images** use DEFLATE for pixel data compression.
- **ZIP files** use DEFLATE. Reading and writing .zip archives requires zlib.

Without native zlib, every one of these capabilities requires either a system library link or an external tool. With native zlib, they are all self-contained.

This is also the smallest and lowest-risk C library migration after PCRE2. It validates the migration tool on a different class of code (algorithmic/numerical rather than pattern-matching/state-machine) and produces a universally useful standard library module.

---

## 3. What It Enables

### 3.1 Unblocks libgit2

The primary immediate motivation. The libgit2 migration proposal is blocked on this. Every git read operation decompresses objects through zlib. Once `std.compress.zlib` exists, libgit2 migration can begin.

### 3.2 Package management

`with get` downloads compressed archives. Native decompression means no dependency on system `tar`, `gzip`, or `unzip`:

```with
use std.compress.zlib
use std.io

fn extract_tar_gz(archive_path: str, dest: str) -> Result[void, Error]:
    let compressed = file.read_bytes(archive_path)
    let decompressed = zlib.decompress(compressed)?
    tar.extract(decompressed, dest)
```

### 3.3 HTTP content-encoding

Package registries and APIs typically serve gzip-compressed responses. The HTTP client can decompress transparently:

```with
use std.compress.zlib
use std.net.http

fn fetch_json(url: str) -> Result[str, Error]:
    let response = http.get(url)?
    if response.header("Content-Encoding") == "gzip":
        return zlib.gunzip(response.body_bytes())?
    response.body()
```

### 3.4 Standard library compression

General-purpose compression available to any With program:

```with
use std.compress.zlib

// Compress data
let original = file.read_bytes("large_file.dat")
let compressed = zlib.compress(original, zlib.Level.Default)
file.write_bytes("large_file.dat.gz", zlib.gzip(compressed))

// Decompress data
let data = file.read_bytes("archive.gz")
let restored = zlib.gunzip(data)
```

### 3.5 Future: PNG, ZIP

With native zlib, writing a PNG encoder/decoder or ZIP reader/writer becomes straightforward -- the hard part (DEFLATE) is already done.

---

## 4. Migration Plan

### 4.1 Obtain and prepare

```bash
mkdir -p .reference/zlib
curl -L https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz \
    | tar xz -C .reference/zlib --strip-components=1
```

Pin to v1.3.1 (latest stable as of 2024, actively maintained).

### 4.2 Source inventory

zlib's source is compact and well-organized:

```
adler32.c    -- Adler-32 checksum (~50 lines of core logic)
compress.c   -- One-shot compression convenience function (~30 lines)
crc32.c      -- CRC-32 checksum with precomputed tables (~60 lines core)
deflate.c    -- DEFLATE compression engine (~1800 lines, the largest file)
gzclose.c    -- gzip file close (~30 lines)
gzlib.c      -- gzip file utility functions (~300 lines)
gzread.c     -- gzip file reading (~500 lines)
gzwrite.c    -- gzip file writing (~400 lines)
infback.c    -- Inflate using a callback interface (~300 lines)
inffast.c    -- Fast inflate for short codes (~300 lines)
inflate.c    -- DEFLATE decompression engine (~1500 lines)
inftrees.c   -- Huffman tree construction for inflate (~300 lines)
trees.c      -- Huffman tree construction for deflate (~1100 lines)
uncompr.c    -- One-shot decompression convenience function (~30 lines)
zutil.c      -- Utility functions (~100 lines)
```

Header files:

```
zlib.h       -- Public API (~1800 lines, mostly comments/documentation)
zconf.h      -- Configuration/platform detection
deflate.h    -- Internal deflate state
inffast.h    -- Internal inflate fast-path declarations
inflate.h    -- Internal inflate state
inftrees.h   -- Internal tree structures
trees.h      -- Static tree data
zutil.h      -- Internal utility macros
crc32.h      -- CRC-32 precomputed table
gzguts.h     -- Internal gzip state
```

Total: ~7K lines of implementation code plus ~8K lines of headers, comments, and tables.

### 4.3 What to migrate

**Include (core compression):**
- `adler32.c` -- checksum, needed by zlib format
- `crc32.c` -- checksum, needed by gzip format
- `deflate.c` + `trees.c` -- compression engine
- `inflate.c` + `inffast.c` + `inftrees.c` -- decompression engine
- `compress.c` + `uncompr.c` -- convenience one-shot functions
- `zutil.c` -- utility functions
- All internal headers

**Include if needed (gzip file I/O):**
- `gzlib.c` + `gzread.c` + `gzwrite.c` + `gzclose.c` -- gzip file operations. These wrap the core engine with FILE* I/O. May be better reimplemented in With using the runtime's file I/O rather than migrated, since they depend on C stdio.

**Exclude:**
- `infback.c` -- callback-based inflate interface, rarely used
- Test programs, examples, contrib/

### 4.4 Migrate

```bash
with migrate .reference/zlib/ \
    -o lib/std/compress/zlib/ \
    -I .reference/zlib \
    --no-c-export \
    --exclude minizip \
    --exclude test \
    --exclude examples
```

### 4.5 Expected migration challenges

zlib is cleaner C than PCRE2. No computed gotos, no macro-heavy codegen, no bit-manipulation spells. The main challenges:

- **Large precomputed tables** in `crc32.h` and `trees.h`. These are static const arrays. The migrator handles these (proven with PCRE2's character tables).
- **Macro-heavy configuration** in `zconf.h`. Platform detection macros (`_WIN32`, `__linux__`, `__APPLE__`). The migrator's `#ifdef` handling resolves these to the target platform at migration time. For cross-platform support, migrate once per platform or abstract behind With's runtime platform layer.
- **Pointer arithmetic in hot loops** in `deflate.c` and `inflate.c`. The migrator handles pointer arithmetic (proven with PCRE2). Performance-sensitive -- verify the migrated code produces the same output and comparable throughput.
- **longjmp for error recovery** in `gzlib.c`. If present, the migrator will flag these. Replace with With's error handling (Result types or early returns).
- **FILE* I/O** in the gzip file functions. These depend on C stdio. Better to reimplement the gzip convenience layer in With using runtime file I/O than to migrate the stdio wrappers.

### 4.6 Build a With-native API layer

The migrated code preserves zlib's C API. Layer a With-idiomatic API on top:

```
lib/std/compress/zlib/     -- migrated zlib internals (private)
lib/std/compress.w         -- public With API
```

The public API:

```with
// lib/std/compress.w
pub module zlib

pub enum Level: i32:
    None = 0
    BestSpeed = 1
    BestCompression = 9
    Default = 6

/// Compress data using the zlib format (RFC 1950).
pub fn compress(data: &[u8], level: Level) -> Vec[u8]

/// Decompress zlib-formatted data.
pub fn decompress(data: &[u8]) -> Result[Vec[u8], Error]

/// Compress data using the gzip format (RFC 1952).
pub fn gzip(data: &[u8]) -> Vec[u8]

/// Decompress gzip-formatted data.
pub fn gunzip(data: &[u8]) -> Result[Vec[u8], Error]

/// Compress raw DEFLATE (no header/trailer).
pub fn deflate_raw(data: &[u8], level: Level) -> Vec[u8]

/// Decompress raw DEFLATE.
pub fn inflate_raw(data: &[u8]) -> Result[Vec[u8], Error]

/// Streaming compressor for large data.
pub type Deflater { ... }
pub fn Deflater.new(level: Level) -> Deflater
pub fn Deflater.write(self: mut Deflater, data: &[u8]) -> Vec[u8]
pub fn Deflater.finish(self: mut Deflater) -> Vec[u8]

/// Streaming decompressor for large data.
pub type Inflater { ... }
pub fn Inflater.new() -> Inflater
pub fn Inflater.write(self: mut Inflater, data: &[u8]) -> Result[Vec[u8], Error]
pub fn Inflater.finish(self: mut Inflater) -> Result[Vec[u8], Error]
```

---

## 5. Verification

### 5.1 Correctness

zlib includes test vectors and a comprehensive test program. The primary correctness test:

1. Compress known data with the migrated implementation.
2. Decompress with the system zlib (or reference implementation) and verify the output matches.
3. Compress with the system zlib, decompress with the migrated implementation, verify the output matches.
4. Round-trip: compress then decompress, verify output equals input.
5. Test edge cases: empty input, single byte, maximum compression, incompressible data, corrupted input (must return error, not crash).

```bash
# Generate test data
dd if=/dev/urandom bs=1M count=10 of=/tmp/test_random.bin
dd if=/dev/zero bs=1M count=10 of=/tmp/test_zeros.bin
cp src/main.w /tmp/test_source.w

# Round-trip test
with run test/behavior/behav_zlib_roundtrip.w
```

### 5.2 Compatibility

Compressed output must be decompressible by any standard zlib/gzip implementation. Decompress must handle any valid zlib/gzip stream produced by any implementation. Test against:

- System zlib (`/usr/lib/libz`)
- gzip command-line tool
- Python's `zlib` module
- Node.js `zlib` module

### 5.3 Performance

Compression and decompression throughput should be within 2x of the C reference implementation. zlib's hot loops are pointer-intensive -- the migrator's pointer arithmetic translation is correct but may not match hand-optimized C performance. This is acceptable; correctness is the priority.

Benchmark:

```with
fn bench_compress(data: &[u8], iterations: i32):
    let start = clock_nanos()
    for _ in 0..iterations:
        let _ = zlib.compress(data, zlib.Level.Default)
    let elapsed = clock_nanos() - start
    let mb_per_sec = (data.len() * iterations) as f64 / (elapsed as f64 / 1e9) / 1e6
    print(f"compress: {mb_per_sec:.1} MB/s")
```

---

## 6. Risks

| Risk | Mitigation |
|---|---|
| Precomputed CRC/Huffman tables are large | The migrator handles static const arrays (proven with PCRE2 character tables). |
| Pointer arithmetic in hot loops | The migrator handles pointer arithmetic (proven with PCRE2). Verify correctness with round-trip tests. |
| Platform-specific optimizations (SSE, NEON) | zlib's core is portable C. Hardware-accelerated CRC is optional and can be added later. Migrate the portable path first. |
| stdio-dependent gzip file I/O | Reimplement gzip convenience layer in With using runtime file I/O instead of migrating C stdio wrappers. |
| Performance regression | Acceptable if within 2x. Correctness first. Optimize hot paths after migration if needed. |

---

## 7. Size Estimate

| Component | Estimated LOC | Notes |
|---|---|---|
| Core migration output (deflate + inflate) | ~8-12K | Compression and decompression engines |
| Checksum migration (adler32 + crc32) | ~1-2K | Including precomputed tables |
| Utility migration | ~500 | zutil and internal helpers |
| std.compress public API | ~200-400 | With-idiomatic wrapper |
| Gzip convenience layer (reimplemented) | ~200-300 | With file I/O instead of C stdio |
| Tests | ~300-500 | Round-trip, compatibility, edge cases |
| **Total** | **~10-15K migrated** | Plus ~700-1200 hand-written |

---

## 8. Timeline

This is a short migration. zlib is smaller than PCRE2 by 5x, cleaner C, and a well-understood algorithm. Estimated effort: 2-3 sessions.

```
Session 1: Migrate core (deflate, inflate, checksums, utilities)
           Verify round-trip correctness
Session 2: Build std.compress.zlib public API
           Gzip convenience layer
           Compatibility testing against system zlib
Session 3: Performance baseline
           Integration with existing HTTP client
           Edge case and error handling tests
```

After this lands, the libgit2 migration proposal is unblocked.

---

## 9. What This Unblocks

```
std.compress.zlib (this proposal)
  |
  +--> libgit2 migration (std.git)
  |      +--> build system: native git version/status
  |      +--> with get: git-based package fetching
  |      +--> with migrate: fetch from git URLs
  |
  +--> package archive extraction (tar.gz, .zip)
  |      +--> with get: extract downloaded packages
  |
  +--> HTTP content-encoding (gzip)
  |      +--> with get: compressed registry responses
  |
  +--> future: PNG, ZIP, compressed assets
```

---

## 10. Success Criteria

1. `std.compress.zlib` provides compress, decompress, gzip, and gunzip.
2. Round-trip correctness: compress then decompress produces identical output for all test inputs.
3. Cross-implementation compatibility: output is decompressible by system zlib, gzip, Python zlib.
4. Cross-implementation compatibility: can decompress streams produced by system zlib, gzip, Python zlib.
5. Works on Darwin, Linux, and Windows.
6. No system zlib link required. The implementation is pure migrated With code.
7. Performance within 2x of reference C implementation.
8. `with build && with build :fixpoint && with build :test` all pass.
9. libgit2 proposal is unblocked.