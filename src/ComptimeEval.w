use ComptimeValue
use Sema
use Ast
use Span
use Diagnostic
use InternPool
use TypeLayout
use CapabilityRegistry

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
extern fn with_str_starts_with(s: str, prefix: str) -> i32
extern fn with_str_ends_with(s: str, suffix: str) -> i32
extern fn with_str_replace(s: str, old: str, new_s: str) -> str
extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str
extern fn with_sysinfo_hostname() -> str

const COMPTIME_RECURSION_LIMIT: i32 = 256
const COMPTIME_STEP_LIMIT: i32 = 50000
const COMPTIME_TOOL_STEP_LIMIT: i32 = 100000000

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
    target_name: str,
    inputs: Vec[str],
    outputs: Vec[str],
    args: Vec[str],
    write_scope: Vec[str],
    write_scoped: i32,
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
        target_name: "",
        inputs: Vec.new(),
        outputs: Vec.new(),
        args: Vec.new(),
        write_scope: Vec.new(),
        write_scoped: 0,
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

fn comptime_action_capability_record(package_name: str, package_version: str, project_root: str, target_name: str, inputs: Vec[str], output: str, extra_outputs: Vec[str], args: Vec[str], write_scopes: Vec[str]) -> ComptimeCapabilityRecord:
    ComptimeCapabilityRecord {
        kind: CapabilityKind.CK_BUILD_ACTION_CTX,
        generation: 0,
        package_name,
        package_version,
        project_root,
        target_name,
        inputs,
        outputs: comptime_action_outputs(output, extra_outputs),
        args,
        write_scope: comptime_action_write_scope(output, extra_outputs, write_scopes),
        write_scoped: 1,
    }

fn comptime_try_eval_expr_result(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, node: i32) -> ComptimeEvalResult:
    var sema = unsafe: *sema_ptr
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
    var sema = unsafe: *sema_ptr
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
    var sema = unsafe: *sema_ptr
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
    evaluator.restore_runtime_env()
    if evaluator.has_pending_diag != 0:
        sema_ptr.diags.emit(evaluator.pending_diag)
    let value =
        if signal.kind == ComptimeControlKind.CTL_VALUE or signal.kind == ComptimeControlKind.CTL_RETURN:
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

fn comptime_eval_tool_action_result(sema_ptr: *mut Sema, ast: AstPool, pool: InternPool, fn_sym: i32, package_name: str, package_version: str, project_root: str, target_name: str, inputs: Vec[str], output: str, extra_outputs: Vec[str], args_values: Vec[str], write_scopes: Vec[str]) -> ComptimeEvalResult:
    var sema = unsafe: *sema_ptr
    sema.ast = ast
    var evaluator = ComptimeEvaluator.init(sema, ast, pool, 1)
    evaluator.allow_runtime_calls = 1
    evaluator.step_budget = COMPTIME_TOOL_STEP_LIMIT
    let call_node = if ast.decl_count() > 0: ast.get_decl(0) else: 0
    let ctx_type = evaluator.capability_type_id(CapabilityKind.CK_BUILD_ACTION_CTX, call_node)
    if ctx_type == 0:
        return ComptimeEvalResult { value: comptime_value_invalid(), extras: evaluator.extra_values, error_msg: evaluator.last_error_msg, runtime_exit_code: evaluator.runtime_exit_code, runtime_stderr: evaluator.runtime_stderr }
    let ctx_record = comptime_action_capability_record(package_name, package_version, project_root, target_name, inputs, output, extra_outputs, args_values, write_scopes)
    let ctx_value = evaluator.mint_capability(ctx_type, ctx_record)
    let args: Vec[ComptimeValue] = Vec.new()
    args.push(ctx_value)
    let signal = evaluator.eval_fn_symbol_call_values(fn_sym, args, call_node)
    evaluator.restore_runtime_env()
    if evaluator.has_pending_diag != 0:
        sema_ptr.diags.emit(evaluator.pending_diag)
    let value =
        if signal.kind == ComptimeControlKind.CTL_VALUE or signal.kind == ComptimeControlKind.CTL_RETURN:
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
    if recv_signal.value.kind == ComptimeValueKind.CV_VEC:
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
    let saved_start = self.extra_values.len() as i32
    for i in 0..vars.extra_count:
        let item = self.extra_values.get((vars.extra_start + i) as i64)
        let name = self.struct_field_value_by_name(item, "name")
        let env_value = self.struct_field_value_by_name(item, "value")
        if name.kind != ComptimeValueKind.CV_STR or env_value.kind != ComptimeValueKind.CV_STR:
            let _ = self.fail(node, "ProcessEnv vars must contain string name/value fields")
            return comptime_value_invalid()
        self.extra_values.push(comptime_value_str(name.text))
        self.extra_values.push(comptime_value_str(with_getenv_str(name.text) ++ ""))
        let _set = with_setenv_str(name.text, env_value.text)
    comptime_value_vec(env_type, saved_start, vars.extra_count * 2)

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
    comptime_control_value(comptime_value_struct(result_type, start, 3))

fn ComptimeEvaluator.eval_buildctx_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, arg_count: i32, node: i32) -> ComptimeControl:
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

    if method == "exists" or method == "is_dir" or method == "read_text" or method == "list_files" or method == "mkdir_all" or method == "remove_file" or method == "remove_tree":
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
    self.fail(node, "ToolFs capability method '" ++ method ++ "' is not implemented yet")

fn ComptimeEvaluator.eval_process_runner_capability_method(self: ComptimeEvaluator, recv_value: ComptimeValue, method: str, extra_start: i32, arg_count: i32, node: i32) -> ComptimeControl:
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_PROCESS_RUNNER, method, node)
    if handle < 0:
        return comptime_control_error()
    let _record = self.capability_records.get(handle as i64)
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
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_exec_argv(argv) as i64))

    if method == "spawn_capture":
        let stdout_path = self.capability_arg_str(args_signal.value, 1, method, node)
        let stderr_path = self.capability_arg_str(args_signal.value, 2, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        return comptime_control_value(comptime_value_int(self.node_type_or(node, self.sema.ty_i32 as i32), with_exec_argv_capture_spawn(argv, stdout_path, stderr_path) as i64))

    let stdout_path = self.capability_arg_str(args_signal.value, 1, method, node)
    let stderr_path = self.capability_arg_str(args_signal.value, 2, method, node)
    let timeout_ms = self.capability_arg_i32(args_signal.value, 3, method, node)
    if self.had_error != 0:
        return comptime_control_error()

    if method == "run_capture":
        return self.tool_process_result(with_exec_argv_capture(argv, stdout_path, stderr_path, timeout_ms), stdout_path, stderr_path, node)
    if method == "run_capture_cwd":
        let cwd = self.capability_arg_str(args_signal.value, 4, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        return self.tool_process_result(with_exec_argv_capture_cwd(argv, stdout_path, stderr_path, timeout_ms, cwd), stdout_path, stderr_path, node)
    if method == "run_capture_input":
        let stdin_path = self.capability_arg_str(args_signal.value, 4, method, node)
        if self.had_error != 0:
            return comptime_control_error()
        return self.tool_process_result(with_exec_argv_capture_input(argv, stdout_path, stderr_path, timeout_ms, stdin_path), stdout_path, stderr_path, node)
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
    if not self.capability_expect_arg_count(arg_count, 0, method, node):
        return comptime_control_error()
    let handle = self.validate_capability(recv_value, CapabilityKind.CK_BUILD_ACTION_CTX, method, node)
    if handle < 0:
        return comptime_control_error()
    let record = self.capability_records.get(handle as i64)
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
    self.unsupported(node)

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
        if recv_signal.value.kind == ComptimeValueKind.CV_VEC:
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
