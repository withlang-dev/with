use c_import("#include <stdio.h>\n#include <string.h>")

fn main() -> i32 =
    puts("hello from c_import")
    let len = strlen("test string")
    println("strlen = {len}")
    0
