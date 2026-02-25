// std.io — I/O utility functions
//
// Provides basic I/O operations wrapping C stdlib functions.

use c_import("#include <stdio.h>\n#include <stdlib.h>")

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

// Exit the process with a status code
pub fn exit(code: i32) -> i32 =
    // Call C exit — this never returns, but we need a return type
    let result = code
    result
