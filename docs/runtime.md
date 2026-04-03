# Eliminating libc — Runtime Plan (v2)

## Design

The standard library calls a runtime interface. The runtime
interface has one implementation per target. The stdlib never
knows what platform it's on.

```
User code → std.io / std.fs / std.mem → rt_* interface → platform backend
```

Adding a platform means writing one backend file. The stdlib
and all user code are unchanged.

---

## The Interface

```
// I/O
fn rt_write(fd: i32, buf: *const u8, len: usize) -> isize
fn rt_read(fd: i32, buf: *mut u8, len: usize) -> isize
fn rt_open(path: *const u8, flags: i32, mode: i32) -> i32
fn rt_close(fd: i32) -> i32
fn rt_seek(fd: i32, offset: i64, whence: i32) -> i64
fn rt_stat(path: *const u8, out: *mut StatBuf) -> i32
fn rt_getcwd(buf: *mut u8, size: usize) -> i32

// Memory
fn rt_mmap(size: usize) -> *mut u8
fn rt_munmap(ptr: *mut u8, size: usize)

// Process
fn rt_exit(code: i32) -> !
fn rt_args() -> (*const *const u8, i32)    // (argv, argc)

// Time
fn rt_clock_ns() -> i64

// Environment
fn rt_getenv(name: *const u8) -> *const u8
```

Thirteen functions. Everything in the standard library is built
from these.

`rt_alloc` and `rt_free` are NOT in this interface. The allocator
is a stdlib component written in With, backed by `rt_mmap`/`rt_munmap`.
The runtime interface is the OS boundary. The allocator is above it.

### Error convention

**All `rt_*` functions that can fail return negative values on
error.** The negative value is the negated error code (e.g., -2
for ENOENT, -13 for EACCES). This is the convention regardless
of platform — each backend is responsible for converting
platform-specific error reporting into negative returns.

```
let fd = rt_open(path, O_RDONLY, 0)
if fd < 0:
    // fd is -errno
    let err = -fd    // positive error code
```

Functions that return pointers (`rt_mmap`, `rt_getenv`) return
`null` on failure.

`rt_mmap` returns `null` on failure, never a sentinel like
MAP_FAILED. The backend converts.

`rt_clock_ns` does not fail. On platforms without a clock (bare
metal without a timer), it returns 0.

This convention means `std/*` has exactly one error-checking
pattern: `if result < 0`. No errno, no GetLastError, no
platform-specific error retrieval. The backend absorbs all of that.

### Error codes

```
enum RtError =
    | EPERM   = 1
    | ENOENT  = 2
    | EIO     = 5
    | EBADF   = 9
    | EAGAIN  = 11
    | ENOMEM  = 12
    | EACCES  = 13
    | EEXIST  = 17
    | ENOTDIR = 20
    | EISDIR  = 21
    | EINVAL  = 22
    | ENFILE  = 23
    | EMFILE  = 24
    | ENOSPC  = 28
    | EPIPE   = 32
    | ERANGE  = 34
    | ENOSYS  = 38
```

These are the POSIX values. Every backend maps its native error
codes to this set. Unmappable errors become `EIO` (general I/O
error). The set is small by design — std.io and std.fs only need
to distinguish a handful of failure modes.

**EINTR rule:** Backends must retry internally on EINTR (interrupted
system call). The stdlib never sees EINTR. If a syscall returns
EINTR, the backend re-issues it. This means `rt_write` and
`rt_read` may block longer than a single syscall, but the stdlib
doesn't need retry loops for signal-interrupted I/O.

### Function reference

**`rt_write(fd, buf, len) -> isize`**
Write `len` bytes from `buf` to file descriptor `fd`. Returns
bytes written (>= 0) or negative error code. Partial writes are
possible (return value < len).

**`rt_read(fd, buf, len) -> isize`**
Read up to `len` bytes from `fd` into `buf`. Returns bytes read
(>= 0, 0 = EOF) or negative error code.

**`rt_open(path, flags, mode) -> i32`**
Open a file. Returns file descriptor (>= 0) or negative error.
Flags: O_RDONLY=0, O_WRONLY=1, O_RDWR=2, O_CREAT=0x200,
O_TRUNC=0x400, O_APPEND=0x800. The backend maps these to native
values.

**`rt_close(fd) -> i32`**
Close file descriptor. Returns 0 or negative error.

**`rt_seek(fd, offset, whence) -> i64`**
Seek. whence: SEEK_SET=0, SEEK_CUR=1, SEEK_END=2. Returns new
position or negative error.

**`rt_stat(path, out) -> i32`**
File metadata. Returns 0 or negative error. Fills `StatBuf`:

```
type StatBuf = {
    size: i64,
    is_dir: bool,
    is_file: bool,
    modified_ns: i64,    // nanoseconds since epoch
}
```

`StatBuf` is the stdlib's view of metadata — not the OS struct.
The backend converts from native stat to this layout.

**`rt_getcwd(buf, size) -> i32`**
Write current working directory into `buf` as null-terminated
string. Returns 0 or negative error (ERANGE if buffer too small).

**`rt_mmap(size) -> *mut u8`**
Allocate `size` bytes of anonymous memory. Returns pointer or
null on failure. Guarantees:
- Memory is zero-initialized.
- Memory is readable and writable.
- Alignment is at least page size (typically 4096 or 16384).
These guarantees hold on every platform. Backends that use
underlying APIs with different defaults must enforce them.

**`rt_munmap(ptr, size)`**
Release memory previously obtained from `rt_mmap`. No return
value — failure is fatal (corrupted state).

**`rt_exit(code) -> !`**
Terminate the process.

**`rt_args() -> (*const *const u8, i32)`**
Return (argv, argc) captured at program start. Backends store
args in static memory allocated during `_start`. The pointers
returned are valid for the process lifetime. On platforms that
provide arguments in non-UTF-8 encoding (Windows UTF-16), the
backend converts to UTF-8 during startup.

**`rt_clock_ns() -> i64`**
Monotonic clock in nanoseconds. Suitable for measuring elapsed
time. Not wall-clock (not affected by system time changes).
Returns 0 on platforms without a timer.

**`rt_getenv(name) -> *const u8`**
Look up environment variable. Returns pointer to value string
(null-terminated) or null if not found. The pointer is valid for
the process lifetime (points into the environment block).

---

## Platform Backends

Each backend implements the thirteen functions above.

```
rt/darwin_aarch64.s + rt/darwin_aarch64.w
rt/darwin_x86_64.s  + rt/darwin_x86_64.w
rt/linux_aarch64.s  + rt/linux_aarch64.w
rt/linux_x86_64.s   + rt/linux_x86_64.w
rt/windows_x86_64.w
rt/freestanding.w
```

| Target      | Strategy            | Reason                              |
|-------------|---------------------|-------------------------------------|
| Linux       | Raw syscalls        | Stable ABI                          |
| macOS       | libSystem wrappers  | Syscall ABI not guaranteed stable   |
| Windows     | Win32 / NT APIs     | No public syscall ABI               |
| Freestanding| User hooks          | No OS                               |

### Per-function backend mapping

| rt_* function | Linux | macOS | Windows | Freestanding |
|---|---|---|---|---|
| `rt_write` | `write` (syscall 64/1) | `write` (libSystem) | `WriteFile` | user hook |
| `rt_read` | `read` (syscall 63/0) | `read` (libSystem) | `ReadFile` | user hook |
| `rt_open` | `openat` (syscall 56/2) | `open` (libSystem) | `CreateFileW` | user hook |
| `rt_close` | `close` (syscall 57/3) | `close` (libSystem) | `CloseHandle` | user hook |
| `rt_seek` | `lseek` (syscall 62/8) | `lseek` (libSystem) | `SetFilePointerEx` | user hook |
| `rt_stat` | `fstatat` (syscall 79/...) | `stat` (libSystem) | `GetFileAttributesExW` | user hook |
| `rt_getcwd` | `getcwd` (syscall 17/...) | `getcwd` (libSystem) | `GetCurrentDirectoryW` | returns "/" |
| `rt_mmap` | `mmap` (syscall 222/9) | `mmap` (libSystem) | `VirtualAlloc` | static pool |
| `rt_munmap` | `munmap` (syscall 215/11) | `munmap` (libSystem) | `VirtualFree` | no-op |
| `rt_exit` | `exit_group` (syscall 94/231) | `exit` (libSystem) | `ExitProcess` | halt loop |
| `rt_args` | from stack at `_start` | from stack at `_start` | `GetCommandLineW` + parse | empty |
| `rt_clock_ns` | `clock_gettime` (syscall 113/228) | `mach_absolute_time` (libSystem) | `QueryPerformanceCounter` | return 0 |
| `rt_getenv` | walk envp from `_start` | `getenv` (libSystem) | `GetEnvironmentVariableW` | return null |

Linux syscall numbers: first is aarch64, second is x86_64.

### Freestanding backend

The freestanding backend provides stubs:

```
fn rt_write(fd: i32, buf: *const u8, len: usize) -> isize: -EIO
fn rt_read(fd: i32, buf: *mut u8, len: usize) -> isize: -EIO
fn rt_open(path: *const u8, flags: i32, mode: i32) -> i32: -ENOSYS
fn rt_close(fd: i32) -> i32: -ENOSYS
fn rt_seek(fd: i32, offset: i64, whence: i32) -> i64: -ENOSYS
fn rt_stat(path: *const u8, out: *mut StatBuf) -> i32: -ENOSYS
fn rt_getcwd(buf: *mut u8, size: usize) -> i32: -ENOSYS
fn rt_mmap(size: usize) -> *mut u8: null
fn rt_munmap(ptr: *mut u8, size: usize): // no-op
fn rt_exit(code: i32) -> !: loop {}
fn rt_args() -> (*const *const u8, i32): (null, 0)
fn rt_clock_ns() -> i64: 0
fn rt_getenv(name: *const u8) -> *const u8: null
```

Each function can be overridden by linking a user-provided
implementation. The stubs ensure the program compiles and links.
Functions that are called but not overridden return clean error
values rather than crashing.

For bare metal with UART output, the user overrides `rt_write`
to push bytes to the UART. For embedded with static memory, the
user overrides `rt_mmap` to carve from a static pool. Everything
else is opt-in.

### Windows notes

Windows has no fd-based I/O — it uses `HANDLE`. The Windows
backend maintains a small fd-to-HANDLE table (stdin=0, stdout=1,
stderr=2 pre-populated). `rt_open` returns an fd, internally
mapping to the `HANDLE` from `CreateFileW`. `rt_close` releases
the mapping. This is the same approach as MSVC's POSIX
compatibility layer, but simpler (no full CRT).

Windows path handling: `rt_open` accepts UTF-8 paths. The backend
converts to UTF-16 for `CreateFileW`. The conversion function is
part of the Windows backend, not exposed to the stdlib.

---

## Entry Point

Every hosted backend provides `_start` (or platform equivalent):

```
// Pseudocode — actual implementation is per-platform assembly
_start:
    capture argc, argv from platform convention
    store to static for rt_args()
    call with_main(argc, argv)
    call rt_exit(return_value)
```

With generates `with_main(argc: i32, argv: **u8)` instead of
`main`. The runtime owns startup. No libc crt0.

**Linux aarch64:** argc at `[sp]`, argv at `[sp+8]`.
**Linux x86_64:** argc at `[rsp]`, argv at `[rsp+8]`.
**macOS:** Same stack layout, but `_start` must be `_main` if
linking with libSystem's crt (or `_start` with `-static`).
**Windows:** Entry is `mainCRTStartup` or `WinMainCRTStartup`.
`GetCommandLineW` provides arguments.
**Freestanding:** User provides entry point.

---

## Allocator

A single allocator in `std/mem.w`, written in With, backed by
`rt_mmap`/`rt_munmap`. No malloc, no free, no libc.

**v1: simple freelist.**

- `rt_mmap` acquires pages from the OS (64KB chunks).
- Small allocations (<= 4096): freelist with size classes
  (16, 32, 64, 128, 256, 512, 1024, 2048, 4096 bytes).
- Large allocations (> 4096): direct `rt_mmap`, direct `rt_munmap`.
- Alignment: all allocations are 16-byte aligned minimum.
  `alloc_aligned(size, align)` for larger alignment (std.math
  needs 64-byte for SIMD).
- Thread safety deferred (single-threaded v1).

This is not a high-performance allocator. It's a correct one.
The compiler's allocation patterns (many small Vec/HashMap
allocations) work fine with a freelist. Optimize later with
profiling data.

### Interface

```
fn alloc(size: usize) -> *mut u8
fn alloc_aligned(size: usize, align: usize) -> *mut u8
fn realloc(ptr: *mut u8, old_size: usize, new_size: usize) -> *mut u8
fn free(ptr: *mut u8)
fn free_sized(ptr: *mut u8, size: usize)
```

`free_sized` is the preferred path when the caller knows the size
(Vec and HashMap do). It avoids the freelist having to look up the
allocation size. `free` works without a size (stores size in a
header before the pointer) but is slightly slower.

---

## Formatting

f-strings currently lower to `snprintf`. This is the hidden libc
dependency that survives even after replacing I/O and allocation.

Replace with:

**Integer formatting:** Digit extraction loop. ~30 lines.
Handles i32, i64, u32, u64, hex, binary, octal, and zero-padding.

**Float formatting:** Port Ryu (f64 → decimal string). ~400 lines.
Public domain C implementations exist. Required because the
compiler itself uses f-strings with floats in diagnostics.

**Formatting guarantees (all platforms):**
- Locale-independent. Decimal separator is always `.`.
- NaN formats as `nan`. Infinity formats as `inf`, `-inf`.
- Output is deterministic: the same f64 value produces the same
  string on every platform, every time.
- No dependency on the C runtime's printf or locale machinery.

**String formatting:** The f-string lowering in the compiler
currently emits calls to `snprintf`. Change it to emit calls to
`std.fmt.write_i64`, `std.fmt.write_f64`, `std.fmt.write_str`,
writing into a `std.fmt.Buffer` that grows via `std.mem.alloc`.

This must land in the same phase as the allocator — formatting
allocates, and the allocator is needed for formatting buffers.

### Format buffer

```
type FmtBuffer = {
    ptr: *mut u8,
    len: usize,
    cap: usize,
}

fn fmt_buf_new() -> FmtBuffer
fn fmt_buf_write_str(buf: &mut FmtBuffer, s: str)
fn fmt_buf_write_i64(buf: &mut FmtBuffer, v: i64, spec: FmtSpec)
fn fmt_buf_write_f64(buf: &mut FmtBuffer, v: f64, spec: FmtSpec)
fn fmt_buf_write_char(buf: &mut FmtBuffer, c: u8)
fn fmt_buf_to_str(buf: FmtBuffer) -> str

type FmtSpec = {
    width: i32,         // minimum field width (0 = unset)
    precision: i32,     // decimal places for float (-1 = default)
    fill: u8,           // padding character (default ' ')
    align: u8,          // '<' left, '>' right, '^' center
    sign: u8,           // '+' always, '-' negative only, ' ' space
    base: u8,           // 10, 16, 8, 2
    uppercase: bool,    // hex: 'A'-'F' vs 'a'-'f'
}
```

The compiler lowers `f"hello {x} world {y:.2}"` to:

```
let __buf = fmt_buf_new()
fmt_buf_write_str(&__buf, "hello ")
fmt_buf_write_i64(&__buf, x, FMT_DEFAULT)
fmt_buf_write_str(&__buf, " world ")
fmt_buf_write_f64(&__buf, y, FmtSpec { precision: 2, ... })
let __result = fmt_buf_to_str(__buf)
```

Types that implement a `Format` trait get `fmt_buf_write_format`
calls instead, passing the buffer and spec to the trait method.

---

## Phases

### Phase 1: I/O + exit + entry point + integer formatting

Implement:
- `rt_write`, `rt_exit`, `rt_args` for first target
- `_start` entry point
- Integer-to-string formatting (`std/fmt.w` — integer path only)
- Wire `print`/`eprint` through `rt_write`

Test: compile a program that prints integers. Verify the binary
links only the expected platform library (or nothing, on Linux).

### Phase 2: Allocator + float formatting + f-strings

Implement:
- `rt_mmap`/`rt_munmap` for first target
- Freelist allocator in `std/mem.w`
- Float formatting (Ryu port)
- `FmtBuffer` and full f-string lowering rewrite
- Replace all `malloc`/`free` calls with `std.mem.alloc`/`free`

Test: compile a program using Vec, HashMap, f-strings with floats.
Verify no libc symbols.

### Phase 3: File I/O + clock + environment

Implement:
- `rt_open`, `rt_close`, `rt_read`, `rt_seek`, `rt_stat` for first target
- `rt_getcwd`, `rt_clock_ns`, `rt_getenv` for first target
- `std/fs.w` using runtime interface
- `std/time.w` using `rt_clock_ns`
- `std/env.w` using `rt_getenv`

Test: compile a program that reads files, measures elapsed time,
and reads environment variables.

### Phase 4: Second platform

Implement all thirteen `rt_*` functions for a second target.
The stdlib and all tests are unchanged — only the backend differs.

If adding the second platform requires any stdlib changes, the
interface is wrong.

### Phase 5: Remaining platforms

Each is one backend file per target. The interface is proven by
Phase 4.

---

## Current Migration Checklist — Legacy Runtime C Elimination

This checklist tracks the active repository migration from handwritten
runtime C to `With + assembly`. It is distinct from the platform-backend
phases above.

### Status

- [x] Embedded runtime extraction moved out of C and into the compiler/link path
- [x] `support_runtime.c` removed
- [x] `embedded_objects.c` removed
- [x] Native fiber core moved out of `runtime/fiber.c` into `rt/*.w`
- [x] Embedded stdlib ownership moved out of `runtime/helpers.c`
- [x] argv/env/process/system/tar-extract compatibility surface moved out of `runtime/helpers.c`
- [x] Sysinfo ownership moved out of `runtime/helpers.c`
- [ ] `runtime/helpers.c` drained completely
- [ ] `runtime/with_runtime.c` reduced to zero or replaced by generated `With`-owned runtime output
- [ ] `runtime/with_runtime.h` replaced by generated declarations
- [ ] Only `runtime/llvm_bridge.c` and `runtime/clang_bridge.c` remain as handwritten C

### Rules For This Checklist

- One subsystem per commit.
- No net-new feature work in handwritten C.
- C may only change to:
  - delete migrated code
  - narrow a low-level boundary
  - fix a root-cause correctness bug blocking the migration
- After each subsystem slice:
  - `make build`
  - `make selfcheck`
  - `make smoke`
  - `make fixpoint`

### Remaining Stage-5 Work

#### 5.1 Duplicate Cleanup — Small, Low-Risk

- [ ] Remove legacy codegen loop-state shims from `runtime/helpers.c`
      Owner already exists in `rt/rt_core.w`.
- [ ] Remove legacy string-builder shims from `runtime/helpers.c`
      Owner already exists in `rt/rt_core.w`.
- [ ] Remove duplicate bitwise/clock helpers from `runtime/helpers.c`
      Owner already exists in `rt/rt_core.w`.

#### 5.2 Duplicate Cleanup — Medium

- [ ] Remove duplicate fs/random/stdin/stdout helpers from `runtime/helpers.c`
      Owners already exist in `rt/rt_core.w` and `rt/compat_runtime.w`.
- [ ] Remove duplicate vec compatibility helpers from `runtime/helpers.c`
      Owner already exists in `rt/rt_core.w`.
- [ ] Remove duplicate formatting helpers from `runtime/helpers.c`
      Owner already exists in `rt/rt_core.w`.
- [ ] Remove duplicate string algorithm helpers from `runtime/helpers.c`
      Owner already exists in `rt/rt_core.w`.
- [ ] Remove duplicate hashmap helpers from `runtime/helpers.c`
      Owner already exists in `rt/rt_core.w`.

#### 5.3 Real Migrations — No Existing With Owner Yet

- [ ] Move the networking surface out of `runtime/helpers.c`
      Surface:
      `with_net_tcp_listen`, `with_net_tcp_accept`, `with_net_tcp_connect`,
      `with_net_send`, `with_net_recv`, `with_net_close`, `with_net_udp_bind`
- [ ] Decide and implement ownership for the `with_cimport_*` weak-stub family
      Current location: `runtime/helpers.c`
      Constraint: this must stay bootstrap-safe and must not depend on clang
      in the runtime path

#### 5.4 Shim Cleanup After helpers.c Drain

- [ ] Audit `runtime/with_runtime.c` and remove anything now owned by `rt/*.w`
- [ ] Replace handwritten `runtime/with_runtime.h` with generated declarations
- [ ] Tighten the runtime C allowlist so only bridge C remains

### Commit Order

Work in this order unless a root-cause bug forces a different dependency:

1. Codegen loop-state shims
2. String builder
3. Bitwise + clock helpers
4. fs/random/stdin/stdout compatibility
5. Vec compatibility
6. Formatting helpers
7. String algorithms
8. HashMap
9. Networking
10. `with_cimport_*` weak stubs
11. `with_runtime.c` / `with_runtime.h` cleanup

### Definition of Done

This migration track is done when:

- `runtime/helpers.c` is deleted or empty
- `runtime/with_runtime.c` is deleted or replaced by generated output
- `runtime/with_runtime.h` is generated, not handwritten
- the runtime C allowlist contains only:
  - `runtime/llvm_bridge.c`
  - `runtime/clang_bridge.c`

---

## File Layout

```
rt/
    interface.w              — rt_* function signatures (extern)
    error.w                  — RtError enum, error code constants
    darwin_aarch64.s         — assembly stubs
    darwin_aarch64.w         — constants, StatBuf mapping, flag mapping
    darwin_x86_64.s
    darwin_x86_64.w
    linux_aarch64.s          — raw syscall stubs
    linux_aarch64.w          — syscall numbers, StatBuf mapping
    linux_x86_64.s
    linux_x86_64.w
    windows_x86_64.w         — Win32 API calls, fd-to-HANDLE table
    freestanding.w           — stubs returning errors

std/
    mem.w                    — allocator (uses rt_mmap/rt_munmap)
    fmt.w                    — FmtBuffer, integer/float/string formatting
    io.w                     — print/eprint/write (uses rt_write)
    fs.w                     — file operations (uses rt_open/read/write/close)
    time.w                   — elapsed time (uses rt_clock_ns)
    env.w                    — environment variables (uses rt_getenv)
```

---

## Interaction with std.math

std.math uses `std.mem.alloc_aligned(size, 64)` for Storage
allocations (64-byte alignment for SIMD). The allocator's
`alloc_aligned` rounds up to alignment and returns a properly
aligned pointer from the freelist or via `rt_mmap` (which returns
page-aligned memory).

std.math uses `std.fmt` for Array printing. No separate formatting
dependency.

std.math uses `std.fs` for `io.load_npy`, `io.save_csv`, etc.
No direct `rt_*` calls.

std.math never calls `rt_*` directly. It goes through `std.*`.
This is the layering: `std.math → std.mem / std.fmt / std.fs → rt_*`.

---

## Rules

1. `std/*` never imports platform-specific code. Only `rt/interface.w`.
2. `rt/interface.w` is extern declarations only. No implementation.
3. One `rt/*.s` + `rt/*.w` pair per platform. No `#if` anywhere.
4. The compiler selects the backend at link time based on target.
5. `c_import` is opt-in. Programs that use it may link libc.
   Programs that don't use it never link libc.
6. The compiler binary itself may link libc (because LLVM).
   User programs must not.
7. All `rt_*` functions that can fail use the negative-return
   error convention. No exceptions.
8. `StatBuf` and flag constants (O_RDONLY, SEEK_SET, etc.) are
   defined in the stdlib, not per-platform. Backends map from
   stdlib constants to native values.
