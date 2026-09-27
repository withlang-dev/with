//! expect-build-stderr: behav_1447_build_warning_span.w:13:9
//! expect-build-stderr: |         types = cur ++ types
// #1447: a build renders the root file's warnings after codegen, which had
// moved the root source text out of the compilation unit, so every warning
// read 1:1 of an empty line. The ++-in-loop warning names the assignment.

fn main:
    var types = ""
    let cur = "x"
    var n = 0
    while n < 2:
        n = n + 1
        types = cur ++ types
    print(types)
