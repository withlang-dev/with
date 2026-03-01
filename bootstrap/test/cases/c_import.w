use c_import("stdio.h")
use c_import("string.h")

fn main -> i32:
    puts("hello from c_import")
    let len = strlen("test string")
    println("strlen = {len}")
