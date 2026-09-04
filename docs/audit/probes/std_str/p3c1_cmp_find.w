use std.string

fn main:
    print(f"eq={string_eq("a", "a")} cmp={string_cmp("a", "b")} cmp2={string_cmp("b", "a")} cmp3={string_cmp("a", "a")}")
    print(f"find={"hello".find("ll")} findmiss={"hello".find("zz")} contains={"hello".contains("ell")} sw={"hi".starts_with("h")} ew={"hi".ends_with("i")}")
