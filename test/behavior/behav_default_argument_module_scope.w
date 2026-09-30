//! expect-stdout: ok
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("default_argument_module_scope", "default_argument_module_scope")
    p7_write(root, "src/constants.w", "pub const DEFAULT_ID: i32 = 7\n")
    p7_write(root, "src/facade.w",
        "use constants\n" ++
        "pub type Pads {}\n" ++
        "const PRIVATE_ID: i32 = 11\n" ++
        "var sequence = 0\n" ++
        "fn next() -> i32 { sequence += 1; sequence }\n" ++
        "pub fn Pads.open(id: i32 = DEFAULT_ID, add: i32 = 0) -> i32 { id + add }\n" ++
        "pub fn Pads.private_default(id: i32 = PRIVATE_ID) -> i32 { id }\n" ++
        "pub fn Pads.count(id: i32 = next()) -> i32 { id }\n" ++
        "pub fn Pads.instance(self: &Self, id: i32 = DEFAULT_ID) -> i32 { id }\n" ++
        "pub fn Pads.mutate(mut self: Self, id: i32 = DEFAULT_ID) -> i32 { id }\n" ++
        "pub fn Pads.caller(file: str = __FILE__, name: str = __FN__) -> bool { file.contains(\"src/main.w\") and name == \"main\" }\n" ++
        "pub fn Pads.line(line: u32 = __LINE__) -> u32 { line }\n" ++
        "pub fn free_default(id: i32 = DEFAULT_ID, add: i32 = 0) -> i32 { id + add }\n")
    p7_write(root, "src/main.w",
        "use facade\n" ++
        "fn main {\n" ++
        "    assert(Pads.open() == 7)\n" ++
        "    assert(Pads.open(add: 2) == 9)\n" ++
        "    assert(Pads.private_default() == 11)\n" ++
        "    assert(Pads.count() == 1)\n" ++
        "    assert(Pads.count() == 2)\n" ++
        "    assert(free_default(add: 3) == 10)\n" ++
        "    assert(Pads.caller())\n" ++
        "    let expected_line = __LINE__ + 1\n" ++
        "    assert(Pads.line() == expected_line)\n" ++
        "}\n")
    p7_assert_success(p7_run(root, "defaults", "run\0src/main.w\0"), "defaults use the callee module")
    p7_write(root, "src/shadow.w",
        "use facade\n" ++
        "fn main {\n" ++
        "    let DEFAULT_ID = 99\n" ++
        "    let PRIVATE_ID = 100\n" ++
        "    let next = 123\n" ++
        "    assert(Pads.open() == 7)\n" ++
        "    assert(Pads.open(add: 2) == 9)\n" ++
        "    assert(Pads.private_default() == 11)\n" ++
        "    assert(Pads.count() == 1)\n" ++
        "    assert(free_default(add: 3) == 10)\n" ++
        "    assert(free_default() == 7)\n" ++
        "    var pads = Pads {}\n" ++
        "    assert(pads.instance() == 7)\n" ++
        "    assert(pads.mutate() == 7)\n" ++
        "    assert(DEFAULT_ID == 99 and PRIVATE_ID == 100 and next == 123)\n" ++
        "}\n")
    p7_assert_success(p7_run(root, "shadow", "run\0src/shadow.w\0"), "caller locals do not replace defaults")
    p7_write(root, "src/hidden.w", "use facade\nfn main { Pads.open(); Pads.open(id: DEFAULT_ID) }\n")
    let hidden = p7_run(root, "hidden", "check\0src/hidden.w\0")
    assert(hidden.rc != 0)
    assert(hidden.stderr.contains("not visible from this module"))
    p7_write(root, "src/private.w", "use facade\nfn main { Pads.private_default(); Pads.open(id: PRIVATE_ID) }\n")
    let private = p7_run(root, "private", "check\0src/private.w\0")
    assert(private.rc != 0)
    assert(private.stderr.contains("is private to module"))
    print("ok")
