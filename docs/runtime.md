# Eliminating libc — Runtime Plan

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

// Memory
fn rt_mmap(size: usize) -> *mut u8
fn rt_munmap(ptr: *mut u8, size: usize)

// Process
fn rt_exit(code: i32) -> !
fn rt_args() -> (*const *const u8, i32)    // (argv, argc)
```

That's it. Ten functions. Everything in the standard library is
built from these.

`rt_alloc` and `rt_free` are NOT in this interface. The allocator
is a stdlib component written in With, backed by `rt_mmap`/`rt_munmap`.
The runtime interface is the OS boundary. The allocator is above it.

---

## Platform Backends

Each backend implements the ten functions above.

```
rt/darwin_aarch64.s + rt/darwin_aarch64.w    — libSystem calls
rt/darwin_x86_64.s  + rt/darwin_x86_64.w     — libSystem calls
rt/linux_aarch64.s  + rt/linux_aarch64.w     — raw syscalls
rt/linux_x86_64.s   + rt/linux_x86_64.w      — raw syscalls
rt/windows_x86_64.w                          — Win32 (WriteFile, VirtualAlloc, etc.)
rt/freestanding.w                            — stubs / user-provided hooks
```

| Target      | Strategy            | Reason                              |
|-------------|---------------------|-------------------------------------|
| Linux       | Raw syscalls        | Stable ABI, no libc needed          |
| macOS       | libSystem wrappers  | Apple doesn't guarantee syscall ABI |
| Windows     | Win32 / NT APIs     | No syscall ABI at all               |
| Freestanding| User hooks          | No OS                               |

macOS links libSystem (not libc). libSystem is a thin stable
wrapper. This is what Zig and Go do.

---

## Entry Point

Every hosted backend provides `_start`:

```asm
// _start for darwin aarch64
.globl _start
_start:
    // argc is at [sp], argv is at [sp+8]
    ldr x0, [sp]          // argc
    add x1, sp, #8        // argv
    bl _with_main         // call into With
    mov x16, #0x2000001   // sys_exit
    svc #0x80
```

With generates `with_main(argc: i32, argv: **u8)` instead of
`main`. The runtime owns startup. libc's crt0 is not linked.

Freestanding targets: the user provides the entry point.

---

## Allocator

A single allocator in `std/mem.w`, written in With, backed by
`rt_mmap`/`rt_munmap`. No malloc, no free, no libc.

**v1: simple freelist.**

- `rt_mmap` acquires pages from the OS (64KB chunks).
- Small allocations (<= 4096): freelist with size classes
  (16, 32, 64, 128, 256, 512, 1024, 2048, 4096 bytes).
- Large allocations (> 4096): direct `rt_mmap`, direct `rt_munmap`.
- Thread safety deferred (single-threaded v1).

This is not a high-performance allocator. It's a correct one.
The compiler's allocation patterns (many small Vec/HashMap
allocations) work fine with a freelist. Optimize later with
profiling data.

---

## Formatting

f-strings currently lower to `snprintf`. This is the hidden libc
dependency that survives even after replacing I/O and allocation.

Replace with:

**Integer formatting:** Simple digit extraction loop. ~30 lines.
Handles i32, i64, u32, u64, hex, binary, and zero-padding.

**Float formatting:** Port Ryu (f64 → decimal string). ~400 lines.
Public domain C implementations exist. Required because the
compiler itself uses f-strings with floats in diagnostics.

**String formatting:** The f-string lowering in the compiler
currently emits calls to `snprintf`. Change it to emit calls to
`std.fmt.write_i64`, `std.fmt.write_f64`, `std.fmt.write_str`,
writing into a `std.fmt.Buffer` that grows via `std.mem.alloc`.

This must land in the same phase as the allocator — formatting
allocates, and the allocator is needed for formatting buffers.

---

## Phases

### Phase 1: I/O + exit + entry point + integer formatting

Implement:
- `rt_write`, `rt_read`, `rt_exit` for darwin-aarch64
- `_start` entry point
- `rt_args` (argc/argv from stack)
- Integer-to-string formatting
- Wire `print`/`eprint` through `rt_write`

Test: compile a program that prints integers. Verify `otool -L`
shows only libSystem, no libc++ or other dependencies.

### Phase 2: Allocator + float formatting + f-strings

Implement:
- `rt_mmap`/`rt_munmap` for darwin-aarch64
- Freelist allocator in `std/mem.w`
- Float formatting (Ryu port)
- Rewrite f-string lowering to use `std.fmt.*`
- Replace all `malloc`/`free` calls with `std.mem.alloc`/`free`

Test: compile a program that uses Vec, HashMap, f-strings with
floats. Verify no libc symbols in the binary.

### Phase 3: File I/O

Implement:
- `rt_open`, `rt_close`, `rt_seek`, `rt_stat` for darwin-aarch64
- `std/fs.w` using the runtime interface
- Replace `fopen`/`fread`/`fwrite`/`fclose`

Test: compile a program that reads and writes files.

### Phase 4: Second platform (linux-aarch64)

Implement the same ten `rt_*` functions using raw syscalls.
The stdlib and all tests are unchanged — only the backend differs.

This is the proof that the `rt_*` interface works. If adding
Linux requires any stdlib changes, the interface is wrong.

### Phase 5: Remaining platforms

- darwin-x86_64
- linux-x86_64
- windows-x86_64 (when needed)
- freestanding (when needed)

Each is just another backend file.

---

## File Layout

```
rt/
    interface.w              — rt_* function signatures (extern)
    darwin_aarch64.s         — assembly stubs (libSystem calls)
    darwin_aarch64.w         — constants, StatBuf layout
    linux_aarch64.s          — assembly stubs (raw syscalls)
    linux_aarch64.w          — constants, StatBuf layout, syscall numbers

std/
    mem.w                    — allocator (uses rt_mmap/rt_munmap)
    fmt.w                    — integer/float/string formatting
    io.w                     — print/eprint/write (uses rt_write)
    fs.w                     — file operations (uses rt_open/read/write/close)
```

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