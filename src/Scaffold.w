// Scaffold — Project scaffold validation utilities.
//
// Validates that all required logical modules exist in the project.

extern fn with_fs_read_file(path: str) -> str

type ModuleSpec {
    logical_name: str,
    file_path: str,
}

fn required_module_count -> i32: 8

fn required_module(idx: i32) -> str:
    if idx == 0: return "ast"
    if idx == 1: return "types"
    if idx == 2: return "parse"
    if idx == 3: return "check"
    if idx == 4: return "mir"
    if idx == 5: return "codegen"
    if idx == 6: return "driver"
    if idx == 7: return "diag"
    ""

fn canonical_module_count -> i32: 8

fn canonical_logical_name(idx: i32) -> str:
    if idx == 0: return "ast"
    if idx == 1: return "types"
    if idx == 2: return "parse"
    if idx == 3: return "check"
    if idx == 4: return "mir"
    if idx == 5: return "codegen"
    if idx == 6: return "driver"
    if idx == 7: return "diag"
    ""

fn canonical_file_path(idx: i32) -> str:
    if idx == 0: return "bootstrap/src/Ast.zig"
    if idx == 1: return "bootstrap/src/Types.zig"
    if idx == 2: return "bootstrap/src/Parse.zig"
    if idx == 3: return "bootstrap/src/Check.zig"
    if idx == 4: return "bootstrap/src/Mir.zig"
    if idx == 5: return "bootstrap/src/Codegen.zig"
    if idx == 6: return "bootstrap/src/Driver.zig"
    if idx == 7: return "bootstrap/src/Diag.zig"
    ""

// Validate error codes
enum ValidateError: i32:
    Ok = 0
    MissingModule = 1
    DuplicateModule = 2

// Validate project scaffold. Returns ValidateError.Ok on success.
fn validate_scaffold(spec_names: Vec[str], spec_paths: Vec[str]) -> i32:
    for ri in 0..required_module_count():
        let req = required_module(ri)
        var count = 0
        for si in 0..spec_names.len() as i32:
            if spec_names.get(si as i64) == req:
                count = count + 1
        if count == 0:
            return ValidateError.MissingModule
        if count > 1:
            return ValidateError.DuplicateModule
    ValidateError.Ok
