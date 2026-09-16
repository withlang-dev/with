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

extern fn with_str_from_cstr(s: *const u8) -> str

pub type rlimit {
    rlim_cur: u64,
    rlim_max: u64,
}

// The stdio streams. C reaches them through a per-libc macro (Darwin
// `__stderrp`, glibc `stderr`, UCRT `__acrt_iob_func(2)`); migrated code
// calls these instead, on every target.
extern fn with_libc_stdin() -> *mut c_void
extern fn with_libc_stdout() -> *mut c_void
extern fn with_libc_stderr() -> *mut c_void

pub fn libc_stdin() -> *mut c_void: with_libc_stdin()
pub fn libc_stdout() -> *mut c_void: with_libc_stdout()
pub fn libc_stderr() -> *mut c_void: with_libc_stderr()
// The UCRT's stream table by index (`__acrt_iob_func`), for code migrated on Windows.
pub fn libc_iob(index: i32) -> *mut c_void:
    if index == 0: return libc_stdin()
    if index == 1: return libc_stdout()
    libc_stderr()

// stdio
pub extern fn fprintf(stream: *mut c_void, fmt: *const i8, ...) -> i32
pub extern fn printf(fmt: *const i8, ...) -> i32
pub extern fn snprintf(dst: *mut i8, size: u64, fmt: *const i8, ...) -> i32
pub extern fn sprintf(dst: *mut i8, fmt: *const i8, ...) -> i32
// The v* formatters take C's va_list: `c_va_list`, modeled per target by the
// compiler (#1104) — never `*mut i8`, which is only Darwin's spelling.
pub extern fn vsnprintf(dst: *mut i8, size: u64, fmt: *const i8, va: c_va_list) -> i32
pub extern fn vfprintf(stream: *mut c_void, fmt: *const i8, va: c_va_list) -> i32
pub extern fn vprintf(fmt: *const i8, va: c_va_list) -> i32
pub extern fn fopen(path: *const i8, mode: *const i8) -> *mut c_void
pub extern fn fclose(stream: *mut c_void) -> i32
pub extern fn fflush(stream: *mut c_void) -> i32
pub extern fn fgets(s: *mut i8, size: i32, stream: *mut c_void) -> *mut i8
pub extern fn fgetc(stream: *mut c_void) -> i32
pub extern fn fputc(c: i32, stream: *mut c_void) -> i32
pub extern fn fputs(s: *const i8, stream: *mut c_void) -> i32
pub extern fn putc(c: i32, stream: *mut c_void) -> i32
pub extern fn perror(s: *const i8) -> Unit
pub extern fn feof(stream: *mut c_void) -> i32
pub extern fn ferror(stream: *mut c_void) -> i32
pub extern fn fread(ptr: *mut c_void, size: u64, count: u64, stream: *mut c_void) -> u64
pub extern fn fwrite(ptr: *const c_void, size: u64, count: u64, stream: *mut c_void) -> u64
// POSIX fileno (UCRT `_fileno`): a seam.
extern fn with_libc_fileno(stream: *mut c_void) -> i32
pub fn fileno(stream: *mut c_void) -> i32: with_libc_fileno(stream)

// strings / locale / conversion
pub extern fn strcpy(dst: *mut i8, src: *const i8) -> *mut i8
pub extern fn strncpy(dst: *mut i8, src: *const i8, n: u64) -> *mut i8
pub extern fn strrchr(s: *const i8, c: i32) -> *mut i8
pub extern fn strstr(haystack: *const i8, needle: *const i8) -> *mut i8
pub extern fn strerror(errnum: i32) -> *mut i8
pub extern fn atoi(nptr: *const i8) -> i32
pub extern fn strtol(nptr: *const i8, endptr: *mut *mut i8, base: i32) -> i64
pub extern fn strtoul(nptr: *const i8, endptr: *mut *mut i8, base: i32) -> u64
pub extern fn strtod(nptr: *const i8, endptr: *mut *mut i8) -> f64
pub extern fn setlocale(category: i32, locale: *const i8) -> *mut i8

// errno: C's lvalue macro reaches a per-libc accessor (Darwin `__error()`,
// glibc `__errno_location()`, UCRT `_errno()`); migrated code derefs this.
extern fn with_libc_errno() -> *mut i32
pub fn errno_ptr() -> *mut i32: with_libc_errno()

// process / time
pub extern fn abort() -> Never
// Assertion reporters of the Darwin (`__assert_rtn`) and glibc
// (`__assert_fail`) assert.h expansions, modeled portably: neither symbol
// exists on the other platforms, and a corpus migrated on one host must
// assert the same way on every target. Same report, then abort.
pub fn __assert_rtn(function: *const i8, file: *const i8, line: i32, expression: *const i8) -> Never:
    libc_assert_failed(expression, function, file, line)
pub fn __assert_fail(expression: *const i8, file: *const i8, line: u32, function: *const i8) -> Never:
    libc_assert_failed(expression, function, file, line as i64)
fn libc_assert_failed(expression: *const i8, function: *const i8, file: *const i8, line: i64) -> Never:
    let text = unsafe { f"Assertion failed: ({with_str_from_cstr(expression as *const u8)}), function {with_str_from_cstr(function as *const u8)}, file {with_str_from_cstr(file as *const u8)}, line {line}." }
    eprint(text)
    abort()
pub extern fn exit(code: i32) -> Never
pub extern fn clock() -> u64
pub extern fn time(tloc: *mut i64) -> i64

// POSIX file descriptors, temp files and paths: seams (UCRT spells them
// `_isatty`, `_open`, ...; Windows has no mkstemp or realpath).
extern fn with_libc_isatty(fd: i32) -> i32
extern fn with_libc_mkstemp(template_path: *mut i8) -> i32
extern fn with_libc_realpath(path: *const i8, resolved_path: *mut i8) -> *mut i8
extern fn with_libc_open(path: *const i8, flags: i32, mode: i32) -> i32
extern fn with_libc_read(fd: i32, buf: *mut u8, count: u64) -> i64
extern fn with_libc_write(fd: i32, buf: *const u8, count: u64) -> i64
extern fn with_libc_close(fd: i32) -> i32
extern fn with_libc_lseek(fd: i32, offset: i64, whence: i32) -> i64
extern fn with_libc_unlink(path: *const i8) -> i32
pub fn isatty(fd: i32) -> i32: with_libc_isatty(fd)
pub fn mkstemp(template_path: *mut i8) -> i32: with_libc_mkstemp(template_path)
pub fn realpath(path: *const i8, resolved_path: *mut i8) -> *mut i8: with_libc_realpath(path, resolved_path)
pub fn open(path: *const i8, flags: i32, mode: i32) -> i32:
    with_libc_open(path, flags, mode)
pub fn read(fd: i32, buf: *mut c_void, count: u64) -> i64:
    with_libc_read(fd, buf as *mut u8, count)
pub fn write(fd: i32, buf: *const c_void, count: u64) -> i64:
    with_libc_write(fd, buf as *const u8, count)
pub fn close(fd: i32) -> i32:
    with_libc_close(fd)
pub fn lseek(fd: i32, offset: i64, whence: i32) -> i64:
    with_libc_lseek(fd, offset, whence)
pub fn unlink(path: *const i8) -> i32:
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
pub type mach_timebase_info { numer: u32 = 0, denom: u32 = 0 }
impl Copy for mach_timebase_info
pub type mach_timebase_info_data_t = mach_timebase_info
extern fn with_libc_mach_absolute_time() -> u64
pub fn mach_absolute_time() -> u64: with_libc_mach_absolute_time()
pub unsafe fn mach_timebase_info(info: *mut mach_timebase_info) -> kern_return_t:
    (*info).numer = 1 as u32
    (*info).denom = 1 as u32
    0

// fcntl is modeled like open/read/close: a runtime seam per target, never
// the bare C symbol (UCRT has none, and zlib's gz layer — migrated with
// O_NONBLOCK/O_CLOEXEC resolved — calls it from the bundle on every
// target). POSIX forwards to libc; Windows returns -1, unsupported, which
// is what zlib's own Windows build would have compiled around.
extern fn with_libc_fcntl(fd: i32, cmd: i32, arg: i32) -> i32
pub fn fcntl(fd: i32, cmd: i32, arg: i32 = 0) -> i32:
    with_libc_fcntl(fd, cmd, arg)
// rlimit: POSIX forwards to libc (the two-u64 layout is Darwin's and
// glibc's); Windows reads RLIMIT_STACK as unlimited and accepts a set.
extern fn with_libc_getrlimit(resource: i32, lim: *mut u8) -> i32
extern fn with_libc_setrlimit(resource: i32, lim: *const u8) -> i32
pub fn getrlimit(resource: i32, rlp: *mut rlimit) -> i32: with_libc_getrlimit(resource, rlp as *mut u8)
pub fn setrlimit(resource: i32, rlp: *const rlimit) -> i32: with_libc_setrlimit(resource, rlp as *const u8)
