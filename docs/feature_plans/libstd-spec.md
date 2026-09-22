# lib/std — Standard Library Plan

> **Refreshed 2026-09-22** against main `f9c11b6d`: every module below carries
> a **Status** line taken from the tree, and the four sections the corpus
> sourcing plan resolved (Vec sorting, encoding, compress, regex) are
> collapsed to pointers. This is a *plan*, not a specification: since D48
> (`db6f935e`) the language specification no longer catalogues `lib/std`,
> and each landed module's own document (`docs/regex-spec.md`,
> `docs/std-encoding-rfc4648.md`, `docs/stdlib_sourcing_plan.md`) is
> authoritative for it.
>
> **Conformance note (D27, 2026-07-30):** the API sketches below predate the
> removal of `&mut T` from safe With (specification §3.1). Their `&mut`
> signatures are non-conforming and must be respelled (mut receivers,
> `[]mut T` slices, or threaded owned values) before implementation.
> Tracked in #739. Since 2026-09-22 (D55) `print` is `print[T: Display](v: &T)`
> and `Sender[T]` is `Clone`; sketches that assume the old shapes are read
> accordingly.

**The standard library for With.**

Small, correct, fast. Not a framework. Every module earns its place
by being something most programs need and that cannot be derived from
existing modules.

**Design principles:**

1. **Methods on types, not free functions.** Users discover APIs from
   the data type. `vec.sort(cmp)` not `sort(vec, cmp)`.
2. **Hardened code over fresh code — the sourcing rule (Eric, 2026-09-02;
   D37).** A *library* whose C implementation has stood the test of time
   (pcre2, zlib, the container corpora) is migrated **whole** with
   `with migrate`, kept as a coherent upstream-derived corpus (`.wo`
   bundle, upstream test suite as the drift lane), and **facaded**: the
   migrator is raw, the With-ness lives in the facade. *Runtime and
   low-level primitives* that are small and entangled with assembly or the
   allocator (fiber switch, crypto primitives, the allocator, entropy) are
   hand-ported and owned, held to upstream's known-answer vectors. "Pure
   With, no C dependency" is no longer a principle; "no hidden malloc in a
   user program" still is. `std.libc` is the one sanctioned libc seam.
3. **Borrow inputs, own outputs.** Auto-ref makes `&` invisible in user
   code; observing functions take `&T` (§3.8).
4. **No ecosystem encroachment.** No image codecs, database drivers,
   template engines, GUI, RPC, or frameworks. Those are ecosystem
   libraries.

---

## Existing Modules

What `lib/std` contains on main today. Listed for orientation — this
document does not redefine them; each module's header comment does.

| Module | Contents |
|---|---|
| `builtins` | `print[T: Display](v: &T)`, `eprint`, `assert`, `require`, `check`, `ToString` |
| `prelude`, `prelude_core`, `prelude_alloc` | Ambient imports |
| `option` | `Option[T]` — Some, None, unwrap, map |
| `result` | `Result[T, E]` — Ok, Err, ContextError, `?` operator |
| `traits` | Eq, Ord, Hash, Debug, Display, Default, Clone, Drop, Scoped, ScopedMut, Iter, IntoIter, MultiIndex, MultiIndexMut, Add/Sub/Mul/Div/MatMul/Neg, Try, ControlFlow, Deref, **Error** (`display`, `source`), Contains, IndexGet, IndexPlace |
| `collections` | Vec, HashMap, HashSet, BTreeMap, BTreeSet, SlotMap/Handle, Atomic, Order, fence, Iterable/IntoIter and the adapter family (Map, Filter, FilterMap, Take, Drop, TakeWhile, DropWhile, Zip, ZipWith, Enumerate, Chain, StepBy, FlatMap), IndexSpec |
| `collections/sorted_vec`, `collections/binary_heap`, `collections/trie`, `collections/hash_index`, `collections/engine_slot` | Facades over migrated engines (c-algorithms, TommyDS) — see *Sourced from corpora* |
| `box`, `rc` | `Box[T]` single-owner heap cell; `Rc[T]` explicit reference counting |
| `string`, `str`, `fixed_string`, `internal/str_abi` | String methods (ASCII classifiers); `str` shim; `FixedString[N]` for core/no_std; raw-pointer bridge |
| `fmt` | fmt_int, fmt_float, fmt_bool |
| `io` | read_line, read_bytes, read_all, print_str, print_line, print_int, write_raw, flush, `Stdin.lines` |
| `fs` | file_exists, read_file, write_file, create_dir, mkdir_p, remove_file, rename_file, remove_dir, remove_tree, copy_tree, symlink, list_files_text, chmod, `IoError` |
| `mem` | alloc, free_mem, mem_copy, mem_move, mem_set, mem_cmp |
| `alloc` | Arena, Pool |
| `hash` | Hasher, DefaultHasher, hash_str, hash_i64, combine |
| `math` | Seven helpers; transcendentals are width-generic compiler builtins (D42, `src/MathBuiltins.w`) |
| `process` | args, env, set_env, exit_code, pid, run, Command |
| `sys`, `sysinfo`, `os` | cpu_count, total_memory, page_size; os, arch, hostname; Layer-1 wrapper (os_kind, arch_kind, env, set_env, has_env, path_exists, posix_*) |
| `signal` | sigint, sigterm, sigkill, raise_signal |
| `random` | xorshift64 PRNG — seed, seed_now, next_i32, range_i32, chance |
| `time` | Duration, now, now_ns, sleep_secs, async sleep |
| `thread` | JoinHandle, spawn_os, join |
| `sync` | Mutex, RwLock, AtomicI64 |
| `task` | Task[T], await_all, await_first, await_any, await_settled, with_concurrency (`lib/std/async/*.md`) |
| `channel` | Sender[T] (`Clone`, close on last sender, `Send` iff `T: Send`), Receiver[T], chan[T](capacity) |
| `context` | Ambient execution record: TraceId, CancellationToken, `trait Logger`, NoopLogger, `Context` (ephemeral), default_context — *not* the cancellation tree of §2.5 |
| `net` | tcp_listen, tcp_accept, tcp_connect, udp_bind, udp_connect, send, recv, socket_close, sock_port |
| `http`, `tls` | https_get, https_download (private URL parsing); TlsConn, tls_connect/send/recv (TLS 1.2) |
| `json` | JsonParser, json_parse, json_find, json_str, json_int, json_skip |
| `encoding`, `encoding/*` | `DecodeError`; base64, base64url, base16, base32, base32hex (RFC 4648) |
| `crypto/*` | SHA-256, HMAC-SHA256, AES-128, AES-GCM, EC P-256, ECDSA, RSA PKCS#1 v1.5 verify, X.509, ChaCha20, Poly1305, ChaCha20-Poly1305, endian (private) |
| `regex`, `re/` | `Regex`/`Match`/`Captures` facade over migrated PCRE2 (`docs/regex-spec.md`) |
| `zlib`, `zip`, `zl/` | compress/decompress/gzip facade and ZIP reader over migrated zlib + minizip |
| `iter` | sum, iter_sum, map, filter, count, contains |
| `testing` | assert, require, check, assert_eq, assert_ne, assert_matches_failed |
| `ffi`, `component`, `compiler`, `build`, `libc`, `cfg/stackify` | Closure-context boxing for C callbacks (§16.7); ECS component ids; compiler-hook introspection; the typed build-graph API; the libc seam; Beyond-Relooper stackification (wasm32) |

### Planned separately

`std.math` (Array type, linalg, random, stats, fft, signal,
interpolate, optimize, integrate, special, io) is specified in
`docs/std-math-spec.md` — **not started** (no `lib/std/math/`; #1161
tracks first steps).

---

## Sourced from corpora

`docs/stdlib_sourcing_plan.md` (ruled 2026-09-12) settles which
containers and algorithms are *facades over migrated corpora* rather
than native modules, and the corpus registry (`build/corpus.w`,
`build/corpora.w`) wires each corpus as a `.wo` bundle with its upstream
test suite as the drift lane. What that resolves in this plan:

| Corpus | Phase / status | Facades landed | Resolves here |
|---|---|---|---|
| **pcre2** | landed (first bundle) | `std.regex` | §3.4 |
| **zlib + minizip** | landed (second bundle; minizip writer waits on setjmp #1217) | `std.zlib`, `std.zip` | §3.1, part of §3.2 |
| **c-algorithms** | Phase 1 landed 2026-09-13 (`5809ac10`) | `SortedVec[T]`, `BinaryHeap[T]`, `Trie[V]` (+ `engine_slot`) | part of §1.2 |
| **TommyDS** | Phase 2 landed 2026-09-14 (`#1139`) | `HashIndex[K, V]` over `hashdyn`; hash-engine benchmark recorded | comparison yardstick for the default map |
| **STC** | Phase 3 — **pending** (the macro-migrator campaign) | `Vec` engine, `Deque`, `Stack`, `Queue`, `PriorityQueue`, `List`, `HashMap`/`HashSet` (default engine), `OrderedMap`/`OrderedSet`, `BitSet`, spans, `std.algorithms` (`sort`, `binary_search`, bounds, `reverse`, `shuffle`) | §1.2 (#940), #938, #939 |
| **M\*LIB `m-bptree`** | Phase 4 — pending | `BTreeMap`/`BTreeSet` (retires the sorted-Vec implementation, #937) | — |

Sections below that the sourcing plan covers say so in their first line
and carry no native API to implement. Candidates named in other status
lines (`tomlc99`, `utf8proc`, `expat`) are *proposals under the sourcing
rule*, not selections; a corpus is added by a ruling and a registry entry.

---

## New Modules

Organized by implementation priority. Each tier must be substantially
complete before the next begins. Every section opens with its status on
main as of 2026-09-22.

---

### Tier 1 — Foundation

These modules are prerequisites for serious programs. Implement first.

#### 1.1 `std.path` — Cross-platform path manipulation

**Status (2026-09-22): not started.** No `lib/std/path.w`; path logic is duplicated privately in `lib/std/build.w` (`tool_path_dirname`, `build_path_dirname`). Native With; first in the refreshed sequencing.

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

**Resolved by the corpus sourcing plan (Phase 3, STC — pending).** `Vec.sort`, `sort_stable`, `is_sorted`, `binary_search`, `reverse`, `dedup` are the `std.algorithms` facade over STC's migrated algorithm layer (`docs/stdlib_sourcing_plan.md`, facade map rows `sort`/`binary_search`/`lower_bound`/`reverse`/`shuffle`; #940). `stable_sort` is exposed only if upstream's stability contract holds. Already landed from Phase 1: `std.collections.sorted_vec.SortedVec[T]` and `std.collections.binary_heap.BinaryHeap[T]` (c-algorithms). Nothing native is written for this section.

#### 1.3 `std.toml` — TOML parser

**Status (2026-09-22): not started.** No TOML parser anywhere in `lib/std` or `src/`. Sourcing candidate under the hardenedness rule: `tomlc99` (MIT, one `.c`/`.h`) migrated whole and facaded; else native.

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

**Resolved — landed 2026-08-31 (`aacace23`, `f89a4cec`), specified in `docs/std-encoding-rfc4648.md`.** `lib/std/encoding.w` (shared `DecodeError`: `InvalidLength`, `InvalidByte`, `InvalidPadding`, `NonCanonicalBits`) plus `encoding/base64.w` (`base64_encode`/`base64_decode`), `encoding/base64url.w`, `encoding/base16.w` (`base16_encode`/`base16_decode`), `encoding/base32.w`, `encoding/base32hex.w`. Module-prefixed names, `[]u8`/`&str` in, `Result[Vec[u8], DecodeError]` out. Not exposed: `encoded_len`/`decoded_len`, an upper-case hex encoder.

#### 1.5 `std.testing` — Test framework utilities

**Status (2026-09-22): partial (2 of 14).** `lib/std/testing.w` has `assert`, `require`, `check`, `assert_eq`, `assert_ne`, `assert_matches_failed` (the `expect_eq`/`expect_ne` of this section under the `assert_` name). The rest of the `expect_*` vocabulary, `fail`, `skip`, diff output: not started.

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

**Status (2026-09-22): not started.** No `Buf`; the endian helpers still live privately in `lib/std/crypto/endian.w` (see 3.7).

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

**Status (2026-09-22): not started.** `lib/std/context.w` carries a `trait Logger`/`NoopLogger` (see 2.5) that this module should absorb or build on.

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

**Status (2026-09-22): partial (trait landed, module not).** `trait Error { display, source }` is in `lib/std/traits.w:82` (`display` is this section's `message`); `ContextError` in `result.w`. `wrap`, `chain`, `ErrorChain`, `is`, `downcast`: not started.

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

**Status (2026-09-22): not started.** `string.w` has ASCII-only `is_alpha`/`is_digit`/`to_lower`/… on `i32` chars — same names, not codepoint semantics. Sourcing candidate: `utf8proc` (MIT, hardened, tables included) migrated whole and facaded — the shape of module the sourcing rule exists for.

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

**Status (2026-09-22): not started.** No `FlagSet`; argument parsing is ad hoc in `build.w` and the tools. Native With.

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

**Status (2026-09-22): diverged — the name is taken by a different design.** `lib/std/context.w` (2026-05-09) is an ambient execution record: `TraceId`, `CancellationToken`, `trait Logger`, `NoopLogger`, `type Context ephemeral`, `default_context()`. The Go-style cancellation tree below (`with_cancel`/`with_timeout`/`with_deadline`/`with_value`, `done`/`err`/`deadline`, `with`-block integration) is not started and must reconcile with the existing record rather than replace it silently — a design item to rule before implementation.

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

**Resolved by the corpus sourcing plan — landed (`1ca0beac`, `b509e340`).** `lib/std/zlib.w` is the facade over migrated zlib (`lib/std/zl/`, the second `.wo` bundle): `compress`, `compress_level`, `decompress`, `decompress_with_limit`, `compress_gzip`, `compress_gzip_level`, `decompress_gzip`, `decompress_gzip_with_limit`, `ZlibError`; `&Vec[u8]` in, `Result[Vec[u8], ZlibError]` out. The pure-With deflate this section demanded is superseded by the hardenedness rule. Not yet facaded: streaming `Inflater`/`Deflater` (the in-place `z_stream` resource — modeled-C stage 4b/D54 pinned resources are the mechanism) and raw-deflate entry points.

#### 3.2 `std.archive` — Tar

**Status (2026-09-22): tar not started; ZIP landed instead.** `lib/std/zip.w` (`ZipArchive.open`, `ZipEntry`, `extract`, `ZipError`) reads ZIP archives over minizip in the zlib corpus (`lib/std/zl/`); the minizip writer waits on `setjmp` (#1217). Tar: the format is small enough for native With; the sourcing rule does not demand a corpus for it.

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

**Status (2026-09-22): not started (0 of 12).** `net.w` is the original surface plus `socket_close`, `udp_connect`, `sock_port`. `IpAddr`/`SocketAddr`, `resolve`, socket options: none.

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

**Resolved — landed (`b0291d9f`), specified in `docs/regex-spec.md`.** `lib/std/regex.w` is the facade over migrated PCRE2 (`lib/std/re/`, the first `.wo` bundle): `Regex.compile`/`compile_flags`, `is_match`, `find`/`find_at`/`find_all`, `captures`/`captures_at`/`captures_all`, `replace`/`replace_all`/`replace_fn`, `split`/`splitn`, `Captures.get/by_name/text`, regex literals `/…/` with `=~`. Complete per its spec.

#### 3.5 `std.encoding.csv` — CSV reader/writer

**Status (2026-09-22): not started.** Native With (the format is small).

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

**Status (2026-09-22): not started.** Sourcing candidate: `expat` (MIT, hardened) migrated whole and facaded, if a full parser is wanted; the tokenizer below is small enough for native With.

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

**Status (2026-09-22): not started (0 exported).** All twelve functions exist by these exact names in `lib/std/crypto/endian.w` but are private and pointer+offset based; promotion is a slice-typed `pub` surface over them.

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

**Status (2026-09-22): not started.** No `random_bytes`/`random_fill` anywhere in `lib/std` outside the migrated corpora; the runtime entropy seam (`getrandom`/`SecRandomCopyBytes`/`BCryptGenRandom`) is the port to own natively under the sourcing rule (runtime primitive, not a library).

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

**Status (2026-09-22): not started.** Nothing of `stack_trace`/`on_panic`/`MemoryStats`; the native debug allocator (`docs/debug-allocator.md`) is the existing adjacent tooling.

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

**Status (2026-09-22): private partial.** `http_parse_url`/`HttpUrl`/`http_resolve_redirect` are private inside `lib/std/http.w`; this module is their promotion.

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

**Status (2026-09-22): not started.** `io.w` has `Stdin.lines()` returning a whole `Vec[str]`; no `BufReader`/`BufWriter`.

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

**Status (2026-09-22): partial (2 of 9), diverged.** `env`/`set_env` exist in *both* `process.w` and `os.w` (+ `has_env`, `args`) — a second surface instead of the consolidation asked for. `vars`, `remove`, `home_dir`, `temp_dir`, `current_dir`, `set_current_dir`, `current_exe`: none.

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

**Status (2026-09-22): not started.** Native With.

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

Scored 2026-09-22. The original 24-item order assumed pure-With delivery
for everything; the sourcing plan now carries the containers and
algorithms, so the native list is shorter and its "unblocks everything"
prefix (path, toml, bytes) is still entirely absent.

| Original # | Module | Outcome |
|---|---|---|
| 4 | `std.encoding` base64 + hex | **landed** to spec (`aacace23`, `f89a4cec`) — plus base32/base32hex |
| 15 | `std.regex` | **landed** via migrated PCRE2 |
| 12 | `std.compress` | **landed** via migrated zlib (facade `std.zlib`); streaming types open |
| 5 | `std.testing` | partial (`assert_*` only) |
| 8 | `std.errors` | partial (`Error` trait in `traits`) |
| 23 | `std.env` | partial and unconsolidated (duplicated in `process`/`os`) |
| 2 | Vec sort / search | → sourcing plan Phase 3 (STC), not started; #940 open |
| 1, 3, 6, 7, 9, 10, 11, 13, 14, 16–22, 24 | everything else | not started (`context` name taken by a different design) |

Refreshed order for the native remainder, by what it unblocks:

| # | Module | Rationale |
|---|---|---|
| 1 | `std.path` | Still unblocks fs, archive, process, env; duplicated privately in `build.w` today |
| 2 | `std.env` consolidation | One surface; `home_dir`/`temp_dir`/`current_dir` are prerequisites for path and tools |
| 3 | `std.bytes` + `std.encoding.binary` | Promote `crypto/endian.w`; foundation for binary protocols and tar |
| 4 | `std.testing` `expect_*` | Better tests for everything after |
| 5 | `std.log` | Absorb `context.w`'s `Logger`; needed for real programs |
| 6 | `std.flag` | CLI tools are the first users (the compiler's own tools included) |
| 7 | `std.toml` | With must parse its own config; sourcing candidate `tomlc99` to rule |
| 8 | `std.errors` chains | `wrap`/`chain` over the landed trait |
| 9 | `std.crypto.rand` | Runtime entropy seam (hand-ported primitive) |
| 10 | `std.unicode` | Sourcing candidate `utf8proc` to rule; else native tables |
| 11 | `std.archive.tar` | Native; ZIP reading already landed |
| 12 | `std.net` enhancements | DNS, addresses, socket options |
| 13 | `std.url` | Promote `http.w`'s private parser |
| 14 | `std.io.buffered` | Reduces syscall overhead |
| 15 | `std.context` cancellation | Reconcile with the existing `context.w` record (ruling) |
| 16 | `std.encoding.csv`, `.xml` | Data interchange; xml sourcing candidate `expat` to rule |
| 17 | `std.debug` | Stack traces, panic hooks |
| 18 | `std.semver` | Package management support |

Sourced items follow `docs/stdlib_sourcing_plan.md`'s own phase order
(STC, then M\*LIB) and are not re-sequenced here.

---

## Module Size Estimates

Native remainder only (pure With). Items delivered by a corpus facade
are sized by their facade, not the engine, and are not listed.

| Module | Estimated lines |
|---|---|
| `path` | 300–400 |
| `env` consolidation | 100–150 |
| `bytes` + `encoding.binary` | 400–500 |
| `testing` (`expect_*`) | 200–300 |
| `log` | 200–300 |
| `flag` | 300–500 |
| `toml` | 800–1200 native, or a facade over a migrated parser |
| `errors` chains | 150–200 |
| `crypto.rand` | 50–80 |
| `unicode` | 500–800 + tables native, or a facade over `utf8proc` |
| `archive.tar` | 400–600 |
| `net` enhancements | 300–400 |
| `url` | 200–300 |
| `io.buffered` | 200–300 |
| `context` cancellation | 300–400 |
| `encoding.csv` | 200–300 |
| `encoding.xml` | 400–600 native, or a facade over `expat` |
| `debug` | 200–400 |
| `semver` | 150–200 |
| **Total** | **~5,500–8,500** |
