// std.libc — narrow libc/POSIX ABI surface used by migrated C code.
//
// This module intentionally exposes concrete target ABI symbols. Migrated C
// output is target-specific and should be regenerated for a different target.

use std.builtins

pub type rlimit {
    rlim_cur: u64,
    rlim_max: u64,
}

// Darwin stdio globals. These are the names produced by the Darwin headers
// after preprocessing stdin/stdout/stderr.
pub extern var __stdinp: *mut c_void
pub extern var __stdoutp: *mut c_void
pub extern var __stderrp: *mut c_void

// stdio
pub extern fn fprintf(stream: *mut c_void, fmt: *const i8, ...) -> i32
pub extern fn printf(fmt: *const i8, ...) -> i32
pub extern fn snprintf(dst: *mut i8, size: u64, fmt: *const i8, ...) -> i32
pub extern fn sprintf(dst: *mut i8, fmt: *const i8, ...) -> i32
pub extern fn fopen(path: *const i8, mode: *const i8) -> *mut c_void
pub extern fn fclose(stream: *mut c_void) -> i32
pub extern fn fflush(stream: *mut c_void) -> i32
pub extern fn fileno(stream: *mut c_void) -> i32
pub extern fn fgets(s: *mut i8, size: i32, stream: *mut c_void) -> *mut i8
pub extern fn fgetc(stream: *mut c_void) -> i32
pub extern fn fputc(c: i32, stream: *mut c_void) -> i32
pub extern fn fputs(s: *const i8, stream: *mut c_void) -> i32
pub extern fn putc(c: i32, stream: *mut c_void) -> i32
pub extern fn feof(stream: *mut c_void) -> i32
pub extern fn fread(ptr: *mut c_void, size: u64, count: u64, stream: *mut c_void) -> u64
pub extern fn fwrite(ptr: *const c_void, size: u64, count: u64, stream: *mut c_void) -> u64

// strings / locale / conversion
pub extern fn strcpy(dst: *mut i8, src: *const i8) -> *mut i8
pub extern fn strncpy(dst: *mut i8, src: *const i8, n: u64) -> *mut i8
pub extern fn strstr(haystack: *const i8, needle: *const i8) -> *mut i8
pub extern fn strerror(errnum: i32) -> *mut i8
pub extern fn strtol(nptr: *const i8, endptr: *mut *mut i8, base: i32) -> i64
pub extern fn strtoul(nptr: *const i8, endptr: *mut *mut i8, base: i32) -> u64
pub extern fn setlocale(category: i32, locale: *const i8) -> *mut i8

// process / time / POSIX
pub extern fn exit(code: i32) -> void
pub extern fn clock() -> u64
pub extern fn time(tloc: *mut i64) -> i64
pub extern fn isatty(fd: i32) -> i32
pub extern fn getrlimit(resource: i32, rlp: *mut rlimit) -> i32
pub extern fn setrlimit(resource: i32, rlp: *const rlimit) -> i32

// Darwin errno accessor.
pub extern fn __error() -> *mut i32
