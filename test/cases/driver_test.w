//! expect-stdout: ok

use Span
use InternPool
use Token
use Lexer
use Ast
use Types
use Sema
use Mir
use MirLower
use BorrowCfg
use Codegen
use Source
use CImport
use render
use Driver

fn test_source_file:
    let sf = SourceFile.new("test.w", "fn main:\n    42\n", 0)
    assert(SourceFile.line_count(sf) == 3)
    assert(SourceFile.line_at(sf, 0) == 0)
    assert(SourceFile.line_at(sf, 10) == 1)
    assert(SourceFile.col_at(sf, 0) == 0)
    assert(SourceFile.col_at(sf, 14) == 4)
    assert(SourceFile.get_line_text(sf, 0) == "fn main:")
    assert(SourceFile.get_line_text(sf, 1) == "    42")

fn test_c_type_mapping:
    assert(c_type_to_with("int") == "i32")
    assert(c_type_to_with("void") == "void")
    assert(c_type_to_with("double") == "f64")
    assert(c_type_to_with("char") == "i8")
    assert(c_type_to_with("unsigned long") == "u64")

fn test_c_import_result:
    var result = CImportResult.new()
    assert(CImportResult.decl_count(result) == 0)
    let d = CDecl.new_fn("printf", "int", 1, 1)
    result.decls.push(d)
    assert(CImportResult.decl_count(result) == 1)
    let d2 = CImportResult.get_decl(result, 0)
    assert(d2.name == "printf")
    assert(d2.is_variadic == 1)

fn test_render_names:
    assert(node_kind_name(NK_FN_DECL) == "FnDecl")
    assert(node_kind_name(NK_INT_LIT) == "IntLit")
    assert(node_kind_name(NK_BINARY) == "Binary")
    assert(binop_name(OP_ADD) == "+")
    assert(binop_name(OP_EQ) == "==")
    assert(type_kind_name(TK_INT) == "int")
    assert(type_kind_name(TK_STRUCT) == "struct")
    var types = TypeTable.new()
    assert(type_name(types, TYPE_I32) == "i32")
    assert(type_name(types, TYPE_BOOL) == "bool")
    assert(type_name(types, TYPE_STR) == "str")
    assert(stmt_kind_name(SK_ASSIGN) == "Assign")
    assert(stmt_kind_name(SK_DROP) == "Drop")
    assert(terminator_kind_name(TM_RETURN) == "Return")
    assert(terminator_kind_name(TM_GOTO) == "Goto")

fn test_driver_new:
    var d = Driver.new(MODE_RUN, "test.w")
    assert(d.mode == MODE_RUN)
    assert(d.source_path == "test.w")
    assert(Driver.error_count(d) == 0)

fn test_compilation_results:
    assert(CR_OK == 0)
    assert(CR_LEX_ERROR == 1)
    assert(CR_SEMA_ERROR == 3)

fn test_process_c_import:
    let result = process_c_import("#include <stdio.h>")
    assert(CImportResult.decl_count(result) == 0)

fn test_full_pipeline_integration:
    // Test that all modules can be used together
    // Create a simple AST manually and run through sema
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    let body = AstPool.add_node(pool, NK_INT_LIT, 5, 7, 42, 0, 0)
    let name_sym = AstPool.add_string(pool, "main")
    let e0 = AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    let fn_node = AstPool.add_node(pool, NK_FN_DECL, 0, 20, name_sym, body, e0)
    AstPool.add_decl(pool, fn_node)
    // Run sema
    var intern = InternPool.new()
    var sema = Sema.new(pool, "fn main:\n    42\n", intern)
    Sema.check_module(sema)
    // Run MIR lowering
    var types = TypeTable.new()
    var builder = MirBuilder.new(pool, types, "fn main:\n    42\n")
    let mir = MirBuilder.lower_fn(builder, fn_node)
    assert(MirBody.block_count(mir) >= 1)
    // Run borrow check (on empty body, no borrows)
    var bc = BorrowChecker.new(mir, types)
    BorrowChecker.check(bc)
    assert(BorrowChecker.error_count(bc) == 0)
    // Run codegen
    var cg = CodegenState.new(mir, types)
    CodegenState.gen_function(cg)
    assert(CodegenState.inst_count(cg) >= 1)

fn main:
    test_source_file()
    test_c_type_mapping()
    test_c_import_result()
    test_render_names()
    test_driver_new()
    test_compilation_results()
    test_process_c_import()
    test_full_pipeline_integration()
    println("ok")
