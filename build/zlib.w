module build.zlib

use std.build

const ZLIB_RELEASE: str = "zlib-1.3.2"
const ZLIB_SHA256: str = "bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16"

fn zlib_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn zlib_safe_label(text: str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        let keep = (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 45 or ch == 46 or ch == 95
        if keep:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
        else:
            out = out ++ "_"
    if out.len() == 0:
        return "unknown"
    out

fn zlib_scratch_dir(ctx: &ActionCtx) -> str:
    "out/tmp/action-scratch/" ++ zlib_safe_label(ctx.target_name())

fn zlib_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn zlib_basename(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    path.slice((last_slash + 1) as i64, path.len())

fn zlib_abs(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    zlib_join(root, path)

fn zlib_fail(ctx: &ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn zlib_remove_tree_if_exists(ctx: &ActionCtx, path: str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(path):
        return 0
    if fs.remove_tree(path) != 0:
        return zlib_fail(ctx, "could not remove directory: " ++ path)
    0

fn zlib_remove_file_if_exists(ctx: &ActionCtx, path: str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(path):
        return 0
    if fs.remove_file(path) != 0:
        return zlib_fail(ctx, "could not remove file: " ++ path)
    0

fn zlib_copy_file(ctx: &ActionCtx, src: str, dst: str) -> i32:
    let fs = ctx.fs()
    if not fs.exists(src):
        return zlib_fail(ctx, "missing source file: " ++ src)
    if fs.mkdir_all(zlib_dirname(dst)) != 0:
        return zlib_fail(ctx, "could not create directory: " ++ zlib_dirname(dst))
    if fs.copy_file(src, dst) != 0:
        return zlib_fail(ctx, "could not copy " ++ src ++ " to " ++ dst)
    0

fn zlib_copy_w_files(ctx: &ActionCtx, source_dir: str, dest_dir: str) -> i32:
    let fs = ctx.fs()
    let files = fs.list_files(source_dir)
    var copied = 0
    if fs.mkdir_all(dest_dir) != 0:
        return zlib_fail(ctx, "could not create destination directory: " ++ dest_dir)
    for fi in 0..files.len() as i32:
        let source_path = files.get(fi as i64)
        if source_path.ends_with(".w"):
            let dest_path = zlib_join(dest_dir, zlib_basename(source_path))
            if fs.copy_file(source_path, dest_path) != 0:
                return zlib_fail(ctx, "could not copy " ++ source_path ++ " to " ++ dest_path)
            copied = copied + 1
    if copied == 0:
        return zlib_fail(ctx, "no .w files found in " ++ source_dir)
    0

fn zlib_sha256_file(ctx: &ActionCtx, path: str) -> str:
    let root = ctx.project_info().project_root()
    let scratch_dir = zlib_scratch_dir(ctx)
    let label = zlib_safe_label(zlib_basename(path))
    let stdout_path = zlib_abs(root, zlib_join(scratch_dir, label ++ ".sha256.stdout"))
    let stderr_path = zlib_abs(root, zlib_join(scratch_dir, label ++ ".sha256.stderr"))
    var args: Vec[str] = Vec.new()
    args.push("shasum")
    args.push("-a")
    args.push("256")
    args.push(zlib_abs(root, path))
    let result = ctx.process_runner().run_capture(args, stdout_path, stderr_path, 120000)
    if result.rc != 0:
        return ""
    if result.stdout.len() < 64:
        return ""
    result.stdout.slice(0, 64)

fn zlib_source_files() -> Vec[str]:
    let files: Vec[str] = Vec.new()
    files.push("adler32.c")
    files.push("compress.c")
    files.push("crc32.c")
    files.push("crc32.h")
    files.push("deflate.c")
    files.push("deflate.h")
    files.push("gzclose.c")
    files.push("gzguts.h")
    files.push("gzlib.c")
    files.push("gzread.c")
    files.push("gzwrite.c")
    files.push("infback.c")
    files.push("inffast.c")
    files.push("inffast.h")
    files.push("inffixed.h")
    files.push("inflate.c")
    files.push("inflate.h")
    files.push("inftrees.c")
    files.push("inftrees.h")
    files.push("trees.c")
    files.push("trees.h")
    files.push("uncompr.c")
    files.push("zconf.h")
    files.push("zlib.h")
    files.push("zutil.c")
    files.push("zutil.h")
    files

fn zlib_prepare_migration_source(ctx: &ActionCtx, ref_dir: str, out_dir: str) -> i32:
    let fs = ctx.fs()
    var rc = zlib_remove_tree_if_exists(ctx, out_dir)
    if rc != 0: return rc
    if fs.mkdir_all(out_dir) != 0:
        return zlib_fail(ctx, "could not create zlib migrate source directory: " ++ out_dir)
    let files = zlib_source_files()
    for i in 0..files.len() as i32:
        let rel = files.get(i as i64)
        rc = zlib_copy_file(ctx, zlib_join(ref_dir, rel), zlib_join(out_dir, rel))
        if rc != 0: return rc
    0

fn zlib_migrate_options(source_path: str, output_path: str, source_dir: str) -> MigrateOptions:
    let include_paths: Vec[str] = Vec.new()
    include_paths.push(source_dir)
    let forced_includes: Vec[str] = Vec.new()
    let defines: Vec[str] = Vec.new()
    MigrateOptions {
        source_path,
        output_path,
        include_paths,
        forced_includes,
        defines,
        exclude_basenames: Vec.new(),
        check_mode: false,
        diff_mode: false,
        stats_mode: false,
        no_c_export: true,
        c_export_functions: false,
        convert_goto_to_structured: false,
        block_style: 2,
        width_slice: 8,
        shared_defs: "std.zlib.defs",
        migrate_one: "",
        shared_fragment: "",
        ir_roundtrip: false,
    }

fn zlib_migrate_one_options(source_dir: str, output_dir: str, basename: str, shared_fragment: str) -> MigrateOptions:
    var options = zlib_migrate_options(source_dir, output_dir, source_dir)
    options.migrate_one = basename
    options.shared_fragment = shared_fragment
    options

fn zlib_migrate_file(ctx: &ActionCtx, workspace_name: str, source_path: str, output_path: str, source_dir: str) -> i32:
    let workspace = ctx.create_workspace(workspace_name)
    workspace.set_migrate_options(zlib_migrate_options(source_path, output_path, source_dir))
    let result = workspace.compile()
    if result.rc != 0:
        return zlib_fail(ctx, workspace_name ++ f" failed with exit code {result.rc}")
    if not ctx.fs().exists(output_path):
        return zlib_fail(ctx, workspace_name ++ " did not produce " ++ output_path)
    0

fn zlib_migrate_one_file(ctx: &ActionCtx, workspace_name: str, source_dir: str, output_dir: str, basename: str, output_path: str) -> i32:
    let workspace = ctx.create_workspace(workspace_name)
    let fragment_path = zlib_join(zlib_scratch_dir(ctx), workspace_name ++ ".shared-fragment")
    workspace.set_migrate_options(zlib_migrate_one_options(source_dir, output_dir, basename, fragment_path))
    let result = workspace.compile()
    if result.rc != 0:
        return zlib_fail(ctx, workspace_name ++ f" failed with exit code {result.rc}")
    if not ctx.fs().exists(output_path):
        return zlib_fail(ctx, workspace_name ++ " did not produce " ++ output_path)
    0

fn zlib_count_w_files(ctx: &ActionCtx, dir: str) -> i32:
    let files = ctx.fs().list_files(dir)
    var count = 0
    for i in 0..files.len() as i32:
        if files.get(i as i64).ends_with(".w"):
            count = count + 1
    count

fn zlib_reject_c_exports(ctx: &ActionCtx, generated_dir: str) -> i32:
    let fs = ctx.fs()
    let files = fs.list_files(generated_dir)
    var errors = 0
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        if path.ends_with(".w"):
            let text = fs.read_text(path)
            if text.contains("@[c_export("):
                ctx.diagnostics().error("zlib generated source contains forbidden c_export attribute in " ++ path)
                errors = errors + 1
            if text.contains("// Bail:") or text.contains("[MIGRATOR_UNTRANSLATED]"):
                ctx.diagnostics().error("zlib generated source contains untranslatable migrator output in " ++ path)
                errors = errors + 1
    errors

fn zlib_compile_binary(ctx: &ActionCtx, workspace_name: str, source_path: str, output_path: str) -> i32:
    let workspace = ctx.create_workspace(workspace_name)
    workspace.add_file(source_path)
    var options = workspace.options()
    options.output_path = output_path
    workspace.set_options(options)
    let result = workspace.compile()
    if result.rc != 0:
        return zlib_fail(ctx, workspace_name ++ f" failed with exit code {result.rc}")
    if not ctx.fs().exists(output_path):
        return zlib_fail(ctx, workspace_name ++ " did not produce " ++ output_path)
    0

pub fn run_zlib_reference_action(ctx: ActionCtx) -> i32:
    let args = ctx.args()
    let ref_dir = ctx.output()
    if args.len() < 2 or ref_dir.len() == 0:
        return zlib_fail(ctx, "requires release and URL args plus reference tree output")
    let release = args.get(0)
    let url = args.get(1)
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let scratch_dir = zlib_scratch_dir(ctx)
    let archive_path = zlib_join(scratch_dir, release ++ ".tar.gz")
    if fs.mkdir_all(zlib_dirname(archive_path)) != 0:
        return zlib_fail(ctx, "could not create archive directory")
    if not fs.exists(archive_path):
        print("fetching " ++ release ++ " from " ++ url)
        var curl_args: Vec[str] = Vec.new()
        curl_args.push("curl")
        curl_args.push("-L")
        curl_args.push("--fail")
        curl_args.push("--show-error")
        curl_args.push("--output")
        curl_args.push(zlib_abs(root, archive_path))
        curl_args.push(url)
        let curl_result = ctx.process_runner().run_capture(curl_args, zlib_abs(root, zlib_join(scratch_dir, release ++ ".curl.stdout")), zlib_abs(root, zlib_join(scratch_dir, release ++ ".curl.stderr")), 300000)
        if curl_result.rc != 0:
            return zlib_fail(ctx, f"curl failed with exit code {curl_result.rc}: " ++ curl_result.stderr)
    let actual_sha = zlib_sha256_file(ctx, archive_path)
    if actual_sha != ZLIB_SHA256:
        return zlib_fail(ctx, "sha256 mismatch for " ++ archive_path ++ ": expected " ++ ZLIB_SHA256 ++ " got " ++ actual_sha)
    if not fs.is_dir(ref_dir):
        let tmp_dir = zlib_join(scratch_dir, release ++ ".extract")
        let extracted_dir = zlib_join(tmp_dir, release)
        if fs.exists(tmp_dir) and fs.remove_tree(tmp_dir) != 0:
            return zlib_fail(ctx, "could not remove old extract directory: " ++ tmp_dir)
        if fs.mkdir_all(tmp_dir) != 0:
            return zlib_fail(ctx, "could not create extract directory: " ++ tmp_dir)
        var tar_args: Vec[str] = Vec.new()
        tar_args.push("tar")
        tar_args.push("-xzf")
        tar_args.push(zlib_abs(root, archive_path))
        tar_args.push("-C")
        tar_args.push(zlib_abs(root, tmp_dir))
        let tar_result = ctx.process_runner().run_capture(tar_args, zlib_abs(root, zlib_join(scratch_dir, release ++ ".tar.stdout")), zlib_abs(root, zlib_join(scratch_dir, release ++ ".tar.stderr")), 300000)
        if tar_result.rc != 0:
            return zlib_fail(ctx, f"tar failed with exit code {tar_result.rc}: " ++ tar_result.stderr)
        if not fs.exists(zlib_join(extracted_dir, "zlib.h")):
            return zlib_fail(ctx, "archive did not contain expected zlib.h: " ++ extracted_dir)
        if fs.mkdir_all(zlib_dirname(ref_dir)) != 0:
            return zlib_fail(ctx, "could not create reference parent: " ++ zlib_dirname(ref_dir))
        if fs.rename(extracted_dir, ref_dir) != 0:
            return zlib_fail(ctx, "could not move extracted tree to: " ++ ref_dir)
        let _remove_extract_root = fs.remove_tree(tmp_dir)
    if fs.write_text(zlib_join(ref_dir, ".with-reference-url"), url ++ "\n") != 0:
        return zlib_fail(ctx, "could not write reference URL marker")
    let ready_stamp = if ctx.outputs().len() > 1: ctx.outputs().get(1) else: zlib_join(ref_dir, ".with-reference-ready")
    if fs.write_text(ready_stamp, "ok\n") != 0:
        return zlib_fail(ctx, "could not write ready stamp: " ++ ready_stamp)
    0

pub fn run_zlib_migrate_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let args = ctx.args()
    let root = ctx.project_info().project_root()
    let stamp_path = ctx.output()
    if inputs.len() == 0 or args.len() == 0 or stamp_path.len() == 0:
        return zlib_fail(ctx, "requires reference-tree input, generated-dir arg, and stamp output")
    let ref_dir = inputs.get(0)
    let generated_dir = args.get(0)
    if not fs.is_dir(ref_dir):
        return zlib_fail(ctx, "missing zlib reference directory: " ++ ref_dir)
    let source_dir = zlib_join(zlib_scratch_dir(ctx), "source")
    var rc = zlib_prepare_migration_source(ctx, ref_dir, source_dir)
    if rc != 0: return rc
    let tmp_dir = zlib_join(zlib_scratch_dir(ctx), "generated")
    rc = zlib_remove_tree_if_exists(ctx, tmp_dir)
    if rc != 0: return rc
    if fs.mkdir_all(zlib_dirname(tmp_dir)) != 0:
        return zlib_fail(ctx, "could not create generated parent: " ++ zlib_dirname(tmp_dir))
    let workspace = ctx.create_workspace("zlib-migrate")
    workspace.set_migrate_options(zlib_migrate_options(source_dir, tmp_dir, source_dir))
    let migrate_result = workspace.compile()
    if migrate_result.rc != 0:
        return zlib_fail(ctx, f"migrate failed with exit code {migrate_result.rc}")
    rc = zlib_copy_file(ctx, zlib_join(ref_dir, "test/example.c"), zlib_join(source_dir, "example.c"))
    if rc != 0: return rc
    rc = zlib_migrate_one_file(ctx, "zlib-migrate-example", source_dir, tmp_dir, "example.c", zlib_join(tmp_dir, "example.w"))
    if rc != 0: return rc
    rc = zlib_remove_file_if_exists(ctx, zlib_join(source_dir, "example.c"))
    if rc != 0: return rc
    rc = zlib_copy_file(ctx, zlib_join(ref_dir, "test/minigzip.c"), zlib_join(source_dir, "minigzip.c"))
    if rc != 0: return rc
    rc = zlib_migrate_one_file(ctx, "zlib-migrate-minigzip", source_dir, tmp_dir, "minigzip.c", zlib_join(tmp_dir, "minigzip.w"))
    if rc != 0: return rc
    let generated_count = zlib_count_w_files(ctx, tmp_dir)
    if generated_count < 18:
        return zlib_fail(ctx, f"only generated {generated_count} .w files; expected at least 18")
    if zlib_reject_c_exports(ctx, tmp_dir) != 0:
        return 1
    rc = zlib_remove_tree_if_exists(ctx, generated_dir)
    if rc != 0: return rc
    if fs.rename(tmp_dir, generated_dir) != 0:
        return zlib_fail(ctx, "could not publish generated directory: " ++ generated_dir)
    rc = zlib_remove_tree_if_exists(ctx, "out/zlib_build")
    if rc != 0: return rc
    rc = zlib_remove_tree_if_exists(ctx, "out/corpus/zlib-test")
    if rc != 0: return rc
    if fs.write_text(stamp_path, "ok\n") != 0:
        return zlib_fail(ctx, "could not write stamp: " ++ stamp_path)
    print(f"migrated zlib: {generated_count} .w files in " ++ zlib_abs(root, generated_dir))
    0

pub fn run_zlib_build_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    if inputs.len() == 0 or output_dir.len() == 0:
        return zlib_fail(ctx, "requires migrated-dir input and output directory")
    let migrated_dir = inputs.get(0)
    if not fs.is_dir(migrated_dir):
        return zlib_fail(ctx, "missing migrated zlib directory: " ++ migrated_dir ++ " - run zlib-migrate deliberately")
    let tmp_dir = zlib_join(zlib_scratch_dir(ctx), "build")
    let zlib_dir = zlib_join(zlib_join(zlib_join(tmp_dir, "lib"), "std"), "zlib")
    let bin_dir = zlib_join(tmp_dir, "bin")
    var rc = zlib_remove_tree_if_exists(ctx, tmp_dir)
    if rc != 0: return rc
    if fs.mkdir_all(zlib_dir) != 0 or fs.mkdir_all(bin_dir) != 0:
        return zlib_fail(ctx, "could not create temp build directories under " ++ tmp_dir)
    rc = zlib_copy_w_files(ctx, migrated_dir, zlib_dir)
    if rc != 0: return rc
    rc = zlib_reject_c_exports(ctx, zlib_dir)
    if rc != 0: return 1
    rc = zlib_compile_binary(ctx, "zlib-build-example", zlib_join(zlib_dir, "example.w"), zlib_join(bin_dir, "zlib_example"))
    if rc != 0: return rc
    rc = zlib_compile_binary(ctx, "zlib-build-minigzip", zlib_join(zlib_dir, "minigzip.w"), zlib_join(bin_dir, "minigzip"))
    if rc != 0: return rc
    rc = zlib_remove_tree_if_exists(ctx, output_dir)
    if rc != 0: return rc
    if fs.rename(tmp_dir, output_dir) != 0:
        return zlib_fail(ctx, "could not move temp tree to " ++ output_dir)
    print("built migrated zlib tests: " ++ zlib_abs(root, zlib_join(output_dir, "bin/zlib_example")))
    0

pub fn run_zlib_test_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let root = ctx.project_info().project_root()
    let output_dir = ctx.output()
    if inputs.len() < 3 or output_dir.len() == 0:
        return zlib_fail(ctx, "requires migrated-dir, example binary, minigzip binary, and output directory")
    let example_bin = inputs.get(1)
    let minigzip_bin = inputs.get(2)
    if not fs.exists(example_bin):
        return zlib_fail(ctx, "missing zlib example binary: " ++ example_bin)
    if not fs.exists(minigzip_bin):
        return zlib_fail(ctx, "missing minigzip binary: " ++ minigzip_bin)
    let run_dir = zlib_join(output_dir, "current")
    var rc = zlib_remove_tree_if_exists(ctx, run_dir)
    if rc != 0: return rc
    if fs.mkdir_all(run_dir) != 0:
        return zlib_fail(ctx, "could not create zlib-test output directory: " ++ run_dir)
    var example_args: Vec[str] = Vec.new()
    example_args.push(zlib_abs(root, example_bin))
    example_args.push("foo.gz")
    let example_result = ctx.process_runner().run_capture_cwd(example_args, zlib_abs(root, zlib_join(run_dir, "example.stdout")), zlib_abs(root, zlib_join(run_dir, "example.stderr")), 120000, zlib_abs(root, run_dir))
    if example_result.rc != 0:
        return zlib_fail(ctx, f"zlib example failed with exit code {example_result.rc}; stdout=" ++ zlib_join(run_dir, "example.stdout") ++ " stderr=" ++ zlib_join(run_dir, "example.stderr"))
    let input_path = zlib_join(run_dir, "minigzip-input.txt")
    if fs.write_text(input_path, "hello, hello!\n") != 0:
        return zlib_fail(ctx, "could not write minigzip input")
    var gzip_args: Vec[str] = Vec.new()
    gzip_args.push(zlib_abs(root, minigzip_bin))
    gzip_args.push("minigzip-input.txt")
    let gzip_result = ctx.process_runner().run_capture_cwd(gzip_args, zlib_abs(root, zlib_join(run_dir, "minigzip-compress.stdout")), zlib_abs(root, zlib_join(run_dir, "minigzip-compress.stderr")), 120000, zlib_abs(root, run_dir))
    if gzip_result.rc != 0:
        return zlib_fail(ctx, f"minigzip compress failed with exit code {gzip_result.rc}")
    if not fs.exists(zlib_join(run_dir, "minigzip-input.txt.gz")):
        return zlib_fail(ctx, "minigzip did not produce compressed file")
    var gunzip_args: Vec[str] = Vec.new()
    gunzip_args.push(zlib_abs(root, minigzip_bin))
    gunzip_args.push("-d")
    gunzip_args.push("minigzip-input.txt.gz")
    let gunzip_result = ctx.process_runner().run_capture_cwd(gunzip_args, zlib_abs(root, zlib_join(run_dir, "minigzip-decompress.stdout")), zlib_abs(root, zlib_join(run_dir, "minigzip-decompress.stderr")), 120000, zlib_abs(root, run_dir))
    if gunzip_result.rc != 0:
        return zlib_fail(ctx, f"minigzip decompress failed with exit code {gunzip_result.rc}")
    if fs.read_text(input_path) != "hello, hello!\n":
        return zlib_fail(ctx, "minigzip round-trip content mismatch")
    print("VERIFIED: migrated zlib example and minigzip tests pass")
    0

pub fn run_zlib_check_generated_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    let output = ctx.output()
    if inputs.len() == 0 or output.len() == 0:
        return zlib_fail(ctx, "requires generated-dir input and stamp output")
    let generated_dir = inputs.get(0)
    if zlib_reject_c_exports(ctx, generated_dir) != 0:
        return 1
    let count = zlib_count_w_files(ctx, generated_dir)
    if count < 18:
        return zlib_fail(ctx, f"only found {count} generated .w files; expected at least 18")
    if ctx.fs().write_text(output, "ok\n") != 0:
        return zlib_fail(ctx, "could not write generated-check stamp: " ++ output)
    0

pub fn run_zlib_promote_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let dest_dir = ctx.output()
    let root = ctx.project_info().project_root()
    if inputs.len() == 0 or dest_dir.len() == 0:
        return zlib_fail(ctx, "requires generated-dir input and destination output")
    let generated_dir = inputs.get(0)
    if zlib_reject_c_exports(ctx, generated_dir) != 0:
        return 1
    if fs.mkdir_all(dest_dir) != 0:
        return zlib_fail(ctx, "could not create destination: " ++ dest_dir)
    let existing = fs.list_files(dest_dir)
    for ei in 0..existing.len() as i32:
        let path = existing.get(ei as i64)
        if path.ends_with(".w") and fs.remove_file(path) != 0:
            return zlib_fail(ctx, "could not remove old generated file: " ++ path)
    let files = fs.list_files(generated_dir)
    var copied = 0
    for fi in 0..files.len() as i32:
        let source_path = files.get(fi as i64)
        if source_path.ends_with(".w"):
            let dest_path = zlib_join(dest_dir, zlib_basename(source_path))
            if fs.copy_file(source_path, dest_path) != 0:
                return zlib_fail(ctx, "could not copy " ++ source_path ++ " to " ++ dest_path)
            copied = copied + 1
    print(f"promoted {copied} generated zlib modules into " ++ zlib_abs(root, dest_dir))
    0
