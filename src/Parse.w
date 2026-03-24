// Parse — Facade providing a simplified parsing entry point.
//
// Coordinates lexing and parsing into a single call.

use Ast
use Token
use Lexer
use InternPool
use Parser
use Diagnostic

type ParseResult {
    pool: AstPool,
    intern: InternPool,
    diagnostics: DiagnosticList,
}

fn parse_module(source: str, file_id: i32, intern: InternPool, diagnostics: DiagnosticList) -> ParseResult:
    var lexer = Lexer.init(source, file_id)
    let tokens = lexer.tokenize()
    var parser = Parser.init(tokens, source, file_id, intern, diagnostics)
    let pool = parser.parse_module()
    ParseResult { pool, intern: parser.intern, diagnostics: parser.diags }

fn parse_source(source: str) -> AstPool:
    let result = parse_module(source, 0, InternPool.init(), DiagnosticList.init())
    result.pool
