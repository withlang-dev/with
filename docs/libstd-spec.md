# lib/std — Standard Library Specification

**The standard library for With.**

Small, correct, fast. Not a framework. Every module earns its place
by being something most programs need and that cannot be derived from
existing modules.

**Design principles:**

1. **Methods on types, not free functions.** Users discover APIs from
   the data type. `vec.sort(cmp)` not `sort(vec, cmp)`.
2. **Pure With over C wrappers.** When feasible, implement in With.
   No hidden malloc, no libc dependency for user programs. Enables
   bare metal.
3. **Borrow inputs, own outputs.** Auto-ref makes `&` invisible in
   user code.
4. **No ecosystem encroachment.** No image codecs, database drivers,
   template engines, GUI, RPC, or frameworks. Those are ecosystem
   libraries.

---

## Existing Modules

These modules exist and are working. Listed for completeness — this
spec does not redefine them.

| Module | Contents |
|---|---|
| `builtins` | print, eprint, assert, require, check, ToString |
| `prelude`, `prelude_core` | Ambient imports |
| `option` | `Option[T]` — Some, None, unwrap, map |
| `result` | `Result[T, E]` — Ok, Err, ContextError, `?` operator |
| `traits` | Eq, Ord, Hash, Debug, Display, Default, Clone, Drop, Scoped, ScopedMut, Iter, IntoIter, MultiIndex |
| `collections` | Vec, HashMap, HashSet, Atomic, VecIter, Order, fence |
| `string` | String methods — len, contains, find, split, replace, trim, slice |
| `fmt` | fmt_int, fmt_float, fmt_bool |
| `io` | read_line, read_bytes, print_str, write_raw, flush |
| `fs` | file_exists, read_file, write_file, create_dir, mkdir_p, remove_file |
| `mem` | alloc, free_mem, mem_copy, mem_move, mem_set, mem_cmp |
| `alloc` | Arena, Pool |
| `hash` | Hasher, DefaultHasher, hash_str, hash_i64, combine |
| `math` | Scalar: sqrt, sin, cos, pow, abs, min, max, clamp, PI, E, TAU |
| `process` | args, env, set_env, exit_code, system_cmd, pid, Command |
| `sys` | cpu_count, total_memory, page_size, memory_bandwidth |
| `sysinfo` | os, arch, hostname |
| `signal` | sigint, sigterm, sigkill, raise_signal |
| `random` | xorshift64 PRNG — seed, next_i32, range_i32, chance |
| `time` | Duration, now, now_ns, sleep_secs, async sleep |
| `thread` | JoinHandle, spawn_os, join |
| `sync` | Mutex, RwLock, AtomicI64 |
| `task` | Task[T], await_all, await_first, await_any, await_settled, with_concurrency |
| `channel` | Sender[T], Receiver[T], chan[T](capacity) |
| `net` | tcp_listen, tcp_accept, tcp_connect, udp_bind, send, recv |
| `http` | https_get, https_download |
| `tls` | TlsConn, tls_connect, tls_send, tls_recv (TLS 1.2) |
| `json` | JsonParser, json_parse, json_find, json_str, json_int, json_skip |
| `crypto/*` | SHA-256, HMAC-SHA256, AES-128, AES-GCM, EC P-256, ECDSA, X.509, ChaCha20, Poly1305, endian |
| `iter` | sum, map, filter, count, contains |

### Planned separately

`std.math` (Array type, linalg, random, stats, fft, signal,
interpolate, optimize, integrate, special, io) is specified in
`docs/std-math-spec.md`. Not repeated here.

---

## New Modules

Organized by implementation priority. Each tier must be substantially
complete before the next begins.

---

### Tier 1 — Foundation

These modules are prerequisites for serious programs. Implement first.

#### 1.1 `std.path` — Cross-platform path manipulation

```
type Path = {
    inner: str,
}

fn Path.new(s: str) -> Path
fn Path.join(self: &Self, other: &str) -> Path
fn Path.parent(self: &Self) -> Option[Path]
fn Path.filename(self: &Self) -> Option[str]
fn Path.stem(self: &Self) -> Option[str]
fn Path.extension(self: &Self) -> Option[str]
fn Path.is_absolute(self: &Self) -> bool
fn Path.is_relative(self: &Self) -> bool
fn Path.normalize(self: &Self) -> Path
fn Path.relative_to(self: &Self, base: &Path) -> Option[Path]
fn Path.with_extension(self: &Self, ext: &str) -> Path
fn Path.with_filename(self: &Self, name: &str) -> Path
fn Path.components(self: &Self) -> Vec[str]
fn Path.exists(self: &Self) -> bool
fn Path.is_file(self: &Self) -> bool
fn Path.is_dir(self: &Self) -> bool
fn Path.to_str(self: &Self) -> str

impl Display for Path
impl Eq for Path
```

Platform-aware separator handling. On Unix, `/`. On Windows, `\`
with `/` accepted. `normalize` resolves `.` and `..` lexically
(no syscalls). `exists`/`is_file`/`is_dir` are the only methods
that touch the filesystem.

#### 1.2 Vec sorting and search — methods on `collections.Vec`

```
fn Vec.sort(self: &mut Self, cmp: fn(&T, &T) -> i32)
fn Vec.sort_stable(self: &mut Self, cmp: fn(&T, &T) -> i32)
fn Vec.is_sorted(self: &Self, cmp: fn(&T, &T) -> i32) -> bool
fn Vec.binary_search(self: &Self, key: &T, cmp: fn(&T, &T) -> i32) -> Option[usize]
fn Vec.reverse(self: &mut Self)
fn Vec.dedup(self: &mut Self, eq: fn(&T, &T) -> bool)
```

`sort` uses pattern-defeating quicksort (pdqsort). `sort_stable`
uses merge sort. Both in pure With. No allocator dependency for
`sort`; `sort_stable` allocates a temporary buffer via the
standard allocator.

`binary_search` returns the index of a matching element, or None.
Requires the Vec to be sorted by the same comparator.

#### 1.3 `std.toml` — TOML parser

With uses `with.toml` for project configuration. The language must
parse its own config format.

```
type TomlValue =
    | String(str)
    | Integer(i64)
    | Float(f64)
    | Boolean(bool)
    | Array(Vec[TomlValue])
    | Table(TomlTable)
    | DateTime(str)

type TomlTable = HashMap[str, TomlValue]

fn parse(input: &str) -> Result[TomlTable, TomlError]
fn parse_file(path: &str) -> Result[TomlTable, TomlError]

fn TomlTable.get_str(self: &Self, key: &str) -> Option[str]
fn TomlTable.get_int(self: &Self, key: &str) -> Option[i64]
fn TomlTable.get_float(self: &Self, key: &str) -> Option[f64]
fn TomlTable.get_bool(self: &Self, key: &str) -> Option[bool]
fn TomlTable.get_array(self: &Self, key: &str) -> Option[&Vec[TomlValue]]
fn TomlTable.get_table(self: &Self, key: &str) -> Option[&TomlTable]

type TomlError = {
    message: str,
    line: i32,
    column: i32,
}
```

Pure With implementation. TOML v1.0 compliant. Supports:
- Basic and literal strings (including multiline)
- Integer formats (decimal, hex, octal, binary)
- Float (including inf, nan)
- Boolean
- Offset Date-Time, Local Date-Time, Local Date, Local Time
- Arrays and inline tables
- Standard tables and array-of-tables (`[[section]]`)
- Dotted keys (`a.b.c = value`)

No serialization in v1. Parse-only.

#### 1.4 `std.encoding` — Base64 and Hex

```
// std.encoding.base64

fn encode(data: &[u8]) -> str
fn decode(s: &str) -> Result[Vec[u8], DecodeError]
fn encode_url_safe(data: &[u8]) -> str
fn decode_url_safe(s: &str) -> Result[Vec[u8], DecodeError]
fn encoded_len(n: usize) -> usize
fn decoded_len(n: usize) -> usize

// std.encoding.hex

fn encode(data: &[u8]) -> str
fn decode(s: &str) -> Result[Vec[u8], DecodeError]
fn encode_upper(data: &[u8]) -> str
```

Pure With. No dependencies. RFC 4648 compliant for base64.

#### 1.5 `std.testing` — Test framework utilities

```
fn expect(cond: bool, msg: str)
fn expect_eq[T: Eq + Debug](actual: T, expected: T)
fn expect_ne[T: Eq + Debug](actual: T, expected: T)
fn expect_near(actual: f64, expected: f64, epsilon: f64)
fn expect_true(cond: bool)
fn expect_false(cond: bool)
fn expect_some[T](opt: Option[T]) -> T
fn expect_none[T](opt: Option[T])
fn expect_ok[T, E](res: Result[T, E]) -> T
fn expect_err[T, E](res: Result[T, E]) -> E
fn expect_contains(haystack: &str, needle: &str)
fn expect_starts_with(s: &str, prefix: &str)

fn fail(msg: str)
fn skip(reason: str)
```

On failure, prints:
- Expected vs actual values (using Debug formatting)
- Source location (file, line)
- Custom message if provided

Diff output for strings: show first point of divergence with
context lines.

Does not define test discovery or a test runner — that is the
compiler's responsibility (`with test`). This module provides
the assertion vocabulary.

#### 1.6 `std.bytes` — Byte buffer for binary protocols

```
type Buf = {
    data: Vec[u8],
    read_pos: usize,
    write_pos: usize,
}

// Construction
fn Buf.new() -> Buf
fn Buf.with_capacity(n: usize) -> Buf
fn Buf.from_slice(data: &[u8]) -> Buf
fn Buf.from_owned(data: Vec[u8]) -> Buf

// Properties
fn Buf.len(self: &Self) -> usize
fn Buf.cap(self: &Self) -> usize
fn Buf.remaining(self: &Self) -> usize
fn Buf.is_empty(self: &Self) -> bool

// Write (appends at write_pos, advances write_pos)
fn Buf.put_u8(self: &mut Self, v: u8)
fn Buf.put_u16_be(self: &mut Self, v: u16)
fn Buf.put_u16_le(self: &mut Self, v: u16)
fn Buf.put_u32_be(self: &mut Self, v: u32)
fn Buf.put_u32_le(self: &mut Self, v: u32)
fn Buf.put_u64_be(self: &mut Self, v: u64)
fn Buf.put_u64_le(self: &mut Self, v: u64)
fn Buf.put_i16_be(self: &mut Self, v: i16)
fn Buf.put_i16_le(self: &mut Self, v: i16)
fn Buf.put_i32_be(self: &mut Self, v: i32)
fn Buf.put_i32_le(self: &mut Self, v: i32)
fn Buf.put_i64_be(self: &mut Self, v: i64)
fn Buf.put_i64_le(self: &mut Self, v: i64)
fn Buf.put_f32_be(self: &mut Self, v: f32)
fn Buf.put_f32_le(self: &mut Self, v: f32)
fn Buf.put_f64_be(self: &mut Self, v: f64)
fn Buf.put_f64_le(self: &mut Self, v: f64)
fn Buf.put_bytes(self: &mut Self, data: &[u8])
fn Buf.put_str(self: &mut Self, s: &str)

// Read (reads at read_pos, advances read_pos)
fn Buf.get_u8(self: &mut Self) -> Result[u8, BufError]
fn Buf.get_u16_be(self: &mut Self) -> Result[u16, BufError]
fn Buf.get_u16_le(self: &mut Self) -> Result[u16, BufError]
fn Buf.get_u32_be(self: &mut Self) -> Result[u32, BufError]
fn Buf.get_u32_le(self: &mut Self) -> Result[u32, BufError]
fn Buf.get_u64_be(self: &mut Self) -> Result[u64, BufError]
fn Buf.get_u64_le(self: &mut Self) -> Result[u64, BufError]
fn Buf.get_i16_be(self: &mut Self) -> Result[i16, BufError]
fn Buf.get_i16_le(self: &mut Self) -> Result[i16, BufError]
fn Buf.get_i32_be(self: &mut Self) -> Result[i32, BufError]
fn Buf.get_i32_le(self: &mut Self) -> Result[i32, BufError]
fn Buf.get_i64_be(self: &mut Self) -> Result[i64, BufError]
fn Buf.get_i64_le(self: &mut Self) -> Result[i64, BufError]
fn Buf.get_f32_be(self: &mut Self) -> Result[f32, BufError]
fn Buf.get_f32_le(self: &mut Self) -> Result[f32, BufError]
fn Buf.get_f64_be(self: &mut Self) -> Result[f64, BufError]
fn Buf.get_f64_le(self: &mut Self) -> Result[f64, BufError]
fn Buf.get_bytes(self: &mut Self, n: usize) -> Result[Vec[u8], BufError]
fn Buf.get_str(self: &mut Self, n: usize) -> Result[str, BufError]

// Zero-copy views
fn Buf.peek_u8(self: &Self) -> Result[u8, BufError]
fn Buf.peek_bytes(self: &Self, n: usize) -> Result[&[u8], BufError]
fn Buf.as_slice(self: &Self) -> &[u8]
fn Buf.unread_slice(self: &Self) -> &[u8]

// Cursor control
fn Buf.advance(self: &mut Self, n: usize)
fn Buf.reset_read(self: &mut Self)
fn Buf.compact(self: &mut Self)
fn Buf.clear(self: &mut Self)

type BufError =
    | Underflow
    | Overflow
```

This is the foundation for binary protocol parsing: TLS, HTTP/2,
DNS, WebSocket frames, serialization formats. Consolidates the
endian byte manipulation currently scattered across `crypto/*`
and `net.w`.

Pure With. The `crypto/endian.w` module should be reimplemented
as methods on Buf (or deprecated in favor of Buf).

---

### Tier 2 — Real Programs

These modules make With viable for production CLI tools and servers.

#### 2.1 `std.log` — Structured logging

```
enum Level =
    | Trace
    | Debug
    | Info
    | Warn
    | Error

fn trace(msg: str)
fn debug(msg: str)
fn info(msg: str)
fn warn(msg: str)
fn error(msg: str)

fn set_level(level: Level)
fn set_writer(w: fn(str))

// Structured fields via builder:
fn log(level: Level, msg: str) -> LogEntry
fn LogEntry.field(self: Self, key: str, value: str) -> LogEntry
fn LogEntry.field_int(self: Self, key: str, value: i64) -> LogEntry
fn LogEntry.field_bool(self: Self, key: str, value: bool) -> LogEntry
fn LogEntry.emit(self: Self)
```

Default output: `2026-04-05T12:00:00Z INFO  message key=value`
(human-readable). Machine-readable JSON output via
`set_format(LogFormat.Json)`.

Global level filter. Messages below the level are dropped before
formatting (zero cost at call site beyond the level check).

Thread-safe. The writer function is called under a lock.

#### 2.2 `std.errors` — Enhanced error handling

```
trait Error:
    fn message(self: &Self) -> str
    fn source(self: &Self) -> Option[&dyn Error]

fn wrap[E: Error](err: E, msg: str) -> ContextError[E]
fn chain(err: &dyn Error) -> ErrorChain

type ErrorChain = {
    current: &dyn Error,
}

impl Iter[&dyn Error] for ErrorChain

fn is[E: Error](err: &dyn Error) -> bool
fn downcast[E: Error](err: &dyn Error) -> Option[&E]
```

The `Error` trait provides a standard interface for all error
types. `wrap` adds context messages. `chain` iterates the
`.source()` chain for display.

`ContextError` (already in `result.w`) is the concrete wrapper.
This module adds the trait and traversal utilities.

#### 2.3 `std.unicode` — Unicode and UTF-8

```
fn is_valid_utf8(data: &[u8]) -> bool
fn utf8_decode(data: &[u8]) -> Vec[i32]
fn utf8_encode(codepoint: i32) -> Vec[u8]
fn utf8_len(codepoint: i32) -> i32
fn codepoint_len_utf8(first_byte: u8) -> i32

// Codepoint iteration over strings
gen fn codepoints(s: &str) -> i32
gen fn grapheme_clusters(s: &str) -> str

// Unicode character properties
fn is_letter(cp: i32) -> bool
fn is_digit(cp: i32) -> bool
fn is_whitespace(cp: i32) -> bool
fn is_upper(cp: i32) -> bool
fn is_lower(cp: i32) -> bool
fn is_alphanumeric(cp: i32) -> bool
fn is_control(cp: i32) -> bool
fn is_punctuation(cp: i32) -> bool

fn to_upper(cp: i32) -> i32
fn to_lower(cp: i32) -> i32
fn to_title(cp: i32) -> i32

// Unicode category
enum Category =
    | Letter
    | Mark
    | Number
    | Punctuation
    | Symbol
    | Separator
    | Other

fn category(cp: i32) -> Category
```

The category tables are generated from UCD (Unicode Character
Database) at build time. Compressed via two-stage lookup table
to keep binary size reasonable (~30KB for the most common
properties).

Grapheme cluster segmentation follows UAX #29 (simplified: handles
the common cases, not the full Thai/Hangul complexity in v1).

#### 2.4 `std.flag` — Command-line argument parsing

```
type FlagSet = {
    name: str,
    description: str,
}

fn FlagSet.new(name: str, description: str) -> FlagSet

fn FlagSet.string(self: &mut Self, name: str, default: str, help: str) -> &str
fn FlagSet.int(self: &mut Self, name: str, default: i32, help: str) -> &i32
fn FlagSet.bool(self: &mut Self, name: str, default: bool, help: str) -> &bool
fn FlagSet.float(self: &mut Self, name: str, default: f64, help: str) -> &f64

fn FlagSet.parse(self: &mut Self, args: &[str]) -> Result[Vec[str], FlagError]
fn FlagSet.usage(self: &Self) -> str

fn FlagSet.add_subcommand(self: &mut Self, name: str, description: str) -> &mut FlagSet
fn FlagSet.subcommand(self: &Self) -> Option[&str]
```

Supports:
- `--flag value`, `--flag=value`
- `-f value`, `-f=value`
- Short flag combining: `-abc` = `-a -b -c`
- `--` to stop flag parsing
- Subcommands with their own flag sets
- Auto-generated `--help`

Positional arguments are returned as the `Vec[str]` from `parse`.

No derive macros, no proc macros, no code generation. Explicit
registration. This keeps it simple and debuggable.

#### 2.5 `std.context` — Cancellation, deadlines, and scoped values

```
type Context = opaque

fn background() -> Context
fn with_cancel(parent: &Context) -> (Context, CancelFn)
fn with_timeout(parent: &Context, timeout: Duration) -> (Context, CancelFn)
fn with_deadline(parent: &Context, deadline: Time) -> (Context, CancelFn)
fn with_value[V](parent: &Context, key: str, value: V) -> Context

type CancelFn = fn()

fn Context.done(self: &Self) -> bool
fn Context.err(self: &Self) -> Option[ContextError]
fn Context.deadline(self: &Self) -> Option[Time]
fn Context.value[V](self: &Self, key: str) -> Option[&V]

// Async integration
async fn Context.wait_done(self: &Self)

type ContextError =
    | Cancelled
    | DeadlineExceeded
```

**Integration with `with` blocks:**

```
with with_timeout(ctx, 5.seconds()) as (ctx, cancel):
    let result = do_work(ctx).await
    // ctx automatically cancelled when `with` scope exits
```

The `CancelFn` returned by `with_cancel`/`with_timeout`/
`with_deadline` is called automatically when the `with` block
exits (via Drop on the Context). This is the natural integration
point between `with` blocks, structured concurrency, and async
cancellation.

**Integration with tasks:**

```
async fn fetch_data(ctx: &Context) -> Result[Data, Error]:
    // Check cancellation
    if ctx.done():
        return Err(ctx.err().unwrap())

    // Or await cancellation alongside work
    select:
        data = http_get(url).await -> Ok(data)
        _ = ctx.wait_done().await -> Err(ContextError.Cancelled)
```

Context forms a tree. Cancelling a parent cancels all children.
Values propagate from parent to child (immutable, keyed lookup).

**Implementation:** Context is a tree node with a parent pointer,
a done flag (atomic bool), and an optional deadline. `wait_done`
parks the current fiber on a wait list; `cancel()` wakes all
parked fibers. Thread-safe via atomics.

---

### Tier 3 — Completeness

These round out the standard library for production use.

#### 3.1 `std.compress` — Compression

```
// std.compress.deflate

fn compress(data: &[u8]) -> Vec[u8]
fn compress_level(data: &[u8], level: i32) -> Vec[u8]
fn decompress(data: &[u8]) -> Result[Vec[u8], DeflateError]

// Streaming
type Deflater = { ... }
type Inflater = { ... }

fn Deflater.new(level: i32) -> Deflater
fn Deflater.write(self: &mut Self, data: &[u8]) -> Vec[u8]
fn Deflater.finish(self: &mut Self) -> Vec[u8]

fn Inflater.new() -> Inflater
fn Inflater.write(self: &mut Self, data: &[u8]) -> Result[Vec[u8], DeflateError]
fn Inflater.finish(self: &mut Self) -> Result[Vec[u8], DeflateError]

// std.compress.gzip — wraps deflate with gzip framing (RFC 1952)

fn compress(data: &[u8]) -> Vec[u8]
fn decompress(data: &[u8]) -> Result[Vec[u8], GzipError]

// std.compress.zlib — wraps deflate with zlib framing (RFC 1950)

fn compress(data: &[u8]) -> Vec[u8]
fn decompress(data: &[u8]) -> Result[Vec[u8], ZlibError]
```

**Pure With implementation.** No zlib dependency, no libc malloc.
Uses With's allocator throughout.

Inflate: ~500-800 lines. Deflate: ~1500 lines. Substantial but
straightforward — the algorithm is well-documented (RFC 1951).

Compression levels:
- 0: store (no compression)
- 1: fast (greedy matching)
- 6: default (lazy matching, reasonable hash chain)
- 9: best (maximum hash chain search)

This enables: HTTP content-encoding, tar.gz archives, PNG
(which uses deflate), and general data compression — all without
a C dependency.

#### 3.2 `std.archive` — Tar

```
// std.archive.tar

type TarReader = { ... }
type TarWriter = { ... }
type TarEntry = {
    name: str,
    size: i64,
    mode: i32,
    mod_time: Time,
    is_dir: bool,
    is_symlink: bool,
    link_target: str,
}

fn TarReader.open(path: &str) -> Result[TarReader, TarError]
fn TarReader.from_bytes(data: &[u8]) -> Result[TarReader, TarError]
fn TarReader.next(self: &mut Self) -> Option[Result[TarEntry, TarError]]
fn TarReader.read_data(self: &mut Self) -> Result[Vec[u8], TarError]
fn TarReader.extract_all(self: &mut Self, dest: &str) -> Result[(), TarError]

fn TarWriter.create(path: &str) -> Result[TarWriter, TarError]
fn TarWriter.add_file(self: &mut Self, path: &str, data: &[u8]) -> Result[(), TarError]
fn TarWriter.add_dir(self: &mut Self, path: &str) -> Result[(), TarError]
fn TarWriter.finish(self: &mut Self) -> Result[(), TarError]

// tar.gz support (composes with std.compress.gzip)
fn TarReader.open_gz(path: &str) -> Result[TarReader, TarError]
fn TarWriter.create_gz(path: &str) -> Result[TarWriter, TarError]
```

Supports POSIX.1-2001 (pax) extended headers for long filenames
and large files. UStar format for writing.

#### 3.3 `std.net` enhancements — DNS, addresses, socket options

```
// Address types
type IpAddr =
    | V4(u8, u8, u8, u8)
    | V6([u8; 16])

type SocketAddr = {
    ip: IpAddr,
    port: u16,
}

fn IpAddr.parse(s: &str) -> Result[IpAddr, ParseError]
fn SocketAddr.parse(s: &str) -> Result[SocketAddr, ParseError]
fn IpAddr.to_str(self: &Self) -> str
fn IpAddr.is_loopback(self: &Self) -> bool
fn IpAddr.is_private(self: &Self) -> bool

// DNS resolution
fn resolve(hostname: &str) -> Result[Vec[IpAddr], DnsError]
fn resolve_addr(hostname: &str, port: u16) -> Result[Vec[SocketAddr], DnsError]

// Socket options (on existing tcp/udp fds)
fn set_timeout(fd: i32, timeout: Duration)
fn set_nodelay(fd: i32, nodelay: bool)
fn set_keepalive(fd: i32, keepalive: bool)
fn set_reuseaddr(fd: i32, reuse: bool)
```

DNS resolution uses the system resolver (`getaddrinfo` via
`c_import`). This is one place where a C call is justified —
DNS resolution requires system configuration awareness
(`/etc/resolv.conf`, mDNS, etc.).

#### 3.4 `std.regex` — Regular expressions

Specified separately in `docs/regex-spec.md`.

Language-level regex literals (`/pattern/flags`), `=~`/`!~`
match operators with capture bindings, regex in `match` arms.
PCRE2 engine auto-migrated from C via `with migrate` (72K lines).
Full Perl-compatible syntax: backreferences, lookahead,
lookbehind, atomic groups, recursive patterns, Unicode
properties. ~300 lines of With wrapper API over migrated PCRE2.

#### 3.5 `std.encoding.csv` — CSV reader/writer

```
type CsvReader = { ... }
type CsvWriter = { ... }

fn CsvReader.from_str(data: &str) -> CsvReader
fn CsvReader.from_file(path: &str) -> Result[CsvReader, CsvError]
fn CsvReader.delimiter(self: Self, d: u8) -> Self
fn CsvReader.has_header(self: Self, h: bool) -> Self

gen fn CsvReader.records(self: &mut Self) -> Result[Vec[str], CsvError]
fn CsvReader.header(self: &Self) -> Option[&Vec[str]]

fn CsvWriter.to_file(path: &str) -> Result[CsvWriter, CsvError]
fn CsvWriter.delimiter(self: Self, d: u8) -> Self
fn CsvWriter.write_record(self: &mut Self, fields: &[str]) -> Result[(), CsvError]
fn CsvWriter.flush(self: &mut Self) -> Result[(), CsvError]
```

RFC 4180 compliant. Handles quoted fields, embedded newlines,
and embedded delimiters.

#### 3.6 `std.encoding.xml` — XML tokenizer

```
type XmlToken =
    | StartElement(str, Vec[XmlAttr])
    | EndElement(str)
    | CharData(str)
    | Comment(str)
    | ProcessingInstruction(str, str)
    | Doctype(str)

type XmlAttr = {
    name: str,
    value: str,
}

type XmlTokenizer = { ... }

fn XmlTokenizer.from_str(data: &str) -> XmlTokenizer
gen fn XmlTokenizer.tokens(self: &mut Self) -> Result[XmlToken, XmlError]
```

Tokenizer only. No DOM, no XPath, no schema validation.
Handles: elements, attributes, text, CDATA, comments, PIs,
entity references (`&amp;` `&lt;` `&gt;` `&apos;` `&quot;`).
Does not handle: DTD processing, external entities, namespaces
(beyond passing through prefixed names as-is).

#### 3.7 `std.encoding.binary` — Endian primitives

Promote the existing `crypto/endian.w` to a proper module.

```
fn u16_from_be(data: &[u8]) -> u16
fn u16_from_le(data: &[u8]) -> u16
fn u32_from_be(data: &[u8]) -> u32
fn u32_from_le(data: &[u8]) -> u32
fn u64_from_be(data: &[u8]) -> u64
fn u64_from_le(data: &[u8]) -> u64

fn u16_to_be(v: u16) -> [u8; 2]
fn u16_to_le(v: u16) -> [u8; 2]
fn u32_to_be(v: u32) -> [u8; 4]
fn u32_to_le(v: u32) -> [u8; 4]
fn u64_to_be(v: u64) -> [u8; 8]
fn u64_to_le(v: u64) -> [u8; 8]
```

These are also available via `std.bytes.Buf` methods. This
module exists for code that manipulates raw byte slices without
a Buf.

#### 3.8 `std.crypto.rand` — Cryptographic randomness

```
fn random_bytes(n: usize) -> Vec[u8]
fn random_u32() -> u32
fn random_u64() -> u64
fn random_fill(buf: &mut [u8])
```

macOS: `SecRandomCopyBytes` via Security framework.
Linux: `getrandom(2)` syscall.

This is the entropy source that seeds `std.random` and is used
by `std.crypto` (TLS client random, ECDHE ephemeral keys, etc.).
Currently internal to the crypto modules — expose it.

#### 3.9 `std.debug` — Debug utilities

```
fn stack_trace() -> Vec[StackFrame]
fn print_stack_trace()

type StackFrame = {
    function: str,
    file: str,
    line: i32,
}

fn on_panic(handler: fn(&str))
fn memory_usage() -> MemoryStats

type MemoryStats = {
    allocated: usize,
    freed: usize,
    peak: usize,
}
```

Stack traces use DWARF debug info when available (debug builds).
In release builds, `stack_trace` returns addresses only.

`on_panic` registers a handler called before the default panic
behavior (print + abort). Useful for crash reporting.

---

### Tier 4 — Before 1.0

Nice to have. Not blocking, but expected by the time With
reaches 1.0.

#### 4.1 `std.url` — URL parsing

```
type Url = {
    scheme: str,
    host: str,
    port: Option[u16],
    path: str,
    query: Option[str],
    fragment: Option[str],
    userinfo: Option[str],
}

fn Url.parse(s: &str) -> Result[Url, UrlError]
fn Url.to_str(self: &Self) -> str

fn query_encode(s: &str) -> str
fn query_decode(s: &str) -> Result[str, UrlError]
fn query_parse(s: &str) -> Vec[(str, str)]
```

RFC 3986 compliant parsing.

#### 4.2 `std.io.buffered` — Buffered I/O

```
type BufReader = { ... }
type BufWriter = { ... }

fn BufReader.new(fd: i32) -> BufReader
fn BufReader.new_sized(fd: i32, capacity: usize) -> BufReader
fn BufReader.read_line(self: &mut Self) -> Option[str]
fn BufReader.read_bytes(self: &mut Self, n: usize) -> Vec[u8]
fn BufReader.read_until(self: &mut Self, delim: u8) -> Vec[u8]
fn BufReader.peek(self: &Self, n: usize) -> &[u8]
gen fn BufReader.lines(self: &mut Self) -> str

fn BufWriter.new(fd: i32) -> BufWriter
fn BufWriter.new_sized(fd: i32, capacity: usize) -> BufWriter
fn BufWriter.write(self: &mut Self, data: &[u8])
fn BufWriter.write_str(self: &mut Self, s: &str)
fn BufWriter.flush(self: &mut Self)
```

Default buffer size: 8KB. Reduces syscall overhead for
line-at-a-time I/O.

#### 4.3 `std.env` — Environment utilities

Consolidate and extend `process.env`/`process.set_env`:

```
fn vars() -> HashMap[str, str]
fn get(name: &str) -> Option[str]
fn set(name: &str, value: &str)
fn remove(name: &str)
fn home_dir() -> Option[Path]
fn temp_dir() -> Path
fn current_dir() -> Result[Path, Error]
fn set_current_dir(path: &Path) -> Result[(), Error]
fn current_exe() -> Result[Path, Error]
```

#### 4.4 `std.semver` — Semantic versioning

```
type Version = {
    major: i32,
    minor: i32,
    patch: i32,
    pre: str,
    build: str,
}

fn Version.parse(s: &str) -> Result[Version, ParseError]
fn Version.to_str(self: &Self) -> str

impl Eq for Version
impl Ord for Version

fn satisfies(version: &Version, constraint: &str) -> bool
```

SemVer 2.0.0 compliant. `satisfies` supports: `^1.2.3`,
`~1.2.3`, `>=1.0.0 <2.0.0`, `1.2.*`.

---

## What std Does NOT Include

| Category | Reason |
|---|---|
| Image codecs (PNG, JPEG, GIF) | Ecosystem library |
| Database drivers | Too opinionated for std |
| Template engines | Too opinionated for std |
| Reflection / `any` type | Conflicts with static type philosophy |
| SIMD intrinsics | LLVM auto-vectorizes; expose later if needed |
| HTTP server | Ecosystem library |
| RPC / protobuf | Ecosystem library |
| GUI / TUI | Ecosystem library |
| ORM / query builder | Ecosystem library |
| Markdown / rich text | Ecosystem library |

---

## Implementation Sequencing

Priority order. Each item should be substantially complete (passing
tests, documented) before moving to the next.

| # | Module | Rationale |
|---|---|---|
| 1 | `std.path` | Unblocks fs, archive, process, env |
| 2 | Vec.sort / binary_search | Fundamental collection operation |
| 3 | `std.toml` | With must parse its own config format |
| 4 | `std.encoding.base64` + `hex` | Tiny, high value, unblocks crypto/network |
| 5 | `std.testing` | Better tests for everything after |
| 6 | `std.bytes` | Foundation for binary protocols |
| 7 | `std.log` | Needed for debugging real programs |
| 8 | `std.errors` | Better error chains |
| 9 | `std.unicode` | Correctness foundation for string ops |
| 10 | `std.flag` | CLI tools are first users |
| 11 | `std.context` | Connects `with` blocks to async cancellation |
| 12 | `std.compress` | Unblocks archive, HTTP content-encoding |
| 13 | `std.archive.tar` | Package distribution |
| 14 | `std.net` enhancements | DNS, addresses, socket options |
| 15 | `std.regex` | Text processing workhorse |
| 16 | `std.encoding.csv` | Data interchange |
| 17 | `std.encoding.xml` | Data interchange |
| 18 | `std.encoding.binary` | Promote crypto/endian |
| 19 | `std.crypto.rand` | Expose existing entropy source |
| 20 | `std.debug` | Stack traces, panic hooks |
| 21 | `std.url` | URL parsing for HTTP client |
| 22 | `std.io.buffered` | Reduces syscall overhead |
| 23 | `std.env` | Consolidate environment access |
| 24 | `std.semver` | Package management support |

---

## Module Size Estimates

| Module | Estimated lines (pure With) |
|---|---|
| `path` | 300–400 |
| Vec sort/search | 400–600 |
| `toml` | 800–1200 |
| `encoding.base64` | 100–150 |
| `encoding.hex` | 50–80 |
| `testing` | 200–300 |
| `bytes` | 400–500 |
| `log` | 200–300 |
| `errors` | 150–200 |
| `unicode` | 500–800 + tables |
| `flag` | 300–500 |
| `context` | 300–400 |
| `compress.deflate` | 1500–2300 |
| `compress.gzip` | 100–150 (framing over deflate) |
| `archive.tar` | 400–600 |
| `net` enhancements | 300–400 |
| `regex` | 2000–3000 |
| `encoding.csv` | 200–300 |
| `encoding.xml` | 400–600 |
| `encoding.binary` | 100 (promote existing) |
| `crypto.rand` | 50–80 |
| `debug` | 200–400 |
| `url` | 200–300 |
| `io.buffered` | 200–300 |
| `env` | 100–150 |
| `semver` | 150–200 |
| **Total** | **~9,000–13,000** |
