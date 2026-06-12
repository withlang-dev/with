// std.compiler — compiler-hook introspection and tool capabilities.

extern fn with_getenv_str(name: str) -> str
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_eprint(s: str) -> Unit
extern fn exit(code: i32) -> Unit

pub enum CompilerHookPhase: i32:
    after_typecheck = 0

pub enum DeclKind: i32:
    function = 0
    type_decl = 1

pub type SourceLocation {
    file: str,
    start: i32,
    end: i32,
}

pub type ModuleInfo {
    name: str,
    path: str,
}

pub type FunctionInfo {
    module_name: str,
    name: str,
    public_value: bool,
    docs_value: bool,
    param_count: i32,
    return_type: str,
    source_location: SourceLocation,
}

pub type TypeInfo {
    module_name: str,
    name: str,
    public_value: bool,
    docs_value: bool,
    kind: str,
    source_location: SourceLocation,
}

pub type ProjectInfo {
    module_items: Vec[ModuleInfo],
    function_items: Vec[FunctionInfo],
    type_items: Vec[TypeInfo],
}

pub type Diagnostics {
    token: str,
    output_path: str,
}

pub type SourceEmitter {
    token: str,
    output_path: str,
}

fn compiler_hook_escape(value: str) -> str:
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

fn compiler_capability_valid(token: str) -> bool:
    let expected = with_getenv_str("WITH_TOOL_CAPABILITY_TOKEN")
    expected.len() > 0 and token == expected

fn compiler_capability_require(token: str, name: str):
    if not compiler_capability_valid(token):
        with_eprint("error: invalid compiler hook capability: " ++ name)
        exit(1)

pub fn Diagnostics.__driver_new(token: str, output_path: str) -> Diagnostics:
    compiler_capability_require(token, "Diagnostics")
    Diagnostics { token, output_path }

pub fn SourceEmitter.__driver_new(token: str, output_path: str) -> SourceEmitter:
    compiler_capability_require(token, "SourceEmitter")
    SourceEmitter { token, output_path }

pub fn Diagnostics.error(self: &Self, location: SourceLocation, message: str) -> Unit:
    compiler_capability_require(self.token, "Diagnostics")
    if self.output_path.len() == 0:
        with_eprint("error: Diagnostics.error called without a driver diagnostic output")
        exit(1)
        return
    let old = with_fs_read_file(self.output_path)
    let line = "error\t" ++
        compiler_hook_escape(location.file) ++ "\t" ++
        f"{location.start}" ++ "\t" ++
        f"{location.end}" ++ "\t" ++
        compiler_hook_escape(message) ++ "\n"
    if with_fs_write_file(self.output_path, old ++ line) != 0:
        with_eprint("error: failed to write compiler hook diagnostic")
        exit(1)

pub fn SourceEmitter.emit_source(self: &Self, source: str) -> Unit:
    compiler_capability_require(self.token, "SourceEmitter")
    if self.output_path.len() == 0:
        with_eprint("error: SourceEmitter.emit_source called without a driver emitted-source output")
        exit(1)
        return
    let old = with_fs_read_file(self.output_path)
    if with_fs_write_file(self.output_path, old ++ "\n" ++ source ++ "\n") != 0:
        with_eprint("error: failed to write compiler hook emitted source")
        exit(1)

pub fn SourceLocation.new(file: str, start: i32, end: i32) -> SourceLocation:
    SourceLocation { file, start, end }

pub fn ModuleInfo.new(name: str, path: str) -> ModuleInfo:
    ModuleInfo { name, path }

pub fn FunctionInfo.new(module_name: str, name: str, public_value: bool, docs_value: bool, param_count: i32, return_type: str, source_location: SourceLocation) -> FunctionInfo:
    FunctionInfo { module_name, name, public_value, docs_value, param_count, return_type, source_location }

pub fn FunctionInfo.is_pub(self: &Self) -> bool:
    self.public_value

pub fn FunctionInfo.has_docs(self: &Self) -> bool:
    self.docs_value

pub fn FunctionInfo.location(self: &Self) -> SourceLocation:
    self.source_location

pub fn TypeInfo.new(module_name: str, name: str, public_value: bool, docs_value: bool, kind: str, source_location: SourceLocation) -> TypeInfo:
    TypeInfo { module_name, name, public_value, docs_value, kind, source_location }

pub fn TypeInfo.is_pub(self: &Self) -> bool:
    self.public_value

pub fn TypeInfo.has_docs(self: &Self) -> bool:
    self.docs_value

pub fn TypeInfo.location(self: &Self) -> SourceLocation:
    self.source_location

pub fn ProjectInfo.new() -> ProjectInfo:
    ProjectInfo {
        module_items: Vec.new(),
        function_items: Vec.new(),
        type_items: Vec.new(),
    }

pub fn ProjectInfo.add_module(mut self: ProjectInfo, module_info: ModuleInfo) -> ProjectInfo:
    self.module_items.push(module_info)
    self

pub fn ProjectInfo.add_function(mut self: ProjectInfo, function: FunctionInfo) -> ProjectInfo:
    self.function_items.push(function)
    self

pub fn ProjectInfo.add_type(mut self: ProjectInfo, type_info: TypeInfo) -> ProjectInfo:
    self.type_items.push(type_info)
    self

pub fn ProjectInfo.modules(self: &Self) -> Vec[ModuleInfo]:
    self.module_items

pub fn ProjectInfo.functions(self: &Self) -> Vec[FunctionInfo]:
    self.function_items

pub fn ProjectInfo.types(self: &Self) -> Vec[TypeInfo]:
    self.type_items
