//! expect-stdout: ok

// Integration test: multi-module usage
// Tests that all self-hosted compiler modules can be imported and used together

use Span
use InternPool
use Diag
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

fn test_all_modules_loadable:
    // Span
    let sp = Span.new(0, 10, 0)
    assert(Span.len(sp) == 10)
    // InternPool
    var ip = InternPool.new()
    let sym = InternPool.intern(ip, "hello")
    assert(sym >= 0)
    assert(InternPool.resolve(ip, sym) == "hello")
    // Diag
    var diag = DiagList.new()
    DiagList.add_error(diag, "test error", 0, 5)
    assert(DiagList.count(diag) == 1)
    // Token
    assert(TK_KW_FN() == 13)
    assert(TK_EOF() == 106)
    // Lexer
    var l = Lexer.new("fn main", 0)
    var tokens = Lexer.tokenize(l)
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FN())
    // Ast
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    assert(AstPool.node_count(pool) == 1)
    // Type
    var types = TypeTable.new()
    assert(TypeTable.lookup(types, "i32") == TYPE_I32())
    // Traits
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Test", 0)
    assert(TraitSolver.trait_count(solver) == 1)
    // Sema
    var intern2 = InternPool.new()
    var pool2 = AstPool.new()
    AstPool.add_node(pool2, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool2, "", intern2)
    assert(s.error_count == 0)
    // Mir
    var body = MirBody.new()
    MirBody.add_local(body, TYPE_I32(), 0)
    assert(MirBody.local_count(body) == 1)
    // Borrow
    var bc = BorrowChecker.new(body, types)
    assert(BorrowChecker.error_count(bc) == 0)
    // Source
    let sf = SourceFile.new("test.w", "hello\n", 0)
    assert(SourceFile.line_count(sf) == 2)
    // CImport
    let cr = process_c_import("")
    assert(CImportResult.decl_count(cr) == 0)
    // render
    assert(node_kind_name(NK_FN_DECL()) == "FnDecl")
    // Driver
    var d = Driver.new(MODE_CHECK(), "test.w")
    assert(d.mode == MODE_CHECK())

fn main:
    test_all_modules_loadable()
    println("ok")
