module build.release_uat

use std.build
use std.sysinfo

type UatRunResult {
    rc: i32,
    stdout: str,
    stderr: str,
}

fn ruat_fail(ctx: ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn ruat_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/") or left.ends_with("\\"):
        return left ++ right
    left ++ "/" ++ right

fn ruat_is_abs(path: str) -> bool:
    if path.len() == 0:
        return false
    let first = path.byte_at(0)
    if first == 47 or first == 92:
        return true
    if os() == "Windows" and path.len() >= 3:
        let drive = path.byte_at(0)
        let colon = path.byte_at(1)
        let slash = path.byte_at(2)
        if colon == 58 and (slash == 47 or slash == 92):
            return (drive >= 65 and drive <= 90) or (drive >= 97 and drive <= 122)
    false

fn ruat_abs(root: str, path: str) -> str:
    if ruat_is_abs(path):
        return path
    ruat_join(root, path)

fn ruat_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 47 or ch == 92:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn ruat_trim_trailing_line_endings(text: str) -> str:
    var end = text.len()
    while end > 0:
        let ch = text.byte_at(end - 1)
        if ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(0, end)

fn ruat_write_stamp(ctx: ActionCtx) -> i32:
    let output = ctx.output()
    let output_dir = ruat_dirname(output)
    if ctx.fs().mkdir_all(output_dir) != 0:
        return ruat_fail(ctx, "could not create output directory: " ++ output_dir)
    if ctx.fs().write_text(output, "ok\n") != 0:
        return ruat_fail(ctx, "could not write UAT stamp: " ++ output)
    0

fn ruat_prepare_clean_dir(ctx: ActionCtx, path: str) -> i32:
    let fs = ctx.fs()
    if fs.exists(path) and fs.remove_tree(path) != 0:
        return ruat_fail(ctx, "could not remove previous UAT directory: " ++ path)
    if fs.mkdir_all(path) != 0:
        return ruat_fail(ctx, "could not create UAT directory: " ++ path)
    0

fn ruat_compiler_input(ctx: ActionCtx) -> str:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return ""
    ruat_abs(ctx.project_info().project_root(), inputs.get(0))

fn ruat_compiler_input_rel(ctx: ActionCtx) -> str:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return ""
    inputs.get(0)

fn ruat_host_exe_suffix() -> str:
    if os() == "Windows":
        return ".exe"
    ""

fn ruat_argv1(compiler: str, a: str) -> Vec[str]:
    let args: Vec[str] = Vec.new()
    args.push(compiler)
    args.push(a)
    args

fn ruat_argv2(compiler: str, a: str, b: str) -> Vec[str]:
    let args: Vec[str] = Vec.new()
    args.push(compiler)
    args.push(a)
    args.push(b)
    args

fn ruat_argv3(compiler: str, a: str, b: str, c: str) -> Vec[str]:
    let args = ruat_argv2(compiler, a, b)
    args.push(c)
    args

fn ruat_capture_path(root: str, dir: str, label: str, suffix: str) -> str:
    ruat_abs(root, ruat_join(dir, label ++ "." ++ suffix))

fn ruat_run_capture_cwd(ctx: ActionCtx, compiler: str, workdir: str, label: str, args: Vec[str], timeout_ms: i32) -> UatRunResult:
    let root = ctx.project_info().project_root()
    let stdout_path = ruat_capture_path(root, workdir, label, "stdout")
    let stderr_path = ruat_capture_path(root, workdir, label, "stderr")
    let result = ctx.process_runner().run_capture_cwd(args, stdout_path, stderr_path, timeout_ms, ruat_abs(root, workdir))
    UatRunResult { result.rc, result.stdout, result.stderr }

fn ruat_run_capture(ctx: ActionCtx, workdir: str, label: str, args: Vec[str], timeout_ms: i32) -> UatRunResult:
    let root = ctx.project_info().project_root()
    let stdout_path = ruat_capture_path(root, workdir, label, "stdout")
    let stderr_path = ruat_capture_path(root, workdir, label, "stderr")
    let result = ctx.process_runner().run_capture(args, stdout_path, stderr_path, timeout_ms)
    UatRunResult { result.rc, result.stdout, result.stderr }

fn ruat_run_capture_input(ctx: ActionCtx, compiler: str, workdir: str, label: str, code_mode: str, code: str, stdin_text: str, timeout_ms: i32) -> UatRunResult:
    let root = ctx.project_info().project_root()
    let stdin_rel = ruat_join(workdir, label ++ ".stdin")
    if ctx.fs().write_text(stdin_rel, stdin_text) != 0:
        return UatRunResult { 1, "", "could not write stdin fixture: " ++ stdin_rel }
    let stdout_path = ruat_capture_path(root, workdir, label, "stdout")
    let stderr_path = ruat_capture_path(root, workdir, label, "stderr")
    let args = ruat_argv2(compiler, code_mode, code)
    let result = ctx.process_runner().run_capture_input(args, stdout_path, stderr_path, timeout_ms, ruat_abs(root, stdin_rel))
    UatRunResult { result.rc, result.stdout, result.stderr }

fn ruat_expect_success(ctx: ActionCtx, result: UatRunResult, label: str) -> i32:
    if result.rc == 0:
        return 0
    ruat_fail(ctx, label ++ f" failed with exit code {result.rc}\nstdout:\n" ++ result.stdout ++ "\nstderr:\n" ++ result.stderr)

fn ruat_expect_stdout(ctx: ActionCtx, result: UatRunResult, expected: str, label: str) -> i32:
    let rc = ruat_expect_success(ctx, result, label)
    if rc != 0:
        return rc
    let actual = ruat_trim_trailing_line_endings(result.stdout)
    if actual == expected:
        return 0
    ruat_fail(ctx, "stdout mismatch for " ++ label ++ "\nexpected:\n" ++ expected ++ "\nactual:\n" ++ actual)

fn ruat_expect_stdout_contains(ctx: ActionCtx, result: UatRunResult, expected: str, label: str) -> i32:
    let rc = ruat_expect_success(ctx, result, label)
    if rc != 0:
        return rc
    if result.stdout.contains(expected):
        return 0
    ruat_fail(ctx, "stdout for " ++ label ++ " did not contain '" ++ expected ++ "'\nstdout:\n" ++ result.stdout ++ "\nstderr:\n" ++ result.stderr)

fn ruat_expect_file_contains(ctx: ActionCtx, path: str, expected: str, label: str) -> i32:
    if not ctx.fs().exists(path):
        return ruat_fail(ctx, label ++ " did not create " ++ path)
    let text = ctx.fs().read_text(path)
    if text.contains(expected):
        return 0
    ruat_fail(ctx, label ++ " output did not contain '" ++ expected ++ "'\nfile:\n" ++ text)

fn ruat_sequence_1_to_100() -> str:
    var out = ""
    for i in 1..101:
        out = out ++ f"{i}\n"
    out

fn ruat_tiny_c_source() -> str:
    "#define SCALE 2\n\n" ++
    "struct Pair { int a; int b; };\n\n" ++
    "int add_pair(struct Pair p) {\n" ++
    "    return (p.a + p.b) * SCALE;\n" ++
    "}\n\n" ++
    "int main(void) {\n" ++
    "    struct Pair p = { 20, 1 };\n" ++
    "    return add_pair(p) == 42 ? 0 : 1;\n" ++
    "}\n"

fn ruat_zlib_program() -> str:
    "use c_import(\"zlib.h\")\n\n" ++
    "fn main:\n" ++
    "    let bound = compressBound(12 as uLong)\n" ++
    "    if bound <= 12 as uLong:\n" ++
    "        print(\"zlib UAT failed\")\n" ++
    "        return 1\n" ++
    "    write(\"zlib UAT passed\\n\")\n"

pub fn run_release_artifact_smoke_uat_action(ctx: ActionCtx) -> i32:
    let compiler = ruat_compiler_input(ctx)
    if compiler.len() == 0:
        return ruat_fail(ctx, "missing compiler input")

    let workdir = "out/release-uat/artifact-smoke"
    var rc = ruat_prepare_clean_dir(ctx, workdir)
    if rc != 0:
        return rc

    rc = ruat_expect_stdout_contains(ctx, ruat_run_capture(ctx, workdir, "version", ruat_argv1(compiler, "version"), 120000), "with ", "release artifact version")
    if rc != 0:
        return rc

    rc = ruat_expect_stdout(ctx, ruat_run_capture(ctx, workdir, "eval", ruat_argv2(compiler, "-e", "print(\"artifact smoke\")"), 120000), "artifact smoke", "release artifact -e")
    if rc != 0:
        return rc

    if ctx.fs().write_text(ruat_join(workdir, "smoke.w"), "fn main:\n    print(\"artifact run\")\n") != 0:
        return ruat_fail(ctx, "could not write artifact smoke source")
    rc = ruat_expect_stdout(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "run-file", ruat_argv2(compiler, "run", "smoke.w"), 120000), "artifact run", "release artifact run file")
    if rc != 0:
        return rc

    ruat_write_stamp(ctx)

pub fn run_release_fresh_project_uat_action(ctx: ActionCtx) -> i32:
    let compiler = ruat_compiler_input(ctx)
    if compiler.len() == 0:
        return ruat_fail(ctx, "missing compiler input")

    let workdir = "out/release-uat/fresh-project"
    var rc = ruat_prepare_clean_dir(ctx, workdir)
    if rc != 0:
        return rc

    let init_args: Vec[str] = Vec.new()
    init_args.push(compiler)
    init_args.push("init")
    init_args.push(".")
    init_args.push("--name")
    init_args.push("fresh_project_uat")
    rc = ruat_expect_success(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "init", init_args, 120000), "with init fresh project")
    if rc != 0:
        return rc

    let source = "fn main:\n    print(\"fresh project UAT passed\")\n"
    if ctx.fs().write_text(ruat_join(workdir, "src/main.w"), source) != 0:
        return ruat_fail(ctx, "could not write fresh project source")

    rc = ruat_expect_stdout(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "run", ruat_argv1(compiler, "run"), 120000), "fresh project UAT passed", "fresh project with run")
    if rc != 0:
        return rc

    ruat_write_stamp(ctx)

pub fn run_release_migrate_uat_action(ctx: ActionCtx) -> i32:
    let compiler = ruat_compiler_input(ctx)
    if compiler.len() == 0:
        return ruat_fail(ctx, "missing compiler input")

    let workdir = "out/release-uat/migrate"
    var rc = ruat_prepare_clean_dir(ctx, workdir)
    if rc != 0:
        return rc

    let c_path = ruat_join(workdir, "tiny.c")
    let w_path = ruat_join(workdir, "tiny.w")
    if ctx.fs().write_text(c_path, ruat_tiny_c_source()) != 0:
        return ruat_fail(ctx, "could not write C migration fixture")

    let migrate_args: Vec[str] = Vec.new()
    migrate_args.push(compiler)
    migrate_args.push("migrate")
    migrate_args.push("tiny.c")
    migrate_args.push("-o")
    migrate_args.push("tiny.w")
    migrate_args.push("--no-c-export")
    migrate_args.push("--prefer-colon")
    rc = ruat_expect_success(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "migrate", migrate_args, 120000), "with migrate tiny.c")
    if rc != 0:
        return rc

    rc = ruat_expect_file_contains(ctx, w_path, "fn add_pair", "with migrate tiny.c")
    if rc != 0:
        return rc
    rc = ruat_expect_success(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "check", ruat_argv2(compiler, "check", "tiny.w"), 120000), "with check migrated tiny.w")
    if rc != 0:
        return rc
    rc = ruat_expect_success(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "run", ruat_argv2(compiler, "run", "tiny.w"), 120000), "with run migrated tiny.w")
    if rc != 0:
        return rc

    ruat_write_stamp(ctx)

pub fn run_release_zlib_uat_action(ctx: ActionCtx) -> i32:
    let compiler = ruat_compiler_input(ctx)
    if compiler.len() == 0:
        return ruat_fail(ctx, "missing compiler input")

    let workdir = "out/release-uat/zlib-project"
    var rc = ruat_prepare_clean_dir(ctx, workdir)
    if rc != 0:
        return rc

    rc = ruat_expect_success(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "init", ruat_argv2(compiler, "init", "."), 120000), "with init zlib project")
    if rc != 0:
        return rc

    rc = ruat_expect_success(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "get-zlib", ruat_argv2(compiler, "get", "c.zlib"), 600000), "with get c.zlib")
    if rc != 0:
        return rc

    if ctx.fs().write_text(ruat_join(workdir, "src/main.w"), ruat_zlib_program()) != 0:
        return ruat_fail(ctx, "could not write zlib UAT source")

    rc = ruat_expect_stdout(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "run", ruat_argv1(compiler, "run"), 120000), "zlib UAT passed", "with run zlib")
    if rc != 0:
        return rc

    ruat_write_stamp(ctx)

pub fn run_release_install_layout_uat_action(ctx: ActionCtx) -> i32:
    let compiler = ruat_compiler_input(ctx)
    let compiler_rel = ruat_compiler_input_rel(ctx)
    if compiler.len() == 0 or compiler_rel.len() == 0:
        return ruat_fail(ctx, "missing compiler input")

    let workdir = "out/release-uat/install-layout"
    var rc = ruat_prepare_clean_dir(ctx, workdir)
    if rc != 0:
        return rc

    let installed_rel = ruat_join(workdir, "bin/with" ++ ruat_host_exe_suffix())
    if ctx.fs().copy_file(compiler_rel, installed_rel) != 0:
        return ruat_fail(ctx, "could not copy compiler into install-layout bin")
    if os() != "Windows" and ctx.fs().chmod(installed_rel, 0o755) != 0:
        return ruat_fail(ctx, "could not chmod install-layout compiler")

    let installed = ruat_abs(ctx.project_info().project_root(), installed_rel)
    rc = ruat_expect_stdout_contains(ctx, ruat_run_capture(ctx, workdir, "version", ruat_argv1(installed, "version"), 120000), "with ", "installed compiler version")
    if rc != 0:
        return rc
    rc = ruat_expect_stdout(ctx, ruat_run_capture(ctx, workdir, "eval", ruat_argv2(installed, "-e", "print(\"installed UAT passed\")"), 120000), "installed UAT passed", "installed compiler -e")
    if rc != 0:
        return rc

    ruat_write_stamp(ctx)

fn ruat_spiral_program() -> str:
    "use c_import(\"raylib.h\")\n\n" ++
    "extern fn sin(x: f64) -> f64\n" ++
    "extern fn cos(x: f64) -> f64\n\n" ++
    "fn draw_spiral(cx: f64, cy: f64, t: f64):\n" ++
    "    for i in 0..180:\n" ++
    "        let p = (i as f64) / 180.0\n" ++
    "        let angle = p * 18.8495559215 + t * 0.8\n" ++
    "        let radius = 28.0 + p * 250.0 + sin(t * 1.4 + p * 6.0) * 18.0\n" ++
    "        let x = cx + cos(angle) * radius\n" ++
    "        let y = cy + sin(angle) * radius\n" ++
    "        let hue = (p * 360.0 + t * 50.0) as f32\n" ++
    "        let col = ColorFromHSV(hue, 0.86 as f32, 1.0 as f32)\n" ++
    "        DrawCircle(x as i32, y as i32, (4.0 + p * 4.0) as f32, col)\n\n" ++
    "fn is_spiral_sample(c: Color) -> bool:\n" ++
    "    let r = c.r as i32\n" ++
    "    let g = c.g as i32\n" ++
    "    let b = c.b as i32\n" ++
    "    (r > 70 or g > 70 or b > 70) and (r + g + b > 170)\n\n" ++
    "fn main:\n" ++
    "    InitWindow(900, 600, \"with raylib spiral uat\")\n" ++
    "    SetTargetFPS(60)\n\n" ++
    "    let bg = Color { r: 14, g: 16, b: 26, a: 255 }\n" ++
    "    let cx = 450.0\n" ++
    "    let cy = 300.0\n" ++
    "    let t = 1.25\n\n" ++
    "    var frame = 0\n" ++
    "    while frame < 10:\n" ++
    "        BeginDrawing()\n" ++
    "        ClearBackground(bg)\n" ++
    "        draw_spiral(cx, cy, t)\n" ++
    "        DrawText(\"with raylib spiral uat\", 20, 20, 20, LIGHTGRAY)\n" ++
    "        EndDrawing()\n" ++
    "        frame = frame + 1\n\n" ++
    "    let image = LoadImageFromScreen()\n" ++
    "    var colored = 0\n" ++
    "    var samples = 0\n\n" ++
    "    var y = 40\n" ++
    "    while y < 560:\n" ++
    "        var x = 40\n" ++
    "        while x < 860:\n" ++
    "            let dx = (x as f64) - cx\n" ++
    "            let dy = (y as f64) - cy\n" ++
    "            let dist2 = dx * dx + dy * dy\n" ++
    "            if dist2 > 900.0 and dist2 < 90000.0:\n" ++
    "                samples = samples + 1\n" ++
    "                if is_spiral_sample(GetImageColor(image, x, y)):\n" ++
    "                    colored = colored + 1\n" ++
    "            x = x + 6\n" ++
    "        y = y + 6\n\n" ++
    "    UnloadImage(image)\n" ++
    "    CloseWindow()\n\n" ++
    "    if samples < 4000:\n" ++
    "        print(f\"raylib spiral UAT failed: only sampled {samples} pixels\")\n" ++
    "        return 1\n" ++
    "    if colored < 120:\n" ++
    "        print(f\"raylib spiral UAT failed: only found {colored} bright spiral samples\")\n" ++
    "        return 1\n\n" ++
    "    print(f\"raylib spiral UAT passed: {colored}/{samples} bright spiral samples\")\n" ++
    "    0\n"

pub fn run_release_raylib_spiral_uat_action(ctx: ActionCtx) -> i32:
    let compiler = ruat_compiler_input(ctx)
    if compiler.len() == 0:
        return ruat_fail(ctx, "missing compiler input")

    let workdir = "out/release-uat/raylib-spiral-project"
    var rc = ruat_prepare_clean_dir(ctx, workdir)
    if rc != 0:
        return rc

    rc = ruat_expect_success(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "init", ruat_argv2(compiler, "init", "."), 120000), "with init")
    if rc != 0:
        return rc

    rc = ruat_expect_success(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "get-raylib", ruat_argv2(compiler, "get", "c.raylib"), 600000), "with get c.raylib")
    if rc != 0:
        return rc

    if ctx.fs().write_text(ruat_join(workdir, "src/main.w"), ruat_spiral_program()) != 0:
        return ruat_fail(ctx, "could not write spiral UAT source")

    rc = ruat_expect_stdout(ctx, ruat_run_capture_cwd(ctx, compiler, workdir, "check", ruat_argv2(compiler, "check", "src/main.w"), 120000), "ok", "with check spiral")
    if rc != 0:
        return rc

    let run_result = ruat_run_capture_cwd(ctx, compiler, workdir, "run", ruat_argv1(compiler, "run"), 180000)
    rc = ruat_expect_success(ctx, run_result, "with run spiral")
    if rc != 0:
        return rc
    let stdout = ruat_trim_trailing_line_endings(run_result.stdout)
    if not stdout.contains("raylib spiral UAT passed:"):
        return ruat_fail(ctx, "spiral UAT did not report visual pass\nstdout:\n" ++ run_result.stdout ++ "\nstderr:\n" ++ run_result.stderr)

    ruat_write_stamp(ctx)

pub fn run_release_one_liner_uat_action(ctx: ActionCtx) -> i32:
    let compiler = ruat_compiler_input(ctx)
    if compiler.len() == 0:
        return ruat_fail(ctx, "missing compiler input")

    let workdir = "out/release-uat/one-liners"
    var rc = ruat_prepare_clean_dir(ctx, workdir)
    if rc != 0:
        return rc

    rc = ruat_expect_stdout(
        ctx,
        ruat_run_capture_input(ctx, compiler, workdir, "single-digit-regex-filter", "-n", "if line =~ /^[0-9]$/: print(line)", ruat_sequence_1_to_100(), 120000),
        "1\n2\n3\n4\n5\n6\n7\n8\n9",
        "seq 100 | with -n single-digit regex filter")
    if rc != 0:
        return rc

    let names = "Ada Lovelace\nGrace Hopper\nKatherine Johnson\nMargaret Hamilton\n"
    if ctx.fs().write_text(ruat_join(workdir, "names.txt"), names) != 0:
        return ruat_fail(ctx, "could not write names.txt fixture")
    rc = ruat_expect_stdout(
        ctx,
        ruat_run_capture_input(ctx, compiler, workdir, "names-upper", "-p", "line = line.upper()", names, 120000),
        "ADA LOVELACE\nGRACE HOPPER\nKATHERINE JOHNSON\nMARGARET HAMILTON",
        "cat names.txt | with -p upper")
    if rc != 0:
        return rc

    rc = ruat_expect_stdout(
        ctx,
        ruat_run_capture_input(ctx, compiler, workdir, "numbered-regex-captures", "-n", "if line =~ /(?<kind>error|warning) (\\d+)/: print(f\"{nr}: {$kind.upper()} code={$2}\")", "error 42\nok\nwarning 7\n", 120000),
        "1: ERROR code=42\n3: WARNING code=7",
        "numbered regex captures")
    if rc != 0:
        return rc

    rc = ruat_expect_stdout(
        ctx,
        ruat_run_capture_input(ctx, compiler, workdir, "nr-map-upper", "-p", "line = f\"{nr}:{line.upper()}\"", "apple\nbanana\npear\n", 120000),
        "1:APPLE\n2:BANANA\n3:PEAR",
        "numbered -p map")
    if rc != 0:
        return rc

    rc = ruat_expect_stdout(
        ctx,
        ruat_run_capture_input(ctx, compiler, workdir, "semicolon-transform", "-p", "line = line.upper(); line = line ++ \"!\"", "abc\n", 120000),
        "ABC!",
        "semicolon transform in -p")
    if rc != 0:
        return rc

    var args: Vec[str] = Vec.new()
    args.push(compiler)
    args.push("-e")
    args.push("for arg in args: print(arg.upper())")
    args.push("--")
    args.push("alpha")
    args.push("beta")
    args.push("gamma")
    rc = ruat_expect_stdout(ctx, ruat_run_capture(ctx, workdir, "one-liner-args", args, 120000), "ALPHA\nBETA\nGAMMA", "one-liner -- args")
    if rc != 0:
        return rc

    ruat_write_stamp(ctx)
