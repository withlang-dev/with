//! expect-error: undefined variable
use c_import("extern \"C++\" int cpp_linkage_only(int value);\n", lang: "c++")
fn main: print(cpp_linkage_only(1))
