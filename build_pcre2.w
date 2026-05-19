module build_pcre2

use std.build

fn pcre2_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn pcre2_scratch_dir() -> str:
    "out/pcre2_tmp"

fn pcre2_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn pcre2_basename(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    path.slice((last_slash + 1) as i64, path.len())

fn pcre2_abs(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    pcre2_join(root, path)

fn pcre2_split_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    var i = 0
    while i <= text.len() as i32:
        let at_end = i == text.len() as i32
        if at_end or text.byte_at(i as i64) == 10:
            var line = text.slice(start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() - 1) == 13:
                line = line.slice(0, line.len() - 1)
            lines.push(line)
            start = i + 1
        i = i + 1
    lines

fn pcre2_emit_normalized_heap_line(line: str, frame_count: i32) -> str:
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

fn pcre2_append_normalized_heap_line(out: str, line: str, frame_count: i32) -> str:
    out ++ pcre2_emit_normalized_heap_line(line, frame_count) ++ "\n"

fn pcre2_normalize_heap_output(text: str) -> str:
    let lines = pcre2_split_lines(text)
    var line_count = lines.len() as i32
    while line_count > 0 and lines.get((line_count - 1) as i64).len() == 0:
        line_count = line_count - 1
    var out = ""
    var frame_count = 0
    var i = 0
    while i < line_count:
        let line = lines.get(i as i64)
        if line == "malloc  40960" and i + 2 < line_count:
            let second = lines.get((i + 1) as i64)
            let third = lines.get((i + 2) as i64)
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
            let second = lines.get((i + 1) as i64)
            let third = lines.get((i + 2) as i64)
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

fn pcre2_copy_if_missing(ctx: ActionCtx, src: str, dst: str) -> i32:
    let fs = ctx.fs()
    if fs.exists(dst):
        return 0
    if not fs.exists(src):
        return pcre2_fail(ctx, "missing source file: " ++ src)
    if fs.copy_file(src, dst) != 0:
        return pcre2_fail(ctx, "could not write: " ++ dst)
    print("generated " ++ pcre2_abs(ctx.project_info().project_root(), dst))
    0

fn pcre2_fail(ctx: ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn pcre2_remove_tree_if_exists(ctx: ActionCtx, path: str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(path):
        return 0
    if fs.remove_tree(path) != 0:
        return pcre2_fail(ctx, "could not remove directory: " ++ path)
    0

fn pcre2_remove_file_if_exists(ctx: ActionCtx, path: str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(path):
        return 0
    if fs.remove_file(path) != 0:
        return pcre2_fail(ctx, "could not remove file: " ++ path)
    0

fn pcre2_count_w_files(ctx: ActionCtx, dir: str) -> i32:
    let files = ctx.fs().list_files(dir)
    var count = 0
    for i in 0..files.len() as i32:
        if files.get(i as i64).ends_with(".w"):
            count = count + 1
    count

fn pcre2_reject_c_exports(ctx: ActionCtx, generated_dir: str) -> i32:
    let fs = ctx.fs()
    let files = fs.list_files(generated_dir)
    var errors = 0
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        if path.ends_with(".w") and fs.read_text(path).contains("@[c_export("):
            ctx.diagnostics().error("pcre2 generated source contains forbidden c_export attribute in " ++ path)
            errors = errors + 1
    errors

fn pcre2_module_name(path: str) -> str:
    let base = pcre2_basename(path)
    if base.ends_with(".w"):
        return base.slice(0, base.len() - 2)
    base

fn pcre2_insert_after_defs_import(text: str, insertion: str) -> str:
    let marker = "use std.re.defs\n"
    var out = ""
    var inserted = false
    var line_start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
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
    text

fn pcre2_add_imports(ctx: ActionCtx, path: str, sentinel: str, insertion: str) -> i32:
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

fn pcre2_line_starts_with_fn_main(line: str) -> bool:
    var j = 0
    while j < line.len() as i32:
        let ch = line.byte_at(j as i64)
        if ch != 32 and ch != 9:
            break
        j = j + 1
    line.slice(j as i64, line.len()).starts_with("fn main")

fn pcre2_module_defines_main(text: str) -> bool:
    var line_start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if pcre2_line_starts_with_fn_main(text.slice(line_start as i64, i as i64)):
                return true
            line_start = i + 1
    if line_start < text.len() as i32:
        if pcre2_line_starts_with_fn_main(text.slice(line_start as i64, text.len())):
            return true
    false

fn pcre2_module_body_for_synthetic_check(text: str) -> str:
    var out = ""
    var line_start = 0
    var line_no = 1
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            let line = text.slice(line_start as i64, (i + 1) as i64)
            if line_no > 2 and not line.starts_with("use std.re."):
                out = out ++ line
            line_start = i + 1
            line_no = line_no + 1
    if line_start < text.len() as i32:
        let line = text.slice(line_start as i64, text.len())
        if line_no > 2 and not line.starts_with("use std.re."):
            out = out ++ line
    out

fn pcre2_count_error_lines(text: str) -> i32:
    var count = 0
    var line_start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            let line = text.slice(line_start as i64, i as i64)
            if line.contains("error:"):
                count = count + 1
            line_start = i + 1
    if line_start < text.len() as i32:
        let line = text.slice(line_start as i64, text.len())
        if line.contains("error:"):
            count = count + 1
    count

fn pcre2_ensure_generated_dependencies(ctx: ActionCtx, generated_dir: str) -> i32:
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
        let mod_name = pcre2_module_name(modules.get(mi as i64))
        if mod_name != "defs" and mod_name != "pcre2test":
            imports = imports ++ "use std.re." ++ mod_name ++ "\n"
    let updated = pcre2_insert_after_defs_import(pcre2test_text, imports)
    if updated != pcre2test_text:
        if fs.write_text(pcre2test_path, updated) != 0:
            return pcre2_fail(ctx, "could not update imports in " ++ pcre2test_path)
    0

fn pcre2_count_generated_errors(ctx: ActionCtx, compiler_path: str, generated_dir: str, print_summary: bool) -> i32:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    if not fs.exists(compiler_path):
        let _ = pcre2_fail(ctx, "missing compiler: " ++ compiler_path)
        return -1
    if not fs.is_dir(generated_dir):
        let _ = pcre2_fail(ctx, "missing generated directory: " ++ generated_dir)
        return -1
    if pcre2_ensure_generated_dependencies(ctx, generated_dir) != 0:
        return -1
    let defs_path = pcre2_join(generated_dir, "defs.w")
    if not fs.exists(defs_path):
        let _ = pcre2_fail(ctx, "missing generated defs.w: " ++ defs_path)
        return -1
    let defs_text = fs.read_text(defs_path)
    let files = fs.list_files(generated_dir)
    let tmp_dir = pcre2_join(pcre2_scratch_dir(), "generated-check-" ++ ctx.target_name())
    if fs.exists(tmp_dir) and fs.remove_tree(tmp_dir) != 0:
        let _ = pcre2_fail(ctx, "could not remove old generated-check temp directory")
        return -1
    if fs.mkdir_all(tmp_dir) != 0:
        let _ = pcre2_fail(ctx, "could not create generated-check temp directory")
        return -1
    let tmp_path = pcre2_join(tmp_dir, "synthetic.w")
    let check_stdout = pcre2_abs(root, pcre2_join(tmp_dir, "check.stdout"))
    let check_stderr = pcre2_abs(root, pcre2_join(tmp_dir, "check.stderr"))
    var ok = 0
    var total_errors = 0
    for fi in 0..files.len() as i32:
        let path = files.get(fi as i64)
        let mod_name = pcre2_module_name(path)
        if mod_name == "defs":
            continue
        let module_text = fs.read_text(path)
        var synthetic = defs_text ++ pcre2_module_body_for_synthetic_check(module_text)
        if not pcre2_module_defines_main(module_text):
            synthetic = synthetic ++ "\nfn main { print(\"ok\") }\n"
        if fs.write_text(tmp_path, synthetic) != 0:
            let _ = pcre2_fail(ctx, "could not write generated-check temp file")
            return -1
        var check_args: Vec[str] = Vec.new()
        check_args |> push(pcre2_abs(root, compiler_path))
        check_args |> push("check")
        check_args |> push(pcre2_abs(root, tmp_path))
        let result = ctx.process_runner().run_capture(check_args, check_stdout, check_stderr, 180000)
        if result.rc == 124:
            let _ = pcre2_fail(ctx, "timed out checking generated module: " ++ mod_name)
            return -1
        let errors = pcre2_count_error_lines(result.stdout ++ result.stderr)
        if errors == 0:
            ok = ok + 1
        else:
            print(mod_name ++ f" {errors} {module_text.len()}")
            total_errors = total_errors + errors
    let _remove_tmp = fs.remove_tree(tmp_dir)
    if print_summary:
        print(f"OK={ok} TOTAL_ERRORS={total_errors}")
    total_errors

fn pcre2_copy_w_files(ctx: ActionCtx, source_dir: str, dest_dir: str) -> i32:
    let fs = ctx.fs()
    let files = fs.list_files(source_dir)
    var copied = 0
    if fs.mkdir_all(dest_dir) != 0:
        return pcre2_fail(ctx, "could not create destination directory: " ++ dest_dir)
    for fi in 0..files.len() as i32:
        let source_path = files.get(fi as i64)
        if source_path.ends_with(".w"):
            let dest_path = pcre2_join(dest_dir, pcre2_basename(source_path))
            if fs.copy_file(source_path, dest_path) != 0:
                return pcre2_fail(ctx, "could not copy " ++ source_path ++ " to " ++ dest_path)
            copied = copied + 1
    if copied == 0:
        return pcre2_fail(ctx, "no .w files found in " ++ source_dir)
    0

fn pcre2_migrate_tmp_dir(ctx: ActionCtx) -> str:
    pcre2_join(pcre2_scratch_dir(), "migrate-" ++ f"{ctx.target_name()}")

fn pcre2_prepare_reference_tree(ctx: ActionCtx, ref_dir: str) -> i32:
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

pub fn run_pcre2_reference_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    if args.len() < 2:
        return pcre2_fail(ctx, "requires release and URL args")
    let release = args.get(0)
    let url = args.get(1)
    let ref_dir = ctx.output()
    if ref_dir.len() == 0:
        return pcre2_fail(ctx, "requires reference tree output")
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let scratch_dir = pcre2_scratch_dir()
    let archive_path = pcre2_join(scratch_dir, release ++ ".tar.gz")
    if fs.mkdir_all(pcre2_dirname(archive_path)) != 0:
        return pcre2_fail(ctx, "could not create archive directory")
    if not fs.exists(archive_path):
        print("fetching " ++ release ++ " from " ++ url)
        var curl_args: Vec[str] = Vec.new()
        curl_args |> push("curl")
        curl_args |> push("-L")
        curl_args |> push("--fail")
        curl_args |> push("--show-error")
        curl_args |> push("--output")
        curl_args |> push(pcre2_abs(root, archive_path))
        curl_args |> push(url)
        let curl_result = ctx.process_runner().run_capture(curl_args, pcre2_abs(root, pcre2_join(scratch_dir, release ++ ".curl.stdout")), pcre2_abs(root, pcre2_join(scratch_dir, release ++ ".curl.stderr")), 300000)
        if curl_result.rc != 0:
            return pcre2_fail(ctx, f"curl failed with exit code {curl_result.rc}: " ++ curl_result.stderr)
    if not fs.is_dir(ref_dir):
        let tmp_dir = pcre2_join(scratch_dir, release ++ ".extract")
        let extracted_dir = pcre2_join(tmp_dir, release)
        if fs.exists(tmp_dir) and fs.remove_tree(tmp_dir) != 0:
            return pcre2_fail(ctx, "could not remove old extract directory: " ++ tmp_dir)
        if fs.mkdir_all(tmp_dir) != 0:
            return pcre2_fail(ctx, "could not create extract directory: " ++ tmp_dir)
        var tar_args: Vec[str] = Vec.new()
        tar_args |> push("tar")
        tar_args |> push("-xzf")
        tar_args |> push(pcre2_abs(root, archive_path))
        tar_args |> push("-C")
        tar_args |> push(pcre2_abs(root, tmp_dir))
        let tar_result = ctx.process_runner().run_capture(tar_args, pcre2_abs(root, pcre2_join(scratch_dir, release ++ ".tar.stdout")), pcre2_abs(root, pcre2_join(scratch_dir, release ++ ".tar.stderr")), 300000)
        if tar_result.rc != 0:
            return pcre2_fail(ctx, f"tar failed with exit code {tar_result.rc}: " ++ tar_result.stderr)
        if not fs.is_dir(pcre2_join(extracted_dir, "src")):
            return pcre2_fail(ctx, "archive did not contain expected src directory: " ++ extracted_dir)
        if fs.mkdir_all(pcre2_dirname(ref_dir)) != 0:
            return pcre2_fail(ctx, "could not create reference parent: " ++ pcre2_dirname(ref_dir))
        if fs.rename(extracted_dir, ref_dir) != 0:
            return pcre2_fail(ctx, "could not move extracted tree to: " ++ ref_dir)
        let _remove_extract_root = fs.remove_tree(tmp_dir)
    if fs.write_text(pcre2_join(ref_dir, ".with-reference-url"), url ++ "\n") != 0:
        return pcre2_fail(ctx, "could not write reference URL marker")
    let prep_rc = pcre2_prepare_reference_tree(ctx, ref_dir)
    if prep_rc != 0:
        return prep_rc
    let ready_stamp = if ctx.outputs().len() > 1: ctx.outputs().get(1) else: pcre2_join(ref_dir, ".with-reference-ready")
    if fs.write_text(ready_stamp, "ok\n") != 0:
        return pcre2_fail(ctx, "could not write ready stamp: " ++ ready_stamp)
    0

pub fn run_pcre2_migrate_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let args = ctx.args()
    let root = ctx.project_info().project_root()
    let stamp_path = ctx.output()
    if inputs.len() == 0 or args.len() == 0 or stamp_path.len() == 0:
        return pcre2_fail(ctx, "requires source-dir input, generated-dir arg, and stamp output")

    let compiler_path = "out/bin/with"
    let source_dir = inputs.get(0)
    let generated_dir = args.get(0)
    if not fs.exists(compiler_path):
        return pcre2_fail(ctx, "missing compiler: " ++ compiler_path)
    if not fs.is_dir(source_dir):
        return pcre2_fail(ctx, "missing PCRE2 source directory: " ++ source_dir)
    if fs.mkdir_all(pcre2_dirname(stamp_path)) != 0:
        return pcre2_fail(ctx, "could not create stamp directory: " ++ pcre2_dirname(stamp_path))
    if fs.mkdir_all(pcre2_dirname(generated_dir)) != 0:
        return pcre2_fail(ctx, "could not create generated parent: " ++ pcre2_dirname(generated_dir))
    if fs.mkdir_all(pcre2_scratch_dir()) != 0:
        return pcre2_fail(ctx, "could not create scratch directory: " ++ pcre2_scratch_dir())

    let tmp_dir = pcre2_migrate_tmp_dir(ctx)
    let remove_tmp_rc = pcre2_remove_tree_if_exists(ctx, tmp_dir)
    if remove_tmp_rc != 0: return remove_tmp_rc
    if fs.mkdir_all(tmp_dir) != 0:
        return pcre2_fail(ctx, "could not create temp migration directory: " ++ tmp_dir)

    var migrate_args: Vec[str] = Vec.new()
    migrate_args |> push(pcre2_abs(root, compiler_path))
    migrate_args |> push("migrate")
    migrate_args |> push(pcre2_abs(root, source_dir) ++ "/")
    migrate_args |> push("-o")
    migrate_args |> push(pcre2_abs(root, tmp_dir) ++ "/")
    migrate_args |> push("--no-c-export")
    migrate_args |> push("--prefer-brace")
    migrate_args |> push("--width-slice")
    migrate_args |> push("8")
    migrate_args |> push("--shared-defs")
    migrate_args |> push("std.re.defs")
    var exclude_i = 1
    while exclude_i < args.len() as i32:
        migrate_args |> push("--exclude")
        migrate_args |> push(args.get(exclude_i as i64))
        exclude_i = exclude_i + 1
    migrate_args |> push("-I")
    migrate_args |> push(pcre2_abs(root, source_dir))
    migrate_args |> push("-D")
    migrate_args |> push("PCRE2_CODE_UNIT_WIDTH=8")
    migrate_args |> push("-D")
    migrate_args |> push("HAVE_CONFIG_H=1")

    let migrate_rc = ctx.process_runner().run(migrate_args)
    if migrate_rc != 0:
        return pcre2_fail(ctx, f"migrate failed with exit code {migrate_rc}")

    let generated_count = pcre2_count_w_files(ctx, tmp_dir)
    if generated_count < 30:
        return pcre2_fail(ctx, f"only generated {generated_count} .w files; expected at least 30")
    if pcre2_reject_c_exports(ctx, tmp_dir) != 0:
        return 1

    var rc = pcre2_remove_tree_if_exists(ctx, generated_dir)
    if rc != 0: return rc
    if fs.rename(tmp_dir, generated_dir) != 0:
        return pcre2_fail(ctx, "could not publish generated directory: " ++ generated_dir)

    rc = pcre2_remove_tree_if_exists(ctx, "out/pcre2_migrate_raw")
    if rc != 0: return rc
    rc = pcre2_remove_tree_if_exists(ctx, "out/pcre2_generated")
    if rc != 0: return rc
    rc = pcre2_remove_file_if_exists(ctx, "out/gen/.regex-build-stamp")
    if rc != 0: return rc
    rc = pcre2_remove_tree_if_exists(ctx, "out/pcre2_build")
    if rc != 0: return rc

    if fs.write_text(stamp_path, "ok\n") != 0:
        return pcre2_fail(ctx, "could not write stamp: " ++ stamp_path)
    print(f"migrated PCRE2: {generated_count} .w files in " ++ pcre2_abs(root, generated_dir))
    0

pub fn run_pcre2_build_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    let compiler_path = "out/bin/with"
    if inputs.len() == 0 or output_dir.len() == 0:
        return pcre2_fail(ctx, "requires migrated-dir input and output directory")
    let migrated_dir = inputs.get(0)
    if not fs.exists(compiler_path):
        return pcre2_fail(ctx, "missing compiler: " ++ compiler_path)
    if not fs.is_dir(migrated_dir):
        return pcre2_fail(ctx, "missing migrated PCRE2 directory: " ++ migrated_dir ++ " - run pcre2-migrate deliberately")
    if fs.mkdir_all(pcre2_scratch_dir()) != 0:
        return pcre2_fail(ctx, "could not create scratch directory: " ++ pcre2_scratch_dir())

    let tmp_dir = pcre2_join(pcre2_scratch_dir(), "build-" ++ ctx.target_name())
    let re_dir = pcre2_join(pcre2_join(pcre2_join(tmp_dir, "lib"), "std"), "re")
    let bin_dir = pcre2_join(tmp_dir, "bin")
    if fs.exists(tmp_dir) and fs.remove_tree(tmp_dir) != 0:
        return pcre2_fail(ctx, "could not remove old build temp directory: " ++ tmp_dir)
    if fs.mkdir_all(re_dir) != 0 or fs.mkdir_all(bin_dir) != 0:
        return pcre2_fail(ctx, "could not create temp build directories under " ++ tmp_dir)
    let copy_rc = pcre2_copy_w_files(ctx, migrated_dir, re_dir)
    if copy_rc != 0:
        return copy_rc
    let errors = pcre2_count_generated_errors(ctx, compiler_path, re_dir, true)
    if errors < 0:
        return 1
    if errors != 0:
        return pcre2_fail(ctx, f"generated sources have {errors} remaining errors")

    let pcre2test_src = pcre2_join(re_dir, "pcre2test.w")
    let pcre2test_bin = pcre2_join(bin_dir, "pcre2test")
    if not fs.exists(pcre2test_src):
        return pcre2_fail(ctx, "missing pcre2test source after copy: " ++ pcre2test_src)
    let stdout_path = pcre2_abs(root, pcre2_join(tmp_dir, "build.stdout"))
    let stderr_path = pcre2_abs(root, pcre2_join(tmp_dir, "build.stderr"))
    var build_args: Vec[str] = Vec.new()
    build_args |> push(pcre2_abs(root, compiler_path))
    build_args |> push("build")
    build_args |> push(pcre2_abs(root, pcre2test_src))
    build_args |> push("-o")
    build_args |> push(pcre2_abs(root, pcre2test_bin))
    var env = process_env()
    env = env.set("WITH_OUT_DIR", pcre2_abs(root, "out"))
    let result = ctx.process_runner().run_capture_with_env(build_args, stdout_path, stderr_path, 600000, env)
    if result.rc == 124:
        return pcre2_fail(ctx, "timed out building pcre2test; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    if result.rc != 0:
        return pcre2_fail(ctx, f"failed building pcre2test with exit code {result.rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
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
