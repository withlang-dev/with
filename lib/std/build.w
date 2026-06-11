// std.build — typed build graph construction API.
//
// The compiler driver is responsible for executing build.w in tool mode and
// turning this graph into concrete compiler/linker actions.

extern fn with_eprint(s: str) -> void
extern fn exit(code: i32) -> void
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_is_dir(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_chmod(path: str, mode: i32) -> i32
extern fn with_fs_copy_tree(src: str, dst: str) -> i32
extern fn with_fs_list_files(path: str) -> str
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_remove_tree(path: str) -> i32
extern fn with_fs_rename_file(old_path: str, new_path: str) -> i32
extern fn with_fs_symlink(target: str, link_path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_exec_argv(args: str) -> i32
extern fn with_exec_argv_capture(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32) -> i32
extern fn with_exec_argv_capture_cwd(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> i32
extern fn with_exec_argv_capture_input(args: str, stdout_path: str, stderr_path: str, timeout_ms: i32, stdin_path: str) -> i32
extern fn with_exec_argv_capture_spawn(args: str, stdout_path: str, stderr_path: str) -> i32
extern fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32

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

pub enum BuildOutputKind: i32:
    Binary = 0
    Object = 1
    C = 2
    LlvmIr = 3
    Archive = 4
    Check = 5

pub enum PreludeMode: i32:
    Full = 0
    Core = 1
    None = 2

pub enum OverflowMode: i32:
    Default = -1
    Panic = 0
    Wrap = 1
    Saturate = 2

pub type BuildOptions {
    source_path: str,
    output_path: str,
    output_kind: BuildOutputKind,
    opt_level: i32,
    debug_info: bool,
    no_std: bool,
    alloc_mode: bool,
    prelude_mode: PreludeMode,
    overflow_mode: OverflowMode,
    deterministic: bool,
    target: BuildTarget,
    include_paths: Vec[str],
    defines: Vec[str],
    link_libs: Vec[str],
    compiler_hooks_enabled: bool,
}

pub type TestOptions {
    filter: str,
    verbose: bool,
    quiet: bool,
}

pub type BuildGraphOptions {
    selected_target: str,
    graph_only: bool,
    dry_run: bool,
    no_deps: bool,
}

pub type MigrateOptions {
    source_path: str,
    output_path: str,
    include_paths: Vec[str],
    forced_includes: Vec[str],
    defines: Vec[str],
    exclude_basenames: Vec[str],
    check_mode: bool,
    diff_mode: bool,
    stats_mode: bool,
    no_c_export: bool,
    c_export_functions: bool,
    convert_goto_to_structured: bool,
    block_style: i32,
    width_slice: i32,
    shared_defs: str,
    migrate_one: str,
    shared_fragment: str,
    ir_roundtrip: bool,
}

pub enum BuildStatus: i32:
    ok = 0
    failed = 1
    crashed = 2
    cancelled = 3

pub enum ArtifactKind: i32:
    executable = 0
    object = 1
    static_library = 2
    dynamic_library = 3
    c_source = 4
    llvm_ir = 5
    diagnostics = 6
    source_tree = 7

pub type SourceSpan {
    file: str,
    start: i32,
    end: i32,
    line: i32,
    column: i32,
}

pub type DiagnosticSummary {
    severity: str,
    message: str,
    source: SourceSpan,
}

pub type Artifact {
    kind: ArtifactKind,
    path: str,
}

pub type BuildResult {
    status: BuildStatus,
    rc: i32,
    workspace_name: str,
    artifacts: Vec[Artifact],
    diagnostics: Vec[DiagnosticSummary],
}

pub enum DeclKind: i32:
    function = 0
    type_decl = 1
    global_decl = 2
    method = 3
    trait_decl = 4
    impl_decl = 5

pub type DeclSummary {
    version: i32,
    kind: DeclKind,
    module_name: str,
    name: str,
    qualified_name: str,
    public_value: bool,
    docs: str,
    type_text: str,
    return_type_text: str,
    param_count: i32,
    generic_param_count: i32,
    receiver_type_text: str,
    source: SourceSpan,
    notes: Vec[str],
}

pub enum CompilerPhase: i32:
    pre_parse = 0
    parsed = 1
    pre_typecheck = 2
    typechecked = 3
    lowered_to_mir = 4
    pre_codegen = 5
    codegen_done = 6
    pre_link = 7
    linked = 8
    complete = 9

pub type EnvVar {
    name: str,
    value: str,
}

pub type LinkCommand {
    linker: str,
    args: Vec[str],
    cwd: str,
    env: Vec[EnvVar],
    inputs: Vec[str],
    outputs: Vec[str],
}

pub enum CompilerMessage:
    Phase(CompilerPhase)
    File(str)
    Import(str, str)
    Typechecked(Vec[DeclSummary])
    Diagnostic(DiagnosticSummary)
    Artifact(Artifact)
    PreLink(LinkCommand)
    Linked(LinkCommand, i32)
    Complete(BuildResult)
    Error(i32, str, SourceSpan)
    DebugDump(str)

pub type CompilerMessageEnvelope {
    workspace_name: str,
    generation: i32,
    message: CompilerMessage,
}

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

pub type Workspace ephemeral {
    token: str,
    id: i32,
}

pub type ProcessEnvVar {
    name: str,
    value: str,
}

pub type ProcessEnv {
    vars: Vec[ProcessEnvVar],
}

pub type ProcessSpec {
    executable: str,
    args: Vec[str],
    cwd: str,
    env: ProcessEnv,
    timeout_ms: i32,
    stdin_path: str,
    capture_stdout: bool,
    capture_stderr: bool,
}

pub fn process_spec(executable: str) -> ProcessSpec:
    ProcessSpec {
        executable,
        args: Vec.new(),
        cwd: "",
        env: ProcessEnv { vars: Vec.new() },
        timeout_ms: 0,
        stdin_path: "",
        capture_stdout: true,
        capture_stderr: true,
    }

pub type ToolProcessResult {
    rc: i32,
    stdout: str,
    stderr: str,
    timed_out: bool,
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
    timeout_ms_value: i32,
    cwd_value: str,
    env_value: Vec[str],
    network_value: bool,
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
    extra_outputs: Vec[str],
    write_scopes: Vec[str],
    deps: Vec[str],
    args: Vec[str],
    action: fn(ActionCtx) -> i32,
    timeout_ms: i32,
    cwd: str,
    env: Vec[str],
    network: bool,
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

pub fn BuildCtx.env_input(self: &Self, name: str) -> str:
    tool_capability_require(self.token, "BuildCtx")
    with_getenv_str(name)

pub fn BuildCtx.create_workspace(self: &Self, name: str) -> Workspace:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: BuildCtx.create_workspace requires compiler driver comptime evaluation\n")
    exit(1)
    Workspace { self.token, -1 }

pub fn BuildCtx.current_workspace(self: &Self) -> Workspace:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: BuildCtx.current_workspace requires compiler driver comptime evaluation\n")
    exit(1)
    Workspace { self.token, -1 }

pub fn ActionCtx.create_workspace(self: &Self, name: str) -> Workspace:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: ActionCtx.create_workspace requires compiler driver comptime evaluation\n")
    exit(1)
    Workspace { self.token, -1 }

pub fn ActionCtx.current_workspace(self: &Self) -> Workspace:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: ActionCtx.current_workspace requires compiler driver comptime evaluation\n")
    exit(1)
    Workspace { self.token, -1 }

pub fn Workspace.name(self: &Self) -> str:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.name requires compiler driver comptime evaluation\n")
    exit(1)
    ""

pub fn Workspace.add_file(self: &Self, path: str) -> void:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.add_file requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.add_string(self: &Self, name: str, source: str) -> void:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.add_string requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.options(self: &Self) -> BuildOptions:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.options requires compiler driver comptime evaluation\n")
    exit(1)
    BuildOptions {
        source_path: "",
        output_path: "",
        output_kind: BuildOutputKind.Binary,
        opt_level: 1,
        debug_info: true,
        no_std: false,
        alloc_mode: false,
        prelude_mode: PreludeMode.Full,
        overflow_mode: OverflowMode.Default,
        deterministic: false,
        target: BuildTarget.native,
        include_paths: Vec.new(),
        defines: Vec.new(),
        link_libs: Vec.new(),
        compiler_hooks_enabled: true,
    }

pub fn Workspace.set_options(self: &Self, options: BuildOptions) -> void:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.set_options requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.set_migrate_options(self: &Self, options: MigrateOptions) -> void:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.set_migrate_options requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.compile(self: &Self) -> BuildResult:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.compile requires compiler driver comptime evaluation\n")
    exit(1)
    BuildResult {
        status: BuildStatus.failed,
        rc: 1,
        workspace_name: "",
        artifacts: Vec.new(),
        diagnostics: Vec.new(),
    }

pub fn Workspace.begin_intercept(self: &Self) -> void:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.begin_intercept requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.wait_for_message(self: &Self) -> CompilerMessageEnvelope:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.wait_for_message requires compiler driver comptime evaluation\n")
    exit(1)
    CompilerMessageEnvelope {
        workspace_name: "",
        generation: 0,
        message: CompilerMessage.Error(1, "Workspace.wait_for_message requires compiler driver comptime evaluation", SourceSpan { file: "", start: -1, end: -1, line: -1, column: -1 }),
    }

pub fn Workspace.end_intercept(self: &Self) -> void:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.end_intercept requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.set_link_command(self: &Self, command: LinkCommand) -> void:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.set_link_command requires compiler driver comptime evaluation\n")
    exit(1)

pub fn parallel(workspaces: Vec[Workspace]) -> Vec[BuildResult]:
    with_eprint("error: parallel requires compiler driver comptime evaluation\n")
    exit(1)
    Vec.new()

pub fn process_env() -> ProcessEnv:
    ProcessEnv { vars: Vec.new() }

pub fn ProcessEnv.set(self: ProcessEnv, name: str, value: str) -> ProcessEnv:
    var vars = self.vars
    vars.push(ProcessEnvVar { name, value })
    ProcessEnv { vars }

pub fn ProjectInfo.package_name(self: &Self) -> str:
    self.package.name

pub fn ProjectInfo.package_version(self: &Self) -> str:
    self.package.version

pub fn ProjectInfo.project_root(self: &Self) -> str:
    self.root

pub fn Diagnostics.warn(self: &Self, message: str) -> void:
    tool_capability_require(self.token, "Diagnostics")
    with_eprint("warning: " ++ message ++ "\n")

pub fn Diagnostics.error(self: &Self, message: str) -> void:
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

fn tool_path_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn tool_path_normalize(path: str) -> str:
    if path.len() == 0:
        return "."
    let parts: Vec[str] = Vec.new()
    var start = 0
    var is_absolute = path.byte_at(0) == 47 or path.byte_at(0) == 92
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 47 or ch == 92:
            if i > start:
                let part = path.slice(start as i64, i as i64)
                if part == "..":
                    if parts.len() > 0 and parts.get(parts.len() - 1) != "..":
                        parts.pop()
                    else if not is_absolute:
                        parts.push(part)
                else if part != ".":
                    parts.push(part)
            start = i + 1
    if start < path.len() as i32:
        let part = path.slice(start as i64, path.len() as i64)
        if part == "..":
            if parts.len() > 0 and parts.get(parts.len() - 1) != "..":
                parts.pop()
            else if not is_absolute:
                parts.push(part)
        else if part != ".":
            parts.push(part)
    if parts.len() == 0:
        if is_absolute:
            return "/"
        return "."
    var result = ""
    if is_absolute:
        result = "/"
    for i in 0..parts.len() as i32:
        if i > 0:
            result = result ++ "/"
        result = result ++ parts.get(i as i64)
    result

fn tool_split_by_slash(path: str) -> Vec[str]:
    let parts: Vec[str] = Vec.new()
    var start = 0
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 47 or ch == 92:
            if i > start:
                parts.push(path.slice(start as i64, i as i64))
            start = i + 1
    if start < path.len() as i32:
        parts.push(path.slice(start as i64, path.len()))
    parts

fn tool_glob_segment_matches(pattern: str, name: str) -> bool:
    var star = -1
    for i in 0..pattern.len() as i32:
        if pattern.byte_at(i as i64) == 42:
            if star >= 0:
                return false
            star = i
    if star < 0:
        return pattern == name
    let prefix = pattern.slice(0, star as i64)
    let suffix = pattern.slice((star + 1) as i64, pattern.len())
    if name.len() < prefix.len() + suffix.len():
        return false
    if prefix.len() > 0 and name.slice(0, prefix.len()) != prefix:
        return false
    if suffix.len() > 0:
        let suffix_start = name.len() - suffix.len()
        if name.slice(suffix_start, name.len()) != suffix:
            return false
    true

fn tool_glob_segments_match(pat_segs: Vec[str], pi: i32, file_segs: Vec[str], fi: i32) -> bool:
    if pi >= pat_segs.len() as i32:
        return fi >= file_segs.len() as i32
    let seg = pat_segs.get(pi as i64)
    if seg == "**":
        var k = fi
        while k <= file_segs.len() as i32:
            if tool_glob_segments_match(pat_segs, pi + 1, file_segs, k):
                return true
            k = k + 1
        return false
    if fi >= file_segs.len() as i32:
        return false
    if not tool_glob_segment_matches(seg, file_segs.get(fi as i64)):
        return false
    tool_glob_segments_match(pat_segs, pi + 1, file_segs, fi + 1)

fn tool_glob_str_compare(a: str, b: str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    var i = 0
    while i < min_len as i32:
        let ac = a.byte_at(i as i64)
        let bc = b.byte_at(i as i64)
        if ac != bc:
            return ac - bc
        i = i + 1
    if a.len() == b.len():
        return 0
    if a.len() < b.len():
        return -1
    1

fn tool_glob_sort(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and tool_glob_str_compare(item, existing) < 0:
                out.push(item)
                inserted = true
            out.push(existing)
        if not inserted:
            out.push(item)
        sorted = out
    sorted

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

fn tool_split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if i > start:
                lines.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start < text.len() as i32:
        lines.push(text.slice(start as i64, text.len()))
    lines

fn ToolFs.project_relative_path(self: &Self, path: str) -> str:
    let normalized = tool_path_normalize(path)
    if self.root.len() == 0 or self.root == ".":
        return normalized
    let root = tool_path_normalize(self.root)
    let prefix = if root.ends_with("/"): root else: root ++ "/"
    if normalized.starts_with(prefix):
        return normalized.slice(prefix.len(), normalized.len())
    normalized

pub fn ToolFs.exists(self: &Self, path: str) -> bool:
    with_fs_file_exists(self.resolve_path(path)) != 0

pub fn ToolFs.host_exists(self: &Self, path: str) -> bool:
    tool_capability_require(self.token, "ToolFs")
    with_fs_file_exists(path) != 0

pub fn ToolFs.host_list_files(self: &Self, path: str) -> Vec[str]:
    tool_capability_require(self.token, "ToolFs")
    tool_split_nonempty_lines(with_fs_list_files(path))

pub fn ToolFs.is_dir(self: &Self, path: str) -> bool:
    with_fs_is_dir(self.resolve_path(path)) != 0

pub fn ToolFs.mkdir_all(self: &Self, path: str) -> i32:
    self.require_mkdir_allowed(path)
    with_fs_mkdir_p(self.resolve_path(path))

pub fn ToolFs.read_text(self: &Self, path: str) -> str:
    with_fs_read_file(self.resolve_path(path))

pub fn ToolFs.read_binary(self: &Self, path: str) -> Vec[u8]:
    let resolved = self.resolve_path(path)
    let data = with_fs_read_file(resolved)
    let result: Vec[u8] = Vec.new()
    for i in 0..data.len() as i32:
        result.push(data.byte_at(i as i64) as u8)
    result

pub fn ToolFs.list_files(self: &Self, path: str) -> Vec[str]:
    let resolved = self.resolve_path(path)
    let raw_files = tool_split_nonempty_lines(with_fs_list_files(resolved))
    let files: Vec[str] = Vec.new()
    for i in 0..raw_files.len() as i32:
        files.push(self.project_relative_path(raw_files.get(i as i64)))
    files

pub fn ToolFs.glob(self: &Self, pattern: str) -> Vec[str]:
    var last_clean_slash = -1
    var has_glob = false
    for i in 0..pattern.len() as i32:
        let c = pattern.byte_at(i as i64)
        if c == 42:
            has_glob = true
            break
        if c == 47:
            last_clean_slash = i
    if not has_glob:
        with_eprint("error: glob pattern contains no wildcards: " ++ pattern ++ "\n")
        exit(1)
    let base_dir = if last_clean_slash < 0: "." else: pattern.slice(0, last_clean_slash as i64)
    let glob_suffix = if last_clean_slash < 0: pattern else: pattern.slice((last_clean_slash + 1) as i64, pattern.len())
    let all_files = self.list_files(base_dir)
    let pat_segs = tool_split_by_slash(glob_suffix)
    let results: Vec[str] = Vec.new()
    let prefix = if base_dir == ".": "" else: base_dir ++ "/"
    for i in 0..all_files.len() as i32:
        let file = all_files.get(i as i64)
        let rel = if prefix.len() > 0 and file.starts_with(prefix): file.slice(prefix.len(), file.len()) else: file
        let file_segs = tool_split_by_slash(rel)
        if tool_glob_segments_match(pat_segs, 0, file_segs, 0):
            results.push(file)
    if results.len() == 0:
        with_eprint("error: glob pattern matched no files: " ++ pattern ++ "\n")
        exit(1)
    tool_glob_sort(results)

pub fn ToolFs.write_text(self: &Self, path: str, contents: str) -> i32:
    self.require_write_file_allowed(path)
    with_fs_write_file(self.resolve_path(path), contents)

pub fn ToolFs.write_binary(self: &Self, path: str, bytes: Vec[u8]) -> i32:
    self.require_write_file_allowed(path)
    let _ = bytes.len()
    with_fs_write_file(self.resolve_path(path), "")

pub fn ToolFs.copy_file(self: &Self, src: str, dst: str) -> i32:
    tool_path_require_project_relative(src)
    self.require_write_file_allowed(dst)
    let dst_dir = tool_path_dirname(dst)
    if dst_dir != ".":
        self.require_mkdir_allowed(dst_dir)
        let mkdir_rc = with_fs_mkdir_p(self.resolve_path(dst_dir))
        if mkdir_rc != 0:
            return mkdir_rc
    let contents = with_fs_read_file(self.resolve_path(src))
    with_fs_write_file(self.resolve_path(dst), contents)

pub fn ToolFs.chmod(self: &Self, path: str, mode: i32) -> i32:
    self.require_write_file_allowed(path)
    with_fs_chmod(self.resolve_path(path), mode)

pub fn ToolFs.rename(self: &Self, old_path: str, new_path: str) -> i32:
    self.require_write_file_allowed(old_path)
    self.require_write_file_allowed(new_path)
    with_fs_rename_file(self.resolve_path(old_path), self.resolve_path(new_path))

pub fn ToolFs.remove_file(self: &Self, path: str) -> i32:
    self.require_write_file_allowed(path)
    with_fs_remove_file(self.resolve_path(path))

pub fn ToolFs.remove_tree(self: &Self, path: str) -> i32:
    self.require_write_file_allowed(path)
    with_fs_remove_tree(self.resolve_path(path))

pub fn ToolFs.copy_tree(self: &Self, src: str, dst: str) -> i32:
    tool_path_require_project_relative(src)
    self.require_write_file_allowed(dst)
    with_fs_copy_tree(self.resolve_path(src), self.resolve_path(dst))

pub fn ToolFs.symlink(self: &Self, target: str, link_path: str) -> i32:
    tool_path_require_project_relative(target)
    self.require_write_file_allowed(link_path)
    with_fs_symlink(self.resolve_path(target), self.resolve_path(link_path))

pub fn ToolFs.normalize(self: &Self, path: str) -> str:
    tool_path_normalize(path)

pub fn ToolFs.join(self: &Self, base: str, child: str) -> str:
    if base.len() == 0:
        return child
    if child.len() == 0:
        return base
    if base.ends_with("/"):
        base ++ child
    else:
        base ++ "/" ++ child

pub fn SourceEmitter.generated_source(self: &Self, path: str, contents: str) -> GeneratedSource:
    tool_capability_require(self.token, "SourceEmitter")
    GeneratedSource { path, contents }

fn tool_process_argv(args: Vec[str]) -> str:
    var out = StringBuilder.new()
    for i in 0..args.len() as i32:
        out.push_str(args.get(i as i64))
        out.push_byte(0)
    out.to_str()

type ToolProcessEnv {
    tool_token: str,
    action_name: str,
}

type SavedProcessEnv {
    driver: ToolProcessEnv,
    names: Vec[str],
    values: Vec[str],
}

fn tool_process_clear_driver_env() -> ToolProcessEnv:
    let tool_token = with_getenv_str("WITH_TOOL_CAPABILITY_TOKEN") ++ ""
    let action_name = with_getenv_str("WITH_BUILD_ACTION_NAME") ++ ""
    let env = ToolProcessEnv {
        tool_token,
        action_name,
    }
    let _clear_tool_token = with_setenv_str("WITH_TOOL_CAPABILITY_TOKEN", "")
    let _clear_action_name = with_setenv_str("WITH_BUILD_ACTION_NAME", "")
    env

fn tool_process_restore_driver_env(env: ToolProcessEnv):
    let _restore_action_name = with_setenv_str("WITH_BUILD_ACTION_NAME", env.action_name)
    let _restore_tool_token = with_setenv_str("WITH_TOOL_CAPABILITY_TOKEN", env.tool_token)

fn tool_process_apply_env(env: ProcessEnv) -> SavedProcessEnv:
    let driver = tool_process_clear_driver_env()
    let names: Vec[str] = Vec.new()
    let values: Vec[str] = Vec.new()
    for i in 0..env.vars.len() as i32:
        let item = env.vars.get(i as i64)
        names.push(item.name)
        values.push(with_getenv_str(item.name) ++ "")
        let _set = with_setenv_str(item.name, item.value)
    SavedProcessEnv { driver, names, values }

fn tool_process_restore_env(saved: SavedProcessEnv):
    for i in 0..saved.names.len() as i32:
        let _restore = with_setenv_str(saved.names.get(i as i64), saved.values.get(i as i64))
    tool_process_restore_driver_env(saved.driver)

pub fn ProcessRunner.run_capture(self: &Self, args: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    let env = tool_process_clear_driver_env()
    let rc = with_exec_argv_capture(tool_process_argv(args), stdout_path, stderr_path, timeout_ms)
    tool_process_restore_driver_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.run(self: &Self, args: Vec[str]) -> i32:
    tool_capability_require(self.token, "ProcessRunner")
    let env = tool_process_clear_driver_env()
    let rc = with_exec_argv(tool_process_argv(args))
    tool_process_restore_driver_env(env)
    rc

pub fn ProcessRunner.run_capture_with_env(self: &Self, args: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, process_env: ProcessEnv) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    let env = tool_process_apply_env(process_env)
    let rc = with_exec_argv_capture(tool_process_argv(args), stdout_path, stderr_path, timeout_ms)
    tool_process_restore_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.run_capture_cwd(self: &Self, args: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    let env = tool_process_clear_driver_env()
    let rc = with_exec_argv_capture_cwd(tool_process_argv(args), stdout_path, stderr_path, timeout_ms, cwd)
    tool_process_restore_driver_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.run_capture_cwd_with_env(self: &Self, args: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str, process_env: ProcessEnv) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    let env = tool_process_apply_env(process_env)
    let rc = with_exec_argv_capture_cwd(tool_process_argv(args), stdout_path, stderr_path, timeout_ms, cwd)
    tool_process_restore_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.run_capture_input(self: &Self, args: Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, stdin_path: str) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    let env = tool_process_clear_driver_env()
    let rc = with_exec_argv_capture_input(tool_process_argv(args), stdout_path, stderr_path, timeout_ms, stdin_path)
    tool_process_restore_driver_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.spawn_capture(self: &Self, args: Vec[str], stdout_path: str, stderr_path: str) -> i32:
    tool_capability_require(self.token, "ProcessRunner")
    let env = tool_process_clear_driver_env()
    let pid = with_exec_argv_capture_spawn(tool_process_argv(args), stdout_path, stderr_path)
    tool_process_restore_driver_env(env)
    pid

pub fn ProcessRunner.wait(self: &Self, pid: i32, timeout_ms: i32) -> i32:
    tool_capability_require(self.token, "ProcessRunner")
    with_exec_wait(pid, timeout_ms)

pub fn ProcessRunner.run_spec(self: &Self, spec: ProcessSpec, stdout_path: str, stderr_path: str) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    let full_args: Vec[str] = Vec.new()
    full_args.push(spec.executable)
    for i in 0..spec.args.len() as i32:
        full_args.push(spec.args.get(i as i64))
    let timeout = if spec.timeout_ms > 0: spec.timeout_ms else: 0
    if spec.env.vars.len() > 0:
        if spec.cwd.len() > 0:
            return self.run_capture_cwd_with_env(full_args, stdout_path, stderr_path, timeout, spec.cwd, spec.env)
        return self.run_capture_with_env(full_args, stdout_path, stderr_path, timeout, spec.env)
    if spec.cwd.len() > 0:
        return self.run_capture_cwd(full_args, stdout_path, stderr_path, timeout, spec.cwd)
    if spec.stdin_path.len() > 0:
        return self.run_capture_input(full_args, stdout_path, stderr_path, timeout, spec.stdin_path)
    self.run_capture(full_args, stdout_path, stderr_path, timeout)

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

pub fn ActionCtx.timeout(self: &Self) -> i32:
    tool_capability_require(self.token, "ActionCtx")
    self.timeout_ms_value

pub fn ActionCtx.working_dir(self: &Self) -> str:
    tool_capability_require(self.token, "ActionCtx")
    self.cwd_value

pub fn ActionCtx.env(self: &Self) -> Vec[str]:
    tool_capability_require(self.token, "ActionCtx")
    self.env_value

pub fn ActionCtx.network(self: &Self) -> bool:
    tool_capability_require(self.token, "ActionCtx")
    self.network_value

pub fn ActionCtx.env_input(self: &Self, name: str) -> str:
    tool_capability_require(self.token, "ActionCtx")
    with_getenv_str(name)

fn build_graph_escape(value: str) -> str:
    var out = StringBuilder.with_capacity(value.len())
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:
            out.push_str("\\\\")
        else if ch == 9:
            out.push_str("\\t")
        else if ch == 10:
            out.push_str("\\n")
        else if ch == 13:
            out.push_str("\\r")
        else:
            out.push_str(value.slice(i as i64, (i + 1) as i64))
    out.to_str()

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
        extra_outputs: Vec.new(),
        write_scopes: Vec.new(),
        deps: Vec.new(),
        args: Vec.new(),
        action: build_noop_action,
        timeout_ms: 0,
        cwd: "",
        env: Vec.new(),
        network: false,
    }

pub fn Target.timeout(mut self: Target, ms: i32) -> Target:
    self.timeout_ms = ms
    self

pub fn Target.working_dir(mut self: Target, path: str) -> Target:
    self.cwd = path
    self

pub fn Target.with_env(mut self: Target, key: str, value: str) -> Target:
    self.env.push(key ++ "=" ++ value)
    self

pub fn Target.allow_network(mut self: Target) -> Target:
    self.network = true
    self

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

pub type Download {
    url: str,
    sha256: str,
    output_path: str,
}

pub fn Build.download(self: Build, name: str, spec: Download) -> Build:
    var target = target_new(.Action, name, "").output(spec.output_path)
    target.action = build_download_action
    target = target.write_scope(build_path_dirname(spec.output_path))
    target = target.write_scope("out/command/" ++ name)
    target = target.arg(spec.url)
    target = target.arg(spec.sha256)
    self.add_target(target)

pub fn Build.extract_tar_gz(self: Build, name: str, archive: str, output_dir: str) -> Build:
    var target = target_new(.Action, name, "").output(output_dir)
    target.action = build_extract_tar_gz_action
    target = target.input(archive)
    target = target.write_scope(output_dir)
    target = target.write_scope("out/command/" ++ name)
    self.add_target(target)

fn build_path_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn build_download_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let proc = ctx.process_runner()
    let args = ctx.args()
    let output_path = ctx.output()
    if args.len() < 2 or output_path.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": download requires url, sha256, and output")
        return 1
    let url = args.get(0)
    let sha256 = args.get(1)
    let output_dir = build_path_dirname(output_path)
    if fs.mkdir_all(output_dir) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not create directory: " ++ output_dir)
        return 1
    let cmd_dir = "out/command/" ++ ctx.target_name()
    fs.mkdir_all(cmd_dir)
    let tmp_path = output_path ++ ".download.tmp"
    let curl_args: Vec[str] = Vec.new()
    curl_args.push("curl")
    curl_args.push("-L")
    curl_args.push("--fail")
    curl_args.push("--show-error")
    curl_args.push("--output")
    curl_args.push(tmp_path)
    curl_args.push(url)
    let stdout_path = cmd_dir ++ "/stdout"
    let stderr_path = cmd_dir ++ "/stderr"
    let result = proc.run_capture(curl_args, stdout_path, stderr_path, 300000)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": curl failed (rc=" ++ f"{result.rc}" ++ ")")
        return 1
    if sha256.len() > 0:
        let sum_args: Vec[str] = Vec.new()
        sum_args.push("shasum")
        sum_args.push("-a")
        sum_args.push("256")
        sum_args.push(tmp_path)
        let sum_result = proc.run_capture(sum_args, cmd_dir ++ "/sha.stdout", cmd_dir ++ "/sha.stderr", 30000)
        if sum_result.rc != 0:
            ctx.diagnostics().error(ctx.target_name() ++ ": shasum failed")
            return 1
        let actual = sum_result.stdout.slice(0, 64)
        if actual != sha256:
            ctx.diagnostics().error(ctx.target_name() ++ ": sha256 mismatch: expected " ++ sha256 ++ " got " ++ actual)
            let _ = fs.remove_file(tmp_path)
            return 1
    else:
        ctx.diagnostics().warn(ctx.target_name() ++ ": no sha256 checksum specified for download")
    if fs.rename(tmp_path, output_path) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not publish: " ++ output_path)
        return 1
    0

fn build_extract_tar_gz_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let proc = ctx.process_runner()
    let inputs = ctx.inputs()
    let output_dir = ctx.output()
    if inputs.len() == 0 or output_dir.len() == 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": extract requires archive input and output dir")
        return 1
    let archive = inputs.get(0)
    fs.mkdir_all(output_dir)
    let cmd_dir = "out/command/" ++ ctx.target_name()
    fs.mkdir_all(cmd_dir)
    let tar_args: Vec[str] = Vec.new()
    tar_args.push("tar")
    tar_args.push("xzf")
    tar_args.push(archive)
    tar_args.push("-C")
    tar_args.push(output_dir)
    let result = proc.run_capture(tar_args, cmd_dir ++ "/stdout", cmd_dir ++ "/stderr", 120000)
    if result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": tar extraction failed (rc=" ++ f"{result.rc}" ++ ")")
        return 1
    0

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
        extra_outputs: self.extra_outputs,
        write_scopes: self.write_scopes,
        deps: self.deps,
        args: self.args,
        action: self.action,
        timeout_ms: self.timeout_ms,
        cwd: self.cwd,
        env: self.env,
        network: self.network,
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
        extra_outputs: self.extra_outputs,
        write_scopes: self.write_scopes,
        deps: self.deps,
        args: self.args,
        action: self.action,
        timeout_ms: self.timeout_ms,
        cwd: self.cwd,
        env: self.env,
        network: self.network,
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
        extra_outputs: self.extra_outputs,
        write_scopes: self.write_scopes,
        deps: self.deps,
        args: self.args,
        action: self.action,
        timeout_ms: self.timeout_ms,
        cwd: self.cwd,
        env: self.env,
        network: self.network,
    }

pub fn Target.input(mut self: Target, input: str) -> Target:
    self.inputs.push(input)
    self

pub fn Target.extra_output(mut self: Target, path: str) -> Target:
    self.extra_outputs.push(path)
    self

pub fn Target.write_scope(mut self: Target, path: str) -> Target:
    self.write_scopes.push(path)
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
    for i in 0..target.extra_outputs.len() as i32:
        outputs.push(target.extra_outputs.get(i as i64))
    outputs

fn build_action_write_scope(target: Target) -> Vec[str]:
    let scopes = build_action_outputs(target)
    for i in 0..target.write_scopes.len() as i32:
        scopes.push(target.write_scopes.get(i as i64))
    scopes

fn build_action_ctx(ctx: BuildCtx, target: Target) -> ActionCtx:
    let fs_outputs = build_action_write_scope(target)
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
        timeout_ms_value: target.timeout_ms,
        cwd_value: target.cwd,
        env_value: target.env,
        network_value: target.network,
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

pub fn __driver_exit(code: i32) -> void:
    exit(code)

pub fn Build.emit_graph(self: Build) -> str:
    var out = StringBuilder.new()
    out.push_str("WITH_BUILD_GRAPH\t2\n")
    out.push_str("package\t")
    out.push_str(build_graph_escape(self.package.name))
    out.push_str("\t")
    out.push_str(build_graph_escape(self.package.version))
    out.push_str("\n")
    if self.default_target.len() > 0:
        out.push_str("default_target\t")
        out.push_str(build_graph_escape(self.default_target))
        out.push_str("\n")
    for gi in 0..self.generated_sources.len() as i32:
        let generated = self.generated_sources.get(gi as i64)
        out.push_str("generated_source\t")
        out.push_str(build_graph_escape(generated.path))
        out.push_str("\t")
        out.push_str(build_graph_escape(generated.contents))
        out.push_str("\n")
    for ti in 0..self.targets.len() as i32:
        let target = self.targets.get(ti as i64)
        out.push_str("target\t")
        out.push_str(f"{target.kind as i32}\t")
        out.push_str(build_graph_escape(target.name))
        out.push_str("\t")
        out.push_str(build_graph_escape(target.entry))
        out.push_str("\t")
        out.push_str(f"{target.target_kind as i32}\t")
        out.push_str(f"{target.optimize_mode as i32}\t")
        out.push_str(build_graph_escape(target.output))
        out.push_str("\n")
        for li in 0..target.system_libs.len() as i32:
            out.push_str("system_lib\t")
            out.push_str(f"{ti}\t")
            out.push_str(build_graph_escape(target.system_libs.get(li as i64)))
            out.push_str("\n")
        for ii in 0..target.include_paths.len() as i32:
            out.push_str("include_path\t")
            out.push_str(f"{ti}\t")
            out.push_str(build_graph_escape(target.include_paths.get(ii as i64)))
            out.push_str("\n")
        for di in 0..target.defines.len() as i32:
            out.push_str("define\t")
            out.push_str(f"{ti}\t")
            out.push_str(build_graph_escape(target.defines.get(di as i64)))
            out.push_str("\n")
        for ini in 0..target.inputs.len() as i32:
            out.push_str("input\t")
            out.push_str(f"{ti}\t")
            out.push_str(build_graph_escape(target.inputs.get(ini as i64)))
            out.push_str("\n")
        for outi in 0..target.extra_outputs.len() as i32:
            out.push_str("extra_output\t")
            out.push_str(f"{ti}\t")
            out.push_str(build_graph_escape(target.extra_outputs.get(outi as i64)))
            out.push_str("\n")
        for depi in 0..target.deps.len() as i32:
            out.push_str("dep\t")
            out.push_str(f"{ti}\t")
            out.push_str(build_graph_escape(target.deps.get(depi as i64)))
            out.push_str("\n")
        for ai in 0..target.args.len() as i32:
            out.push_str("arg\t")
            out.push_str(f"{ti}\t")
            out.push_str(build_graph_escape(target.args.get(ai as i64)))
            out.push_str("\n")
    out.to_str()
