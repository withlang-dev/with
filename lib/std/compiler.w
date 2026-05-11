// std.compiler — read-only compiler introspection value model.
//
// Compiler hooks receive ProjectInfo values once hook execution is wired into
// the driver. This module defines the stable data shape and query methods.

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
