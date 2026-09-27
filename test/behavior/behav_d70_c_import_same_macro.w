//! expect-stdout: 4 3 4 1

// #1753 (D70, §18.2): two c_imports whose headers define one macro are two
// imports: the later shadows the earlier for the bare name, and each
// header's value stays reachable through its namespace (its file name
// without `.h`). The second header's PI was deduplicated against the
// first's, so its translation came back empty and was reported as "failed
// to compile C header snippet". behav_d70_c_import_same_macro_reversed.w
// imports them the other way round.
use c_import("behav_d70_raylike.h")
use c_import("behav_d70_second_header.h")

fn main:
    print(f"{PI} {behav_d70_raylike.PI} {behav_d70_second_header.PI} {ONE}")
