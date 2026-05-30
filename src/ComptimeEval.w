use ComptimeValue
use Sema
use Ast
use Span
use Diagnostic
use InternPool
use TypeLayout
use CapabilityRegistry
use compiler.Compilation
use compiler.Link
use compiler.ProjectConfig
use render
use CiMigrate

extern fn with_eprint(s: str) -> void
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_is_dir(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
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
extern fn with_thread_spawn(fn_ptr: *mut u8, ctx: *mut u8) -> i64
extern fn with_thread_join(handle: i64) -> i32
extern fn with_println_str(s: str) -> void
extern fn with_println_i32(n: i32) -> void
extern fn with_println_i64(n: i64) -> void
extern fn with_println_bool(v: bool) -> void
extern fn with_print_str(s: str) -> void
extern fn with_write(s: str) -> void
extern fn with_ewrite(s: str) -> void
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_str_len(s: str) -> i64
extern fn with_str_byte_at(s: str, index: i64) -> i32
extern fn with_str_slice(s: str, start: i64, end: i64) -> str
extern fn with_str_contains(haystack: str, needle: str) -> i32
extern fn with_str_concat(a: str, b: str) -> str
extern fn with_str_from_byte(byte: i32) -> str
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_str_ends_with(s: str, suffix: str) -> i32
extern fn with_str_replace(s: str, old: str, new_s: str) -> str
extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str
extern fn with_sysinfo_hostname() -> str

const COMPTIME_RECURSION_LIMIT: i32 = 256
const COMPTIME_STEP_LIMIT: i32 = 50000
// Tool-mode functions are build programs. They can legitimately walk large
// generated source trees and run many small capability calls; keep the guard
// high enough for real project actions while still catching runaway loops.
const COMPTIME_TOOL_STEP_LIMIT: i32 = 1000000000

enum ComptimeControlKind: i32:
    CTL_VALUE = 0
    CTL_RETURN = 1
    CTL_BREAK = 2
    CTL_CONTINUE = 3
    CTL_ERROR = 4

type ComptimeControl {
    kind: i32,
    value: ComptimeValue,
    label: i32,
}

type ComptimeCapabilityRecord {
    kind: i32,
    generation: i32,
    package_name: str,
    package_version: str,
    project_root: str,
    workspace_id: i32,
    target_name: str,
    inputs: Vec[str],
    outputs: Vec[str],
    args: Vec[str],
    write_scope: Vec[str],
    write_scoped: i32,
    timeout_ms: i32,
    cwd: str,
    env: Vec[str],
    network: i32,
}

type ComptimeWorkspaceRecord {
    name: str,
    files: Vec[str],
    string_names: Vec[str],
    string_sources: Vec[str],
    options: ComptimeValue,
    migrate_options: ComptimeValue,
    intercept_active: i32,
    intercept_terminal: i32,
    generation: i32,
    intercept_phase: i32,
    messages: Vec[ComptimeValue],
    message_cursor: i32,
    intercept_started: i32,
    pending_link_active: i32,
    pending_link_obj_path: str,
    pending_link_bin_path: str,
    pending_link_output_path: str,
    pending_link_output_kind: i32,
    pending_link_debug_info: i32,
    pending_link_command: LinkStageCommand,
}

type ComptimeWorkspaceCompileResult {
    result: ComptimeValue,
    messages: Vec[ComptimeValue],
}

type ComptimeWorkspaceCompilePlan {
    valid: i32,
    name: str,
    is_migrate: i32,
    final_output: str,
    absolute_output: str,
    output_kind: i32,
    has_strings: i32,
    source_paths: Vec[str],
    source_texts: Vec[str],
    absolute_source: str,
    include_paths: Vec[str],
    defines: Vec[str],
    link_libs: Vec[str],
    opt_level: i32,
    no_std: bool,
    alloc_mode: bool,
    runtime_available: bool,
    debug_info: bool,
    compiler_hooks_enabled: bool,
    prelude_mode: i32,
    migrate_is_dir: i32,
    migrate_source: str,
    migrate_include_paths: Vec[str],
    migrate_forced_includes: Vec[str],
    migrate_defines: Vec[str],
    migrate_exclude_basenames: str,
    migrate_no_c_export: bool,
    migrate_c_export_functions: bool,
    migrate_convert_goto_to_structured: bool,
    migrate_block_style: i32,
    migrate_width_slice: i32,
    migrate_shared_defs: str,
    migrate_one: str,
    migrate_shared_fragment: str,
}

type ComptimeWorkspaceNativeCompileResult {
    rc: i32,
    artifact_path: str,
    comp: Compilation,
    is_migrate: i32,
}

type ComptimeWorkspaceThreadJob {
    plan: ComptimeWorkspaceCompilePlan,
    result: ComptimeWorkspaceNativeCompileResult,
}

type ComptimeLineColumn {
    line: i32,
    column: i32,
}

type ComptimeEvaluator {
    sema: Sema,
    ast: AstPool,
    pool: InternPool,
    slot_syms: Vec[i32],
    slot_values: Vec[ComptimeValue],
    slot_muts: Vec[i32],
    scope_starts: Vec[i32],
    loop_labels: Vec[i32],
    extra_values: Vec[ComptimeValue],
    active_global_syms: Vec[i32],
    active_fn_syms: Vec[i32],
    capability_records: Vec[ComptimeCapabilityRecord],
    workspace_records: Vec[ComptimeWorkspaceRecord],
    current_workspace_id: i32,
    next_capability_generation: i32,
    steps: i32,
    step_budget: i32,
    recursion_limit: i32,
    require_success: i32,
    allow_runtime_calls: i32,
    had_error: i32,
    last_error_msg: str,
    runtime_exit_code: i32,
    runtime_stderr: str,
    runtime_env_names: Vec[str],
    runtime_env_values: Vec[str],
    has_pending_diag: i32,
    pending_diag: Diagnostic,
}

type ComptimeEvalResult {
    value: ComptimeValue,
    extras: Vec[ComptimeValue],
    error_msg: str,
    runtime_exit_code: i32,
    runtime_stderr: str,
}

type ComptimeSourceLoc {
    line: i32,
    col: i32,
}

fn comptime_control_value(value: ComptimeValue) -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_VALUE, value, label: 0 }

fn comptime_control_return(value: ComptimeValue) -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_RETURN, value, label: 0 }

fn comptime_control_break(value: ComptimeValue, label: i32) -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_BREAK, value, label }

fn comptime_control_continue(label: i32) -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_CONTINUE, value: comptime_value_void(0), label }

fn comptime_control_error() -> ComptimeControl:
    ComptimeControl { kind: ComptimeControlKind.CTL_ERROR, value: comptime_value_invalid(), label: 0 }

fn ComptimeEvaluator.init(sema: Sema, ast: AstPool, pool: InternPool, require_success: i32) -> ComptimeEvaluator:
    ComptimeEvaluator {
        sema,
        ast,
        pool,
        slot_syms: Vec.new(),
        slot_values: Vec.new(),
        slot_muts: Vec.new(),
        scope_starts: Vec.new(),
        loop_labels: Vec.new(),
        extra_values: Vec.new(),
        active_global_syms: Vec.new(),
        active_fn_syms: Vec.new(),
        capability_records: Vec.new(),
        workspace_records: Vec.new(),
        current_workspace_id: -1,
        next_capability_generation: 1,
        steps: 0,
        step_budget: COMPTIME_STEP_LIMIT,
        recursion_limit: COMPTIME_RECURSION_LIMIT,
        require_success,
        allow_runtime_calls: 0,
        had_error: 0,
        last_error_msg: "",
        runtime_exit_code: 0,
        runtime_stderr: "",
        runtime_env_names: Vec.new(),
        runtime_env_values: Vec.new(),
        has_pending_diag: 0,
        pending_diag: Diagnostic.err("", Span { file: 0, start: 0, end: 0 }),
    }

fn comptime_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return ""
    path.slice(0, last_slash as i64)

fn comptime_resolve_embed_file_path(source_path: str, raw_path: str) -> str:
    if raw_path.len() > 0 and raw_path.byte_at(0) == 47:
        return raw_path
    let dir = comptime_dirname(source_path)
    if dir.len() == 0:
        return raw_path
    dir ++ "/" ++ raw_path

fn comptime_source_loc(text: str, offset: i32) -> ComptimeSourceLoc:
    var line = 1
    var col = 1
    var i = 0
    while i < offset and i < text.len() as i32:
        if text.byte_at(i as i64) == 10:
            line = line + 1
            col = 1
        else:
            col = col + 1
        i = i + 1
    ComptimeSourceLoc { line: line, col: col }

fn comptime_type_name_has_base(type_name: str, base_name: str) -> i32:
    if type_name == base_name:
        return 1
    if type_name.len() <= base_name.len():
        return 0
    if type_name.slice(0, base_name.len()) != base_name:
        return 0
    if type_name.byte_at(base_name.len() as i64) == 91:
        return 1
    0

fn comptime_hex_digit_value(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 97 and ch <= 102:
        return ch - 87
    if ch >= 65 and ch <= 70:
        return ch - 55
    -1

fn comptime_decode_string_escapes(text: str) -> str:
    let raw_prefix = "\x01raw\x01"
    if text.starts_with(raw_prefix):
        return text.slice(raw_prefix.len(), text.len())
    var out = ""
    let len = text.len() as i32
    var i = 0
    while i < len:
        let ch = text.byte_at(i as i64)
        if ch == 92 and i + 1 < len:
            i = i + 1
            let esc = text.byte_at(i as i64)
            if esc == 120 and i + 2 < len:
                let hi = comptime_hex_digit_value(text.byte_at((i + 1) as i64))
                let lo = comptime_hex_digit_value(text.byte_at((i + 2) as i64))
                if hi >= 0 and lo >= 0:
                    out = out ++ str_from_byte(hi * 16 + lo)
                    i = i + 2
                else:
                    out = out ++ text.slice(i as i64, (i + 1) as i64)
            else if esc == 110:
                out = out ++ "\n"
            else if esc == 116:
                out = out ++ "\t"
            else if esc == 114:
                out = out ++ "\r"
            else if esc == 48:
                out = out ++ str_from_byte(0)
            else if esc == 92:
                out = out ++ "\\"
            else if esc == 34:
                out = out ++ "\""
            else:
                out = out ++ text.slice(i as i64, (i + 1) as i64)
        else:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
        i = i + 1
    out

fn comptime_tool_path_is_project_relative(path: str) -> bool:
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

fn comptime_tool_path_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn comptime_tool_join(root: str, path: str) -> str:
    if root.len() == 0 or root == ".":
        return path
    if root.ends_with("/"):
        return root ++ path
    root ++ "/" ++ path

fn comptime_tool_path_normalize(path: str) -> str:
    if path.len() == 0:
        return "."
    let parts: Vec[str] = Vec.new()
    var start = 0
    var is_absolute = path.byte_at(0) == 47
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
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

fn comptime_tool_path_is_same_or_child(path: str, root: str) -> bool:
    if path == root:
        return true
    if path.len() <= root.len():
        return false
    path.starts_with(root) and path.byte_at(root.len() as i64) == 47

fn comptime_tool_path_is_parent_of(parent: str, child: str) -> bool:
    if parent.len() >= child.len():
        return false
    child.starts_with(parent) and child.byte_at(parent.len() as i64) == 47

fn comptime_tool_split_nonempty_lines(text: str) -> Vec[str]:
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

fn comptime_glob_split_by_slash(path: str) -> Vec[str]:
    let parts: Vec[str] = Vec.new()
    var start = 0
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            if i > start:
                parts.push(path.slice(start as i64, i as i64))
            start = i + 1
    if start < path.len() as i32:
        parts.push(path.slice(start as i64, path.len()))
    parts

fn comptime_glob_segment_matches(pattern: str, name: str) -> bool:
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

fn comptime_glob_segments_match(pat_segs: Vec[str], pi: i32, file_segs: Vec[str], fi: i32) -> bool:
    if pi >= pat_segs.len() as i32:
        return fi >= file_segs.len() as i32
    let seg = pat_segs.get(pi as i64)
    if seg == "**":
        var k = fi
        while k <= file_segs.len() as i32:
            if comptime_glob_segments_match(pat_segs, pi + 1, file_segs, k):
                return true
            k = k + 1
        return false
    if fi >= file_segs.len() as i32:
        return false
    if not comptime_glob_segment_matches(seg, file_segs.get(fi as i64)):
        return false
    comptime_glob_segments_match(pat_segs, pi + 1, file_segs, fi + 1)

fn comptime_glob_str_compare(a: str, b: str) -> i32:
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

fn comptime_glob_sort(items: Vec[str]) -> Vec[str]:
    var sorted: Vec[str] = Vec.new()
    for i in 0..items.len() as i32:
        let item = items.get(i as i64)
        var inserted = false
        var out: Vec[str] = Vec.new()
        for j in 0..sorted.len() as i32:
            let existing = sorted.get(j as i64)
            if not inserted and comptime_glob_str_compare(item, existing) < 0:
                out.push(item)
                inserted = true
            out.push(existing)
        if not inserted:
            out.push(item)
        sorted = out
    sorted

fn comptime_eval_result_invalid() -> ComptimeEvalResult:
    ComptimeEvalResult {
        value: comptime_value_invalid(),
        extras: Vec.new(),
        error_msg: "",
        runtime_exit_code: 0,
        runtime_stderr: "",
    }

fn comptime_capability_record(kind: i32, package_name: str, package_version: str, project_root: str) -> ComptimeCapabilityRecord:
    ComptimeCapabilityRecord {
        kind,
        generation: 0,
        package_name,
        package_version,
        project_root,
        workspace_id: -1,
        target_name: "",
        inputs: Vec.new(),
        outputs: Vec.new(),
        args: Vec.new(),
        write_scope: Vec.new(),
        write_scoped: 0,
        timeout_ms: 0,
        cwd: "",
        env: Vec.new(),
        network: 0,
    }

fn comptime_action_outputs(output: str, extra_outputs: Vec[str]) -> Vec[str]:
    let outputs: Vec[str] = Vec.new()
    if output.len() > 0:
        outputs.push(output)
    for i in 0..extra_outputs.len() as i32:
        outputs.push(extra_outputs.get(i as i64))
    outputs

fn comptime_action_write_scope(output: str, extra_outputs: Vec[str], write_scopes: Vec[str]) -> Vec[str]:
    let scopes = comptime_action_outputs(output, extra_outputs)
    for i in 0..write_scopes.len() as i32:
        scopes.push(write_scopes.get(i as i64))
    scopes

fn comptime_action_capability_record(package_name: str, package_version: str, project_root: str, target_name: str, inputs: Vec[str], output: str, extra_outputs: Vec[str], args: Vec[str], write_scopes: Vec[str], timeout_ms: i32, cwd: str, env: Vec[str], network: i32) -> ComptimeCapabilityRecord:
    ComptimeCapabilityRecord {
        kind: CapabilityKind.CK_BUILD_ACTION_CTX,
        generation: 0,
        package_name,
        package_version,
        project_root,
        workspace_id: -1,
        target_name,
        inputs,
        outputs: comptime_action_outputs(output, extra_outputs),
        args,
        write_scope: comptime_action_write_scope(output, extra_outputs, write_scopes),
        write_scoped: 1,
        timeout_ms,
        cwd,
        env,
        network,
    }

fn ComptimeEvaluator.check_workspace_intercepts_finished(self: ComptimeEvaluator):
    if self.had_error != 0:
        return
    for wi in 0..self.workspace_records.len() as i32:
        let record = self.workspace_records.get(wi as i64)
        if record.intercept_active == 0:
            continue
        if record.intercept_terminal != 0 and record.message_cursor >= record.messages.len() as i32:
            continue
        let reason =
            if record.intercept_terminal != 0:
                "terminal message was not consumed"
            else:
                "workspace did not reach a terminal message"
        let _ = self.fail(0, "incomplete workspace interception for '" ++ record.name ++ "': " ++ reason)
        return

fn comptime_try_eval_expr_result(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, node: i32) -> ComptimeEvalResult:
    var sema = unsafe *sema_ptr
    sema.ast = ast
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 0)
    let value = evaluator.eval_root(node)
    if evaluator.has_pending_diag != 0:
        sema_ptr.diags.emit(evaluator.pending_diag)
    ComptimeEvalResult {
        value,
        extras: evaluator.extra_values,
        error_msg: evaluator.last_error_msg,
        runtime_exit_code: evaluator.runtime_exit_code,
        runtime_stderr: evaluator.runtime_stderr,
    }

fn comptime_force_eval_expr_result(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, node: i32) -> ComptimeEvalResult:
    var sema = unsafe *sema_ptr
    sema.ast = ast
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 1)
    let value = evaluator.eval_root(node)
    if evaluator.has_pending_diag != 0:
        sema_ptr.diags.emit(evaluator.pending_diag)
    ComptimeEvalResult {
        value,
        extras: evaluator.extra_values,
        error_msg: evaluator.last_error_msg,
        runtime_exit_code: evaluator.runtime_exit_code,
        runtime_stderr: evaluator.runtime_stderr,
    }

fn comptime_try_eval_expr(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, node: i32) -> ComptimeValue:
    comptime_try_eval_expr_result(sema_ptr, ast, pool, node).value

fn comptime_force_eval_expr(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, node: i32) -> ComptimeValue:
    comptime_force_eval_expr_result(sema_ptr, ast, pool, node).value

fn comptime_eval_tool_build_result(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, fn_sym: i32, package_name: str, package_version: str, project_root: str) -> ComptimeEvalResult:
    var sema = unsafe *sema_ptr
    sema.ast = ast
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 1)
    evaluator.allow_runtime_calls = 1
    evaluator.step_budget = COMPTIME_TOOL_STEP_LIMIT
    let call_node = if ast.decl_count() > 0: ast.get_decl(0) else: 0
    let ctx_type = evaluator.capability_type_id(CapabilityKind.CK_BUILD_CTX, call_node)
    if ctx_type == 0:
        return ComptimeEvalResult { value: comptime_value_invalid(), extras: evaluator.extra_values, error_msg: evaluator.last_error_msg, runtime_exit_code: evaluator.runtime_exit_code, runtime_stderr: evaluator.runtime_stderr }
    let ctx_record = comptime_capability_record(CapabilityKind.CK_BUILD_CTX, package_name, package_version, project_root)
    let ctx_value = evaluator.mint_capability(ctx_type, ctx_record)
    let args: Vec[ComptimeValue] = Vec.new()
    args.push(ctx_value)
    let signal = evaluator.eval_fn_symbol_call_values(fn_sym, args, call_node)
    evaluator.check_workspace_intercepts_finished()
    evaluator.restore_runtime_env()
    if evaluator.has_pending_diag != 0:
        sema_ptr.diags.emit(evaluator.pending_diag)
    let value =
        if evaluator.had_error == 0 and (signal.kind == ComptimeControlKind.CTL_VALUE or signal.kind == ComptimeControlKind.CTL_RETURN):
            signal.value
        else:
            comptime_value_invalid()
    ComptimeEvalResult {
        value,
        extras: evaluator.extra_values,
        error_msg: evaluator.last_error_msg,
        runtime_exit_code: evaluator.runtime_exit_code,
        runtime_stderr: evaluator.runtime_stderr,
    }

fn comptime_eval_tool_action_result(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, fn_sym: i32, package_name: str, package_version: str, project_root: str, target_name: str, inputs: Vec[str], output: str, extra_outputs: Vec[str], args_values: Vec[str], write_scopes: Vec[str], timeout_ms: i32, cwd: str, env: Vec[str], network: i32) -> ComptimeEvalResult:
    var sema = unsafe *sema_ptr
    sema.ast = ast
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 1)
    evaluator.allow_runtime_calls = 1
    evaluator.step_budget = COMPTIME_TOOL_STEP_LIMIT
    let call_node = if ast.decl_count() > 0: ast.get_decl(0) else: 0
    let ctx_type = evaluator.capability_type_id(CapabilityKind.CK_BUILD_ACTION_CTX, call_node)
    if ctx_type == 0:
        return ComptimeEvalResult { value: comptime_value_invalid(), extras: evaluator.extra_values, error_msg: evaluator.last_error_msg, runtime_exit_code: evaluator.runtime_exit_code, runtime_stderr: evaluator.runtime_stderr }
    let ctx_record = comptime_action_capability_record(package_name, package_version, project_root, target_name, inputs, output, extra_outputs, args_values, write_scopes, timeout_ms, cwd, env, network)
    let ctx_value = evaluator.mint_capability(ctx_type, ctx_record)
    let args: Vec[ComptimeValue] = Vec.new()
    args.push(ctx_value)
    let signal = evaluator.eval_fn_symbol_call_values(fn_sym, args, call_node)
    evaluator.check_workspace_intercepts_finished()
    evaluator.restore_runtime_env()
    if evaluator.has_pending_diag != 0:
        sema_ptr.diags.emit(evaluator.pending_diag)
    let value =
        if evaluator.had_error == 0 and (signal.kind == ComptimeControlKind.CTL_VALUE or signal.kind == ComptimeControlKind.CTL_RETURN):
            signal.value
        else:
            comptime_value_invalid()
    ComptimeEvalResult {
        value,
        extras: evaluator.extra_values,
        error_msg: evaluator.last_error_msg,
        runtime_exit_code: evaluator.runtime_exit_code,
        runtime_stderr: evaluator.runtime_stderr,
    }

fn ComptimeEvaluator.eval_root(self: ComptimeEvaluator, node: i32) -> ComptimeValue:
    let signal = self.eval_expr(node)
    if signal.kind == ComptimeControlKind.CTL_VALUE:
        return signal.value
    if signal.kind == ComptimeControlKind.CTL_RETURN:
        return signal.value
    if signal.kind == ComptimeControlKind.CTL_BREAK:
        self.fail(node, "break escaped comptime evaluation")
        return comptime_value_invalid()
    if signal.kind == ComptimeControlKind.CTL_CONTINUE:
        self.fail(node, "continue escaped comptime evaluation")
        return comptime_value_invalid()
    comptime_value_invalid()

fn ComptimeEvaluator.fail(self: ComptimeEvaluator, node: i32, msg: str) -> ComptimeControl:
    self.last_error_msg = msg
    if self.had_error == 0 and self.require_success != 0 and self.sema.suppress_errors == 0:
        let start = self.ast.get_start(node)
        let end = self.ast.get_end(node)
        self.has_pending_diag = 1
        self.pending_diag = Diagnostic.err(msg, Span { file: self.sema.local_file_id, start, end })
    self.had_error = 1
    comptime_control_error()

fn ComptimeEvaluator.unsupported(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    self.fail(node, f"expression kind {self.ast.kind(node)} is not comptime-evaluable yet")

fn ComptimeEvaluator.capability_type_name(self: ComptimeEvaluator, kind: i32) -> str:
    if kind == CapabilityKind.CK_BUILD_CTX: return "BuildCtx"
    if kind == CapabilityKind.CK_BUILD_PROJECT_INFO: return "ProjectInfo"
    if kind == CapabilityKind.CK_BUILD_DIAGNOSTICS: return "Diagnostics"
    if kind == CapabilityKind.CK_BUILD_SOURCE_EMITTER: return "SourceEmitter"
    if kind == CapabilityKind.CK_BUILD_TOOL_FS: return "ToolFs"
    if kind == CapabilityKind.CK_BUILD_PROCESS_RUNNER: return "ProcessRunner"
    if kind == CapabilityKind.CK_BUILD_ACTION_CTX: return "ActionCtx"
    if kind == CapabilityKind.CK_BUILD_WORKSPACE: return "Workspace"
    ""

fn ComptimeEvaluator.capability_type_id(self: ComptimeEvaluator, kind: i32, node: i32) -> i32:
    let type_name = self.capability_type_name(kind)
    if type_name.len() == 0:
        let _ = self.fail(node, "unknown capability type")
        return 0
    let type_sym = self.pool.intern(type_name) as i32
    let tid = self.sema.lookup_named_type_visible(type_sym)
    if tid == 0:
        let _ = self.fail(node, "capability type is not visible to comptime evaluator")
        return 0
    tid

fn ComptimeEvaluator.named_type_id(self: ComptimeEvaluator, type_name: str, node: i32) -> i32:
    let type_sym = self.pool.intern(type_name) as i32
    let tid = self.sema.lookup_named_type_visible(type_sym)
    if tid == 0:
        let _ = self.fail(node, "type '" ++ type_name ++ "' is not visible to comptime evaluator")
        return 0
    tid

fn ComptimeEvaluator.empty_vec_for_field(self: ComptimeEvaluator, owner_type: i32, field_name: str, node: i32) -> ComptimeValue:
    let field_sym = self.pool.intern(field_name) as i32
    let field_index = self.struct_field_index(owner_type, field_sym)
    if field_index < 0:
        let _ = self.fail(node, "missing field '" ++ field_name ++ "' while constructing comptime struct")
        return comptime_value_invalid()
    let field_type = self.sema.type_reflection_field_type(owner_type, field_index)
    comptime_value_vec(field_type, self.extra_values.len() as i32, 0)

fn ComptimeEvaluator.eval_package_value(self: ComptimeEvaluator, record: ComptimeCapabilityRecord, node: i32) -> ComptimeValue:
    let package_type = self.named_type_id("Package", node)
    if package_type == 0:
        return comptime_value_invalid()
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str(record.package_name))
    self.extra_values.push(comptime_value_str(record.package_version))
    comptime_value_struct(package_type, start, 2)

fn ComptimeEvaluator.eval_new_build_value(self: ComptimeEvaluator, record: ComptimeCapabilityRecord, node: i32) -> ComptimeValue:
    let build_type = self.named_type_id("Build", node)
    if build_type == 0:
        return comptime_value_invalid()
    let package = self.eval_package_value(record, node)
    if package.kind == ComptimeValueKind.CV_INVALID:
        return package
    let targets = self.empty_vec_for_field(build_type, "targets", node)
    if targets.kind == ComptimeValueKind.CV_INVALID:
        return targets
    let generated_sources = self.empty_vec_for_field(build_type, "generated_sources", node)
    if generated_sources.kind == ComptimeValueKind.CV_INVALID:
        return generated_sources
    let start = self.extra_values.len() as i32
    self.extra_values.push(package)
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(targets)
    self.extra_values.push(generated_sources)
    comptime_value_struct(build_type, start, 4)

fn ComptimeEvaluator.default_build_options_value(self: ComptimeEvaluator, node: i32) -> ComptimeValue:
    let options_type = self.named_type_id("BuildOptions", node)
    if options_type == 0:
        return comptime_value_invalid()
    let output_kind_type = self.named_type_id("BuildOutputKind", node)
    let prelude_mode_type = self.named_type_id("PreludeMode", node)
    let target_type = self.named_type_id("BuildTarget", node)
    if output_kind_type == 0 or prelude_mode_type == 0 or target_type == 0:
        return comptime_value_invalid()
    let include_paths = self.empty_vec_for_field(options_type, "include_paths", node)
    let defines = self.empty_vec_for_field(options_type, "defines", node)
    let link_libs = self.empty_vec_for_field(options_type, "link_libs", node)
    if include_paths.kind == ComptimeValueKind.CV_INVALID or defines.kind == ComptimeValueKind.CV_INVALID or link_libs.kind == ComptimeValueKind.CV_INVALID:
        return comptime_value_invalid()
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_int(output_kind_type, 0))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, 1))
    self.extra_values.push(comptime_value_bool(1))
    self.extra_values.push(comptime_value_bool(0))
    self.extra_values.push(comptime_value_bool(0))
    self.extra_values.push(comptime_value_int(prelude_mode_type, 0))
    self.extra_values.push(comptime_value_bool(0))
    self.extra_values.push(comptime_value_int(target_type, 0))
    self.extra_values.push(include_paths)
    self.extra_values.push(defines)
    self.extra_values.push(link_libs)
    self.extra_values.push(comptime_value_bool(1))
    comptime_value_struct(options_type, start, 14)

fn ComptimeEvaluator.default_migrate_options_value(self: ComptimeEvaluator, node: i32) -> ComptimeValue:
    let options_type = self.named_type_id("MigrateOptions", node)
    if options_type == 0:
        return comptime_value_invalid()
    let include_paths = self.empty_vec_for_field(options_type, "include_paths", node)
    let forced_includes = self.empty_vec_for_field(options_type, "forced_includes", node)
    let defines = self.empty_vec_for_field(options_type, "defines", node)
    let exclude_basenames = self.empty_vec_for_field(options_type, "exclude_basenames", node)
    if include_paths.kind == ComptimeValueKind.CV_INVALID or forced_includes.kind == ComptimeValueKind.CV_INVALID or defines.kind == ComptimeValueKind.CV_INVALID or exclude_basenames.kind == ComptimeValueKind.CV_INVALID:
        return comptime_value_invalid()
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(include_paths)
    self.extra_values.push(forced_includes)
    self.extra_values.push(defines)
    self.extra_values.push(exclude_basenames)
    self.extra_values.push(comptime_value_bool(0))
    self.extra_values.push(comptime_value_bool(0))
    self.extra_values.push(comptime_value_bool(0))
    self.extra_values.push(comptime_value_bool(1))
    self.extra_values.push(comptime_value_bool(0))
    self.extra_values.push(comptime_value_bool(0))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, 0))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, 8))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_bool(0))
    comptime_value_struct(options_type, start, 18)

fn ComptimeEvaluator.new_workspace_record(self: ComptimeEvaluator, name: str, node: i32) -> ComptimeWorkspaceRecord:
    ComptimeWorkspaceRecord {
        name,
        files: Vec.new(),
        string_names: Vec.new(),
        string_sources: Vec.new(),
        options: self.default_build_options_value(node),
        migrate_options: self.default_migrate_options_value(node),
        intercept_active: 0,
        intercept_terminal: 0,
        generation: 0,
        intercept_phase: -1,
        messages: Vec.new(),
        message_cursor: 0,
        intercept_started: 0,
        pending_link_active: 0,
        pending_link_obj_path: "",
        pending_link_bin_path: "",
        pending_link_output_path: "",
        pending_link_output_kind: 0,
        pending_link_debug_info: 0,
        pending_link_command: link_stage_empty_command(),
    }

fn ComptimeEvaluator.store_workspace_record(self: ComptimeEvaluator, workspace_id: i32, record: ComptimeWorkspaceRecord):
    let slot_index = workspace_id as i64
    with self.workspace_records.slot(slot_index) as mut slot:
        slot.set(record)

fn ComptimeEvaluator.mint_capability(self: ComptimeEvaluator, type_id: i32, record: ComptimeCapabilityRecord) -> ComptimeValue:
    var stored = record
    stored.generation = self.next_capability_generation
    self.next_capability_generation = self.next_capability_generation + 1
    let handle_id = self.capability_records.len() as i32
    self.capability_records.push(stored)
    comptime_value_capability(type_id, stored.kind, handle_id, stored.generation)

fn ComptimeEvaluator.validate_capability(self: ComptimeEvaluator, value: ComptimeValue, expected_kind: i32, method: str, node: i32) -> i32:
    if value.kind != ComptimeValueKind.CV_CAPABILITY:
        let _ = self.fail(node, "capability receiver expected for " ++ method)
        return -1
    if value.data0 as i32 != expected_kind:
        let _ = self.fail(node, "tool capability kind mismatch for " ++ method)
        return -1
    let handle_id = value.data1 as i32
    if handle_id < 0 or handle_id >= self.capability_records.len() as i32:
        let _ = self.fail(node, "invalid tool capability handle for " ++ method)
        return -1
    let record = self.capability_records.get(handle_id as i64)
    if record.kind != expected_kind or record.generation != value.extra_start:
        let _ = self.fail(node, "stale or invalid tool capability handle for " ++ method)
        return -1
    handle_id

fn ComptimeEvaluator.step(self: ComptimeEvaluator, node: i32) -> i32:
    if self.had_error != 0:
        return 0
    self.steps = self.steps + 1
    if self.steps > self.step_budget:
        self.fail(node, "comptime step limit exceeded")
        return 0
    1

fn ComptimeEvaluator.push_scope(self: ComptimeEvaluator) -> void:
    self.scope_starts.push(self.slot_syms.len() as i32)

fn ComptimeEvaluator.pop_scope(self: ComptimeEvaluator):
    if self.scope_starts.len() as i32 == 0:
        return
    let start = self.scope_starts.get((self.scope_starts.len() as i32 - 1) as i64)
    while self.slot_syms.len() as i32 > start:
        self.slot_syms.pop()
        self.slot_values.pop()
        self.slot_muts.pop()
    self.scope_starts.pop()

fn ComptimeEvaluator.bind_value(self: ComptimeEvaluator, sym: i32, value: ComptimeValue, is_mut: i32) -> void:
    self.slot_syms.push(sym)
    self.slot_values.push(value)
    self.slot_muts.push(is_mut)

fn ComptimeEvaluator.update_slot_value(self: ComptimeEvaluator, idx: i32, value: ComptimeValue) -> void:
    let slot_index = idx as i64
    with self.slot_values.slot(slot_index) as mut slot:
        slot.set(value)

fn ComptimeEvaluator.record_runtime_env_set(self: ComptimeEvaluator, name: str) -> void:
    for i in 0..self.runtime_env_names.len() as i32:
        if self.runtime_env_names.get(i as i64) == name:
            return
    self.runtime_env_names.push(name)
    self.runtime_env_values.push(with_getenv_str(name) ++ "")

fn ComptimeEvaluator.restore_runtime_env(self: ComptimeEvaluator) -> void:
    for i in 0..self.runtime_env_names.len() as i32:
        let _restore = with_setenv_str(self.runtime_env_names.get(i as i64), self.runtime_env_values.get(i as i64))

fn ComptimeEvaluator.lookup_slot_index(self: ComptimeEvaluator, sym: i32) -> i32:
    var i = self.slot_syms.len() as i32 - 1
    while i >= 0:
        if self.slot_syms.get(i as i64) == sym:
            return i
        i = i - 1
    -1

fn ComptimeEvaluator.lookup_value(self: ComptimeEvaluator, sym: i32, node: i32) -> ComptimeControl:
    let idx = self.lookup_slot_index(sym)
    if idx >= 0:
        return comptime_control_value(self.slot_values.get(idx as i64))
    let decl = self.find_module_let_decl(sym)
    if decl == 0:
        return self.fail(node, "runtime value is not available at comptime")
    if self.ast.get_data2(decl) % 2 != 0:
        return self.fail(node, "mutable global access is not allowed in comptime")
    self.eval_module_let_decl(decl, node)

fn ComptimeEvaluator.assign_value(self: ComptimeEvaluator, sym: i32, value: ComptimeValue, node: i32) -> ComptimeControl:
    let idx = self.lookup_slot_index(sym)
    if idx < 0:
        return self.fail(node, "assignment target is not available at comptime")
    if self.slot_muts.get(idx as i64) == 0:
        return self.fail(node, "cannot assign to immutable variable")
    self.update_slot_value(idx, value)
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.assign_struct_field_value(self: ComptimeEvaluator, target: i32, value: ComptimeValue, node: i32) -> ComptimeControl:
    let base_node = self.ast.get_data0(target)
    let field_sym = self.ast.get_data1(target)
    let base_sym = self.binding_sym(base_node)
    if base_sym == 0:
        return self.fail(node, "comptime field assignment requires a local identifier receiver")
    let idx = self.lookup_slot_index(base_sym)
    if idx < 0:
        return self.fail(node, "comptime field assignment target is not available")
    if self.slot_muts.get(idx as i64) == 0:
        return self.fail(node, "cannot assign to field of immutable value")
    let base_value = self.slot_values.get(idx as i64)
    if base_value.kind != ComptimeValueKind.CV_STRUCT:
        return self.fail(node, "comptime field assignment requires a struct value")
    let field_index = self.struct_field_index(base_value.type_id, field_sym)
    if field_index < 0:
        return self.fail(node, "unknown comptime struct field")
    let new_start = self.extra_values.len() as i32
    for fi in 0..base_value.extra_count:
        if fi == field_index:
            self.extra_values.push(value)
        else:
            self.extra_values.push(self.extra_values.get((base_value.extra_start + fi) as i64))
    let updated = comptime_value_struct(base_value.type_id, new_start, base_value.extra_count)
    self.update_slot_value(idx, updated)
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.find_module_let_decl(self: ComptimeEvaluator, sym: i32) -> i32:
    var di = self.ast.decl_count() as i32 - 1
    while di >= 0:
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_LET_DECL and self.ast.get_data0(decl) == sym:
            return decl as i32
        di = di - 1
    0

fn ComptimeEvaluator.find_fn_decl_node(self: ComptimeEvaluator, sym: i32) -> i32:
    if self.sema.fn_decl_nodes.contains(sym):
        return self.sema.fn_decl_nodes.get(sym).unwrap()
    var di = self.ast.decl_count() as i32 - 1
    while di >= 0:
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_FN_DECL and self.ast.get_data0(decl) == sym:
            return decl as i32
        di = di - 1
    0

fn ComptimeEvaluator.fn_decl_node_is_comptime(self: ComptimeEvaluator, fn_node: i32) -> i32:
    if fn_node == 0:
        return 0
    if self.ast.is_comptime_decl_node(fn_node) != 0:
        return 1
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    let flags = self.ast.fn_meta_flags(meta)
    if (flags / FnFlags.COMPTIME) % 2 == 1:
        return 1
    0

fn ComptimeEvaluator.find_decl_index(self: ComptimeEvaluator, decl_node: i32) -> i32:
    for di in 0..self.ast.decl_count():
        if self.ast.get_decl(di) == decl_node:
            return di
    -1

fn ComptimeEvaluator.decl_file_id(self: ComptimeEvaluator, decl_node: i32) -> i32:
    let decl_idx = self.find_decl_index(decl_node)
    if decl_idx >= 0 and decl_idx < self.sema.decl_source_file_ids.len() as i32:
        return self.sema.decl_source_file_ids.get(decl_idx as i64)
    self.sema.local_file_id

fn ComptimeEvaluator.decl_path(self: ComptimeEvaluator, decl_node: i32) -> str:
    let decl_idx = self.find_decl_index(decl_node)
    if decl_idx >= 0 and decl_idx < self.sema.decl_source_paths.len() as i32:
        let path = self.sema.decl_source_paths.get(decl_idx as i64)
        if path.len() > 0:
            return path
    if self.sema.current_module_path.len() > 0:
        return self.sema.current_module_path
    ""

fn ComptimeEvaluator.current_source_path(self: ComptimeEvaluator) -> str:
    if self.sema.current_module_path.len() > 0:
        return self.sema.current_module_path
    "<unknown>"

fn ComptimeEvaluator.current_source_text(self: ComptimeEvaluator) -> str:
    let path = self.current_source_path()
    if path != "<unknown>":
        let text = with_fs_read_file(path)
        if text.len() > 0 or with_fs_file_exists(path) != 0:
            return text
    self.sema.source_text

fn ComptimeEvaluator.push_extra_value(self: ComptimeEvaluator, value: ComptimeValue) -> void:
    self.extra_values.push(value)

fn ComptimeEvaluator.binding_sym(self: ComptimeEvaluator, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        return self.ast.get_data0(node)
    if kind == NodeKind.NK_GROUPED:
        return self.binding_sym(self.ast.get_data0(node))
    0

fn ComptimeEvaluator.copy_extra_slice(self: ComptimeEvaluator, start: i32, count: i32) -> i32:
    let new_start = self.extra_values.len() as i32
    for i in 0..count:
        self.extra_values.push(self.extra_values.get((start + i) as i64))
    new_start

fn ComptimeEvaluator.copy_vec_snapshot(self: ComptimeEvaluator, value: ComptimeValue) -> i32:
    self.copy_extra_slice(value.extra_start, value.extra_count)

fn ComptimeEvaluator.copy_map_snapshot(self: ComptimeEvaluator, value: ComptimeValue) -> i32:
    self.copy_extra_slice(value.extra_start, value.extra_count * 2)

fn ComptimeEvaluator.rebind_collection_receiver(self: ComptimeEvaluator, recv_node: i32, value: ComptimeValue, node: i32) -> ComptimeControl:
    let sym = self.binding_sym(recv_node)
    if sym != 0:
        let idx = self.lookup_slot_index(sym)
        if idx < 0:
            return self.fail(node, "comptime collection mutation requires a local identifier receiver")
        self.update_slot_value(idx, value)
        return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
    if self.ast.kind(recv_node) == NodeKind.NK_FIELD_ACCESS:
        return self.assign_struct_field_value(recv_node, value, node)
    self.fail(node, "comptime collection mutation requires a local identifier or field receiver")

fn ComptimeEvaluator.node_type_or(self: ComptimeEvaluator, node: i32, fallback: i32) -> i32:
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed != 0:
            return typed
    fallback

fn ComptimeEvaluator.comptime_int_width(self: ComptimeEvaluator, type_id: i32) -> i32:
    let numeric = self.sema.numeric_operand_type(type_id)
    let resolved = self.sema.resolve_alias(numeric as TypeId)
    if self.sema.get_type_kind(resolved) == TypeKind.TY_INT:
        return self.sema.get_type_d0(resolved)
    64

fn ComptimeEvaluator.comptime_int_is_unsigned(self: ComptimeEvaluator, type_id: i32) -> bool:
    let numeric = self.sema.numeric_operand_type(type_id)
    let resolved = self.sema.resolve_alias(numeric as TypeId)
    if self.sema.get_type_kind(resolved) == TypeKind.TY_INT:
        return self.sema.get_type_d1(resolved) == 0
    false

fn ComptimeEvaluator.eval_shift_value(self: ComptimeEvaluator, op: i32, result_ty: i32, lhs: i64, rhs: i64) -> i64:
    let width = self.comptime_int_width(result_ty)
    if rhs < 0 or rhs >= width as i64:
        if op == BinaryOp.OP_SHL:
            return 0
        if self.comptime_int_is_unsigned(result_ty):
            return 0
        if lhs < 0:
            return -1
        return 0
    let count = rhs as u32
    if op == BinaryOp.OP_SHL:
        return lhs << count
    if self.comptime_int_is_unsigned(result_ty):
        return exact_int_logical_shr_word(lhs, rhs as i32)
    lhs >> count

fn ComptimeEvaluator.static_type_expr(self: ComptimeEvaluator, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_GENERIC or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TUPLE or kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        return self.sema.resolve_type_expr(node) as i32
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        let prim = self.sema.primitive_type_by_sym(sym)
        if prim != 0:
            return prim
        if self.sema.named_types.contains(sym):
            return self.sema.named_types.get(sym).unwrap()
        return 0
    if kind == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(node)
        let base_sym =
            if self.ast.kind(base) == NodeKind.NK_IDENT or self.ast.kind(base) == NodeKind.NK_TYPE_NAMED:
                self.ast.get_data0(base)
            else:
                0
        if base_sym == 0:
            return 0
        let arg1 = self.static_type_expr(self.ast.get_data1(node))
        if arg1 == 0:
            return 0
        let args: Vec[i32] = Vec.new()
        args.push(arg1)
        var arg_count = 1
        if self.ast.get_data2(node) != 0:
            let arg2 = self.static_type_expr(self.ast.get_data2(node))
            if arg2 == 0:
                return 0
            args.push(arg2)
            arg_count = 2
        return self.sema.find_generic_inst_type(base_sym, args, arg_count) as i32
    0

fn ComptimeEvaluator.static_receiver_type(self: ComptimeEvaluator, node: i32) -> i32:
    let sym = self.binding_sym(node)
    if sym != 0:
        if self.lookup_slot_index(sym) >= 0:
            return 0
        if self.find_module_let_decl(sym) != 0:
            return 0
    self.static_type_expr(node)

fn ComptimeEvaluator.struct_field_index(self: ComptimeEvaluator, type_id: i32, field_sym: i32) -> i32:
    let field_count = self.sema.type_reflection_field_count(type_id)
    for fi in 0..field_count:
        if self.sema.type_reflection_field_name(type_id, fi) == field_sym:
            return fi
    -1

fn ComptimeEvaluator.variant_payload_name(self: ComptimeEvaluator, type_id: i32, variant_index: i32) -> str:
    let payload_count = self.sema.type_reflection_variant_payload_count(type_id, variant_index)
    if payload_count <= 0:
        return ""
    if payload_count == 1:
        let payload_tid = self.sema.type_reflection_variant_payload_type(type_id, variant_index, 0)
        return self.sema.type_name(payload_tid)
    var out = "("
    for pi in 0..payload_count:
        if pi > 0:
            out = out ++ ", "
        let payload_tid = self.sema.type_reflection_variant_payload_type(type_id, variant_index, pi)
        out = out ++ self.sema.type_name(payload_tid)
    out ++ ")"

fn ComptimeEvaluator.eval_type_fields_array(self: ComptimeEvaluator, type_id: i32) -> ComptimeControl:
    let layout_sema = self.sema
    let field_count = self.sema.type_reflection_field_count(type_id)
    let array_tid = self.sema.ensure_exact_type(TypeKind.TY_ARRAY, self.sema.ty_field_info as i32, field_count, 0) as i32
    let arr_start = self.extra_values.len() as i32
    let payload_start = arr_start + field_count
    let payload_values: Vec[ComptimeValue] = Vec.new()
    for fi in 0..field_count:
        let row_start = payload_start + payload_values.len() as i32
        self.extra_values.push(comptime_value_struct(self.sema.ty_field_info as i32, row_start, 5))
        let field_sym = self.sema.type_reflection_field_name(type_id, fi)
        let field_tid = self.sema.type_reflection_field_type(type_id, fi)
        payload_values.push(comptime_value_str(self.pool.resolve(field_sym)))
        payload_values.push(comptime_value_str(self.sema.type_name(field_tid)))
        payload_values.push(comptime_value_int(self.sema.ty_usize as i32, layout_sema.type_layout_struct_field_offset(type_id, fi)))
        payload_values.push(comptime_value_int(self.sema.ty_usize as i32, layout_sema.type_layout_size_of(field_tid)))
        payload_values.push(comptime_value_bool(self.sema.type_is_ephemeral_value(field_tid)))
    for pi in 0..payload_values.len() as i32:
        self.extra_values.push(payload_values.get(pi as i64))
    comptime_control_value(comptime_value_array(array_tid, arr_start, field_count))

fn ComptimeEvaluator.eval_type_variants_array(self: ComptimeEvaluator, type_id: i32) -> ComptimeControl:
    let variant_count = self.sema.type_reflection_variant_count(type_id)
    let array_tid = self.sema.ensure_exact_type(TypeKind.TY_ARRAY, self.sema.ty_variant_info as i32, variant_count, 0) as i32
    let arr_start = self.extra_values.len() as i32
    let payload_start = arr_start + variant_count
    let payload_values: Vec[ComptimeValue] = Vec.new()
    for vi in 0..variant_count:
        let row_start = payload_start + payload_values.len() as i32
        self.extra_values.push(comptime_value_struct(self.sema.ty_variant_info as i32, row_start, 4))
        let variant_sym = self.sema.type_reflection_variant_name(type_id, vi)
        let payload_count = self.sema.type_reflection_variant_payload_count(type_id, vi)
        payload_values.push(comptime_value_str(self.pool.resolve(variant_sym)))
        payload_values.push(comptime_value_int(self.sema.ty_i64 as i32, self.sema.type_reflection_variant_discriminant(type_id, vi)))
        payload_values.push(comptime_value_bool(if payload_count > 0: 1 else: 0))
        payload_values.push(comptime_value_str(self.variant_payload_name(type_id, vi)))
    for pi in 0..payload_values.len() as i32:
        self.extra_values.push(payload_values.get(pi as i64))
    comptime_control_value(comptime_value_array(array_tid, arr_start, variant_count))

fn ComptimeEvaluator.eval_static_collection_new(self: ComptimeEvaluator, result_type: i32, node: i32, arg_count: i32) -> ComptimeControl:
    if arg_count != 0:
        return self.fail(node, "collection.new() takes no arguments in comptime")
    let resolved = self.sema.resolve_alias(result_type)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return self.fail(node, "collection.new() requires a concrete generic type")
    let type_name = self.sema.type_name(result_type)
    let empty_start = self.extra_values.len() as i32
    if comptime_type_name_has_base(type_name, "Vec") != 0:
        return comptime_control_value(comptime_value_vec(result_type, empty_start, 0))
    if comptime_type_name_has_base(type_name, "HashMap") != 0:
        return comptime_control_value(comptime_value_map(result_type, empty_start, 0))
    self.fail(node, "static method is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_bytes_method_call(self: ComptimeEvaluator, recv_node: i32, recv_value: ComptimeValue, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let method = self.pool.resolve(field)
    if method == "len":
        if arg_count != 0:
            return self.fail(node, "Vec[u8].len() takes no arguments")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), recv_value.text.len()))
    if method == "get":
        if arg_count != 1:
            return self.fail(node, "Vec[u8].get() expects exactly one argument")
        let index_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if index_signal.kind != ComptimeControlKind.CTL_VALUE:
            return index_signal
        if comptime_value_is_intlike(index_signal.value) == 0:
            return self.fail(node, "Vec[u8].get() index must be an integer")
        let index = comptime_value_intlike(index_signal.value)
        if index < 0 or index >= recv_value.text.len():
            return self.fail(node, "Vec[u8].get() index out of bounds in comptime")
        return comptime_control_value(comptime_value_int(self.sema.ty_u8 as i32, with_str_byte_at(recv_value.text, index) as i64))
    if method == "push":
        if arg_count != 1:
            return self.fail(node, "Vec[u8].push() expects exactly one argument")
        let arg_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        if comptime_value_is_intlike(arg_signal.value) == 0:
            return self.fail(node, "Vec[u8].push() argument must be an integer")
        let byte_val = comptime_value_intlike(arg_signal.value) as i32
        let new_text = with_str_concat(recv_value.text, with_str_from_byte(byte_val))
        let updated = comptime_value_bytes(recv_value.type_id, new_text)
        return self.rebind_collection_receiver(recv_node, updated, node)
    if method == "contains":
        if arg_count != 1:
            return self.fail(node, "Vec[u8].contains() expects exactly one argument")
        let needle_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if needle_signal.kind != ComptimeControlKind.CTL_VALUE:
            return needle_signal
        if comptime_value_is_intlike(needle_signal.value) == 0:
            return self.fail(node, "Vec[u8].contains() argument must be an integer")
        let needle_byte = comptime_value_intlike(needle_signal.value) as i32
        for i in 0..recv_value.text.len():
            if with_str_byte_at(recv_value.text, i) == needle_byte:
                return comptime_control_value(comptime_value_bool(1))
        return comptime_control_value(comptime_value_bool(0))
    if method == "pop":
        if arg_count != 0:
            return self.fail(node, "Vec[u8].pop() takes no arguments")
        if recv_value.text.len() <= 0:
            return self.fail(node, "Vec[u8].pop() on empty comptime byte vector")
        let last_byte = with_str_byte_at(recv_value.text, recv_value.text.len() - 1)
        let new_text = with_str_slice(recv_value.text, 0, recv_value.text.len() - 1)
        let updated = comptime_value_bytes(recv_value.type_id, new_text)
        let rebind = self.rebind_collection_receiver(recv_node, updated, node)
        if rebind.kind != ComptimeControlKind.CTL_VALUE:
            return rebind
        return comptime_control_value(comptime_value_int(self.sema.ty_u8 as i32, last_byte as i64))
    if method == "clear":
        if arg_count != 0:
            return self.fail(node, "Vec[u8].clear() takes no arguments")
        let updated = comptime_value_bytes(recv_value.type_id, "")
        return self.rebind_collection_receiver(recv_node, updated, node)
    if method == "remove":
        if arg_count != 1:
            return self.fail(node, "Vec[u8].remove() expects exactly one argument")
        let index_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if index_signal.kind != ComptimeControlKind.CTL_VALUE:
            return index_signal
        if comptime_value_is_intlike(index_signal.value) == 0:
            return self.fail(node, "Vec[u8].remove() index must be an integer")
        let index = comptime_value_intlike(index_signal.value)
        if index < 0 or index >= recv_value.text.len():
            return self.fail(node, "Vec[u8].remove() index out of bounds in comptime")
        let removed_byte = with_str_byte_at(recv_value.text, index)
        let prefix = with_str_slice(recv_value.text, 0, index)
        let suffix = with_str_slice(recv_value.text, index + 1, recv_value.text.len())
        let new_text = with_str_concat(prefix, suffix)
        let updated = comptime_value_bytes(recv_value.type_id, new_text)
        let rebind = self.rebind_collection_receiver(recv_node, updated, node)
        if rebind.kind != ComptimeControlKind.CTL_VALUE:
            return rebind
        return comptime_control_value(comptime_value_int(self.sema.ty_u8 as i32, removed_byte as i64))
    self.fail(node, "Vec[u8] method '" ++ method ++ "' is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_vec_method_call(self: ComptimeEvaluator, recv_node: i32, recv_value: ComptimeValue, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let method = self.pool.resolve(field)

    if method == "push":
        if arg_count != 1:
            return self.fail(node, "Vec.push() expects exactly one argument")
        let arg_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        let new_start = self.copy_vec_snapshot(recv_value)
        self.extra_values.push(arg_signal.value)
        let updated = comptime_value_vec(recv_value.type_id, new_start, recv_value.extra_count + 1)
        return self.rebind_collection_receiver(recv_node, updated, node)

    if method == "len":
        if arg_count != 0:
            return self.fail(node, "Vec.len() takes no arguments")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), recv_value.extra_count as i64))

    if method == "contains":
        if arg_count != 1:
            return self.fail(node, "Vec.contains() expects exactly one argument")
        let needle_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if needle_signal.kind != ComptimeControlKind.CTL_VALUE:
            return needle_signal
        for i in 0..recv_value.extra_count:
            let item = self.extra_values.get((recv_value.extra_start + i) as i64)
            if comptime_values_equal(item, needle_signal.value, self.extra_values) != 0:
                return comptime_control_value(comptime_value_bool(1))
        return comptime_control_value(comptime_value_bool(0))

    if method == "get":
        if arg_count != 1:
            return self.fail(node, "Vec.get() expects exactly one argument")
        let index_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if index_signal.kind != ComptimeControlKind.CTL_VALUE:
            return index_signal
        if comptime_value_is_intlike(index_signal.value) == 0:
            return self.fail(node, "Vec.get() index must be an integer")
        let index = comptime_value_intlike(index_signal.value)
        if index < 0 or index >= recv_value.extra_count as i64:
            return self.fail(node, "Vec.get() index out of bounds in comptime")
        return comptime_control_value(self.extra_values.get((recv_value.extra_start + index as i32) as i64))

    if method == "clear":
        if arg_count != 0:
            return self.fail(node, "Vec.clear() takes no arguments")
        let updated = comptime_value_vec(recv_value.type_id, self.extra_values.len() as i32, 0)
        return self.rebind_collection_receiver(recv_node, updated, node)

    if method == "pop":
        if arg_count != 0:
            return self.fail(node, "Vec.pop() takes no arguments")
        if recv_value.extra_count <= 0:
            return self.fail(node, "Vec.pop() on empty comptime vector")
        let removed = self.extra_values.get((recv_value.extra_start + recv_value.extra_count - 1) as i64)
        let new_start = self.copy_extra_slice(recv_value.extra_start, recv_value.extra_count - 1)
        let updated = comptime_value_vec(recv_value.type_id, new_start, recv_value.extra_count - 1)
        let rebind = self.rebind_collection_receiver(recv_node, updated, node)
        if rebind.kind != ComptimeControlKind.CTL_VALUE:
            return rebind
        return comptime_control_value(removed)

    if method == "remove":
        if arg_count != 1:
            return self.fail(node, "Vec.remove() expects exactly one argument")
        let index_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if index_signal.kind != ComptimeControlKind.CTL_VALUE:
            return index_signal
        if comptime_value_is_intlike(index_signal.value) == 0:
            return self.fail(node, "Vec.remove() index must be an integer")
        let index = comptime_value_intlike(index_signal.value) as i32
        if index < 0 or index >= recv_value.extra_count:
            return self.fail(node, "Vec.remove() index out of bounds in comptime")
        let removed = self.extra_values.get((recv_value.extra_start + index) as i64)
        let new_start = self.extra_values.len() as i32
        for i in 0..recv_value.extra_count:
            if i == index:
                continue
            self.extra_values.push(self.extra_values.get((recv_value.extra_start + i) as i64))
        let updated = comptime_value_vec(recv_value.type_id, new_start, recv_value.extra_count - 1)
        let rebind = self.rebind_collection_receiver(recv_node, updated, node)
        if rebind.kind != ComptimeControlKind.CTL_VALUE:
            return rebind
        return comptime_control_value(removed)

    self.fail(node, "Vec method is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_map_method_call(self: ComptimeEvaluator, recv_node: i32, recv_value: ComptimeValue, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let method = self.pool.resolve(field)

    if method == "insert":
        if arg_count != 2:
            return self.fail(node, "HashMap.insert() expects exactly two arguments")
        let key_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if key_signal.kind != ComptimeControlKind.CTL_VALUE:
            return key_signal
        let value_signal = self.eval_expr(self.ast.get_extra(extra_start + 1))
        if value_signal.kind != ComptimeControlKind.CTL_VALUE:
            return value_signal
        let new_start = self.extra_values.len() as i32
        var replaced = 0
        for i in 0..recv_value.extra_count:
            let base = recv_value.extra_start + i * 2
            let old_key = self.extra_values.get(base as i64)
            self.extra_values.push(old_key)
            if comptime_values_equal(old_key, key_signal.value, self.extra_values) != 0:
                self.extra_values.push(value_signal.value)
                replaced = 1
            else:
                self.extra_values.push(self.extra_values.get((base + 1) as i64))
        if replaced == 0:
            self.extra_values.push(key_signal.value)
            self.extra_values.push(value_signal.value)
        let new_count = if replaced != 0: recv_value.extra_count else: recv_value.extra_count + 1
        let updated = comptime_value_map(recv_value.type_id, new_start, new_count)
        return self.rebind_collection_receiver(recv_node, updated, node)

    if method == "len":
        if arg_count != 0:
            return self.fail(node, "HashMap.len() takes no arguments")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), recv_value.extra_count as i64))

    if method == "contains":
        if arg_count != 1:
            return self.fail(node, "HashMap.contains() expects exactly one argument")
        let key_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if key_signal.kind != ComptimeControlKind.CTL_VALUE:
            return key_signal
        for i in 0..recv_value.extra_count:
            let base = recv_value.extra_start + i * 2
            let old_key = self.extra_values.get(base as i64)
            if comptime_values_equal(old_key, key_signal.value, self.extra_values) != 0:
                return comptime_control_value(comptime_value_bool(1))
        return comptime_control_value(comptime_value_bool(0))

    if method == "get":
        if arg_count != 1:
            return self.fail(node, "HashMap.get() expects exactly one argument")
        let key_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if key_signal.kind != ComptimeControlKind.CTL_VALUE:
            return key_signal
        for i in 0..recv_value.extra_count:
            let base = recv_value.extra_start + i * 2
            let old_key = self.extra_values.get(base as i64)
            if comptime_values_equal(old_key, key_signal.value, self.extra_values) != 0:
                return comptime_control_value(self.extra_values.get((base + 1) as i64))
        return self.fail(node, "HashMap.get() missing key in comptime")

    if method == "clear":
        if arg_count != 0:
            return self.fail(node, "HashMap.clear() takes no arguments")
        let updated = comptime_value_map(recv_value.type_id, self.extra_values.len() as i32, 0)
        return self.rebind_collection_receiver(recv_node, updated, node)

    if method == "remove":
        if arg_count != 1:
            return self.fail(node, "HashMap.remove() expects exactly one argument")
        let key_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if key_signal.kind != ComptimeControlKind.CTL_VALUE:
            return key_signal
        let new_start = self.extra_values.len() as i32
        var found = 0
        var removed = comptime_value_invalid()
        for i in 0..recv_value.extra_count:
            let base = recv_value.extra_start + i * 2
            let old_key = self.extra_values.get(base as i64)
            let old_value = self.extra_values.get((base + 1) as i64)
            if comptime_values_equal(old_key, key_signal.value, self.extra_values) != 0:
                found = 1
                removed = old_value
                continue
            self.extra_values.push(old_key)
            self.extra_values.push(old_value)
        if found == 0:
            return self.fail(node, "HashMap.remove() missing key in comptime")
        let updated = comptime_value_map(recv_value.type_id, new_start, recv_value.extra_count - 1)
        let rebind = self.rebind_collection_receiver(recv_node, updated, node)
        if rebind.kind != ComptimeControlKind.CTL_VALUE:
            return rebind
        return comptime_control_value(removed)

    self.fail(node, "HashMap method is not comptime-evaluable yet")

fn comptime_str_find(haystack: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    if haystack.len() < needle.len():
        return -1
    let last = haystack.len() as i32 - needle.len() as i32
    for i in 0..(last + 1):
        var matched = true
        for j in 0..needle.len() as i32:
            if haystack.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
        if matched:
            return i
    -1

fn ComptimeEvaluator.eval_str_method_call(self: ComptimeEvaluator, recv_value: ComptimeValue, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let method = self.pool.resolve(field)
    let text = recv_value.text
    if method == "len":
        if arg_count != 0:
            return self.fail(node, "str.len() takes no arguments")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), text.len()))
    if method == "byte_at":
        if arg_count != 1:
            return self.fail(node, "str.byte_at() expects exactly one argument")
        let index_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if index_signal.kind != ComptimeControlKind.CTL_VALUE:
            return index_signal
        if comptime_value_is_intlike(index_signal.value) == 0:
            return self.fail(node, "str.byte_at() index must be an integer")
        let index = comptime_value_intlike(index_signal.value)
        if index < 0 or index >= text.len():
            return self.fail(node, "str.byte_at() index out of bounds in comptime")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), text.byte_at(index)))
    if method == "slice":
        if arg_count != 2:
            return self.fail(node, "str.slice() expects exactly two arguments")
        let start_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if start_signal.kind != ComptimeControlKind.CTL_VALUE:
            return start_signal
        let end_signal = self.eval_expr(self.ast.get_extra(extra_start + 1))
        if end_signal.kind != ComptimeControlKind.CTL_VALUE:
            return end_signal
        if comptime_value_is_intlike(start_signal.value) == 0 or comptime_value_is_intlike(end_signal.value) == 0:
            return self.fail(node, "str.slice() bounds must be integers")
        let start = comptime_value_intlike(start_signal.value)
        let end = comptime_value_intlike(end_signal.value)
        if start < 0 or end < start or end > text.len():
            return self.fail(node, "str.slice() bounds out of range in comptime")
        return comptime_control_value(comptime_value_str(text.slice(start, end)))
    if method == "contains" or method == "starts_with" or method == "ends_with" or method == "find":
        if arg_count != 1:
            return self.fail(node, "str." ++ method ++ "() expects exactly one argument")
        let needle_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if needle_signal.kind != ComptimeControlKind.CTL_VALUE:
            return needle_signal
        if needle_signal.value.kind != ComptimeValueKind.CV_STR:
            return self.fail(node, "str." ++ method ++ "() argument must be a string")
        let needle = needle_signal.value.text
        if method == "contains":
            return comptime_control_value(comptime_value_bool(if comptime_str_find(text, needle) >= 0: 1 else: 0))
        if method == "starts_with":
            return comptime_control_value(comptime_value_bool(if text.starts_with(needle): 1 else: 0))
        if method == "ends_with":
            return comptime_control_value(comptime_value_bool(if text.ends_with(needle): 1 else: 0))
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), comptime_str_find(text, needle) as i64))
    if method == "replace":
        if arg_count != 2:
            return self.fail(node, "str.replace() expects exactly two arguments")
        let old_signal = self.eval_expr(self.ast.get_extra(extra_start))
        if old_signal.kind != ComptimeControlKind.CTL_VALUE:
            return old_signal
        let new_signal = self.eval_expr(self.ast.get_extra(extra_start + 1))
        if new_signal.kind != ComptimeControlKind.CTL_VALUE:
            return new_signal
        if old_signal.value.kind != ComptimeValueKind.CV_STR or new_signal.value.kind != ComptimeValueKind.CV_STR:
            return self.fail(node, "str.replace() arguments must be strings")
        return comptime_control_value(comptime_value_str(with_str_replace(text, old_signal.value.text, new_signal.value.text)))
    self.fail(node, "str method '" ++ method ++ "' is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_resolved_method_call(self: ComptimeEvaluator, fn_sym: i32, recv_value: ComptimeValue, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    if fn_sym == 0:
        return self.fail(node, "method was not resolved for comptime evaluation")
    let args: Vec[ComptimeValue] = Vec.new()
    args.push(recv_value)
    for i in 0..arg_count:
        let arg_signal = self.eval_expr(self.ast.get_extra(extra_start + i))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        args.push(arg_signal.value)
    self.eval_fn_symbol_call_values(fn_sym, args, node)

fn ComptimeEvaluator.eval_pipeline_method_call(self: ComptimeEvaluator, lhs: i32, method: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let recv_signal = self.eval_expr(lhs)
    if recv_signal.kind != ComptimeControlKind.CTL_VALUE:
        return recv_signal
    if recv_signal.value.kind == ComptimeValueKind.CV_VEC or recv_signal.value.kind == ComptimeValueKind.CV_BYTES:
        if recv_signal.value.kind == ComptimeValueKind.CV_BYTES:
            return self.eval_bytes_method_call(lhs, recv_signal.value, method, extra_start, arg_count, node)
        return self.eval_vec_method_call(lhs, recv_signal.value, method, extra_start, arg_count, node)
    if recv_signal.value.kind == ComptimeValueKind.CV_MAP:
        return self.eval_map_method_call(lhs, recv_signal.value, method, extra_start, arg_count, node)
    if recv_signal.value.kind == ComptimeValueKind.CV_STR:
        return self.eval_str_method_call(recv_signal.value, method, extra_start, arg_count, node)
    self.fail(node, "pipeline method '" ++ self.pool.resolve(method) ++ "' is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_pipeline(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let lhs = self.ast.get_data0(node)
    let rhs = self.ast.get_data1(node)
    var callee = rhs
    var args_start = -1
    var arg_count = 0
    if self.ast.kind(rhs) == NodeKind.NK_CALL:
        callee = self.ast.get_data0(rhs)
        args_start = self.ast.get_data1(rhs)
        arg_count = self.ast.get_data2(rhs)
    if self.sema.pipeline_method_calls.contains(node):
        return self.eval_pipeline_method_call(lhs, self.sema.pipeline_method_calls.get(node).unwrap(), args_start, arg_count, node)
    if self.ast.kind(callee) != NodeKind.NK_IDENT:
        return self.fail(node, "pipeline rhs is not comptime-evaluable")
    let lhs_signal = self.eval_expr(lhs)
    if lhs_signal.kind != ComptimeControlKind.CTL_VALUE:
        return lhs_signal
    let fn_sym = self.ast.get_data0(callee)
    let args: Vec[ComptimeValue] = Vec.new()
    args.push(lhs_signal.value)
    for i in 0..arg_count:
        let arg_signal = self.eval_expr(self.ast.get_extra(args_start + i))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        args.push(arg_signal.value)
    self.eval_fn_symbol_call_values(fn_sym, args, node)

fn ComptimeEvaluator.eval_static_type_method_call(self: ComptimeEvaluator, recv_type: i32, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let layout_sema = self.sema
    let method = self.pool.resolve(field)
    let resolved_recv = self.sema.resolve_alias(recv_type)
    if self.sema.enum_has_variant(resolved_recv as i32, field) != 0:
        let variant_sym = self.sema.qualified_enum_variant_sym(resolved_recv as i32, field)
        return self.eval_variant_constructor_call(variant_sym, extra_start, arg_count, node)
    if method == "name":
        if arg_count != 0:
            return self.fail(node, "type.name() takes no arguments")
        return comptime_control_value(comptime_value_str(self.sema.type_name(recv_type)))
    if method == "size":
        if arg_count != 0:
            return self.fail(node, "type.size() takes no arguments")
        return comptime_control_value(comptime_value_int(self.sema.ty_usize as i32, layout_sema.type_layout_size_of(recv_type)))
    if method == "align":
        if arg_count != 0:
            return self.fail(node, "type.align() takes no arguments")
        return comptime_control_value(comptime_value_int(self.sema.ty_usize as i32, layout_sema.type_layout_align_of(recv_type)))
    if method == "is_copy":
        if arg_count != 0:
            return self.fail(node, "type.is_copy() takes no arguments")
        return comptime_control_value(comptime_value_bool(self.sema.is_copy(recv_type)))
    if method == "implements":
        if arg_count != 1:
            return self.fail(node, "type.implements() expects exactly one trait argument")
        let trait_node = self.ast.get_extra(extra_start)
        if trait_node == 0:
            return self.fail(node, "type.implements() requires a trait name")
        let trait_kind = self.ast.kind(trait_node)
        if trait_kind != NodeKind.NK_IDENT and trait_kind != NodeKind.NK_TYPE_NAMED:
            return self.fail(trait_node, "type.implements() requires a trait name")
        let trait_sym = self.ast.get_data0(trait_node)
        if not self.sema.lang_trait_syms.contains(trait_sym) and not self.sema.trait_lookup.contains(trait_sym):
            return self.fail(trait_node, "unknown trait '" ++ self.pool.resolve(trait_sym) ++ "'")
        return comptime_control_value(comptime_value_bool(self.sema.type_implements_trait(recv_type, trait_sym)))
    if method == "fields":
        if arg_count != 0:
            return self.fail(node, "type.fields() takes no arguments")
        let resolved = self.sema.resolve_alias(recv_type)
        let tk = self.sema.get_type_kind(resolved)
        if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_GENERIC_INST:
            return self.fail(node, "type.fields() requires a struct type")
        return self.eval_type_fields_array(recv_type)
    if method == "variants":
        if arg_count != 0:
            return self.fail(node, "type.variants() takes no arguments")
        if self.sema.type_reflection_variant_base(recv_type) == 0:
            return self.fail(node, "type.variants() requires an enum type")
        return self.eval_type_variants_array(recv_type)
    self.fail(node, "type method '" ++ method ++ "' is not comptime-evaluable yet")

fn ComptimeEvaluator.eval_variant_constructor_call(self: ComptimeEvaluator, variant_sym: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    var resolved_variant = variant_sym
    if self.sema.comp_resolved.contains(node):
        resolved_variant = self.sema.comp_resolved.get(node).unwrap()
    if not self.sema.variant_lookup.contains(resolved_variant):
        return self.fail(node, "enum variant constructor is not resolved for comptime")
    var enum_type = self.node_type_or(node, 0)
    if enum_type == 0 and self.sema.variant_type_ids.contains(resolved_variant):
        enum_type = self.sema.variant_type_ids.get(resolved_variant).unwrap()
    if enum_type == 0:
        return self.fail(node, "enum variant constructor type is unknown in comptime")
    let payload_start = self.extra_values.len() as i32
    for i in 0..arg_count:
        let arg_signal = self.eval_expr(self.ast.get_extra(extra_start + i))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        self.extra_values.push(arg_signal.value)
    comptime_control_value(comptime_value_enum(enum_type, resolved_variant, payload_start, arg_count))

fn ComptimeEvaluator.capability_expect_arg_count(self: ComptimeEvaluator, arg_count: i32, expected: i32, method: str, node: i32) -> bool:
    if arg_count == expected:
        return true
    let _ = self.fail(node, "wrong argument count for capability method " ++ method)
    false

fn ComptimeEvaluator.capability_args(self: ComptimeEvaluator, extra_start: i32, arg_count: i32) -> ComptimeControl:
    var values: Vec[ComptimeValue] = Vec.new()
    for i in 0..arg_count:
        let arg_signal = self.eval_expr(self.ast.get_extra(extra_start + i))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        values.push(arg_signal.value)
    let start = self.extra_values.len() as i32
    for i in 0..values.len() as i32:
        self.extra_values.push(values.get(i as i64))
    comptime_control_value(comptime_value_tuple(0, start, arg_count))

fn ComptimeEvaluator.capability_arg_str(self: ComptimeEvaluator, args: ComptimeValue, index: i32, method: str, node: i32) -> str:
    let value = self.extra_values.get((args.extra_start + index) as i64)
    if value.kind != ComptimeValueKind.CV_STR:
        let _ = self.fail(node, "capability method " ++ method ++ " expects a string argument")
        return ""
    value.text

fn ComptimeEvaluator.capability_arg_i32(self: ComptimeEvaluator, args: ComptimeValue, index: i32, method: str, node: i32) -> i32:
    let value = self.extra_values.get((args.extra_start + index) as i64)
    if comptime_value_is_intlike(value) == 0:
        let _ = self.fail(node, "capability method " ++ method ++ " expects an integer argument")
        return 0
    comptime_value_intlike(value) as i32

fn ComptimeEvaluator.capability_resolve_project_path(self: ComptimeEvaluator, record: ComptimeCapabilityRecord, path: str, method: str, node: i32) -> str:
    if not comptime_tool_path_is_project_relative(path):
        let _ = self.fail(node, "ToolFs path escapes project root in " ++ method ++ ": " ++ path)
        return ""
    comptime_tool_join(record.project_root, path)

fn ComptimeEvaluator.capability_write_file_allowed(self: ComptimeEvaluator, record: ComptimeCapabilityRecord, path: str) -> bool:
    if record.write_scoped == 0:
        return true
    for i in 0..record.write_scope.len() as i32:
        if comptime_tool_path_is_same_or_child(path, record.write_scope.get(i as i64)):
            return true
    false

fn ComptimeEvaluator.capability_mkdir_allowed(self: ComptimeEvaluator, record: ComptimeCapabilityRecord, path: str) -> bool:
    if record.write_scoped == 0:
        return true
    for i in 0..record.write_scope.len() as i32:
        let allowed = record.write_scope.get(i as i64)
        if comptime_tool_path_is_same_or_child(path, allowed) or comptime_tool_path_is_parent_of(path, allowed):
            return true
    false

fn ComptimeEvaluator.capability_require_write_file_allowed(self: ComptimeEvaluator, record: ComptimeCapabilityRecord, path: str, method: str, node: i32) -> bool:
    if not comptime_tool_path_is_project_relative(path):
        let _ = self.fail(node, "ToolFs path escapes project root in " ++ method ++ ": " ++ path)
        return false
    if not self.capability_write_file_allowed(record, path):
        let _ = self.fail(node, "ToolFs write path is not a declared action output in " ++ method ++ ": " ++ path)
        return false
    true

fn ComptimeEvaluator.capability_require_mkdir_allowed(self: ComptimeEvaluator, record: ComptimeCapabilityRecord, path: str, method: str, node: i32) -> bool:
    if not comptime_tool_path_is_project_relative(path):
        let _ = self.fail(node, "ToolFs path escapes project root in " ++ method ++ ": " ++ path)
        return false
    if not self.capability_mkdir_allowed(record, path):
        let _ = self.fail(node, "ToolFs mkdir path is not a declared action output in " ++ method ++ ": " ++ path)
        return false
    true

fn ComptimeEvaluator.capability_project_relative_path(self: ComptimeEvaluator, record: ComptimeCapabilityRecord, path: str) -> str:
    if record.project_root.len() == 0 or record.project_root == ".":
        return path
    let prefix = if record.project_root.ends_with("/"): record.project_root else: record.project_root ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    path

fn ComptimeEvaluator.str_vec_value(self: ComptimeEvaluator, values: Vec[str], node: i32) -> ComptimeValue:
    let vec_type = self.node_type_or(node, 0)
    if vec_type == 0:
        let _ = self.fail(node, "string vector result type is unknown")
        return comptime_value_invalid()
    let start = self.extra_values.len() as i32
    for i in 0..values.len() as i32:
        self.extra_values.push(comptime_value_str(values.get(i as i64)))
    comptime_value_vec(vec_type, start, values.len() as i32)

fn ComptimeEvaluator.str_vec_value_with_type(self: ComptimeEvaluator, vec_type: i32, values: Vec[str]) -> ComptimeValue:
    let start = self.extra_values.len() as i32
    for i in 0..values.len() as i32:
        self.extra_values.push(comptime_value_str(values.get(i as i64)))
    comptime_value_vec(vec_type, start, values.len() as i32)

fn ComptimeEvaluator.struct_field_value_by_name(self: ComptimeEvaluator, value: ComptimeValue, field_name: str) -> ComptimeValue:
    if value.kind != ComptimeValueKind.CV_STRUCT:
        return comptime_value_invalid()
    let field_sym = self.pool.intern(field_name) as i32
    let index = self.struct_field_index(value.type_id, field_sym)
    if index < 0 or index >= value.extra_count:
        return comptime_value_invalid()
    self.extra_values.get((value.extra_start + index) as i64)

fn ComptimeEvaluator.vec_str_to_argv(self: ComptimeEvaluator, value: ComptimeValue, method: str, node: i32) -> str:
    if value.kind != ComptimeValueKind.CV_VEC and value.kind != ComptimeValueKind.CV_ARRAY:
        let _ = self.fail(node, "ProcessRunner." ++ method ++ "() expects Vec[str] args")
        return ""
    var out = ""
    for i in 0..value.extra_count:
        let item = self.extra_values.get((value.extra_start + i) as i64)
        if item.kind != ComptimeValueKind.CV_STR:
            let _ = self.fail(node, "ProcessRunner." ++ method ++ "() expects Vec[str] args")
            return ""
        out = out ++ item.text ++ "\0"
    out

fn ComptimeEvaluator.vec_str_to_argv_from_parts(self: ComptimeEvaluator, parts: Vec[str], method: str, node: i32) -> str:
    var out = ""
    for i in 0..parts.len() as i32:
        out = out ++ parts.get(i as i64) ++ "\0"
    out

fn ComptimeEvaluator.process_env_apply(self: ComptimeEvaluator, value: ComptimeValue, node: i32) -> ComptimeValue:
    let env_type = self.named_type_id("ProcessEnv", node)
    if env_type == 0:
        return comptime_value_invalid()
    if value.kind != ComptimeValueKind.CV_STRUCT:
        let _ = self.fail(node, "ProcessRunner env argument must be ProcessEnv")
        return comptime_value_invalid()
    let vars = self.struct_field_value_by_name(value, "vars")
    if vars.kind != ComptimeValueKind.CV_VEC and vars.kind != ComptimeValueKind.CV_ARRAY:
        let _ = self.fail(node, "ProcessEnv.vars is not a vector")
        return comptime_value_invalid()
    for i in 0..vars.extra_count:
        let item = self.extra_values.get((vars.extra_start + i) as i64)
        let name = self.struct_field_value_by_name(item, "name")
        let env_value = self.struct_field_value_by_name(item, "value")
        if name.kind != ComptimeValueKind.CV_STR or env_value.kind != ComptimeValueKind.CV_STR:
            let _ = self.fail(node, "ProcessEnv vars must contain string name/value fields")
            return comptime_value_invalid()
    let saved_start = self.extra_values.len() as i32
    let tool_token = with_getenv_str("WITH_TOOL_CAPABILITY_TOKEN") ++ ""
    let action_name = with_getenv_str("WITH_BUILD_ACTION_NAME") ++ ""
    let _clear_tool_token = with_setenv_str("WITH_TOOL_CAPABILITY_TOKEN", "")
    let _clear_action_name = with_setenv_str("WITH_BUILD_ACTION_NAME", "")
    for i in 0..vars.extra_count:
        let item = self.extra_values.get((vars.extra_start + i) as i64)
        let name = self.struct_field_value_by_name(item, "name")
        let env_value = self.struct_field_value_by_name(item, "value")
        self.extra_values.push(comptime_value_str(name.text))
        self.extra_values.push(comptime_value_str(with_getenv_str(name.text) ++ ""))
        let _set = with_setenv_str(name.text, env_value.text)
    self.extra_values.push(comptime_value_str("WITH_TOOL_CAPABILITY_TOKEN"))
    self.extra_values.push(comptime_value_str(tool_token))
    self.extra_values.push(comptime_value_str("WITH_BUILD_ACTION_NAME"))
    self.extra_values.push(comptime_value_str(action_name))
    comptime_value_vec(env_type, saved_start, vars.extra_count * 2 + 4)

fn ComptimeEvaluator.process_driver_env_clear(self: ComptimeEvaluator, node: i32) -> ComptimeValue:
    let env_type = self.named_type_id("ProcessEnv", node)
    if env_type == 0:
        return comptime_value_invalid()
    let saved_start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str("WITH_TOOL_CAPABILITY_TOKEN"))
    self.extra_values.push(comptime_value_str(with_getenv_str("WITH_TOOL_CAPABILITY_TOKEN") ++ ""))
    self.extra_values.push(comptime_value_str("WITH_BUILD_ACTION_NAME"))
    self.extra_values.push(comptime_value_str(with_getenv_str("WITH_BUILD_ACTION_NAME") ++ ""))
    let _clear_tool_token = with_setenv_str("WITH_TOOL_CAPABILITY_TOKEN", "")
    let _clear_action_name = with_setenv_str("WITH_BUILD_ACTION_NAME", "")
    comptime_value_vec(env_type, saved_start, 4)

fn ComptimeEvaluator.process_env_restore(self: ComptimeEvaluator, saved: ComptimeValue):
    if saved.kind != ComptimeValueKind.CV_VEC and saved.kind != ComptimeValueKind.CV_ARRAY:
        return
    var i = 0
    while i + 1 < saved.extra_count:
        let name = self.extra_values.get((saved.extra_start + i) as i64)
        let value = self.extra_values.get((saved.extra_start + i + 1) as i64)
        if name.kind == ComptimeValueKind.CV_STR and value.kind == ComptimeValueKind.CV_STR:
            let _restore = with_setenv_str(name.text, value.text)
        i = i + 2

fn ComptimeEvaluator.tool_process_result(self: ComptimeEvaluator, rc: i32, stdout_path: str, stderr_path: str, node: i32) -> ComptimeControl:
    let result_type = self.named_type_id("ToolProcessResult", node)
    if result_type == 0:
        return comptime_control_error()
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, rc as i64))
    self.extra_values.push(comptime_value_str(with_fs_read_file(stdout_path)))
    self.extra_values.push(comptime_value_str(with_fs_read_file(stderr_path)))
    self.extra_values.push(comptime_value_bool(if rc == 124: 1 else: 0))
    comptime_control_value(comptime_value_struct(result_type, start, 4))

fn ComptimeEvaluator.workspace_record_index(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, node: i32) -> i32:
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_WORKSPACE, method, node)
    if handle < 0:
        return -1
    let capability = self.capability_records.get(handle as i64)
    let workspace_id = capability.workspace_id
    if workspace_id < 0 or workspace_id >= self.workspace_records.len() as i32:
        let _ = self.fail(node, "invalid Workspace handle for " ++ method)
        return -1
    workspace_id

fn ComptimeEvaluator.workspace_path(self: ComptimeEvaluator, root: str, path: str) -> str:
    if path.len() == 0:
        return path
    if path.byte_at(0) == 47:
        return path
    let clean_root = if root.ends_with("/"): root.slice(0, root.len() - 1) else: root
    clean_root ++ "/" ++ path

fn ComptimeEvaluator.workspace_str_vec_field(self: ComptimeEvaluator, options: ComptimeValue, field_name: str) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let value = self.struct_field_value_by_name(options, field_name)
    if value.kind != ComptimeValueKind.CV_VEC and value.kind != ComptimeValueKind.CV_ARRAY:
        return out
    for i in 0..value.extra_count:
        let item = self.extra_values.get((value.extra_start + i) as i64)
        if item.kind == ComptimeValueKind.CV_STR:
            out.push(item.text)
    out

fn ComptimeEvaluator.workspace_str_option(self: ComptimeEvaluator, options: ComptimeValue, field_name: str) -> str:
    let value = self.struct_field_value_by_name(options, field_name)
    if value.kind == ComptimeValueKind.CV_STR:
        return value.text
    ""

fn ComptimeEvaluator.workspace_i32_option(self: ComptimeEvaluator, options: ComptimeValue, field_name: str, default_value: i32) -> i32:
    let value = self.struct_field_value_by_name(options, field_name)
    if comptime_value_is_intlike(value) != 0:
        return value.data0 as i32
    if value.kind == ComptimeValueKind.CV_ENUM:
        let sym = value.data0 as i32
        if self.sema.variant_type_ids.contains(sym):
            let enum_tid = self.sema.variant_type_ids.get(sym).unwrap()
            let enum_resolved = self.sema.resolve_alias(enum_tid as TypeId)
            if self.sema.disc_repr_types.contains(enum_resolved as i32) and not self.sema.disc_has_payload.contains(enum_resolved as i32):
                return if self.sema.disc_values.contains(sym): self.sema.disc_values.get(sym).unwrap() else: self.sema.variant_lookup.get(sym).unwrap()
    default_value

fn ComptimeEvaluator.workspace_bool_option(self: ComptimeEvaluator, options: ComptimeValue, field_name: str, default_value: bool) -> bool:
    let value = self.struct_field_value_by_name(options, field_name)
    if value.kind == ComptimeValueKind.CV_BOOL:
        return value.data0 != 0
    default_value

fn ComptimeEvaluator.workspace_path_vec_field(self: ComptimeEvaluator, root: str, options: ComptimeValue, field_name: str) -> Vec[str]:
    let raw = self.workspace_str_vec_field(options, field_name)
    let out: Vec[str] = Vec.new()
    for i in 0..raw.len() as i32:
        out.push(self.workspace_path(root, raw.get(i as i64)))
    out

fn ComptimeEvaluator.workspace_exclude_basenames_field(self: ComptimeEvaluator, options: ComptimeValue) -> str:
    let excludes = self.workspace_str_vec_field(options, "exclude_basenames")
    var out = ""
    for i in 0..excludes.len() as i32:
        out = out ++ "|" ++ excludes.get(i as i64) ++ "|"
    out

fn ComptimeEvaluator.workspace_artifact_kind_for_output(self: ComptimeEvaluator, output_kind: i32) -> i32:
    if output_kind == 1: return 1
    if output_kind == 2: return 4
    if output_kind == 3: return 5
    if output_kind == 4: return 2
    if output_kind == 5: return 6
    0

fn ComptimeEvaluator.workspace_build_result_value(self: ComptimeEvaluator, workspace_name: str, rc: i32, artifact_kind: i32, artifact_path: str, node: i32) -> ComptimeValue:
    let result_type = self.named_type_id("BuildResult", node)
    let artifact_type = self.named_type_id("Artifact", node)
    let build_status_type = self.named_type_id("BuildStatus", node)
    let artifact_kind_type = self.named_type_id("ArtifactKind", node)
    if result_type == 0 or artifact_type == 0 or build_status_type == 0 or artifact_kind_type == 0:
        return comptime_value_invalid()
    let artifact_vec = self.empty_vec_for_field(result_type, "artifacts", node)
    let diagnostic_vec = self.empty_vec_for_field(result_type, "diagnostics", node)
    if artifact_vec.kind == ComptimeValueKind.CV_INVALID or diagnostic_vec.kind == ComptimeValueKind.CV_INVALID:
        return comptime_value_invalid()

    let artifact_vec_type = artifact_vec.type_id
    var artifacts = artifact_vec
    if rc == 0 and artifact_path.len() > 0:
        let artifact_start = self.extra_values.len() as i32
        self.extra_values.push(comptime_value_int(artifact_kind_type, artifact_kind as i64))
        self.extra_values.push(comptime_value_str(artifact_path))
        let artifact = comptime_value_struct(artifact_type, artifact_start, 2)
        let vec_start = self.extra_values.len() as i32
        self.extra_values.push(artifact)
        artifacts = comptime_value_vec(artifact_vec_type, vec_start, 1)

    let result_start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_int(build_status_type, if rc == 0: 0 else: 1))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, rc as i64))
    self.extra_values.push(comptime_value_str(workspace_name))
    self.extra_values.push(artifacts)
    self.extra_values.push(diagnostic_vec)
    comptime_value_struct(result_type, result_start, 5)

fn comptime_workspace_compile_result(result: ComptimeValue, messages: Vec[ComptimeValue]) -> ComptimeWorkspaceCompileResult:
    ComptimeWorkspaceCompileResult { result, messages }

fn comptime_workspace_compile_invalid() -> ComptimeWorkspaceCompileResult:
    let messages: Vec[ComptimeValue] = Vec.new()
    comptime_workspace_compile_result(comptime_value_invalid(), messages)

fn comptime_module_name_for_path(root: str, path: str) -> str:
    var rel = path
    let prefix = if root.ends_with("/"): root else: root ++ "/"
    if root.len() > 0 and path.starts_with(prefix):
        rel = path.slice(prefix.len(), path.len())
    if rel.ends_with(".w"):
        rel = rel.slice(0, rel.len() - 2)
    var out = ""
    for i in 0..rel.len() as i32:
        let ch = rel.byte_at(i as i64)
        if ch == 47:
            out = out ++ "."
        else:
            out = out ++ rel.slice(i as i64, (i + 1) as i64)
    out

fn comptime_line_column_for_offset(text: str, offset: i32) -> ComptimeLineColumn:
    var line = 0
    var column = 0
    var i = 0
    let clamped = if offset < 0: 0 else if offset > text.len() as i32: text.len() as i32 else: offset
    while i < clamped:
        if text.byte_at(i as i64) == 10:
            line = line + 1
            column = 0
        else:
            column = column + 1
        i = i + 1
    ComptimeLineColumn { line, column }

fn ComptimeEvaluator.source_span_value(self: ComptimeEvaluator, file: str, text: str, start: i32, end: i32, node: i32) -> ComptimeValue:
    let span_type = self.named_type_id("SourceSpan", node)
    if span_type == 0:
        return comptime_value_invalid()
    let loc = comptime_line_column_for_offset(text, start)
    let span_start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str(file))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, start as i64))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, end as i64))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, loc.line as i64))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, loc.column as i64))
    comptime_value_struct(span_type, span_start, 5)

fn ComptimeEvaluator.decl_summary_vec_type(self: ComptimeEvaluator, node: i32) -> i32:
    let decl_type = self.named_type_id("DeclSummary", node)
    if decl_type == 0:
        return 0
    let args: Vec[i32] = Vec.new()
    args.push(decl_type)
    let tid = self.sema.find_generic_inst_type(self.sema.syms.vec, args, 1) as i32
    if tid == 0:
        let _ = self.fail(node, "Vec[DeclSummary] type is not visible to comptime evaluator")
    tid

fn comptime_decl_kind_for_function(name: str) -> i32:
    if name.contains("."):
        return 3
    0

fn ComptimeEvaluator.function_decl_summary_value(self: ComptimeEvaluator, comp: Compilation, pool: AstPool, decl: NodeId, decl_index: i32, node: i32) -> ComptimeValue:
    let decl_type = self.named_type_id("DeclSummary", node)
    let kind_type = self.named_type_id("DeclKind", node)
    if decl_type == 0 or kind_type == 0:
        return comptime_value_invalid()
    let path = comp.zcu.decl_source_path_frontend(decl_index)
    let file_id = comp.zcu.decl_source_file_id_frontend(decl_index)
    let source = comp.zcu.source_for_file_id_frontend(file_id)
    let module_name = comptime_module_name_for_path(comp.zcu.project_config.root_dir, path)
    let name = comp.zcu.pool.resolve(pool.get_data0(decl))
    let flags = pool.get_data2(decl)
    let is_pub = (flags / FnFlags.PUB) % 2 == 1
    let meta = pool.find_fn_meta(decl)
    var param_count = 0
    var generic_param_count = 0
    var return_type = "void"
    if meta >= 0:
        param_count = pool.fn_meta_param_count(meta)
        generic_param_count = pool.fn_meta_tp_count(meta)
        let ret_node = pool.fn_meta_ret(meta)
        if ret_node != 0:
            return_type = render_type_expr(pool, comp.zcu.pool, ret_node as NodeId)
    let summary_source = self.source_span_value(path, source.text, pool.get_start(decl), pool.get_end(decl), node)
    if summary_source.kind == ComptimeValueKind.CV_INVALID:
        return summary_source
    let notes = self.empty_vec_for_field(decl_type, "notes", node)
    if notes.kind == ComptimeValueKind.CV_INVALID:
        return notes
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, 1))
    self.extra_values.push(comptime_value_int(kind_type, comptime_decl_kind_for_function(name) as i64))
    self.extra_values.push(comptime_value_str(module_name))
    self.extra_values.push(comptime_value_str(name))
    self.extra_values.push(comptime_value_str(module_name ++ "." ++ name))
    self.extra_values.push(comptime_value_bool(if is_pub: 1 else: 0))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_str("fn"))
    self.extra_values.push(comptime_value_str(return_type))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, param_count as i64))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, generic_param_count as i64))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(summary_source)
    self.extra_values.push(notes)
    comptime_value_struct(decl_type, start, 14)

fn ComptimeEvaluator.type_decl_summary_value(self: ComptimeEvaluator, comp: Compilation, pool: AstPool, decl: NodeId, decl_index: i32, node: i32) -> ComptimeValue:
    let decl_type = self.named_type_id("DeclSummary", node)
    let kind_type = self.named_type_id("DeclKind", node)
    if decl_type == 0 or kind_type == 0:
        return comptime_value_invalid()
    let path = comp.zcu.decl_source_path_frontend(decl_index)
    let file_id = comp.zcu.decl_source_file_id_frontend(decl_index)
    let source = comp.zcu.source_for_file_id_frontend(file_id)
    let module_name = comptime_module_name_for_path(comp.zcu.project_config.root_dir, path)
    let name = comp.zcu.pool.resolve(pool.get_data0(decl))
    let packed = pool.get_data2(decl)
    let sub_kind = type_decl_sub_kind(packed)
    let is_pub = type_decl_is_pub(pool, pool.get_data1(decl), sub_kind)
    let summary_source = self.source_span_value(path, source.text, pool.get_start(decl), pool.get_end(decl), node)
    if summary_source.kind == ComptimeValueKind.CV_INVALID:
        return summary_source
    let notes = self.empty_vec_for_field(decl_type, "notes", node)
    if notes.kind == ComptimeValueKind.CV_INVALID:
        return notes
    let type_text =
        if sub_kind == TypeDeclKind.Enum:
            "enum"
        else if sub_kind == TypeDeclKind.DiscEnum:
            "disc_enum"
        else if sub_kind == TypeDeclKind.Union:
            "union"
        else:
            "type"
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, 1))
    self.extra_values.push(comptime_value_int(kind_type, 1))
    self.extra_values.push(comptime_value_str(module_name))
    self.extra_values.push(comptime_value_str(name))
    self.extra_values.push(comptime_value_str(module_name ++ "." ++ name))
    self.extra_values.push(comptime_value_bool(if is_pub: 1 else: 0))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_str(type_text))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, 0))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, 0))
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(summary_source)
    self.extra_values.push(notes)
    comptime_value_struct(decl_type, start, 14)

fn ComptimeEvaluator.typechecked_message_value(self: ComptimeEvaluator, comp: Compilation, pool: AstPool, node: i32) -> ComptimeValue:
    let vec_type = self.decl_summary_vec_type(node)
    if vec_type == 0:
        return comptime_value_invalid()
    let summaries: Vec[ComptimeValue] = Vec.new()
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind == NodeKind.NK_FN_DECL:
            let summary = self.function_decl_summary_value(comp, pool, decl, di, node)
            if summary.kind == ComptimeValueKind.CV_INVALID:
                return summary
            summaries.push(summary)
        else if kind == NodeKind.NK_TYPE_DECL:
            let summary = self.type_decl_summary_value(comp, pool, decl, di, node)
            if summary.kind == ComptimeValueKind.CV_INVALID:
                return summary
            summaries.push(summary)
    let start = self.extra_values.len() as i32
    for i in 0..summaries.len() as i32:
        self.extra_values.push(summaries.get(i as i64))
    let decls = comptime_value_vec(vec_type, start, summaries.len() as i32)
    let payloads: Vec[ComptimeValue] = Vec.new()
    payloads.push(decls)
    self.compiler_message_value("Typechecked", payloads, node)

fn ComptimeEvaluator.workspace_typechecked_messages(self: ComptimeEvaluator, comp: Compilation, pool: AstPool, node: i32) -> Vec[ComptimeValue]:
    let messages: Vec[ComptimeValue] = Vec.new()
    if pool.decl_count() == 0:
        return messages
    let phase = self.compiler_message_phase_value(3, node)
    if phase.kind == ComptimeValueKind.CV_INVALID:
        return messages
    let typechecked = self.typechecked_message_value(comp, pool, node)
    if typechecked.kind == ComptimeValueKind.CV_INVALID:
        return messages
    messages.push(phase)
    messages.push(typechecked)
    messages

fn ComptimeEvaluator.workspace_phase_message_append(self: ComptimeEvaluator, messages: Vec[ComptimeValue], phase_value: i32, node: i32) -> Vec[ComptimeValue]:
    let phase = self.compiler_message_phase_value(phase_value, node)
    if phase.kind == ComptimeValueKind.CV_INVALID:
        return messages
    messages.push(phase)
    messages

fn ComptimeEvaluator.workspace_success_messages(self: ComptimeEvaluator, comp: Compilation, pool: AstPool, node: i32) -> Vec[ComptimeValue]:
    var messages: Vec[ComptimeValue] = Vec.new()
    messages = self.workspace_phase_message_append(messages, 0, node)
    messages = self.workspace_phase_message_append(messages, 1, node)
    messages = self.workspace_phase_message_append(messages, 2, node)
    let typechecked = self.workspace_typechecked_messages(comp, pool, node)
    for mi in 0..typechecked.len() as i32:
        messages.push(typechecked.get(mi as i64))
    messages = self.workspace_phase_message_append(messages, 4, node)
    messages = self.workspace_phase_message_append(messages, 5, node)
    messages = self.workspace_phase_message_append(messages, 6, node)
    if comp.last_link_command_available != 0:
        messages = self.workspace_phase_message_append(messages, 7, node)
        let prelink = self.compiler_message_prelink_value(comp.last_link_command, node)
        if prelink.kind != ComptimeValueKind.CV_INVALID:
            messages.push(prelink)
        messages = self.workspace_phase_message_append(messages, 8, node)
        let linked = self.compiler_message_linked_value(comp.last_link_command, comp.last_link_rc, node)
        if linked.kind != ComptimeValueKind.CV_INVALID:
            messages.push(linked)
    messages

fn ComptimeEvaluator.enum_payload_value(self: ComptimeEvaluator, enum_name: str, variant_name: str, payloads: Vec[ComptimeValue], node: i32) -> ComptimeValue:
    let enum_type = self.named_type_id(enum_name, node)
    if enum_type == 0:
        return comptime_value_invalid()
    let variant_sym = self.pool.intern(enum_name ++ "." ++ variant_name) as i32
    if not self.sema.variant_lookup.contains(variant_sym):
        let _ = self.fail(node, "missing enum variant '" ++ enum_name ++ "." ++ variant_name ++ "'")
        return comptime_value_invalid()
    let payload_start = self.extra_values.len() as i32
    for i in 0..payloads.len() as i32:
        self.extra_values.push(payloads.get(i as i64))
    comptime_value_enum(enum_type, variant_sym, payload_start, payloads.len() as i32)

fn ComptimeEvaluator.compiler_message_value(self: ComptimeEvaluator, variant_name: str, payloads: Vec[ComptimeValue], node: i32) -> ComptimeValue:
    self.enum_payload_value("CompilerMessage", variant_name, payloads, node)

fn ComptimeEvaluator.compiler_phase_value(self: ComptimeEvaluator, phase_value: i32, node: i32) -> ComptimeValue:
    let phase_type = self.named_type_id("CompilerPhase", node)
    if phase_type == 0:
        return comptime_value_invalid()
    comptime_value_int(phase_type, phase_value as i64)

fn ComptimeEvaluator.compiler_message_phase_value(self: ComptimeEvaluator, phase_value: i32, node: i32) -> ComptimeValue:
    let phase = self.compiler_phase_value(phase_value, node)
    if phase.kind == ComptimeValueKind.CV_INVALID:
        return phase
    let payloads: Vec[ComptimeValue] = Vec.new()
    payloads.push(phase)
    self.compiler_message_value("Phase", payloads, node)

fn ComptimeEvaluator.compiler_message_artifact_value(self: ComptimeEvaluator, artifact: ComptimeValue, node: i32) -> ComptimeValue:
    let payloads: Vec[ComptimeValue] = Vec.new()
    payloads.push(artifact)
    self.compiler_message_value("Artifact", payloads, node)

fn ComptimeEvaluator.link_command_value(self: ComptimeEvaluator, command: LinkStageCommand, node: i32) -> ComptimeValue:
    let command_type = self.named_type_id("LinkCommand", node)
    if command_type == 0:
        return comptime_value_invalid()
    let args = self.empty_vec_for_field(command_type, "args", node)
    let env = self.empty_vec_for_field(command_type, "env", node)
    let inputs = self.empty_vec_for_field(command_type, "inputs", node)
    let outputs = self.empty_vec_for_field(command_type, "outputs", node)
    if args.kind == ComptimeValueKind.CV_INVALID or env.kind == ComptimeValueKind.CV_INVALID or inputs.kind == ComptimeValueKind.CV_INVALID or outputs.kind == ComptimeValueKind.CV_INVALID:
        return comptime_value_invalid()
    let args_value = self.str_vec_value_with_type(args.type_id, command.args)
    let env_value = self.link_command_env_value_with_type(env.type_id, command.env, node)
    let inputs_value = self.str_vec_value_with_type(inputs.type_id, command.inputs)
    let outputs_value = self.str_vec_value_with_type(outputs.type_id, command.outputs)
    if env_value.kind == ComptimeValueKind.CV_INVALID:
        return comptime_value_invalid()
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str(command.linker))
    self.extra_values.push(args_value)
    self.extra_values.push(comptime_value_str(command.cwd))
    self.extra_values.push(env_value)
    self.extra_values.push(inputs_value)
    self.extra_values.push(outputs_value)
    comptime_value_struct(command_type, start, 6)

fn ComptimeEvaluator.link_command_env_value_with_type(self: ComptimeEvaluator, vec_type: i32, values: Vec[LinkStageEnvVar], node: i32) -> ComptimeValue:
    let env_type = self.named_type_id("EnvVar", node)
    if env_type == 0:
        return comptime_value_invalid()
    let items: Vec[ComptimeValue] = Vec.new()
    for i in 0..values.len() as i32:
        let item = values.get(i as i64)
        let field_start = self.extra_values.len() as i32
        self.extra_values.push(comptime_value_str(item.name))
        self.extra_values.push(comptime_value_str(item.value))
        items.push(comptime_value_struct(env_type, field_start, 2))
    let vec_start = self.extra_values.len() as i32
    for i in 0..items.len() as i32:
        self.extra_values.push(items.get(i as i64))
    comptime_value_vec(vec_type, vec_start, items.len() as i32)

fn ComptimeEvaluator.link_command_str_field(self: ComptimeEvaluator, value: ComptimeValue, name: str, node: i32) -> str:
    let field = self.struct_field_value_by_name(value, name)
    if field.kind != ComptimeValueKind.CV_STR:
        let _ = self.fail(node, "LinkCommand." ++ name ++ " must be a string")
        return ""
    field.text

fn ComptimeEvaluator.link_command_str_vec_field(self: ComptimeEvaluator, value: ComptimeValue, name: str, node: i32) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    let field = self.struct_field_value_by_name(value, name)
    if field.kind != ComptimeValueKind.CV_VEC and field.kind != ComptimeValueKind.CV_ARRAY:
        let _ = self.fail(node, "LinkCommand." ++ name ++ " must be a Vec[str]")
        return out
    for i in 0..field.extra_count:
        let item = self.extra_values.get((field.extra_start + i) as i64)
        if item.kind != ComptimeValueKind.CV_STR:
            let _ = self.fail(node, "LinkCommand." ++ name ++ " contains a non-string value")
            return out
        out.push(item.text)
    out

fn ComptimeEvaluator.link_command_env_field(self: ComptimeEvaluator, value: ComptimeValue, node: i32) -> Vec[LinkStageEnvVar]:
    let out: Vec[LinkStageEnvVar] = Vec.new()
    let field = self.struct_field_value_by_name(value, "env")
    if field.kind != ComptimeValueKind.CV_VEC and field.kind != ComptimeValueKind.CV_ARRAY:
        let _ = self.fail(node, "LinkCommand.env must be a Vec[EnvVar]")
        return out
    for i in 0..field.extra_count:
        let item = self.extra_values.get((field.extra_start + i) as i64)
        if item.kind != ComptimeValueKind.CV_STRUCT:
            let _ = self.fail(node, "LinkCommand.env contains a non-EnvVar value")
            return out
        let name = self.struct_field_value_by_name(item, "name")
        let env_value = self.struct_field_value_by_name(item, "value")
        if name.kind != ComptimeValueKind.CV_STR or env_value.kind != ComptimeValueKind.CV_STR:
            let _ = self.fail(node, "LinkCommand.env entries must contain string name and value fields")
            return out
        out.push(LinkStageEnvVar { name: name.text, value: env_value.text })
    out

fn ComptimeEvaluator.link_command_from_value(self: ComptimeEvaluator, value: ComptimeValue, node: i32) -> LinkStageCommand:
    let linker = self.link_command_str_field(value, "linker", node)
    let cwd = self.link_command_str_field(value, "cwd", node)
    let args = self.link_command_str_vec_field(value, "args", node)
    let env = self.link_command_env_field(value, node)
    let inputs = self.link_command_str_vec_field(value, "inputs", node)
    let outputs = self.link_command_str_vec_field(value, "outputs", node)
    LinkStageCommand { linker, args, cwd, env, inputs, outputs }

fn link_command_outputs_superset(replacement: LinkStageCommand, original: LinkStageCommand) -> bool:
    for oi in 0..original.outputs.len() as i32:
        let output = original.outputs.get(oi as i64)
        var found = false
        for ri in 0..replacement.outputs.len() as i32:
            if replacement.outputs.get(ri as i64) == output:
                found = true
        if not found:
            return false
    true

fn ComptimeEvaluator.compiler_message_prelink_value(self: ComptimeEvaluator, command: LinkStageCommand, node: i32) -> ComptimeValue:
    let command_value = self.link_command_value(command, node)
    if command_value.kind == ComptimeValueKind.CV_INVALID:
        return command_value
    let payloads: Vec[ComptimeValue] = Vec.new()
    payloads.push(command_value)
    self.compiler_message_value("PreLink", payloads, node)

fn ComptimeEvaluator.compiler_message_linked_value(self: ComptimeEvaluator, command: LinkStageCommand, rc: i32, node: i32) -> ComptimeValue:
    let command_value = self.link_command_value(command, node)
    if command_value.kind == ComptimeValueKind.CV_INVALID:
        return command_value
    let payloads: Vec[ComptimeValue] = Vec.new()
    payloads.push(command_value)
    payloads.push(comptime_value_int(self.sema.ty_i32 as i32, rc as i64))
    self.compiler_message_value("Linked", payloads, node)

fn ComptimeEvaluator.enqueue_artifact_messages(self: ComptimeEvaluator, record: ComptimeWorkspaceRecord, result: ComptimeValue, node: i32) -> ComptimeWorkspaceRecord:
    let artifacts = self.struct_field_value_by_name(result, "artifacts")
    if artifacts.kind != ComptimeValueKind.CV_VEC and artifacts.kind != ComptimeValueKind.CV_ARRAY:
        return record
    var out = record
    for i in 0..artifacts.extra_count:
        let artifact = self.extra_values.get((artifacts.extra_start + i) as i64)
        let message = self.compiler_message_artifact_value(artifact, node)
        if message.kind == ComptimeValueKind.CV_INVALID:
            return out
        out.messages.push(message)
    out

fn ComptimeEvaluator.enqueue_workspace_compile_result(self: ComptimeEvaluator, record: ComptimeWorkspaceRecord, result: ComptimeValue, messages: Vec[ComptimeValue], node: i32) -> ComptimeWorkspaceRecord:
    var out = record
    for mi in 0..messages.len() as i32:
        out.messages.push(messages.get(mi as i64))
    out = self.enqueue_artifact_messages(out, result, node)
    if self.had_error != 0:
        return out
    let phase_message = self.compiler_message_phase_value(9, node)
    if phase_message.kind == ComptimeValueKind.CV_INVALID:
        return out
    let complete_message = self.compiler_message_complete_value(result, node)
    if complete_message.kind == ComptimeValueKind.CV_INVALID:
        return out
    out.messages.push(phase_message)
    out.messages.push(complete_message)
    out.intercept_terminal = 1
    out

fn ComptimeEvaluator.compiler_message_complete_value(self: ComptimeEvaluator, result: ComptimeValue, node: i32) -> ComptimeValue:
    let payloads: Vec[ComptimeValue] = Vec.new()
    payloads.push(result)
    self.compiler_message_value("Complete", payloads, node)

fn ComptimeEvaluator.compiler_message_error_value(self: ComptimeEvaluator, code: i32, message: str, node: i32) -> ComptimeValue:
    let span_type = self.named_type_id("SourceSpan", node)
    if span_type == 0:
        return comptime_value_invalid()
    let span_start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str(""))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, -1))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, -1))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, -1))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, -1))
    let span = comptime_value_struct(span_type, span_start, 5)
    let payloads: Vec[ComptimeValue] = Vec.new()
    payloads.push(comptime_value_int(self.sema.ty_i32 as i32, code as i64))
    payloads.push(comptime_value_str(message))
    payloads.push(span)
    self.compiler_message_value("Error", payloads, node)

fn ComptimeEvaluator.compiler_message_envelope_value(self: ComptimeEvaluator, workspace_name: str, generation: i32, message: ComptimeValue, node: i32) -> ComptimeValue:
    let envelope_type = self.named_type_id("CompilerMessageEnvelope", node)
    if envelope_type == 0:
        return comptime_value_invalid()
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str(workspace_name))
    self.extra_values.push(comptime_value_int(self.sema.ty_i32 as i32, generation as i64))
    self.extra_values.push(message)
    comptime_value_struct(envelope_type, start, 3)

fn ComptimeEvaluator.compiler_message_phase_id(self: ComptimeEvaluator, message: ComptimeValue) -> i32:
    if message.kind != ComptimeValueKind.CV_ENUM:
        return -1
    let phase_variant = self.pool.intern("CompilerMessage.Phase") as i32
    if message.data0 as i32 != phase_variant:
        return -1
    if message.extra_count != 1:
        return -1
    let payload = self.extra_values.get(message.extra_start as i64)
    if comptime_value_is_intlike(payload) == 0:
        return -1
    comptime_value_intlike(payload) as i32

fn comptime_workspace_compile_plan_invalid() -> ComptimeWorkspaceCompilePlan:
    ComptimeWorkspaceCompilePlan {
        valid: 0,
        name: "",
        is_migrate: 0,
        final_output: "",
        absolute_output: "",
        output_kind: 0,
        has_strings: 0,
        source_paths: Vec.new(),
        source_texts: Vec.new(),
        absolute_source: "",
        include_paths: Vec.new(),
        defines: Vec.new(),
        link_libs: Vec.new(),
        opt_level: 0,
        no_std: false,
        alloc_mode: false,
        runtime_available: true,
        debug_info: false,
        compiler_hooks_enabled: false,
        prelude_mode: 0,
        migrate_is_dir: 0,
        migrate_source: "",
        migrate_include_paths: Vec.new(),
        migrate_forced_includes: Vec.new(),
        migrate_defines: Vec.new(),
        migrate_exclude_basenames: "",
        migrate_no_c_export: false,
        migrate_c_export_functions: false,
        migrate_convert_goto_to_structured: false,
        migrate_block_style: 0,
        migrate_width_slice: 0,
        migrate_shared_defs: "",
        migrate_one: "",
        migrate_shared_fragment: "",
    }

fn comptime_workspace_native_compile_invalid() -> ComptimeWorkspaceNativeCompileResult:
    ComptimeWorkspaceNativeCompileResult { rc: 1, artifact_path: "", comp: Compilation.init(), is_migrate: 0 }

fn comptime_workspace_output_kind_supported(kind: i32) -> bool:
    kind == 0 or kind == 1 or kind == 2 or kind == 4 or kind == 5

fn comptime_execute_workspace_migrate_plan(plan: ComptimeWorkspaceCompilePlan) -> i32:
    migrate_reset_options()
    for i in 0..plan.migrate_include_paths.len() as i32:
        migrate_add_include_path(plan.migrate_include_paths.get(i as i64))
    for i in 0..plan.migrate_forced_includes.len() as i32:
        migrate_add_forced_include(plan.migrate_forced_includes.get(i as i64))
    for i in 0..plan.migrate_defines.len() as i32:
        migrate_add_define(plan.migrate_defines.get(i as i64))
    if plan.migrate_no_c_export:
        migrate_set_no_c_export(1)
    if plan.migrate_c_export_functions:
        migrate_set_export_function_defs(1)
    if plan.migrate_convert_goto_to_structured:
        migrate_set_convert_goto_to_structured(1)
    migrate_set_block_style(plan.migrate_block_style)
    migrate_set_width_slice(plan.migrate_width_slice)
    if plan.migrate_shared_defs.len() > 0:
        migrate_set_shared_defs(plan.migrate_shared_defs)
    if plan.migrate_one.len() > 0:
        migrate_set_directory_one_basename(plan.migrate_one)
    if plan.migrate_shared_fragment.len() > 0:
        migrate_set_shared_fragment_path(plan.migrate_shared_fragment)
    if plan.migrate_is_dir != 0:
        return migrate_c_directory(plan.migrate_source, plan.absolute_output, plan.migrate_exclude_basenames)
    migrate_c_file(plan.migrate_source, plan.absolute_output)

fn ComptimeEvaluator.workspace_compile_plan(self: ComptimeEvaluator, record: ComptimeWorkspaceRecord, capability: ComptimeCapabilityRecord, node: i32) -> ComptimeWorkspaceCompilePlan:
    let options = record.options
    let migrate_options = record.migrate_options
    let migrate_source_option = self.workspace_str_option(migrate_options, "source_path")
    if migrate_source_option.len() > 0:
        if self.workspace_bool_option(migrate_options, "check_mode", false) or self.workspace_bool_option(migrate_options, "diff_mode", false) or self.workspace_bool_option(migrate_options, "stats_mode", false):
            let _ = self.fail(node, "Workspace.compile migrate check/diff/stats modes are not implemented yet")
            return comptime_workspace_compile_plan_invalid()
        if self.workspace_bool_option(migrate_options, "ir_roundtrip", false):
            let _ = self.fail(node, "Workspace.compile migrate ir_roundtrip mode is not implemented yet")
            return comptime_workspace_compile_plan_invalid()
        let migrate_source = self.workspace_path(capability.project_root, migrate_source_option)
        var migrate_output = self.workspace_str_option(migrate_options, "output_path")
        let migrate_is_dir = if with_fs_is_dir(migrate_source) != 0 or (migrate_source.len() > 2 and migrate_source.slice(migrate_source.len() - 2, migrate_source.len()) != ".c" and migrate_source.slice(migrate_source.len() - 2, migrate_source.len()) != ".h"): 1 else: 0
        if migrate_output.len() == 0:
            if migrate_is_dir != 0:
                migrate_output = migrate_source_option ++ "_migrated"
            else if migrate_source_option.len() > 2 and migrate_source_option.slice(migrate_source_option.len() - 2, migrate_source_option.len()) == ".c":
                migrate_output = migrate_source_option.slice(0, migrate_source_option.len() - 2) ++ ".w"
            else:
                migrate_output = migrate_source_option ++ ".w"
        let absolute_migrate_output = self.workspace_path(capability.project_root, migrate_output)
        return ComptimeWorkspaceCompilePlan {
            valid: 1,
            name: record.name,
            is_migrate: 1,
            final_output: migrate_output,
            absolute_output: absolute_migrate_output,
            output_kind: 0,
            has_strings: 0,
            source_paths: Vec.new(),
            source_texts: Vec.new(),
            absolute_source: "",
            include_paths: Vec.new(),
            defines: Vec.new(),
            link_libs: Vec.new(),
            opt_level: 0,
            no_std: false,
            alloc_mode: false,
            runtime_available: true,
            debug_info: false,
            compiler_hooks_enabled: false,
            prelude_mode: 0,
            migrate_is_dir,
            migrate_source,
            migrate_include_paths: self.workspace_path_vec_field(capability.project_root, migrate_options, "include_paths"),
            migrate_forced_includes: self.workspace_path_vec_field(capability.project_root, migrate_options, "forced_includes"),
            migrate_defines: self.workspace_str_vec_field(migrate_options, "defines"),
            migrate_exclude_basenames: self.workspace_exclude_basenames_field(migrate_options),
            migrate_no_c_export: self.workspace_bool_option(migrate_options, "no_c_export", true),
            migrate_c_export_functions: self.workspace_bool_option(migrate_options, "c_export_functions", false),
            migrate_convert_goto_to_structured: self.workspace_bool_option(migrate_options, "convert_goto_to_structured", false),
            migrate_block_style: self.workspace_i32_option(migrate_options, "block_style", 0),
            migrate_width_slice: self.workspace_i32_option(migrate_options, "width_slice", 8),
            migrate_shared_defs: self.workspace_str_option(migrate_options, "shared_defs"),
            migrate_one: self.workspace_str_option(migrate_options, "migrate_one"),
            migrate_shared_fragment: self.workspace_str_option(migrate_options, "shared_fragment"),
        }

    let option_source = self.workspace_str_option(options, "source_path")
    var source_path = option_source
    if source_path.len() == 0 and record.files.len() > 0:
        source_path = record.files.get(0)
    let output_path = self.workspace_str_option(options, "output_path")
    let output_kind = self.workspace_i32_option(options, "output_kind", 0)
    let target_kind = self.workspace_i32_option(options, "target", 0)
    if target_kind != 0:
        let _ = self.fail(node, "Workspace.compile currently supports only the native target")
        return comptime_workspace_compile_plan_invalid()
    if source_path.len() == 0 and record.string_names.len() == 0:
        let _ = self.fail(node, "Workspace.compile requires at least one source file or source string")
        return comptime_workspace_compile_plan_invalid()
    var final_output = output_path
    if final_output.len() == 0:
        final_output = "out/bin/" ++ record.name
        if output_kind == 1:
            final_output = "out/obj/" ++ record.name ++ ".o"
        else if output_kind == 2:
            final_output = "out/gen/" ++ record.name ++ ".c"
        else if output_kind == 4:
            final_output = "out/lib/lib" ++ record.name ++ ".a"
    let absolute_output = self.workspace_path(capability.project_root, final_output)
    let include_paths = self.workspace_str_vec_field(options, "include_paths")
    let defines = self.workspace_str_vec_field(options, "defines")
    let link_libs = self.workspace_str_vec_field(options, "link_libs")
    let source_paths: Vec[str] = Vec.new()
    let source_texts: Vec[str] = Vec.new()
    var absolute_source = ""
    var has_strings = 0
    if record.string_names.len() > 0:
        if output_kind != 0 and output_kind != 5:
            let _ = self.fail(node, "Workspace.compile source strings currently support binary or check output only")
            return comptime_workspace_compile_plan_invalid()
        for si in 0..record.string_names.len() as i32:
            source_paths.push(self.workspace_path(capability.project_root, record.string_names.get(si as i64)))
            source_texts.push(record.string_sources.get(si as i64))
        has_strings = 1
    else:
        if not comptime_workspace_output_kind_supported(output_kind):
            let _ = self.fail(node, "Workspace.compile output kind is not implemented yet")
            return comptime_workspace_compile_plan_invalid()
        absolute_source = self.workspace_path(capability.project_root, source_path)
    ComptimeWorkspaceCompilePlan {
        valid: 1,
        name: record.name,
        is_migrate: 0,
        final_output,
        absolute_output,
        output_kind,
        has_strings,
        source_paths,
        source_texts,
        absolute_source,
        include_paths,
        defines,
        link_libs,
        opt_level: self.workspace_i32_option(options, "opt_level", 1),
        no_std: self.workspace_bool_option(options, "no_std", false),
        alloc_mode: self.workspace_bool_option(options, "alloc_mode", false),
        runtime_available: self.workspace_bool_option(options, "runtime_available", true),
        debug_info: self.workspace_bool_option(options, "debug_info", true),
        compiler_hooks_enabled: self.workspace_bool_option(options, "compiler_hooks_enabled", true),
        prelude_mode: self.workspace_i32_option(options, "prelude_mode", 0),
        migrate_is_dir: 0,
        migrate_source: "",
        migrate_include_paths: Vec.new(),
        migrate_forced_includes: Vec.new(),
        migrate_defines: Vec.new(),
        migrate_exclude_basenames: "",
        migrate_no_c_export: false,
        migrate_c_export_functions: false,
        migrate_convert_goto_to_structured: false,
        migrate_block_style: 0,
        migrate_width_slice: 0,
        migrate_shared_defs: "",
        migrate_one: "",
        migrate_shared_fragment: "",
    }

fn comptime_execute_workspace_compile_plan(plan: ComptimeWorkspaceCompilePlan) -> ComptimeWorkspaceNativeCompileResult:
    if plan.valid == 0:
        return comptime_workspace_native_compile_invalid()
    if plan.is_migrate != 0:
        let rc = comptime_execute_workspace_migrate_plan(plan)
        return ComptimeWorkspaceNativeCompileResult {
            rc: rc,
            artifact_path: if rc == 0: plan.final_output else: "",
            comp: Compilation.init(),
            is_migrate: 1,
        }
    var comp = Compilation.init()
    comp.configure(plan.opt_level, plan.no_std, plan.alloc_mode, plan.runtime_available)
    comp.set_debug_info(plan.debug_info)
    comp.set_compiler_hooks_enabled(plan.compiler_hooks_enabled)
    comp.set_prelude_mode(plan.prelude_mode)

    var artifact_path = ""
    var success = false
    if plan.has_strings != 0:
        if plan.output_kind == 5:
            if comp.check_source_texts(plan.source_paths, plan.source_texts):
                success = true
        else:
            artifact_path = comp.build_entry_binary_from_sources_to_path(plan.source_paths, plan.source_texts, plan.absolute_output)
            success = artifact_path.len() > 0
    else:
        if plan.output_kind == 0:
            artifact_path = comp.build_binary_to_path_with_build_settings(plan.absolute_source, plan.absolute_output, plan.include_paths, plan.defines, plan.link_libs)
            success = artifact_path.len() > 0
        else if plan.output_kind == 1:
            artifact_path = comp.emit_object_to_path_with_build_settings(plan.absolute_source, plan.absolute_output, plan.include_paths, plan.defines, plan.link_libs)
            success = artifact_path.len() > 0
        else if plan.output_kind == 2:
            artifact_path = comp.emit_c(plan.absolute_source, plan.absolute_output)
            success = artifact_path.len() > 0
        else if plan.output_kind == 4:
            artifact_path = comp.emit_archive_to_path_with_build_settings(plan.absolute_source, plan.absolute_output, plan.include_paths, plan.defines, plan.link_libs)
            success = artifact_path.len() > 0
        else if plan.output_kind == 5:
            if comp.check_file_with_build_settings(plan.absolute_source, plan.include_paths, plan.defines, plan.link_libs):
                success = true
        else:
            return comptime_workspace_native_compile_invalid()
    ComptimeWorkspaceNativeCompileResult {
        rc: if success: 0 else: 1,
        artifact_path: artifact_path,
        comp: comp,
        is_migrate: 0,
    }

fn comptime_workspace_thread_entry(arg: *mut u8) -> i32:
    let job = arg as *mut ComptimeWorkspaceThreadJob
    let native = comptime_execute_workspace_compile_plan((unsafe *job).plan)
    (unsafe *job).result = native
    0

fn ComptimeEvaluator.compile_workspace_record(self: ComptimeEvaluator, record: ComptimeWorkspaceRecord, capability: ComptimeCapabilityRecord, node: i32, want_messages: i32) -> ComptimeWorkspaceCompileResult:
    let plan = self.workspace_compile_plan(record, capability, node)
    if plan.valid == 0:
        return comptime_workspace_compile_invalid()
    let native = comptime_execute_workspace_compile_plan(plan)
    let artifact_kind = if plan.is_migrate != 0: 7 else: self.workspace_artifact_kind_for_output(plan.output_kind)
    let result_artifact_path = if plan.output_kind == 5 and plan.is_migrate == 0: "" else: plan.final_output
    let result = self.workspace_build_result_value(plan.name, native.rc, artifact_kind, result_artifact_path, node)
    if result.kind == ComptimeValueKind.CV_INVALID:
        return comptime_workspace_compile_invalid()
    let messages =
        if want_messages != 0 and native.rc == 0 and native.is_migrate == 0:
            self.workspace_success_messages(native.comp, native.comp.zcu.last_sema.ast, node)
        else:
            Vec.new()
    if self.had_error != 0:
        return comptime_workspace_compile_invalid()
    comptime_workspace_compile_result(result, messages)

fn ComptimeEvaluator.start_intercept_workspace_compile(self: ComptimeEvaluator, record: ComptimeWorkspaceRecord, capability: ComptimeCapabilityRecord, node: i32) -> ComptimeWorkspaceRecord:
    var out = record
    out.intercept_started = 1
    if self.workspace_str_option(out.migrate_options, "source_path").len() > 0:
        let _ = self.fail(node, "Workspace.intercept does not support MigrateOptions in Phase D")
        return out
    let options = out.options
    let option_source = self.workspace_str_option(options, "source_path")
    var source_path = option_source
    if source_path.len() == 0 and out.files.len() > 0:
        source_path = out.files.get(0)
    let output_path = self.workspace_str_option(options, "output_path")
    let output_kind = self.workspace_i32_option(options, "output_kind", 0)
    let target_kind = self.workspace_i32_option(options, "target", 0)
    if target_kind != 0:
        let _ = self.fail(node, "Workspace.intercept currently supports only the native target")
        return out
    if output_kind != 0:
        let _ = self.fail(node, "Workspace.intercept currently supports binary output only")
        return out
    if source_path.len() == 0 and out.string_names.len() == 0:
        let _ = self.fail(node, "Workspace.intercept requires at least one source file or source string")
        return out

    var final_output = output_path
    if final_output.len() == 0:
        final_output = "out/bin/" ++ out.name
    let absolute_output = self.workspace_path(capability.project_root, final_output)
    let obj_path = absolute_output ++ ".o"
    let output_dir = link_stage_dirname(absolute_output)
    if output_dir.len() > 0:
        let _ = with_fs_mkdir_p(output_dir)
    let include_paths = self.workspace_str_vec_field(options, "include_paths")
    let defines = self.workspace_str_vec_field(options, "defines")
    let link_libs = self.workspace_str_vec_field(options, "link_libs")

    var comp = Compilation.init()
    comp.configure(self.workspace_i32_option(options, "opt_level", 1), self.workspace_bool_option(options, "no_std", false), self.workspace_bool_option(options, "alloc_mode", false), self.workspace_bool_option(options, "runtime_available", true))
    comp.set_debug_info(self.workspace_bool_option(options, "debug_info", true))
    comp.set_compiler_hooks_enabled(self.workspace_bool_option(options, "compiler_hooks_enabled", true))
    comp.set_prelude_mode(self.workspace_i32_option(options, "prelude_mode", 0))

    var pool = AstPool.new()
    var source_name = source_path
    if out.string_names.len() > 0:
        let source_paths: Vec[str] = Vec.new()
        let source_texts: Vec[str] = Vec.new()
        for si in 0..out.string_names.len() as i32:
            source_paths.push(self.workspace_path(capability.project_root, out.string_names.get(si as i64)))
            source_texts.push(out.string_sources.get(si as i64))
        source_name = source_paths.get(0)
        pool = comp.compile_entry_source_texts(source_paths, source_texts)
    else:
        let absolute_source = self.workspace_path(capability.project_root, source_path)
        var cfg = project_config_load_for_source(absolute_source)
        for ii in 0..include_paths.len() as i32:
            cfg.c_import_include_paths.push(include_paths.get(ii as i64))
        for di in 0..defines.len() as i32:
            cfg.c_import_defines.push(defines.get(di as i64))
        for li in 0..link_libs.len() as i32:
            cfg.dep_link_libs.push(link_libs.get(li as i64))
        pool = comp.compile_entry_file_with_config(absolute_source, cfg)

    let link_plan = comp.prepare_binary_link_from_pool(pool, source_name, obj_path, absolute_output)
    if not link_plan.ok:
        let _ = self.fail(node, "Workspace.intercept failed before PRE_LINK")
        return out
    let messages = self.workspace_success_messages(comp, comp.zcu.last_sema.ast, node)
    for mi in 0..messages.len() as i32:
        out.messages.push(messages.get(mi as i64))
    let prelink_phase = self.compiler_message_phase_value(7, node)
    if prelink_phase.kind == ComptimeValueKind.CV_INVALID:
        return out
    out.messages.push(prelink_phase)
    let prelink = self.compiler_message_prelink_value(link_plan.command, node)
    if prelink.kind == ComptimeValueKind.CV_INVALID:
        return out
    out.messages.push(prelink)
    out.pending_link_active = 1
    out.pending_link_obj_path = link_plan.obj_path
    out.pending_link_bin_path = link_plan.bin_path
    out.pending_link_output_path = final_output
    out.pending_link_output_kind = output_kind
    out.pending_link_debug_info = if self.workspace_bool_option(options, "debug_info", true): 1 else: 0
    out.pending_link_command = link_plan.command
    out

fn ComptimeEvaluator.finish_intercept_workspace_link(self: ComptimeEvaluator, record: ComptimeWorkspaceRecord, node: i32) -> ComptimeWorkspaceRecord:
    var out = record
    if out.pending_link_active == 0:
        return out
    let plan = CompilationBinaryLinkPlan {
        ok: true,
        obj_path: out.pending_link_obj_path,
        bin_path: out.pending_link_bin_path,
        command: out.pending_link_command,
    }
    let link_result = compilation_execute_binary_link_plan(out.pending_link_debug_info != 0, plan)
    out.pending_link_active = 0
    let linked_phase = self.compiler_message_phase_value(8, node)
    if linked_phase.kind != ComptimeValueKind.CV_INVALID:
        out.messages.push(linked_phase)
    let linked = self.compiler_message_linked_value(link_result.command, link_result.rc, node)
    if linked.kind != ComptimeValueKind.CV_INVALID:
        out.messages.push(linked)
    let result = self.workspace_build_result_value(out.name, link_result.rc, self.workspace_artifact_kind_for_output(out.pending_link_output_kind), out.pending_link_output_path, node)
    if result.kind == ComptimeValueKind.CV_INVALID:
        return out
    out = self.enqueue_artifact_messages(out, result, node)
    let phase_message = self.compiler_message_phase_value(9, node)
    if phase_message.kind != ComptimeValueKind.CV_INVALID:
        out.messages.push(phase_message)
    let complete = self.compiler_message_complete_value(result, node)
    if complete.kind != ComptimeValueKind.CV_INVALID:
        out.messages.push(complete)
    out.intercept_terminal = 1
    out

fn ComptimeEvaluator.mint_workspace_capability(self: ComptimeEvaluator, parent: ComptimeCapabilityRecord, workspace_id: i32, node: i32) -> ComptimeControl:
    let workspace_type = self.capability_type_id(CapabilityKind.CK_BUILD_WORKSPACE, node)
    if workspace_type == 0:
        return comptime_control_error()
    var record = parent
    record.kind = CapabilityKind.CK_BUILD_WORKSPACE
    record.workspace_id = workspace_id
    comptime_control_value(self.mint_capability(workspace_type, record))

fn ComptimeEvaluator.create_workspace_for_capability(self: ComptimeEvaluator, parent: ComptimeCapabilityRecord, name: str, node: i32) -> ComptimeControl:
    let workspace_id = self.workspace_records.len() as i32
    self.workspace_records.push(self.new_workspace_record(name, node))
    self.current_workspace_id = workspace_id
    self.mint_workspace_capability(parent, workspace_id, node)

fn ComptimeEvaluator.current_workspace_for_capability(self: ComptimeEvaluator, parent: ComptimeCapabilityRecord, owner_name: str, node: i32) -> ComptimeControl:
    if self.current_workspace_id < 0:
        return self.fail(node, owner_name ++ ".current_workspace called before create_workspace")
    self.mint_workspace_capability(parent, self.current_workspace_id, node)

fn ComptimeEvaluator.eval_buildctx_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, arg_count: i32, node: i32) -> ComptimeControl:
    if method == "create_workspace":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_CTX, method, node)
        if handle < 0:
            return comptime_control_error()
        let args_signal = self.capability_args(self.ast.get_data1(node), arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let name = self.capability_arg_str(args_signal.value, 0, method, node)
        return self.create_workspace_for_capability(self.capability_records.get(handle as i64), name, node)
    if method == "current_workspace":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_CTX, method, node)
        if handle < 0:
            return comptime_control_error()
        return self.current_workspace_for_capability(self.capability_records.get(handle as i64), "BuildCtx", node)
    if method == "new_build":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_CTX, method, node)
        if handle < 0:
            return comptime_control_error()
        let build_value = self.eval_new_build_value(self.capability_records.get(handle as i64), node)
        if build_value.kind == ComptimeValueKind.CV_INVALID:
            return comptime_control_error()
        return comptime_control_value(build_value)
    if method == "project_info":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_CTX, method, node)
        if handle < 0:
            return comptime_control_error()
        let record = self.capability_records.get(handle as i64)
        let project_info_type = self.capability_type_id(CapabilityKind.CK_BUILD_PROJECT_INFO, node)
        if project_info_type == 0:
            return comptime_control_error()
        let child = comptime_capability_record(CapabilityKind.CK_BUILD_PROJECT_INFO, record.package_name, record.package_version, record.project_root)
        return comptime_control_value(self.mint_capability(project_info_type, child))
    if method == "diagnostics" or method == "source_emitter" or method == "fs" or method == "process_runner":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_CTX, method, node)
        if handle < 0:
            return comptime_control_error()
        let child_kind =
            if method == "diagnostics":
                CapabilityKind.CK_BUILD_DIAGNOSTICS
            else if method == "source_emitter":
                CapabilityKind.CK_BUILD_SOURCE_EMITTER
            else if method == "fs":
                CapabilityKind.CK_BUILD_TOOL_FS
            else:
                CapabilityKind.CK_BUILD_PROCESS_RUNNER
        let child_type = self.capability_type_id(child_kind, node)
        if child_type == 0:
            return comptime_control_error()
        let record = self.capability_records.get(handle as i64)
        let child = comptime_capability_record(child_kind, record.package_name, record.package_version, record.project_root)
        return comptime_control_value(self.mint_capability(child_type, child))
    self.fail(node, "BuildCtx capability method '" ++ method ++ "' is not implemented yet")

fn ComptimeEvaluator.eval_project_info_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, arg_count: i32, node: i32) -> ComptimeControl:
    if not self.capability_expect_arg_count(arg_count, 0, method, node):
        return comptime_control_error()
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_PROJECT_INFO, method, node)
    if handle < 0:
        return comptime_control_error()
    let record = self.capability_records.get(handle as i64)
    if method == "package_name":
        return comptime_control_value(comptime_value_str(record.package_name))
    if method == "package_version":
        return comptime_control_value(comptime_value_str(record.package_version))
    if method == "project_root":
        return comptime_control_value(comptime_value_str(record.project_root))
    self.fail(node, "ProjectInfo capability method '" ++ method ++ "' is not implemented yet")

fn ComptimeEvaluator.eval_diagnostics_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    if method != "warn" and method != "error":
        return self.fail(node, "Diagnostics capability method '" ++ method ++ "' is not implemented yet")
    if not self.capability_expect_arg_count(arg_count, 1, method, node):
        return comptime_control_error()
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_DIAGNOSTICS, method, node)
    if handle < 0:
        return comptime_control_error()
    let args_signal = self.capability_args(extra_start, arg_count)
    if args_signal.kind != ComptimeControlKind.CTL_VALUE:
        return args_signal
    let message = self.capability_arg_str(args_signal.value, 0, method, node)
    if self.had_error != 0:
        return comptime_control_error()
    if method == "warn":
        with_eprint("warning: " ++ message ++ "\n")
        return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
    with_eprint("error: " ++ message ++ "\n")
    self.fail(node, message)

fn ComptimeEvaluator.eval_source_emitter_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    if method != "generated_source":
        return self.fail(node, "SourceEmitter capability method '" ++ method ++ "' is not implemented yet")
    if not self.capability_expect_arg_count(arg_count, 2, method, node):
        return comptime_control_error()
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_SOURCE_EMITTER, method, node)
    if handle < 0:
        return comptime_control_error()
    let args_signal = self.capability_args(extra_start, arg_count)
    if args_signal.kind != ComptimeControlKind.CTL_VALUE:
        return args_signal
    let path = self.capability_arg_str(args_signal.value, 0, method, node)
    let contents = self.capability_arg_str(args_signal.value, 1, method, node)
    if self.had_error != 0:
        return comptime_control_error()
    let source_type = self.named_type_id("GeneratedSource", node)
    if source_type == 0:
        return comptime_control_error()
    let start = self.extra_values.len() as i32
    self.extra_values.push(comptime_value_str(path))
    self.extra_values.push(comptime_value_str(contents))
    comptime_control_value(comptime_value_struct(source_type, start, 2))

fn ComptimeEvaluator.eval_toolfs_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_TOOL_FS, method, node)
    if handle < 0:
        return comptime_control_error()
    let record = self.capability_records.get(handle as i64)

    if method == "normalize":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let path = self.capability_arg_str(args_signal.value, 0, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        return comptime_control_value(comptime_value_str(comptime_tool_path_normalize(path)))
    if method == "join":
        if not self.capability_expect_arg_count(arg_count, 2, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let base = self.capability_arg_str(args_signal.value, 0, method, node)
        let child = self.capability_arg_str(args_signal.value, 1, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        if base.len() == 0:
            return comptime_control_value(comptime_value_str(child))
        if child.len() == 0:
            return comptime_control_value(comptime_value_str(base))
        let joined = if base.ends_with("/"): base ++ child else: base ++ "/" ++ child
        return comptime_control_value(comptime_value_str(joined))
    if method == "glob":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let pattern = self.capability_arg_str(args_signal.value, 0, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        var last_clean_slash = -1
        var has_glob = false
        for gi in 0..pattern.len() as i32:
            let gc = pattern.byte_at(gi as i64)
            if gc == 42:
                has_glob = true
                break
            if gc == 47:
                last_clean_slash = gi
        if not has_glob:
            return self.fail(node, "glob pattern contains no wildcards: " ++ pattern)
        let glob_base = if last_clean_slash < 0: "." else: pattern.slice(0, last_clean_slash as i64)
        let glob_suffix = if last_clean_slash < 0: pattern else: pattern.slice((last_clean_slash + 1) as i64, pattern.len())
        let resolved_base = self.capability_resolve_project_path(record, glob_base, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let raw_files = comptime_tool_split_nonempty_lines(with_fs_list_files(resolved_base))
        let pat_segs = comptime_glob_split_by_slash(glob_suffix)
        let results: Vec[str] = Vec.new()
        for gi in 0..raw_files.len() as i32:
            let abs_file = raw_files.get(gi as i64)
            let rel_file = self.capability_project_relative_path(record, abs_file)
            let base_prefix = if glob_base == ".": "" else: glob_base ++ "/"
            let rel_to_base = if base_prefix.len() > 0 and rel_file.starts_with(base_prefix): rel_file.slice(base_prefix.len(), rel_file.len()) else: rel_file
            let file_segs = comptime_glob_split_by_slash(rel_to_base)
            if comptime_glob_segments_match(pat_segs, 0, file_segs, 0):
                results.push(rel_file)
        if results.len() == 0:
            return self.fail(node, "glob pattern matched no files: " ++ pattern)
        let sorted = comptime_glob_sort(results)
        let vec_type = self.node_type_or(node, 0)
        if vec_type == 0:
            return self.fail(node, "ToolFs.glob result type is unknown")
        let gstart = self.extra_values.len() as i32
        for gi in 0..sorted.len() as i32:
            self.extra_values.push(comptime_value_str(sorted.get(gi as i64)))
        return comptime_control_value(comptime_value_vec(vec_type, gstart, sorted.len() as i32))
    if method == "exists" or method == "is_dir" or method == "read_text" or method == "read_binary" or method == "list_files" or method == "mkdir_all" or method == "remove_file" or method == "remove_tree":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let path = self.capability_arg_str(args_signal.value, 0, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let resolved = self.capability_resolve_project_path(record, path, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        if method == "exists":
            return comptime_control_value(comptime_value_bool(if with_fs_file_exists(resolved) != 0: 1 else: 0))
        if method == "is_dir":
            return comptime_control_value(comptime_value_bool(if with_fs_is_dir(resolved) != 0: 1 else: 0))
        if method == "read_text":
            return comptime_control_value(comptime_value_str(with_fs_read_file(resolved)))
        if method == "read_binary":
            let vec_type = self.node_type_or(node, 0)
            if vec_type == 0:
                return self.fail(node, "ToolFs.read_binary result type is unknown")
            return comptime_control_value(comptime_value_bytes(vec_type, with_fs_read_file(resolved)))
        if method == "list_files":
            let raw_files = comptime_tool_split_nonempty_lines(with_fs_list_files(resolved))
            let vec_type = self.node_type_or(node, 0)
            if vec_type == 0:
                return self.fail(node, "ToolFs.list_files result type is unknown")
            let start = self.extra_values.len() as i32
            for i in 0..raw_files.len() as i32:
                self.extra_values.push(comptime_value_str(self.capability_project_relative_path(record, raw_files.get(i as i64))))
            return comptime_control_value(comptime_value_vec(vec_type, start, raw_files.len() as i32))
        if method == "mkdir_all":
            if not self.capability_require_mkdir_allowed(record, path, method, node):
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_mkdir_p(resolved) as i64))
        if method == "remove_file":
            if not self.capability_require_write_file_allowed(record, path, method, node):
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_remove_file(resolved) as i64))
        if method == "remove_tree":
            if not self.capability_require_write_file_allowed(record, path, method, node):
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_remove_tree(resolved) as i64))
    if method == "host_exists":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let path = self.capability_arg_str(args_signal.value, 0, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        return comptime_control_value(comptime_value_bool(if with_fs_file_exists(path) != 0: 1 else: 0))
    if method == "host_list_files":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let path = self.capability_arg_str(args_signal.value, 0, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let raw_files = comptime_tool_split_nonempty_lines(with_fs_list_files(path))
        let vec_type = self.node_type_or(node, 0)
        if vec_type == 0:
            return self.fail(node, "ToolFs.host_list_files result type is unknown")
        let start = self.extra_values.len() as i32
        for i in 0..raw_files.len() as i32:
            self.extra_values.push(comptime_value_str(raw_files.get(i as i64)))
        return comptime_control_value(comptime_value_vec(vec_type, start, raw_files.len() as i32))
    if method == "write_text" or method == "copy_file" or method == "chmod" or method == "rename" or method == "copy_tree" or method == "symlink":
        let expected =
            if method == "chmod":
                2
            else:
                2
        if not self.capability_expect_arg_count(arg_count, expected, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        if method == "write_text":
            let path = self.capability_arg_str(args_signal.value, 0, method, node)
            let contents = self.capability_arg_str(args_signal.value, 1, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            if not self.capability_require_write_file_allowed(record, path, method, node):
                return comptime_control_error()
            let resolved = self.capability_resolve_project_path(record, path, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_write_file(resolved, contents) as i64))
        if method == "copy_file":
            let src = self.capability_arg_str(args_signal.value, 0, method, node)
            let dst = self.capability_arg_str(args_signal.value, 1, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            let resolved_src = self.capability_resolve_project_path(record, src, method, node)
            if not self.capability_require_write_file_allowed(record, dst, method, node):
                return comptime_control_error()
            let dst_dir = comptime_tool_path_dirname(dst)
            if dst_dir != ".":
                if not self.capability_require_mkdir_allowed(record, dst_dir, method, node):
                    return comptime_control_error()
                let mkdir_rc = with_fs_mkdir_p(self.capability_resolve_project_path(record, dst_dir, method, node))
                if mkdir_rc != 0:
                    return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), mkdir_rc as i64))
            let resolved_dst = self.capability_resolve_project_path(record, dst, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_write_file(resolved_dst, with_fs_read_file(resolved_src)) as i64))
        if method == "chmod":
            let path = self.capability_arg_str(args_signal.value, 0, method, node)
            let mode = self.capability_arg_i32(args_signal.value, 1, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            if not self.capability_require_write_file_allowed(record, path, method, node):
                return comptime_control_error()
            let resolved = self.capability_resolve_project_path(record, path, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_chmod(resolved, mode) as i64))
        if method == "rename":
            let old_path = self.capability_arg_str(args_signal.value, 0, method, node)
            let new_path = self.capability_arg_str(args_signal.value, 1, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            if not self.capability_require_write_file_allowed(record, old_path, method, node) or not self.capability_require_write_file_allowed(record, new_path, method, node):
                return comptime_control_error()
            let resolved_old = self.capability_resolve_project_path(record, old_path, method, node)
            let resolved_new = self.capability_resolve_project_path(record, new_path, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_rename_file(resolved_old, resolved_new) as i64))
        if method == "copy_tree":
            let src = self.capability_arg_str(args_signal.value, 0, method, node)
            let dst = self.capability_arg_str(args_signal.value, 1, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            let resolved_src = self.capability_resolve_project_path(record, src, method, node)
            if not self.capability_require_write_file_allowed(record, dst, method, node):
                return comptime_control_error()
            let resolved_dst = self.capability_resolve_project_path(record, dst, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_copy_tree(resolved_src, resolved_dst) as i64))
        if method == "symlink":
            let target = self.capability_arg_str(args_signal.value, 0, method, node)
            let link_path = self.capability_arg_str(args_signal.value, 1, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            let resolved_target = self.capability_resolve_project_path(record, target, method, node)
            if not self.capability_require_write_file_allowed(record, link_path, method, node):
                return comptime_control_error()
            let resolved_link = self.capability_resolve_project_path(record, link_path, method, node)
            if self.had_error != 0:
                return comptime_control_error()
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_symlink(resolved_target, resolved_link) as i64))
    if method == "write_binary":
        if not self.capability_expect_arg_count(arg_count, 2, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let path = self.capability_arg_str(args_signal.value, 0, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        if not self.capability_require_write_file_allowed(record, path, method, node):
            return comptime_control_error()
        let resolved = self.capability_resolve_project_path(record, path, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let bytes_value = self.extra_values.get((args_signal.value.extra_start + 1) as i64)
        let data = if bytes_value.kind == ComptimeValueKind.CV_BYTES:
            bytes_value.text
        else:
            if bytes_value.kind == ComptimeValueKind.CV_VEC:
                var assembled = ""
                for i in 0..bytes_value.extra_count:
                    let elem = self.extra_values.get((bytes_value.extra_start + i) as i64)
                    assembled = with_str_concat(assembled, with_str_from_byte(comptime_value_intlike(elem) as i32))
                assembled
            else:
                let _ = self.fail(node, "write_binary second argument must be Vec[u8]")
                return comptime_control_error()
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_fs_write_file(resolved, data) as i64))
    self.fail(node, "ToolFs capability method '" ++ method ++ "' is not implemented yet")

fn ComptimeEvaluator.eval_process_runner_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_PROCESS_RUNNER, method, node)
    if handle < 0:
        return comptime_control_error()
    let _record = self.capability_records.get(handle as i64)
    if method == "run_spec":
        if not self.capability_expect_arg_count(arg_count, 3, method, node):
            return comptime_control_error()
        let spec_args_signal = self.capability_args(extra_start, arg_count)
        if spec_args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return spec_args_signal
        let spec_val = self.extra_values.get(spec_args_signal.value.extra_start as i64)
        if spec_val.kind != ComptimeValueKind.CV_STRUCT:
            return self.fail(node, "run_spec first argument must be ProcessSpec struct")
        let executable = self.struct_field_value_by_name(spec_val, "executable")
        let spec_args = self.struct_field_value_by_name(spec_val, "args")
        let spec_cwd = self.struct_field_value_by_name(spec_val, "cwd")
        let spec_env = self.struct_field_value_by_name(spec_val, "env")
        let spec_timeout = self.struct_field_value_by_name(spec_val, "timeout_ms")
        let spec_stdin = self.struct_field_value_by_name(spec_val, "stdin_path")
        var argv_parts: Vec[str] = Vec.new()
        argv_parts.push(executable.text)
        if spec_args.kind == ComptimeValueKind.CV_VEC or spec_args.kind == ComptimeValueKind.CV_ARRAY:
            for ai in 0..spec_args.extra_count:
                let elem = self.extra_values.get((spec_args.extra_start + ai) as i64)
                argv_parts.push(elem.text)
        let argv = self.vec_str_to_argv_from_parts(argv_parts, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let stdout_path = self.capability_arg_str(spec_args_signal.value, 1, method, node)
        let stderr_path = self.capability_arg_str(spec_args_signal.value, 2, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let timeout_ms = spec_timeout.data0 as i32
        let has_cwd = spec_cwd.text.len() > 0
        let env_vars = if spec_env.kind == ComptimeValueKind.CV_STRUCT: self.struct_field_value_by_name(spec_env, "vars") else: comptime_value_invalid()
        let has_env = env_vars.kind == ComptimeValueKind.CV_VEC and env_vars.extra_count > 0
        let has_stdin = spec_stdin.text.len() > 0
        if has_env:
            let saved_env = self.process_env_apply(spec_env, node)
            if self.had_error != 0:
                return comptime_control_error()
            let rc = if has_cwd: with_exec_argv_capture_cwd(argv, stdout_path, stderr_path, timeout_ms, spec_cwd.text) else: with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
            self.process_env_restore(saved_env)
            return self.tool_process_result(rc, stdout_path, stderr_path, node)
        let saved_env = self.process_driver_env_clear(node)
        if self.had_error != 0:
            return comptime_control_error()
        let rc = if has_cwd: with_exec_argv_capture_cwd(argv, stdout_path, stderr_path, timeout_ms, spec_cwd.text) else if has_stdin: with_exec_argv_capture_input(argv, stdout_path, stderr_path, timeout_ms, spec_stdin.text) else: with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
        self.process_env_restore(saved_env)
        return self.tool_process_result(rc, stdout_path, stderr_path, node)
    let expected =
        if method == "run":
            1
        else if method == "spawn_capture":
            3
        else if method == "wait":
            2
        else if method == "run_capture":
            4
        else if method == "run_capture_with_env":
            5
        else if method == "run_capture_cwd" or method == "run_capture_input":
            5
        else if method == "run_capture_cwd_with_env":
            6
        else:
            -1
    if expected < 0:
        return self.fail(node, "ProcessRunner capability method '" ++ method ++ "' is not implemented yet")
    if not self.capability_expect_arg_count(arg_count, expected, method, node):
        return comptime_control_error()
    let args_signal = self.capability_args(extra_start, arg_count)
    if args_signal.kind != ComptimeControlKind.CTL_VALUE:
        return args_signal

    if method == "wait":
        let pid = self.capability_arg_i32(args_signal.value, 0, method, node)
        let timeout_ms = self.capability_arg_i32(args_signal.value, 1, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_exec_wait(pid, timeout_ms) as i64))

    let argv_value = self.extra_values.get(args_signal.value.extra_start as i64)
    let argv = self.vec_str_to_argv(argv_value, method, node)
    if self.had_error != 0:
        return comptime_control_error()

    if method == "run":
        let saved_env = self.process_driver_env_clear(node)
        if self.had_error != 0:
            return comptime_control_error()
        let rc = with_exec_argv(argv)
        self.process_env_restore(saved_env)
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), rc as i64))

    if method == "spawn_capture":
        let stdout_path = self.capability_arg_str(args_signal.value, 1, method, node)
        let stderr_path = self.capability_arg_str(args_signal.value, 2, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let saved_env = self.process_driver_env_clear(node)
        if self.had_error != 0:
            return comptime_control_error()
        let pid = with_exec_argv_capture_spawn(argv, stdout_path, stderr_path)
        self.process_env_restore(saved_env)
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), pid as i64))

    let stdout_path = self.capability_arg_str(args_signal.value, 1, method, node)
    let stderr_path = self.capability_arg_str(args_signal.value, 2, method, node)
    let timeout_ms = self.capability_arg_i32(args_signal.value, 3, method, node)
    if self.had_error != 0:
        return comptime_control_error()

    if method == "run_capture":
        let saved_env = self.process_driver_env_clear(node)
        if self.had_error != 0:
            return comptime_control_error()
        let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
        self.process_env_restore(saved_env)
        return self.tool_process_result(rc, stdout_path, stderr_path, node)
    if method == "run_capture_cwd":
        let cwd = self.capability_arg_str(args_signal.value, 4, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let saved_env = self.process_driver_env_clear(node)
        if self.had_error != 0:
            return comptime_control_error()
        let rc = with_exec_argv_capture_cwd(argv, stdout_path, stderr_path, timeout_ms, cwd)
        self.process_env_restore(saved_env)
        return self.tool_process_result(rc, stdout_path, stderr_path, node)
    if method == "run_capture_input":
        let stdin_path = self.capability_arg_str(args_signal.value, 4, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        let saved_env = self.process_driver_env_clear(node)
        if self.had_error != 0:
            return comptime_control_error()
        let rc = with_exec_argv_capture_input(argv, stdout_path, stderr_path, timeout_ms, stdin_path)
        self.process_env_restore(saved_env)
        return self.tool_process_result(rc, stdout_path, stderr_path, node)
    if method == "run_capture_with_env":
        let saved_env = self.process_env_apply(self.extra_values.get((args_signal.value.extra_start + 4) as i64), node)
        if self.had_error != 0:
            return comptime_control_error()
        let rc = with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms)
        self.process_env_restore(saved_env)
        return self.tool_process_result(rc, stdout_path, stderr_path, node)
    let cwd = self.capability_arg_str(args_signal.value, 4, method, node)
    if self.had_error != 0:
        return comptime_control_error()
    let saved_env = self.process_env_apply(self.extra_values.get((args_signal.value.extra_start + 5) as i64), node)
    if self.had_error != 0:
        return comptime_control_error()
    let rc = with_exec_argv_capture_cwd(argv, stdout_path, stderr_path, timeout_ms, cwd)
    self.process_env_restore(saved_env)
    self.tool_process_result(rc, stdout_path, stderr_path, node)

fn ComptimeEvaluator.eval_actionctx_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, arg_count: i32, node: i32) -> ComptimeControl:
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_ACTION_CTX, method, node)
    if handle < 0:
        return comptime_control_error()
    let record = self.capability_records.get(handle as i64)
    if method == "create_workspace":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(self.ast.get_data1(node), arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        return self.create_workspace_for_capability(record, self.capability_arg_str(args_signal.value, 0, method, node), node)
    if not self.capability_expect_arg_count(arg_count, 0, method, node):
        return comptime_control_error()
    if method == "current_workspace":
        return self.current_workspace_for_capability(record, "ActionCtx", node)
    if method == "target_name":
        return comptime_control_value(comptime_value_str(record.target_name))
    if method == "inputs":
        return comptime_control_value(self.str_vec_value(record.inputs, node))
    if method == "outputs":
        return comptime_control_value(self.str_vec_value(record.outputs, node))
    if method == "args":
        return comptime_control_value(self.str_vec_value(record.args, node))
    if method == "output":
        if record.outputs.len() == 0:
            return comptime_control_value(comptime_value_str(""))
        return comptime_control_value(comptime_value_str(record.outputs.get(0)))
    if method == "timeout":
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), record.timeout_ms as i64))
    if method == "working_dir":
        return comptime_control_value(comptime_value_str(record.cwd))
    if method == "env":
        return comptime_control_value(self.str_vec_value(record.env, node))
    if method == "network":
        return comptime_control_value(comptime_value_bool(if record.network != 0: 1 else: 0))
    let child_kind =
        if method == "project_info":
            CapabilityKind.CK_BUILD_PROJECT_INFO
        else if method == "diagnostics":
            CapabilityKind.CK_BUILD_DIAGNOSTICS
        else if method == "fs":
            CapabilityKind.CK_BUILD_TOOL_FS
        else if method == "process_runner":
            CapabilityKind.CK_BUILD_PROCESS_RUNNER
        else:
            0
    if child_kind == 0:
        return self.fail(node, "ActionCtx capability method '" ++ method ++ "' is not implemented yet")
    let child_type = self.capability_type_id(child_kind, node)
    if child_type == 0:
        return comptime_control_error()
    var child = comptime_capability_record(child_kind, record.package_name, record.package_version, record.project_root)
    child.target_name = record.target_name
    child.inputs = record.inputs
    child.outputs = record.outputs
    child.args = record.args
    if child_kind == CapabilityKind.CK_BUILD_TOOL_FS:
        child.write_scope = record.write_scope
        child.write_scoped = 1
    comptime_control_value(self.mint_capability(child_type, child))

fn ComptimeEvaluator.eval_workspace_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let workspace_id = self.workspace_record_index(recv_value, method, node)
    if workspace_id < 0:
        return comptime_control_error()
    var record = self.workspace_records.get(workspace_id as i64)
    let capability_handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_WORKSPACE, method, node)
    if capability_handle < 0:
        return comptime_control_error()
    let capability = self.capability_records.get(capability_handle as i64)
    if method == "name":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        return comptime_control_value(comptime_value_str(record.name))
    if method == "add_file":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        record.files.push(self.capability_arg_str(args_signal.value, 0, method, node))
        self.store_workspace_record(workspace_id, record)
        return comptime_control_value(comptime_value_void(0))
    if method == "add_string":
        if not self.capability_expect_arg_count(arg_count, 2, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        record.string_names.push(self.capability_arg_str(args_signal.value, 0, method, node))
        record.string_sources.push(self.capability_arg_str(args_signal.value, 1, method, node))
        if record.intercept_active != 0 and record.intercept_started != 0:
            if record.intercept_phase == 3:
                record.generation = record.generation + 1
                record.intercept_phase = -1
                record.messages = Vec.new()
                record.message_cursor = 0
                record.intercept_started = 0
                record.pending_link_active = 0
                record.intercept_terminal = 0
                self.store_workspace_record(workspace_id, record)
                return comptime_control_value(comptime_value_void(0))
            if record.intercept_phase >= 7:
                return self.fail(node, "Workspace.add_string during PRE_LINK is not supported in Phase D")
            return self.fail(node, "Workspace.add_string during interception is only supported after TYPECHECKED in Phase D")
        self.store_workspace_record(workspace_id, record)
        return comptime_control_value(comptime_value_void(0))
    if method == "options":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        return comptime_control_value(record.options)
    if method == "set_options":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        record.options = self.extra_values.get(args_signal.value.extra_start)
        self.store_workspace_record(workspace_id, record)
        return comptime_control_value(comptime_value_void(0))
    if method == "set_migrate_options":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        record.migrate_options = self.extra_values.get(args_signal.value.extra_start)
        self.store_workspace_record(workspace_id, record)
        return comptime_control_value(comptime_value_void(0))
    if method == "begin_intercept":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        if record.intercept_active != 0:
            return self.fail(node, "Workspace.begin_intercept called while interception is already active")
        record.intercept_active = 1
        record.intercept_terminal = 0
        record.generation = record.generation + 1
        if record.generation <= 0:
            record.generation = 1
        record.intercept_phase = -1
        record.messages = Vec.new()
        record.message_cursor = 0
        self.store_workspace_record(workspace_id, record)
        return comptime_control_value(comptime_value_void(0))
    if method == "wait_for_message":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        if record.intercept_active == 0:
            return self.fail(node, "Workspace.wait_for_message called without active interception")
        if record.message_cursor >= record.messages.len() as i32 and record.intercept_terminal == 0:
            if record.pending_link_active != 0:
                record = self.finish_intercept_workspace_link(record, node)
            else if record.intercept_started == 0:
                record = self.start_intercept_workspace_compile(record, capability, node)
            if self.had_error != 0:
                return comptime_control_error()
            self.store_workspace_record(workspace_id, record)
        if record.message_cursor < record.messages.len() as i32:
            let message = record.messages.get(record.message_cursor as i64)
            let phase = self.compiler_message_phase_id(message)
            if phase >= 0:
                record.intercept_phase = phase
            record.message_cursor = record.message_cursor + 1
            self.store_workspace_record(workspace_id, record)
            let envelope = self.compiler_message_envelope_value(record.name, record.generation, message, node)
            if envelope.kind == ComptimeValueKind.CV_INVALID:
                return comptime_control_error()
            return comptime_control_value(envelope)
        if record.intercept_terminal != 0:
            let message = self.compiler_message_error_value(1, "Workspace message queue is closed", node)
            if message.kind == ComptimeValueKind.CV_INVALID:
                return comptime_control_error()
            let envelope = self.compiler_message_envelope_value(record.name, record.generation, message, node)
            if envelope.kind == ComptimeValueKind.CV_INVALID:
                return comptime_control_error()
            return comptime_control_value(envelope)
        return self.fail(node, "Workspace.wait_for_message requires a pending message; cooperative suspension is not implemented yet")
    if method == "end_intercept":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        if record.intercept_active == 0:
            return self.fail(node, "Workspace.end_intercept called without active interception")
        if record.intercept_terminal != 0 and record.message_cursor < record.messages.len() as i32:
            return self.fail(node, "Workspace.end_intercept called before terminal message was consumed")
        record.intercept_active = 0
        self.store_workspace_record(workspace_id, record)
        return comptime_control_value(comptime_value_void(0))
    if method == "set_link_command":
        if not self.capability_expect_arg_count(arg_count, 1, method, node):
            return comptime_control_error()
        if record.pending_link_active == 0:
            return self.fail(node, "Workspace.set_link_command called without a pending PRE_LINK command")
        let args_signal = self.capability_args(extra_start, arg_count)
        if args_signal.kind != ComptimeControlKind.CTL_VALUE:
            return args_signal
        let replacement_value = self.extra_values.get(args_signal.value.extra_start)
        let replacement = self.link_command_from_value(replacement_value, node)
        if self.had_error != 0:
            return comptime_control_error()
        if replacement.linker != record.pending_link_command.linker:
            return self.fail(node, "Workspace.set_link_command cannot change linker without ProcessRunner authority")
        if not link_command_outputs_superset(replacement, record.pending_link_command):
            return self.fail(node, "Workspace.set_link_command replacement must preserve declared outputs")
        record.pending_link_command = replacement
        self.store_workspace_record(workspace_id, record)
        return comptime_control_value(comptime_value_void(0))
    if method == "compile":
        if not self.capability_expect_arg_count(arg_count, 0, method, node):
            return comptime_control_error()
        let compiled = self.compile_workspace_record(record, capability, node, if record.intercept_active != 0: 1 else: 0)
        let result = compiled.result
        if result.kind == ComptimeValueKind.CV_INVALID:
            return comptime_control_error()
        if record.intercept_active != 0:
            record = self.enqueue_workspace_compile_result(record, result, compiled.messages, node)
            if self.had_error != 0:
                return comptime_control_error()
            self.store_workspace_record(workspace_id, record)
        return comptime_control_value(result)
    self.fail(node, "Workspace capability method '" ++ method ++ "' is not implemented yet")

fn ComptimeEvaluator.eval_capability_method_call(self: ComptimeEvaluator, recv_value: ComptimeValue, field: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let method = self.pool.resolve(field)
    let kind = recv_value.data0 as i32
    if kind == CapabilityKind.CK_BUILD_CTX:
        return self.eval_buildctx_capability_method(recv_value, method, arg_count, node)
    if kind == CapabilityKind.CK_BUILD_PROJECT_INFO:
        return self.eval_project_info_capability_method(recv_value, method, arg_count, node)
    if kind == CapabilityKind.CK_BUILD_DIAGNOSTICS:
        return self.eval_diagnostics_capability_method(recv_value, method, extra_start, arg_count, node)
    if kind == CapabilityKind.CK_BUILD_SOURCE_EMITTER:
        return self.eval_source_emitter_capability_method(recv_value, method, extra_start, arg_count, node)
    if kind == CapabilityKind.CK_BUILD_TOOL_FS:
        return self.eval_toolfs_capability_method(recv_value, method, extra_start, arg_count, node)
    if kind == CapabilityKind.CK_BUILD_PROCESS_RUNNER:
        return self.eval_process_runner_capability_method(recv_value, method, extra_start, arg_count, node)
    if kind == CapabilityKind.CK_BUILD_ACTION_CTX:
        return self.eval_actionctx_capability_method(recv_value, method, arg_count, node)
    if kind == CapabilityKind.CK_BUILD_WORKSPACE:
        return self.eval_workspace_capability_method(recv_value, method, extra_start, arg_count, node)
    self.fail(node, "capability method dispatch is not implemented for " ++ capability_registry_kind_name(kind) ++ "." ++ method)

fn ComptimeEvaluator.eval_module_let_decl(self: ComptimeEvaluator, decl: i32, use_node: i32) -> ComptimeControl:
    let sym = self.ast.get_data0(decl)
    for i in 0..self.active_global_syms.len() as i32:
        if self.active_global_syms.get(i as i64) == sym:
            return self.fail(use_node, "cyclic comptime constant dependency")
    let value_node = self.ast.get_data1(decl)
    if value_node == 0:
        return self.fail(use_node, "missing constant value")

    let saved_file = self.sema.local_file_id
    let saved_path = self.sema.current_module_path
    self.sema.local_file_id = self.decl_file_id(decl)
    self.sema.current_module_path = self.decl_path(decl)
    self.active_global_syms.push(sym)
    let result = self.eval_expr(value_node)
    self.active_global_syms.pop()
    self.sema.local_file_id = saved_file
    self.sema.current_module_path = saved_path
    result

fn ComptimeEvaluator.eval_src_call(self: ComptimeEvaluator, node: i32, arg_count: i32) -> ComptimeControl:
    if arg_count != 0:
        return self.fail(node, "src() takes no arguments")
    let path = self.current_source_path()
    let text = self.current_source_text()
    let loc = comptime_source_loc(text, self.ast.get_start(node))
    comptime_control_value(comptime_value_str(f"{path}:{loc.line}:{loc.col}"))

fn ComptimeEvaluator.node_is_src_call(self: ComptimeEvaluator, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_CALL:
        return 0
    if self.ast.get_data2(node) != 0:
        return 0
    let callee = self.ast.get_data0(node)
    if callee == 0 or self.ast.kind(callee) != NodeKind.NK_IDENT:
        return 0
    let sym = self.ast.get_data0(callee)
    if sym == self.sema.syms.src:
        return 1
    let canonical_sym = self.sema.pool_lookup_symbol(self.pool.resolve(sym))
    if canonical_sym == self.sema.syms.src: 1 else: 0

fn ComptimeEvaluator.magic_ident_kind(self: ComptimeEvaluator, node: i32) -> i32:
    var kind = self.sema.magic_ident_kind(node)
    if kind != SemaMagicIdentKind.NONE:
        return kind
    if node == 0 or self.ast.kind(node) != NodeKind.NK_IDENT:
        return SemaMagicIdentKind.NONE
    let sym = self.ast.get_data0(node)
    if sym == self.sema.syms.file_magic:
        return SemaMagicIdentKind.FILE
    if sym == self.sema.syms.line_magic:
        return SemaMagicIdentKind.LINE
    if sym == self.sema.syms.fn_magic:
        return SemaMagicIdentKind.FN
    SemaMagicIdentKind.NONE

fn ComptimeEvaluator.default_arg_uses_call_site(self: ComptimeEvaluator, default_node: i32) -> i32:
    if self.node_is_src_call(default_node) != 0:
        return 1
    if self.magic_ident_kind(default_node) != SemaMagicIdentKind.NONE: 1 else: 0

fn ComptimeEvaluator.eval_call_site_default_arg(self: ComptimeEvaluator, default_node: i32, call_node: i32, caller_path: str, caller_text: str, caller_fn_sym: i32) -> ComptimeControl:
    if self.node_is_src_call(default_node) != 0:
        let loc = comptime_source_loc(caller_text, self.ast.get_start(call_node))
        return comptime_control_value(comptime_value_str(f"{caller_path}:{loc.line}:{loc.col}"))
    let kind = self.magic_ident_kind(default_node)
    if kind == SemaMagicIdentKind.FILE:
        return comptime_control_value(comptime_value_str(caller_path))
    if kind == SemaMagicIdentKind.LINE:
        let loc = comptime_source_loc(caller_text, self.ast.get_start(call_node))
        return comptime_control_value(comptime_value_int(self.sema.ty_u32 as i32, loc.line as i64))
    if kind == SemaMagicIdentKind.FN:
        let name = if caller_fn_sym != 0: self.pool.resolve(caller_fn_sym) else: ""
        return comptime_control_value(comptime_value_str(name))
    comptime_control_error()

fn ComptimeEvaluator.eval_embed_file_call(self: ComptimeEvaluator, node: i32, arg_count: i32) -> ComptimeControl:
    if arg_count != 1:
        return self.fail(node, "embed_file() takes exactly one string argument")
    let args_start = self.ast.get_data1(node)
    let arg_signal = self.eval_expr(self.ast.get_extra(args_start))
    if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
        return arg_signal
    if arg_signal.value.kind != ComptimeValueKind.CV_STR:
        return self.fail(node, "embed_file() argument must be a comptime string")
    let path = comptime_resolve_embed_file_path(self.current_source_path(), arg_signal.value.text)
    if with_fs_file_exists(path) == 0:
        return self.fail(node, "embed_file: could not read '" ++ path ++ "'")
    comptime_control_value(comptime_value_str(with_fs_read_file(path)))

fn ComptimeEvaluator.eval_array(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let extra_start = self.ast.get_data0(node)
    let count = self.ast.get_data1(node)
    let start = self.extra_values.len() as i32
    for i in 0..count:
        let elem_signal = self.eval_expr(self.ast.get_extra(extra_start + i))
        if elem_signal.kind != ComptimeControlKind.CTL_VALUE:
            return elem_signal
        self.push_extra_value(elem_signal.value)
    comptime_control_value(comptime_value_array(self.node_type_or(node, 0), start, count))

fn ComptimeEvaluator.eval_tuple(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let extra_start = self.ast.get_data0(node)
    let count = self.ast.get_data1(node)
    let start = self.extra_values.len() as i32
    for i in 0..count:
        let elem_signal = self.eval_expr(self.ast.get_extra(extra_start + i))
        if elem_signal.kind != ComptimeControlKind.CTL_VALUE:
            return elem_signal
        self.push_extra_value(elem_signal.value)
    comptime_control_value(comptime_value_tuple(self.node_type_or(node, 0), start, count))

fn ComptimeEvaluator.eval_struct_lit(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    var type_id = self.node_type_or(node, 0)
    if type_id == 0:
        let name = self.ast.get_data0(node)
        if self.sema.named_types.contains(name):
            type_id = self.sema.named_types.get(name).unwrap()
    if type_id == 0:
        return self.fail(node, "comptime struct literal is missing type information")

    let resolved = self.sema.resolve_alias(type_id)
    let tk = self.sema.get_type_kind(resolved)
    if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_GENERIC_INST:
        return self.fail(node, "comptime struct literal requires a struct type")

    let field_total = self.sema.type_reflection_field_count(type_id)
    let extra_start = self.ast.get_data1(node)
    let init_count = self.ast.get_data2(node)
    let init_syms: Vec[i32] = Vec.new()
    let init_values: Vec[ComptimeValue] = Vec.new()

    for fi in 0..init_count:
        var field_sym = self.ast.get_extra(extra_start + fi * 2)
        if field_sym == 0:
            if fi >= field_total:
                return self.fail(node, "too many fields in comptime struct literal for '" ++ self.sema.type_name(type_id) ++ "'")
            field_sym = self.sema.type_reflection_field_name(type_id, fi)
        if self.struct_field_index(type_id, field_sym) < 0:
            return self.fail(node, "unknown comptime struct field '" ++ self.pool.resolve(field_sym) ++ "' for '" ++ self.sema.type_name(type_id) ++ "'")
        for pi in 0..init_syms.len() as i32:
            if init_syms.get(pi as i64) == field_sym:
                return self.fail(node, "duplicate comptime struct field '" ++ self.pool.resolve(field_sym) ++ "'")
        let field_signal = self.eval_expr(self.ast.get_extra(extra_start + fi * 2 + 1))
        if field_signal.kind != ComptimeControlKind.CTL_VALUE:
            return field_signal
        init_syms.push(field_sym)
        init_values.push(field_signal.value)

    let start = self.extra_values.len() as i32
    for fi in 0..field_total:
        let field_sym = self.sema.type_reflection_field_name(type_id, fi)
        var found = -1
        for pi in 0..init_syms.len() as i32:
            if init_syms.get(pi as i64) == field_sym:
                found = pi
                break
        if found < 0:
            return self.fail(node, "missing comptime struct field '" ++ self.pool.resolve(field_sym) ++ "'")
        self.push_extra_value(init_values.get(found as i64))
    comptime_control_value(comptime_value_struct(type_id, start, field_total))

fn ComptimeEvaluator.eval_range(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let start_node = self.ast.get_data0(node)
    let end_node = self.ast.get_data1(node)
    let inclusive = self.ast.get_data2(node)
    if start_node == 0 or end_node == 0:
        return self.fail(node, "open-ended ranges are not supported in comptime")
    let start_signal = self.eval_expr(start_node)
    if start_signal.kind != ComptimeControlKind.CTL_VALUE:
        return start_signal
    let end_signal = self.eval_expr(end_node)
    if end_signal.kind != ComptimeControlKind.CTL_VALUE:
        return end_signal
    if comptime_value_is_intlike(start_signal.value) == 0 or comptime_value_is_intlike(end_signal.value) == 0:
        return self.fail(node, "range bounds must be integers in comptime")
    comptime_control_value(
        comptime_value_range(
            self.node_type_or(node, 0),
            comptime_value_intlike(start_signal.value),
            comptime_value_intlike(end_signal.value),
            inclusive
        )
    )

fn ComptimeEvaluator.eval_cast(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let value_signal = self.eval_expr(self.ast.get_data0(node))
    if value_signal.kind != ComptimeControlKind.CTL_VALUE:
        return value_signal
    let target_type = self.node_type_or(node, self.sema.resolve_type_expr(self.ast.get_data1(node)) as i32)
    if target_type == 0:
        return self.fail(node, "comptime cast target type is unknown")
    if comptime_value_is_intlike(value_signal.value) != 0:
        return comptime_control_value(comptime_value_int(target_type, comptime_value_intlike(value_signal.value)))
    if value_signal.value.kind == ComptimeValueKind.CV_STR and self.sema.resolve_alias(target_type as TypeId) == self.sema.ty_str:
        return value_signal
    self.fail(node, "comptime cast is not supported for this value")

fn ComptimeEvaluator.eval_disc_variant_sym(self: ComptimeEvaluator, sym: i32, node: i32) -> ComptimeControl:
    if not self.sema.variant_lookup.contains(sym):
        return self.unsupported(node)
    let enum_tid = self.sema.variant_type_ids.get(sym).unwrap()
    let enum_resolved = self.sema.resolve_alias(enum_tid as TypeId)
    if not self.sema.disc_repr_types.contains(enum_resolved as i32) or self.sema.disc_has_payload.contains(enum_resolved as i32):
        return self.unsupported(node)
    let disc = if self.sema.disc_values.contains(sym): self.sema.disc_values.get(sym).unwrap() else: self.sema.variant_lookup.get(sym).unwrap()
    let repr_ty = self.sema.disc_repr_types.get(enum_resolved as i32).unwrap()
    comptime_control_value(comptime_value_int(self.node_type_or(node, repr_ty), disc as i64))

fn ComptimeEvaluator.eval_variant_shorthand(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let arg_count = self.ast.get_data2(node)
    if arg_count != 0:
        return self.fail(node, "comptime enum variant shorthand with payload is not supported yet")
    var sym = self.ast.get_data0(node)
    if self.sema.comp_resolved.contains(node):
        sym = self.sema.comp_resolved.get(node).unwrap()
    self.eval_disc_variant_sym(sym, node)

fn ComptimeEvaluator.eval_ident(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let sym = self.ast.get_data0(node)
    let magic_kind = self.magic_ident_kind(node)
    if magic_kind == SemaMagicIdentKind.FILE:
        return comptime_control_value(comptime_value_str(self.current_source_path()))
    if magic_kind == SemaMagicIdentKind.LINE:
        let loc = comptime_source_loc(self.current_source_text(), self.ast.get_start(node))
        return comptime_control_value(comptime_value_int(self.sema.ty_u32 as i32, loc.line as i64))
    if magic_kind == SemaMagicIdentKind.FN:
        if self.active_fn_syms.len() > 0:
            return comptime_control_value(comptime_value_str(self.pool.resolve(self.active_fn_syms.get((self.active_fn_syms.len() - 1) as i64))))
        return comptime_control_value(comptime_value_str(""))
    let idx = self.lookup_slot_index(sym)
    if idx >= 0:
        return comptime_control_value(self.slot_values.get(idx as i64))
    let decl = self.find_module_let_decl(sym)
    if decl != 0:
        if self.ast.get_data2(decl) % 2 != 0:
            return self.fail(node, "mutable global access is not allowed in comptime")
        return self.eval_module_let_decl(decl, node)
    if self.sema.variant_lookup.contains(sym):
        return self.eval_disc_variant_sym(sym, node)
    if self.find_fn_decl_node(sym) != 0:
        return comptime_control_value(comptime_value_fn(self.node_type_or(node, 0), sym))
    self.fail(node, "runtime value is not available at comptime")

fn ComptimeEvaluator.eval_field_access(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let base = self.ast.get_data0(node)
    let field = self.ast.get_data1(node)
    if self.ast.kind(base) == NodeKind.NK_IDENT:
        let base_sym = self.ast.get_data0(base)
        if self.sema.named_types.contains(base_sym):
            let base_tid = self.sema.named_types.get(base_sym).unwrap()
            let base_resolved = self.sema.resolve_alias(base_tid as TypeId)
            if self.sema.get_type_kind(base_resolved) == TypeKind.TY_ENUM and self.sema.enum_has_variant(base_resolved as i32, field) != 0:
                let qual_name = self.pool.resolve(base_sym) ++ "." ++ self.pool.resolve(field)
                let qual_sym = self.pool.intern(qual_name)
                if self.sema.variant_lookup.contains(qual_sym):
                    return self.eval_disc_variant_sym(qual_sym, node)
                return self.eval_disc_variant_sym(field, node)
    let base_signal = self.eval_expr(base)
    if base_signal.kind != ComptimeControlKind.CTL_VALUE:
        return base_signal
    if base_signal.value.kind == ComptimeValueKind.CV_STRUCT:
        let field_index = self.struct_field_index(base_signal.value.type_id, field)
        if field_index < 0:
            return self.fail(node, "unknown comptime struct field")
        return comptime_control_value(self.extra_values.get((base_signal.value.extra_start + field_index) as i64))
    self.fail(node, "comptime field access requires a struct value, got " ++ comptime_value_kind_name(base_signal.value.kind))

fn ComptimeEvaluator.eval_index(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let base_signal = self.eval_expr(self.ast.get_data0(node))
    if base_signal.kind != ComptimeControlKind.CTL_VALUE:
        return base_signal
    let index_signal = self.eval_expr(self.ast.get_data1(node))
    if index_signal.kind != ComptimeControlKind.CTL_VALUE:
        return index_signal
    if comptime_value_is_intlike(index_signal.value) == 0:
        return self.fail(node, "comptime index must be an integer")
    let index = comptime_value_intlike(index_signal.value)
    let base = base_signal.value
    if base.kind == ComptimeValueKind.CV_ARRAY or base.kind == ComptimeValueKind.CV_TUPLE or base.kind == ComptimeValueKind.CV_VEC:
        if index < 0 or index >= base.extra_count as i64:
            return self.fail(node, "comptime index out of bounds")
        return comptime_control_value(self.extra_values.get((base.extra_start + index as i32) as i64))
    self.fail(node, "comptime index requires an array, tuple, or vec")

fn ComptimeEvaluator.fstring_segment_text(self: ComptimeEvaluator, value: ComptimeValue, node: i32) -> str:
    if value.kind == ComptimeValueKind.CV_STR:
        return value.text
    if value.kind == ComptimeValueKind.CV_INT:
        return f"{value.data0}"
    if value.kind == ComptimeValueKind.CV_BOOL:
        if value.data0 != 0:
            return "true"
        return "false"
    let _ = self.fail(node, "comptime f-string does not support " ++ comptime_value_kind_name(value.kind) ++ " interpolation yet")
    ""

fn ComptimeEvaluator.eval_fstring(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let segment_count = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    var out = ""
    var cursor = extra_start
    for si in 0..segment_count:
        let segment_kind = self.ast.get_extra(cursor)
        cursor = cursor + 1
        if segment_kind == FStringSegmentKind.LITERAL:
            let sym = self.ast.get_extra(cursor)
            cursor = cursor + 1
            out = out ++ comptime_decode_string_escapes(self.pool.resolve(sym))
        else if segment_kind == FStringSegmentKind.EXPR:
            let expr_node = self.ast.get_extra(cursor)
            let spec_node = self.ast.get_extra(cursor + 1)
            cursor = cursor + 2
            if spec_node != 0:
                return self.fail(node, "comptime f-string format specs are not supported yet")
            let value_signal = self.eval_expr(expr_node)
            if value_signal.kind != ComptimeControlKind.CTL_VALUE:
                return value_signal
            if self.had_error != 0:
                return comptime_control_error()
            out = out ++ self.fstring_segment_text(value_signal.value, expr_node)
        else:
            return self.fail(node, "invalid comptime f-string segment")
    comptime_control_value(comptime_value_str(out))

fn ComptimeEvaluator.eval_unary(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let inner = self.eval_expr(self.ast.get_data1(node))
    if inner.kind != ComptimeControlKind.CTL_VALUE:
        return inner
    let op = self.ast.get_data0(node)
    let result_ty = self.node_type_or(node, inner.value.type_id)
    if op == UnaryOp.UOP_NEGATE:
        if comptime_value_is_intlike(inner.value) == 0:
            return self.fail(node, "unary '-' requires integer comptime values")
        return comptime_control_value(comptime_value_int(result_ty, 0 - comptime_value_intlike(inner.value)))
    if op == UnaryOp.UOP_BIT_NOT:
        if comptime_value_is_intlike(inner.value) == 0:
            return self.fail(node, "bitwise not requires integer comptime values")
        return comptime_control_value(comptime_value_int(result_ty, 0 - comptime_value_intlike(inner.value) - 1))
    if op == UnaryOp.UOP_NOT:
        let truthy = comptime_value_truthy(inner.value)
        if truthy < 0:
            return self.fail(node, "logical not requires bool or integer comptime values")
        return comptime_control_value(comptime_value_bool(if truthy == 0: 1 else: 0))
    self.unsupported(node)

fn ComptimeEvaluator.eval_binary_compare(self: ComptimeEvaluator, node: i32, op: i32, lhs: ComptimeValue, rhs: ComptimeValue) -> ComptimeControl:
    if comptime_value_is_intlike(lhs) != 0 and comptime_value_is_intlike(rhs) != 0:
        let lv = comptime_value_intlike(lhs)
        let rv = comptime_value_intlike(rhs)
        if op == BinaryOp.OP_EQ: return comptime_control_value(comptime_value_bool(if lv == rv: 1 else: 0))
        if op == BinaryOp.OP_NEQ: return comptime_control_value(comptime_value_bool(if lv != rv: 1 else: 0))
        if op == BinaryOp.OP_LT: return comptime_control_value(comptime_value_bool(if lv < rv: 1 else: 0))
        if op == BinaryOp.OP_GT: return comptime_control_value(comptime_value_bool(if lv > rv: 1 else: 0))
        if op == BinaryOp.OP_LTE: return comptime_control_value(comptime_value_bool(if lv <= rv: 1 else: 0))
        if op == BinaryOp.OP_GTE: return comptime_control_value(comptime_value_bool(if lv >= rv: 1 else: 0))
    if lhs.kind == ComptimeValueKind.CV_STR and rhs.kind == ComptimeValueKind.CV_STR:
        if op == BinaryOp.OP_EQ:
            return comptime_control_value(comptime_value_bool(comptime_values_equal(lhs, rhs, self.extra_values)))
        if op == BinaryOp.OP_NEQ:
            return comptime_control_value(comptime_value_bool(if comptime_values_equal(lhs, rhs, self.extra_values) != 0: 0 else: 1))
    if lhs.kind == ComptimeValueKind.CV_BOOL and rhs.kind == ComptimeValueKind.CV_BOOL:
        let lv = lhs.data0
        let rv = rhs.data0
        if op == BinaryOp.OP_EQ: return comptime_control_value(comptime_value_bool(if lv == rv: 1 else: 0))
        if op == BinaryOp.OP_NEQ: return comptime_control_value(comptime_value_bool(if lv != rv: 1 else: 0))
    self.fail(node, "comparison requires comptime scalar values")

fn ComptimeEvaluator.eval_binary_membership(self: ComptimeEvaluator, node: i32, lhs: ComptimeValue, rhs: ComptimeValue, negate: i32) -> ComptimeControl:
    var matched = 0
    if rhs.kind == ComptimeValueKind.CV_ARRAY or rhs.kind == ComptimeValueKind.CV_TUPLE or rhs.kind == ComptimeValueKind.CV_VEC:
        for i in 0..rhs.extra_count:
            let item = self.extra_values.get((rhs.extra_start + i) as i64)
            if comptime_values_equal(lhs, item, self.extra_values) != 0:
                matched = 1
                break
    else if rhs.kind == ComptimeValueKind.CV_RANGE and comptime_value_is_intlike(lhs) != 0:
        let value = comptime_value_intlike(lhs)
        if rhs.extra_start != 0:
            matched = if value >= rhs.data0 and value <= rhs.data1: 1 else: 0
        else:
            matched = if value >= rhs.data0 and value < rhs.data1: 1 else: 0
    else:
        return self.fail(node, "'in' requires an array, tuple, or range in comptime")
    if negate != 0:
        matched = if matched != 0: 0 else: 1
    comptime_control_value(comptime_value_bool(matched))

fn ComptimeEvaluator.eval_binary(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let op = self.ast.get_data0(node)
    if op == BinaryOp.OP_AND or op == BinaryOp.OP_OR:
        let lhs_signal = self.eval_expr(self.ast.get_data1(node))
        if lhs_signal.kind != ComptimeControlKind.CTL_VALUE:
            return lhs_signal
        let lhs_truthy = comptime_value_truthy(lhs_signal.value)
        if lhs_truthy < 0:
            return self.fail(node, "logical operators require bool or integer comptime values")
        if op == BinaryOp.OP_AND and lhs_truthy == 0:
            return comptime_control_value(comptime_value_bool(0))
        if op == BinaryOp.OP_OR and lhs_truthy != 0:
            return comptime_control_value(comptime_value_bool(1))
        let rhs_signal = self.eval_expr(self.ast.get_data2(node))
        if rhs_signal.kind != ComptimeControlKind.CTL_VALUE:
            return rhs_signal
        let rhs_truthy = comptime_value_truthy(rhs_signal.value)
        if rhs_truthy < 0:
            return self.fail(node, "logical operators require bool or integer comptime values")
        return comptime_control_value(comptime_value_bool(rhs_truthy))

    let lhs_signal = self.eval_expr(self.ast.get_data1(node))
    if lhs_signal.kind != ComptimeControlKind.CTL_VALUE:
        return lhs_signal
    let rhs_signal = self.eval_expr(self.ast.get_data2(node))
    if rhs_signal.kind != ComptimeControlKind.CTL_VALUE:
        return rhs_signal
    let lhs = lhs_signal.value
    let rhs = rhs_signal.value

    if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE:
        return self.eval_binary_compare(node, op, lhs, rhs)
    if op == BinaryOp.OP_IN:
        return self.eval_binary_membership(node, lhs, rhs, 0)
    if op == BinaryOp.OP_NOT_IN:
        return self.eval_binary_membership(node, lhs, rhs, 1)
    if op == BinaryOp.OP_CONCAT or (op == BinaryOp.OP_ADD and lhs.kind == ComptimeValueKind.CV_STR and rhs.kind == ComptimeValueKind.CV_STR):
        if lhs.kind != ComptimeValueKind.CV_STR or rhs.kind != ComptimeValueKind.CV_STR:
            return self.fail(node, "string concatenation requires comptime strings")
        return comptime_control_value(comptime_value_str(lhs.text ++ rhs.text))

    if comptime_value_is_intlike(lhs) == 0 or comptime_value_is_intlike(rhs) == 0:
        return self.fail(node, "operator requires integer comptime values")
    let lv = comptime_value_intlike(lhs)
    let rv = comptime_value_intlike(rhs)
    let result_ty = self.node_type_or(node, if lhs.type_id != 0: lhs.type_id else: rhs.type_id)
    if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_ADD_SAT:
        return comptime_control_value(comptime_value_int(result_ty, lv + rv))
    if op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_SUB_SAT:
        return comptime_control_value(comptime_value_int(result_ty, lv - rv))
    if op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP or op == BinaryOp.OP_MUL_SAT:
        return comptime_control_value(comptime_value_int(result_ty, lv * rv))
    if op == BinaryOp.OP_DIV:
        if rv == 0:
            return self.fail(node, "division by zero in comptime")
        return comptime_control_value(comptime_value_int(result_ty, lv / rv))
    if op == BinaryOp.OP_MOD:
        if rv == 0:
            return self.fail(node, "modulo by zero in comptime")
        return comptime_control_value(comptime_value_int(result_ty, lv % rv))
    if op == BinaryOp.OP_SHL:
        return comptime_control_value(comptime_value_int(result_ty, self.eval_shift_value(op, result_ty, lv, rv)))
    if op == BinaryOp.OP_SHR:
        return comptime_control_value(comptime_value_int(result_ty, self.eval_shift_value(op, result_ty, lv, rv)))
    if op == BinaryOp.OP_BIT_AND:
        return comptime_control_value(comptime_value_int(result_ty, lv & rv))
    if op == BinaryOp.OP_BIT_OR:
        return comptime_control_value(comptime_value_int(result_ty, lv | rv))
    if op == BinaryOp.OP_BIT_XOR:
        return comptime_control_value(comptime_value_int(result_ty, lv ^ rv))
    self.unsupported(node)

fn ComptimeEvaluator.eval_let_binding(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let value_signal = self.eval_expr(self.ast.get_data1(node))
    if value_signal.kind != ComptimeControlKind.CTL_VALUE:
        return value_signal
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2
    self.bind_value(self.ast.get_data0(node), value_signal.value, is_mut)
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.eval_assign(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let target = self.ast.get_data0(node)
    let value_signal = self.eval_expr(self.ast.get_data1(node))
    if value_signal.kind != ComptimeControlKind.CTL_VALUE:
        return value_signal
    if self.ast.kind(target) == NodeKind.NK_FIELD_ACCESS:
        return self.assign_struct_field_value(target, value_signal.value, node)
    if self.ast.kind(target) != NodeKind.NK_IDENT:
        return self.fail(node, "comptime assignment only supports local identifiers and struct fields")
    self.assign_value(self.ast.get_data0(target), value_signal.value, node)

fn ComptimeEvaluator.eval_if(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let cond_signal = self.eval_expr(self.ast.get_data0(node))
    if cond_signal.kind != ComptimeControlKind.CTL_VALUE:
        return cond_signal
    let truthy = comptime_value_truthy(cond_signal.value)
    if truthy < 0:
        return self.fail(node, "comptime if requires a bool or integer condition")
    if truthy != 0:
        return self.eval_expr(self.ast.get_data1(node))
    let else_node = self.ast.get_data2(node)
    if else_node != 0:
        return self.eval_expr(else_node)
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.match_pattern(self: ComptimeEvaluator, pat: i32, value: ComptimeValue, node: i32) -> i32:
    if pat == 0:
        return 1
    let kind = self.ast.kind(pat)
    if kind == NodeKind.NK_PAT_WILDCARD:
        return 1
    if kind == NodeKind.NK_PAT_IDENT:
        self.bind_value(self.ast.get_data0(pat), value, 0)
        return 1
    if kind == NodeKind.NK_PAT_TYPED_BIND:
        self.bind_value(self.ast.get_data0(pat), value, 0)
        return 1
    if kind == NodeKind.NK_PAT_INT:
        if comptime_value_is_intlike(value) == 0:
            return 0
        if comptime_value_intlike(value) == self.ast.int_lit_value(pat):
            return 1
        return 0
    if kind == NodeKind.NK_PAT_BOOL:
        if value.kind != ComptimeValueKind.CV_BOOL:
            return 0
        if value.data0 == self.ast.get_data0(pat) as i64:
            return 1
        return 0
    if kind == NodeKind.NK_PAT_STRING:
        if value.kind != ComptimeValueKind.CV_STR:
            return 0
        if value.text == self.pool.resolve(self.ast.get_data0(pat)):
            return 1
        return 0
    if kind == NodeKind.NK_PAT_RANGE:
        if comptime_value_is_intlike(value) == 0:
            return 0
        let v = comptime_value_intlike(value)
        let start_value = self.ast.get_data0(pat) as i64
        let end_value = self.ast.get_data1(pat) as i64
        if self.ast.get_data2(pat) != 0:
            return if v >= start_value and v <= end_value: 1 else: 0
        return if v >= start_value and v < end_value: 1 else: 0
    if kind == NodeKind.NK_PAT_AT_BINDING:
        self.bind_value(self.ast.get_data0(pat), value, 0)
        return self.match_pattern(self.ast.get_data1(pat), value, node)
    if kind == NodeKind.NK_PAT_OR:
        let start = self.slot_syms.len() as i32
        let extra_start = self.ast.get_data0(pat)
        let count = self.ast.get_data1(pat)
        for i in 0..count:
            while self.slot_syms.len() as i32 > start:
                self.slot_syms.pop()
                self.slot_values.pop()
                self.slot_muts.pop()
            if self.match_pattern(self.ast.get_extra(extra_start + i), value, node) != 0:
                return 1
        while self.slot_syms.len() as i32 > start:
            self.slot_syms.pop()
            self.slot_values.pop()
            self.slot_muts.pop()
        return 0
    if kind == NodeKind.NK_PAT_TUPLE:
        if value.kind != ComptimeValueKind.CV_TUPLE:
            return 0
        let count = self.ast.get_data1(pat)
        if value.extra_count != count:
            return 0
        let extra_start = self.ast.get_data0(pat)
        for i in 0..count:
            let elem_pat = self.ast.get_extra(extra_start + i)
            let elem_value = self.extra_values.get((value.extra_start + i) as i64)
            if self.match_pattern(elem_pat, elem_value, node) == 0:
                return 0
        return 1
    if kind == NodeKind.NK_PAT_VARIANT or kind == NodeKind.NK_PAT_ENUM_SHORTHAND:
        var variant_sym = self.ast.get_data0(pat)
        if self.sema.comp_resolved.contains(pat):
            variant_sym = self.sema.comp_resolved.get(pat).unwrap()
        if value.kind == ComptimeValueKind.CV_ENUM:
            if value.data0 as i32 != variant_sym:
                return 0
            let bind_count = self.ast.get_data2(pat)
            if bind_count != value.extra_count:
                return 0
            let extra_start = self.ast.get_data1(pat)
            for i in 0..bind_count:
                let inner_pat = self.ast.get_extra(extra_start + i)
                let inner_value = self.extra_values.get((value.extra_start + i) as i64)
                if self.match_pattern(inner_pat, inner_value, node) == 0:
                    return 0
            return 1
        if comptime_value_is_intlike(value) != 0:
            let variant_value = self.eval_disc_variant_sym(variant_sym, pat)
            if variant_value.kind == ComptimeControlKind.CTL_VALUE and comptime_value_is_intlike(variant_value.value) != 0:
                return if comptime_value_intlike(value) == comptime_value_intlike(variant_value.value): 1 else: 0
        return 0
    if self.require_success != 0:
        let _ = self.fail(pat, "pattern is not comptime-evaluable yet")
    0

fn ComptimeEvaluator.eval_match(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let subject_signal = self.eval_expr(self.ast.get_data0(node))
    if subject_signal.kind != ComptimeControlKind.CTL_VALUE:
        return subject_signal
    let extra_start = self.ast.get_data1(node)
    let arm_count = self.ast.get_data2(node)
    for i in 0..arm_count:
        let arm = self.ast.get_extra(extra_start + i)
        self.push_scope()
        let pat = self.ast.get_data0(arm)
        if self.match_pattern(pat, subject_signal.value, arm) != 0:
            let guard = self.ast.get_data2(arm)
            var guard_ok = 1
            if guard != 0:
                let guard_signal = self.eval_expr(guard)
                if guard_signal.kind != ComptimeControlKind.CTL_VALUE:
                    self.pop_scope()
                    return guard_signal
                let truthy = comptime_value_truthy(guard_signal.value)
                if truthy < 0:
                    self.pop_scope()
                    return self.fail(guard, "match guard must be bool or integer in comptime")
                guard_ok = truthy
            if guard_ok != 0:
                let body_signal = self.eval_expr(self.ast.get_data1(arm))
                self.pop_scope()
                return body_signal
        self.pop_scope()
    self.fail(node, "no comptime match arm matched")

fn ComptimeEvaluator.signal_matches_loop(self: ComptimeEvaluator, signal: ComptimeControl, loop_label: i32) -> i32:
    if signal.kind != ComptimeControlKind.CTL_BREAK and signal.kind != ComptimeControlKind.CTL_CONTINUE:
        return 0
    if signal.label == 0:
        return 1
    if signal.label == loop_label:
        return 1
    0

fn ComptimeEvaluator.signal_matches_block(self: ComptimeEvaluator, signal: ComptimeControl, block_label: i32) -> i32:
    if signal.kind != ComptimeControlKind.CTL_BREAK:
        return 0
    if block_label == 0:
        return 0
    if signal.label == block_label:
        return 1
    0

fn ComptimeEvaluator.eval_loop(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let loop_label = self.ast.get_data1(node)
    self.loop_labels.push(loop_label)
    while true:
        let body_signal = self.eval_expr(self.ast.get_data0(node))
        if body_signal.kind == ComptimeControlKind.CTL_VALUE:
            continue
        if self.signal_matches_loop(body_signal, loop_label) != 0:
            if body_signal.kind == ComptimeControlKind.CTL_CONTINUE:
                continue
            self.loop_labels.pop()
            return comptime_control_value(body_signal.value)
        self.loop_labels.pop()
        return body_signal
    comptime_control_error()

fn ComptimeEvaluator.eval_while(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let loop_label = self.ast.get_data2(node)
    self.loop_labels.push(loop_label)
    while true:
        let cond_signal = self.eval_expr(self.ast.get_data0(node))
        if cond_signal.kind != ComptimeControlKind.CTL_VALUE:
            self.loop_labels.pop()
            return cond_signal
        let truthy = comptime_value_truthy(cond_signal.value)
        if truthy < 0:
            self.loop_labels.pop()
            return self.fail(node, "while condition must be bool or integer in comptime")
        if truthy == 0:
            self.loop_labels.pop()
            return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
        let body_signal = self.eval_expr(self.ast.get_data1(node))
        if body_signal.kind == ComptimeControlKind.CTL_VALUE:
            continue
        if self.signal_matches_loop(body_signal, loop_label) != 0:
            if body_signal.kind == ComptimeControlKind.CTL_CONTINUE:
                continue
            self.loop_labels.pop()
            return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
        self.loop_labels.pop()
        return body_signal
    comptime_control_error()

fn ComptimeEvaluator.eval_do_while(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let loop_label = self.ast.get_data2(node)
    self.loop_labels.push(loop_label)
    while true:
        let body_signal = self.eval_expr(self.ast.get_data0(node))
        if body_signal.kind != ComptimeControlKind.CTL_VALUE:
            if self.signal_matches_loop(body_signal, loop_label) != 0:
                if body_signal.kind != ComptimeControlKind.CTL_CONTINUE:
                    self.loop_labels.pop()
                    return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
            else:
                self.loop_labels.pop()
                return body_signal
        let cond_signal = self.eval_expr(self.ast.get_data1(node))
        if cond_signal.kind != ComptimeControlKind.CTL_VALUE:
            self.loop_labels.pop()
            return cond_signal
        let truthy = comptime_value_truthy(cond_signal.value)
        if truthy < 0:
            self.loop_labels.pop()
            return self.fail(node, "do-while condition must be bool or integer in comptime")
        if truthy == 0:
            self.loop_labels.pop()
            return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
    comptime_control_error()

fn ComptimeEvaluator.eval_for(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let iterable_signal = self.eval_expr(self.ast.get_data1(node))
    if iterable_signal.kind != ComptimeControlKind.CTL_VALUE:
        return iterable_signal
    let binding = self.ast.get_data0(node)
    let body = self.ast.get_data2(node)
    var count = 0
    if iterable_signal.value.kind == ComptimeValueKind.CV_ARRAY or iterable_signal.value.kind == ComptimeValueKind.CV_TUPLE or iterable_signal.value.kind == ComptimeValueKind.CV_VEC:
        count = iterable_signal.value.extra_count
    else if iterable_signal.value.kind == ComptimeValueKind.CV_RANGE:
        let start_value = iterable_signal.value.data0
        let end_value = iterable_signal.value.data1
        count = if iterable_signal.value.extra_start != 0: (end_value - start_value + 1) as i32 else: (end_value - start_value) as i32
        if count < 0:
            count = 0
    else:
        return self.fail(node, "comptime for requires an array, tuple, vec, or range")

    let for_meta = self.ast.find_for_meta(node)
    let index_binding = if for_meta >= 0: self.ast.for_meta_index_binding(for_meta) else: 0
    let loop_label = if for_meta >= 0: self.ast.for_meta_label(for_meta) else: 0
    self.loop_labels.push(loop_label)
    for i in 0..count:
        self.push_scope()
        if iterable_signal.value.kind == ComptimeValueKind.CV_RANGE:
            let step_value = iterable_signal.value.data0 + i as i64
            self.bind_value(binding, comptime_value_int(self.sema.ty_i64 as i32, step_value), 0)
        else:
            let elem = self.extra_values.get((iterable_signal.value.extra_start + i) as i64)
            self.bind_value(binding, elem, 0)
        if index_binding != 0:
            self.bind_value(index_binding, comptime_value_int(self.sema.ty_i64 as i32, i as i64), 0)
        let body_signal = self.eval_expr(body)
        self.pop_scope()
        if body_signal.kind == ComptimeControlKind.CTL_VALUE:
            continue
        if self.signal_matches_loop(body_signal, loop_label) != 0:
            if body_signal.kind == ComptimeControlKind.CTL_CONTINUE:
                continue
            self.loop_labels.pop()
            return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
        self.loop_labels.pop()
        return body_signal
    self.loop_labels.pop()
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.eval_call(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let callee = self.ast.get_data0(node)
    let arg_count = self.ast.get_data2(node)
    if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
        let recv_node = self.ast.get_data0(callee)
        let field = self.ast.get_data1(callee)
        let method_name = self.pool.resolve(field)
        let recv_type = self.static_receiver_type(recv_node)
        if recv_type != 0:
            if method_name == "new":
                let result_type = self.node_type_or(node, recv_type)
                if result_type != 0:
                    let resolved_result = self.sema.resolve_alias(result_type)
                    let result_name = self.sema.type_name(resolved_result)
                    if comptime_type_name_has_base(result_name, "Vec") != 0 or comptime_type_name_has_base(result_name, "HashMap") != 0:
                        return self.eval_static_collection_new(result_type, node, arg_count)
            return self.eval_static_type_method_call(recv_type, field, self.ast.get_data1(node), arg_count, node)
        let recv_signal = self.eval_expr(recv_node)
        if recv_signal.kind != ComptimeControlKind.CTL_VALUE:
            return recv_signal
        if recv_signal.value.kind == ComptimeValueKind.CV_CAPABILITY:
            return self.eval_capability_method_call(recv_signal.value, field, self.ast.get_data1(node), arg_count, node)
        if recv_signal.value.kind == ComptimeValueKind.CV_STRUCT:
            let field_index = self.struct_field_index(recv_signal.value.type_id, field)
            if field_index >= 0:
                let field_value = self.extra_values.get((recv_signal.value.extra_start + field_index) as i64)
                if field_value.kind == ComptimeValueKind.CV_FN:
                    return self.eval_fn_value_call(field_value, self.ast.get_data1(node), arg_count, node)
            if self.sema.comp_resolved.contains(node):
                return self.eval_resolved_method_call(self.sema.comp_resolved.get(node).unwrap(), recv_signal.value, self.ast.get_data1(node), arg_count, node)
        if recv_signal.value.kind == ComptimeValueKind.CV_VEC or recv_signal.value.kind == ComptimeValueKind.CV_BYTES:
            if recv_signal.value.kind == ComptimeValueKind.CV_BYTES:
                return self.eval_bytes_method_call(recv_node, recv_signal.value, field, self.ast.get_data1(node), arg_count, node)
            return self.eval_vec_method_call(recv_node, recv_signal.value, field, self.ast.get_data1(node), arg_count, node)
        if recv_signal.value.kind == ComptimeValueKind.CV_MAP:
            return self.eval_map_method_call(recv_node, recv_signal.value, field, self.ast.get_data1(node), arg_count, node)
        if recv_signal.value.kind == ComptimeValueKind.CV_STR:
            return self.eval_str_method_call(recv_signal.value, field, self.ast.get_data1(node), arg_count, node)
        return self.fail(node, "method '" ++ self.pool.resolve(field) ++ "' is not comptime-evaluable yet")
    if self.ast.kind(callee) != NodeKind.NK_IDENT:
        return self.fail(node, "only direct comptime function calls are supported")
    let fn_sym = self.ast.get_data0(callee)
    let callee_slot = self.lookup_slot_index(fn_sym)
    if callee_slot >= 0:
        let callee_value = self.slot_values.get(callee_slot as i64)
        if callee_value.kind == ComptimeValueKind.CV_FN:
            return self.eval_fn_value_call(callee_value, self.ast.get_data1(node), arg_count, node)
        return self.fail(node, "callee is not a comptime function value")
    if self.sema.variant_lookup.contains(fn_sym):
        return self.eval_variant_constructor_call(fn_sym, self.ast.get_data1(node), arg_count, node)
    self.eval_fn_symbol_call(fn_sym, self.ast.get_data1(node), arg_count, node)

fn ComptimeEvaluator.eval_fn_value_call(self: ComptimeEvaluator, fn_value: ComptimeValue, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    if fn_value.kind != ComptimeValueKind.CV_FN:
        return self.fail(node, "callee is not a comptime function value")
    self.eval_fn_symbol_call(fn_value.data0 as i32, extra_start, arg_count, node)

fn ComptimeEvaluator.eval_fn_symbol_call(self: ComptimeEvaluator, fn_sym: i32, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    if fn_sym == self.sema.syms.src:
        return self.eval_src_call(node, arg_count)
    if fn_sym == self.sema.syms.embed_file:
        return self.eval_embed_file_call(node, arg_count)
    let arg_values: Vec[ComptimeValue] = Vec.new()
    for i in 0..arg_count:
        let arg_signal = self.eval_expr(self.ast.get_extra(extra_start + i))
        if arg_signal.kind != ComptimeControlKind.CTL_VALUE:
            return arg_signal
        arg_values.push(arg_signal.value)
    self.eval_fn_symbol_call_values(fn_sym, arg_values, node)

fn ComptimeEvaluator.eval_allowed_runtime_call(self: ComptimeEvaluator, fn_sym: i32, arg_values: Vec[ComptimeValue], node: i32) -> ComptimeControl:
    let fn_name = self.pool.resolve(fn_sym)
    if fn_name == "with_panic":
        if arg_values.len() as i32 != 3:
            return self.fail(node, "with_panic takes three arguments")
        let message = arg_values.get(0)
        let location = arg_values.get(1)
        let line = arg_values.get(2)
        if message.kind != ComptimeValueKind.CV_STR or location.kind != ComptimeValueKind.CV_STR or comptime_value_is_intlike(line) == 0:
            return self.fail(node, "with_panic expects string, string, integer arguments")
        let line_value = comptime_value_intlike(line)
        let rendered_location =
            if line_value > 0:
                location.text ++ f":{line_value}"
            else:
                location.text
        self.runtime_exit_code = 134
        self.runtime_stderr = "panic at " ++ rendered_location ++ ": " ++ message.text ++ "\n"
        self.had_error = 1
        return comptime_control_error()
    if fn_name == "with_println_str" or fn_name == "with_print_str" or fn_name == "with_eprint" or fn_name == "with_write" or fn_name == "with_ewrite":
        if arg_values.len() as i32 != 1:
            return self.fail(node, fn_name ++ " takes one argument")
        let text = arg_values.get(0)
        if text.kind != ComptimeValueKind.CV_STR:
            return self.fail(node, fn_name ++ " argument must be a string")
        if fn_name == "with_println_str":
            with_println_str(text.text)
        else if fn_name == "with_print_str":
            with_print_str(text.text)
        else if fn_name == "with_eprint":
            with_eprint(text.text)
        else if fn_name == "with_write":
            with_write(text.text)
        else:
            with_ewrite(text.text)
        return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
    if fn_name == "with_println_i32" or fn_name == "with_println_i64":
        if arg_values.len() as i32 != 1:
            return self.fail(node, fn_name ++ " takes one argument")
        let value = arg_values.get(0)
        if comptime_value_is_intlike(value) == 0:
            return self.fail(node, fn_name ++ " argument must be an integer")
        if fn_name == "with_println_i32":
            with_println_i32(comptime_value_intlike(value) as i32)
        else:
            with_println_i64(comptime_value_intlike(value))
        return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
    if fn_name == "with_println_bool":
        if arg_values.len() as i32 != 1:
            return self.fail(node, "with_println_bool takes one argument")
        let value = arg_values.get(0)
        if value.kind != ComptimeValueKind.CV_BOOL:
            return self.fail(node, "with_println_bool argument must be a bool")
        with_println_bool(value.data0 != 0)
        return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
    if fn_name == "with_getenv_str":
        if arg_values.len() as i32 != 1:
            return self.fail(node, "with_getenv_str takes one argument")
        let name = arg_values.get(0)
        if name.kind != ComptimeValueKind.CV_STR:
            return self.fail(node, "with_getenv_str argument must be a string")
        return comptime_control_value(comptime_value_str(with_getenv_str(name.text)))
    if fn_name == "with_setenv_str":
        if arg_values.len() as i32 != 2:
            return self.fail(node, "with_setenv_str takes two arguments")
        let name = arg_values.get(0)
        let value = arg_values.get(1)
        if name.kind != ComptimeValueKind.CV_STR or value.kind != ComptimeValueKind.CV_STR:
            return self.fail(node, "with_setenv_str expects string arguments")
        self.record_runtime_env_set(name.text)
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_setenv_str(name.text, value.text) as i64))
    if fn_name == "with_str_len":
        if arg_values.len() as i32 != 1:
            return self.fail(node, "with_str_len takes one argument")
        let text = arg_values.get(0)
        if text.kind != ComptimeValueKind.CV_STR:
            return self.fail(node, "with_str_len argument must be a string")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), with_str_len(text.text)))
    if fn_name == "with_str_byte_at":
        if arg_values.len() as i32 != 2:
            return self.fail(node, "with_str_byte_at takes two arguments")
        let text = arg_values.get(0)
        let index = arg_values.get(1)
        if text.kind != ComptimeValueKind.CV_STR or comptime_value_is_intlike(index) == 0:
            return self.fail(node, "with_str_byte_at expects string and integer arguments")
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_str_byte_at(text.text, comptime_value_intlike(index))))
    if fn_name == "with_str_slice":
        if arg_values.len() as i32 != 3:
            return self.fail(node, "with_str_slice takes three arguments")
        let text = arg_values.get(0)
        let start = arg_values.get(1)
        let end = arg_values.get(2)
        if text.kind != ComptimeValueKind.CV_STR or comptime_value_is_intlike(start) == 0 or comptime_value_is_intlike(end) == 0:
            return self.fail(node, "with_str_slice expects string and integer arguments")
        return comptime_control_value(comptime_value_str(with_str_slice(text.text, comptime_value_intlike(start), comptime_value_intlike(end))))
    if fn_name == "with_str_contains" or fn_name == "with_str_starts_with" or fn_name == "with_str_ends_with":
        if arg_values.len() as i32 != 2:
            return self.fail(node, fn_name ++ " takes two arguments")
        let text = arg_values.get(0)
        let needle = arg_values.get(1)
        if text.kind != ComptimeValueKind.CV_STR or needle.kind != ComptimeValueKind.CV_STR:
            return self.fail(node, fn_name ++ " expects string arguments")
        let result =
            if fn_name == "with_str_contains":
                with_str_contains(text.text, needle.text)
            else if fn_name == "with_str_starts_with":
                with_str_starts_with(text.text, needle.text)
            else:
                with_str_ends_with(text.text, needle.text)
        return comptime_control_value(comptime_value_bool(result))
    if fn_name == "with_sysinfo_os" or fn_name == "with_sysinfo_arch" or fn_name == "with_sysinfo_hostname":
        if arg_values.len() as i32 != 0:
            return self.fail(node, "sysinfo runtime call takes no arguments")
        if fn_name == "with_sysinfo_os":
            return comptime_control_value(comptime_value_str(with_sysinfo_os()))
        if fn_name == "with_sysinfo_arch":
            return comptime_control_value(comptime_value_str(with_sysinfo_arch()))
        return comptime_control_value(comptime_value_str(with_sysinfo_hostname()))
    comptime_control_error()

fn ComptimeEvaluator.eval_fn_symbol_call_values(self: ComptimeEvaluator, fn_sym: i32, arg_values: Vec[ComptimeValue], node: i32) -> ComptimeControl:
    if self.pool.resolve(fn_sym) == "parallel":
        return self.eval_parallel_workspaces_call(arg_values, node)
    let fn_node = self.find_fn_decl_node(fn_sym)
    if fn_node == 0 and self.allow_runtime_calls != 0:
        let runtime_signal = self.eval_allowed_runtime_call(fn_sym, arg_values, node)
        if runtime_signal.kind != ComptimeControlKind.CTL_ERROR or self.had_error != 0:
            return runtime_signal
    if self.allow_runtime_calls == 0 and self.fn_decl_node_is_comptime(fn_node) == 0:
        return self.fail(node, "comptime can only call comptime functions")
    if self.sema.generic_fn_nodes.contains(fn_sym):
        return self.fail(node, "generic comptime functions are not supported yet")
    if fn_node == 0:
        return self.fail(node, "callee '" ++ self.pool.resolve(fn_sym) ++ "' is not a comptime function body")
    if self.active_fn_syms.len() as i32 >= self.recursion_limit:
        return self.fail(node, "comptime recursion limit exceeded")

    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return self.fail(node, "missing comptime function metadata")
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let arg_count = arg_values.len() as i32
    if arg_count > param_count:
        return self.fail(node, "wrong argument count in comptime call")

    let caller_path = self.current_source_path()
    let caller_text = self.current_source_text()
    let caller_fn_sym = if self.active_fn_syms.len() > 0: self.active_fn_syms.get((self.active_fn_syms.len() - 1) as i64) else: 0

    let saved_file = self.sema.local_file_id
    let saved_path = self.sema.current_module_path
    self.sema.local_file_id = self.decl_file_id(fn_node)
    self.sema.current_module_path = self.decl_path(fn_node)
    self.active_fn_syms.push(fn_sym)
    self.push_scope()

    for i in 0..param_count:
        let param_name = self.ast.fn_param_name(param_start, i)
        let param_flags = self.ast.fn_param_flags(param_start, i)
        let param_mut = fn_param_is_mut_self(param_flags)
        if i < arg_count:
            self.bind_value(param_name, arg_values.get(i as i64), param_mut)
        else:
            let default_node = self.ast.get_fn_param_default(param_start, i)
            if default_node == 0:
                self.pop_scope()
                self.active_fn_syms.pop()
                self.sema.local_file_id = saved_file
                self.sema.current_module_path = saved_path
                return self.fail(node, "wrong argument count in comptime call")
            let default_signal = if self.default_arg_uses_call_site(default_node) != 0:
                self.eval_call_site_default_arg(default_node, node, caller_path, caller_text, caller_fn_sym)
            else:
                self.eval_expr(default_node)
            if default_signal.kind != ComptimeControlKind.CTL_VALUE:
                self.pop_scope()
                self.active_fn_syms.pop()
                self.sema.local_file_id = saved_file
                self.sema.current_module_path = saved_path
                return default_signal
            self.bind_value(param_name, default_signal.value, param_mut)

    let pmeta = self.ast.find_fn_param_pattern_meta(fn_node)
    if pmeta >= 0:
        let ppat_start = self.ast.fn_param_pattern_meta_start(pmeta)
        let ppat_count = self.ast.fn_param_pattern_meta_count(pmeta)
        let apply_count = if ppat_count < param_count: ppat_count else: param_count
        for i in 0..apply_count:
            let ppat = self.ast.fn_param_pattern_value(ppat_start + i)
            if ppat != 0:
                let param_name = self.ast.fn_param_name(param_start, i)
                let param_idx = self.lookup_slot_index(param_name)
                if param_idx >= 0:
                    let param_value = self.slot_values.get(param_idx as i64)
                    if self.match_pattern(ppat, param_value, ppat) == 0:
                        self.pop_scope()
                        self.active_fn_syms.pop()
                        self.sema.local_file_id = saved_file
                        self.sema.current_module_path = saved_path
                        return self.fail(ppat, "comptime argument did not match parameter pattern")

    let body_signal = self.eval_expr(self.ast.get_data1(fn_node))
    self.pop_scope()
    self.active_fn_syms.pop()
    self.sema.local_file_id = saved_file
    self.sema.current_module_path = saved_path
    if body_signal.kind == ComptimeControlKind.CTL_RETURN:
        return comptime_control_value(body_signal.value)
    if body_signal.kind == ComptimeControlKind.CTL_BREAK or body_signal.kind == ComptimeControlKind.CTL_CONTINUE:
        return self.fail(fn_node, "loop control escaped comptime function")
    body_signal

fn ComptimeEvaluator.eval_parallel_workspaces_call(self: ComptimeEvaluator, arg_values: Vec[ComptimeValue], node: i32) -> ComptimeControl:
    if arg_values.len() as i32 != 1:
        return self.fail(node, "parallel takes one Vec[Workspace] argument")
    let workspaces = arg_values.get(0)
    if workspaces.kind != ComptimeValueKind.CV_VEC and workspaces.kind != ComptimeValueKind.CV_ARRAY:
        return self.fail(node, "parallel expects a Vec[Workspace]")
    let result_type = self.node_type_or(node, 0)
    if result_type == 0:
        return self.fail(node, "parallel result type is unknown")
    let plans: Vec[ComptimeWorkspaceCompilePlan] = Vec.new()
    let workspace_ids: Vec[i32] = Vec.new()
    let intercepted: Vec[i32] = Vec.new()
    for i in 0..workspaces.extra_count:
        let workspace_value = self.extra_values.get((workspaces.extra_start + i) as i64)
        let workspace_id = self.workspace_record_index(workspace_value, "parallel", node)
        if workspace_id < 0:
            return comptime_control_error()
        let capability_handle = self.validate_capability(workspace_value, CapabilityKind.CK_BUILD_WORKSPACE, "parallel", node)
        if capability_handle < 0:
            return comptime_control_error()
        let record = self.workspace_records.get(workspace_id as i64)
        if record.intercept_active != 0:
            if record.intercept_started != 0 or record.messages.len() > 0 or record.pending_link_active != 0:
                return self.fail(node, "parallel does not support partially consumed intercepted workspaces yet")
        let capability = self.capability_records.get(capability_handle as i64)
        let plan = self.workspace_compile_plan(record, capability, node)
        if plan.valid == 0:
            return comptime_control_error()
        plans.push(plan)
        workspace_ids.push(workspace_id)
        intercepted.push(if record.intercept_active != 0: 1 else: 0)
    let native_results: Vec[ComptimeWorkspaceNativeCompileResult] = Vec.new()
    if plans.len() as i32 == 1:
        native_results.push(comptime_execute_workspace_compile_plan(plans.get(0)))
    else:
        let jobs: Vec[ComptimeWorkspaceThreadJob] = Vec.new()
        let handles: Vec[i64] = Vec.new()
        for i in 0..plans.len() as i32:
            jobs.push(ComptimeWorkspaceThreadJob { plan: plans.get(i as i64), result: comptime_workspace_native_compile_invalid() })
        for i in 0..jobs.len() as i32:
            let job_ptr = (jobs.ptr as *mut ComptimeWorkspaceThreadJob) + i as u64
            let handle = with_thread_spawn(comptime_workspace_thread_entry as *mut u8, job_ptr as *mut u8)
            if handle < 0:
                for hi in 0..handles.len() as i32:
                    let _ = with_thread_join(handles.get(hi as i64))
                return self.fail(node, "parallel failed to spawn workspace thread")
            handles.push(handle)
        var thread_rc = 0
        for hi in 0..handles.len() as i32:
            let rc = with_thread_join(handles.get(hi as i64))
            if rc != 0 and thread_rc == 0:
                thread_rc = rc
        if thread_rc != 0:
            return self.fail(node, "parallel workspace thread failed")
        for i in 0..jobs.len() as i32:
            native_results.push(jobs.get(i as i64).result)
    let results: Vec[ComptimeValue] = Vec.new()
    for i in 0..native_results.len() as i32:
        let plan = plans.get(i as i64)
        let native = native_results.get(i as i64)
        if native.rc != 0:
            with_eprint(f"error: parallel workspace '{plan.name}' failed with exit code {native.rc}\n")
        let result = self.workspace_build_result_value(plan.name, native.rc, self.workspace_artifact_kind_for_output(plan.output_kind), plan.final_output, node)
        if result.kind == ComptimeValueKind.CV_INVALID:
            return comptime_control_error()
        if intercepted.get(i as i64) != 0:
            var record = self.workspace_records.get(workspace_ids.get(i as i64) as i64)
            let messages =
                if native.rc == 0:
                    self.workspace_success_messages(native.comp, native.comp.zcu.last_sema.ast, node)
                else:
                    Vec.new()
            record.intercept_started = 1
            record = self.enqueue_workspace_compile_result(record, result, messages, node)
            if self.had_error != 0:
                return comptime_control_error()
            self.store_workspace_record(workspace_ids.get(i as i64), record)
        results.push(result)
    let start = self.extra_values.len() as i32
    for i in 0..results.len() as i32:
        self.extra_values.push(results.get(i as i64))
    comptime_control_value(comptime_value_vec(result_type, start, workspaces.extra_count))

fn ComptimeEvaluator.eval_return(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let value_node = self.ast.get_data0(node)
    if value_node == 0:
        return comptime_control_return(comptime_value_void(self.sema.ty_void as i32))
    let value_signal = self.eval_expr(value_node)
    if value_signal.kind != ComptimeControlKind.CTL_VALUE:
        return value_signal
    comptime_control_return(value_signal.value)

fn ComptimeEvaluator.eval_break(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let value_node = self.ast.get_data0(node)
    var value = comptime_value_void(self.sema.ty_void as i32)
    if value_node != 0:
        let value_signal = self.eval_expr(value_node)
        if value_signal.kind != ComptimeControlKind.CTL_VALUE:
            return value_signal
        value = value_signal.value
    comptime_control_break(value, self.ast.get_data1(node))

fn ComptimeEvaluator.eval_continue(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    comptime_control_continue(self.ast.get_data0(node))

fn ComptimeEvaluator.eval_block(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let extra_start = self.ast.get_data0(node)
    let stmt_count = self.ast.get_data1(node)
    let tail = self.ast.get_data2(node)
    let block_meta = self.ast.find_block_meta(node)
    let block_label = if block_meta >= 0: self.ast.block_meta_label(block_meta) else: 0
    self.push_scope()
    for i in 0..stmt_count:
        let stmt_signal = self.eval_expr(self.ast.get_extra(extra_start + i))
        if stmt_signal.kind != ComptimeControlKind.CTL_VALUE:
            self.pop_scope()
            if self.signal_matches_block(stmt_signal, block_label) != 0:
                return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
            return stmt_signal
    if tail != 0:
        let tail_signal = self.eval_expr(tail)
        self.pop_scope()
        if self.signal_matches_block(tail_signal, block_label) != 0:
            return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
        return tail_signal
    self.pop_scope()
    comptime_control_value(comptime_value_void(self.sema.ty_void as i32))

fn ComptimeEvaluator.eval_comptime_error(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    let msg_sym = self.ast.get_data0(node)
    self.fail(node, self.pool.resolve(msg_sym))

fn ComptimeEvaluator.eval_expr(self: ComptimeEvaluator, node: i32) -> ComptimeControl:
    if node == 0:
        return comptime_control_value(comptime_value_void(self.sema.ty_void as i32))
    if self.step(node) == 0:
        return comptime_control_error()

    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_INT_LIT:
        let fast = self.ast.int_literal_fast_i64(node as NodeId)
        if fast.ok == 0:
            let exact = self.ast.int_literal_exact_value(node as NodeId)
            if exact.ok == 0 or exact.overflow != 0:
                return self.fail(node, "comptime integer literal too large")
            return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i64 as i32), exact.lo))
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), fast.value))
    if kind == NodeKind.NK_BOOL_LIT:
        return comptime_control_value(comptime_value_bool(self.ast.get_data0(node)))
    if kind == NodeKind.NK_STRING_LIT:
        return comptime_control_value(comptime_value_str(comptime_decode_string_escapes(self.pool.resolve(self.ast.get_data0(node)))))
    if kind == NodeKind.NK_FSTRING:
        return self.eval_fstring(node)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_COMPTIME:
        return self.eval_expr(self.ast.get_data0(node))
    if kind == NodeKind.NK_IDENT:
        return self.eval_ident(node)
    if kind == NodeKind.NK_FIELD_ACCESS:
        return self.eval_field_access(node)
    if kind == NodeKind.NK_INDEX:
        return self.eval_index(node)
    if kind == NodeKind.NK_UNARY:
        return self.eval_unary(node)
    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        return self.unsupported(node)
    if kind == NodeKind.NK_BINARY:
        return self.eval_binary(node)
    if kind == NodeKind.NK_BLOCK:
        return self.eval_block(node)
    if kind == NodeKind.NK_LET_BINDING:
        return self.eval_let_binding(node)
    if kind == NodeKind.NK_ASSIGN:
        return self.eval_assign(node)
    if kind == NodeKind.NK_IF_EXPR:
        return self.eval_if(node)
    if kind == NodeKind.NK_MATCH:
        return self.eval_match(node)
    if kind == NodeKind.NK_FOR:
        return self.eval_for(node)
    if kind == NodeKind.NK_WHILE:
        return self.eval_while(node)
    if kind == NodeKind.NK_DO_WHILE:
        return self.eval_do_while(node)
    if kind == NodeKind.NK_LOOP:
        return self.eval_loop(node)
    if kind == NodeKind.NK_CALL:
        return self.eval_call(node)
    if kind == NodeKind.NK_RETURN:
        return self.eval_return(node)
    if kind == NodeKind.NK_BREAK:
        return self.eval_break(node)
    if kind == NodeKind.NK_CONTINUE:
        return self.eval_continue(node)
    if kind == NodeKind.NK_ARRAY_LIT:
        return self.eval_array(node)
    if kind == NodeKind.NK_TUPLE:
        return self.eval_tuple(node)
    if kind == NodeKind.NK_STRUCT_LIT:
        return self.eval_struct_lit(node)
    if kind == NodeKind.NK_RANGE:
        return self.eval_range(node)
    if kind == NodeKind.NK_PIPELINE:
        return self.eval_pipeline(node)
    if kind == NodeKind.NK_CAST:
        return self.eval_cast(node)
    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        return self.eval_variant_shorthand(node)
    if kind == NodeKind.NK_COMPTIME_ERROR:
        return self.eval_comptime_error(node)
    self.unsupported(node)

fn Sema.force_eval_comptime_expr(mut self: Sema, node: i32) -> i32:
    let value = comptime_force_eval_expr(self as *mut Sema, self.ast, self.pool, node)
    comptime_value_is_valid(value)

fn Sema.check_top_level_comptime_let_values(mut self: Sema):
    if self.diags.has_errors():
        return
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        let value = self.ast.get_data1(decl)
        if value == 0 or self.ast.kind(value) != NodeKind.NK_COMPTIME:
            continue

        let flags = self.ast.get_data2(decl)
        let ann_extra = self.top_level_let_type_ann_extra(flags)
        let ann_type = if ann_extra >= 0: self.resolve_type_expr(self.ast.get_extra(ann_extra)) else: 0 as TypeId
        let val_type = if ann_type != 0: self.check_expr_with_expected(value, ann_type) else: self.check_expr(value)
        if ann_type != 0 and val_type != 0:
            if self.types_compatible(ann_type as i32, val_type as i32) == 0:
                if self.arithmetic_result_type(ann_type, val_type) == 0:
                    self.emit_error("type mismatch in binding", decl)
        if val_type != 0 and ann_type == 0:
            self.typed_binding_types.insert(decl as i32, val_type as i32)
        if self.diags.has_errors():
            return
        let _ = self.force_eval_comptime_expr(value)
        if self.diags.has_errors():
            return
