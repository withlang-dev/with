// CImport — libclang FFI for c_import declarations.
//
// Handles `use c_import("#include <header.h>")` by invoking
// libclang to parse C headers and extract extern function
// declarations into the AST.
//
// In the self-hosted compiler, this uses c_import itself to
// access the libclang API. For now, this module provides the
// interface and data structures; actual clang integration
// requires the LLVM/Clang libraries to be available.
//
// Ref: bootstrap/CImport.zig

use Ast

// ── C declaration types ──────────────────────────────────────────────

fn CD_FUNCTION() -> i32: 0
fn CD_TYPEDEF() -> i32: 1
fn CD_STRUCT() -> i32: 2
fn CD_ENUM() -> i32: 3
fn CD_MACRO() -> i32: 4

// ── Extracted C declaration ──────────────────────────────────────────

type CDecl = {
    kind: i32,
    name: str,
    return_type: str,
    param_count: i32,
    param_names_start: i32,
    param_types_start: i32,
    is_variadic: i32,
}

fn CDecl.new_fn(name: str, return_type: str, param_count: i32, is_variadic: i32) -> CDecl:
    CDecl {
        kind: CD_FUNCTION(),
        name: name,
        return_type: return_type,
        param_count: param_count,
        param_names_start: 0,
        param_types_start: 0,
        is_variadic: is_variadic,
    }

// ── C Import result ──────────────────────────────────────────────────

type CImportResult = {
    decls: Vec[CDecl],
    param_names: Vec[str],
    param_types: Vec[str],
    errors: Vec[str],
}

fn CImportResult.new() -> CImportResult:
    CImportResult {
        decls: Vec.new(),
        param_names: Vec.new(),
        param_types: Vec.new(),
        errors: Vec.new(),
    }

fn CImportResult.decl_count(self: CImportResult) -> i32:
    self.decls.len() as i32

fn CImportResult.get_decl(self: CImportResult, idx: i32) -> CDecl:
    self.decls.get(idx as i64)

fn CImportResult.error_count(self: CImportResult) -> i32:
    self.errors.len() as i32

// ── C type mapping ───────────────────────────────────────────────────
// Map C type names to With type names.

fn c_type_to_with(c_type: str) -> str:
    if c_type == "void" then "void"
    else if c_type == "int" then "i32"
    else if c_type == "unsigned int" then "u32"
    else if c_type == "long" then "i64"
    else if c_type == "unsigned long" then "u64"
    else if c_type == "long long" then "i64"
    else if c_type == "unsigned long long" then "u64"
    else if c_type == "short" then "i16"
    else if c_type == "unsigned short" then "u16"
    else if c_type == "char" then "i8"
    else if c_type == "unsigned char" then "u8"
    else if c_type == "float" then "f32"
    else if c_type == "double" then "f64"
    else if c_type == "size_t" then "u64"
    else if c_type == "ssize_t" then "i64"
    else if c_type == "bool" then "bool"
    else if c_type == "_Bool" then "bool"
    else "i32"

// ── Stub: Process a c_import header string ───────────────────────────
// This is a placeholder. The real implementation would:
//   1. Write the header content to a temp file
//   2. Call libclang to parse it
//   3. Walk the AST to extract function declarations
//   4. Convert C types to With types
//   5. Return CImportResult with extracted declarations

fn process_c_import(header_content: str) -> CImportResult:
    var result = CImportResult.new()
    // In a full implementation, this would invoke libclang.
    // For now, we return an empty result.
    result

// ── Inject extracted declarations into AST ───────────────────────────

fn inject_c_decls(pool: AstPool, result: CImportResult) -> void:
    let count = CImportResult.decl_count(result)
    var i = 0
    while i < count:
        let decl = CImportResult.get_decl(result, i)
        if decl.kind == CD_FUNCTION():
            // Create an NK_EXTERN_FN node
            let name_sym = AstPool.add_string(pool, decl.name)
            let node = AstPool.add_node(pool, NK_EXTERN_FN(), 0, 0, name_sym, 0, decl.is_variadic)
            AstPool.add_decl(pool, node)
        i = i + 1
