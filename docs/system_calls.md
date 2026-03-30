# System Calls — Eliminating libc Dependency

## Goal

Replace all libc/stdio dependencies with direct kernel syscalls.
The With runtime should talk to the kernel directly, not through C.

This is how Zig works: `std.os.linux` and `std.os.darwin` contain
raw syscall wrappers. No glibc, no musl, no libSystem dependency
for core operations.

## Why

- **No C dependency.** The compiler should be self-contained.
- **Cross-compilation.** Direct syscalls work on any target without
  needing a matching libc.
- **Transparency.** Every I/O operation is visible — no hidden
  buffering, no locale handling, no signal mask manipulation.
- **Binary size.** Static libc adds megabytes; raw syscalls add bytes.

## What We Need

### Phase 1: Core I/O (write, exit)

The minimum to implement `print`, `eprint`, `write`, `ewrite`, and
`exit`:

| Syscall | macOS aarch64 | macOS x86_64 | Linux aarch64 | Linux x86_64 |
|---------|--------------|--------------|---------------|--------------|
| write   | 0x2000004    | 0x2000004    | 64            | 1            |
| exit    | 0x2000001    | 0x2000001    | 93            | 60           |

Implementation: one `.s` file per platform with a `sys_write(fd, buf, len)`
and `sys_exit(code)` function. The With stdlib calls these instead of
`fwrite`/`fputc`/`exit`.

```asm
// runtime/syscall_aarch64_darwin.s
.globl _sys_write
_sys_write:
    mov x16, #0x2000004
    svc #0x80
    ret

.globl _sys_exit
_sys_exit:
    mov x16, #0x2000001
    svc #0x80
```

```asm
// runtime/syscall_x86_64_darwin.s
.globl _sys_write
_sys_write:
    mov $0x2000004, %rax
    syscall
    ret

.globl _sys_exit
_sys_exit:
    mov $0x2000001, %rax
    syscall
```

Linux variants use different numbers and `svc #0` (aarch64) or
`syscall` (x86_64) without the `0x2000000` base.

### Phase 2: File I/O (open, close, read, stat)

| Syscall | Purpose |
|---------|---------|
| open    | Open files |
| close   | Close file descriptors |
| read    | Read from fd |
| fstat   | File metadata |
| lseek   | Seek in file |
| mmap    | Memory-mapped I/O |

These replace `fopen`/`fclose`/`fread`/`fwrite` for file operations.

### Phase 3: Memory (mmap/munmap, brk)

Replace `malloc`/`free` with a custom allocator backed by `mmap`.
This is the big one — the entire runtime memory model changes.

### Phase 4: Process (fork, exec, waitpid, pipe)

Replace `system()`, `popen()`, and process management.

### Phase 5: Time, Signals, Networking

Replace `clock_gettime`, `sigaction`, `socket`/`bind`/`listen`/`accept`.

## Architecture

```
lib/sys/darwin_aarch64.w    — syscall number constants + extern declarations
lib/sys/darwin_x86_64.w     — syscall number constants + extern declarations
lib/sys/linux_aarch64.w     — syscall number constants + extern declarations
lib/sys/linux_x86_64.w      — syscall number constants + extern declarations

runtime/syscall_aarch64_darwin.s   — raw syscall stubs
runtime/syscall_x86_64_darwin.s    — raw syscall stubs
runtime/syscall_aarch64_linux.s    — raw syscall stubs
runtime/syscall_x86_64_linux.s     — raw syscall stubs

lib/std/io.w                — print/eprint/write/ewrite using sys_write
lib/std/fs.w                — file operations using sys_open/read/write/close
lib/std/process.w           — process operations using sys_fork/exec/wait
lib/std/mem.w               — allocator using sys_mmap/munmap
```

The With source files (`lib/sys/*.w`) declare the extern syscall
functions. The assembly files implement them. User code never sees
syscall numbers — they use `std.io.print`, `std.fs.read_file`, etc.

## Migration Path

1. Implement Phase 1 (write + exit) as new files alongside existing runtime
2. Wire `print`/`eprint`/`write`/`ewrite` to use `sys_write`
3. Verify fixpoint — compiler still builds itself
4. Implement Phase 2 (file I/O), migrate `std.fs`
5. Implement Phase 3 (memory), replace malloc — this is the hard part
6. Remove libc dependency from the default build
7. Keep libc as opt-in for `c_import` users

## Constraints

- The compiler uses LLVM, which depends on libc++. The compiler binary
  itself will always link libc. But user programs that don't use
  `c_import` should not need it.
- String formatting (f-strings) currently uses `snprintf`. This needs
  a custom implementation or a dependency-free formatter.
- The allocator replacement (Phase 3) is the hardest part. Every Vec,
  HashMap, and string allocation goes through malloc today.

## Not In Scope

- Windows support (different syscall ABI entirely — uses ntdll)
- WASM (has its own I/O model)
- Bare metal (no kernel to syscall into)

These targets would use different backends, not the syscall layer.
