//! expect-stdout: ok

// #2400: a field's default is the declaring module's expression. A literal
// that omits the field evaluates the default where the type is declared,
// so a name the default uses (`V2`, from a module only the declaring
// module imports) resolves. At the literal it failed with "unknown type
// 'V2' in struct literal".
use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("field_default_declaring_module", "field_default_declaring_module")
    p7_write(case_dir, "src/game.w", "pub type V2 { x: f64 = 0.0, y: f64 = 0.0 }\nimpl Copy for V2\n")
    p7_write(case_dir, "src/controls.w", "use game\npub type ActionFrame { id: u64 = 0, motion: V2 = V2 {}, held: u32 = 0 }\nimpl Copy for ActionFrame\n")
    p7_write(case_dir, "src/main.w", "use controls\nfn main:\n    var frame = ActionFrame {}\n    print(f\"{frame.motion.x} {frame.held}\")\n")
    let src_dir = p7_join(case_dir, "src")
    let ran = p7_run(src_dir, "field_default_run", "run\0main.w\0")
    p7_assert_success(ran, "a field default resolves in its declaring module")
    assert(ran.stdout.contains("0 0"))
    print("ok")
