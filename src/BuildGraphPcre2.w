// BuildGraphPcre2 -- PCRE2-specific build graph operations.

use Resolve
use BuildGraphModel
use BuildGraphRuntime
use BuildGraphSupport

pub fn build_graph_run_pcre2_test(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0:
        build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ "' requires a pcre2test binary")
        return 1
    if target.args.len() == 0:
        build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ "' requires a PCRE2 reference directory argument")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let pcre2test_path = build_graph_resolve_project_path(root, target.entry)
    let ref_dir = build_graph_resolve_project_path(root, target.args.get(0))
    let run_test_path = resolve_join(ref_dir, "RunTest")
    for ii in 0..target.inputs.len() as i32:
        let input_path = build_graph_resolve_project_path(root, target.inputs.get(ii as i64))
        if build_graph_rt_file_exists(input_path) == 0 and build_graph_rt_is_dir(input_path) == 0:
            build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ "' missing declared input: " ++ input_path)
            return 1
    if build_graph_rt_file_exists(pcre2test_path) == 0:
        build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ "' missing pcre2test binary: " ++ pcre2test_path)
        return 1
    if build_graph_rt_file_exists(run_test_path) == 0:
        build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ "' missing upstream RunTest: " ++ run_test_path)
        return 1
    if build_graph_rt_is_dir(ref_dir) == 0:
        build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ "' reference path is not a directory: " ++ ref_dir)
        return 1
    let stamp = f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let output_dir = if target.output.len() > 0:
        build_graph_resolve_project_path(root, target.output)
    else:
        resolve_join(resolve_join(resolve_join(root, "out/corpus"), target.name), stamp)
    if build_graph_rt_mkdir_p(output_dir) != 0:
        build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ "' could not create output directory: " ++ output_dir)
        return 1
    let stdout_path = resolve_join(output_dir, "stdout.txt")
    let stderr_path = resolve_join(output_dir, "stderr.txt")
    var argv = ""
    argv = build_graph_argv_append(argv, "/bin/bash")
    argv = build_graph_argv_append(argv, run_test_path)
    argv = build_graph_argv_append(argv, "-8")
    argv = build_graph_argv_append(argv, "0-29")
    argv = build_graph_argv_append(argv, "heap")
    let old_srcdir = build_graph_rt_getenv("srcdir")
    let old_pcre2test = build_graph_rt_getenv("pcre2test")
    let _set_srcdir = build_graph_rt_setenv("srcdir", ref_dir)
    let _set_pcre2test = build_graph_rt_setenv("pcre2test", pcre2test_path)
    let rc = build_graph_rt_exec_argv_capture_cwd(argv, stdout_path, stderr_path, 900000, output_dir)
    let _restore_srcdir = build_graph_rt_setenv("srcdir", old_srcdir)
    let _restore_pcre2test = build_graph_rt_setenv("pcre2test", old_pcre2test)
    if rc == 124:
        build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ "' timed out; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: pcre2_run_test target '" ++ target.name ++ f"' failed with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return if rc == 0: 1 else: rc
    build_graph_rt_write("VERIFIED: migrated pcre2test passes upstream RunTest for the 8-bit corpus\n")
    0

fn build_graph_insert_after_defs_import(text: str, insertion: str) -> str:
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

fn build_graph_pcre2_add_imports(path: str, sentinel: str, insertion: str) -> i32:
    if build_graph_rt_file_exists(path) == 0:
        return 0
    let text = build_graph_rt_read_file(path)
    if text.contains(sentinel):
        return 0
    let updated = build_graph_insert_after_defs_import(text, insertion)
    if updated == text:
        return 0
    build_graph_rt_write_file(path, updated)

fn build_graph_pcre2_module_name(path: str) -> str:
    let base = build_graph_path_basename(path)
    if base.ends_with(".w"):
        return base.slice(0, base.len() - 2)
    base

fn build_graph_pcre2_ensure_generated_dependencies(generated_dir: str) -> i32:
    let compile_path = resolve_join(generated_dir, "pcre2_compile.w")
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
    if build_graph_pcre2_add_imports(compile_path, "use std.re.pcre2_auto_possess", compile_imports) != 0:
        build_graph_rt_eprint("error: pcre2 generated check could not update imports in " ++ compile_path)
        return 1

    let auto_path = resolve_join(generated_dir, "pcre2_auto_possess.w")
    if build_graph_pcre2_add_imports(auto_path, "use std.re.pcre2_xclass", "use std.re.pcre2_xclass\n") != 0:
        build_graph_rt_eprint("error: pcre2 generated check could not update imports in " ++ auto_path)
        return 1

    let pcre2test_path = resolve_join(generated_dir, "pcre2test.w")
    if build_graph_rt_file_exists(pcre2test_path) == 0:
        return 0
    let pcre2test_text = build_graph_rt_read_file(pcre2test_path)
    if pcre2test_text.contains("use std.re.pcre2_context"):
        return 0
    let modules = collect_test_files(generated_dir)
    var imports = ""
    for mi in 0..modules.len() as i32:
        let mod_name = build_graph_pcre2_module_name(modules.get(mi as i64))
        if mod_name != "defs" and mod_name != "pcre2test":
            imports = imports ++ "use std.re." ++ mod_name ++ "\n"
    let updated_pcre2test = build_graph_insert_after_defs_import(pcre2test_text, imports)
    if updated_pcre2test != pcre2test_text:
        if build_graph_rt_write_file(pcre2test_path, updated_pcre2test) != 0:
            build_graph_rt_eprint("error: pcre2 generated check could not update imports in " ++ pcre2test_path)
            return 1
    0

fn build_graph_pcre2_line_starts_with_fn_main(line: str) -> bool:
    var j = 0
    while j < line.len() as i32:
        let ch = line.byte_at(j as i64)
        if ch != 32 and ch != 9:
            break
        j = j + 1
    line.slice(j as i64, line.len()).starts_with("fn main")

fn build_graph_pcre2_module_defines_main(text: str) -> bool:
    var line_start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if build_graph_pcre2_line_starts_with_fn_main(text.slice(line_start as i64, i as i64)):
                return true
            line_start = i + 1
    if line_start < text.len() as i32:
        if build_graph_pcre2_line_starts_with_fn_main(text.slice(line_start as i64, text.len())):
            return true
    false

fn build_graph_pcre2_module_body_for_synthetic_check(text: str) -> str:
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

fn build_graph_count_error_lines(text: str) -> i32:
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

fn build_graph_pcre2_count_generated_errors(root: str, target: BuildGraphTarget, compiler_path: str, generated_dir: str, print_summary: bool) -> i32:
    if build_graph_rt_file_exists(compiler_path) == 0:
        build_graph_rt_eprint("error: pcre2 generated check target '" ++ target.name ++ "' missing compiler: " ++ compiler_path)
        return -1
    if build_graph_rt_is_dir(generated_dir) == 0:
        build_graph_rt_eprint("error: pcre2 generated check target '" ++ target.name ++ "' missing generated directory: " ++ generated_dir)
        return -1
    let deps_rc = build_graph_pcre2_ensure_generated_dependencies(generated_dir)
    if deps_rc != 0:
        return -1
    let defs_path = resolve_join(generated_dir, "defs.w")
    if build_graph_rt_file_exists(defs_path) == 0:
        build_graph_rt_eprint("error: pcre2 generated check target '" ++ target.name ++ "' missing generated defs.w: " ++ defs_path)
        return -1
    let defs_text = build_graph_rt_read_file(defs_path)
    let files = collect_test_files(generated_dir)
    let tmp_dir = resolve_join(resolve_join(root, "out/tmp"), "pcre2-generated-check")
    if build_graph_rt_mkdir_p(tmp_dir) != 0:
        build_graph_rt_eprint("error: pcre2 generated check target '" ++ target.name ++ "' could not create temp directory: " ++ tmp_dir)
        return -1
    let tmp_path = resolve_join(tmp_dir, f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}.w")
    let check_out = tmp_path ++ ".out"
    var ok = 0
    var total_errors = 0
    for fi in 0..files.len() as i32:
        let path = files.get(fi as i64)
        let mod_name = build_graph_pcre2_module_name(path)
        if mod_name == "defs":
            continue
        let module_text = build_graph_rt_read_file(path)
        var synthetic = defs_text ++ build_graph_pcre2_module_body_for_synthetic_check(module_text)
        if not build_graph_pcre2_module_defines_main(module_text):
            synthetic = synthetic ++ "\nfn main { print(\"ok\") }\n"
        if build_graph_rt_write_file(tmp_path, synthetic) != 0:
            build_graph_rt_eprint("error: pcre2 generated check target '" ++ target.name ++ "' could not write temp file: " ++ tmp_path)
            return -1
        var argv = ""
        argv = build_graph_argv_append(argv, compiler_path)
        argv = build_graph_argv_append(argv, "check")
        argv = build_graph_argv_append(argv, tmp_path)
        let rc = build_graph_rt_exec_argv_capture(argv, check_out, check_out, 180000)
        if rc == 124:
            build_graph_rt_eprint("error: pcre2 generated check target '" ++ target.name ++ "' timed out checking module: " ++ mod_name)
            return -1
        let output = build_graph_rt_read_file(check_out)
        let errors = build_graph_count_error_lines(output)
        if errors == 0:
            ok = ok + 1
        else:
            build_graph_rt_write(mod_name ++ f" {errors} {module_text.len()}\n")
            total_errors = total_errors + errors
        let _remove_check_out = build_graph_rt_remove_file(check_out)
    let _remove_tmp = build_graph_rt_remove_file(tmp_path)
    if print_summary:
        build_graph_rt_write(f"OK={ok} TOTAL_ERRORS={total_errors}\n")
    total_errors

pub fn build_graph_run_pcre2_generated_check(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.inputs.len() == 0:
        build_graph_rt_eprint("error: pcre2_generated_check target '" ++ target.name ++ "' requires compiler entry and generated-dir input")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let compiler_path = build_graph_resolve_project_path(root, target.entry)
    let generated_dir = build_graph_resolve_project_path(root, target.inputs.get(0))
    let errors = build_graph_pcre2_count_generated_errors(root, target, compiler_path, generated_dir, true)
    if errors < 0:
        return 1
    if errors != 0:
        return 1
    0

pub fn build_graph_run_pcre2_generated_promote(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.inputs.len() == 0 or target.output.len() == 0:
        build_graph_rt_eprint("error: pcre2_generated_promote target '" ++ target.name ++ "' requires compiler entry, generated-dir input, and destination output")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let compiler_path = build_graph_resolve_project_path(root, target.entry)
    let generated_dir = build_graph_resolve_project_path(root, target.inputs.get(0))
    let dest_dir = build_graph_resolve_project_path(root, target.output)
    let errors = build_graph_pcre2_count_generated_errors(root, target, compiler_path, generated_dir, true)
    if errors < 0:
        return 1
    if errors != 0:
        build_graph_rt_eprint(f"error: refusing to promote generated PCRE2 with {errors} remaining errors")
        return 1
    if build_graph_rt_mkdir_p(dest_dir) != 0:
        build_graph_rt_eprint("error: pcre2_generated_promote target '" ++ target.name ++ "' could not create destination: " ++ dest_dir)
        return 1
    let existing = collect_test_files(dest_dir)
    for ei in 0..existing.len() as i32:
        let _remove_old = build_graph_rt_remove_file(existing.get(ei as i64))
    let files = collect_test_files(generated_dir)
    var copied = 0
    for fi in 0..files.len() as i32:
        let source_path = files.get(fi as i64)
        let dest_path = resolve_join(dest_dir, build_graph_path_basename(source_path))
        let contents = build_graph_rt_read_file(source_path)
        if build_graph_rt_write_file(dest_path, contents) != 0:
            build_graph_rt_eprint("error: pcre2_generated_promote target '" ++ target.name ++ "' could not copy " ++ source_path ++ " to " ++ dest_path)
            return 1
        copied = copied + 1
    build_graph_rt_write(f"promoted {copied} generated modules into {dest_dir}\n")
    0

fn build_graph_copy_w_files(source_dir: str, dest_dir: str) -> i32:
    let files = collect_test_files(source_dir)
    if files.len() == 0:
        build_graph_rt_eprint("error: no .w files found in " ++ source_dir)
        return 1
    if build_graph_rt_mkdir_p(dest_dir) != 0:
        build_graph_rt_eprint("error: could not create destination directory: " ++ dest_dir)
        return 1
    for fi in 0..files.len() as i32:
        let source_path = files.get(fi as i64)
        let dest_path = resolve_join(dest_dir, build_graph_path_basename(source_path))
        let contents = build_graph_rt_read_file(source_path)
        if build_graph_rt_write_file(dest_path, contents) != 0:
            build_graph_rt_eprint("error: could not copy " ++ source_path ++ " to " ++ dest_path)
            return 1
    0

pub fn build_graph_run_pcre2_build(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.inputs.len() == 0 or target.output.len() == 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' requires compiler entry, migrated-dir input, and output directory")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let compiler_path = build_graph_resolve_project_path(root, target.entry)
    let migrated_dir = build_graph_resolve_project_path(root, target.inputs.get(0))
    let output_dir = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_file_exists(compiler_path) == 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' missing compiler: " ++ compiler_path)
        return 1
    if build_graph_rt_is_dir(migrated_dir) == 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' missing migrated PCRE2 directory: " ++ migrated_dir ++ " - run pcre2-migrate deliberately")
        return 1
    let tmp_dir = output_dir ++ ".tmp." ++ f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    let re_dir = resolve_join(resolve_join(resolve_join(tmp_dir, "lib"), "std"), "re")
    let bin_dir = resolve_join(tmp_dir, "bin")
    let _remove_tmp = build_graph_rt_remove_dir(tmp_dir)
    if build_graph_rt_mkdir_p(re_dir) != 0 or build_graph_rt_mkdir_p(bin_dir) != 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' could not create temp build directories under " ++ tmp_dir)
        return 1
    let copy_rc = build_graph_copy_w_files(migrated_dir, re_dir)
    if copy_rc != 0:
        return copy_rc
    let errors = build_graph_pcre2_count_generated_errors(root, target, compiler_path, re_dir, true)
    if errors < 0:
        return 1
    if errors != 0:
        build_graph_rt_eprint(f"error: pcre2_build target '{target.name}' generated sources have {errors} remaining errors")
        return 1
    let pcre2test_src = resolve_join(re_dir, "pcre2test.w")
    let pcre2test_bin = resolve_join(bin_dir, "pcre2test")
    if build_graph_rt_file_exists(pcre2test_src) == 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' missing pcre2test source after copy: " ++ pcre2test_src)
        return 1
    let stdout_path = resolve_join(tmp_dir, "build.stdout")
    let stderr_path = resolve_join(tmp_dir, "build.stderr")
    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "build")
    argv = build_graph_argv_append(argv, pcre2test_src)
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, pcre2test_bin)
    let old_out_dir = build_graph_rt_getenv("WITH_OUT_DIR")
    let _set_out_dir = build_graph_rt_setenv("WITH_OUT_DIR", resolve_join(root, "out"))
    let rc = build_graph_rt_exec_argv_capture(argv, stdout_path, stderr_path, 600000)
    let _restore_out_dir = build_graph_rt_setenv("WITH_OUT_DIR", old_out_dir)
    if rc == 124:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' timed out building pcre2test; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return 124
    if rc != 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ f"' failed building pcre2test with exit code {rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
        return if rc == 0: 1 else: rc
    if build_graph_rt_file_exists(pcre2test_bin) == 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' did not produce pcre2test binary: " ++ pcre2test_bin)
        return 1
    let _remove_old = build_graph_rt_remove_dir(output_dir)
    var mv_argv = ""
    mv_argv = build_graph_argv_append(mv_argv, "/bin/mv")
    mv_argv = build_graph_argv_append(mv_argv, tmp_dir)
    mv_argv = build_graph_argv_append(mv_argv, output_dir)
    if build_graph_rt_exec_argv(mv_argv) != 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' could not move temp tree to " ++ output_dir)
        return 1
    build_graph_rt_write("built migrated PCRE2: " ++ resolve_join(output_dir, "bin/pcre2test") ++ "\n")
    0
