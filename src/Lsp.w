// Lsp — Minimal Language Server Protocol server for the With language.
//
// Communicates over stdin/stdout using JSON-RPC 2.0.
// This is a stub in the self-hosted compiler; the full implementation
// requires JSON parsing and TCP/stdio stream handling.
// Direct port of bootstrap/src/Lsp.zig to With.

use std.prelude_core

use Driver
use Source
use Lexer
use Token
use Ast
use Sema
use Diagnostic
use InternPool
use Parser

extern fn with_eprintln(s: str) -> void

type Lsp = {
    documents: HashMap[str, str],
}

fn Lsp.init -> Lsp:
    Lsp {
        documents: HashMap.new(),
    }

fn Lsp.run(self: Lsp) -> i32:
    with_eprintln("LSP server not yet implemented in self-hosted compiler")
    1
