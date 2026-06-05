use std.build
use build.runtime
use build.selfhost
use build.pcre2
use build.seed
use build.emit_c
use build.compiler
use build.clang_resource
use build.retention
use std.sysinfo

fn build_project_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn with_object_target(name: str, compiler: str, source: str, output: str, opt: str, dep: str) -> Target:
    var target = target_new(.Action, name, "").output(output)
    target.action = run_with_compiler_build_action
    target = target.compiler(compiler)
    target = target.input(source)
    target = target.arg("--emit-obj")
    target = target.arg("--no-prelude")
    target = target.arg(opt)
    target = target.write_scope("out/command/" ++ name)
    target = target.write_scope(build_project_dirname(output))
    if dep.len() > 0:
        target = target.dep(dep)
    target

fn with_ir_target(name: str, compiler: str, source: str, output: str, dep: str) -> Target:
    var target = target_new(.Action, name, "").output(output)
    target.action = run_with_compiler_ir_action
    target = target.compiler(compiler)
    target = target.input(source)
    target = target.arg("--no-prelude")
    target = target.write_scope(build_project_dirname(output))
    target = target.write_scope("out/command/" ++ name)
    if dep.len() > 0:
        target = target.dep(dep)
    target

fn run_write_empty_file_action(ctx: ActionCtx) -> i32:
    let output = ctx.output()
    if output.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": missing output")
        return 1
    let dir = build_project_dirname(output)
    let fs = ctx.fs()
    if fs.mkdir_all(dir) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not create output directory: " ++ dir)
        return 1
    if fs.write_text(output, "") != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not write: " ++ output)
        return 1
    0

fn empty_file_target(name: str, output: str) -> Target:
    var target = target_new(.Action, name, "").output(output)
    target.action = run_write_empty_file_action
    target = target.write_scope(build_project_dirname(output))
    target

fn run_prepare_bootstrap_link_root_action(ctx: ActionCtx) -> i32:
    // Old seed compilers prefer out/lib before out/bootstrap-lib. Removing the
    // probe object makes stage1 select the freshly generated bootstrap runtime.
    let fs = ctx.fs()
    let _remove_probe = fs.remove_file("out/lib/cimport_stubs.o")
    let output = ctx.output()
    if fs.mkdir_all(build_project_dirname(output)) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not create output directory: " ++ build_project_dirname(output))
        return 1
    if fs.write_text(output, "ok\n") != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not write: " ++ output)
        return 1
    0

fn target_with_embedded_stdlib_inputs(target: Target, ctx: BuildCtx) -> Target:
    var out = target
    let files = ctx.fs().list_files("lib/std")
    for i in 0..files.len() as i32:
        let path = files.get(i as i64)
        if path.ends_with(".w") and not path.starts_with("lib/std/re/"):
            out = out.input(path)
    out

fn target_with_compiler_c_export_audit_inputs(target: Target, ctx: BuildCtx) -> Target:
    var out = target
    let roots: Vec[str] = Vec.new()
    roots.push("src")
    roots.push("rt")
    roots.push("lib/std")
    for ri in 0..roots.len() as i32:
        let files = ctx.fs().list_files(roots.get(ri as i64))
        for fi in 0..files.len() as i32:
            let path = files.get(fi as i64)
            if path.ends_with(".w"):
                out = out.input(path)
    out

fn build_project_trim_line(text: str) -> str:
    var end = 0
    while end < text.len() as i32:
        let ch = text.byte_at(end as i64)
        if ch == 10 or ch == 13:
            break
        end = end + 1
    var start = 0
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 9 and ch != 32:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 9 and ch != 32:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn target_with_version_inputs(target: Target, ctx: BuildCtx) -> Target:
    var out = target
    out = out.arg("version-env=" ++ env("WITH_VERSION"))
    let fs = ctx.fs()
    if not fs.exists(".git/HEAD"):
        return out
    out = out.input(".git/HEAD")
    let head = build_project_trim_line(fs.read_text(".git/HEAD"))
    if head.starts_with("ref: "):
        let ref_path = ".git/" ++ head.slice(5, head.len())
        if fs.exists(ref_path):
            out = out.input(ref_path)
        else if fs.exists(".git/packed-refs"):
            out = out.input(".git/packed-refs")
    out

fn target_with_live_targets(target: Target, graph: Build) -> Target:
    var out = target
    for i in 0..graph.targets.len() as i32:
        out = out.arg("live-target=" ++ graph.targets.get(i as i64).name)
    out

type HostRuntimeSpec:
    platform_source: str
    compat_source: str
    bootstrap_platform_object: str
    platform_object: str
    platform_install_object: str
    platform_symbol: str
    opposite_bootstrap_platform_blob: str
    opposite_platform_blob: str
    opposite_platform_symbol: str
    second_opposite_bootstrap_platform_blob: str
    second_opposite_platform_blob: str
    second_opposite_platform_symbol: str
    fiber_core_source: str
    fiber_asm_source: str

fn host_exe_suffix() -> str:
    if os() == "Windows":
        return ".exe"
    ""

fn host_bin(path: str) -> str:
    path ++ host_exe_suffix()

fn host_runtime_spec() -> HostRuntimeSpec:
    if os() == "Linux" and arch() == "x86_64":
        return HostRuntimeSpec {
            platform_source: "rt/linux_x86_64.w",
            compat_source: "rt/compat_runtime.w",
            bootstrap_platform_object: "out/bootstrap-lib/rt_linux_x86_64.o",
            platform_object: "out/lib/rt_linux_x86_64.o",
            platform_install_object: "rt_linux_x86_64.o",
            platform_symbol: "rt_linux_x86_64_o",
            opposite_bootstrap_platform_blob: "out/bootstrap-lib/empty_rt_darwin_aarch64.bin",
            opposite_platform_blob: "out/lib/empty_rt_darwin_aarch64.bin",
            opposite_platform_symbol: "rt_darwin_aarch64_o",
            second_opposite_bootstrap_platform_blob: "out/bootstrap-lib/empty_rt_windows_x86_64.bin",
            second_opposite_platform_blob: "out/lib/empty_rt_windows_x86_64.bin",
            second_opposite_platform_symbol: "rt_windows_x86_64_o",
            fiber_core_source: "rt/fiber_core_darwin.w",
            fiber_asm_source: "runtime/fiber_asm_linux_x86_64.s",
        }
    if os() == "Windows" and arch() == "x86_64":
        return HostRuntimeSpec {
            platform_source: "rt/windows_x86_64.w",
            compat_source: "rt/compat_runtime.w",
            bootstrap_platform_object: "out/bootstrap-lib/rt_windows_x86_64.o",
            platform_object: "out/lib/rt_windows_x86_64.o",
            platform_install_object: "rt_windows_x86_64.o",
            platform_symbol: "rt_windows_x86_64_o",
            opposite_bootstrap_platform_blob: "out/bootstrap-lib/empty_rt_darwin_aarch64.bin",
            opposite_platform_blob: "out/lib/empty_rt_darwin_aarch64.bin",
            opposite_platform_symbol: "rt_darwin_aarch64_o",
            second_opposite_bootstrap_platform_blob: "out/bootstrap-lib/empty_rt_linux_x86_64.bin",
            second_opposite_platform_blob: "out/lib/empty_rt_linux_x86_64.bin",
            second_opposite_platform_symbol: "rt_linux_x86_64_o",
            fiber_core_source: "rt/fiber_core_windows_stub.w",
            fiber_asm_source: "runtime/fiber_asm_windows_x86_64.s",
        }
    HostRuntimeSpec {
        platform_source: "rt/darwin_aarch64.w",
        compat_source: "rt/compat_runtime.w",
        bootstrap_platform_object: "out/bootstrap-lib/rt_darwin_aarch64.o",
        platform_object: "out/lib/rt_darwin_aarch64.o",
        platform_install_object: "rt_darwin_aarch64.o",
        platform_symbol: "rt_darwin_aarch64_o",
        opposite_bootstrap_platform_blob: "out/bootstrap-lib/empty_rt_linux_x86_64.bin",
        opposite_platform_blob: "out/lib/empty_rt_linux_x86_64.bin",
        opposite_platform_symbol: "rt_linux_x86_64_o",
        second_opposite_bootstrap_platform_blob: "out/bootstrap-lib/empty_rt_windows_x86_64.bin",
        second_opposite_platform_blob: "out/lib/empty_rt_windows_x86_64.bin",
        second_opposite_platform_symbol: "rt_windows_x86_64_o",
        fiber_core_source: "rt/fiber_core_darwin.w",
        fiber_asm_source: "runtime/fiber_asm_aarch64.s",
    }

fn release_asset_for_host() -> str:
    if os() == "Linux" and arch() == "x86_64":
        return "with-linux-x86_64"
    if os() == "Macos" and (arch() == "armv8" or arch() == "aarch64"):
        return "with-darwin-aarch64"
    if os() == "Windows" and arch() == "x86_64":
        return "with-windows-x86_64"
    "with-darwin-aarch64"

// "with-darwin-aarch64" -> "darwin-aarch64"
fn release_platform_tag() -> str:
    let asset = release_asset_for_host()
    if asset.starts_with("with-"):
        return asset.slice(5, asset.len())
    asset

// ".deps/llvm-<ver>-<host>" -> "llvm-<ver>-<host>"
fn llvm_sdk_dir_basename() -> str:
    let prefix = compiler_default_llvm_prefix()
    if prefix.starts_with(".deps/"):
        return prefix.slice(6, prefix.len())
    prefix

fn llvm_sdk_asset_for_host() -> str:
    "with-llvm-sdk-" ++ compiler_llvm_version() ++ "-" ++ release_platform_tag() ++ ".tar.zst"

fn install_file_target(name: str, source: str, dest: str, mode: str, dep: str) -> Target:
    var target = target_new(.Install, name, source).output(dest)
    target = target.input(source)
    target = target.arg(mode)
    if dep.len() > 0:
        target = target.dep(dep)
    target

fn build_project_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn build_project_abs(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    build_project_join(root, path)

fn build_trim_trailing_line_endings(text: str) -> str:
    var end = text.len()
    while end > 0:
        let ch = text.byte_at(end - 1)
        if ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(0, end)

fn build_replace_once(text: str, needle: str, replacement: str) -> str:
    let idx = text.find(needle)
    if idx < 0:
        return ""
    text.slice(0, idx) ++ replacement ++ text.slice(idx + needle.len(), text.len())

fn issue61_fail(ctx: ActionCtx, message: str) -> i32:
    ctx.diagnostics().error("issue61-regression: " ++ message)
    1

fn issue61_regression_action(ctx: ActionCtx) -> i32:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return issue61_fail(ctx, "missing compiler input")
    let fs = ctx.fs()
    let output_dir = ctx.output()
    if fs.mkdir_all(output_dir) != 0:
        return issue61_fail(ctx, "could not create output directory: " ++ output_dir)

    let root = ctx.project_info().project_root()
    let compiler_path = build_project_abs(root, inputs.get(0))
    if not fs.exists(inputs.get(0)):
        return issue61_fail(ctx, "missing compiler: " ++ inputs.get(0))

    let repo_copy = build_project_join(output_dir, "repo")
    if fs.exists(repo_copy) and fs.remove_tree(repo_copy) != 0:
        return issue61_fail(ctx, "could not remove existing repo copy: " ++ repo_copy)
    if fs.mkdir_all(repo_copy) != 0:
        return issue61_fail(ctx, "could not create repo copy directory: " ++ repo_copy)

    if fs.copy_tree("src", build_project_join(repo_copy, "src")) != 0:
        return issue61_fail(ctx, "could not copy src into repo fixture")
    let copied_seed = build_project_join(repo_copy, "src/main")
    if fs.exists(copied_seed) and fs.remove_file(copied_seed) != 0:
        return issue61_fail(ctx, "could not remove copied seed from repo fixture")
    if fs.symlink("lib", build_project_join(repo_copy, "lib")) != 0:
        return issue61_fail(ctx, "could not link lib into repo fixture")

    let embedded_src = "out/gen/compiler/EmbeddedStdlibData.w"
    let embedded_dst = build_project_join(repo_copy, "out/gen/compiler/EmbeddedStdlibData.w")
    if fs.mkdir_all(build_project_join(repo_copy, "out/gen/compiler")) != 0:
        return issue61_fail(ctx, "could not create embedded stdlib data directory")
    if fs.write_text(embedded_dst, fs.read_text(embedded_src)) != 0:
        return issue61_fail(ctx, "could not copy embedded stdlib data module")

    let clang_res_src = "out/gen/compiler/EmbeddedClangResourceData.w"
    let clang_res_dst = build_project_join(repo_copy, "out/gen/compiler/EmbeddedClangResourceData.w")
    if fs.write_text(clang_res_dst, fs.read_text(clang_res_src)) != 0:
        return issue61_fail(ctx, "could not copy embedded clang resource data module")

    let sema_path = build_project_join(repo_copy, "src/SemaCheck.w")
    let sema_text = fs.read_text(sema_path)
    let marker = "    // Check all arguments (with expected-type propagation for Atomic ordering params)"
    let replacement = marker ++ "\n    var mc_issue61_padding_local: i32 = 0"
    let patched = build_replace_once(sema_text, marker, replacement)
    if patched.len() == 0:
        return issue61_fail(ctx, "missing insertion point in " ++ sema_path)
    if fs.write_text(sema_path, patched) != 0:
        return issue61_fail(ctx, "could not patch " ++ sema_path)
    if not fs.read_text(sema_path).contains("mc_issue61_padding_local"):
        return issue61_fail(ctx, "failed to inject noop local")

    let stdout_path = build_project_abs(root, build_project_join(output_dir, "check.stdout"))
    let stderr_path = build_project_abs(root, build_project_join(output_dir, "check.stderr"))
    var check_args: Vec[str] = Vec.new()
    check_args |> push(compiler_path)
    check_args |> push("check")
    check_args |> push("src/main.w")
    let check = ctx.process_runner().run_capture_cwd(check_args, stdout_path, stderr_path, 60000, build_project_abs(root, repo_copy))
    if check.rc == 124:
        return issue61_fail(ctx, "check timed out; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    if check.rc != 0:
        return issue61_fail(ctx, f"check failed with exit code {check.rc}; stdout=" ++ stdout_path ++ " stderr=" ++ stderr_path)
    let output = build_trim_trailing_line_endings(check.stdout)
    if output != "ok":
        return issue61_fail(ctx, "check produced unexpected output: " ++ output)
    0

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    let host_runtime = host_runtime_spec()

    var compiler_sources = target_new(.Action, "compiler-sources", "").output("out/gen/.generated-stamp")
    compiler_sources.action = run_generate_compiler_entrypoints_action
    compiler_sources = compiler_sources.input("src/main.w")
    compiler_sources = compiler_sources.input("src/bootstrap_main.w")
    compiler_sources = compiler_sources.input("src/version")
    compiler_sources = compiler_sources.extra_output("out/gen/main.w")
    compiler_sources = compiler_sources.extra_output("out/gen/bootstrap_main.w")
    compiler_sources = compiler_sources.extra_output("out/gen/version.txt")
    compiler_sources = target_with_version_inputs(compiler_sources, ctx)
    out = out.add_target(compiler_sources)

    var compat_runtime = target_new(.Action, "compat-runtime-source", "").output("out/gen/compat_runtime.w")
    compat_runtime = compat_runtime.extra_output("out/gen/compiler/EmbeddedStdlibData.w")
    compat_runtime = compat_runtime.input(host_runtime.compat_source)
    compat_runtime = target_with_embedded_stdlib_inputs(compat_runtime, ctx)
    compat_runtime.action = generate_compat_runtime_action
    out = out.add_target(compat_runtime)

    // Embed clang's builtin headers into the binary so c_import is self-contained
    // at runtime (#312). Generated from the static SDK fetched/built into .deps.
    var clang_resource = target_new(.Action, "embedded-clang-resource-source", "").output("out/gen/compiler/EmbeddedClangResourceData.w")
    clang_resource.action = generate_embedded_clang_resource_action
    out = out.add_target(clang_resource)

    var compiler_no_c_export = target_new(.Action, "compiler-no-c-export", "").output("out/.build-state/compiler-no-c-export.txt")
    compiler_no_c_export.action = run_check_compiler_no_new_c_export_action
    compiler_no_c_export = compiler_no_c_export.write_scope("out/.build-state")
    compiler_no_c_export = target_with_compiler_c_export_audit_inputs(compiler_no_c_export, ctx)
    out = out.add_target(compiler_no_c_export)

    out = out.add_target(with_object_target("bootstrap-llvm-bridge-object", "seed", "src/compiler/LlvmBridge.w", "out/bootstrap-lib/llvm_bridge.o", "-O0", ""))
    out = out.add_target(with_object_target("bootstrap-clang-bridge-object", "seed", "src/compiler/ClangBridge.w", "out/bootstrap-lib/clang_bridge.o", "-O0", ""))

    var bootstrap_llvm_link_metadata = target_new(.Action, "bootstrap-llvm-link-metadata", "").output("out/bootstrap-lib/.llvm-link-ready")
    bootstrap_llvm_link_metadata.action = run_generate_llvm_link_metadata_action
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.input("out/bootstrap-lib/llvm_bridge.o")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.input("out/bootstrap-lib/clang_bridge.o")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.extra_output("out/bootstrap-lib/llvm_link.rsp")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.extra_output("out/bootstrap-lib/llvm_cc")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.extra_output("out/bootstrap-lib/llvm_ld.rsp")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.extra_output("out/bootstrap-lib/llvm_ld")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.dep("bootstrap-llvm-bridge-object")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.dep("bootstrap-clang-bridge-object")
    out = out.add_target(bootstrap_llvm_link_metadata)

    out = out.add_target(with_object_target("bootstrap-rt-core-object", "seed", "rt/rt_core.w", "out/bootstrap-lib/rt_core.o", "-O2", ""))
    out = out.add_target(with_object_target("bootstrap-rt-platform-object", "seed", host_runtime.platform_source, host_runtime.bootstrap_platform_object, "-O2", ""))
    out = out.add_target(empty_file_target("bootstrap-empty-opposite-runtime-blob", host_runtime.opposite_bootstrap_platform_blob))
    out = out.add_target(empty_file_target("bootstrap-empty-second-opposite-runtime-blob", host_runtime.second_opposite_bootstrap_platform_blob))
    out = out.add_target(with_object_target("bootstrap-cimport-stubs-object", "seed", "rt/cimport_stubs.w", "out/bootstrap-lib/cimport_stubs.o", "-O0", ""))
    out = out.add_target(with_object_target("bootstrap-compat-runtime-object", "seed", "out/gen/compat_runtime.w", "out/bootstrap-lib/compat_runtime.o", "-O0", "compat-runtime-source"))
    out = out.add_target(with_object_target("bootstrap-panic-runtime-object", "seed", "rt/panic_runtime.w", "out/bootstrap-lib/panic_runtime.o", "-O0", ""))
    out = out.add_target(with_ir_target("bootstrap-regex-runtime-ir", "seed", "rt/regex_runtime.w", "out/bootstrap-tmp/regex_runtime.ll", ""))
    var bootstrap_regex_runtime = target_new(.CompileLlvmIrObject, "bootstrap-regex-runtime-object", "out/bootstrap-tmp/regex_runtime.ll").output("out/bootstrap-lib/regex_runtime.o")
    bootstrap_regex_runtime = bootstrap_regex_runtime.dep("bootstrap-regex-runtime-ir")
    out = out.add_target(bootstrap_regex_runtime)
    out = out.add_target(with_object_target("bootstrap-fiber-stubs-object", "seed", "rt/fiber_stubs.w", "out/bootstrap-lib/fiber_stubs.o", "-O0", ""))
    out = out.add_target(with_object_target("bootstrap-channel-runtime-object", "seed", "rt/channel_runtime.w", "out/bootstrap-lib/channel_runtime.o", "-O0", ""))
    out = out.add_target(with_object_target("bootstrap-fiber-runtime-object", "seed", "rt/fiber_runtime.w", "out/bootstrap-lib/fiber_runtime.o", "-O0", ""))
    out = out.add_target(with_object_target("bootstrap-fiber-core-object", "seed", host_runtime.fiber_core_source, "out/bootstrap-lib/fiber.o", "-O0", ""))
    var bootstrap_fiber_asm = target_new(.CompileAsmObject, "bootstrap-fiber-asm-object", host_runtime.fiber_asm_source).output("out/bootstrap-lib/fiber_asm.o")
    out = out.add_target(bootstrap_fiber_asm)

    var bootstrap_embedded_objects = target_new(.EmbedObjectFiles, "bootstrap-embedded-objects-asm", "").output("out/bootstrap-lib/embedded_objects.s")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/cimport_stubs.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("cimport_stubs_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/compat_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("compat_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/panic_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("panic_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/regex_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("regex_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/fiber_stubs.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("fiber_stubs_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/channel_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("channel_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/fiber_runtime.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("fiber_runtime_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/fiber.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("fiber_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/fiber_asm.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("fiber_asm_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/rt_core.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("rt_core_o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.input(host_runtime.bootstrap_platform_object)
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg(host_runtime.platform_symbol)
    bootstrap_embedded_objects = bootstrap_embedded_objects.input(host_runtime.opposite_bootstrap_platform_blob)
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg(host_runtime.opposite_platform_symbol)
    bootstrap_embedded_objects = bootstrap_embedded_objects.input(host_runtime.second_opposite_bootstrap_platform_blob)
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg(host_runtime.second_opposite_platform_symbol)
    out = out.add_target(bootstrap_embedded_objects)
    var bootstrap_embedded_objects_obj = target_new(.CompileAsmObject, "bootstrap-embedded-objects-object", "out/bootstrap-lib/embedded_objects.s").output("out/bootstrap-lib/embedded_objects.o")
    bootstrap_embedded_objects_obj = bootstrap_embedded_objects_obj.dep("bootstrap-embedded-objects-asm")
    out = out.add_target(bootstrap_embedded_objects_obj)

    var bootstrap_runtime = target_new(.Group, "bootstrap-runtime", "")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-llvm-link-metadata")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-rt-core-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-rt-platform-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-empty-opposite-runtime-blob")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-empty-second-opposite-runtime-blob")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-cimport-stubs-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-compat-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-panic-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-regex-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-fiber-stubs-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-channel-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-fiber-runtime-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-fiber-core-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-fiber-asm-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-embedded-objects-object")
    out = out.add_target(bootstrap_runtime)

    var prepare_bootstrap_link_root = target_new(.Action, "prepare-bootstrap-link-root", "").output("out/bootstrap-lib/.prepared-link-root")
    prepare_bootstrap_link_root.action = run_prepare_bootstrap_link_root_action
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input("src/compiler/LlvmBridge.w")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input("src/compiler/ClangBridge.w")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input("rt/cimport_stubs.w")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input("rt/rt_core.w")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input(host_runtime.platform_source)
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.input(host_runtime.compat_source)
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.write_scope("out/lib")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.write_scope("out/bootstrap-lib")
    prepare_bootstrap_link_root = prepare_bootstrap_link_root.dep("bootstrap-runtime")
    out = out.add_target(prepare_bootstrap_link_root)

    out = out.add_target(with_object_target("llvm-bridge-object", host_bin("out/bin/with-stage2"), "src/compiler/LlvmBridge.w", "out/lib/llvm_bridge.o", "-O0", "stage2"))
    out = out.add_target(with_object_target("clang-bridge-object", host_bin("out/bin/with-stage2"), "src/compiler/ClangBridge.w", "out/lib/clang_bridge.o", "-O0", "stage2"))

    var llvm_link_metadata = target_new(.Action, "llvm-link-metadata", "").output("out/lib/.llvm-link-ready")
    llvm_link_metadata.action = run_generate_llvm_link_metadata_action
    llvm_link_metadata = llvm_link_metadata.input("out/lib/llvm_bridge.o")
    llvm_link_metadata = llvm_link_metadata.input("out/lib/clang_bridge.o")
    llvm_link_metadata = llvm_link_metadata.extra_output("out/lib/llvm_link.rsp")
    llvm_link_metadata = llvm_link_metadata.extra_output("out/lib/llvm_cc")
    llvm_link_metadata = llvm_link_metadata.extra_output("out/lib/llvm_ld.rsp")
    llvm_link_metadata = llvm_link_metadata.extra_output("out/lib/llvm_ld")
    llvm_link_metadata = llvm_link_metadata.dep("llvm-bridge-object")
    llvm_link_metadata = llvm_link_metadata.dep("clang-bridge-object")
    out = out.add_target(llvm_link_metadata)

    var stage1 = target_new(.Action, "stage1", "").output(host_bin("out/bin/with-stage1"))
    stage1.action = run_with_compiler_build_action
    stage1 = stage1.compiler("seed")
    stage1 = stage1.input("out/gen/main.w")
    stage1 = stage1.arg("-O0")
    stage1 = stage1.extra_output("out/command/stage1")
    stage1 = stage1.extra_output("out/.build-state/seed-input.json")
    stage1 = stage1.write_scope("out/bin")
    stage1 = stage1.write_scope("out/.build-state")
    stage1 = stage1.dep("compiler-sources")
    stage1 = stage1.dep("compat-runtime-source")
    stage1 = stage1.dep("embedded-clang-resource-source")
    stage1 = stage1.dep("compiler-no-c-export")
    stage1 = stage1.dep("prepare-bootstrap-link-root")
    out = out.add_target(stage1)

    var stage2 = target_new(.Action, "stage2", "").output(host_bin("out/bin/with-stage2"))
    stage2.action = run_with_compiler_build_action
    stage2 = stage2.compiler(host_bin("out/bin/with-stage1"))
    stage2 = stage2.input("out/gen/main.w")
    stage2 = stage2.arg("-O0")
    stage2 = stage2.extra_output("out/command/stage2")
    stage2 = stage2.write_scope("out/bin")
    stage2 = stage2.dep("stage1")
    stage2 = stage2.dep("compat-runtime-source")
    stage2 = stage2.dep("embedded-clang-resource-source")
    out = out.add_target(stage2)

    var stage3 = target_new(.Action, "stage3", "").output(host_bin("out/bin/with-stage3"))
    stage3.action = run_with_compiler_build_action
    stage3 = stage3.compiler(host_bin("out/bin/with-stage2"))
    stage3 = stage3.input("out/gen/main.w")
    stage3 = stage3.arg("-O0")
    stage3 = stage3.extra_output("out/command/stage3")
    stage3 = stage3.write_scope("out/bin")
    stage3 = stage3.dep("stage2")
    stage3 = stage3.dep("compat-runtime-source")
    stage3 = stage3.dep("embedded-clang-resource-source")
    out = out.add_target(stage3)

    var stage2_fixpoint = target_new(.Action, "stage2-fixpoint-object", "").output("out/bin/with-stage2-fixpoint.o")
    stage2_fixpoint.action = run_with_compiler_build_action
    stage2_fixpoint = stage2_fixpoint.compiler(host_bin("out/bin/with-stage1"))
    stage2_fixpoint = stage2_fixpoint.input("out/gen/main.w")
    stage2_fixpoint = stage2_fixpoint.arg("--emit-obj")
    stage2_fixpoint = stage2_fixpoint.arg("-O0")
    stage2_fixpoint = stage2_fixpoint.extra_output("out/command/stage2-fixpoint-object")
    stage2_fixpoint = stage2_fixpoint.write_scope("out/bin")
    stage2_fixpoint = stage2_fixpoint.dep("stage1")
    stage2_fixpoint = stage2_fixpoint.dep("compat-runtime-source")
    stage2_fixpoint = stage2_fixpoint.dep("embedded-clang-resource-source")
    out = out.add_target(stage2_fixpoint)

    var stage3_fixpoint = target_new(.Action, "stage3-fixpoint-object", "").output("out/bin/with-stage3-fixpoint.o")
    stage3_fixpoint.action = run_with_compiler_build_action
    stage3_fixpoint = stage3_fixpoint.compiler(host_bin("out/bin/with-stage2"))
    stage3_fixpoint = stage3_fixpoint.input("out/gen/main.w")
    stage3_fixpoint = stage3_fixpoint.arg("--emit-obj")
    stage3_fixpoint = stage3_fixpoint.arg("-O0")
    stage3_fixpoint = stage3_fixpoint.extra_output("out/command/stage3-fixpoint-object")
    stage3_fixpoint = stage3_fixpoint.write_scope("out/bin")
    stage3_fixpoint = stage3_fixpoint.dep("stage2")
    stage3_fixpoint = stage3_fixpoint.dep("compat-runtime-source")
    stage3_fixpoint = stage3_fixpoint.dep("embedded-clang-resource-source")
    out = out.add_target(stage3_fixpoint)

    var selfcheck = target_new(.RunCorpusTest, "selfcheck", host_bin("out/bin/with-stage2"))
    selfcheck = selfcheck.output("out/corpus/selfcheck")
    selfcheck = selfcheck.arg("check")
    selfcheck = selfcheck.arg("src/main.w")
    selfcheck = selfcheck.dep("stage2")
    out = out.add_target(selfcheck)

    var fixpoint_compare = target_new(.FixpointCompare, "fixpoint-compare", "out/bin/with-stage2-fixpoint.o")
    fixpoint_compare = fixpoint_compare.arg("out/bin/with-stage3-fixpoint.o")
    fixpoint_compare = fixpoint_compare.dep("stage2-fixpoint-object")
    fixpoint_compare = fixpoint_compare.dep("stage3-fixpoint-object")
    out = out.add_target(fixpoint_compare)

    var bless_manifest = target_new(.Action, "bless-manifest", "").output("out/.build-state/blessed-manifest")
    bless_manifest.action = run_bless_manifest_action
    bless_manifest = bless_manifest.write_scope("out/.build-state")
    bless_manifest = bless_manifest.dep("fixpoint-compare")
    out = out.add_target(bless_manifest)

    var fixpoint = target_new(.Group, "fixpoint", "")
    fixpoint = fixpoint.dep("fixpoint-compare")
    fixpoint = fixpoint.dep("bless-manifest")
    out = out.add_target(fixpoint)

    var verified = target_new(.Group, "verified-existing-stage", "")
    verified = verified.dep("selfcheck")
    verified = verified.dep("fixpoint")
    out = out.add_target(verified)

    out = out.add_target(with_object_target("rt-core-object", host_bin("out/bin/with-stage2"), "rt/rt_core.w", "out/lib/rt_core.o", "-O2", "stage2"))
    out = out.add_target(with_object_target("rt-platform-object", host_bin("out/bin/with-stage2"), host_runtime.platform_source, host_runtime.platform_object, "-O2", "stage2"))
    out = out.add_target(empty_file_target("empty-opposite-runtime-blob", host_runtime.opposite_platform_blob))
    out = out.add_target(empty_file_target("empty-second-opposite-runtime-blob", host_runtime.second_opposite_platform_blob))
    out = out.add_target(with_object_target("cimport-stubs-object", host_bin("out/bin/with-stage2"), "rt/cimport_stubs.w", "out/lib/cimport_stubs.o", "-O0", "stage2"))
    var compat_runtime_obj = with_object_target("compat-runtime-object", host_bin("out/bin/with-stage2"), "out/gen/compat_runtime.w", "out/lib/compat_runtime.o", "-O0", "stage2")
    compat_runtime_obj = compat_runtime_obj.dep("compat-runtime-source")
    out = out.add_target(compat_runtime_obj)
    out = out.add_target(with_object_target("panic-runtime-object", host_bin("out/bin/with-stage2"), "rt/panic_runtime.w", "out/lib/panic_runtime.o", "-O0", "stage2"))
    out = out.add_target(with_ir_target("regex-runtime-ir", host_bin("out/bin/with-stage2"), "rt/regex_runtime.w", "out/tmp/regex_runtime.ll", "stage2"))

    var regex_runtime = target_new(.CompileLlvmIrObject, "regex-runtime-object", "out/tmp/regex_runtime.ll").output("out/lib/regex_runtime.o")
    out = out.add_target(regex_runtime)

    out = out.add_target(with_object_target("fiber-stubs-object", host_bin("out/bin/with-stage2"), "rt/fiber_stubs.w", "out/lib/fiber_stubs.o", "-O0", "stage2"))
    out = out.add_target(with_object_target("channel-runtime-object", host_bin("out/bin/with-stage2"), "rt/channel_runtime.w", "out/lib/channel_runtime.o", "-O0", "stage2"))
    out = out.add_target(with_object_target("fiber-runtime-object", host_bin("out/bin/with-stage2"), "rt/fiber_runtime.w", "out/lib/fiber_runtime.o", "-O0", "stage2"))
    out = out.add_target(with_object_target("fiber-core-object", host_bin("out/bin/with-stage2"), host_runtime.fiber_core_source, "out/lib/fiber.o", "-O0", "stage2"))

    var fiber_asm = target_new(.CompileAsmObject, "fiber-asm-object", host_runtime.fiber_asm_source).output("out/lib/fiber_asm.o")
    out = out.add_target(fiber_asm)

    var embedded_objects = target_new(.EmbedObjectFiles, "embedded-objects-asm", "").output("out/lib/embedded_objects.s")
    embedded_objects = embedded_objects.input("out/lib/cimport_stubs.o")
    embedded_objects = embedded_objects.arg("cimport_stubs_o")
    embedded_objects = embedded_objects.input("out/lib/compat_runtime.o")
    embedded_objects = embedded_objects.arg("compat_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/panic_runtime.o")
    embedded_objects = embedded_objects.arg("panic_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/regex_runtime.o")
    embedded_objects = embedded_objects.arg("regex_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/fiber_stubs.o")
    embedded_objects = embedded_objects.arg("fiber_stubs_o")
    embedded_objects = embedded_objects.input("out/lib/channel_runtime.o")
    embedded_objects = embedded_objects.arg("channel_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/fiber_runtime.o")
    embedded_objects = embedded_objects.arg("fiber_runtime_o")
    embedded_objects = embedded_objects.input("out/lib/fiber.o")
    embedded_objects = embedded_objects.arg("fiber_o")
    embedded_objects = embedded_objects.input("out/lib/fiber_asm.o")
    embedded_objects = embedded_objects.arg("fiber_asm_o")
    embedded_objects = embedded_objects.input("out/lib/rt_core.o")
    embedded_objects = embedded_objects.arg("rt_core_o")
    embedded_objects = embedded_objects.input(host_runtime.platform_object)
    embedded_objects = embedded_objects.arg(host_runtime.platform_symbol)
    embedded_objects = embedded_objects.input(host_runtime.opposite_platform_blob)
    embedded_objects = embedded_objects.arg(host_runtime.opposite_platform_symbol)
    embedded_objects = embedded_objects.input(host_runtime.second_opposite_platform_blob)
    embedded_objects = embedded_objects.arg(host_runtime.second_opposite_platform_symbol)
    out = out.add_target(embedded_objects)

    var embedded_objects_obj = target_new(.CompileAsmObject, "embedded-objects-object", "out/lib/embedded_objects.s").output("out/lib/embedded_objects.o")
    out = out.add_target(embedded_objects_obj)

    var runtime = target_new(.Group, "runtime", "")
    runtime = runtime.dep("embedded-objects-object")
    runtime = runtime.dep("empty-opposite-runtime-blob")
    runtime = runtime.dep("empty-second-opposite-runtime-blob")
    out = out.add_target(runtime)

    var compiler = target_new(.Action, "build", "").output(host_bin("out/bin/with"))
    compiler.action = run_with_compiler_build_action
    compiler = compiler.compiler(host_bin("out/bin/with-stage2"))
    compiler = compiler.input("out/gen/main.w")
    compiler = compiler.arg("-O0")
    compiler = compiler.extra_output("out/command/build")
    compiler = compiler.write_scope("out/bin")
    compiler = compiler.dep("llvm-link-metadata")
    compiler = compiler.dep("embedded-objects-object")
    out = out.add_target(compiler)

    var emit_c_test = target_new(.Action, "emit-c-test", "").output("out/gen/.emit-c-test-stamp")
    emit_c_test.action = run_emit_c_test_action
    emit_c_test = emit_c_test.input(host_bin("out/bin/with"))
    emit_c_test = emit_c_test.extra_output("out/emit-c-test")
    emit_c_test = emit_c_test.extra_output("out/gen/wl_decls.h")
    emit_c_test = emit_c_test.extra_output("out/gen/wl_stubs.c")
    emit_c_test = emit_c_test.extra_output("out/command/emit-c-test")
    emit_c_test = emit_c_test.dep("build")
    out = out.add_target(emit_c_test)

    var emit_c_fixpoint = target_new(.Action, "emit-c-fixpoint", "").output("out/gen/.emit-c-fixpoint-stamp")
    emit_c_fixpoint.action = run_emit_c_fixpoint_action
    emit_c_fixpoint = emit_c_fixpoint.input("out/emit-c-test/main.c")
    emit_c_fixpoint = emit_c_fixpoint.input("out/emit-c-test/with-from-c")
    emit_c_fixpoint = emit_c_fixpoint.extra_output("out/emit-c-test/main2.c")
    emit_c_fixpoint = emit_c_fixpoint.extra_output("out/command/emit-c-fixpoint")
    emit_c_fixpoint = emit_c_fixpoint.dep("emit-c-test")
    out = out.add_target(emit_c_fixpoint)

    var emit_c_roundtrip = target_new(.Action, "emit-c-roundtrip", "").output("out/gen/.emit-c-roundtrip-stamp")
    emit_c_roundtrip.action = run_emit_c_roundtrip_action
    emit_c_roundtrip = emit_c_roundtrip.input(host_bin("out/bin/with"))
    emit_c_roundtrip = emit_c_roundtrip.extra_output("out/emit-c-roundtrip")
    emit_c_roundtrip = emit_c_roundtrip.extra_output("out/gen/wl_decls.h")
    emit_c_roundtrip = emit_c_roundtrip.extra_output("out/gen/wl_stubs.c")
    emit_c_roundtrip = emit_c_roundtrip.extra_output("out/command/emit-c-roundtrip")
    emit_c_roundtrip = emit_c_roundtrip.dep("build")
    out = out.add_target(emit_c_roundtrip)

    var behavior_tests = target_new(.Test, "behavior-tests", "test/behavior/*.w")
    behavior_tests = behavior_tests.arg("compiler=" ++ host_bin("out/bin/with"))
    behavior_tests = behavior_tests.dep("build")
    out = out.add_target(behavior_tests)

    var native_compile_error_tests = target_new(.Test, "native-compile-error-tests", "test/compile_errors/*.w")
    native_compile_error_tests = native_compile_error_tests.arg("compiler=" ++ host_bin("out/bin/with"))
    native_compile_error_tests = native_compile_error_tests.dep("build")
    native_compile_error_tests = native_compile_error_tests.dep("selfcheck")
    out = out.add_target(native_compile_error_tests)

    var native_codegen_tests = target_new(.Test, "native-codegen-tests", "test/codegen/*.w")
    native_codegen_tests = native_codegen_tests.arg("compiler=" ++ host_bin("out/bin/with"))
    native_codegen_tests = native_codegen_tests.dep("build")
    native_codegen_tests = native_codegen_tests.dep("selfcheck")
    out = out.add_target(native_codegen_tests)

    var native_spec_tests = target_new(.Test, "native-spec-tests", "test/spec/*.w")
    native_spec_tests = native_spec_tests.arg("compiler=" ++ host_bin("out/bin/with"))
    native_spec_tests = native_spec_tests.dep("build")
    native_spec_tests = native_spec_tests.dep("selfcheck")
    out = out.add_target(native_spec_tests)

    var native_phase_tests = target_new(.Test, "native-phase-tests", "test/phase/*.w")
    native_phase_tests = native_phase_tests.arg("compiler=" ++ host_bin("out/bin/with"))
    native_phase_tests = native_phase_tests.dep("build")
    native_phase_tests = native_phase_tests.dep("selfcheck")
    out = out.add_target(native_phase_tests)

    var cli_selfhost_smoke_tests = target_new(.Action, "cli-selfhost-smoke-tests", "").output("out/test-graph/cli-selfhost-smoke-tests")
    cli_selfhost_smoke_tests.action = run_cli_selfhost_smoke_action
    cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.input(host_bin("out/bin/with"))
    cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.dep("build")
    out = out.add_target(cli_selfhost_smoke_tests)

    var cli_selfhost_one_liner_tests = target_new(.Action, "cli-selfhost-one-liner-tests", "").output("out/test-graph/cli-selfhost-one-liner-tests")
    cli_selfhost_one_liner_tests.action = run_cli_selfhost_one_liner_action
    cli_selfhost_one_liner_tests = cli_selfhost_one_liner_tests.input(host_bin("out/bin/with"))
    cli_selfhost_one_liner_tests = cli_selfhost_one_liner_tests.dep("build")
    out = out.add_target(cli_selfhost_one_liner_tests)

    var cli_selfhost_object_symbol_tests = target_new(.Action, "cli-selfhost-object-symbol-tests", "").output("out/test-graph/cli-selfhost-object-symbol-tests")
    cli_selfhost_object_symbol_tests.action = run_cli_selfhost_object_symbol_action
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.arg("nm")
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.input(host_bin("out/bin/with"))
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.dep("build")
    out = out.add_target(cli_selfhost_object_symbol_tests)

    var cli_selfhost_build_w_tests = target_new(.Action, "cli-selfhost-build-w-tests", "").output("out/test-graph/cli-selfhost-build-w-tests")
    cli_selfhost_build_w_tests.action = run_cli_selfhost_build_w_action
    cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.input(host_bin("out/bin/with"))
    cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.dep("build")
    out = out.add_target(cli_selfhost_build_w_tests)

    var cli_selfhost_project_tests = target_new(.Action, "cli-selfhost-project-tests", "").output("out/test-graph/cli-selfhost-project-tests")
    cli_selfhost_project_tests.action = run_cli_selfhost_project_action
    cli_selfhost_project_tests = cli_selfhost_project_tests.input(host_bin("out/bin/with"))
    cli_selfhost_project_tests = cli_selfhost_project_tests.allow_network()
    cli_selfhost_project_tests = cli_selfhost_project_tests.dep("build")
    out = out.add_target(cli_selfhost_project_tests)

    var cli_selfhost_edge_tests = target_new(.Action, "cli-selfhost-edge-tests", "").output("out/test-graph/cli-selfhost-edge-tests")
    cli_selfhost_edge_tests.action = run_cli_selfhost_edge_action
    cli_selfhost_edge_tests = cli_selfhost_edge_tests.input(host_bin("out/bin/with"))
    cli_selfhost_edge_tests = cli_selfhost_edge_tests.dep("build")
    out = out.add_target(cli_selfhost_edge_tests)

    var cli_selfhost_parallel_tests = target_new(.Action, "cli-selfhost-parallel-tests", "").output("out/test-graph/cli-selfhost-parallel-tests")
    cli_selfhost_parallel_tests.action = run_cli_selfhost_parallel_action
    cli_selfhost_parallel_tests = cli_selfhost_parallel_tests.input(host_bin("out/bin/with"))
    cli_selfhost_parallel_tests = cli_selfhost_parallel_tests.dep("build")
    out = out.add_target(cli_selfhost_parallel_tests)

    var c_migrator_pcre2_prep_tests = target_new(.Action, "c-migrator-pcre2-prep-tests", "").output("out/test-graph/c-migrator-pcre2-prep-tests")
    c_migrator_pcre2_prep_tests.action = run_cli_selfhost_pcre2_prep_action
    c_migrator_pcre2_prep_tests = c_migrator_pcre2_prep_tests.input(host_bin("out/bin/with"))
    c_migrator_pcre2_prep_tests = c_migrator_pcre2_prep_tests.write_scope("out/pcre2_tmp")
    c_migrator_pcre2_prep_tests = c_migrator_pcre2_prep_tests.dep("build")
    out = out.add_target(c_migrator_pcre2_prep_tests)

    var c_migrator_basic_tests = target_new(.Action, "c-migrator-basic-tests", "").output("out/test-graph/c-migrator-basic-tests")
    c_migrator_basic_tests.action = run_cli_selfhost_migrate_basic_action
    c_migrator_basic_tests = c_migrator_basic_tests.input(host_bin("out/bin/with"))
    c_migrator_basic_tests = c_migrator_basic_tests.dep("build")
    out = out.add_target(c_migrator_basic_tests)

    var c_migrator_core_tests = target_new(.Action, "c-migrator-core-tests", "").output("out/test-graph/c-migrator-core-tests")
    c_migrator_core_tests.action = run_cli_selfhost_migrate_core_action
    c_migrator_core_tests = c_migrator_core_tests.input(host_bin("out/bin/with"))
    c_migrator_core_tests = c_migrator_core_tests.dep("build")
    out = out.add_target(c_migrator_core_tests)

    var c_migrator_tests = target_new(.Group, "c-migrator-tests", "")
    c_migrator_tests = c_migrator_tests.dep("c-migrator-basic-tests")
    c_migrator_tests = c_migrator_tests.dep("c-migrator-core-tests")
    out = out.add_target(c_migrator_tests)

    var issue61_regression = target_new(.Action, "issue61-regression", "").output("out/test-graph/issue61-regression")
    issue61_regression.action = issue61_regression_action
    issue61_regression = issue61_regression.input(host_bin("out/bin/with"))
    issue61_regression = issue61_regression.dep("build")
    out = out.add_target(issue61_regression)

    var embedded_runtime_regression = target_new(.Action, "embedded-runtime-regression", "").output("out/test-graph/embedded-runtime-regression")
    embedded_runtime_regression.action = run_embedded_runtime_regression_action
    embedded_runtime_regression = embedded_runtime_regression.input(host_bin("out/bin/with"))
    embedded_runtime_regression = embedded_runtime_regression.dep("build")
    out = out.add_target(embedded_runtime_regression)

    var emit_c_smoke = target_new(.Action, "emit-c-smoke", "").output("out/test-graph/emit-c-smoke")
    emit_c_smoke.action = run_emit_c_smoke_action
    emit_c_smoke = emit_c_smoke.input(host_bin("out/bin/with"))
    emit_c_smoke = emit_c_smoke.input("test/hello.w")
    emit_c_smoke = emit_c_smoke.dep("build")
    emit_c_smoke = emit_c_smoke.dep("runtime")
    out = out.add_target(emit_c_smoke)

    var test_green = target_new(.Action, "test-green", "").output("out/.build-state/test-green.json")
    test_green.action = run_test_green_action
    test_green = test_green.write_scope("out/.build-state")
    test_green = test_green.write_scope("out/command/test-green")
    out = out.add_target(test_green)

    var tests = target_new(.Group, "test", "")
    tests = tests.dep("behavior-tests")
    tests = tests.dep("native-compile-error-tests")
    tests = tests.dep("native-codegen-tests")
    tests = tests.dep("native-spec-tests")
    tests = tests.dep("native-phase-tests")
    tests = tests.dep("cli-selfhost-smoke-tests")
    tests = tests.dep("cli-selfhost-one-liner-tests")
    tests = tests.dep("cli-selfhost-object-symbol-tests")
    tests = tests.dep("cli-selfhost-build-w-tests")
    tests = tests.dep("cli-selfhost-project-tests")
    tests = tests.dep("cli-selfhost-edge-tests")
    tests = tests.dep("cli-selfhost-parallel-tests")
    tests = tests.dep("c-migrator-tests")
    tests = tests.dep("issue61-regression")
    tests = tests.dep("embedded-runtime-regression")
    tests = tests.dep("emit-c-smoke")
    tests = tests.dep("test-green")
    out = out.add_target(tests)

    var last_green = target_new(.Action, "last-green", "").output("out/.build-state/last-green.json")
    last_green.action = run_last_green_action
    last_green = last_green.input(host_bin("out/bin/with"))
    last_green = last_green.input("out/bin/with-stage2-fixpoint.o")
    last_green = last_green.input("out/bin/with-stage3-fixpoint.o")
    last_green = last_green.input("out/.build-state/seed-input.json")
    last_green = last_green.input("src/version")
    last_green = last_green.extra_output("out/seed-archive")
    last_green = last_green.extra_output("out/command/last-green")
    last_green = last_green.write_scope("out/.build-state")
    last_green = last_green.write_scope("out/seed-archive")
    last_green = last_green.write_scope("out/command/last-green")
    last_green = last_green.dep("fixpoint")
    out = out.add_target(last_green)

    var require_last_green = target_new(.Action, "require-last-green", "").output("out/command/require-last-green/ok")
    require_last_green.action = run_require_last_green_action
    require_last_green = require_last_green.write_scope("out/command/require-last-green")
    out = out.add_target(require_last_green)

    var check_committed = target_new(.Action, "check-committed-state", "").output("out/command/check-committed-state/ok")
    check_committed.action = run_check_committed_state_action
    check_committed = check_committed.write_scope("out/command/check-committed-state")
    out = out.add_target(check_committed)

    var install_user = target_new(.Action, "install-user", "").output("out/command/install-user/ok")
    install_user.action = run_install_verified_compiler_action
    install_user = install_user.arg(host_bin("out/bin/with"))
    install_user = install_user.arg("$HOME/.local/bin/with")
    install_user = install_user.arg("0755")
    install_user = install_user.write_scope("out/command/install-user")
    install_user = install_user.dep("require-last-green")
    out = out.add_target(install_user)

    out = out.add_target(install_file_target("install-compiler", host_bin("out/bin/with-stage2"), "$INSTALL_BINDIR/with" ++ host_exe_suffix(), "0755", "stage2"))
    out = out.add_target(install_file_target("install-rt-core", "out/lib/rt_core.o", "$INSTALL_LIBDIR/rt_core.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-rt-platform", host_runtime.platform_object, "$INSTALL_LIBDIR/" ++ host_runtime.platform_install_object, "0644", "runtime"))
    out = out.add_target(install_file_target("install-cimport-stubs", "out/lib/cimport_stubs.o", "$INSTALL_LIBDIR/cimport_stubs.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-compat-runtime", "out/lib/compat_runtime.o", "$INSTALL_LIBDIR/compat_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-panic-runtime", "out/lib/panic_runtime.o", "$INSTALL_LIBDIR/panic_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-regex-runtime", "out/lib/regex_runtime.o", "$INSTALL_LIBDIR/regex_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-fiber-stubs", "out/lib/fiber_stubs.o", "$INSTALL_LIBDIR/fiber_stubs.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-channel-runtime", "out/lib/channel_runtime.o", "$INSTALL_LIBDIR/channel_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-fiber-runtime", "out/lib/fiber_runtime.o", "$INSTALL_LIBDIR/fiber_runtime.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-fiber-core", "out/lib/fiber.o", "$INSTALL_LIBDIR/fiber.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-fiber-asm", "out/lib/fiber_asm.o", "$INSTALL_LIBDIR/fiber_asm.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-embedded-objects", "out/lib/embedded_objects.o", "$INSTALL_LIBDIR/embedded_objects.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-embedded-objects-asm", "out/lib/embedded_objects.s", "$INSTALL_LIBDIR/embedded_objects.s", "0644", "runtime"))
    out = out.add_target(install_file_target("install-llvm-bridge", "out/lib/llvm_bridge.o", "$INSTALL_LIBDIR/llvm_bridge.o", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-clang-bridge", "out/lib/clang_bridge.o", "$INSTALL_LIBDIR/clang_bridge.o", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-llvm-link-rsp", "out/lib/llvm_link.rsp", "$INSTALL_LIBDIR/llvm_link.rsp", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-llvm-cc", "out/lib/llvm_cc", "$INSTALL_LIBDIR/llvm_cc", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-llvm-ld-rsp", "out/lib/llvm_ld.rsp", "$INSTALL_LIBDIR/llvm_ld.rsp", "0644", "llvm-link-metadata"))
    out = out.add_target(install_file_target("install-llvm-ld", "out/lib/llvm_ld", "$INSTALL_LIBDIR/llvm_ld", "0644", "llvm-link-metadata"))
    var install = target_new(.Group, "install", "")
    install = install.dep("install-compiler")
    install = install.dep("install-rt-core")
    install = install.dep("install-rt-platform")
    install = install.dep("install-cimport-stubs")
    install = install.dep("install-compat-runtime")
    install = install.dep("install-panic-runtime")
    install = install.dep("install-regex-runtime")
    install = install.dep("install-fiber-stubs")
    install = install.dep("install-channel-runtime")
    install = install.dep("install-fiber-runtime")
    install = install.dep("install-fiber-core")
    install = install.dep("install-fiber-asm")
    install = install.dep("install-embedded-objects")
    install = install.dep("install-embedded-objects-asm")
    install = install.dep("install-llvm-bridge")
    install = install.dep("install-clang-bridge")
    install = install.dep("install-llvm-link-rsp")
    install = install.dep("install-llvm-cc")
    install = install.dep("install-llvm-ld-rsp")
    install = install.dep("install-llvm-ld")
    out = out.add_target(install)

    var seed = target_new(.Action, "seed", "").output("src/main")
    seed.action = run_seed_download_action
    seed = seed.write_scope("out/tmp")
    seed = seed.arg("withlang-dev/with")
    seed = seed.arg(release_asset_for_host())
    out = out.add_target(seed)

    // `with build :deps` — fetch the pinned, per-platform static LLVM SDK that
    // bootstrap built and a release published, into `.deps/llvm-<ver>-<host>`,
    // so a build never rebuilds LLVM from source or trusts a system LLVM.
    var deps = target_new(.Action, "deps", "").output(compiler_default_libclang_archive_path())
    deps.action = run_deps_download_action
    deps = deps.write_scope("out/tmp")
    deps = deps.write_scope(".deps")
    deps = deps.arg("withlang-dev/with")
    deps = deps.arg(llvm_sdk_asset_for_host())
    deps = deps.arg(llvm_sdk_dir_basename())
    out = out.add_target(deps)

    var update_seed = target_new(.Action, "update-seed", "").output("src/main")
    update_seed.action = run_install_verified_compiler_action
    update_seed = update_seed.arg(host_bin("out/bin/with"))
    update_seed = update_seed.arg("src/main")
    update_seed = update_seed.arg("0755")
    update_seed = update_seed.write_scope("src")
    update_seed = update_seed.dep("require-last-green")
    out = out.add_target(update_seed)

    var clean = target_new(.Clean, "clean", "")
    clean = clean.arg("out")
    clean = clean.arg(".with")
    clean = clean.arg("src/main.c")
    clean = clean.arg("src/main.o")
    clean = clean.arg("src/bootstrap_main.c")
    clean = clean.arg("src/bootstrap_main.o")
    clean = clean.arg("main.c")
    clean = clean.arg("main.o")
    clean = clean.arg("bootstrap_main.c")
    clean = clean.arg("bootstrap_main.o")
    out = out.add_target(clean)

    var pcre2_reference = target_new(.Action, "pcre2-reference", "").output("out/pcre2_reference/pcre2-10.47")
    pcre2_reference.action = run_pcre2_reference_action
    pcre2_reference = pcre2_reference.extra_output("out/pcre2_reference/pcre2-10.47/.with-reference-ready")
    pcre2_reference = pcre2_reference.extra_output("out/pcre2_tmp")
    pcre2_reference = pcre2_reference.arg("pcre2-10.47")
    pcre2_reference = pcre2_reference.arg("https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.47/pcre2-10.47.tar.gz")
    out = out.add_target(pcre2_reference)

    var pcre2_migrate = target_new(.Action, "pcre2-migrate", "").output("out/gen/.regex-migrate-stamp")
    pcre2_migrate.action = run_pcre2_migrate_action
    pcre2_migrate = pcre2_migrate.extra_output("out/pcre2_migrated")
    pcre2_migrate = pcre2_migrate.write_scope("out/pcre2_tmp")
    pcre2_migrate = pcre2_migrate.write_scope("out/pcre2_migrate_raw")
    pcre2_migrate = pcre2_migrate.write_scope("out/pcre2_generated")
    pcre2_migrate = pcre2_migrate.write_scope("out/pcre2_build")
    pcre2_migrate = pcre2_migrate.write_scope("out/gen/.regex-build-stamp")
    pcre2_migrate = pcre2_migrate.input("out/pcre2_reference/pcre2-10.47/src")
    pcre2_migrate = pcre2_migrate.arg("out/pcre2_migrated")
    pcre2_migrate = pcre2_migrate.arg("pcre2demo.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2grep.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2posix_test.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2_jit_test.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2_dftables.c")
    pcre2_migrate = pcre2_migrate.arg("pcre2_fuzzsupport.c")
    pcre2_migrate = pcre2_migrate.dep("pcre2-reference")
    out = out.add_target(pcre2_migrate)

    var pcre2_migrate_smoke = target_new(.Action, "pcre2-migrate-smoke", "").output("out/test-graph/pcre2-migrate-smoke")
    pcre2_migrate_smoke.action = run_pcre2_migrate_smoke_action
    pcre2_migrate_smoke = pcre2_migrate_smoke.input("out/pcre2_reference/pcre2-10.47/src/pcre2_compile.c")
    pcre2_migrate_smoke = pcre2_migrate_smoke.input("out/pcre2_reference/pcre2-10.47/src")
    pcre2_migrate_smoke = pcre2_migrate_smoke.dep("pcre2-reference")
    out = out.add_target(pcre2_migrate_smoke)

    var pcre2_test_smoke = target_new(.Action, "pcre2-test-smoke", "").output("out/test-graph/pcre2-test-smoke")
    pcre2_test_smoke.action = run_pcre2_test_smoke_action
    pcre2_test_smoke = pcre2_test_smoke.input("lib/std/re/pcre2test.w")
    pcre2_test_smoke = pcre2_test_smoke.input("out/pcre2_reference/pcre2-10.47/RunTest")
    pcre2_test_smoke = pcre2_test_smoke.arg("out/pcre2_reference/pcre2-10.47")
    pcre2_test_smoke = pcre2_test_smoke.dep("pcre2-reference")
    pcre2_test_smoke = pcre2_test_smoke.dep("selfcheck")
    out = out.add_target(pcre2_test_smoke)

    var pcre2_build = target_new(.Action, "pcre2-build", "").output("out/pcre2_build")
    pcre2_build.action = run_pcre2_build_action
    pcre2_build = pcre2_build.write_scope("out/pcre2_tmp")
    pcre2_build = pcre2_build.input("out/pcre2_migrated")
    pcre2_build = pcre2_build.dep("build")
    out = out.add_target(pcre2_build)

    var pcre2_test = target_new(.Action, "pcre2-test", "").output("out/corpus/pcre2-test")
    pcre2_test.action = run_pcre2_test_action
    pcre2_test = pcre2_test.input("out/pcre2_migrated")
    pcre2_test = pcre2_test.input("out/pcre2_build/bin/pcre2test")
    pcre2_test = pcre2_test.input("out/pcre2_reference/pcre2-10.47/RunTest")
    pcre2_test = pcre2_test.arg("out/pcre2_reference/pcre2-10.47")
    pcre2_test = pcre2_test.dep("verified-existing-stage")
    out = out.add_target(pcre2_test)

    var pcre2_check_generated = target_new(.Action, "pcre2-check-generated", "").output("out/gen/.pcre2-check-generated-stamp")
    pcre2_check_generated.action = run_pcre2_check_generated_action
    pcre2_check_generated = pcre2_check_generated.write_scope("out/pcre2_tmp")
    pcre2_check_generated = pcre2_check_generated.input("out/pcre2_build/lib/std/re")
    pcre2_check_generated = pcre2_check_generated.dep("build")
    out = out.add_target(pcre2_check_generated)

    var pcre2_promote = target_new(.Action, "pcre2-promote", "").output("lib/std/re")
    pcre2_promote.action = run_pcre2_promote_action
    pcre2_promote = pcre2_promote.write_scope("out/pcre2_tmp")
    pcre2_promote = pcre2_promote.input("out/pcre2_build/lib/std/re")
    pcre2_promote = pcre2_promote.dep("pcre2-test")
    out = out.add_target(pcre2_promote)

    var prune = target_new(.Action, "prune", "").output("out/.build-state/prune.always")
    prune.action = run_prune_action
    prune = prune.arg("dry-run")
    prune = prune.arg("live-target=prune")
    prune = prune.arg("live-target=prune-apply")
    prune = target_with_live_targets(prune, out)
    prune = prune.write_scope("out/bin")
    prune = prune.write_scope("out/lib")
    prune = prune.write_scope("out/bootstrap-lib")
    prune = prune.write_scope("out/.build-state")
    prune = prune.write_scope("out/seed-archive")
    prune = prune.write_scope("out/test-graph")
    prune = prune.write_scope("out/command/prune")
    out = out.add_target(prune)

    var prune_apply = target_new(.Action, "prune-apply", "").output("out/.build-state/prune-apply.always")
    prune_apply.action = run_prune_action
    prune_apply = prune_apply.arg("apply")
    prune_apply = prune_apply.arg("live-target=prune")
    prune_apply = prune_apply.arg("live-target=prune-apply")
    prune_apply = target_with_live_targets(prune_apply, out)
    prune_apply = prune_apply.write_scope("out/bin")
    prune_apply = prune_apply.write_scope("out/lib")
    prune_apply = prune_apply.write_scope("out/bootstrap-lib")
    prune_apply = prune_apply.write_scope("out/.build-state")
    prune_apply = prune_apply.write_scope("out/seed-archive")
    prune_apply = prune_apply.write_scope("out/test-graph")
    prune_apply = prune_apply.write_scope("out/command/prune-apply")
    out = out.add_target(prune_apply)

    out.default("build")
