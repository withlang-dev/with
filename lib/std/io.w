// std.io — I/O utility functions
//
// Provides basic I/O operations wrapping C stdlib functions.

use c_import("#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>")

// Print a string to stdout (no newline)
pub fn print_str(s: str) -> i32 =
    printf("%s", s)

// Print a string to stdout with newline
pub fn print_line(s: str) -> i32 =
    puts(s)

// Print an integer to stdout with newline
pub fn print_int(n: i64) -> i32 =
    printf("%ld\n", n)

// Print a float to stdout with newline
pub fn print_float(x: f64) -> i32 =
    printf("%f\n", x)

// Open a file for reading, returns file pointer (0 on failure)
pub fn file_open(path: str, mode: str) -> i64 =
    fopen(path, mode)

// Close a file
pub fn file_close(fp: i64) -> i32 =
    fclose(fp)

// Write a string to a file
pub fn file_write(fp: i64, s: str) -> i32 =
    fputs(s, fp)

// Read bytes from a file
pub fn file_read(fp: i64, buf: *i8, size: i64) -> i64 =
    fread(buf, 1, size, fp)
