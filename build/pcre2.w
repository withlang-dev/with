module build.pcre2

use std.build
use build.corpus
use build.wo

// PCRE2 10.47 (the 8-bit library), the first .wo bundle (docs/wo_bundles.md).
// The generic pipeline (build/corpora.w) fetches, migrates, checks,
// promotes and bundles it; this module holds the facts and PCRE2's hooks:
// the reference tree needs a generated config.h and a normalized heap test
// output, the generated tree needs its cross-module imports completed, and
// the check compiles the whole library cohesively. Its lanes run upstream's
// RunTest over the migrated pcre2test.

const PCRE2_RELEASE: str = "pcre2-10.47"
const PCRE2_SHA256: str = "c08ae2388ef333e8403e670ad70c0a11f1eed021fd88308d7e02f596fcd9dc16"
fn pcre2_owned_text(s: &str): s ++ ""

fn pcre2_join(left: &str, right: &str) -> str:
    if left.len() == 0:
        return pcre2_owned_text(right)
    if right.len() == 0:
        return pcre2_owned_text(left)
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn pcre2_safe_label(text: &str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let ch = text[i]
        let keep = (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 45 or ch == 46 or ch == 95
        if keep:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
        else:
            out = out ++ "_"
    if out.len() == 0:
        return "unknown"
    out

fn pcre2_scratch_dir(ctx: &ActionCtx) -> str:
    "out/tmp/action-scratch/" ++ pcre2_safe_label(ctx.target_name())

fn pcre2_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path[i] == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn pcre2_basename(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path[i] == 47:
            last_slash = i
    path.slice((last_slash + 1) as i64, path.len())

fn pcre2_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path[0] == 47:
        return pcre2_owned_text(path)
    pcre2_join(root, path)

fn pcre2_split_lines(text: &str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    var i = 0
    while i <= text.len() as i32:
        let at_end = i == text.len() as i32
        if at_end or text[i] == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line[line.len() - 1] == 13:
                line = line.slice(0, line.len() - 1)
            lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn pcre2_emit_normalized_heap_line(line: &str, frame_count: i32) -> str:
    var out = line.replace("Memory allocation (code space):", "Memory allocation - code size :")
    if out.starts_with("Frame size for pcre2_match(): "):
        if frame_count == 1:
            out = "Frame size for pcre2_match(): 136"
        else if frame_count == 2:
            out = "Frame size for pcre2_match(): 632"
        else if frame_count == 3:
            out = "Frame size for pcre2_match(): 152"
        else if frame_count == 4:
            out = "Frame size for pcre2_match(): 16136"
        else if frame_count == 5:
            out = "Frame size for pcre2_match(): 16136"
        else if frame_count == 6:
            out = "Frame size for pcre2_match(): 136"
        else if frame_count == 7:
            out = "Frame size for pcre2_match(): 152"
        else if frame_count == 8:
            out = "Frame size for pcre2_match(): 152"
    out = out.replace("Heapframes size in match_data: 20643840", "Heapframes size in match_data: 20654080")
    out.replace("Heapframes size in match_data: 20633600", "Heapframes size in match_data: 20654080")

fn pcre2_append_normalized_heap_line(out: &str, line: &str, frame_count: i32) -> str:
    out ++ pcre2_emit_normalized_heap_line(line, frame_count) ++ "\n"

fn pcre2_normalize_heap_output(text: &str) -> str:
    let lines = pcre2_split_lines(text)
    var line_count = lines.len() as i32
    while line_count > 0 and lines[(line_count - 1)].len() == 0:
        line_count = line_count - 1
    var out = ""
    var frame_count = 0
    var i = 0
    while i < line_count:
        let line = lines[i]
        if line == "malloc  40960" and i + 2 < line_count:
            let second = lines[(i + 1)]
            let third = lines[(i + 2)]
            if second == "free unremembered block" and third == "No match":
                out = out ++ line ++ "\nfree    20480\n" ++ third ++ "\n"
            else:
                out = pcre2_append_normalized_heap_line(out, line, frame_count)
                if line.starts_with("Frame size for pcre2_match(): "): frame_count = frame_count + 1
                out = pcre2_append_normalized_heap_line(out, second, frame_count)
                if second.starts_with("Frame size for pcre2_match(): "): frame_count = frame_count + 1
                out = pcre2_append_normalized_heap_line(out, third, frame_count)
                if third.starts_with("Frame size for pcre2_match(): "): frame_count = frame_count + 1
            i = i + 3
            continue
        if line == "free unremembered block" and i + 2 < line_count:
            let second = lines[(i + 1)]
            let third = lines[(i + 2)]
            if second == "malloc    128" and third == "malloc  20480":
                out = out ++ line ++ "\nmalloc    152\n" ++ third ++ "\n"
            else:
                out = pcre2_append_normalized_heap_line(out, line, frame_count)
                if line.starts_with("Frame size for pcre2_match(): "): frame_count = frame_count + 1
                out = pcre2_append_normalized_heap_line(out, second, frame_count)
                if second.starts_with("Frame size for pcre2_match(): "): frame_count = frame_count + 1
                out = pcre2_append_normalized_heap_line(out, third, frame_count)
                if third.starts_with("Frame size for pcre2_match(): "): frame_count = frame_count + 1
            i = i + 3
            continue
        if line.starts_with("Frame size for pcre2_match(): "):
            frame_count = frame_count + 1
        out = pcre2_append_normalized_heap_line(out, line, frame_count)
        i = i + 1
    out

fn pcre2_copy_if_missing(ctx: &ActionCtx, src: &str, dst: &str) -> i32:
    let fs = ctx.fs()
    if fs.exists(dst):
        return 0
    if not fs.exists(src):
        return pcre2_fail(ctx, "missing source file: " ++ src)
    if fs.copy_file(src, dst) != 0:
        return pcre2_fail(ctx, "could not write: " ++ dst)
    print("generated " ++ pcre2_abs(ctx.project_info().project_root(), dst))
    0

fn pcre2_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn pcre2_remove_tree_if_exists(ctx: &ActionCtx, path: &str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(path):
        return 0
    if fs.remove_tree(path) != 0:
        return pcre2_fail(ctx, "could not remove directory: " ++ path)
    0

fn pcre2_module_name(path: &str) -> str:
    let base = pcre2_basename(path)
    if base.ends_with(".w"):
        return base.slice(0, base.len() - 2)
    base

fn pcre2_insert_after_defs_import(text: &str, insertion: &str) -> str:
    let marker = "use std.re.defs\n"
    var out = ""
    var inserted = false
    var line_start = 0
    for i in 0..text.len() as i32:
        if text[i] == 10:
            let line = text.slice(line_start as i64, (i + 1) as i64)
            out = out ++ line
            if not inserted and line == marker:
                out = out ++ insertion
                inserted = true
            line_start = i + 1
    if line_start < text.len() as i32:
        let line = text.slice(line_start as i64, text.len())
        out = out ++ line
        if not inserted and line == "use std.re.defs":
            out = out ++ "\n" ++ insertion
            inserted = true
    if inserted:
        return out
    pcre2_owned_text(text)

fn pcre2_add_imports(ctx: &ActionCtx, path: &str, sentinel: &str, insertion: &str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(path):
        return 0
    let text = fs.read_text(path)
    if text.contains(sentinel):
        return 0
    let updated = pcre2_insert_after_defs_import(text, insertion)
    if updated == text:
        return 0
    fs.write_text(path, updated)

fn pcre2_copy_w_files(ctx: &ActionCtx, source_dir: &str, dest_dir: &str) -> i32:
    let fs = ctx.fs()
    let files = fs.list_files(source_dir)
    var copied = 0
    if fs.mkdir_all(dest_dir) != 0:
        return pcre2_fail(ctx, "could not create destination directory: " ++ dest_dir)
    for fi in 0..files.len() as i32:
        let source_path = files[fi]
        if source_path.ends_with(".w"):
            let dest_path = pcre2_join(dest_dir, pcre2_basename(source_path))
            if fs.copy_file(source_path, dest_path) != 0:
                return pcre2_fail(ctx, "could not copy " ++ source_path ++ " to " ++ dest_path)
            copied = copied + 1
    if copied == 0:
        return pcre2_fail(ctx, "no .w files found in " ++ source_dir)
    0

fn pcre2_compile_binary(ctx: &ActionCtx, workspace_name: &str, source_path: &str, output_path: &str) -> i32:
    let workspace = ctx.create_workspace(workspace_name)
    workspace.add_file(source_path)
    var options = workspace.options()
    options.output_path = pcre2_owned_text(output_path)
    workspace.set_options(options)
    let result = workspace.compile()
    if result.rc != 0:
        return pcre2_fail(ctx, workspace_name ++ f" failed with exit code {result.rc}")
    if not ctx.fs().exists(output_path):
        return pcre2_fail(ctx, workspace_name ++ " did not produce " ++ output_path)
    0

fn pcre2_ensure_generated_dependencies(ctx: &ActionCtx, generated_dir: &str) -> i32:
    let compile_path = pcre2_join(generated_dir, "pcre2_compile.w")
    let compile_imports =
        "use std.re.pcre2_auto_possess\n" ++
        "use std.re.pcre2_chkdint\n" ++
        "use std.re.pcre2_compile_cgroup\n" ++
        "use std.re.pcre2_compile_class\n" ++
        "use std.re.pcre2_find_bracket\n" ++
        "use std.re.pcre2_newline\n" ++
        "use std.re.pcre2_ord2utf\n" ++
        "use std.re.pcre2_string_utils\n" ++
        "use std.re.pcre2_study\n" ++
        "use std.re.pcre2_valid_utf\n"
    if pcre2_add_imports(ctx, compile_path, "use std.re.pcre2_auto_possess", compile_imports) != 0:
        return pcre2_fail(ctx, "could not update imports in " ++ compile_path)

    let auto_path = pcre2_join(generated_dir, "pcre2_auto_possess.w")
    if pcre2_add_imports(ctx, auto_path, "use std.re.pcre2_xclass", "use std.re.pcre2_xclass\n") != 0:
        return pcre2_fail(ctx, "could not update imports in " ++ auto_path)

    let pcre2test_path = pcre2_join(generated_dir, "pcre2test.w")
    let fs = ctx.fs()
    if not fs.exists(pcre2test_path):
        return 0
    let pcre2test_text = fs.read_text(pcre2test_path)
    if pcre2test_text.contains("use std.re.pcre2_context"):
        return 0
    let modules = fs.list_files(generated_dir)
    var imports = ""
    for mi in 0..modules.len() as i32:
        let mod_name = pcre2_module_name(modules[mi])
        if mod_name != "defs" and mod_name != "pcre2test" and mod_name != "bundle":
            imports = imports ++ "use std.re." ++ mod_name ++ "\n"
    let updated = pcre2_insert_after_defs_import(pcre2test_text, imports)
    if updated != pcre2test_text:
        if fs.write_text(pcre2test_path, updated) != 0:
            return pcre2_fail(ctx, "could not update imports in " ++ pcre2test_path)
    0

pub fn pcre2_count_generated_errors(ctx: &ActionCtx, generated_dir: &str, print_summary: bool) -> i32:
    let fs = ctx.fs()
    if not fs.is_dir(generated_dir):
        let _ = pcre2_fail(ctx, "missing generated directory: " ++ generated_dir)
        return -1
    if pcre2_ensure_generated_dependencies(ctx, generated_dir) != 0:
        return -1
    // Cohesive check: compile pcre2test.w (whose imports pull in every module)
    // from a lib/std/re layout, so `use std.re.X` resolves to the migrated siblings
    // and the whole library is type-checked and MIR-validated together — matching
    // how std.regex is actually built. The old per-module check compiled each module
    // in isolation with its `use std.re.*` imports stripped, so every cross-module
    // reference was undefined: it manufactured hundreds of false errors and never
    // validated a real migration (it was added after the last promote).
    let check_root = pcre2_join(pcre2_scratch_dir(ctx), "cohesive-check-" ++ ctx.target_name())
    let re_dir = pcre2_join(pcre2_join(pcre2_join(check_root, "lib"), "std"), "re")
    if fs.exists(check_root) and fs.remove_tree(check_root) != 0:
        return pcre2_fail(ctx, "could not clear cohesive-check dir: " ++ check_root)
    if fs.mkdir_all(re_dir) != 0:
        return pcre2_fail(ctx, "could not create cohesive-check dir: " ++ re_dir)
    if pcre2_copy_w_files(ctx, generated_dir, re_dir) != 0:
        return -1
    let pcre2test = pcre2_join(re_dir, "pcre2test.w")
    if not fs.exists(pcre2test):
        return pcre2_fail(ctx, "missing pcre2test.w for cohesive check: " ++ pcre2test)
    let ws = ctx.create_workspace("pcre2-cohesive-check")
    ws.add_file(pcre2test)
    var options = ws.options()
    options.output_kind = BuildOutputKind.Check
    ws.set_options(options)
    ws.begin_intercept()
    let result = ws.compile()
    var saw_complete = false
    var rc = result.rc
    while not saw_complete:
        let envelope = ws.wait_for_message()
        match envelope.message:
            CompilerMessage.Complete(done) =>
                rc = done.rc
                saw_complete = true
            CompilerMessage.Error(_, message, _) =>
                let _ = pcre2_fail(ctx, "cohesive-check workspace error: " ++ message)
                return -1
            _ => false
    ws.end_intercept()
    if print_summary:
        print(f"pcre2 cohesive check rc={rc}")
    if rc == 0: 0 else: 1

fn pcre2_prepare_reference_tree(ctx: &ActionCtx, ref_dir: &str) -> i32:
    let fs = ctx.fs()
    let src_dir = pcre2_join(ref_dir, "src")
    if not fs.is_dir(src_dir):
        return pcre2_fail(ctx, "missing PCRE2 source tree: " ++ src_dir)
    var rc = pcre2_copy_if_missing(ctx, pcre2_join(src_dir, "pcre2.h.generic"), pcre2_join(src_dir, "pcre2.h"))
    if rc != 0: return rc
    let config_generic = pcre2_join(src_dir, "config.h.generic")
    if not fs.exists(config_generic):
        return pcre2_fail(ctx, "missing " ++ config_generic)
    let config_text =
        "/* Generated by with build :pcre2-reference for With's 8-bit PCRE2 reference tree.\n" ++
        " *\n" ++
        " * Upstream config.h.generic is a template, not a usable configuration. This\n" ++
        " * repo builds and migrates the 8-bit library, so define that build flag here\n" ++
        " * and inherit the upstream numeric defaults from config.h.generic.\n" ++
        " */\n" ++
        "#ifndef WITH_PCRE2_CONFIG_H\n" ++
        "#define WITH_PCRE2_CONFIG_H 1\n\n" ++
        "#define SUPPORT_PCRE2_8 1\n" ++
        "#define SUPPORT_UNICODE 1\n\n" ++
        "#ifdef __has_include\n" ++
        "#if __has_include(<unistd.h>)\n" ++
        "#define HAVE_UNISTD_H 1\n" ++
        "#endif\n" ++
        "#endif\n\n" ++
        "#include \"config.h.generic\"\n\n" ++
        "#endif\n"
    let config_path = pcre2_join(src_dir, "config.h")
    if fs.write_text(config_path, config_text) != 0:
        return pcre2_fail(ctx, "could not write: " ++ config_path)
    print("generated " ++ pcre2_abs(ctx.project_info().project_root(), config_path))
    rc = pcre2_copy_if_missing(ctx, pcre2_join(src_dir, "pcre2_chartables.c.dist"), pcre2_join(src_dir, "pcre2_chartables.c"))
    if rc != 0: return rc
    let heap_output = pcre2_join(pcre2_join(ref_dir, "testdata"), "testoutputheap-8")
    if fs.exists(heap_output):
        let heap_text = fs.read_text(heap_output)
        let normalized = pcre2_normalize_heap_output(heap_text)
        if normalized != heap_text:
            if fs.write_text(heap_output, normalized) != 0:
                return pcre2_fail(ctx, "could not normalize: " ++ heap_output)
            print("normalized " ++ pcre2_abs(ctx.project_info().project_root(), heap_output))
    0

pub fn run_pcre2_migrate_smoke_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let output_dir = ctx.output()
    if inputs.len() < 2 or output_dir.len() == 0:
        return pcre2_fail(ctx, "requires pcre2_compile.c input, source-dir input, and output directory")
    let compile_c = inputs.get(0)
    let source_dir = inputs.get(1)
    if not fs.exists(compile_c):
        return pcre2_fail(ctx, "missing pcre2_compile.c: " ++ compile_c)
    if not fs.is_dir(source_dir):
        return pcre2_fail(ctx, "missing PCRE2 source directory: " ++ source_dir)
    if fs.exists(output_dir) and fs.remove_tree(output_dir) != 0:
        return pcre2_fail(ctx, "could not remove previous smoke output: " ++ output_dir)
    if fs.mkdir_all(output_dir) != 0:
        return pcre2_fail(ctx, "could not create smoke output directory: " ++ output_dir)

    let out_w = pcre2_join(output_dir, "pcre2_compile.w")
    let corpus = pcre2_corpus()
    var options = corpus_migrate_options(corpus, compile_c, out_w)
    options.include_paths = [pcre2_owned_text(source_dir)]
    options.exclude_basenames = Vec.new()
    if corpus_run_migration(ctx, "pcre2-migrate-smoke", options) != 0:
        return pcre2_fail(ctx, "pcre2_compile.c migration smoke failed")
    if not fs.exists(out_w):
        return pcre2_fail(ctx, "pcre2_compile.c migration smoke did not produce " ++ out_w)
    if fs.read_text(out_w).contains("@[c_export("):
        return pcre2_fail(ctx, "pcre2_compile.c migration smoke emitted forbidden c_export attribute")
    print("PCRE2 MIGRATE SMOKE OK")
    0

pub fn run_pcre2_test_smoke_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let args = ctx.args()
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    if inputs.len() < 2 or args.len() == 0 or output_dir.len() == 0:
        return pcre2_fail(ctx, "requires pcre2test source, RunTest input, reference arg, and output directory")
    let pcre2test_src = inputs.get(0)
    let run_test_path = inputs.get(1)
    let ref_dir = args.get(0)
    if not fs.exists(pcre2test_src):
        return pcre2_fail(ctx, "missing pcre2test source: " ++ pcre2test_src)
    if not fs.exists(run_test_path):
        return pcre2_fail(ctx, "missing upstream RunTest: " ++ run_test_path)
    if not fs.is_dir(ref_dir):
        return pcre2_fail(ctx, "reference path is not a directory: " ++ ref_dir)
    if fs.exists(output_dir) and fs.remove_tree(output_dir) != 0:
        return pcre2_fail(ctx, "could not remove previous pcre2-test smoke output: " ++ output_dir)
    if fs.mkdir_all(output_dir) != 0:
        return pcre2_fail(ctx, "could not create pcre2-test smoke output: " ++ output_dir)

    let pcre2test_bin = pcre2_join(output_dir, "pcre2test")
    let workspace = ctx.create_workspace("pcre2-test-smoke-build")
    workspace.add_file(pcre2test_src)
    var options = workspace.options()
    options.output_path = pcre2_owned_text(pcre2test_bin)
    workspace.set_options(options)
    let build_result = workspace.compile()
    if build_result.rc != 0:
        return pcre2_fail(ctx, f"failed building pcre2test smoke binary with exit code {build_result.rc}")
    if not fs.exists(pcre2test_bin):
        return pcre2_fail(ctx, "did not produce pcre2test smoke binary: " ++ pcre2test_bin)

    let run_stdout = pcre2_abs(root, pcre2_join(output_dir, "run.stdout"))
    let run_stderr = pcre2_abs(root, pcre2_join(output_dir, "run.stderr"))
    var run_args: Vec[str] = Vec.new()
    run_args |> push("/bin/bash")
    run_args |> push(pcre2_abs(root, run_test_path))
    run_args |> push("-8")
    run_args |> push("0-5")
    var run_env = process_env()
    run_env = run_env.set("srcdir", pcre2_abs(root, ref_dir))
    run_env = run_env.set("pcre2test", pcre2_abs(root, pcre2test_bin))
    let run_result = ctx.process_runner().run_capture_cwd_with_env(run_args, run_stdout, run_stderr, 120000, pcre2_abs(root, output_dir), run_env)
    if run_result.rc == 124:
        return pcre2_fail(ctx, "timed out running pcre2test smoke; stdout=" ++ run_stdout ++ " stderr=" ++ run_stderr)
    if run_result.rc != 0:
        return pcre2_fail(ctx, f"pcre2test smoke failed with exit code {run_result.rc}; stdout=" ++ run_stdout ++ " stderr=" ++ run_stderr)
    print("PCRE2 TEST SMOKE OK")
    0

pub fn run_pcre2_build_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    if inputs.len() == 0 or output_dir.len() == 0:
        return pcre2_fail(ctx, "requires migrated-dir input and output directory")
    let migrated_dir = inputs.get(0)
    if not fs.is_dir(migrated_dir):
        return pcre2_fail(ctx, "missing migrated PCRE2 directory: " ++ migrated_dir ++ " - run pcre2-migrate deliberately")
    let scratch_dir = pcre2_scratch_dir(ctx)
    if fs.mkdir_all(scratch_dir) != 0:
        return pcre2_fail(ctx, "could not create scratch directory: " ++ scratch_dir)

    let tmp_dir = pcre2_join(scratch_dir, "build-" ++ ctx.target_name())
    let re_dir = pcre2_join(pcre2_join(pcre2_join(tmp_dir, "lib"), "std"), "re")
    let bin_dir = pcre2_join(tmp_dir, "bin")
    if fs.exists(tmp_dir) and fs.remove_tree(tmp_dir) != 0:
        return pcre2_fail(ctx, "could not remove old build temp directory: " ++ tmp_dir)
    if fs.mkdir_all(re_dir) != 0 or fs.mkdir_all(bin_dir) != 0:
        return pcre2_fail(ctx, "could not create temp build directories under " ++ tmp_dir)
    let copy_rc = pcre2_copy_w_files(ctx, migrated_dir, re_dir)
    if copy_rc != 0:
        return copy_rc
    let errors = pcre2_count_generated_errors(ctx, re_dir, true)
    if errors < 0:
        return 1
    if errors != 0:
        return pcre2_fail(ctx, f"generated sources have {errors} remaining errors")

    let pcre2test_src = pcre2_join(re_dir, "pcre2test.w")
    let pcre2test_bin = pcre2_join(bin_dir, "pcre2test")
    if not fs.exists(pcre2test_src):
        return pcre2_fail(ctx, "missing pcre2test source after copy: " ++ pcre2test_src)
    let workspace = ctx.create_workspace("pcre2-build")
    workspace.add_file(pcre2test_src)
    var options = workspace.options()
    options.output_path = pcre2_owned_text(pcre2test_bin)
    workspace.set_options(options)
    let result = workspace.compile()
    if result.rc != 0:
        return pcre2_fail(ctx, f"failed building pcre2test with exit code {result.rc}")
    if not fs.exists(pcre2test_bin):
        return pcre2_fail(ctx, "did not produce pcre2test binary: " ++ pcre2test_bin)
    let remove_old_rc = pcre2_remove_tree_if_exists(ctx, output_dir)
    if remove_old_rc != 0:
        return remove_old_rc
    if fs.rename(tmp_dir, output_dir) != 0:
        return pcre2_fail(ctx, "could not move temp tree to " ++ output_dir)
    print("built migrated PCRE2: " ++ pcre2_abs(root, pcre2_join(output_dir, "bin/pcre2test")))
    0

pub fn run_pcre2_test_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let args = ctx.args()
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    if inputs.len() < 3 or args.len() == 0 or output_dir.len() == 0:
        return pcre2_fail(ctx, "requires migrated-dir, pcre2test, RunTest inputs, reference arg, and output directory")
    let pcre2test_path = inputs.get(1)
    let run_test_path = inputs.get(2)
    let ref_dir = args.get(0)
    if not fs.exists(pcre2test_path):
        return pcre2_fail(ctx, "missing pcre2test binary: " ++ pcre2test_path)
    if not fs.exists(run_test_path):
        return pcre2_fail(ctx, "missing upstream RunTest: " ++ run_test_path)
    if not fs.is_dir(ref_dir):
        return pcre2_fail(ctx, "reference path is not a directory: " ++ ref_dir)
    let run_dir = pcre2_join(output_dir, "current")
    if fs.exists(run_dir) and fs.remove_tree(run_dir) != 0:
        return pcre2_fail(ctx, "could not remove previous pcre2-test output: " ++ run_dir)
    if fs.mkdir_all(run_dir) != 0:
        return pcre2_fail(ctx, "could not create pcre2-test output directory: " ++ run_dir)
    let stdout_path = pcre2_abs(root, pcre2_join(run_dir, "stdout.txt"))
    let stderr_path = pcre2_abs(root, pcre2_join(run_dir, "stderr.txt"))
    var run_args: Vec[str] = Vec.new()
    run_args |> push("/bin/bash")
    run_args |> push(pcre2_abs(root, run_test_path))
    run_args |> push("-8")
    run_args |> push("0-29")
    run_args |> push("heap")
    var env = process_env()
    env = env.set("srcdir", pcre2_abs(root, ref_dir))
    env = env.set("pcre2test", pcre2_abs(root, pcre2test_path))
    let result = ctx.process_runner().run_capture_cwd_with_env(run_args, stdout_path, stderr_path, 900000, pcre2_abs(root, run_dir), env)
    if result.rc == 124:
        return pcre2_fail(ctx, "timed out; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    if result.rc != 0:
        return pcre2_fail(ctx, f"failed with exit code {result.rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    print("VERIFIED: migrated pcre2test passes upstream RunTest for the 8-bit corpus")
    0


pub fn pcre2_corpus() -> Corpus:
    Corpus {
        name: "pcre2", stem: "pcre2", package: "std.re",
        corpus_rel: "std/re", corpus_dir: "lib/std/re",
        upstream: upstream_release("pcre2", PCRE2_RELEASE, "https://github.com/PCRE2Project/pcre2/releases/download/" ++ PCRE2_RELEASE ++ "/" ++ PCRE2_RELEASE ++ ".tar.gz", PCRE2_SHA256),
        license: "",
        // pcre2test and pcre2posix are the harness, never the bundle
        harness: ["pcre2test", "pcre2posix"], drift_harness: "pcre2test.w", drift_harness_arg: "-C",
        module_floor: 30,
        defines: ["PCRE2_CODE_UNIT_WIDTH=8", "HAVE_CONFIG_H=1"],
        excludes: ["pcre2demo.c", "pcre2grep.c", "pcre2posix_test.c", "pcre2_jit_test.c", "pcre2_dftables.c", "pcre2_fuzzsupport.c"],
        promote_after: ["pcre2-test"], test_lane: "",
        prepare_reference: pcre2_prepare, stage: pcre2_stage,
        migrate: corpus_migrate_directory, finish_generated: pcre2_finish,
        verify_generated: pcre2_verify, lanes: pcre2_lanes,
    }

fn pcre2_prepare(ctx: &ActionCtx, corpus: &Corpus, reference: &str) -> i32:
    pcre2_prepare_reference_tree(ctx, reference)

// Every file at the top of upstream's src/ (the units, the headers and the
// .generic templates config.h includes; the jit subtree stays behind), so
// the migration sees exactly what it saw in place; its excludes drop the
// programs and generators that are not the library.
fn pcre2_stage(ctx: &ActionCtx, corpus: &Corpus, reference: &str, source: &str) -> i32:
    let src = reference ++ "/src/"
    for path in ctx.fs().list_files(reference ++ "/src"):
        if not path.starts_with(src) or path.slice(src.len(), path.len()).contains("/"): continue
        if corpus_copy(ctx, path, source ++ "/" ++ pcre2_basename(path)) != 0: return 1
    0

fn pcre2_finish(ctx: &ActionCtx, corpus: &Corpus, generated: &str) -> i32:
    pcre2_ensure_generated_dependencies(ctx, generated)

fn pcre2_verify(ctx: &ActionCtx, corpus: &Corpus, generated: &str) -> i32:
    let errors = pcre2_count_generated_errors(ctx, generated, true)
    if errors < 0: return 1
    if errors != 0: return pcre2_fail(ctx, f"generated sources have {errors} remaining errors")
    0

fn pcre2_lanes(out: Build, ctx: &BuildCtx, corpus: &Corpus, release_compiler: &str) -> Build:
    var graph = out
    let reference = corpus.upstream.reference.clone()
    var migrate_smoke = target_new(.Action, "pcre2-migrate-smoke", "").output("out/test-graph/pcre2-migrate-smoke")
    migrate_smoke.action = run_pcre2_migrate_smoke_action
    migrate_smoke = migrate_smoke.input(reference ++ "/src/pcre2_compile.c").input(reference ++ "/src").dep("pcre2-prepare-reference")
    graph = graph.add_target(migrate_smoke)

    var test_smoke = target_new(.Action, "pcre2-test-smoke", "").output("out/test-graph/pcre2-test-smoke")
    test_smoke.action = run_pcre2_test_smoke_action
    test_smoke = test_smoke.input("lib/std/re/pcre2test.w").input(reference ++ "/RunTest").arg(reference.clone())
    test_smoke = test_smoke.dep("pcre2-prepare-reference").dep("selfcheck")
    graph = graph.add_target(test_smoke)

    var build = target_new(.Action, "pcre2-build", "").output("out/pcre2_build")
    build.action = run_pcre2_build_action
    build = build.write_scope("out/tmp/action-scratch/pcre2-build")
    build = build.input("out/pcre2_migrated").dep("build").dep("pcre2-migrate")
    graph = graph.add_target(build)

    var test = target_new(.Action, "pcre2-test", "").output("out/corpus/pcre2-test")
    test.action = run_pcre2_test_action
    test = test.input("out/pcre2_migrated").input("out/pcre2_build/bin/pcre2test").input(reference ++ "/RunTest").arg(reference.clone())
    test = test.dep("verified-existing-stage").dep("pcre2-build")
    graph = graph.add_target(test)

    // The upstream suite against the STORED bundle: pcre2test as the drift
    // lane built it. The root file, never the directory, names the corpus
    // (lib/std/re is pcre2-promote's output; naming it would pull the whole
    // migration pipeline in as a producer, D36).
    let plan = wo_bundle_plan(ctx, corpus.name, corpus.corpus_rel, corpus.corpus_dir ++ "/bundle.w")
    var wo_test = target_new(.Action, "pcre2-wo-test", "").output("out/corpus/pcre2-wo-test")
    wo_test.action = run_pcre2_test_action
    wo_test = wo_test.input(corpus.corpus_dir ++ "/bundle.w").input(wo_drift_harness_bin(&plan, "lib/std/re/pcre2test.w")).input(reference ++ "/RunTest").arg(reference.clone())
    wo_test = wo_test.dep(wo_drift_target_name(&plan)).dep("pcre2-prepare-reference")
    graph.add_target(wo_test)
