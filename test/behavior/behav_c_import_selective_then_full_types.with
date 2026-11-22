//! expect-stdout: 5 7 11 13 17

// #1872: names filtered by only: are available to a later full import.
// Aa/BB collide in the emitted-name table, as do Gf/HG at its last slot;
// removing a filtered name must preserve the retained collision's lookup.
// The C name `match` is escaped in the With AST, and must be released too.
use c_import("typedef int Aa; typedef int BB; typedef int Gf; typedef int HG; typedef int match;\n#define alias_t Aa\nstatic inline int keep(int x) { return x; }\n", only: ["BB", "HG", "keep"])
use c_import("typedef int Aa; typedef int BB; typedef int Gf; typedef int HG; typedef int match;\n#define alias_t Aa\nstatic inline int keep(int x) { return x; }\nint more(int x);\n")

fn main:
    let a: alias_t = 5
    let b: BB = 7
    let c: Gf = 11
    let d: HG = 13
    let e: match_ = 17
    print(f"{keep(a)} {b} {c} {d} {e}")
