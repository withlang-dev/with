// std.build — typed build graph construction API.
//
// The compiler driver is responsible for executing build.w in tool mode and
// turning this graph into concrete compiler/linker actions.

use std.crypto.sha256

extern fn with_eprint(s: str) -> Unit
extern fn exit(code: i32) -> Unit
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_sysinfo_os() -> str
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
    scratch_path: str,
}

pub type ProcessRunner {
    token: str,
    root: str,
    target_name: str,
    write_scope: Vec[str],
    write_scoped: bool,
    network: bool,
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

pub enum ArchiveEntryKind: i32:
    File = 0
    Directory = 1
    Symlink = 2

pub type ArchiveEntry {
    kind: ArchiveEntryKind,
    source_path: str,
    archive_path: str,
    mode: i32,
}

pub fn archive_file_entry(source_path: str, archive_path: str, mode: i32) -> ArchiveEntry:
    ArchiveEntry {
        kind: ArchiveEntryKind.File,
        source_path,
        archive_path,
        mode,
    }

pub fn archive_dir_entry(archive_path: str, mode: i32) -> ArchiveEntry:
    ArchiveEntry {
        kind: ArchiveEntryKind.Directory,
        source_path: "",
        archive_path,
        mode,
    }

pub fn archive_symlink_entry(target: str, archive_path: str, mode: i32) -> ArchiveEntry:
    ArchiveEntry {
        kind: ArchiveEntryKind.Symlink,
        source_path: target,
        archive_path,
        mode,
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

pub fn ProcessSpec.arg(self: ProcessSpec, value: str) -> ProcessSpec:
    var args = self.args
    args.push(value)
    ProcessSpec { executable: self.executable, args, cwd: self.cwd, env: self.env, timeout_ms: self.timeout_ms, stdin_path: self.stdin_path, capture_stdout: self.capture_stdout, capture_stderr: self.capture_stderr }

pub fn ProcessSpec.working_dir(self: ProcessSpec, path: str) -> ProcessSpec:
    ProcessSpec { executable: self.executable, args: self.args, cwd: path, env: self.env, timeout_ms: self.timeout_ms, stdin_path: self.stdin_path, capture_stdout: self.capture_stdout, capture_stderr: self.capture_stderr }

pub fn ProcessSpec.timeout(self: ProcessSpec, ms: i32) -> ProcessSpec:
    ProcessSpec { executable: self.executable, args: self.args, cwd: self.cwd, env: self.env, timeout_ms: ms, stdin_path: self.stdin_path, capture_stdout: self.capture_stdout, capture_stderr: self.capture_stderr }

pub fn ProcessSpec.stdin(self: ProcessSpec, path: str) -> ProcessSpec:
    ProcessSpec { executable: self.executable, args: self.args, cwd: self.cwd, env: self.env, timeout_ms: self.timeout_ms, stdin_path: path, capture_stdout: self.capture_stdout, capture_stderr: self.capture_stderr }

pub fn ProcessSpec.env_var(self: ProcessSpec, name: str, value: str) -> ProcessSpec:
    let env = self.env.set(name, value)
    ProcessSpec { executable: self.executable, args: self.args, cwd: self.cwd, env, timeout_ms: self.timeout_ms, stdin_path: self.stdin_path, capture_stdout: self.capture_stdout, capture_stderr: self.capture_stderr }

pub fn ProcessSpec.capture(self: ProcessSpec, stdout: bool, stderr: bool) -> ProcessSpec:
    ProcessSpec { executable: self.executable, args: self.args, cwd: self.cwd, env: self.env, timeout_ms: self.timeout_ms, stdin_path: self.stdin_path, capture_stdout: stdout, capture_stderr: stderr }

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

fn tool_safe_label(text: str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        let keep = (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 45 or ch == 46 or ch == 95
        if keep:
            out.push_byte(ch)
        else:
            out.push_byte(95)
    let result = out.to_str()
    if result.len() == 0:
        return "unknown"
    result

fn tool_action_scratch_dir(target_name: str) -> str:
    "out/tmp/action-scratch/" ++ tool_safe_label(target_name)

pub fn BuildCtx.__driver_new(package: Package, root: str, token: str) -> BuildCtx:
    tool_capability_require(token, "BuildCtx")
    BuildCtx {
        token,
        project: ProjectInfo { package, root },
        diagnostics: Diagnostics { token },
        source_emitter: SourceEmitter { token },
        fs: ToolFs { token, root, write_scope: Vec.new(), write_scoped: false, scratch_path: "" },
        process_runner: ProcessRunner { token, root, target_name: "", write_scope: Vec.new(), write_scoped: false, network: false },
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

pub fn Workspace.add_file(self: &Self, path: str) -> Unit:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.add_file requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.add_string(self: &Self, name: str, source: str) -> Unit:
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

pub fn Workspace.set_options(self: &Self, options: BuildOptions) -> Unit:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.set_options requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.set_migrate_options(self: &Self, options: MigrateOptions) -> Unit:
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

pub fn Workspace.begin_intercept(self: &Self) -> Unit:
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

pub fn Workspace.end_intercept(self: &Self) -> Unit:
    tool_capability_require(self.token, "Workspace")
    with_eprint("error: Workspace.end_intercept requires compiler driver comptime evaluation\n")
    exit(1)

pub fn Workspace.set_link_command(self: &Self, command: LinkCommand) -> Unit:
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

pub fn Diagnostics.warn(self: &Self, message: str) -> Unit:
    tool_capability_require(self.token, "Diagnostics")
    with_eprint("warning: " ++ message ++ "\n")

pub fn Diagnostics.error(self: &Self, message: str) -> Unit:
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

pub fn ToolFs.host_read_text(self: &Self, path: str) -> str:
    tool_capability_require(self.token, "ToolFs")
    with_fs_read_file(path)

fn tool_sha256_text(data: str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

pub fn ToolFs.sha256_file(self: &Self, path: str) -> str:
    if not self.exists(path):
        return ""
    tool_sha256_text(self.read_text(path))

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
    var out = StringBuilder.with_capacity(bytes.len())
    for i in 0..bytes.len() as i32:
        out.push_byte(bytes.get(i as i64))
    with_fs_write_file(self.resolve_path(path), out.to_str())

fn tool_tar_append_zeroes(mut out: Vec[u8], count: i64) -> Vec[u8]:
    var i: i64 = 0
    while i < count:
        out.push(0 as u8)
        i = i + 1
    out

fn tool_tar_append_bytes(mut out: Vec[u8], bytes: &Vec[u8]) -> Vec[u8]:
    for i in 0..bytes.len() as i32:
        out.push(bytes.get(i as i64))
    out

fn tool_tar_append_str_padded(mut out: Vec[u8], value: str, width: i64) -> Vec[u8]:
    if value.len() > width:
        return Vec.new()
    for i in 0..value.len() as i32:
        out.push(value.byte_at(i as i64) as u8)
    var pad = value.len()
    while pad < width:
        out.push(0 as u8)
        pad = pad + 1
    out

fn tool_tar_octal_digits(value: i64) -> str:
    if value == 0:
        return "0"
    var v = value
    var rev = StringBuilder.new()
    while v > 0:
        rev.push_byte((48 + (v % 8) as i32) as u8)
        v = v / 8
    let reversed = rev.to_str()
    var out = StringBuilder.with_capacity(reversed.len())
    var i = reversed.len()
    while i > 0:
        i = i - 1
        out.push_byte(reversed.byte_at(i) as u8)
    out.to_str()

fn tool_tar_append_octal_nul(mut out: Vec[u8], value: i64, width: i64) -> Vec[u8]:
    if value < 0:
        return Vec.new()
    let digits = tool_tar_octal_digits(value)
    if digits.len() + 1 > width:
        return Vec.new()
    var pad = digits.len() + 1
    while pad < width:
        out.push(48 as u8)
        pad = pad + 1
    for i in 0..digits.len() as i32:
        out.push(digits.byte_at(i as i64) as u8)
    out.push(0 as u8)
    out

fn tool_tar_append_checksum(mut out: Vec[u8], checksum: i64) -> Vec[u8]:
    let digits = tool_tar_octal_digits(checksum)
    if digits.len() > 6:
        return Vec.new()
    var pad = digits.len()
    while pad < 6:
        out.push(48 as u8)
        pad = pad + 1
    for i in 0..digits.len() as i32:
        out.push(digits.byte_at(i as i64) as u8)
    out.push(0 as u8)
    out.push(32 as u8)
    out

fn tool_tar_sum(bytes: &Vec[u8]) -> i64:
    var sum: i64 = 0
    for i in 0..bytes.len() as i32:
        sum = sum + bytes.get(i as i64) as i64
    sum

fn tool_tar_entry_name(path: str, directory: bool) -> str:
    if path.len() == 0 or (not directory and path.ends_with("/")):
        return ""
    let normalized = tool_path_normalize(path)
    if normalized == ".":
        return ""
    tool_path_require_project_relative(normalized)
    let result = if directory: normalized ++ "/" else: normalized
    if result.len() > 100:
        return ""
    result

fn tool_tar_link_name(target: str) -> str:
    if target.len() == 0 or target.len() > 100:
        return ""
    if not tool_path_is_project_relative(target):
        return ""
    target

fn tool_tar_link_target_safe(output_dir: str, output_path: str, target: str) -> bool:
    if target.len() == 0:
        return false
    if target.byte_at(0) == 47 or target.byte_at(0) == 92:
        return false
    if target.len() >= 3 and target.byte_at(1) == 58 and (target.byte_at(2) == 47 or target.byte_at(2) == 92):
        return false
    for i in 0..target.len() as i32:
        let ch = target.byte_at(i as i64)
        if ch == 0 or ch == 9 or ch == 10 or ch == 13:
            return false
    let parent = tool_path_dirname(output_path)
    let resolved = tool_path_normalize(parent ++ "/" ++ target)
    if not tool_path_is_project_relative(resolved):
        return false
    let root = tool_path_normalize(output_dir)
    if root == ".":
        return true
    tool_path_is_same_or_child(resolved, root)

fn tool_tar_extract_fail(message: str) -> i32:
    with_eprint("error: ToolFs.extract_tar: " ++ message ++ "\n")
    1

fn tool_tar_build_header(name: str, mode: i32, size: i64, kind: ArchiveEntryKind, link_name: str) -> Vec[u8]:
    if name.len() == 0 or name.len() > 100 or mode < 0 or size < 0 or link_name.len() > 100:
        return Vec.new()
    var prefix: Vec[u8] = Vec.new()
    prefix = tool_tar_append_str_padded(prefix, name, 100)
    prefix = tool_tar_append_octal_nul(prefix, mode as i64, 8)
    prefix = tool_tar_append_octal_nul(prefix, 0, 8)
    prefix = tool_tar_append_octal_nul(prefix, 0, 8)
    prefix = tool_tar_append_octal_nul(prefix, size, 12)
    prefix = tool_tar_append_octal_nul(prefix, 0, 12)
    if prefix.len() == 0:
        return Vec.new()
    var suffix: Vec[u8] = Vec.new()
    if kind == ArchiveEntryKind.Directory:
        suffix.push(53 as u8)
    else if kind == ArchiveEntryKind.Symlink:
        suffix.push(50 as u8)
    else:
        suffix.push(48 as u8)
    suffix = tool_tar_append_str_padded(suffix, link_name, 100)
    suffix = tool_tar_append_str_padded(suffix, "ustar", 6)
    suffix = tool_tar_append_str_padded(suffix, "00", 2)
    suffix = tool_tar_append_zeroes(suffix, 247)
    if suffix.len() == 0:
        return Vec.new()
    let checksum = tool_tar_sum(&prefix) + 256 + tool_tar_sum(&suffix)
    var header: Vec[u8] = Vec.new()
    header = tool_tar_append_bytes(header, &prefix)
    header = tool_tar_append_checksum(header, checksum)
    header = tool_tar_append_bytes(header, &suffix)
    if header.len() != 512:
        return Vec.new()
    header

fn ToolFs.tar_bytes(self: &Self, entries: &Vec[ArchiveEntry]) -> Vec[u8]:
    var out: Vec[u8] = Vec.new()
    for i in 0..entries.len() as i32:
        let entry = entries.get(i as i64)
        if entry.kind == ArchiveEntryKind.Directory:
            let name = tool_tar_entry_name(entry.archive_path, true)
            let header = tool_tar_build_header(name, entry.mode, 0, ArchiveEntryKind.Directory, "")
            if header.len() == 0:
                return Vec.new()
            out = tool_tar_append_bytes(out, &header)
        else if entry.kind == ArchiveEntryKind.Symlink:
            let name = tool_tar_entry_name(entry.archive_path, false)
            let link_name = tool_tar_link_name(entry.source_path)
            let header = tool_tar_build_header(name, entry.mode, 0, ArchiveEntryKind.Symlink, link_name)
            if header.len() == 0:
                return Vec.new()
            out = tool_tar_append_bytes(out, &header)
        else:
            if entry.source_path.len() == 0:
                return Vec.new()
            tool_path_require_project_relative(entry.source_path)
            let name = tool_tar_entry_name(entry.archive_path, false)
            let contents = self.read_binary(entry.source_path)
            let header = tool_tar_build_header(name, entry.mode, contents.len(), ArchiveEntryKind.File, "")
            if header.len() == 0:
                return Vec.new()
            out = tool_tar_append_bytes(out, &header)
            out = tool_tar_append_bytes(out, &contents)
            let padding = (512 - (contents.len() % 512)) % 512
            out = tool_tar_append_zeroes(out, padding)
    out = tool_tar_append_zeroes(out, 1024)
    out

fn tool_gzip_append_u16_le(mut out: Vec[u8], value: i32) -> Vec[u8]:
    out.push((value & 0xff) as u8)
    out.push(((value >> 8) & 0xff) as u8)
    out

fn tool_gzip_append_u32_le(mut out: Vec[u8], value: u32) -> Vec[u8]:
    out.push((value & (0xff as u32)) as u8)
    out.push(((value >> (8 as u32)) & (0xff as u32)) as u8)
    out.push(((value >> (16 as u32)) & (0xff as u32)) as u8)
    out.push(((value >> (24 as u32)) & (0xff as u32)) as u8)
    out

fn tool_gzip_crc32(bytes: &Vec[u8]) -> u32:
    var crc = 0xffffffff as u32
    for i in 0..bytes.len() as i32:
        var c = (crc ^ (bytes.get(i as i64) as u32)) & (0xff as u32)
        var bit = 0
        while bit < 8:
            if (c & (1 as u32)) != 0 as u32:
                c = (c >> (1 as u32)) ^ (0xedb88320 as u32)
            else:
                c = c >> (1 as u32)
            bit = bit + 1
        crc = (crc >> (8 as u32)) ^ c
    crc ^ (0xffffffff as u32)

fn tool_gzip_stored(bytes: &Vec[u8]) -> Vec[u8]:
    var out: Vec[u8] = Vec.new()
    out.push(31 as u8)
    out.push(139 as u8)
    out.push(8 as u8)
    out.push(0 as u8)
    out = tool_gzip_append_u32_le(out, 0 as u32)
    out.push(0 as u8)
    out.push(255 as u8)
    var offset: i64 = 0
    if bytes.len() == 0:
        out.push(1 as u8)
        out = tool_gzip_append_u16_le(out, 0)
        out = tool_gzip_append_u16_le(out, 0xffff)
    while offset < bytes.len():
        let remaining = bytes.len() - offset
        let chunk = if remaining > 65535: 65535 else: remaining
        let final_block = offset + chunk == bytes.len()
        out.push(if final_block: 1 as u8 else: 0 as u8)
        out = tool_gzip_append_u16_le(out, chunk as i32)
        out = tool_gzip_append_u16_le(out, 0xffff - chunk as i32)
        var i: i64 = 0
        while i < chunk:
            out.push(bytes.get(offset + i))
            i = i + 1
        offset = offset + chunk
    out = tool_gzip_append_u32_le(out, tool_gzip_crc32(bytes))
    out = tool_gzip_append_u32_le(out, bytes.len() as u32)
    out

pub fn ToolFs.write_tar(self: &Self, output_path: str, entries: &Vec[ArchiveEntry]) -> i32:
    self.require_write_file_allowed(output_path)
    let out = self.tar_bytes(entries)
    if out.len() == 0:
        return 1
    self.write_binary(output_path, out)

pub fn ToolFs.write_tar_gz(self: &Self, output_path: str, entries: &Vec[ArchiveEntry]) -> i32:
    self.require_write_file_allowed(output_path)
    let tar = self.tar_bytes(entries)
    if tar.len() == 0:
        return 1
    self.write_binary(output_path, tool_gzip_stored(&tar))

fn tool_tar_block_is_zero(bytes: &Vec[u8], offset: i64) -> bool:
    if offset + 512 > bytes.len():
        return false
    var i: i64 = 0
    while i < 512:
        if bytes.get(offset + i) != 0 as u8:
            return false
        i = i + 1
    true

fn tool_tar_field_str(bytes: &Vec[u8], offset: i64, width: i64) -> str:
    var out = StringBuilder.new()
    var i: i64 = 0
    while i < width:
        let b = bytes.get(offset + i)
        if b == 0 as u8:
            return out.to_str()
        out.push_byte(b)
        i = i + 1
    out.to_str()

fn tool_tar_parse_octal(bytes: &Vec[u8], offset: i64, width: i64) -> i64:
    var value: i64 = 0
    var i: i64 = 0
    while i < width:
        let b = bytes.get(offset + i)
        if b != 0 as u8 and b != 32 as u8:
            if b < 48 as u8 or b > 55 as u8:
                return -1
            value = value * 8 + (b as i64 - 48)
        i = i + 1
    value

fn tool_tar_header_checksum(bytes: &Vec[u8], offset: i64) -> i64:
    var sum: i64 = 0
    var i: i64 = 0
    while i < 512:
        if i >= 148 and i < 156:
            sum = sum + 32
        else:
            sum = sum + bytes.get(offset + i) as i64
        i = i + 1
    sum

fn tool_tar_magic_ok(bytes: &Vec[u8], offset: i64) -> bool:
    let ustar = bytes.get(offset + 257) == 117 as u8 and
        bytes.get(offset + 258) == 115 as u8 and
        bytes.get(offset + 259) == 116 as u8 and
        bytes.get(offset + 260) == 97 as u8 and
        bytes.get(offset + 261) == 114 as u8
    if ustar:
        return true
    var i: i64 = 257
    while i < 265:
        if bytes.get(offset + i) != 0 as u8:
            return false
        i = i + 1
    true

fn tool_tar_archive_name_safe(name: str) -> bool:
    if name.len() == 0:
        return false
    tool_path_is_project_relative(name)

fn tool_tar_header_name(bytes: &Vec[u8], offset: i64) -> str:
    let name = tool_tar_field_str(bytes, offset, 100)
    let prefix = tool_tar_field_str(bytes, offset + 345, 155)
    if prefix.len() == 0:
        return name
    prefix ++ "/" ++ name

fn tool_tar_payload_text(bytes: &Vec[u8], offset: i64, size: i64) -> str:
    var out = StringBuilder.with_capacity(size)
    var i: i64 = 0
    while i < size:
        out.push_byte(bytes.get(offset + i))
        i = i + 1
    out.to_str()

fn tool_tar_trim_payload_name(text: str) -> str:
    var end = text.len() as i32
    while end > 0:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 0 and ch != 10 and ch != 13:
            break
        end = end - 1
    text.slice(0, end as i64)

fn tool_pax_parse_decimal(text: str, start: i32, end: i32) -> i32:
    if start >= end:
        return -1
    var value = 0
    var i = start
    while i < end:
        let ch = text.byte_at(i as i64)
        if ch < 48 or ch > 57:
            return -1
        value = value * 10 + (ch - 48)
        i = i + 1
    value

fn tool_pax_value(text: str, key: str) -> str:
    var pos = 0
    while pos < text.len() as i32:
        var space = pos
        while space < text.len() as i32 and text.byte_at(space as i64) != 32:
            space = space + 1
        if space >= text.len() as i32:
            return ""
        let record_len = tool_pax_parse_decimal(text, pos, space)
        if record_len <= 0 or pos + record_len > text.len() as i32:
            return ""
        let record_start = space + 1
        let record_end = pos + record_len
        var eq = record_start
        while eq < record_end and text.byte_at(eq as i64) != 61:
            eq = eq + 1
        if eq < record_end:
            let name = text.slice(record_start as i64, eq as i64)
            if name == key:
                var value_end = record_end
                while value_end > eq + 1:
                    let ch = text.byte_at((value_end - 1) as i64)
                    if ch != 10 and ch != 13:
                        break
                    value_end = value_end - 1
                return text.slice((eq + 1) as i64, value_end as i64)
        pos = record_end
    ""

pub fn ToolFs.extract_tar(self: &Self, archive_path: str, output_dir: str) -> i32:
    tool_path_require_project_relative(archive_path)
    if self.mkdir_all(output_dir) != 0:
        return tool_tar_extract_fail("could not create output directory: " ++ output_dir)
    let archive = self.read_binary(archive_path)
    var offset: i64 = 0
    var pending_path = ""
    var pending_link = ""
    while offset + 512 <= archive.len():
        if tool_tar_block_is_zero(&archive, offset):
            return 0
        if not tool_tar_magic_ok(&archive, offset):
            return tool_tar_extract_fail(f"invalid tar magic at offset {offset}")
        let stored_checksum = tool_tar_parse_octal(&archive, offset + 148, 8)
        if stored_checksum < 0 or stored_checksum != tool_tar_header_checksum(&archive, offset):
            return tool_tar_extract_fail(f"invalid header checksum at offset {offset}")
        let mode = tool_tar_parse_octal(&archive, offset + 100, 8)
        let size = tool_tar_parse_octal(&archive, offset + 124, 12)
        if mode < 0 or size < 0:
            return tool_tar_extract_fail(f"invalid numeric field at offset {offset}")
        let typeflag = archive.get(offset + 156)
        let content_start = offset + 512
        if content_start + size > archive.len():
            return tool_tar_extract_fail(f"entry payload extends past archive at offset {offset}")
        let padded = ((size + 511) / 512) * 512
        if typeflag == 120 as u8:
            let pax = tool_tar_payload_text(&archive, content_start, size)
            let pax_path = tool_pax_value(pax, "path")
            let pax_link = tool_pax_value(pax, "linkpath")
            if pax_path.len() > 0:
                pending_path = pax_path
            if pax_link.len() > 0:
                pending_link = pax_link
            offset = offset + 512 + padded
            continue
        if typeflag == 103 as u8:
            offset = offset + 512 + padded
            continue
        if typeflag == 76 as u8:
            pending_path = tool_tar_trim_payload_name(tool_tar_payload_text(&archive, content_start, size))
            offset = offset + 512 + padded
            continue
        let raw_name = if pending_path.len() > 0: pending_path else: tool_tar_header_name(&archive, offset)
        pending_path = ""
        if not tool_tar_archive_name_safe(raw_name):
            return tool_tar_extract_fail("unsafe archive path: " ++ raw_name)
        let name = tool_path_normalize(raw_name)
        let output_path = self.join(output_dir, name)
        if typeflag == 53 as u8:
            if self.mkdir_all(output_path) != 0:
                return tool_tar_extract_fail("could not create directory entry: " ++ output_path)
            if mode > 0:
                let _ = self.chmod(output_path, mode as i32)
        else if typeflag == 50 as u8:
            let link_name = if pending_link.len() > 0: pending_link else: tool_tar_field_str(&archive, offset + 157, 100)
            pending_link = ""
            if not tool_tar_link_target_safe(output_dir, output_path, link_name):
                return tool_tar_extract_fail("unsafe symlink target for " ++ output_path ++ ": " ++ link_name)
            let output_parent = tool_path_dirname(output_path)
            if output_parent != "." and self.mkdir_all(output_parent) != 0:
                return tool_tar_extract_fail("could not create parent directory for symlink: " ++ output_parent)
            if not self.write_file_allowed(output_path):
                return tool_tar_extract_fail("symlink path is outside declared write scope: " ++ output_path)
            if with_fs_symlink(link_name, self.resolve_path(output_path)) != 0:
                return tool_tar_extract_fail("could not create symlink: " ++ output_path)
        else if typeflag == 48 as u8 or typeflag == 0 as u8:
            let output_parent = tool_path_dirname(output_path)
            if output_parent != "." and self.mkdir_all(output_parent) != 0:
                return tool_tar_extract_fail("could not create parent directory for file: " ++ output_parent)
            var payload: Vec[u8] = Vec[u8].with_capacity(size)
            var pi: i64 = 0
            while pi < size:
                payload.push(archive.get(content_start + pi))
                pi = pi + 1
            if self.write_binary(output_path, payload) != 0:
                return tool_tar_extract_fail("could not write file entry: " ++ output_path)
            if mode > 0:
                let _ = self.chmod(output_path, mode as i32)
        else:
            return tool_tar_extract_fail(f"unsupported tar entry type {typeflag as i32} for " ++ raw_name)
        offset = offset + 512 + padded
    tool_tar_extract_fail("archive ended without two zero blocks")

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

pub fn ToolFs.scratch_dir(self: &Self) -> str:
    tool_capability_require(self.token, "ToolFs")
    if self.scratch_path.len() == 0:
        with_eprint("error: ToolFs.scratch_dir is only available inside an action\n")
        exit(1)
    self.scratch_path

pub fn SourceEmitter.generated_source(self: &Self, path: str, contents: str) -> GeneratedSource:
    tool_capability_require(self.token, "SourceEmitter")
    GeneratedSource { path, contents }

fn tool_process_argv(args: &Vec[str]) -> str:
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

pub fn ProcessRunner.run_capture(self: &Self, args: &Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    self.require_network_allowed(args, "run_capture")
    self.require_capture_allowed(stdout_path, stderr_path, "run_capture")
    let env = tool_process_clear_driver_env()
    let rc = with_exec_argv_capture(tool_process_argv(args), stdout_path, stderr_path, timeout_ms)
    tool_process_restore_driver_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.run(self: &Self, args: &Vec[str]) -> i32:
    tool_capability_require(self.token, "ProcessRunner")
    self.require_network_allowed(args, "run")
    let env = tool_process_clear_driver_env()
    let rc = with_exec_argv(tool_process_argv(args))
    tool_process_restore_driver_env(env)
    rc

pub fn ProcessRunner.run_capture_with_env(self: &Self, args: &Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, process_env: ProcessEnv) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    self.require_network_allowed(args, "run_capture_with_env")
    self.require_capture_allowed(stdout_path, stderr_path, "run_capture_with_env")
    let env = tool_process_apply_env(process_env)
    let rc = with_exec_argv_capture(tool_process_argv(args), stdout_path, stderr_path, timeout_ms)
    tool_process_restore_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.run_capture_cwd(self: &Self, args: &Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    self.require_network_allowed(args, "run_capture_cwd")
    self.require_capture_allowed(stdout_path, stderr_path, "run_capture_cwd")
    let env = tool_process_clear_driver_env()
    let rc = with_exec_argv_capture_cwd(tool_process_argv(args), stdout_path, stderr_path, timeout_ms, cwd)
    tool_process_restore_driver_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.run_capture_cwd_with_env(self: &Self, args: &Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, cwd: str, process_env: ProcessEnv) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    self.require_network_allowed(args, "run_capture_cwd_with_env")
    self.require_capture_allowed(stdout_path, stderr_path, "run_capture_cwd_with_env")
    let env = tool_process_apply_env(process_env)
    let rc = with_exec_argv_capture_cwd(tool_process_argv(args), stdout_path, stderr_path, timeout_ms, cwd)
    tool_process_restore_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.run_capture_input(self: &Self, args: &Vec[str], stdout_path: str, stderr_path: str, timeout_ms: i32, stdin_path: str) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    self.require_network_allowed(args, "run_capture_input")
    self.require_capture_allowed(stdout_path, stderr_path, "run_capture_input")
    let env = tool_process_clear_driver_env()
    let rc = with_exec_argv_capture_input(tool_process_argv(args), stdout_path, stderr_path, timeout_ms, stdin_path)
    tool_process_restore_driver_env(env)
    ToolProcessResult {
        rc,
        stdout: with_fs_read_file(stdout_path),
        stderr: with_fs_read_file(stderr_path),
        timed_out: rc == 124,
    }

pub fn ProcessRunner.spawn_capture(self: &Self, args: &Vec[str], stdout_path: str, stderr_path: str) -> i32:
    tool_capability_require(self.token, "ProcessRunner")
    self.require_network_allowed(args, "spawn_capture")
    self.require_capture_allowed(stdout_path, stderr_path, "spawn_capture")
    let env = tool_process_clear_driver_env()
    let pid = with_exec_argv_capture_spawn(tool_process_argv(args), stdout_path, stderr_path)
    tool_process_restore_driver_env(env)
    pid

pub fn ProcessRunner.wait(self: &Self, pid: i32, timeout_ms: i32) -> i32:
    tool_capability_require(self.token, "ProcessRunner")
    with_exec_wait(pid, timeout_ms)

fn tool_process_basename(path: str) -> str:
    var start = 0
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 47 or ch == 92:
            start = i + 1
    path.slice(start as i64, path.len())

fn tool_process_requires_network(args: &Vec[str]) -> bool:
    if args.len() == 0:
        return false
    let name = tool_process_basename(args.get(0))
    name == "curl" or name == "curl.exe" or name == "wget" or name == "wget.exe" or name == "https_fetch" or name == "https_fetch.exe"

fn ProcessRunner.project_relative_path(self: &Self, path: str) -> str:
    let normalized = tool_path_normalize(path)
    if self.root.len() == 0 or self.root == ".":
        return normalized
    let root = tool_path_normalize(self.root)
    let prefix = if root.ends_with("/"): root else: root ++ "/"
    if normalized.starts_with(prefix):
        return normalized.slice(prefix.len(), normalized.len())
    normalized

fn ProcessRunner.write_path_allowed(self: &Self, path: str) -> bool:
    if not self.write_scoped:
        return true
    for i in 0..self.write_scope.len() as i32:
        if tool_path_is_same_or_child(path, self.write_scope.get(i as i64)):
            return true
    false

fn ProcessRunner.require_network_allowed(self: &Self, args: &Vec[str], method: str):
    if not tool_process_requires_network(args):
        return
    if self.network:
        return
    let target = if self.target_name.len() > 0: self.target_name else: "<build>"
    let tool = tool_process_basename(args.get(0))
    with_eprint("error: ProcessRunner." ++ method ++ " uses network tool '" ++ tool ++ "' for target '" ++ target ++ "' without target.allow_network()\n")
    exit(1)

fn ProcessRunner.require_capture_path_allowed(self: &Self, path: str, method: str):
    if path.len() == 0:
        return
    let rel = self.project_relative_path(path)
    if not tool_path_is_project_relative(rel):
        with_eprint("error: ProcessRunner." ++ method ++ " capture path escapes project root: " ++ path ++ "\n")
        exit(1)
    if not self.write_path_allowed(rel):
        with_eprint("error: ProcessRunner." ++ method ++ " capture path is not a declared action output: " ++ rel ++ "\n")
        exit(1)

fn ProcessRunner.require_capture_allowed(self: &Self, stdout_path: str, stderr_path: str, method: str):
    self.require_capture_path_allowed(stdout_path, method)
    self.require_capture_path_allowed(stderr_path, method)

fn tool_process_spec_fail(message: str):
    with_eprint("error: ProcessRunner.run_spec: " ++ message ++ "\n")
    exit(1)

fn tool_process_spec_validate(spec: &ProcessSpec, stdout_path: str, stderr_path: str):
    if spec.executable.len() == 0:
        tool_process_spec_fail("executable is required")
    if stdout_path.len() == 0 or stderr_path.len() == 0:
        tool_process_spec_fail("stdout and stderr capture paths are required")
    if not spec.capture_stdout or not spec.capture_stderr:
        tool_process_spec_fail("non-capturing stdout/stderr is not implemented")
    if spec.stdin_path.len() > 0 and (spec.cwd.len() > 0 or spec.env.vars.len() > 0):
        tool_process_spec_fail("stdin cannot yet be combined with cwd or env")

pub fn ProcessRunner.run_spec(self: &Self, spec: ProcessSpec, stdout_path: str, stderr_path: str) -> ToolProcessResult:
    tool_capability_require(self.token, "ProcessRunner")
    tool_process_spec_validate(spec, stdout_path, stderr_path)
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
    target = target.allow_network()
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

fn build_host_exe_suffix() -> str:
    if with_sysinfo_os() == "Windows":
        return ".exe"
    ""

fn build_timeout_or(timeout: i32, fallback: i32) -> i32:
    if timeout > 0:
        return timeout
    fallback

fn build_https_fetch_source() -> str:
    "use std.http\n" ++
    "use std.process\n\n" ++
    "fn main -> i32:\n" ++
    "    let argv = args()\n" ++
    "    if argv.len() < 3:\n" ++
    "        print(\"usage: https_fetch <url> <output>\")\n" ++
    "        return 2\n" ++
    "    let rc = https_download(argv.get(1), argv.get(2))\n" ++
    "    if rc != 0:\n" ++
    "        print(\"HTTPS download failed: \" ++ argv.get(1))\n" ++
    "        return 1\n" ++
    "    0\n"

fn build_zlib_gunzip_source() -> str:
    "use std.fs\n" ++
    "use std.process\n" ++
    "use std.zlib\n\n" ++
    "const MAX_OUTPUT: i64 = 8589934592\n\n" ++
    "fn bytes_from_str(data: str) -> Vec[u8]:\n" ++
    "    let out: Vec[u8] = Vec.new()\n" ++
    "    var i: i64 = 0\n" ++
    "    while i < data.len():\n" ++
    "        out.push(data.byte_at(i) as u8)\n" ++
    "        i = i + 1\n" ++
    "    out\n\n" ++
    "fn bytes_to_str(data: &Vec[u8]) -> str:\n" ++
    "    var out = StringBuilder.with_capacity(data.len())\n" ++
    "    var i: i64 = 0\n" ++
    "    while i < data.len():\n" ++
    "        out.push_byte(data.get(i))\n" ++
    "        i = i + 1\n" ++
    "    out.to_str()\n\n" ++
    "fn main -> i32:\n" ++
    "    let argv = args()\n" ++
    "    if argv.len() < 3:\n" ++
    "        print(\"usage: zlib_gunzip <input.tar.gz> <output.tar>\")\n" ++
    "        return 2\n" ++
    "    let input = read_file(argv.get(1))\n" ++
    "    if input.len() == 0:\n" ++
    "        print(\"could not read input archive\")\n" ++
    "        return 1\n" ++
    "    let input_bytes = bytes_from_str(input)\n" ++
    "    match decompress_gzip_with_limit(&input_bytes, MAX_OUTPUT):\n" ++
    "        Ok(tar_bytes) => {\n" ++
    "            if write_file(argv.get(2), bytes_to_str(&tar_bytes)) != 0:\n" ++
    "                print(\"could not write output tar\")\n" ++
    "                return 1\n" ++
    "        }\n" ++
    "        Err(err) => {\n" ++
    "            print(err.message)\n" ++
    "            return 1\n" ++
    "        }\n" ++
    "    0\n"

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
    if fs.mkdir_all(cmd_dir) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not create command directory: " ++ cmd_dir)
        return 1
    let tmp_path = output_path ++ ".download.tmp"
    let helper = cmd_dir ++ "/https_fetch" ++ build_host_exe_suffix()
    let ws = ctx.create_workspace(ctx.target_name() ++ "-https_fetch")
    ws.add_string(cmd_dir ++ "/https_fetch.w", build_https_fetch_source())
    var opts = ws.options()
    opts.output_path = helper
    opts.debug_info = false
    ws.set_options(opts)
    let compile_result = ws.compile()
    if compile_result.status != BuildStatus.ok or compile_result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": failed to compile https_fetch helper")
        return 1
    let fetch_args: Vec[str] = Vec.new()
    fetch_args.push(helper)
    fetch_args.push(url)
    fetch_args.push(tmp_path)
    let result = proc.run_capture(fetch_args, cmd_dir ++ "/https_fetch.stdout", cmd_dir ++ "/https_fetch.stderr", build_timeout_or(ctx.timeout(), 300000))
    if result.rc != 0:
        var detail = ""
        if result.stderr.len() > 0:
            detail = ": " ++ result.stderr
        else if result.stdout.len() > 0:
            detail = ": " ++ result.stdout
        ctx.diagnostics().error(ctx.target_name() ++ ": HTTPS download failed for " ++ url ++ " (rc=" ++ f"{result.rc}" ++ ")" ++ detail)
        return 1
    if sha256.len() > 0:
        let actual = fs.sha256_file(tmp_path)
        if actual.len() == 0:
            ctx.diagnostics().error(ctx.target_name() ++ ": could not hash downloaded file")
            return 1
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
    if fs.mkdir_all(output_dir) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not create output directory: " ++ output_dir)
        return 1
    let cmd_dir = "out/command/" ++ ctx.target_name()
    if fs.mkdir_all(cmd_dir) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": could not create command directory: " ++ cmd_dir)
        return 1
    let helper = cmd_dir ++ "/zlib_gunzip" ++ build_host_exe_suffix()
    let ws = ctx.create_workspace(ctx.target_name() ++ "-zlib_gunzip")
    ws.add_string(cmd_dir ++ "/zlib_gunzip.w", build_zlib_gunzip_source())
    var opts = ws.options()
    opts.output_path = helper
    opts.debug_info = false
    ws.set_options(opts)
    let compile_result = ws.compile()
    if compile_result.status != BuildStatus.ok or compile_result.rc != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": failed to compile zlib_gunzip helper")
        return 1
    let tar_path = cmd_dir ++ "/archive.tar"
    let gunzip_args: Vec[str] = Vec.new()
    gunzip_args.push(helper)
    gunzip_args.push(archive)
    gunzip_args.push(tar_path)
    let result = proc.run_capture(gunzip_args, cmd_dir ++ "/zlib_gunzip.stdout", cmd_dir ++ "/zlib_gunzip.stderr", build_timeout_or(ctx.timeout(), 300000))
    if result.rc != 0:
        var detail = ""
        if result.stderr.len() > 0:
            detail = ": " ++ result.stderr
        else if result.stdout.len() > 0:
            detail = ": " ++ result.stdout
        ctx.diagnostics().error(ctx.target_name() ++ ": gzip decompression failed for " ++ archive ++ " (rc=" ++ f"{result.rc}" ++ ")" ++ detail)
        return 1
    if fs.extract_tar(tar_path, output_dir) != 0:
        ctx.diagnostics().error(ctx.target_name() ++ ": tar extraction failed for " ++ tar_path)
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

fn build_action_outputs(target: &Target) -> Vec[str]:
    let outputs: Vec[str] = Vec.new()
    if target.output.len() > 0:
        outputs.push(target.output)
    for i in 0..target.extra_outputs.len() as i32:
        outputs.push(target.extra_outputs.get(i as i64))
    outputs

fn build_action_write_scope(target: &Target) -> Vec[str]:
    let scopes = build_action_outputs(target)
    for i in 0..target.write_scopes.len() as i32:
        scopes.push(target.write_scopes.get(i as i64))
    scopes.push(tool_action_scratch_dir(target.name))
    scopes

fn build_action_ctx(ctx: &BuildCtx, target: &Target) -> ActionCtx:
    let fs_outputs = build_action_write_scope(target)
    let ctx_outputs = build_action_outputs(target)
    let scratch_path = tool_action_scratch_dir(target.name)
    ActionCtx {
        token: ctx.token,
        target_name_value: target.name,
        project: ctx.project,
        diagnostics_value: ctx.diagnostics,
        fs_value: ToolFs { token: ctx.token, root: ctx.fs.root, write_scope: fs_outputs, write_scoped: true, scratch_path },
        process_runner_value: ProcessRunner { token: ctx.token, root: ctx.fs.root, target_name: target.name, write_scope: fs_outputs, write_scoped: true, network: target.network },
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
            let scratch_path = tool_action_scratch_dir(target.name)
            let scratch_abs = if ctx.fs.root.len() == 0 or ctx.fs.root == ".":
                scratch_path
            else if ctx.fs.root.ends_with("/"):
                ctx.fs.root ++ scratch_path
            else:
                ctx.fs.root ++ "/" ++ scratch_path
            let _remove_scratch = with_fs_remove_tree(scratch_abs)
            if with_fs_mkdir_p(scratch_abs) != 0:
                with_eprint("error: build action target '" ++ action_name ++ "' could not create scratch directory: " ++ scratch_path ++ "\n")
                return 1
            let action_ctx = build_action_ctx(ctx, target)
            return target.action(action_ctx)
    with_eprint("error: build action target not found: " ++ action_name ++ "\n")
    1

pub fn __driver_action_name() -> str:
    with_getenv_str("WITH_BUILD_ACTION_NAME")

pub fn __driver_exit(code: i32) -> Unit:
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
