// std.build — typed build graph construction API.
//
// The compiler driver is responsible for executing build.w in tool mode and
// turning this graph into concrete compiler/linker actions.

extern fn with_eprint(s: str) -> void
extern fn exit(code: i32) -> void
extern fn with_getenv_str(name: str) -> str
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_is_dir(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32

pub enum BuildKind: i32:
    Executable = 0
    Library = 1
    Test = 2
    Object = 3
    Archive = 4
    // Values 5 and 6 were removed with the old GeneratedSource and
    // GeneratedBinary target kinds. Generated sources are graph entries, not
    // targets. Do not reuse these values; old graphs should fail loudly.
    Command = 7
    Install = 8
    Group = 9
    BinaryCompare = 10
    FixpointCompare = 11
    CompileCObject = 12
    CompileAsmObject = 13
    CompileLlvmIrObject = 14
    CreateStaticArchive = 15
    GenerateResponseFile = 16
    EmbedObjectFiles = 17
    CopyTree = 18
    RunCorpusTest = 19
    PromoteTreeIfVerified = 20
    Clean = 21
    CopyFile = 22
    Action = 23

pub enum BuildTarget: i32:
    native = 0
    linux_x86_64 = 1
    linux_aarch64 = 2
    darwin_x86_64 = 3
    darwin_aarch64 = 4
    windows_x86_64 = 5

pub enum OptimizeMode: i32:
    debug = 0
    release = 1

pub type Package {
    name: str,
    version: str,
}

pub type ProjectInfo {
    package: Package,
    root: str,
}

pub type Diagnostics {
    token: str,
}

pub type SourceEmitter {
    token: str,
}

pub type ToolFs {
    token: str,
    root: str,
    write_scope: Vec[str],
    write_scoped: bool,
}

pub type ProcessRunner {
    token: str,
}

pub type ToolProcessResult {
    rc: i32,
    stdout: str,
    stderr: str,
}

pub type BuildCtx {
    token: str,
    project: ProjectInfo,
    diagnostics: Diagnostics,
    source_emitter: SourceEmitter,
    fs: ToolFs,
    process_runner: ProcessRunner,
}

pub type ActionCtx {
    token: str,
    target_name_value: str,
    project: ProjectInfo,
    diagnostics_value: Diagnostics,
    fs_value: ToolFs,
    process_runner_value: ProcessRunner,
    inputs_value: Vec[str],
    outputs_value: Vec[str],
    args_value: Vec[str],
}

fn build_noop_action(ctx: ActionCtx) -> i32:
    0

pub type Target {
    kind: BuildKind,
    name: str,
    entry: str,
    output: str,
    target_kind: BuildTarget,
    optimize_mode: OptimizeMode,
    system_libs: Vec[str],
    include_paths: Vec[str],
    defines: Vec[str],
    inputs: Vec[str],
    deps: Vec[str],
    args: Vec[str],
    action: fn(ActionCtx) -> i32,
}

pub type GeneratedSource {
    path: str,
    contents: str,
}

pub type Build {
    package: Package,
    default_target: str,
    targets: Vec[Target],
    generated_sources: Vec[GeneratedSource],
}

fn tool_capability_valid(token: str) -> bool:
    let expected = with_getenv_str("WITH_TOOL_CAPABILITY_TOKEN")
    expected.len() > 0 and token == expected

fn tool_capability_require(token: str, name: str):
    if not tool_capability_valid(token):
        with_eprint("error: invalid tool capability: " ++ name)
        exit(1)

pub fn BuildCtx.__driver_new(package: Package, root: str, token: str) -> BuildCtx:
    tool_capability_require(token, "BuildCtx")
    BuildCtx {
        token,
        project: ProjectInfo { package, root },
        diagnostics: Diagnostics { token },
        source_emitter: SourceEmitter { token },
        fs: ToolFs { token, root, write_scope: Vec.new(), write_scoped: false },
        process_runner: ProcessRunner { token },
    }

pub fn BuildCtx.project_info(self: &Self) -> ProjectInfo:
    tool_capability_require(self.token, "BuildCtx")
    self.project

pub fn BuildCtx.new_build(self: &Self) -> Build:
    tool_capability_require(self.token, "BuildCtx")
    new_build(self.project.package)

pub fn BuildCtx.diagnostics(self: &Self) -> Diagnostics:
    tool_capability_require(self.token, "Diagnostics")
    self.diagnostics

pub fn BuildCtx.source_emitter(self: &Self) -> SourceEmitter:
    tool_capability_require(self.token, "SourceEmitter")
    self.source_emitter

pub fn BuildCtx.fs(self: &Self) -> ToolFs:
    tool_capability_require(self.token, "ToolFs")
    self.fs

pub fn BuildCtx.process_runner(self: &Self) -> ProcessRunner:
    tool_capability_require(self.token, "ProcessRunner")
    self.process_runner

pub fn ProjectInfo.package_name(self: &Self) -> str:
    self.package.name

pub fn ProjectInfo.package_version(self: &Self) -> str:
    self.package.version

pub fn ProjectInfo.project_root(self: &Self) -> str:
    self.root

pub fn Diagnostics.warn(self: &Self, message: str):
    tool_capability_require(self.token, "Diagnostics")
    with_eprint("warning: " ++ message ++ "\n")

pub fn Diagnostics.error(self: &Self, message: str):
    tool_capability_require(self.token, "Diagnostics")
    with_eprint("error: " ++ message ++ "\n")
    exit(1)

fn tool_path_is_project_relative(path: str) -> bool:
    if path.len() == 0:
        return false
    if path.byte_at(0) == 47:
        return false
    if path.contains(".."):
        return false
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 0 or ch == 9 or ch == 10 or ch == 13:
            return false
    true

fn tool_path_require_project_relative(path: str):
    if not tool_path_is_project_relative(path):
        with_eprint("error: ToolFs path escapes project root: " ++ path ++ "\n")
        exit(1)

fn ToolFs.resolve_path(self: &Self, path: str) -> str:
    tool_capability_require(self.token, "ToolFs")
    tool_path_require_project_relative(path)
    if self.root.len() == 0 or self.root == ".":
        return path
    if self.root.ends_with("/"):
        return self.root ++ path
    self.root ++ "/" ++ path

fn tool_path_is_same_or_child(path: str, root: str) -> bool:
    if path == root:
        return true
    if path.len() <= root.len():
        return false
    path.starts_with(root) and path.byte_at(root.len() as i64) == 47

fn tool_path_is_parent_of(parent: str, child: str) -> bool:
    if parent.len() >= child.len():
        return false
    child.starts_with(parent) and child.byte_at(parent.len() as i64) == 47

fn ToolFs.write_file_allowed(self: &Self, path: str) -> bool:
    if not self.write_scoped:
        return true
    for i in 0..self.write_scope.len() as i32:
        if tool_path_is_same_or_child(path, self.write_scope.get(i as i64)):
            return true
    false

fn ToolFs.mkdir_allowed(self: &Self, path: str) -> bool:
    if not self.write_scoped:
        return true
    for i in 0..self.write_scope.len() as i32:
        let allowed = self.write_scope.get(i as i64)
        if tool_path_is_same_or_child(path, allowed) or tool_path_is_parent_of(path, allowed):
            return true
    false

fn ToolFs.require_write_file_allowed(self: &Self, path: str):
    tool_path_require_project_relative(path)
    if not self.write_file_allowed(path):
        with_eprint("error: ToolFs write path is not a declared action output: " ++ path ++ "\n")
        exit(1)

fn ToolFs.require_mkdir_allowed(self: &Self, path: str):
    tool_path_require_project_relative(path)
    if not self.mkdir_allowed(path):
        with_eprint("error: ToolFs mkdir path is not a declared action output: " ++ path ++ "\n")
        exit(1)

pub fn ToolFs.exists(self: &Self, path: str) -> bool:
    with_fs_file_exists(self.resolve_path(path)) != 0

pub fn ToolFs.is_dir(self: &Self, path: str) -> bool:
    with_fs_is_dir(self.resolve_path(path)) != 0

pub fn ToolFs.mkdir_all(self: &Self, path: str) -> i32:
    self.require_mkdir_allowed(path)
    with_fs_mkdir_p(self.resolve_path(path))

pub fn ToolFs.read_text(self: &Self, path: str) -> str:
    with_fs_read_file(self.resolve_path(path))

pub fn ToolFs.write_text(self: &Self, path: str, contents: str) -> i32:
    self.require_write_file_allowed(path)
    with_fs_write_file(self.resolve_path(path), contents)

pub fn ToolFs.remove_file(self: &Self, path: str) -> i32:
    self.require_write_file_allowed(path)
    with_fs_remove_file(self.resolve_path(path))

pub fn SourceEmitter.generated_source(self: &Self, path: str, contents: str) -> GeneratedSource:
    tool_capability_require(self.token, "SourceEmitter")
    GeneratedSource { path, contents }

fn tool_process_argv(args: Vec[str]) -> str:
    var out = ""
    for i in 0..args.len() as i32:
        out = out ++ args.get(i as i64) ++ "\0"
    out

pub fn ProcessRunner.run_capture(self: &Self, args: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    let rc = with_exec_argv_capture(tool_process_argv(args), stdout_path, stderr_path, timeout_ms)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
    }

pub fn ProcessRunner.run_capture_cwd(self: &Self, args: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    let rc = with_exec_argv_capture_cwd(tool_process_argv(args), stdout_path, stderr_path, timeout_ms, cwd)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
    }

pub fn ActionCtx.target_name(self: &Self) -> str:
    tool_capability_require(self.token, "ActionCtx")
    self.target_name_value

pub fn ActionCtx.project_info(self: &Self) -> ProjectInfo:
    tool_capability_require(self.token, "ActionCtx")
    self.project

pub fn ActionCtx.diagnostics(self: &Self) -> Diagnostics:
    tool_capability_require(self.token, "ActionCtx")
    self.diagnostics_value

pub fn ActionCtx.fs(self: &Self) -> ToolFs:
    tool_capability_require(self.token, "ActionCtx")
    self.fs_value

pub fn ActionCtx.process_runner(self: &Self) -> ProcessRunner:
    tool_capability_require(self.token, "ActionCtx")
    self.process_runner_value

pub fn ActionCtx.inputs(self: &Self) -> Vec[str]:
    tool_capability_require(self.token, "ActionCtx")
    self.inputs_value

pub fn ActionCtx.outputs(self: &Self) -> Vec[str]:
    tool_capability_require(self.token, "ActionCtx")
    self.outputs_value

pub fn ActionCtx.args(self: &Self) -> Vec[str]:
    tool_capability_require(self.token, "ActionCtx")
    self.args_value

pub fn ActionCtx.output(self: &Self) -> str:
    tool_capability_require(self.token, "ActionCtx")
    if self.outputs_value.len() == 0:
        return ""
    self.outputs_value.get(0)

fn build_graph_escape(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:
            out = out ++ "\\\\"
        else if ch == 9:
            out = out ++ "\\t"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

pub fn new_build(package: Package) -> Build:
    Build {
        package,
        default_target: "",
        targets: Vec.new(),
        generated_sources: Vec.new(),
    }

pub fn Build.default(mut self: Build, target_name: str) -> Build:
    self.default_target = target_name
    self

pub fn target_new(kind: BuildKind, name: str, entry: str) -> Target:
    Target {
        kind,
        name,
        entry,
        output: "",
        target_kind: BuildTarget.native,
        optimize_mode: OptimizeMode.debug,
        system_libs: Vec.new(),
        include_paths: Vec.new(),
        defines: Vec.new(),
        inputs: Vec.new(),
        deps: Vec.new(),
        args: Vec.new(),
        action: build_noop_action,
    }

pub fn Build.add_target(mut self: Build, target: Target) -> Build:
    self.targets.push(target)
    self

pub fn Build.generated_source(mut self: Build, path: str, contents: str) -> Build:
    self.generated_sources.push(GeneratedSource { path, contents })
    self

pub fn Build.add_generated_source(mut self: Build, source: GeneratedSource) -> Build:
    self.generated_sources.push(source)
    self

pub fn Build.executable(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Executable, name, entry)
    self.add_target(target)

pub fn Build.library(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Library, name, entry)
    self.add_target(target)

pub fn Build.test(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Test, name, entry)
    self.add_target(target)

pub fn Build.object(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Object, name, entry)
    self.add_target(target)

pub fn Build.archive(self: Build, name: str, entry: str) -> Build:
    let target = target_new(.Archive, name, entry)
    self.add_target(target)

pub fn Build.action(self: Build, name: str, action: fn(ActionCtx) -> i32) -> Build:
    var target = target_new(.Action, name, "")
    target.action = action
    self.add_target(target)

pub fn Build.command(self: Build, name: str, runner: str) -> Build:
    let target = target_new(.Command, name, runner)
    self.add_target(target)

pub fn Build.install(self: Build, name: str, source: str, dest: str) -> Build:
    let target = target_new(.Install, name, source).output(dest)
    self.add_target(target)

pub fn Build.group(self: Build, name: str) -> Build:
    let target = target_new(.Group, name, "")
    self.add_target(target)

pub fn Build.binary_compare(self: Build, name: str, left: str, right: str) -> Build:
    var target = target_new(.BinaryCompare, name, left)
    target = target.arg(right)
    self.add_target(target)

pub fn Build.fixpoint_compare(self: Build, name: str, left: str, right: str) -> Build:
    var target = target_new(.FixpointCompare, name, left)
    target = target.arg(right)
    self.add_target(target)

pub fn Build.compile_c_object(self: Build, name: str, source: str, output: str) -> Build:
    let target = target_new(.CompileCObject, name, source).output(output)
    self.add_target(target)

pub fn Build.compile_asm_object(self: Build, name: str, source: str, output: str) -> Build:
    let target = target_new(.CompileAsmObject, name, source).output(output)
    self.add_target(target)

pub fn Build.compile_llvm_ir_object(self: Build, name: str, source: str, output: str) -> Build:
    let target = target_new(.CompileLlvmIrObject, name, source).output(output)
    self.add_target(target)

pub fn Build.create_static_archive(self: Build, name: str, output: str) -> Build:
    let target = target_new(.CreateStaticArchive, name, "").output(output)
    self.add_target(target)

pub fn Build.generate_response_file(self: Build, name: str, output: str) -> Build:
    let target = target_new(.GenerateResponseFile, name, "").output(output)
    self.add_target(target)

pub fn Build.embed_object_files(self: Build, name: str, output: str) -> Build:
    let target = target_new(.EmbedObjectFiles, name, "").output(output)
    self.add_target(target)

pub fn Build.copy_tree(self: Build, name: str, source_dir: str, output_dir: str) -> Build:
    let target = target_new(.CopyTree, name, source_dir).output(output_dir)
    self.add_target(target)

pub fn Build.copy_file(self: Build, name: str, source: str, dest: str) -> Build:
    let target = target_new(.CopyFile, name, source).output(dest)
    self.add_target(target)

pub fn Build.clean(self: Build, name: str) -> Build:
    let target = target_new(.Clean, name, "")
    self.add_target(target)

pub fn Build.run_corpus_test(self: Build, name: str, runner: str) -> Build:
    let target = target_new(.RunCorpusTest, name, runner)
    self.add_target(target)

pub fn Build.promote_tree_if_verified(self: Build, name: str, source_dir: str, output_dir: str) -> Build:
    let target = target_new(.PromoteTreeIfVerified, name, source_dir).output(output_dir)
    self.add_target(target)

pub fn Target.target(self: Target, target: BuildTarget) -> Target:
    Target {
        kind: self.kind,
        name: self.name,
        entry: self.entry,
        output: self.output,
        target_kind: target,
        optimize_mode: self.optimize_mode,
        system_libs: self.system_libs,
        include_paths: self.include_paths,
        defines: self.defines,
        inputs: self.inputs,
        deps: self.deps,
        args: self.args,
        action: self.action,
    }

pub fn Target.optimize(self: Target, mode: OptimizeMode) -> Target:
    Target {
        kind: self.kind,
        name: self.name,
        entry: self.entry,
        output: self.output,
        target_kind: self.target_kind,
        optimize_mode: mode,
        system_libs: self.system_libs,
        include_paths: self.include_paths,
        defines: self.defines,
        inputs: self.inputs,
        deps: self.deps,
        args: self.args,
        action: self.action,
    }

pub fn Target.link_system_lib(mut self: Target, lib: str) -> Target:
    self.system_libs.push(lib)
    self

pub fn Target.include_path(mut self: Target, path: str) -> Target:
    self.include_paths.push(path)
    self

pub fn Target.define(mut self: Target, define: str) -> Target:
    self.defines.push(define)
    self

pub fn Target.output(self: Target, output: str) -> Target:
    Target {
        kind: self.kind,
        name: self.name,
        entry: self.entry,
        output,
        target_kind: self.target_kind,
        optimize_mode: self.optimize_mode,
        system_libs: self.system_libs,
        include_paths: self.include_paths,
        defines: self.defines,
        inputs: self.inputs,
        deps: self.deps,
        args: self.args,
        action: self.action,
    }

pub fn Target.input(mut self: Target, input: str) -> Target:
    self.inputs.push(input)
    self

pub fn Target.dep(mut self: Target, dep: str) -> Target:
    self.deps.push(dep)
    self

pub fn Target.arg(mut self: Target, arg: str) -> Target:
    self.args.push(arg)
    self

pub fn Target.compiler(mut self: Target, compiler: str) -> Target:
    self.args.push("compiler=" ++ compiler)
    self

fn build_action_outputs(target: Target) -> Vec[str]:
    let outputs: Vec[str] = Vec.new()
    if target.output.len() > 0:
        outputs.push(target.output)
    outputs

fn build_action_ctx(ctx: BuildCtx, target: Target) -> ActionCtx:
    let fs_outputs = build_action_outputs(target)
    let ctx_outputs = build_action_outputs(target)
    ActionCtx {
        token: ctx.token,
        target_name_value: target.name,
        project: ctx.project,
        diagnostics_value: ctx.diagnostics,
        fs_value: ToolFs { token: ctx.token, root: ctx.fs.root, write_scope: fs_outputs, write_scoped: true },
        process_runner_value: ctx.process_runner,
        inputs_value: target.inputs,
        outputs_value: ctx_outputs,
        args_value: target.args,
    }

pub fn Build.__driver_run_action(self: Build, ctx: BuildCtx, action_name: str) -> i32:
    tool_capability_require(ctx.token, "ActionCtx")
    for i in 0..self.targets.len() as i32:
        let target = self.targets.get(i as i64)
        if target.name == action_name:
            if target.kind != .Action:
                with_eprint("error: build action target '" ++ action_name ++ "' is not an Action target\n")
                return 1
            return target.action(build_action_ctx(ctx, target))
    with_eprint("error: build action target not found: " ++ action_name ++ "\n")
    1

pub fn __driver_action_name() -> str:
    with_getenv_str("WITH_BUILD_ACTION_NAME")

pub fn __driver_exit(code: i32):
    exit(code)

pub fn Build.emit_graph(self: Build) -> str:
    var out = "WITH_BUILD_GRAPH\t2\n"
    out = out ++ "package\t" ++ build_graph_escape(self.package.name) ++ "\t" ++ build_graph_escape(self.package.version) ++ "\n"
    if self.default_target.len() > 0:
        out = out ++ "default_target\t" ++ build_graph_escape(self.default_target) ++ "\n"
    for gi in 0..self.generated_sources.len() as i32:
        let generated = self.generated_sources.get(gi as i64)
        out = out ++ "generated_source\t" ++ build_graph_escape(generated.path) ++ "\t" ++ build_graph_escape(generated.contents) ++ "\n"
    for ti in 0..self.targets.len() as i32:
        let target = self.targets.get(ti as i64)
        out = out ++ "target\t"
        out = out ++ f"{target.kind as i32}\t"
        out = out ++ build_graph_escape(target.name) ++ "\t"
        out = out ++ build_graph_escape(target.entry) ++ "\t"
        out = out ++ f"{target.target_kind as i32}\t"
        out = out ++ f"{target.optimize_mode as i32}\t"
        out = out ++ build_graph_escape(target.output) ++ "\n"
        for li in 0..target.system_libs.len() as i32:
            out = out ++ "system_lib\t" ++ f"{ti}\t" ++ build_graph_escape(target.system_libs.get(li as i64)) ++ "\n"
        for ii in 0..target.include_paths.len() as i32:
            out = out ++ "include_path\t" ++ f"{ti}\t" ++ build_graph_escape(target.include_paths.get(ii as i64)) ++ "\n"
        for di in 0..target.defines.len() as i32:
            out = out ++ "define\t" ++ f"{ti}\t" ++ build_graph_escape(target.defines.get(di as i64)) ++ "\n"
        for ini in 0..target.inputs.len() as i32:
            out = out ++ "input\t" ++ f"{ti}\t" ++ build_graph_escape(target.inputs.get(ini as i64)) ++ "\n"
        for depi in 0..target.deps.len() as i32:
            out = out ++ "dep\t" ++ f"{ti}\t" ++ build_graph_escape(target.deps.get(depi as i64)) ++ "\n"
        for ai in 0..target.args.len() as i32:
            out = out ++ "arg\t" ++ f"{ti}\t" ++ build_graph_escape(target.args.get(ai as i64)) ++ "\n"
    out
