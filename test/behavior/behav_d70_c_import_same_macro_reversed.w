//! expect-stdout: 3 3 4 1

// #1753: behav_d70_c_import_same_macro.w with the imports reversed — the
// bare name follows the import order (D70: the last import wins), and both
// values stay reachable through the headers' namespaces.
use c_import("behav_d70_second_header.h")
use c_import("behav_d70_raylike.h")

fn main:
    print(f"{PI} {behav_d70_raylike.PI} {behav_d70_second_header.PI} {ONE}")
