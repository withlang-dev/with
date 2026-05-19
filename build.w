use std.build
use build_runtime
use build_selfhost
use build_pcre2
use build_seed

fn project_kind_generate_compiler_entrypoints() -> BuildKind: 1003 as BuildKind
fn project_kind_with_compiler_build() -> BuildKind: 1004 as BuildKind
fn project_kind_with_compiler_ir() -> BuildKind: 1013 as BuildKind
fn project_kind_generate_llvm_link_metadata() -> BuildKind: 1020 as BuildKind
fn project_kind_emit_c_test() -> BuildKind: 1025 as BuildKind
fn project_kind_emit_c_fixpoint() -> BuildKind: 1026 as BuildKind
fn project_kind_emit_c_roundtrip() -> BuildKind: 1027 as BuildKind

fn with_object_target(name: str, compiler: str, source: str, output: str, opt: str, dep: str) -> Target:
    var target = target_new(project_kind_with_compiler_build(), name, compiler).output(output)
    target = target.input(source)
    target = target.arg("--emit-obj")
    target = target.arg("--no-prelude")
    target = target.arg(opt)
    if dep.len() > 0:
        target = target.dep(dep)
    target

fn with_ir_target(name: str, compiler: str, source: str, output: str, dep: str) -> Target:
    var target = target_new(project_kind_with_compiler_ir(), name, compiler).output(output)
    target = target.input(source)
    target = target.arg("--no-prelude")
    if dep.len() > 0:
        target = target.dep(dep)
    target

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
    if fs.symlink("lib", build_project_join(repo_copy, "lib")) != 0:
        return issue61_fail(ctx, "could not link lib into repo fixture")

    let embedded_src = "out/gen/compiler/EmbeddedStdlibData.w"
    let embedded_dst = build_project_join(repo_copy, "out/gen/compiler/EmbeddedStdlibData.w")
    if fs.mkdir_all(build_project_join(repo_copy, "out/gen/compiler")) != 0:
        return issue61_fail(ctx, "could not create embedded stdlib data directory")
    if fs.write_text(embedded_dst, fs.read_text(embedded_src)) != 0:
        return issue61_fail(ctx, "could not copy embedded stdlib data module")

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

    var compiler_sources = target_new(project_kind_generate_compiler_entrypoints(), "compiler-sources", "").output("out/gen/.generated-stamp")
    compiler_sources = compiler_sources.input("src/main.w")
    compiler_sources = compiler_sources.input("src/bootstrap_main.w")
    compiler_sources = compiler_sources.input("src/main_emit_temp.w")
    compiler_sources = compiler_sources.input("src/version")
    out = out.add_target(compiler_sources)

    var compat_runtime = target_new(.Action, "compat-runtime-source", "").output("out/gen/compat_runtime.w")
    compat_runtime = compat_runtime.extra_output("out/gen/compiler/EmbeddedStdlibData.w")
    compat_runtime = compat_runtime.input("rt/compat_runtime.w")
    compat_runtime.action = generate_compat_runtime_action
    out = out.add_target(compat_runtime)

    out = out.add_target(with_object_target("bootstrap-llvm-bridge-object", "seed", "rt/llvm_bridge.w", "out/bootstrap-lib/llvm_bridge.o", "-O0", ""))
    out = out.add_target(with_object_target("bootstrap-clang-bridge-object", "seed", "rt/clang_bridge.w", "out/bootstrap-lib/clang_bridge.o", "-O0", ""))

    var bootstrap_llvm_link_metadata = target_new(project_kind_generate_llvm_link_metadata(), "bootstrap-llvm-link-metadata", "").output("out/bootstrap-lib/.llvm-link-ready")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.input("out/bootstrap-lib/llvm_bridge.o")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.input("out/bootstrap-lib/clang_bridge.o")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.dep("bootstrap-llvm-bridge-object")
    bootstrap_llvm_link_metadata = bootstrap_llvm_link_metadata.dep("bootstrap-clang-bridge-object")
    out = out.add_target(bootstrap_llvm_link_metadata)

    out = out.add_target(with_object_target("bootstrap-rt-core-object", "seed", "rt/rt_core.w", "out/bootstrap-lib/rt_core.o", "-O2", ""))
    out = out.add_target(with_object_target("bootstrap-rt-darwin-aarch64-object", "seed", "rt/darwin_aarch64.w", "out/bootstrap-lib/rt_darwin_aarch64.o", "-O2", ""))
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
    out = out.add_target(with_object_target("bootstrap-fiber-core-object", "seed", "rt/fiber_core_darwin.w", "out/bootstrap-lib/fiber.o", "-O0", ""))
    var bootstrap_fiber_asm = target_new(.CompileAsmObject, "bootstrap-fiber-asm-object", "runtime/fiber_asm_aarch64.s").output("out/bootstrap-lib/fiber_asm.o")
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
    bootstrap_embedded_objects = bootstrap_embedded_objects.input("out/bootstrap-lib/rt_darwin_aarch64.o")
    bootstrap_embedded_objects = bootstrap_embedded_objects.arg("rt_darwin_aarch64_o")
    out = out.add_target(bootstrap_embedded_objects)
    var bootstrap_embedded_objects_obj = target_new(.CompileAsmObject, "bootstrap-embedded-objects-object", "out/bootstrap-lib/embedded_objects.s").output("out/bootstrap-lib/embedded_objects.o")
    bootstrap_embedded_objects_obj = bootstrap_embedded_objects_obj.dep("bootstrap-embedded-objects-asm")
    out = out.add_target(bootstrap_embedded_objects_obj)

    var bootstrap_runtime = target_new(.Group, "bootstrap-runtime", "")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-llvm-link-metadata")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-rt-core-object")
    bootstrap_runtime = bootstrap_runtime.dep("bootstrap-rt-darwin-aarch64-object")
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

    var llvm_bridge = target_new(project_kind_with_compiler_build(), "llvm-bridge-object", "seed").output("out/lib/llvm_bridge.o")
    llvm_bridge = llvm_bridge.input("rt/llvm_bridge.w")
    llvm_bridge = llvm_bridge.arg("--emit-obj")
    llvm_bridge = llvm_bridge.arg("--no-prelude")
    llvm_bridge = llvm_bridge.arg("-O0")
    out = out.add_target(llvm_bridge)

    var clang_bridge = target_new(project_kind_with_compiler_build(), "clang-bridge-object", "seed").output("out/lib/clang_bridge.o")
    clang_bridge = clang_bridge.input("rt/clang_bridge.w")
    clang_bridge = clang_bridge.arg("--emit-obj")
    clang_bridge = clang_bridge.arg("--no-prelude")
    clang_bridge = clang_bridge.arg("-O0")
    out = out.add_target(clang_bridge)

    var llvm_link_metadata = target_new(project_kind_generate_llvm_link_metadata(), "llvm-link-metadata", "").output("out/lib/.llvm-link-ready")
    llvm_link_metadata = llvm_link_metadata.input("out/lib/llvm_bridge.o")
    llvm_link_metadata = llvm_link_metadata.input("out/lib/clang_bridge.o")
    llvm_link_metadata = llvm_link_metadata.dep("llvm-bridge-object")
    llvm_link_metadata = llvm_link_metadata.dep("clang-bridge-object")
    out = out.add_target(llvm_link_metadata)

    var stage1 = target_new(project_kind_with_compiler_build(), "stage1", "seed").output("out/bin/with-stage1")
    stage1 = stage1.input("out/gen/main.w")
    stage1 = stage1.arg("-O0")
    stage1 = stage1.dep("compiler-sources")
    stage1 = stage1.dep("compat-runtime-source")
    stage1 = stage1.dep("bootstrap-runtime")
    out = out.add_target(stage1)

    var stage2 = target_new(project_kind_with_compiler_build(), "stage2", "out/bin/with-stage1").output("out/bin/with-stage2")
    stage2 = stage2.input("out/gen/main.w")
    stage2 = stage2.arg("-O0")
    stage2 = stage2.dep("stage1")
    stage2 = stage2.dep("compat-runtime-source")
    out = out.add_target(stage2)

    var stage3 = target_new(project_kind_with_compiler_build(), "stage3", "out/bin/with-stage2").output("out/bin/with-stage3")
    stage3 = stage3.input("out/gen/main.w")
    stage3 = stage3.arg("-O0")
    stage3 = stage3.dep("stage2")
    stage3 = stage3.dep("compat-runtime-source")
    out = out.add_target(stage3)

    var stage2_fixpoint = target_new(project_kind_with_compiler_build(), "stage2-fixpoint-object", "out/bin/with-stage1").output("out/bin/with-stage2-fixpoint.o")
    stage2_fixpoint = stage2_fixpoint.input("out/gen/main.w")
    stage2_fixpoint = stage2_fixpoint.arg("--emit-obj")
    stage2_fixpoint = stage2_fixpoint.arg("-O0")
    stage2_fixpoint = stage2_fixpoint.dep("stage1")
    stage2_fixpoint = stage2_fixpoint.dep("compat-runtime-source")
    out = out.add_target(stage2_fixpoint)

    var stage3_fixpoint = target_new(project_kind_with_compiler_build(), "stage3-fixpoint-object", "out/bin/with-stage2").output("out/bin/with-stage3-fixpoint.o")
    stage3_fixpoint = stage3_fixpoint.input("out/gen/main.w")
    stage3_fixpoint = stage3_fixpoint.arg("--emit-obj")
    stage3_fixpoint = stage3_fixpoint.arg("-O0")
    stage3_fixpoint = stage3_fixpoint.dep("stage2")
    stage3_fixpoint = stage3_fixpoint.dep("compat-runtime-source")
    out = out.add_target(stage3_fixpoint)

    var selfcheck = target_new(.RunCorpusTest, "selfcheck", "out/bin/with-stage2")
    selfcheck = selfcheck.output("out/corpus/selfcheck")
    selfcheck = selfcheck.arg("check")
    selfcheck = selfcheck.arg("src/main.w")
    selfcheck = selfcheck.dep("stage2")
    out = out.add_target(selfcheck)

    var fixpoint = target_new(.FixpointCompare, "fixpoint", "out/bin/with-stage2-fixpoint.o")
    fixpoint = fixpoint.arg("out/bin/with-stage3-fixpoint.o")
    fixpoint = fixpoint.dep("stage2-fixpoint-object")
    fixpoint = fixpoint.dep("stage3-fixpoint-object")
    out = out.add_target(fixpoint)

    var verified = target_new(.Group, "verified-existing-stage", "")
    verified = verified.dep("selfcheck")
    verified = verified.dep("fixpoint")
    out = out.add_target(verified)

    var rt_core = target_new(project_kind_with_compiler_build(), "rt-core-object", "out/bin/with-stage2").output("out/lib/rt_core.o")
    rt_core = rt_core.input("rt/rt_core.w")
    rt_core = rt_core.arg("--emit-obj")
    rt_core = rt_core.arg("--no-prelude")
    rt_core = rt_core.arg("-O2")
    rt_core = rt_core.dep("stage2")
    out = out.add_target(rt_core)

    var rt_darwin = target_new(project_kind_with_compiler_build(), "rt-darwin-aarch64-object", "out/bin/with-stage2").output("out/lib/rt_darwin_aarch64.o")
    rt_darwin = rt_darwin.input("rt/darwin_aarch64.w")
    rt_darwin = rt_darwin.arg("--emit-obj")
    rt_darwin = rt_darwin.arg("--no-prelude")
    rt_darwin = rt_darwin.arg("-O2")
    rt_darwin = rt_darwin.dep("stage2")
    out = out.add_target(rt_darwin)

    var cimport_stubs = target_new(project_kind_with_compiler_build(), "cimport-stubs-object", "out/bin/with-stage2").output("out/lib/cimport_stubs.o")
    cimport_stubs = cimport_stubs.input("rt/cimport_stubs.w")
    cimport_stubs = cimport_stubs.arg("--emit-obj")
    cimport_stubs = cimport_stubs.arg("--no-prelude")
    cimport_stubs = cimport_stubs.arg("-O0")
    cimport_stubs = cimport_stubs.dep("stage2")
    out = out.add_target(cimport_stubs)

    var compat_runtime_obj = target_new(project_kind_with_compiler_build(), "compat-runtime-object", "out/bin/with-stage2").output("out/lib/compat_runtime.o")
    compat_runtime_obj = compat_runtime_obj.input("out/gen/compat_runtime.w")
    compat_runtime_obj = compat_runtime_obj.arg("--emit-obj")
    compat_runtime_obj = compat_runtime_obj.arg("--no-prelude")
    compat_runtime_obj = compat_runtime_obj.arg("-O0")
    compat_runtime_obj = compat_runtime_obj.dep("stage2")
    compat_runtime_obj = compat_runtime_obj.dep("compat-runtime-source")
    out = out.add_target(compat_runtime_obj)

    var panic_runtime = target_new(project_kind_with_compiler_build(), "panic-runtime-object", "out/bin/with-stage2").output("out/lib/panic_runtime.o")
    panic_runtime = panic_runtime.input("rt/panic_runtime.w")
    panic_runtime = panic_runtime.arg("--emit-obj")
    panic_runtime = panic_runtime.arg("--no-prelude")
    panic_runtime = panic_runtime.arg("-O0")
    panic_runtime = panic_runtime.dep("stage2")
    out = out.add_target(panic_runtime)

    var regex_runtime_ir = target_new(project_kind_with_compiler_ir(), "regex-runtime-ir", "out/bin/with-stage2").output("out/tmp/regex_runtime.ll")
    regex_runtime_ir = regex_runtime_ir.input("rt/regex_runtime.w")
    regex_runtime_ir = regex_runtime_ir.arg("--no-prelude")
    regex_runtime_ir = regex_runtime_ir.dep("stage2")
    out = out.add_target(regex_runtime_ir)

    var regex_runtime = target_new(.CompileLlvmIrObject, "regex-runtime-object", "out/tmp/regex_runtime.ll").output("out/lib/regex_runtime.o")
    out = out.add_target(regex_runtime)

    var fiber_stubs = target_new(project_kind_with_compiler_build(), "fiber-stubs-object", "out/bin/with-stage2").output("out/lib/fiber_stubs.o")
    fiber_stubs = fiber_stubs.input("rt/fiber_stubs.w")
    fiber_stubs = fiber_stubs.arg("--emit-obj")
    fiber_stubs = fiber_stubs.arg("--no-prelude")
    fiber_stubs = fiber_stubs.arg("-O0")
    fiber_stubs = fiber_stubs.dep("stage2")
    out = out.add_target(fiber_stubs)

    var channel_runtime = target_new(project_kind_with_compiler_build(), "channel-runtime-object", "out/bin/with-stage2").output("out/lib/channel_runtime.o")
    channel_runtime = channel_runtime.input("rt/channel_runtime.w")
    channel_runtime = channel_runtime.arg("--emit-obj")
    channel_runtime = channel_runtime.arg("--no-prelude")
    channel_runtime = channel_runtime.arg("-O0")
    channel_runtime = channel_runtime.dep("stage2")
    out = out.add_target(channel_runtime)

    var fiber_runtime = target_new(project_kind_with_compiler_build(), "fiber-runtime-object", "out/bin/with-stage2").output("out/lib/fiber_runtime.o")
    fiber_runtime = fiber_runtime.input("rt/fiber_runtime.w")
    fiber_runtime = fiber_runtime.arg("--emit-obj")
    fiber_runtime = fiber_runtime.arg("--no-prelude")
    fiber_runtime = fiber_runtime.arg("-O0")
    fiber_runtime = fiber_runtime.dep("stage2")
    out = out.add_target(fiber_runtime)

    var fiber_core = target_new(project_kind_with_compiler_build(), "fiber-core-object", "out/bin/with-stage2").output("out/lib/fiber.o")
    fiber_core = fiber_core.input("rt/fiber_core_darwin.w")
    fiber_core = fiber_core.arg("--emit-obj")
    fiber_core = fiber_core.arg("--no-prelude")
    fiber_core = fiber_core.arg("-O0")
    fiber_core = fiber_core.dep("stage2")
    out = out.add_target(fiber_core)

    var fiber_asm = target_new(.CompileAsmObject, "fiber-asm-object", "runtime/fiber_asm_aarch64.s").output("out/lib/fiber_asm.o")
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
    embedded_objects = embedded_objects.input("out/lib/rt_darwin_aarch64.o")
    embedded_objects = embedded_objects.arg("rt_darwin_aarch64_o")
    out = out.add_target(embedded_objects)

    var embedded_objects_obj = target_new(.CompileAsmObject, "embedded-objects-object", "out/lib/embedded_objects.s").output("out/lib/embedded_objects.o")
    out = out.add_target(embedded_objects_obj)

    var runtime = target_new(.Group, "runtime", "")
    runtime = runtime.dep("embedded-objects-object")
    out = out.add_target(runtime)

    var compiler = target_new(project_kind_with_compiler_build(), "build", "out/bin/with-stage2").output("out/bin/with")
    compiler = compiler.input("out/gen/main.w")
    compiler = compiler.arg("-O0")
    compiler = compiler.dep("llvm-link-metadata")
    compiler = compiler.dep("embedded-objects-object")
    out = out.add_target(compiler)

    var emit_c_test = target_new(project_kind_emit_c_test(), "emit-c-test", "out/bin/with").output("out/gen/.emit-c-test-stamp")
    emit_c_test = emit_c_test.input("out/bin/with")
    emit_c_test = emit_c_test.dep("build")
    out = out.add_target(emit_c_test)

    var emit_c_fixpoint = target_new(project_kind_emit_c_fixpoint(), "emit-c-fixpoint", "out/emit-c-test/with-from-c").output("out/gen/.emit-c-fixpoint-stamp")
    emit_c_fixpoint = emit_c_fixpoint.input("out/emit-c-test/main.c")
    emit_c_fixpoint = emit_c_fixpoint.input("out/emit-c-test/with-from-c")
    emit_c_fixpoint = emit_c_fixpoint.dep("emit-c-test")
    out = out.add_target(emit_c_fixpoint)

    var emit_c_roundtrip = target_new(project_kind_emit_c_roundtrip(), "emit-c-roundtrip", "out/bin/with").output("out/gen/.emit-c-roundtrip-stamp")
    emit_c_roundtrip = emit_c_roundtrip.input("out/bin/with")
    emit_c_roundtrip = emit_c_roundtrip.dep("build")
    out = out.add_target(emit_c_roundtrip)

    var behavior_tests = target_new(.Test, "behavior-tests", "test/behavior/*.w")
    behavior_tests = behavior_tests.arg("compiler=out/bin/with-stage2")
    behavior_tests = behavior_tests.dep("selfcheck")
    out = out.add_target(behavior_tests)

    var native_compile_error_tests = target_new(.Test, "native-compile-error-tests", "test/compile_errors/*.w")
    native_compile_error_tests = native_compile_error_tests.dep("selfcheck")
    out = out.add_target(native_compile_error_tests)

    var native_codegen_tests = target_new(.Test, "native-codegen-tests", "test/codegen/*.w")
    native_codegen_tests = native_codegen_tests.dep("selfcheck")
    out = out.add_target(native_codegen_tests)

    var native_spec_tests = target_new(.Test, "native-spec-tests", "test/spec/*.w")
    native_spec_tests = native_spec_tests.dep("selfcheck")
    out = out.add_target(native_spec_tests)

    var native_phase_tests = target_new(.Test, "native-phase-tests", "test/phase/*.w")
    native_phase_tests = native_phase_tests.dep("selfcheck")
    out = out.add_target(native_phase_tests)

    var cli_selfhost_smoke_tests = target_new(.Action, "cli-selfhost-smoke-tests", "").output("out/test-graph/cli-selfhost-smoke-tests")
    cli_selfhost_smoke_tests.action = run_cli_selfhost_smoke_action
    cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.input("out/bin/with-stage2")
    cli_selfhost_smoke_tests = cli_selfhost_smoke_tests.dep("selfcheck")
    out = out.add_target(cli_selfhost_smoke_tests)

    var cli_selfhost_one_liner_tests = target_new(.Action, "cli-selfhost-one-liner-tests", "").output("out/test-graph/cli-selfhost-one-liner-tests")
    cli_selfhost_one_liner_tests.action = run_cli_selfhost_one_liner_action
    cli_selfhost_one_liner_tests = cli_selfhost_one_liner_tests.input("out/bin/with-stage2")
    cli_selfhost_one_liner_tests = cli_selfhost_one_liner_tests.dep("selfcheck")
    out = out.add_target(cli_selfhost_one_liner_tests)

    var cli_selfhost_object_symbol_tests = target_new(.Action, "cli-selfhost-object-symbol-tests", "").output("out/test-graph/cli-selfhost-object-symbol-tests")
    cli_selfhost_object_symbol_tests.action = run_cli_selfhost_object_symbol_action
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.arg("nm")
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.input("out/bin/with-stage2")
    cli_selfhost_object_symbol_tests = cli_selfhost_object_symbol_tests.dep("selfcheck")
    out = out.add_target(cli_selfhost_object_symbol_tests)

    var cli_selfhost_build_w_tests = target_new(.Action, "cli-selfhost-build-w-tests", "").output("out/test-graph/cli-selfhost-build-w-tests")
    cli_selfhost_build_w_tests.action = run_cli_selfhost_build_w_action
    cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.input("out/bin/with-stage2")
    cli_selfhost_build_w_tests = cli_selfhost_build_w_tests.dep("selfcheck")
    out = out.add_target(cli_selfhost_build_w_tests)

    var cli_selfhost_project_tests = target_new(.Action, "cli-selfhost-project-tests", "").output("out/test-graph/cli-selfhost-project-tests")
    cli_selfhost_project_tests.action = run_cli_selfhost_project_action
    cli_selfhost_project_tests = cli_selfhost_project_tests.input("out/bin/with-stage2")
    cli_selfhost_project_tests = cli_selfhost_project_tests.dep("selfcheck")
    out = out.add_target(cli_selfhost_project_tests)

    var cli_selfhost_edge_tests = target_new(.Action, "cli-selfhost-edge-tests", "").output("out/test-graph/cli-selfhost-edge-tests")
    cli_selfhost_edge_tests.action = run_cli_selfhost_edge_action
    cli_selfhost_edge_tests = cli_selfhost_edge_tests.input("out/bin/with-stage2")
    cli_selfhost_edge_tests = cli_selfhost_edge_tests.dep("selfcheck")
    out = out.add_target(cli_selfhost_edge_tests)

    var cli_selfhost_parallel_tests = target_new(.Action, "cli-selfhost-parallel-tests", "").output("out/test-graph/cli-selfhost-parallel-tests")
    cli_selfhost_parallel_tests.action = run_cli_selfhost_parallel_action
    cli_selfhost_parallel_tests = cli_selfhost_parallel_tests.input("out/bin/with-stage2")
    cli_selfhost_parallel_tests = cli_selfhost_parallel_tests.dep("selfcheck")
    out = out.add_target(cli_selfhost_parallel_tests)

    var c_migrator_pcre2_prep_tests = target_new(.Action, "c-migrator-pcre2-prep-tests", "").output("out/test-graph/c-migrator-pcre2-prep-tests")
    c_migrator_pcre2_prep_tests.action = run_cli_selfhost_pcre2_prep_action
    c_migrator_pcre2_prep_tests = c_migrator_pcre2_prep_tests.input("out/bin/with-stage2")
    c_migrator_pcre2_prep_tests = c_migrator_pcre2_prep_tests.write_scope("out/pcre2_tmp")
    c_migrator_pcre2_prep_tests = c_migrator_pcre2_prep_tests.dep("selfcheck")
    out = out.add_target(c_migrator_pcre2_prep_tests)

    var c_migrator_basic_tests = target_new(.Action, "c-migrator-basic-tests", "").output("out/test-graph/c-migrator-basic-tests")
    c_migrator_basic_tests.action = run_cli_selfhost_migrate_basic_action
    c_migrator_basic_tests = c_migrator_basic_tests.input("out/bin/with-stage2")
    c_migrator_basic_tests = c_migrator_basic_tests.dep("selfcheck")
    out = out.add_target(c_migrator_basic_tests)

    var c_migrator_core_tests = target_new(.Action, "c-migrator-core-tests", "").output("out/test-graph/c-migrator-core-tests")
    c_migrator_core_tests.action = run_cli_selfhost_migrate_core_action
    c_migrator_core_tests = c_migrator_core_tests.input("out/bin/with-stage2")
    c_migrator_core_tests = c_migrator_core_tests.dep("selfcheck")
    out = out.add_target(c_migrator_core_tests)

    var c_migrator_tests = target_new(.Group, "c-migrator-tests", "")
    c_migrator_tests = c_migrator_tests.dep("c-migrator-basic-tests")
    c_migrator_tests = c_migrator_tests.dep("c-migrator-core-tests")
    c_migrator_tests = c_migrator_tests.dep("c-migrator-pcre2-prep-tests")
    out = out.add_target(c_migrator_tests)

    var issue61_regression = target_new(.Action, "issue61-regression", "").output("out/test-graph/issue61-regression")
    issue61_regression.action = issue61_regression_action
    issue61_regression = issue61_regression.input("out/bin/with-stage2")
    issue61_regression = issue61_regression.dep("selfcheck")
    out = out.add_target(issue61_regression)

    var embedded_runtime_regression = target_new(.Action, "embedded-runtime-regression", "").output("out/test-graph/embedded-runtime-regression")
    embedded_runtime_regression.action = run_embedded_runtime_regression_action
    embedded_runtime_regression = embedded_runtime_regression.input("out/bin/with")
    embedded_runtime_regression = embedded_runtime_regression.dep("build")
    out = out.add_target(embedded_runtime_regression)

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
    out = out.add_target(tests)

    var install_user = target_new(.Install, "install-user", "out/bin/with").output("$HOME/.local/bin/with")
    install_user = install_user.input("out/bin/with")
    install_user = install_user.arg("0755")
    install_user = install_user.dep("build")
    out = out.add_target(install_user)

    out = out.add_target(install_file_target("install-compiler", "out/bin/with-stage2", "$INSTALL_BINDIR/with", "0755", "stage2"))
    out = out.add_target(install_file_target("install-rt-core", "out/lib/rt_core.o", "$INSTALL_LIBDIR/rt_core.o", "0644", "runtime"))
    out = out.add_target(install_file_target("install-rt-darwin-aarch64", "out/lib/rt_darwin_aarch64.o", "$INSTALL_LIBDIR/rt_darwin_aarch64.o", "0644", "runtime"))
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
    var install = target_new(.Group, "install", "")
    install = install.dep("install-compiler")
    install = install.dep("install-rt-core")
    install = install.dep("install-rt-darwin-aarch64")
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
    out = out.add_target(install)

    var seed = target_new(.Action, "seed", "").output("src/main")
    seed.action = run_seed_download_action
    seed = seed.write_scope("out/tmp")
    seed = seed.arg("withlang-dev/with")
    seed = seed.arg("main")
    out = out.add_target(seed)

    var update_seed = target_new(.Install, "update-seed", "out/bin/with-stage2").output("src/main")
    update_seed = update_seed.input("out/bin/with-stage2")
    update_seed = update_seed.arg("0755")
    update_seed = update_seed.dep("verified-existing-stage")
    out = out.add_target(update_seed)

    var clean = target_new(.Clean, "clean", "")
    clean = clean.arg("out")
    clean = clean.arg(".with")
    clean = clean.arg("src/main.c")
    clean = clean.arg("src/main.o")
    clean = clean.arg("src/bootstrap_main.c")
    clean = clean.arg("src/bootstrap_main.o")
    clean = clean.arg("src/main_emit_temp.c")
    clean = clean.arg("src/main_emit_temp.o")
    clean = clean.arg("main.c")
    clean = clean.arg("main.o")
    clean = clean.arg("bootstrap_main.c")
    clean = clean.arg("bootstrap_main.o")
    clean = clean.arg("main_emit_temp.c")
    clean = clean.arg("main_emit_temp.o")
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

    out.default("verified-existing-stage")
