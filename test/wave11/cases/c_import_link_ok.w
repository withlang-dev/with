use c_import("int ext_add(int, int);", link: "extadd")

fn main -> i32:
    if ext_add(1, 2) == 8 then 0 else 1
