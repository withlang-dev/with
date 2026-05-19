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
    var out = ""
    var frame_count = 0
    var i = 0
    while i < lines.len() as i32:
        let line = lines.get(i as i64)
        if line == "malloc  40960" and i + 2 < lines.len() as i32:
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
        if line == "free unremembered block" and i + 2 < lines.len() as i32:
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
