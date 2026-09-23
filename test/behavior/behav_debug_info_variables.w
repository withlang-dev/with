//! skip-on: windows issue #802: core-language behavior fails on native Windows (needs root-cause)
//! expect-stdout: ok

use pre_d_build_runner

// #1348: the debug info had no variable records at all (`frame variable`: "no
// variable information is available in debug info for this compile unit"),
// and a generic function's specialization or a closure had no subprogram, so
// a debugger could not stop on a line inside one. Each is now a subprogram of
// its own, declared at its own line, with its parameters and bindings.
fn prog -> str:
    "use std.process\n" ++
    "\n" ++
    "type Pair[T] { left: T, right: T }\n" ++
    "\n" ++
    "impl[T] Pair[T]:\n" ++
    "    fn swap_sides(self: &Self, extra: i32) -> i32:\n" ++
    "        let widened = extra + args().len() as i32\n" ++
    "        widened * 2\n" ++
    "\n" ++
    "fn largest[T](first: T, second: T, bias: i32) -> i32:\n" ++
    "    let doubled = bias * 2 + args().len() as i32\n" ++
    "    doubled + 1\n" ++
    "\n" ++
    "fn main:\n" ++
    "    let base = args().len() as i32 + 4\n" ++
    "    let label = \"points\"\n" ++
    "    let adder = (n: i32) => n * base + args().len() as i32\n" ++
    "    let p = Pair { left: 3, right: 4 }\n" ++
    "    let total = largest(1, 2, base) + adder(3) + p.swap_sides(7)\n" ++
    "    print(f\"{label} {total}\")\n"

// The metadata id of the first subprogram whose name starts with `name`, at
// `line`: the text between `!` and ` = distinct !DISubprogram(`.
fn subprogram_id(ir: &str, name: &str, line: i32) -> str:
    for l in ir.split("\n"):
        if l.contains(f"!DISubprogram(name: \"{name}") and l.contains(f", line: {line},"):
            return l.slice(1, l.find(" = ")).clone()
    eprint(f"no subprogram `{name}` at line {line}")
    assert(false)
    ""

fn expect(ir: &str, needle: &str):
    if not ir.contains(needle):
        eprint("missing from the IR: " ++ needle)
        assert(false)

fn main:
    let dir = p7_prepare_case("debug_info_variables", "debuginfovariables")
    p7_write(dir, "src/prog.w", prog())
    let ir_run = p7_run(dir, "debug-info-ir", "ir\0src/prog.w\0")
    p7_assert_success(ir_run, "with ir")
    let ir = ir_run.stdout
    let method = subprogram_id(ir, "Pair.swap_sides", 6)
    let generic = subprogram_id(ir, "largest", 10)
    let closure = subprogram_id(ir, "__closure", 17)
    let main_sp = subprogram_id(ir, "main", 14)
    expect(ir, f"!DILocalVariable(name: \"self\", arg: 1, scope: !{method},")
    expect(ir, f"!DILocalVariable(name: \"extra\", arg: 2, scope: !{method},")
    expect(ir, f"!DILocalVariable(name: \"widened\", scope: !{method}, file: ")
    expect(ir, f"!DILocalVariable(name: \"first\", arg: 1, scope: !{generic},")
    expect(ir, f"!DILocalVariable(name: \"bias\", arg: 3, scope: !{generic},")
    expect(ir, f"!DILocalVariable(name: \"doubled\", scope: !{generic}, file: ")
    expect(ir, f"!DILocalVariable(name: \"n\", arg: 1, scope: !{closure},")
    expect(ir, f"!DILocalVariable(name: \"base\", scope: !{closure},")
    expect(ir, f"!DILocalVariable(name: \"label\", scope: !{main_sp}, file: ")
    expect(ir, f"!DILocalVariable(name: \"total\", scope: !{main_sp}, file: ")
    expect(ir, "#dbg_declare(")
    // A `let` is declared on its own line.
    for l in ir.split("\n"):
        if l.contains("!DILocalVariable(name: \"doubled\"") and not l.contains(", line: 11,"):
            eprint("`doubled` is declared on line 11: " ++ l)
            assert(false)
    print("ok")
