//! expect-stdout: ok

// Integration test: full compiler pipeline
// Tests: Lex → Parse → Sema → MIR → Borrow → Codegen on a complete program

use Span
use InternPool
use Token
use Lexer
use Ast
use Type
use Traits
use Sema
use Mir
use MirBuild
use Borrow
use Codegen
use Source
use CImport
use render
use Driver

fn test_lex_parse_sema:
    // Phase 1: Lex a simple function
    let src = "fn main:\n    42\n"
    var l = Lexer.new(src, 0)
    var tokens = Lexer.tokenize(l)
    assert(TokenList.len(tokens) > 0)
    // Phase 2: Parse
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_FN_DECL())
    // Phase 3: Sema
    var intern = InternPool.new()
    var s = Sema.new(p.pool, src, intern)
    let body = AstPool.get_data1(p.pool, decl)
    let t = Sema.check_expr(s, body)
    assert(t == TYPE_I32())

fn test_full_pipeline:
    let src = "fn main:\n    42\n"
    var l = Lexer.new(src, 0)
    var tokens = Lexer.tokenize(l)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    // Sema
    var intern = InternPool.new()
    var sema = Sema.new(p.pool, src, intern)
    // MIR lowering
    var types = TypeTable.new()
    let decl = AstPool.get_decl(p.pool, 0)
    var builder = MirBuilder.new(p.pool, types, src)
    let mir = MirBuilder.lower_fn(builder, decl)
    assert(MirBody.block_count(mir) >= 1)
    // Borrow check
    var bc = BorrowChecker.new(mir, types)
    BorrowChecker.check(bc)
    assert(BorrowChecker.error_count(bc) == 0)
    // Codegen
    var cg = CodegenState.new(mir, types)
    CodegenState.gen_function(cg)
    assert(CodegenState.inst_count(cg) >= 1)

fn test_source_file_integration:
    let src = "fn main:\n    42\n"
    let sf = SourceFile.new("test.w", src, 0)
    assert(SourceFile.line_count(sf) == 3)
    assert(SourceFile.get_line_text(sf, 0) == "fn main:")
    assert(SourceFile.get_line_text(sf, 1) == "    42")

fn test_c_import_integration:
    let result = process_c_import("#include <stdio.h>")
    assert(CImportResult.decl_count(result) == 0)

fn test_render_integration:
    assert(node_kind_name(NK_FN_DECL()) == "FnDecl")
    assert(node_kind_name(NK_INT_LIT()) == "IntLit")
    assert(binop_name(OP_ADD()) == "+")
    assert(type_kind_name(TK_INT()) == "int")

fn test_driver_integration:
    var d = Driver.new(MODE_RUN(), "test.w")
    assert(d.mode == MODE_RUN())
    assert(d.source_path == "test.w")
    assert(Driver.error_count(d) == 0)

fn test_compilation_results:
    assert(CR_OK() == 0)
    assert(CR_LEX_ERROR() == 1)
    assert(CR_PARSE_ERROR() == 2)
    assert(CR_SEMA_ERROR() == 3)
    assert(CR_BORROW_ERROR() == 4)
    assert(CR_CODEGEN_ERROR() == 5)
    assert(CR_LINK_ERROR() == 6)

fn main:
    test_lex_parse_sema()
    test_full_pipeline()
    test_source_file_integration()
    test_c_import_integration()
    test_render_integration()
    test_driver_integration()
    test_compilation_results()
    println("ok")
