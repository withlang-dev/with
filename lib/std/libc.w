// std.libc — the C surface migrated C code links against.
//
// The rule (Eric, 2026-09-15): this module exports C-standard functions —
// present under the same name in libSystem, glibc and the UCRT — and With
// functions over `with_libc_*` runtime seams (rt/rt_core.w, one body per
// backend). Nothing POSIX-, Darwin- or glibc-spelled is exported: a corpus
// migrated on one host must link and behave the same on every target, with
// no external dependency beyond the OS's C runtime and system calls. The
// migrator rewrites the host's spelling of a modeled symbol (`__stderrp`,
// `stderr`, `__error()`, `_errno()`, `_fileno`) to the name here, and the
// `libc-surface-check` lane refuses any other `pub extern` in this file.

use std.builtins.eprint
use std.os.Target
use rt.rt_core


// time.h: `struct tm` as POSIX lays it out (Darwin and glibc agree: nine
// ints, the UTC offset, the zone name). The UCRT record ends after the nine
// ints; this record is 12 bytes longer than it, which every C write fits,
// and `tm_gmtoff`/`tm_zone` read nothing meaningful there.
@[repr(C)]
pub type tm {
    pub tm_sec: c_int,
    pub tm_min: c_int,
    pub tm_hour: c_int,
    pub tm_mday: c_int,
    pub tm_mon: c_int,
    pub tm_year: c_int,
    pub tm_wday: c_int,
    pub tm_yday: c_int,
    pub tm_isdst: c_int,
    pub tm_gmtoff: c_long,
    pub tm_zone: *const c_char,
}
pub extern fn strftime(buf: *mut c_char, max: u64, fmt: *const c_char, timeptr: *const tm) -> u64
pub extern fn mktime(timeptr: *mut tm) -> i64

pub type rlimit {
    pub rlim_cur: u64,
    pub rlim_max: u64,
}

// The stdio streams. C reaches them through a per-libc macro (Darwin
// `__stderrp`, glibc `stderr`, UCRT `__acrt_iob_func(2)`); migrated code
// calls these instead, on every target.

pub fn libc_stdin() -> *mut c_void: with_libc_stdin()
pub fn libc_stdout() -> *mut c_void: with_libc_stdout()
pub fn libc_stderr() -> *mut c_void: with_libc_stderr()

// #1998: CPU time (user + system, ns) of this process and of every child it
// has reaped; -1 where the platform cannot say. One body per backend under
// the seam (getrusage SELF + CHILDREN; GetProcessTimes, children summed at
// reap), so it means the same on every target — unlike C's clock(), which
// leaves children out and on the UCRT counts wall time. A timing that must
// not count the rest of a loaded machine reads this, not a wall clock.
pub fn cpu_time_ns() -> i64: with_libc_cpu_time_ns()
// The UCRT's stream table by index (`__acrt_iob_func`), for code migrated on Windows.
pub fn libc_iob(index: i32) -> *mut c_void:
    if index == 0: return libc_stdin()
    if index == 1: return libc_stdout()
    libc_stderr()

// stdio
pub extern fn fprintf(stream: *mut c_void, fmt: *const c_char, ...) -> i32
pub extern fn printf(fmt: *const c_char, ...) -> i32
pub extern fn snprintf(dst: *mut c_char, size: u64, fmt: *const c_char, ...) -> i32
pub extern fn sprintf(dst: *mut c_char, fmt: *const c_char, ...) -> i32
// The v* formatters take C's va_list: `c_va_list`, modeled per target by the
// compiler (#1104) — never `*mut c_char`, which is only Darwin's spelling.
pub extern fn vsnprintf(dst: *mut c_char, size: u64, fmt: *const c_char, va: c_va_list) -> i32
pub extern fn vfprintf(stream: *mut c_void, fmt: *const c_char, va: c_va_list) -> i32
pub extern fn vprintf(fmt: *const c_char, va: c_va_list) -> i32
pub extern fn fopen(path: *const c_char, mode: *const c_char) -> *mut c_void
pub extern fn fclose(stream: *mut c_void) -> i32
pub extern fn remove(path: *const c_char) -> i32
pub extern fn fflush(stream: *mut c_void) -> i32
pub extern fn fgets(s: *mut c_char, size: i32, stream: *mut c_void) -> *mut c_char
pub extern fn fgetc(stream: *mut c_void) -> i32
pub extern fn ungetc(c: i32, stream: *mut c_void) -> i32
pub extern fn strcoll(a: *const c_char, b: *const c_char) -> i32
pub extern fn strspn(s: *const c_char, accept: *const c_char) -> u64
pub extern fn strcspn(s: *const c_char, reject: *const c_char) -> u64
pub extern fn strpbrk(s: *const c_char, accept: *const c_char) -> *mut c_char
pub extern fn strncat(dst: *mut c_char, src: *const c_char, n: u64) -> *mut c_char
pub extern fn fscanf(stream: *mut c_void, fmt: *const c_char, ...) -> i32
pub extern fn fputc(c: i32, stream: *mut c_void) -> i32
pub extern fn fputs(s: *const c_char, stream: *mut c_void) -> i32
pub extern fn putc(c: i32, stream: *mut c_void) -> i32
pub extern fn putchar(c: i32) -> i32
pub extern fn perror(s: *const c_char) -> Unit
pub extern fn feof(stream: *mut c_void) -> i32
pub extern fn ferror(stream: *mut c_void) -> i32
pub extern fn rewind(stream: *mut c_void)
pub extern fn fread(ptr: *mut c_void, size: u64, count: u64, stream: *mut c_void) -> u64
pub extern fn fwrite(ptr: *const c_void, size: u64, count: u64, stream: *mut c_void) -> u64
// POSIX fileno (UCRT `_fileno`): a seam.
pub fn fileno(stream: *mut c_void) -> i32: with_libc_fileno(stream)
// Stream positions are 64-bit on every target: C's `long` is 32 bits on
// Windows, so fseek/ftell and the host's wide spellings (fseeko, ftello,
// _fseeki64, _ftelli64) are one seam.
pub fn fseek(stream: *mut c_void, offset: i64, whence: i32) -> i32: with_libc_fseek(stream, offset, whence)
pub fn ftell(stream: *mut c_void) -> i64: with_libc_ftell(stream)

// strings / locale / conversion
pub extern fn strcpy(dst: *mut c_char, src: *const c_char) -> *mut c_char
pub extern fn strncpy(dst: *mut c_char, src: *const c_char, n: u64) -> *mut c_char
pub extern fn strrchr(s: *const c_char, c: i32) -> *mut c_char
pub extern fn strstr(haystack: *const c_char, needle: *const c_char) -> *mut c_char
pub extern fn strerror(errnum: i32) -> *mut c_char
pub extern fn atoi(nptr: *const c_char) -> i32
// strtol and strtoul parse a 64-bit long on every target (D114): where C's
// long is 32 bits (the UCRT) the runtime binds the 64-bit parse (#2592).
pub fn strtol(nptr: *const c_char, endptr: *mut *mut c_char, base: i32) -> i64: with_libc_strtol(nptr, endptr, base)
pub fn strtoul(nptr: *const c_char, endptr: *mut *mut c_char, base: i32) -> u64: with_libc_strtoul(nptr, endptr, base)
pub extern fn strtod(nptr: *const c_char, endptr: *mut *mut c_char) -> f64
pub extern fn strtoll(nptr: *const c_char, endptr: *mut *mut c_char, base: i32) -> i64
pub extern fn strtoull(nptr: *const c_char, endptr: *mut *mut c_char, base: i32) -> u64
pub extern fn strtof(nptr: *const c_char, endptr: *mut *mut c_char) -> f32
// C's `long double` is With's f64 where it is 8 bytes (Darwin arm64, Windows);
// elsewhere With has no float for it and the parse is strtod's (#2176).
pub fn strtold(nptr: *const c_char, endptr: *mut *mut c_char) -> f64: with_libc_strtold(nptr, endptr)
pub extern fn setlocale(category: i32, locale: *const c_char) -> *mut c_char

// errno: C's lvalue macro reaches a per-libc accessor (Darwin `__error()`,
// glibc `__errno_location()`, UCRT `_errno()`); migrated code derefs this.
pub fn errno_ptr() -> *mut i32: with_libc_errno()

// process / time
pub extern fn abort() -> Never
// Assertion reporters of the Darwin (`__assert_rtn`), glibc
// (`__assert_fail`) and mingw-w64 (`_assert`) assert.h expansions, modeled
// portably: none of the symbols exists on the other platforms, and a corpus
// migrated on one host must assert the same way on every target. Same
// report, then abort.
pub fn __assert_rtn(function: *const c_char, file: *const c_char, line: i32, expression: *const c_char) -> Never:
    libc_assert_failed(expression, function, file, line)
pub fn __assert_fail(expression: *const c_char, file: *const c_char, line: u32, function: *const c_char) -> Never:
    libc_assert_failed(expression, function, file, line as i64)
// mingw-w64's reporter names no function.
pub fn _assert(expression: *const c_char, file: *const c_char, line: u32) -> Never:
    libc_assert_failed(expression, c"".ptr, file, line as i64)
fn libc_assert_failed(expression: *const c_char, function: *const c_char, file: *const c_char, line: i64) -> Never:
    let function_name = with_str_from_cstr(function as *const u8)
    let site = if function_name.len() > 0: ", function " ++ function_name else: ""
    let text = f"Assertion failed: ({with_str_from_cstr(expression as *const u8)}){site}, file {with_str_from_cstr(file as *const u8)}, line {line}."
    eprint(text)
    abort()
pub extern fn exit(code: i32) -> Never
pub extern fn clock() -> u64
pub extern fn time(tloc: *mut i64) -> i64

// POSIX file descriptors, temp files and paths: seams (UCRT spells them
// `_isatty`, `_open`, ...; Windows has no mkstemp or realpath).
pub fn isatty(fd: i32) -> i32: with_libc_isatty(fd)
pub fn mkstemp(template_path: *mut c_char) -> i32: with_libc_mkstemp(template_path)
pub fn realpath(path: *const c_char, resolved_path: *mut c_char) -> *mut c_char: with_libc_realpath(path, resolved_path)
pub fn open(path: *const c_char, flags: i32, mode: i32) -> i32:
    with_libc_open(path, flags, mode)
pub fn read(fd: i32, buf: *mut c_void, count: u64) -> i64:
    with_libc_read(fd, buf as *mut u8, count)
pub fn write(fd: i32, buf: *const c_void, count: u64) -> i64:
    with_libc_write(fd, buf as *const u8, count)
pub fn close(fd: i32) -> i32:
    with_libc_close(fd)
pub fn lseek(fd: i32, offset: i64, whence: i32) -> i64:
    with_libc_lseek(fd, offset, whence)
pub fn unlink(path: *const c_char) -> i32:
    with_libc_unlink(path)
pub extern fn rand() -> i32
pub extern fn srand(seed: u32) -> Unit
pub extern fn qsort(base: *mut c_void, count: u64, size: u64, compare: unsafe extern "C" fn(*const c_void, *const c_void) -> i32) -> Unit

// Darwin's mach clock, modeled portably: the absolute time is the runtime's
// monotonic clock in nanoseconds on every target and the timebase is 1/1,
// so `(t / denom) * numer` yields nanoseconds exactly as it does on Darwin.
pub type kern_return_t = i32
// C's `struct mach_timebase_info`, typedef'd `mach_timebase_info_data_t`;
// migrated code spells the tag.
pub type mach_timebase_info { pub numer: u32 = 0, pub denom: u32 = 0 }
impl Copy for mach_timebase_info
pub type mach_timebase_info_data_t = mach_timebase_info
pub fn mach_absolute_time() -> u64: with_libc_mach_absolute_time()

// sys/time.h's gettimeofday, modeled portably: the runtime's wall clock in
// nanoseconds on every target, split as C splits it. `struct timeval` is
// this record (its C layouts differ per libc; nothing passes it to C).
@[repr(C)]
pub type timeval { pub tv_sec: i64 = 0, pub tv_usec: i64 = 0 }
impl Copy for timeval
pub unsafe fn gettimeofday(tv: *mut timeval, tz: *mut c_void) -> i32:
    let ns = with_wall_clock_nanos()
    (*tv).tv_sec = ns / 1000000000
    (*tv).tv_usec = (ns % 1000000000) / 1000
    0
pub unsafe fn mach_timebase_info(info: *mut mach_timebase_info) -> kern_return_t:
    (*info).numer = 1 as u32
    (*info).denom = 1 as u32
    0

// fcntl is modeled like open/read/close: a runtime seam per target, never
// the bare C symbol (UCRT has none, and zlib's gz layer — migrated with
// O_NONBLOCK/O_CLOEXEC resolved — calls it from the bundle on every
// target). POSIX forwards to libc; Windows returns -1, unsupported, which
// is what zlib's own Windows build would have compiled around.
pub fn fcntl(fd: i32, cmd: i32, arg: i32 = 0) -> i32:
    with_libc_fcntl(fd, cmd, arg)
// rlimit: POSIX forwards to libc (the two-u64 layout is Darwin's and
// glibc's); Windows reads RLIMIT_STACK as unlimited and accepts a set.
pub fn getrlimit(resource: i32, rlp: *mut rlimit) -> i32: with_libc_getrlimit(resource, rlp as *mut u8)
pub fn setrlimit(resource: i32, rlp: *const rlimit) -> i32: with_libc_setrlimit(resource, rlp as *const u8)

// ── Constants (D90) ─────────────────────────────────────────────
// A migrated corpus names a libc constant; it never carries the number its
// migration's headers gave it. The value here is what the function that
// consumes it accepts on the target being compiled for: the runtime's own
// numbering where a seam translates (`open`, `fcntl`), the target's own
// value where the call goes straight to the OS's C runtime (`errno`,
// `clock`, `setlocale`). A constant and the function that consumes it come
// from this one table. A value that differs by target is a
// `comptime match Target.os` (D91): a target added to `OsKind` is a compile
// error here until its value is stated.

// limits.h, stdint.h, stdlib.h: the same on every supported target.
pub const INT_MAX: i32 = 2147483647
pub const UINT_MAX: u32 = 4294967295
pub const UINT8_MAX: i32 = 255
pub const UINT16_MAX: i32 = 65535
pub const UINT32_MAX: u32 = 4294967295
pub const SIZE_MAX: u64 = 18446744073709551615
pub const UINTPTR_MAX: u64 = 18446744073709551615
pub const EXIT_SUCCESS: i32 = 0
pub const EXIT_FAILURE: i32 = 1
// C's `unsigned long` is 32 bits on Windows and 64 elsewhere.
pub const ULONG_MAX: u64 = comptime match Target.os:
    .Windows => 4294967295u64
    .Macos => 18446744073709551615u64
    .Linux => 18446744073709551615u64
    .Wasi => 4294967295u64

// stdio.h: `fseek` and `lseek` origins.
pub const SEEK_SET: i32 = 0
pub const SEEK_CUR: i32 = 1
pub const SEEK_END: i32 = 2

// fcntl.h: `open` flags and `fcntl` commands, in the numbering the `open`
// and `fcntl` seams take (rt_open, rt_fcntl translate per target).
pub const O_RDONLY: i32 = 0
pub const O_WRONLY: i32 = 1
pub const O_RDWR: i32 = 2
pub const O_CREAT: i32 = 0x200
pub const O_TRUNC: i32 = 0x400
pub const O_APPEND: i32 = 0x800
pub const O_EXCL: i32 = 0x1000
pub const O_NONBLOCK: i32 = 0x2000
pub const O_CLOEXEC: i32 = 0x4000
pub const F_GETFD: i32 = 1
pub const F_SETFD: i32 = 2
pub const F_GETFL: i32 = 3
pub const F_SETFL: i32 = 4
pub const FD_CLOEXEC: i32 = 1

// errno.h: what `*errno_ptr()` holds on the target.
pub const EAGAIN: i32 = comptime match Target.os:
    .Macos => 35
    .Linux => 11
    .Windows => 11
    .Wasi => 6
pub const EWOULDBLOCK: i32 = comptime match Target.os:
    .Macos => 35
    .Linux => 11
    .Windows => 140
    .Wasi => 6

// time.h: the unit of `clock()`.
pub const CLOCKS_PER_SEC: i32 = comptime match Target.os:
    .Windows => 1000
    .Macos => 1000000
    .Linux => 1000000
    .Wasi => 1000000000

// sys/resource.h: `getrlimit` and `setrlimit`.
pub const RLIMIT_STACK: i32 = 3
// The Windows seam reports Darwin's value (rt: win_getrlimit).
pub const RLIM_INFINITY: u64 = comptime match Target.os:
    .Linux => 18446744073709551615u64
    .Macos => 9223372036854775807u64
    .Windows => 9223372036854775807u64
    .Wasi => 18446744073709551615u64

// locale.h: `setlocale` categories.
pub const LC_CTYPE: i32 = comptime match Target.os:
    .Linux => 0
    .Macos => 2
    .Windows => 2
    .Wasi => 0
