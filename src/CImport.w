// CImport — C header import via libclang.
//
// Parses C header code and generates synthetic extern fn declarations.
// In the self-hosted compiler, this calls into libclang via extern functions.

use Ast
use InternPool
use Span

extern fn int_to_string(n: i32) -> str

// Opaque libclang handles
extern fn clang_createIndex(exclude_decls: i32, display_diags: i32) -> i32
extern fn clang_disposeIndex(idx: i32) -> void
extern fn clang_parseTranslationUnit_simple(idx: i32, source: str) -> i32
extern fn clang_disposeTranslationUnit(tu: i32) -> void
extern fn clang_getNumFunctions(tu: i32) -> i32
extern fn clang_getFunctionName(tu: i32, index: i32) -> str
extern fn clang_getFunctionReturnType(tu: i32, index: i32) -> str
extern fn clang_getFunctionParamCount(tu: i32, index: i32) -> i32
extern fn clang_getFunctionParamName(tu: i32, fn_idx: i32, param_idx: i32) -> str
extern fn clang_getFunctionParamType(tu: i32, fn_idx: i32, param_idx: i32) -> str
extern fn clang_isFunctionVariadic(tu: i32, index: i32) -> i32

// Process a c_import header string and return synthetic extern fn nodes in pool.
// Returns the number of declarations added.
// Note: In the bootstrap compiler this uses libclang directly. Here we provide
// the same interface but the actual C interop happens via the runtime bridge.
fn process_c_import(header_code: str, pool: AstPool, intern: InternPool) -> i32:
    // This is a stub - the actual implementation requires libclang bindings
    // which are provided by the runtime when available.
    0

// Map a C type name string to a With type name.
fn map_c_type(name: str) -> str:
    if name == "void": return "void"
    if name == "_Bool": return "bool"
    if name == "char": return "i8"
    if name == "signed char": return "i8"
    if name == "unsigned char": return "u8"
    if name == "short": return "i16"
    if name == "unsigned short": return "u16"
    if name == "int": return "i32"
    if name == "unsigned int": return "u32"
    if name == "long": return "i64"
    if name == "unsigned long": return "u64"
    if name == "long long": return "i64"
    if name == "unsigned long long": return "u64"
    if name == "float": return "f32"
    if name == "double": return "f64"
    if name == "long double": return "f64"
    // Default: treat as opaque pointer
    "i32"
