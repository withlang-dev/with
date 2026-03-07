// std.io — I/O utility functions
//
// Provides basic I/O operations wrapping C stdlib functions.

use c_import("stdio.h")
use c_import("stdlib.h")
use c_import("string.h")

// Print a string to stdout (no newline)
pub fn print_str(s: str) -> i32:
    printf("%s" as *const i8, s)

// Print a string to stdout with newline
pub fn print_line(s: str) -> i32:
    puts(s as *const i8)

// Print an integer to stdout with newline
pub fn print_int(n: i32) -> i32:
    printf("%d\n" as *const i8, n)

// Print a float to stdout with newline
pub fn print_float(x: f64) -> i32:
    printf("%f\n" as *const i8, x)

// Open a file for reading, returns file pointer (null on failure)
pub fn file_open(path: str, mode: str) -> *const i8:
    fopen(path as *const i8, mode as *const i8)

// Close a file
pub fn file_close(fp: *const i8) -> i32:
    fclose(fp)

// Write a string to a file
pub fn file_write(fp: *const i8, s: str) -> i32:
    fputs(s as *const i8, fp)

// Read bytes from a file
pub fn file_read(fp: *const i8, buf: *const i8, size: u64) -> u64:
    fread(buf, 1, size, fp)
