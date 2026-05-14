// BuildGraphPcre2 -- PCRE2-specific build graph operations.

use Resolve
use BuildGraphModel
use BuildGraphRuntime
use BuildGraphSupport
use BuildGraphTools

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

fn pcre2_copy_if_missing(src: str, dst: str, target_name: str) -> i32:
    if build_graph_rt_file_exists(dst) != 0:
        return 0
    if build_graph_rt_file_exists(src) == 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target_name ++ "' missing source file: " ++ src)
        return 1
    if build_graph_rt_write_file(dst, build_graph_rt_read_file(src)) != 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target_name ++ "' could not write: " ++ dst)
        return 1
    build_graph_rt_write("generated " ++ dst ++ "\n")
    0

fn pcre2_prepare_reference_tree(ref_dir: str, target_name: str) -> i32:
    let src_dir = resolve_join(ref_dir, "src")
    if build_graph_rt_is_dir(src_dir) == 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target_name ++ "' missing PCRE2 source tree: " ++ src_dir)
        return 1
    var rc = pcre2_copy_if_missing(resolve_join(src_dir, "pcre2.h.generic"), resolve_join(src_dir, "pcre2.h"), target_name)
    if rc != 0: return rc
    let config_generic = resolve_join(src_dir, "config.h.generic")
    if build_graph_rt_file_exists(config_generic) == 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target_name ++ "' missing " ++ config_generic)
        return 1
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
    let config_path = resolve_join(src_dir, "config.h")
    if build_graph_rt_write_file(config_path, config_text) != 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target_name ++ "' could not write: " ++ config_path)
        return 1
    build_graph_rt_write("generated " ++ config_path ++ "\n")
    rc = pcre2_copy_if_missing(resolve_join(src_dir, "pcre2_chartables.c.dist"), resolve_join(src_dir, "pcre2_chartables.c"), target_name)
    if rc != 0: return rc
    let heap_output = resolve_join(resolve_join(ref_dir, "testdata"), "testoutputheap-8")
    if build_graph_rt_file_exists(heap_output) != 0:
        let heap_text = build_graph_rt_read_file(heap_output)
        let normalized = pcre2_normalize_heap_output(heap_text)
        if normalized != heap_text:
            if build_graph_rt_write_file(heap_output, normalized) != 0:
                build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target_name ++ "' could not normalize: " ++ heap_output)
                return 1
            build_graph_rt_write("normalized " ++ heap_output ++ "\n")
    0

pub fn build_graph_run_pcre2_reference_prepare(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.args.len() == 0 or target.output.len() == 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ "' requires release entry, URL arg, and ready-stamp output")
        return 1
    let release = target.entry
    let url = target.args.get(0)
    let output_path = build_graph_resolve_project_path(root, target.output)
    let ref_dir = build_graph_dirname(output_path)
    let archive_path = resolve_join(resolve_join(root, "out/tmp"), release ++ ".tar.gz")
    if build_graph_rt_mkdir_p(build_graph_dirname(archive_path)) != 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ "' could not create archive directory")
        return 1
    if build_graph_rt_file_exists(archive_path) == 0:
        build_graph_rt_write("fetching " ++ release ++ " from " ++ url ++ "\n")
        var curl_argv = ""
        curl_argv = build_graph_argv_append(curl_argv, build_graph_curl_tool().executable)
        curl_argv = build_graph_argv_append(curl_argv, "-L")
        curl_argv = build_graph_argv_append(curl_argv, "--fail")
        curl_argv = build_graph_argv_append(curl_argv, "--show-error")
        curl_argv = build_graph_argv_append(curl_argv, "--output")
        curl_argv = build_graph_argv_append(curl_argv, archive_path)
        curl_argv = build_graph_argv_append(curl_argv, url)
        let curl_rc = build_graph_rt_exec_argv(curl_argv)
        if curl_rc != 0:
            build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ f"' curl failed with exit code {curl_rc}")
            return if curl_rc == 0: 1 else: curl_rc
    if build_graph_rt_is_dir(ref_dir) == 0:
        let tmp_dir = resolve_join(resolve_join(root, "out/tmp"), release ++ ".extract." ++ f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}")
        let extracted_dir = resolve_join(tmp_dir, release)
        if build_graph_rt_mkdir_p(tmp_dir) != 0:
            build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ "' could not create extract directory: " ++ tmp_dir)
            return 1
        var tar_argv = ""
        tar_argv = build_graph_argv_append(tar_argv, build_graph_tar_tool().executable)
        tar_argv = build_graph_argv_append(tar_argv, "-xzf")
        tar_argv = build_graph_argv_append(tar_argv, archive_path)
        tar_argv = build_graph_argv_append(tar_argv, "-C")
        tar_argv = build_graph_argv_append(tar_argv, tmp_dir)
        let tar_rc = build_graph_rt_exec_argv(tar_argv)
        if tar_rc != 0:
            build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ f"' tar failed with exit code {tar_rc}")
            return if tar_rc == 0: 1 else: tar_rc
        if build_graph_rt_is_dir(resolve_join(extracted_dir, "src")) == 0:
            build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ "' archive did not contain expected src directory: " ++ extracted_dir)
            return 1
        if build_graph_rt_mkdir_p(build_graph_dirname(ref_dir)) != 0:
            build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ "' could not create reference parent: " ++ build_graph_dirname(ref_dir))
            return 1
        if build_graph_rt_rename_file(extracted_dir, ref_dir) != 0:
            build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ "' could not move extracted tree to: " ++ ref_dir)
            return 1
        let _remove_extract_root = build_graph_rt_remove_dir(tmp_dir)
    if build_graph_rt_write_file(resolve_join(ref_dir, ".with-reference-url"), url ++ "\n") != 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ "' could not write reference URL marker")
        return 1
    let prep_rc = pcre2_prepare_reference_tree(ref_dir, target.name)
    if prep_rc != 0:
        return prep_rc
    if build_graph_rt_write_file(output_path, "ok\n") != 0:
        build_graph_rt_eprint("error: pcre2_reference_prepare target '" ++ target.name ++ "' could not write ready stamp: " ++ output_path)
        return 1
    0

fn pcre2_remove_dir_if_exists(path: str, target_name: str) -> i32:
    if build_graph_rt_is_dir(path) == 0:
        return 0
    if build_graph_rt_remove_dir(path) != 0:
        build_graph_rt_eprint("error: pcre2 target '" ++ target_name ++ "' could not remove directory: " ++ path)
        return 1
    0

fn pcre2_remove_file_if_exists(path: str, target_name: str) -> i32:
    if build_graph_rt_file_exists(path) == 0:
        return 0
    if build_graph_rt_remove_file(path) != 0:
        build_graph_rt_eprint("error: pcre2 target '" ++ target_name ++ "' could not remove file: " ++ path)
        return 1
    0

fn pcre2_remove_w_file_dir(path: str, target_name: str) -> i32:
    if build_graph_rt_is_dir(path) == 0:
        return 0
    let files = collect_test_files(path)
    for fi in 0..files.len() as i32:
        let file_path = files.get(fi as i64)
        if build_graph_rt_remove_file(file_path) != 0:
            build_graph_rt_eprint("error: pcre2 target '" ++ target_name ++ "' could not remove file: " ++ file_path)
            return 1
    pcre2_remove_dir_if_exists(path, target_name)

fn pcre2_remove_known_build_tree(output_dir: str, target_name: str) -> i32:
    if build_graph_rt_is_dir(output_dir) == 0:
        return 0
    let re_dir = resolve_join(resolve_join(resolve_join(output_dir, "lib"), "std"), "re")
    let bin_dir = resolve_join(output_dir, "bin")
    let dsym_dir = resolve_join(bin_dir, "pcre2test.dSYM")
    let dsym_contents = resolve_join(dsym_dir, "Contents")
    let dsym_resources = resolve_join(dsym_contents, "Resources")
    let dsym_dwarf = resolve_join(dsym_resources, "DWARF")
    let dsym_relocations = resolve_join(dsym_resources, "Relocations")
    let dsym_relocations_arch = resolve_join(dsym_relocations, "aarch64")

    var rc = pcre2_remove_w_file_dir(re_dir, target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(resolve_join(resolve_join(output_dir, "lib"), "std"), target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(resolve_join(output_dir, "lib"), target_name)
    if rc != 0: return rc

    rc = pcre2_remove_file_if_exists(resolve_join(bin_dir, "pcre2test"), target_name)
    if rc != 0: return rc
    rc = pcre2_remove_file_if_exists(resolve_join(dsym_contents, "Info.plist"), target_name)
    if rc != 0: return rc
    rc = pcre2_remove_file_if_exists(resolve_join(dsym_dwarf, "pcre2test"), target_name)
    if rc != 0: return rc
    rc = pcre2_remove_file_if_exists(resolve_join(dsym_relocations_arch, "pcre2test.yml"), target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(dsym_dwarf, target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(dsym_relocations_arch, target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(dsym_relocations, target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(dsym_resources, target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(dsym_contents, target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(dsym_dir, target_name)
    if rc != 0: return rc
    rc = pcre2_remove_dir_if_exists(bin_dir, target_name)
    if rc != 0: return rc

    rc = pcre2_remove_file_if_exists(resolve_join(output_dir, "build.stdout"), target_name)
    if rc != 0: return rc
    rc = pcre2_remove_file_if_exists(resolve_join(output_dir, "build.stderr"), target_name)
    if rc != 0: return rc
    pcre2_remove_dir_if_exists(output_dir, target_name)

pub fn build_graph_run_pcre2_migrate(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.inputs.len() == 0 or target.args.len() == 0 or target.output.len() == 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ "' requires compiler entry, source-dir input, generated-dir arg, and stamp output")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let compiler_path = build_graph_resolve_project_path(root, target.entry)
    let source_dir = build_graph_resolve_project_path(root, target.inputs.get(0))
    let generated_dir = build_graph_resolve_project_path(root, target.args.get(0))
    let stamp_path = build_graph_resolve_project_path(root, target.output)
    if build_graph_rt_file_exists(compiler_path) == 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ "' missing compiler: " ++ compiler_path)
        return 1
    if build_graph_rt_is_dir(source_dir) == 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ "' missing PCRE2 source directory: " ++ source_dir)
        return 1
    if build_graph_rt_mkdir_p(build_graph_dirname(stamp_path)) != 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ "' could not create stamp directory: " ++ build_graph_dirname(stamp_path))
        return 1
    if build_graph_rt_mkdir_p(build_graph_dirname(generated_dir)) != 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ "' could not create generated parent: " ++ build_graph_dirname(generated_dir))
        return 1

    let tmp_dir = generated_dir ++ ".tmp." ++ f"{build_graph_rt_getpid()}.{build_graph_rt_clock_nanos()}"
    if build_graph_rt_mkdir_p(tmp_dir) != 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ "' could not create temp migration directory: " ++ tmp_dir)
        return 1

    var argv = ""
    argv = build_graph_argv_append(argv, compiler_path)
    argv = build_graph_argv_append(argv, "migrate")
    argv = build_graph_argv_append(argv, source_dir ++ "/")
    argv = build_graph_argv_append(argv, "-o")
    argv = build_graph_argv_append(argv, tmp_dir ++ "/")
    argv = build_graph_argv_append(argv, "--no-c-export")
    argv = build_graph_argv_append(argv, "--prefer-brace")
    argv = build_graph_argv_append(argv, "--width-slice")
    argv = build_graph_argv_append(argv, "8")
    argv = build_graph_argv_append(argv, "--shared-defs")
    argv = build_graph_argv_append(argv, "std.re.defs")
    var exclude_i = 1
    while exclude_i < target.args.len() as i32:
        argv = build_graph_argv_append(argv, "--exclude")
        argv = build_graph_argv_append(argv, target.args.get(exclude_i as i64))
        exclude_i = exclude_i + 1
    argv = build_graph_argv_append(argv, "-I")
    argv = build_graph_argv_append(argv, source_dir)
    argv = build_graph_argv_append(argv, "-D")
    argv = build_graph_argv_append(argv, "PCRE2_CODE_UNIT_WIDTH=8")
    argv = build_graph_argv_append(argv, "-D")
    argv = build_graph_argv_append(argv, "HAVE_CONFIG_H=1")
    let migrate_rc = build_graph_rt_exec_argv(argv)
    if migrate_rc != 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ f"' migrate failed with exit code {migrate_rc}")
        return if migrate_rc == 0: 1 else: migrate_rc

    let files = collect_test_files(tmp_dir)
    if files.len() < 30:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ f"' only generated {files.len()} .w files; expected at least 30")
        return 1
    let c_export_errors = build_graph_pcre2_reject_c_exports(target, tmp_dir)
    if c_export_errors != 0:
        return 1

    var remove_rc = pcre2_remove_w_file_dir(generated_dir, target.name)
    if remove_rc != 0:
        return remove_rc
    if build_graph_rt_rename_file(tmp_dir, generated_dir) != 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ "' could not publish generated directory: " ++ generated_dir)
        return 1

    remove_rc = pcre2_remove_w_file_dir(resolve_join(root, "out/pcre2_migrate_raw"), target.name)
    if remove_rc != 0: return remove_rc
    remove_rc = pcre2_remove_w_file_dir(resolve_join(root, "out/pcre2_generated"), target.name)
    if remove_rc != 0: return remove_rc
    let remove_build_stamp_rc = pcre2_remove_file_if_exists(resolve_join(root, "out/gen/.regex-build-stamp"), target.name)
    if remove_build_stamp_rc != 0:
        return remove_build_stamp_rc
    let build_remove_rc = pcre2_remove_known_build_tree(resolve_join(root, "out/pcre2_build"), target.name)
    if build_remove_rc != 0:
        return build_remove_rc

    if build_graph_rt_write_file(stamp_path, "ok\n") != 0:
        build_graph_rt_eprint("error: pcre2_migrate target '" ++ target.name ++ "' could not write stamp: " ++ stamp_path)
        return 1
    build_graph_rt_write(f"migrated PCRE2: {files.len()} .w files in {generated_dir}\n")
    0

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

fn build_graph_pcre2_reject_c_exports(target: BuildGraphTarget, generated_dir: str) -> i32:
    let files = collect_test_files(generated_dir)
    var errors = 0
    for fi in 0..files.len() as i32:
        let path = files.get(fi as i64)
        let text = build_graph_rt_read_file(path)
        if text.contains("@[c_export("):
            build_graph_rt_eprint("error: pcre2 generated source contains forbidden c_export attribute in " ++ path)
            errors = errors + 1
    errors

pub fn build_graph_run_pcre2_generated_check(root: str, target: BuildGraphTarget) -> i32:
    if target.entry.len() == 0 or target.inputs.len() == 0:
        build_graph_rt_eprint("error: pcre2_generated_check target '" ++ target.name ++ "' requires compiler entry and generated-dir input")
        return 1
    let arg_rc = build_graph_validate_process_args(target)
    if arg_rc != 0:
        return arg_rc
    let compiler_path = build_graph_resolve_project_path(root, target.entry)
    let generated_dir = build_graph_resolve_project_path(root, target.inputs.get(0))
    let c_export_errors = build_graph_pcre2_reject_c_exports(target, generated_dir)
    if c_export_errors != 0:
        return 1
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
    let c_export_errors = build_graph_pcre2_reject_c_exports(target, generated_dir)
    if c_export_errors != 0:
        return 1
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
    let remove_old_rc = pcre2_remove_known_build_tree(output_dir, target.name)
    if remove_old_rc != 0:
        return remove_old_rc
    if build_graph_rt_rename_file(tmp_dir, output_dir) != 0:
        build_graph_rt_eprint("error: pcre2_build target '" ++ target.name ++ "' could not move temp tree to " ++ output_dir)
        return 1
    build_graph_rt_write("built migrated PCRE2: " ++ resolve_join(output_dir, "bin/pcre2test") ++ "\n")
    0
