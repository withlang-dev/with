// Parser — Recursive descent parser: tokens -> AST.
//
// Consumes a TokenList and produces nodes in an AstPool.
// On parse errors, emits a diagnostic and recovers to next top-level decl.

use Ast
use Token
use Span
use Lexer
use InternPool
use Diagnostic

extern fn with_parse_i64(s: str) -> i64
extern fn str_from_byte(b: i32) -> str
type Parser {
    tokens: TokenList,
    pos: i32,
    pool: AstPool,
    intern: InternPool,
    diags: DiagnosticList,
    source: str,
    file_id: i32,
    suppress_as: i32,
    suppress_brace: i32,
    pending_tailrec: i32,
    pending_inline: i32,
    pending_noinline: i32,
    pending_must_use: i32,
    pending_panic_handler: i32,
    pending_entry: i32,
    pending_no_main: i32,
    pending_test: i32,
    pending_before: i32,
    pending_after: i32,
    pending_bench: i32,
    pending_derive_start: i32,
    pending_derive_count: i32,
    pending_sealed: i32,
    pending_flags: i32,
    pending_packed: i32,
    pending_bitpacked: i32,
    pending_weak: i32,
    pending_callconv: i32,
    pending_stack_size: i32,
    pending_unsafe_fn: i32,
    pending_iter_of_self: i32,
    saw_implicit_it: i32,
    implicit_it_depth: i32,
    last_param_pattern_start: i32,
    last_param_pattern_count: i32,
    last_param_required_count: i32,
    last_where_start: i32,
    last_where_count: i32,
    if_chain_form: i32,
    suppress_fat_arrow_closure: i32,
}

type InterpolatedExprParseAttempt {
    node: NodeId,
    consumed_all: i32,
    had_errors: i32,
    pool: AstPool,
    intern: InternPool,
}

fn Parser.init(tokens: TokenList, source: str, file_id: i32, intern: InternPool, diags: DiagnosticList) -> Parser:
    Parser.init_with_pool(tokens, source, file_id, intern, diags, AstPool.new())

fn Parser.init_with_pool(tokens: TokenList, source: str, file_id: i32, intern: InternPool, diags: DiagnosticList, pool: AstPool) -> Parser:
    Parser {
        tokens,
        pos: 0,
        pool,
        intern,
        diags,
        source,
        file_id,
        suppress_as: 0,
        suppress_brace: 0,
        pending_tailrec: 0,
        pending_inline: 0,
        pending_noinline: 0,
        pending_must_use: 0,
        pending_panic_handler: 0,
        pending_entry: 0,
        pending_no_main: 0,
        pending_test: 0,
        pending_before: 0,
        pending_after: 0,
        pending_bench: 0,
        pending_derive_start: 0,
        pending_derive_count: 0,
        pending_sealed: 0,
        pending_flags: 0,
        pending_packed: 0,
        pending_bitpacked: 0,
        pending_weak: 0,
        pending_callconv: 0,
        pending_stack_size: 0,
        pending_unsafe_fn: 0,
        pending_iter_of_self: 0,
        saw_implicit_it: 0,
        implicit_it_depth: 0,
        last_param_pattern_start: 0,
        last_param_pattern_count: 0,
        last_param_required_count: 0,
        last_where_start: 0,
        last_where_count: 0,
        if_chain_form: 0,
        suppress_fat_arrow_closure: 0,
    }

// ── Token helpers ────────────────────────────────────────────────

fn Parser.peek(self: Parser) -> i32:
    if self.pos >= self.tokens.len():
        return TokenKind.TK_EOF
    self.tokens.get_tag(self.pos)

fn Parser.advance(self: Parser):
    if self.pos < self.tokens.len():
        self.pos = self.pos + 1

fn Parser.current_start(self: Parser) -> i32:
    if self.pos >= self.tokens.len():
        return 0
    self.tokens.get_start(self.pos)

fn Parser.current_end(self: Parser) -> i32:
    if self.pos >= self.tokens.len():
        return 0
    self.tokens.get_end(self.pos)

fn Parser.prev_start(self: Parser) -> i32:
    if self.pos == 0:
        return 0
    self.tokens.get_start(self.pos - 1)

fn Parser.prev_end(self: Parser) -> i32:
    if self.pos == 0:
        return 0
    self.tokens.get_end(self.pos - 1)

fn Parser.expect(self: Parser, expected: i32) -> i32:
    if self.peek() != expected:
        self.emit_error("expected " ++ tag_name(expected))
        return 0
    self.advance()
    1

fn Parser.expect_ident(self: Parser) -> i32:
    if self.peek() != TokenKind.TK_IDENT:
        self.emit_error("expected identifier")
        return 0
    let sym = self.intern_current()
    self.advance()
    sym

fn Parser.expect_ident_or_keyword(self: Parser) -> i32:
    let t = self.peek()
    if t == TokenKind.TK_IDENT or parser_is_keyword_tag(t):
        let sym = self.intern_current()
        self.advance()
        return sym
    self.emit_error("expected identifier")
    0

fn parser_is_keyword_tag(tag: i32) -> bool:
    if tag >= TokenKind.TK_KW_FN and tag <= TokenKind.TK_KW_OR:
        return true
    if tag == TokenKind.TK_KW_CONST or tag == TokenKind.TK_KW_IT or tag == TokenKind.TK_KW_ERRDEFER or tag == TokenKind.TK_KW_MOVE:
        return true
    if tag == TokenKind.TK_KW_WHERE or tag == TokenKind.TK_KW_OPAQUE or tag == TokenKind.TK_KW_NULL or tag == TokenKind.TK_KW_UNION or tag == TokenKind.TK_KW_ENUM or tag == TokenKind.TK_KW_GOTO:
        return true
    false

fn Parser.emit_help_error(self: Parser, msg: str, help: str):
    let span = Span { file: self.file_id, start: self.current_start(), end: self.current_end() }
    var diag = Diagnostic.err(msg, span)
    diag.add_help(help)
    self.diags.emit(diag)

fn Parser.expect_use_path_segment(self: Parser) -> i32:
    let t = self.peek()
    if t == TokenKind.TK_IDENT:
        let sym = self.intern_current()
        self.advance()
        return sym
    if parser_is_keyword_tag(t):
        let sym = self.intern_current()
        let keyword = self.intern.resolve(sym)
        let span = Span { file: self.file_id, start: self.current_start(), end: self.current_end() }
        var diag = Diagnostic.err("'" ++ keyword ++ "' is a reserved keyword and cannot be used as a module name", span)
        diag.add_help("rename the module to avoid the keyword, e.g. '" ++ keyword ++ "s'")
        self.diags.emit(diag)
        return 0
    self.emit_error("expected identifier")
    0

fn Parser.intern_current(self: Parser) -> i32:
    let s = self.current_start()
    let e = self.current_end()
    let text = self.source.slice(s as i64, e as i64)
    self.intern.intern(text)

fn Parser.is_ident_named(self: Parser, name: str) -> bool:
    if self.peek() != TokenKind.TK_IDENT:
        return false
    let s = self.current_start()
    let e = self.current_end()
    self.source.slice(s as i64, e as i64) == name

fn Parser.skip_newlines(self: Parser):
    while self.peek() == TokenKind.TK_NEWLINE:
        self.advance()

fn Parser.skip_separators(self: Parser):
    while self.peek() == TokenKind.TK_NEWLINE or self.peek() == TokenKind.TK_SEMICOLON:
        self.advance()

fn Parser.peek_past_newlines(self: Parser) -> i32:
    var p = self.pos
    while p < self.tokens.len() and self.tokens.get_tag(p) == TokenKind.TK_NEWLINE:
        p = p + 1
    if p < self.tokens.len():
        return self.tokens.get_tag(p)
    TokenKind.TK_EOF

fn Parser.peek_past_separators(self: Parser) -> i32:
    var p = self.pos
    while p < self.tokens.len() and (self.tokens.get_tag(p) == TokenKind.TK_NEWLINE or self.tokens.get_tag(p) == TokenKind.TK_SEMICOLON):
        p = p + 1
    if p < self.tokens.len():
        return self.tokens.get_tag(p)
    TokenKind.TK_EOF

fn Parser.emit_error(self: Parser, msg: str):
    let span = Span { file: self.file_id, start: self.current_start(), end: self.current_end() }
    self.diags.emit(Diagnostic.err(msg, span))

fn Parser.poisoned_expr(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    self.pool.add_node(NodeKind.NK_POISONED_EXPR, start, end, 0, 0, 0)

fn Parser.poisoned_decl(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    self.pool.add_node(NodeKind.NK_POISONED_DECL, start, end, 0, 0, 0)

fn Parser.recover_to_statement(self: Parser):
    // Skip tokens until we reach a new line that could start a statement.
    // In an indentation-based language, this means a line at the same or
    // lower indentation level, or a statement keyword.
    let src = self.source
    let slen = src.len() as i32
    while self.peek() != TokenKind.TK_EOF:
        let t = self.peek()
        let tok_start = self.current_start()
        // Statement keywords are safe sync points
        if t == TokenKind.TK_KW_LET or t == TokenKind.TK_KW_VAR or
           t == TokenKind.TK_KW_RETURN or t == TokenKind.TK_KW_IF or
           t == TokenKind.TK_KW_FOR or t == TokenKind.TK_KW_WHILE or
           t == TokenKind.TK_KW_MATCH or t == TokenKind.TK_KW_BREAK or
           t == TokenKind.TK_KW_CONTINUE or t == TokenKind.TK_KW_GOTO or
           t == TokenKind.TK_LABEL or t == TokenKind.TK_KW_DEFER:
            // Check this is at the start of a line (preceded by newline or BOF)
            if tok_start == 0:
                return
            if tok_start > 0 and tok_start < slen:
                // Walk backward to check we're at line start (only whitespace before us on this line)
                var ci = tok_start - 1
                var at_line_start = false
                while ci >= 0:
                    let ch = src.byte_at(ci as i64)
                    if ch == 10:
                        at_line_start = true
                        break
                    if ch != 32 and ch != 9:
                        break
                    ci = ci - 1
                if at_line_start or ci < 0:
                    return
        // Top-level declarations are also sync points
        if t == TokenKind.TK_KW_FN or t == TokenKind.TK_KW_TYPE or
           t == TokenKind.TK_KW_ENUM or t == TokenKind.TK_KW_USE or
           t == TokenKind.TK_KW_PUB or t == TokenKind.TK_KW_EXTERN or
           t == TokenKind.TK_KW_TRAIT or t == TokenKind.TK_KW_IMPL or
           t == TokenKind.TK_KW_EXTEND or t == TokenKind.TK_KW_ERROR:
            return
        self.advance()

fn Parser.recover_to_top_level(self: Parser):
    while self.peek() != TokenKind.TK_EOF:
        let t = self.peek()
        if t == TokenKind.TK_AT or
           t == TokenKind.TK_KW_FN or t == TokenKind.TK_KW_TYPE or t == TokenKind.TK_KW_ENUM or t == TokenKind.TK_KW_USE or t == TokenKind.TK_KW_LET or
           t == TokenKind.TK_KW_VAR or t == TokenKind.TK_KW_PUB or t == TokenKind.TK_KW_EXTERN or t == TokenKind.TK_KW_ERROR or
           t == TokenKind.TK_KW_TRAIT or t == TokenKind.TK_KW_IMPL or t == TokenKind.TK_KW_EXTEND or t == TokenKind.TK_KW_ASYNC or
           t == TokenKind.TK_KW_GEN or t == TokenKind.TK_KW_COMPTIME:
            return
        self.advance()

// ── Attribute parsing ────────────────────────────────────────────

fn Parser.skip_attributes(self: Parser):
    self.pending_derive_start = 0
    self.pending_derive_count = 0
    self.pending_tailrec = 0
    self.pending_inline = 0
    self.pending_noinline = 0
    self.pending_must_use = 0
    self.pending_panic_handler = 0
    self.pending_entry = 0
    self.pending_no_main = 0
    self.pending_test = 0
    self.pending_before = 0
    self.pending_after = 0
    self.pending_bench = 0
    self.pending_sealed = 0
    self.pending_flags = 0
    self.pending_packed = 0
    self.pending_bitpacked = 0
    self.pending_weak = 0
    self.pending_callconv = 0
    self.pending_stack_size = 0
    self.pending_iter_of_self = 0
    var derive_syms: Vec[i32] = Vec.new()

    while self.peek() == TokenKind.TK_AT:
        let saved = self.pos
        self.advance()
        if self.peek() != TokenKind.TK_L_BRACKET:
            self.emit_error("expected '[' after '@' for attribute (use 'label for loop labels)")
            return
        self.advance()

        // Check for must_use and flags BEFORE the else-if chain
        if self.peek() == TokenKind.TK_IDENT:
            let attr_s = self.current_start()
            let attr_e = self.current_end()
            let attr_text = self.source.slice(attr_s as i64, attr_e as i64)
            if attr_text == "must_use":
                self.pending_must_use = 1
            if attr_text == "flags":
                self.pending_flags = 1
            if attr_text == "sealed":
                self.pending_sealed = 1
            if attr_text == "packed":
                self.pending_packed = 1
            if attr_text == "bitpacked":
                self.pending_bitpacked = 1
            if attr_text == "weak":
                self.pending_weak = 1

        if self.is_ident_named("derive"):
            self.advance()
            if self.peek() == TokenKind.TK_L_PAREN:
                self.advance()
                while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    if self.peek() == TokenKind.TK_IDENT:
                        let sym = self.intern_current()
                        self.advance()
                        derive_syms.push(sym)
                    else:
                        self.advance()
                    if self.peek() == TokenKind.TK_COMMA:
                        self.advance()
                        self.skip_newlines()
                if self.peek() == TokenKind.TK_R_PAREN:
                    self.advance()
        else if self.is_ident_named("tailrec"):
            self.pending_tailrec = 1
            self.advance()
        else if self.is_ident_named("iter_of_self"):
            self.pending_iter_of_self = 1
            self.advance()
        else if self.is_ident_named("inline"):
            self.pending_inline = 1
            self.advance()
        else if self.is_ident_named("noinline"):
            self.pending_noinline = 1
            self.advance()
        else if self.is_ident_named("must_use"):
            // Already handled by standalone check above
            self.advance()
        else if self.is_ident_named("panic_handler"):
            self.pending_panic_handler = 1
            self.advance()
        else if self.is_ident_named("entry"):
            self.pending_entry = 1
            self.advance()
        else if self.is_ident_named("no_main"):
            self.pending_no_main = 1
            self.advance()
        else if self.is_ident_named("test"):
            self.pending_test = 1
            self.advance()
        else if self.is_ident_named("before"):
            self.pending_before = 1
            self.advance()
        else if self.is_ident_named("after"):
            self.pending_after = 1
            self.advance()
        else if self.is_ident_named("bench"):
            self.pending_bench = 1
            self.advance()
        else if self.is_ident_named("sealed"):
            // Already handled by standalone check above
            self.advance()
        else if self.is_ident_named("flags"):
            // Already handled by standalone check above
            self.advance()
        else if self.is_ident_named("c_export"):
            // @[c_export("name")] — parse and store the export name as callconv
            // with "c_export:" prefix so codegen can detect it
            self.advance()
            if self.peek() == TokenKind.TK_L_PAREN:
                self.advance()
                if self.peek() == TokenKind.TK_STRING_LIT:
                    let export_name = self.source.slice((self.current_start() + 1) as i64, (self.current_end() - 1) as i64)
                    self.pending_callconv = self.intern.intern("c_export:" ++ export_name)
                    self.advance()
                if self.peek() == TokenKind.TK_R_PAREN:
                    self.advance()
        else if self.is_ident_named("callconv"):
            self.advance()
            if self.peek() == TokenKind.TK_L_PAREN:
                self.advance()
                if self.peek() == TokenKind.TK_STRING_LIT:
                    let cc_name = self.source.slice((self.current_start() + 1) as i64, (self.current_end() - 1) as i64)
                    self.pending_callconv = self.intern.intern(cc_name)
                    self.advance()
                if self.peek() == TokenKind.TK_R_PAREN:
                    self.advance()
        else if self.is_ident_named("stack_size"):
            self.advance()
            if self.peek() == TokenKind.TK_L_PAREN:
                self.advance()
                if self.peek() == TokenKind.TK_INT_LIT:
                    let val_s = self.current_start()
                    let val_e = self.current_end()
                    let val_text = self.source.slice(val_s as i64, val_e as i64)
                    self.pending_stack_size = parse_int(val_text) as i32
                    self.advance()
                if self.peek() == TokenKind.TK_R_PAREN:
                    self.advance()

        // consume until matching ]
        var depth = 1
        while depth > 0 and self.peek() != TokenKind.TK_EOF:
            if self.peek() == TokenKind.TK_L_BRACKET:
                depth = depth + 1
            if self.peek() == TokenKind.TK_R_BRACKET:
                depth = depth - 1
            self.advance()
        self.skip_newlines()

    // Store derive traits in extra array
    if derive_syms.len() > 0:
        self.pending_derive_start = self.pool.extra_len()
        self.pending_derive_count = derive_syms.len() as i32
        for i in 0..derive_syms.len() as i32:
            self.pool.add_extra(derive_syms.get(i as i64))

// ── Module parsing ───────────────────────────────────────────────

fn Parser.parse_module(self: Parser) -> AstPool:
    self.skip_separators()

    // Skip optional module declaration
    if self.peek() == TokenKind.TK_KW_MODULE:
        self.advance()
        if self.peek() == TokenKind.TK_IDENT or self.peek() == TokenKind.TK_DOT_IDENT:
            self.advance()
        while true:
            if self.peek() == TokenKind.TK_DOT:
                self.advance()
                if self.peek() == TokenKind.TK_IDENT:
                    self.advance()
                else:
                    break
            else if self.peek() == TokenKind.TK_DOT_IDENT:
                // .Uppercase segments are lexed as dot-identifiers.
                self.advance()
            else:
                break
        self.skip_separators()

    while self.peek() != TokenKind.TK_EOF:
        self.skip_separators()
        self.skip_attributes()
        self.skip_separators()
        if self.peek() == TokenKind.TK_EOF:
            break

        if self.peek() == TokenKind.TK_KW_PUB:
            let saved_pos = self.pos
            self.advance()
            if self.peek() == TokenKind.TK_KW_IMPL or self.peek() == TokenKind.TK_KW_EXTEND:
                self.parse_impl_block(Visibility.Public)
                self.skip_separators()
                continue
            if self.peek() == TokenKind.TK_KW_TRAIT:
                self.parse_trait_decl(Visibility.Public)
                self.skip_separators()
                continue
            self.pos = saved_pos
        else if self.peek() == TokenKind.TK_KW_IMPL or self.peek() == TokenKind.TK_KW_EXTEND:
            self.parse_impl_block(Visibility.Private)
            self.skip_separators()
            continue
        else if self.peek() == TokenKind.TK_KW_TRAIT:
            self.parse_trait_decl(Visibility.Private)
            self.skip_separators()
            continue
        else if self.peek() == TokenKind.TK_KW_COMPTIME:
            if self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) == TokenKind.TK_COLON:
                self.parse_comptime_decl_block()
                self.skip_separators()
                continue

        let decl = self.parse_decl()
        if decl != 0:
            self.pool.add_decl(decl)
        else:
            self.recover_to_top_level()
        self.skip_separators()

    self.pool

// ── Declaration parsing ──────────────────────────────────────────

fn Parser.parse_decl(self: Parser) -> NodeId:
    var is_pub = Visibility.Private
    let start = self.current_start()

    if self.peek() == TokenKind.TK_KW_PUB:
        is_pub = Visibility.Public
        self.advance()

    if self.peek() != TokenKind.TK_KW_TYPE and self.peek() != TokenKind.TK_KW_ENUM:
        self.pending_derive_start = 0
        self.pending_derive_count = 0

    let t = self.peek()
    if t == TokenKind.TK_KW_FN:
        return self.parse_fn_decl(is_pub, start, 0, 0, 0)
    if t == TokenKind.TK_KW_UNSAFE:
        self.advance()
        if self.peek() != TokenKind.TK_KW_FN:
            self.emit_error("expected 'fn' after 'unsafe'")
            return self.poisoned_expr()
        self.pending_unsafe_fn = 1
        let result = self.parse_fn_decl(is_pub, start, 0, 0, 0)
        self.pending_unsafe_fn = 0
        return result
    if t == TokenKind.TK_KW_COMPTIME:
        self.advance()
        if self.peek() != TokenKind.TK_KW_FN:
            self.emit_error("expected 'fn' after 'comptime'")
            return self.poisoned_expr()
        return self.parse_fn_decl(is_pub, start, 0, 0, 1)
    if t == TokenKind.TK_KW_ASYNC:
        self.advance()
        return self.parse_fn_decl(is_pub, start, 1, 0, 0)
    if t == TokenKind.TK_KW_GEN:
        self.advance()
        return self.parse_fn_decl(is_pub, start, 0, 1, 0)
    if t == TokenKind.TK_KW_TYPE:
        return self.parse_type_decl(is_pub, start)
    if t == TokenKind.TK_KW_ENUM:
        return self.parse_enum_decl(is_pub, start)
    if t == TokenKind.TK_KW_USE:
        return self.parse_use_decl(start)
    if t == TokenKind.TK_KW_LET or t == TokenKind.TK_KW_VAR or t == TokenKind.TK_KW_GLOBAL:
        return self.parse_top_level_let(is_pub, start)
    if t == TokenKind.TK_KW_EXTERN:
        return self.parse_extern_decl(start)
    if t == TokenKind.TK_KW_ERROR:
        return self.parse_error_decl(is_pub, start)
    if t == TokenKind.TK_KW_CONST:
        return self.parse_const_decl(is_pub, start)

    self.emit_error("expected declaration (fn, type, enum, let, use, extern)")
    0 as NodeId

fn Parser.mark_decl_comptime(self: Parser, decl: NodeId):
    if decl == 0:
        return
    self.pool.mark_comptime_decl(decl)
    if self.pool.kind(decl) != NodeKind.NK_FN_DECL:
        return
    let flags = self.pool.get_data2(decl)
    if (flags / FnFlags.COMPTIME) % 2 == 0:
        self.pool.set_data2(decl, flags + FnFlags.COMPTIME)
    let meta = self.pool.find_fn_meta(decl)
    if meta >= 0:
        let meta_flags = self.pool.fn_meta_flags(meta)
        if (meta_flags / FnFlags.COMPTIME) % 2 == 0:
            self.pool.state.fn_meta.set_i32((meta + 1) as i64, meta_flags + FnFlags.COMPTIME)

fn Parser.mark_new_comptime_decls(self: Parser, start_decl_count: i32):
    var di = start_decl_count
    while di < self.pool.decl_count():
        self.mark_decl_comptime(self.pool.get_decl(di))
        di = di + 1

fn Parser.parse_comptime_decl_block(self: Parser):
    if self.expect(TokenKind.TK_KW_COMPTIME) == 0:
        return
    if self.expect(TokenKind.TK_COLON) == 0:
        return
    if self.peek() != TokenKind.TK_NEWLINE:
        self.emit_error("expected newline after 'comptime:'")
        return
    self.skip_newlines()
    if self.peek() == TokenKind.TK_EOF:
        return

    let block_col = column_of(self.source, self.current_start())
    while self.peek() != TokenKind.TK_EOF:
        self.skip_newlines()
        self.skip_attributes()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_EOF:
            break
        let cur_col = column_of(self.source, self.current_start())
        if cur_col < block_col:
            break
        if cur_col > block_col:
            self.emit_error("unexpected indentation in comptime block")
            break

        if self.peek() == TokenKind.TK_KW_PUB:
            let saved_pos = self.pos
            self.advance()
            if self.peek() == TokenKind.TK_KW_IMPL or self.peek() == TokenKind.TK_KW_EXTEND:
                let decl_start = self.pool.decl_count()
                self.parse_impl_block(Visibility.Public)
                self.mark_new_comptime_decls(decl_start)
                self.skip_newlines()
                continue
            if self.peek() == TokenKind.TK_KW_TRAIT:
                let decl_start = self.pool.decl_count()
                self.parse_trait_decl(Visibility.Public)
                self.mark_new_comptime_decls(decl_start)
                self.skip_newlines()
                continue
            self.pos = saved_pos
        else if self.peek() == TokenKind.TK_KW_IMPL or self.peek() == TokenKind.TK_KW_EXTEND:
            let decl_start = self.pool.decl_count()
            self.parse_impl_block(Visibility.Private)
            self.mark_new_comptime_decls(decl_start)
            self.skip_newlines()
            continue
        else if self.peek() == TokenKind.TK_KW_TRAIT:
            let decl_start = self.pool.decl_count()
            self.parse_trait_decl(Visibility.Private)
            self.mark_new_comptime_decls(decl_start)
            self.skip_newlines()
            continue
        else if self.peek() == TokenKind.TK_KW_COMPTIME:
            if self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) == TokenKind.TK_COLON:
                self.parse_comptime_decl_block()
                self.skip_newlines()
                continue

        let decl = self.parse_decl()
        if decl != 0:
            self.mark_decl_comptime(decl)
            self.pool.add_decl(decl)
        else:
            self.recover_to_top_level()
        self.skip_newlines()

// ── fn decl ──────────────────────────────────────────────────────

fn Parser.parse_fn_decl(self: Parser, is_pub: i32, start: i32, is_async: i32, is_gen: i32, is_comptime: i32) -> NodeId:
    if self.expect(TokenKind.TK_KW_FN) == 0:
        return self.poisoned_expr()
    var name = self.expect_ident_or_keyword()
    if name == 0:
        return self.poisoned_expr()

    // Method syntax: fn Type.method(...)
    if self.peek() == TokenKind.TK_DOT:
        self.advance()
        let method_name = self.expect_ident_or_keyword()
        if method_name == 0:
            return self.poisoned_expr()
        let type_str = self.intern.resolve(name)
        let method_str = self.intern.resolve(method_name)
        name = self.intern.intern(type_str ++ "." ++ method_str)

    // Type parameters
    let tp_start = self.pool.extra_len()
    var tp_count = self.parse_type_params()

    // Parameters
    var params_start = 0
    var param_count = 0
    var required_param_count = 0
    self.last_param_pattern_start = self.pool.fn_param_patterns_len()
    self.last_param_pattern_count = 0
    if self.peek() == TokenKind.TK_L_PAREN:
        self.advance()
        param_count = self.parse_param_list()
        required_param_count = self.last_param_required_count
        if param_count > 0:
            params_start = self.pool.extra_len() - param_count * FN_PARAM_STRIDE
        if self.expect(TokenKind.TK_R_PAREN) == 0:
            return self.poisoned_expr()

    // Return type
    var ret_type: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_ARROW:
        self.advance()
        ret_type = self.parse_type_expr()

    // Where clause
    self.parse_optional_where_clause()

    // Body
    let body = self.parse_body()
    if body == 0:
        return self.poisoned_expr()

    // Build flags
    var flags = 0
    if is_pub == Visibility.Public:
        flags = flags + FnFlags.PUB
    if is_async != 0:
        flags = flags + FnFlags.ASYNC
    if is_gen != 0:
        flags = flags + FnFlags.GEN
    if is_comptime != 0:
        flags = flags + FnFlags.COMPTIME
    if self.pending_tailrec != 0:
        flags = flags + FnFlags.TAILREC
    if self.pending_must_use != 0:
        flags = flags + FnFlags.MUST_USE
    if self.pending_inline != 0:
        flags = flags + FnFlags.INLINE
    if self.pending_noinline != 0:
        flags = flags + FnFlags.NOINLINE
    if self.pending_panic_handler != 0:
        flags = flags + FnFlags.PANIC_HANDLER
    if self.pending_entry != 0:
        flags = flags + FnFlags.ENTRY
    if self.pending_no_main != 0:
        flags = flags + FnFlags.NO_MAIN
    if self.pending_test != 0:
        flags = flags + FnFlags.TEST
    if self.pending_before != 0:
        flags = flags + FnFlags.BEFORE
    if self.pending_after != 0:
        flags = flags + FnFlags.AFTER
    if self.pending_bench != 0:
        flags = flags + FnFlags.BENCH

    // Store extra: type params then params already in extra from parsing.
    // We encode: d0=name, d1=body, d2=flags
    // For unsafe fn, wrap body in NodeKind.NK_UNSAFE_BLOCK
    var final_body = body
    if self.pending_unsafe_fn != 0:
        final_body = self.pool.add_node(NodeKind.NK_UNSAFE_BLOCK, self.pool.get_start(body), self.pool.get_end(body), body, 0, 0)
    let fn_node = self.pool.add_node(NodeKind.NK_FN_DECL, start, self.pool.get_end(body), name, final_body, flags)
    let meta_flags = flags + required_param_count * FN_META_REQUIRED_UNIT
    // @[c_export("name")] on non-extern fn: store callconv in tp_start slot
    var final_tp_start = if tp_count > 0: tp_start else: 0
    var final_tp_count = tp_count
    if self.pending_callconv != 0 and tp_count == 0:
        final_tp_start = self.pending_callconv
        self.pending_callconv = 0
    self.pool.add_fn_meta(fn_node, meta_flags, ret_type, params_start, param_count, final_tp_start, final_tp_count)
    self.pool.add_fn_param_pattern_meta(fn_node, self.last_param_pattern_start, self.last_param_pattern_count)
    if self.last_where_count > 0:
        self.pool.add_where_meta(fn_node, self.last_where_start, self.last_where_count)
    if self.pending_stack_size > 0:
        self.pool.state.fn_stack_sizes.insert(fn_node as i32, self.pending_stack_size)
        self.pending_stack_size = 0
    if self.pending_weak != 0:
        self.pool.state.fn_weak_flags.insert(fn_node as i32, 1)
        self.pending_weak = 0
    if self.pending_iter_of_self != 0:
        self.pool.mark_iter_of_self_fn(fn_node)
        self.pending_iter_of_self = 0
    fn_node

// ── extern fn ────────────────────────────────────────────────────

fn Parser.parse_extern_decl(self: Parser, start: i32) -> NodeId:
    if self.expect(TokenKind.TK_KW_EXTERN) == 0:
        return self.poisoned_expr()
    // Optional ABI string: extern "C" fn ...
    if self.peek() == TokenKind.TK_STRING_LIT:
        self.advance()
    // extern let NAME: TYPE  or  extern var NAME: TYPE
    if self.peek() == TokenKind.TK_KW_LET or self.peek() == TokenKind.TK_KW_VAR:
        let is_mut = if self.peek() == TokenKind.TK_KW_VAR: 1 else: 0
        self.advance()
        let ev_name = self.expect_ident()
        if ev_name == 0: return self.poisoned_expr()
        if self.expect(TokenKind.TK_COLON) == 0: return self.poisoned_expr()
        let ev_type = self.parse_type_expr()
        return self.pool.add_node(NodeKind.NK_EXTERN_VAR, start, self.prev_end(), ev_name, ev_type, is_mut)
    if self.expect(TokenKind.TK_KW_FN) == 0:
        return self.poisoned_expr()
    let name = self.expect_ident()
    if name == 0:
        return self.poisoned_expr()
    if self.expect(TokenKind.TK_L_PAREN) == 0:
        return self.poisoned_expr()

    let param_count = self.parse_param_list()
    let extra_start = if param_count > 0:
        self.pool.extra_len() - param_count * FN_PARAM_STRIDE
    else:
        self.pool.extra_len()

    var is_variadic = 0
    if self.peek() == TokenKind.TK_DOT_DOT_DOT:
        is_variadic = 1
        self.advance()

    if self.expect(TokenKind.TK_R_PAREN) == 0:
        return self.poisoned_expr()

    var ret_type: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_ARROW:
        self.advance()
        ret_type = self.parse_type_expr()

    // Store: d0=name, d1=extra_start, d2=flags(bit0=variadic)
    // Extra already has [param_name, param_type, param_flags]* from parse_param_list
    let extern_node = self.pool.add_node(NodeKind.NK_EXTERN_FN, start, self.prev_end(), name, extra_start, is_variadic)
    // Add fn_meta so Codegen can access param_count and return_type
    // Store callconv sym in ts field (unused for extern fns)
    let required_param_count = self.last_param_required_count
    let meta_flags = is_variadic + required_param_count * FN_META_REQUIRED_UNIT
    self.pool.add_fn_meta(extern_node, meta_flags, ret_type, extra_start, param_count, self.pending_callconv, 0)
    self.pending_callconv = 0
    extern_node

// ── type decl ────────────────────────────────────────────────────

fn Parser.parse_type_decl(self: Parser, is_pub: i32, start: i32) -> NodeId:
    if self.expect(TokenKind.TK_KW_TYPE) == 0:
        return self.poisoned_expr()
    let name = self.expect_ident()
    if name == 0:
        return self.poisoned_expr()

    let tp_start = self.pool.extra_len()
    let tp_count = self.parse_type_params()
    self.parse_optional_where_clause()

    var repr_type_node: NodeId = 0 as NodeId
    var is_ephemeral = 0
    if self.peek() == TokenKind.TK_KW_EPHEMERAL:
        is_ephemeral = 1
        self.advance()
    self.skip_newlines()

    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        if self.peek() == TokenKind.TK_NEWLINE:
            self.skip_newlines()
            let extra_start = self.parse_struct_body_block()
            self.pool.add_extra(is_pub)
            self.pool.add_extra(tp_start)
            self.pool.add_extra(tp_count)
            var struct_kind = pack_type_decl_kind(TypeDeclKind.Struct, is_ephemeral)
            if self.pending_packed != 0:
                struct_kind = struct_kind + TDK_FLAG_PACKED
            if self.pending_bitpacked != 0:
                struct_kind = struct_kind + TDK_FLAG_BITPACKED
            let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, struct_kind)
            return self.finish_type_decl(node)
        repr_type_node = self.parse_type_expr()

    if self.peek() == TokenKind.TK_L_BRACE:
        let extra_start = self.parse_struct_body()
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        var struct_kind = pack_type_decl_kind(TypeDeclKind.Struct, is_ephemeral)
        if self.pending_packed != 0:
            struct_kind = struct_kind + TDK_FLAG_PACKED
        if self.pending_bitpacked != 0:
            struct_kind = struct_kind + TDK_FLAG_BITPACKED
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, struct_kind)
        return self.finish_type_decl(node)

    if self.peek() != TokenKind.TK_EQ:
        self.emit_error("expected type body")
        return self.poisoned_expr()

    self.advance()
    self.skip_newlines()

    if self.peek() == TokenKind.TK_KW_EPHEMERAL:
        is_ephemeral = 1
        self.advance()
        self.skip_newlines()

    if repr_type_node != 0:
        self.emit_legacy_enum_decl_error()
        let extra_start = self.parse_disc_enum_variants(repr_type_node)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TypeDeclKind.DiscEnum, is_ephemeral))
        return self.finish_type_decl(node)

    if self.peek() == TokenKind.TK_L_BRACE:
        self.emit_legacy_struct_decl_error()
        let extra_start = self.parse_struct_body()
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        var struct_kind = pack_type_decl_kind(TypeDeclKind.Struct, is_ephemeral)
        if self.pending_packed != 0:
            struct_kind = struct_kind + TDK_FLAG_PACKED
        if self.pending_bitpacked != 0:
            struct_kind = struct_kind + TDK_FLAG_BITPACKED
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, struct_kind)
        return self.finish_type_decl(node)

    if self.peek() == TokenKind.TK_PIPE or (self.peek() == TokenKind.TK_IDENT and self.is_enum_def()):
        self.emit_legacy_enum_decl_error()
        let extra_start = self.parse_enum_variants()
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TypeDeclKind.Enum, is_ephemeral))
        return self.finish_type_decl(node)

    if self.peek() == TokenKind.TK_KW_OPAQUE:
        self.advance()
        let extra_start = self.pool.extra_len()
        self.pool.add_extra(0)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TypeDeclKind.Opaque, is_ephemeral))
        return self.finish_type_decl(node)

    if self.peek() == TokenKind.TK_KW_UNION:
        self.advance()
        self.skip_newlines()
        var extra_start = 0
        if self.peek() == TokenKind.TK_L_BRACE:
            extra_start = self.parse_struct_body()
        else if self.peek() == TokenKind.TK_NEWLINE:
            self.skip_newlines()
            extra_start = self.parse_struct_body_block()
        else:
            self.emit_error("expected union body")
            return self.poisoned_expr()
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TypeDeclKind.Union, is_ephemeral))
        return self.finish_type_decl(node)

    if self.peek() == TokenKind.TK_IDENT and self.is_ident_named("distinct"):
        self.advance()
        let aliased = self.parse_type_expr()
        let extra_start = self.pool.extra_len()
        self.pool.add_extra(aliased)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TypeDeclKind.Distinct, is_ephemeral))
        return self.finish_type_decl(node)

    if self.peek() == TokenKind.TK_KW_FN or
       self.peek() == TokenKind.TK_IDENT or
       self.peek() == TokenKind.TK_AMPERSAND or
       self.peek() == TokenKind.TK_L_PAREN or
       self.peek() == TokenKind.TK_QUESTION or
       self.peek() == TokenKind.TK_STAR or
       self.peek() == TokenKind.TK_L_BRACKET or
       self.peek() == TokenKind.TK_KW_DYN:
        let aliased = self.parse_type_expr()
        let extra_start = self.pool.extra_len()
        self.pool.add_extra(aliased)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(tp_start)
        self.pool.add_extra(tp_count)
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(TypeDeclKind.Alias, is_ephemeral))
        return self.finish_type_decl(node)

    self.emit_error("expected type body")
    0 as NodeId

fn Parser.parse_enum_decl(self: Parser, is_pub: i32, start: i32) -> NodeId:
    if self.expect(TokenKind.TK_KW_ENUM) == 0:
        return self.poisoned_expr()
    let name = self.expect_ident()
    if name == 0:
        return self.poisoned_expr()

    let tp_start = self.pool.extra_len()
    let tp_count = self.parse_type_params()
    self.parse_optional_where_clause()

    var is_ephemeral = 0
    if self.peek() == TokenKind.TK_KW_EPHEMERAL:
        is_ephemeral = 1
        self.advance()
    self.skip_newlines()

    self.parse_enum_named_decl(start, name, is_pub, tp_start, tp_count, is_ephemeral)

fn Parser.emit_legacy_enum_decl_error(self: Parser):
    self.emit_error("use 'enum' for enum declarations")

fn Parser.emit_legacy_struct_decl_error(self: Parser):
    self.emit_error("drop '=' in struct type declarations")

fn Parser.parse_enum_named_decl(self: Parser, start: i32, name: i32, is_pub: i32, tp_start: i32, tp_count: i32, is_ephemeral: i32) -> NodeId:
    var repr_type_node: NodeId = 0 as NodeId
    var use_block_body = 0
    var use_braced_body = 0

    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        if self.peek() == TokenKind.TK_NEWLINE:
            use_block_body = 1
            self.skip_newlines()
        else:
            repr_type_node = self.parse_type_expr()
            if self.peek() == TokenKind.TK_COLON:
                self.advance()
                use_block_body = 1
                self.skip_newlines()
            else:
                if self.peek() == TokenKind.TK_L_BRACE:
                    use_braced_body = 1
                else:
                    self.emit_error("expected enum body after backing type")
                    return self.poisoned_expr()
    else:
        if self.peek() == TokenKind.TK_L_BRACE:
            use_braced_body = 1
        else:
            self.emit_error("expected enum body")
            return self.poisoned_expr()

    var extra_start = 0
    var sub_kind = TypeDeclKind.Enum
    if repr_type_node != 0:
        sub_kind = TypeDeclKind.DiscEnum
        if use_block_body != 0:
            extra_start = self.parse_disc_enum_variants_block(repr_type_node)
        else:
            extra_start = self.parse_disc_enum_variants_braced(repr_type_node)
    else:
        if use_block_body != 0:
            extra_start = self.parse_enum_variants_block()
        else:
            extra_start = self.parse_enum_variants_braced()

    self.pool.add_extra(is_pub)
    self.pool.add_extra(tp_start)
    self.pool.add_extra(tp_count)
    let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, pack_type_decl_kind(sub_kind, is_ephemeral))
    return self.finish_type_decl(node)

fn Parser.finish_type_decl(self: Parser, node: NodeId) -> NodeId:
    if self.pending_derive_count > 0:
        self.pool.add_type_meta(node, self.pending_derive_start, self.pending_derive_count)
    self.pending_derive_start = 0
    self.pending_derive_count = 0
    if self.pending_must_use != 0:
        self.pool.mark_must_use_type(node)
    node

fn Parser.parse_struct_body(self: Parser) -> i32:
    self.advance()  // consume {
    self.skip_newlines()
    var fields: Vec[i32] = Vec.new()
    var aligns: Vec[i32] = Vec.new()
    var field_count = 0

    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        // Check for per-field @[align(N)] attribute
        var field_align = 0
        if self.peek() == TokenKind.TK_AT:
            let saved = self.pos
            self.advance()
            if self.peek() == TokenKind.TK_L_BRACKET:
                self.advance()
                if self.is_ident_named("align"):
                    self.advance()
                    if self.peek() == TokenKind.TK_L_PAREN:
                        self.advance()
                        if self.peek() == TokenKind.TK_INT_LIT:
                            let atext = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                            field_align = parse_i64(atext) as i32
                            self.advance()
                            if self.peek() == TokenKind.TK_R_PAREN:
                                self.advance()
                    if self.peek() == TokenKind.TK_R_BRACKET:
                        self.advance()
                        self.skip_newlines()
                else:
                    self.pos = saved
            else:
                self.pos = saved

        let field_name = self.expect_ident()
        if field_name == 0:
            break
        if self.expect(TokenKind.TK_COLON) == 0:
            break
        let field_type = self.parse_type_expr()

        // Optional default value
        var field_default: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            field_default = self.parse_expr()

        fields.push(field_name)
        fields.push(field_type as i32)
        fields.push(field_default as i32)
        aligns.push(field_align)
        field_count = field_count + 1

        self.skip_newlines()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()

    self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(field_count)
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    // Alignment array: one entry per field (0 = natural)
    for fi in 0..field_count:
        self.pool.add_extra(aligns.get(fi as i64))
    extra_start

fn Parser.parse_struct_body_block(self: Parser) -> i32:
    var fields: Vec[i32] = Vec.new()
    var aligns: Vec[i32] = Vec.new()
    var field_count = 0
    var field_col = -1

    while self.peek() != TokenKind.TK_EOF:
        let cur_col = column_of(self.source, self.current_start())
        if field_col < 0:
            field_col = cur_col
        else if cur_col != field_col:
            break

        var field_align = 0
        if self.peek() == TokenKind.TK_AT:
            let saved = self.pos
            self.advance()
            if self.peek() == TokenKind.TK_L_BRACKET:
                self.advance()
                if self.is_ident_named("align"):
                    self.advance()
                    if self.peek() == TokenKind.TK_L_PAREN:
                        self.advance()
                        if self.peek() == TokenKind.TK_INT_LIT:
                            let atext = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                            field_align = parse_i64(atext) as i32
                            self.advance()
                            if self.peek() == TokenKind.TK_R_PAREN:
                                self.advance()
                    if self.peek() == TokenKind.TK_R_BRACKET:
                        self.advance()
                        self.skip_newlines()
                else:
                    self.pos = saved
            else:
                self.pos = saved
        if self.peek() != TokenKind.TK_IDENT:
            break
        let field_name = self.expect_ident()
        if self.expect(TokenKind.TK_COLON) == 0:
            break
        let field_type = self.parse_type_expr()
        var field_default: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            field_default = self.parse_expr()

        fields.push(field_name)
        fields.push(field_type as i32)
        fields.push(field_default as i32)
        aligns.push(field_align)
        field_count = field_count + 1

        self.skip_newlines()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
        if self.peek() == TokenKind.TK_EOF:
            break
        let next_col = column_of(self.source, self.current_start())
        if next_col != field_col:
            break

    let extra_start = self.pool.extra_len()
    self.pool.add_extra(field_count)
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    for fi in 0..field_count:
        self.pool.add_extra(aligns.get(fi as i64))
    extra_start

fn Parser.is_enum_def(self: Parser) -> bool:
    let saved = self.pos
    self.advance()  // skip identifier
    self.skip_newlines()
    if self.peek() == TokenKind.TK_PIPE:
        self.pos = saved
        return true
    if self.peek() == TokenKind.TK_L_PAREN:
        self.advance()
        var depth = 1
        while depth > 0 and self.peek() != TokenKind.TK_EOF:
            if self.peek() == TokenKind.TK_L_PAREN:
                depth = depth + 1
            if self.peek() == TokenKind.TK_R_PAREN:
                depth = depth - 1
            self.advance()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_PIPE:
            self.pos = saved
            return true
    self.pos = saved
    false

fn Parser.parse_enum_variants(self: Parser) -> i32:
    var variants: Vec[i32] = Vec.new()
    var variant_count = 0

    if self.peek() == TokenKind.TK_PIPE:
        self.advance()
        self.skip_newlines()

    while self.peek() == TokenKind.TK_IDENT:
        let vname = self.expect_ident()
        var payloads: Vec[i32] = Vec.new()

        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                // Support named payload fields: Variant(name: Type, ...)
                if self.peek() == TokenKind.TK_IDENT and
                   self.pos + 1 < self.tokens.len() and
                   self.tokens.get_tag(self.pos + 1) == TokenKind.TK_COLON:
                    self.advance()
                    self.advance()
                    self.skip_newlines()

                let before_payload = self.pos
                let pty = self.parse_type_expr()
                payloads.push(pty as i32)
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
                else if self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    self.emit_error("expected ',' or ')' in enum payload")
                    if self.pos == before_payload:
                        self.advance()
            self.expect(TokenKind.TK_R_PAREN)

        variants.push(vname)
        variants.push(payloads.len() as i32)
        for pi in 0..payloads.len() as i32:
            variants.push(payloads.get(pi as i64))
        variant_count = variant_count + 1

        self.skip_newlines()
        if self.peek() == TokenKind.TK_PIPE:
            self.advance()
            self.skip_newlines()
            continue
        if self.peek() == TokenKind.TK_IDENT:
            continue
        break

    let extra_start = self.pool.extra_len()
    self.pool.add_extra(variant_count)
    for vi in 0..variants.len() as i32:
        self.pool.add_extra(variants.get(vi as i64))
    extra_start

fn Parser.parse_enum_variants_braced(self: Parser) -> i32:
    self.advance()
    self.skip_newlines()
    var variants: Vec[i32] = Vec.new()
    var variant_count = 0

    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        if self.peek() == TokenKind.TK_PIPE or self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
            continue
        let vname = self.expect_ident()
        if vname == 0:
            break
        var payloads: Vec[i32] = Vec.new()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                if self.peek() == TokenKind.TK_IDENT and
                   self.pos + 1 < self.tokens.len() and
                   self.tokens.get_tag(self.pos + 1) == TokenKind.TK_COLON:
                    self.advance()
                    self.advance()
                    self.skip_newlines()
                let before_payload = self.pos
                let pty = self.parse_type_expr()
                payloads.push(pty as i32)
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
                else if self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    self.emit_error("expected ',' or ')' in enum payload")
                    if self.pos == before_payload:
                        self.advance()
            self.expect(TokenKind.TK_R_PAREN)
        variants.push(vname)
        variants.push(payloads.len() as i32)
        for pi in 0..payloads.len() as i32:
            variants.push(payloads.get(pi as i64))
        variant_count = variant_count + 1

        self.skip_newlines()
        if self.peek() == TokenKind.TK_PIPE or self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
        else if self.peek() == TokenKind.TK_IDENT:
            continue
    self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(variant_count)
    for vi in 0..variants.len() as i32:
        self.pool.add_extra(variants.get(vi as i64))
    extra_start

fn Parser.parse_enum_variants_block(self: Parser) -> i32:
    var variants: Vec[i32] = Vec.new()
    var variant_count = 0
    var variant_col = -1

    while self.peek() != TokenKind.TK_EOF:
        let cur_col = column_of(self.source, self.current_start())
        if variant_col < 0:
            variant_col = cur_col
        else if cur_col != variant_col:
            break
        if self.peek() == TokenKind.TK_PIPE:
            self.advance()
        let vname = self.expect_ident()
        if vname == 0:
            break
        var payloads: Vec[i32] = Vec.new()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                if self.peek() == TokenKind.TK_IDENT and
                   self.pos + 1 < self.tokens.len() and
                   self.tokens.get_tag(self.pos + 1) == TokenKind.TK_COLON:
                    self.advance()
                    self.advance()
                    self.skip_newlines()
                let before_payload = self.pos
                let pty = self.parse_type_expr()
                payloads.push(pty as i32)
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
                else if self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    self.emit_error("expected ',' or ')' in enum payload")
                    if self.pos == before_payload:
                        self.advance()
            self.expect(TokenKind.TK_R_PAREN)
        variants.push(vname)
        variants.push(payloads.len() as i32)
        for pi in 0..payloads.len() as i32:
            variants.push(payloads.get(pi as i64))
        variant_count = variant_count + 1
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
        if self.peek() == TokenKind.TK_EOF:
            break
        let next_col = column_of(self.source, self.current_start())
        if next_col != variant_col:
            break
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(variant_count)
    for vi in 0..variants.len() as i32:
        self.pool.add_extra(variants.get(vi as i64))
    extra_start

fn Parser.parse_disc_enum_variants(self: Parser, repr_type_node: i32) -> i32:
    var variants: Vec[i32] = Vec.new()
    var variant_count = 0
    var current_disc = 0

    if self.pending_flags != 0:
        current_disc = 1

    if self.peek() == TokenKind.TK_PIPE:
        self.advance()
        self.skip_newlines()

    while self.peek() == TokenKind.TK_IDENT:
        let vname = self.expect_ident()

        // Optional payload
        var payloads: Vec[i32] = Vec.new()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                if self.peek() == TokenKind.TK_IDENT and
                   self.pos + 1 < self.tokens.len() and
                   self.tokens.get_tag(self.pos + 1) == TokenKind.TK_COLON:
                    self.advance()
                    self.advance()
                    self.skip_newlines()
                let pty = self.parse_type_expr()
                payloads.push(pty as i32)
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
                else if self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    self.emit_error("expected ',' or ')' in enum payload")
                    self.advance()
            self.expect(TokenKind.TK_R_PAREN)

        // Optional explicit discriminant: = value
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            var negate = 0
            if self.peek() == TokenKind.TK_MINUS:
                negate = 1
                self.advance()
            if self.peek() == TokenKind.TK_INT_LIT:
                let text = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                let val = parse_i64(text) as i32
                if negate != 0:
                    current_disc = 0 - val
                else:
                    current_disc = val
                self.advance()
            else:
                self.emit_error("expected integer literal for discriminant value")

        variants.push(vname)
        variants.push(current_disc)
        variants.push(payloads.len() as i32)
        for pi in 0..payloads.len() as i32:
            variants.push(payloads.get(pi as i64))
        variant_count = variant_count + 1

        // Auto-increment for next variant
        if self.pending_flags != 0:
            current_disc = current_disc * 2
        else:
            current_disc = current_disc + 1

        self.skip_newlines()
        if self.peek() == TokenKind.TK_PIPE:
            self.advance()
            self.skip_newlines()
            continue
        if self.peek() == TokenKind.TK_IDENT:
            continue
        break

    let extra_start = self.pool.extra_len()
    self.pool.add_extra(repr_type_node)
    self.pool.add_extra(variant_count)
    for vi in 0..variants.len() as i32:
        self.pool.add_extra(variants.get(vi as i64))
    extra_start

fn Parser.parse_disc_enum_variants_braced(self: Parser, repr_type_node: i32) -> i32:
    self.advance()
    self.skip_newlines()
    var variants: Vec[i32] = Vec.new()
    var variant_count = 0
    var current_disc = 0
    if self.pending_flags != 0:
        current_disc = 1

    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        if self.peek() == TokenKind.TK_PIPE or self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
            continue
        let vname = self.expect_ident()
        if vname == 0:
            break
        var payloads: Vec[i32] = Vec.new()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                if self.peek() == TokenKind.TK_IDENT and
                   self.pos + 1 < self.tokens.len() and
                   self.tokens.get_tag(self.pos + 1) == TokenKind.TK_COLON:
                    self.advance()
                    self.advance()
                    self.skip_newlines()
                let pty = self.parse_type_expr()
                payloads.push(pty as i32)
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
                else if self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    self.emit_error("expected ',' or ')' in enum payload")
                    self.advance()
            self.expect(TokenKind.TK_R_PAREN)
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            var negate = 0
            if self.peek() == TokenKind.TK_MINUS:
                negate = 1
                self.advance()
            if self.peek() == TokenKind.TK_INT_LIT:
                let text = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                let val = parse_i64(text) as i32
                if negate != 0:
                    current_disc = 0 - val
                else:
                    current_disc = val
                self.advance()
            else:
                self.emit_error("expected integer literal for discriminant value")
        variants.push(vname)
        variants.push(current_disc)
        variants.push(payloads.len() as i32)
        for pi in 0..payloads.len() as i32:
            variants.push(payloads.get(pi as i64))
        variant_count = variant_count + 1
        if self.pending_flags != 0:
            current_disc = current_disc * 2
        else:
            current_disc = current_disc + 1
        self.skip_newlines()
        if self.peek() == TokenKind.TK_PIPE or self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
        else if self.peek() == TokenKind.TK_IDENT:
            continue
    self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(repr_type_node)
    self.pool.add_extra(variant_count)
    for vi in 0..variants.len() as i32:
        self.pool.add_extra(variants.get(vi as i64))
    extra_start

fn Parser.parse_disc_enum_variants_block(self: Parser, repr_type_node: i32) -> i32:
    var variants: Vec[i32] = Vec.new()
    var variant_count = 0
    var current_disc = 0
    var variant_col = -1
    if self.pending_flags != 0:
        current_disc = 1

    while self.peek() != TokenKind.TK_EOF:
        let cur_col = column_of(self.source, self.current_start())
        if variant_col < 0:
            variant_col = cur_col
        else if cur_col != variant_col:
            break
        if self.peek() == TokenKind.TK_PIPE:
            self.advance()
        let vname = self.expect_ident()
        if vname == 0:
            break
        var payloads: Vec[i32] = Vec.new()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                if self.peek() == TokenKind.TK_IDENT and
                   self.pos + 1 < self.tokens.len() and
                   self.tokens.get_tag(self.pos + 1) == TokenKind.TK_COLON:
                    self.advance()
                    self.advance()
                    self.skip_newlines()
                let pty = self.parse_type_expr()
                payloads.push(pty as i32)
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
                else if self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    self.emit_error("expected ',' or ')' in enum payload")
                    self.advance()
            self.expect(TokenKind.TK_R_PAREN)
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            var negate = 0
            if self.peek() == TokenKind.TK_MINUS:
                negate = 1
                self.advance()
            if self.peek() == TokenKind.TK_INT_LIT:
                let text = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                let val = parse_i64(text) as i32
                if negate != 0:
                    current_disc = 0 - val
                else:
                    current_disc = val
                self.advance()
            else:
                self.emit_error("expected integer literal for discriminant value")
        variants.push(vname)
        variants.push(current_disc)
        variants.push(payloads.len() as i32)
        for pi in 0..payloads.len() as i32:
            variants.push(payloads.get(pi as i64))
        variant_count = variant_count + 1
        if self.pending_flags != 0:
            current_disc = current_disc * 2
        else:
            current_disc = current_disc + 1
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
        if self.peek() == TokenKind.TK_EOF:
            break
        let next_col = column_of(self.source, self.current_start())
        if next_col != variant_col:
            break
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(repr_type_node)
    self.pool.add_extra(variant_count)
    for vi in 0..variants.len() as i32:
        self.pool.add_extra(variants.get(vi as i64))
    extra_start

// ── use decl ─────────────────────────────────────────────────────

fn Parser.parse_use_decl(self: Parser, start: i32) -> NodeId:
    if self.expect(TokenKind.TK_KW_USE) == 0:
        return self.poisoned_expr()

    // use c_import("header.h")
    if self.peek() == TokenKind.TK_KW_C_IMPORT:
        return self.parse_c_import(start)

    let extra_start = self.pool.extra_len()
    var path_count = 0

    let first = self.peek()
    if first == TokenKind.TK_IDENT or parser_is_keyword_tag(first):
        let sym = self.expect_use_path_segment()
        if sym == 0:
            return self.poisoned_expr()
        self.pool.add_extra(sym)
        path_count = path_count + 1

    while true:
        if self.peek() == TokenKind.TK_DOT:
            self.advance()
            let next = self.peek()
            if next == TokenKind.TK_IDENT or parser_is_keyword_tag(next):
                let sym = self.expect_use_path_segment()
                if sym == 0:
                    return self.poisoned_expr()
                self.pool.add_extra(sym)
                path_count = path_count + 1
            else if self.peek() == TokenKind.TK_STAR:
                self.advance()
                break
            else if self.peek() == TokenKind.TK_L_BRACE:
                self.advance()
                while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF and self.peek() != TokenKind.TK_NEWLINE:
                    self.advance()
                if self.peek() == TokenKind.TK_R_BRACE:
                    self.advance()
                break
            else:
                break
        else if self.peek() == TokenKind.TK_DOT_IDENT:
            let span_s = self.current_start()
            let span_e = self.current_end()
            let text = self.source.slice((span_s + 1) as i64, span_e as i64)
            let sym = self.intern.intern(text)
            self.pool.add_extra(sym)
            path_count = path_count + 1
            self.advance()
        else:
            break

    if path_count == 0:
        self.emit_error("expected import path after 'use'")
        return self.poisoned_expr()

    // Skip any trailing paren groups
    if self.peek() == TokenKind.TK_L_PAREN:
        var depth = 1
        self.advance()
        while depth > 0 and self.peek() != TokenKind.TK_EOF:
            if self.peek() == TokenKind.TK_L_PAREN:
                depth = depth + 1
            if self.peek() == TokenKind.TK_R_PAREN:
                depth = depth - 1
            self.advance()

    self.pool.add_node(NodeKind.NK_USE_DECL, start, self.prev_end(), extra_start, path_count, 0)

fn Parser.parse_c_import(self: Parser, start: i32) -> NodeId:
    self.advance()  // consume c_import
    if self.expect(TokenKind.TK_L_PAREN) == 0:
        return self.poisoned_expr()
    if self.peek() != TokenKind.TK_STRING_LIT:
        self.emit_error("expected string literal after c_import(")
        return self.poisoned_expr()
    let str_s = self.current_start()
    let str_e = self.current_end()
    let raw = self.source.slice((str_s + 1) as i64, (str_e - 1) as i64)
    let header_sym = self.intern.intern(raw)
    self.advance()

    let extra_start = self.pool.extra_len()
    var link_count = 0

    if self.peek() == TokenKind.TK_COMMA:
        self.advance()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_IDENT:
            self.advance()  // skip 'link'
        if self.expect(TokenKind.TK_COLON) == 0:
            return self.poisoned_expr()
        self.skip_newlines()
        while self.peek() == TokenKind.TK_STRING_LIT:
            let ls = self.current_start()
            let le = self.current_end()
            let lib = self.source.slice((ls + 1) as i64, (le - 1) as i64)
            let lib_sym = self.intern.intern(lib)
            self.pool.add_extra(lib_sym)
            link_count = link_count + 1
            self.advance()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_COMMA:
                let cp = self.pos
                self.advance()
                self.skip_newlines()
                if self.peek() == TokenKind.TK_STRING_LIT:
                    continue
                self.pos = cp
            break

    self.expect(TokenKind.TK_R_PAREN)
    self.pool.add_node(NodeKind.NK_C_IMPORT, start, self.prev_end(), header_sym, extra_start, link_count)

// ── let decl ─────────────────────────────────────────────────────

fn Parser.parse_top_level_let(self: Parser, is_pub: i32, start: i32) -> NodeId:
    // docs/mut.md Rev 8 §12 — `global` (stable) and `global var` (rebindable)
    // are module-level place declarations. The GLOBAL / GLOBAL_VAR markers
    // are stored in NK_LET_DECL.d2 bits 2 and 3 (see Ast.w LET_FLAG_GLOBAL /
    // LET_FLAG_GLOBAL_VAR). Plain top-level `let`/`var` (without `global`)
    // leave those bits clear; sema's check_assign treats stable globals as
    // non-rebindable per §15.12.
    let is_global = self.peek() == TokenKind.TK_KW_GLOBAL
    if is_global:
        self.advance()  // consume 'global'
    let is_var = self.peek() == TokenKind.TK_KW_VAR
    if is_var:
        self.advance()  // consume 'var' (covers both 'var' and 'global var')
    else if not is_global:
        self.advance()  // consume 'let'
    // For bare `global X = ...`, no further keyword to consume; cursor is at the name.
    var is_mut = is_var
    if not is_var and self.peek() == TokenKind.TK_KW_MUT:
        self.emit_error("'let mut' is not supported; use 'var' for mutable bindings")
        is_mut = true
        self.advance()
    let name = self.expect_ident()
    if name == 0:
        return self.poisoned_expr()

    var type_ann: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        type_ann = self.parse_type_expr()

    let global_bits = if is_global:
        if is_var: LET_FLAG_GLOBAL_VAR else: LET_FLAG_GLOBAL
    else: 0

    // var x: T (no initializer) — zero-initialized
    if self.peek() != TokenKind.TK_EQ:
        if is_mut and type_ann != 0:
            var flags = 1  // mut
            if is_pub == Visibility.Public:
                flags = flags + 2
            flags = flags + global_bits
            let type_extra = self.pool.extra_len()
            self.pool.add_extra(type_ann)
            flags = flags + (type_extra + 1) * 16
            return self.pool.add_node(NodeKind.NK_LET_DECL, start, self.prev_end(), name, 0, flags)
        if not is_mut:
            self.emit_error("let binding requires initializer")
            return self.poisoned_expr()
        self.emit_error("var without initializer requires type annotation")
        return self.poisoned_expr()

    self.advance()  // consume '='
    self.skip_newlines()
    let value = self.parse_expr()
    if value == 0:
        return self.poisoned_expr()

    var flags = 0
    if is_mut:
        flags = flags + 1
    if is_pub == Visibility.Public:
        flags = flags + 2
    flags = flags + global_bits
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        // Lower 4 bits: mut, pub, GLOBAL, GLOBAL_VAR. Type-extra at bit 4+.
        flags = flags + (type_extra + 1) * 16

    self.pool.add_node(NodeKind.NK_LET_DECL, start, self.prev_end(), name, value, flags)

fn Parser.parse_const_decl(self: Parser, is_pub: i32, start: i32) -> NodeId:
    self.advance()  // consume 'const'
    let name = self.expect_ident()
    if name == 0:
        return self.poisoned_expr()

    if self.peek() != TokenKind.TK_COLON:
        self.emit_error("const declaration requires a type annotation")
        return self.poisoned_expr()
    self.advance()
    let type_ann = self.parse_type_expr()

    if self.expect(TokenKind.TK_EQ) == 0:
        return self.poisoned_expr()
    self.skip_newlines()
    let raw_value = self.parse_expr()
    if raw_value == 0:
        return self.poisoned_expr()
    // const desugars to comptime-wrapped immutable let
    let value = self.pool.add_node(NodeKind.NK_COMPTIME, start, self.prev_end(), raw_value, 0, 0)

    var flags = 0
    if is_pub == Visibility.Public:
        flags = flags + 2
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        flags = flags + (type_extra + 1) * 16

    self.pool.add_node(NodeKind.NK_LET_DECL, start, self.prev_end(), name, value, flags)

// ── error decl (desugars to enum) ────────────────────────────────

fn Parser.parse_error_decl(self: Parser, is_pub: i32, start: i32) -> NodeId:
    self.advance()  // consume 'error'
    let err_name = self.expect_ident()
    if err_name == 0:
        return self.poisoned_expr()

    // error Name from OtherError, ...
    if self.is_ident_named("from"):
        self.advance()
        let extra_start = self.pool.extra_len()
        var variant_count = 0
        let count_idx = self.pool.add_extra(0)
        while true:
            let src_sym = self.expect_ident()
            if src_sym == 0:
                break
            self.pool.add_extra(src_sym)
            self.pool.add_extra(0)  // payload count = 0
            variant_count = variant_count + 1
            if self.peek() != TokenKind.TK_COMMA:
                break
            self.advance()
            self.skip_newlines()
        self.pool.state.extra.set_i32(count_idx as i64, variant_count)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(0)
        self.pool.add_extra(0)
        return self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), err_name, extra_start, pack_type_decl_kind(TypeDeclKind.Enum, 0))

    // error Name = Variant1, Variant2(payload), ...
    if self.expect(TokenKind.TK_EQ) == 0:
        return self.poisoned_expr()
    self.skip_newlines()

    let extra_start = self.parse_enum_variants()
    self.pool.add_extra(is_pub)
    self.pool.add_extra(0)
    self.pool.add_extra(0)
    self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), err_name, extra_start, pack_type_decl_kind(TypeDeclKind.Enum, 0))

// ── trait decl ───────────────────────────────────────────────────

fn Parser.parse_trait_decl(self: Parser, vis: i32):
    let start = self.current_start()
    if self.peek() == TokenKind.TK_KW_PUB:
        self.advance()
    if self.expect(TokenKind.TK_KW_TRAIT) == 0:
        return
    let name = self.expect_ident()
    if name == 0:
        return
    // Parse optional type parameters: trait Iter[T] = ...
    let trait_tp_start = self.pool.extra_len()
    let trait_tp_count = self.parse_type_params()
    var trait_braced = false
    if self.peek() == TokenKind.TK_L_BRACE:
        trait_braced = true
        self.advance()
    else if self.peek() == TokenKind.TK_EQ or self.peek() == TokenKind.TK_COLON:
        self.advance()
    else:
        self.emit_error("expected '=', ':' or '{'")
        return
    self.skip_newlines()

    var method_names: Vec[i32] = Vec.new()
    var method_flags: Vec[i32] = Vec.new()
    var method_param_starts: Vec[i32] = Vec.new()
    var method_param_counts: Vec[i32] = Vec.new()
    var method_ret_types: Vec[i32] = Vec.new()
    var method_bodies: Vec[i32] = Vec.new()

    var assoc_names: Vec[i32] = Vec.new()
    var assoc_bound_starts: Vec[i32] = Vec.new()
    var assoc_bound_counts: Vec[i32] = Vec.new()
    var assoc_default_types: Vec[i32] = Vec.new()
    var assoc_bounds_flat: Vec[i32] = Vec.new()

    while self.peek() == TokenKind.TK_KW_FN or self.peek() == TokenKind.TK_KW_PUB or self.peek() == TokenKind.TK_KW_TYPE or self.peek() == TokenKind.TK_KW_ASYNC or (trait_braced and self.peek() == TokenKind.TK_R_BRACE):
        if trait_braced and self.peek() == TokenKind.TK_R_BRACE:
            break
        if not trait_braced:
            let fn_col = column_of(self.source, self.current_start())
            if fn_col == 0:
                break

        if self.peek() == TokenKind.TK_KW_TYPE:
            self.advance()
            let at_name = self.expect_ident()
            let bound_start = assoc_bounds_flat.len() as i32
            var bound_count = 0
            if self.peek() == TokenKind.TK_COLON:
                self.advance()
                let b = self.parse_type_bound_symbol()
                if b != 0:
                    assoc_bounds_flat.push(b)
                    bound_count = bound_count + 1
                while self.peek() == TokenKind.TK_PLUS:
                    self.advance()
                    let b2 = self.parse_type_bound_symbol()
                    if b2 != 0:
                        assoc_bounds_flat.push(b2)
                        bound_count = bound_count + 1
            var default_ty: NodeId = 0 as NodeId
            if self.peek() == TokenKind.TK_EQ:
                self.advance()
                default_ty = self.parse_type_expr()
            assoc_names.push(at_name)
            assoc_bound_starts.push(bound_start)
            assoc_bound_counts.push(bound_count)
            assoc_default_types.push(default_ty as i32)
            self.skip_newlines()
            continue

        var is_pub_method = 0
        if self.peek() == TokenKind.TK_KW_PUB:
            is_pub_method = 1
            self.advance()
        var is_async_method = 0
        if self.peek() == TokenKind.TK_KW_ASYNC:
            is_async_method = 1
            self.advance()
        if self.expect(TokenKind.TK_KW_FN) == 0:
            break
        let mname = self.expect_ident_or_keyword()
        let m_tp_count = self.parse_type_params()

        var params_start = 0
        var param_count = 0
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            param_count = self.parse_param_list()
            if param_count > 0:
                params_start = self.pool.extra_len() - param_count * FN_PARAM_STRIDE
            self.expect(TokenKind.TK_R_PAREN)

        var ret_type: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_ARROW:
            self.advance()
            ret_type = self.parse_type_expr()

        self.parse_optional_where_clause()

        var method_body: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            method_body = self.parse_block_or_expr()
        else if self.peek() == TokenKind.TK_L_BRACE:
            self.advance()
            method_body = self.parse_braced_body()

        method_names.push(mname)
        method_param_starts.push(params_start)
        method_param_counts.push(param_count)
        method_ret_types.push(ret_type as i32)
        method_bodies.push(method_body as i32)
        var mflags = 0
        if is_async_method != 0:
            mflags = mflags + 1
        if is_pub_method != 0:
            mflags = mflags + 2
        if m_tp_count > 0:
            mflags = mflags + 4
        method_flags.push(mflags)
        self.skip_newlines()

    if trait_braced:
        self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    // Type params: count and start index into extra pool
    self.pool.add_extra(trait_tp_count)
    self.pool.add_extra(trait_tp_start)
    let assoc_count = assoc_names.len() as i32
    self.pool.add_extra(assoc_count)
    for ai in 0..assoc_count:
        self.pool.add_extra(assoc_names.get(ai as i64))
        let bound_start = assoc_bound_starts.get(ai as i64)
        let bound_count = assoc_bound_counts.get(ai as i64)
        self.pool.add_extra(bound_count)
        for bi in 0..bound_count:
            self.pool.add_extra(assoc_bounds_flat.get((bound_start + bi) as i64))
        self.pool.add_extra(assoc_default_types.get(ai as i64))

    let method_count = method_names.len() as i32
    self.pool.add_extra(method_count)
    for mi in 0..method_count:
        self.pool.add_extra(method_names.get(mi as i64))
        self.pool.add_extra(method_flags.get(mi as i64))
        self.pool.add_extra(method_param_starts.get(mi as i64))
        self.pool.add_extra(method_param_counts.get(mi as i64))
        self.pool.add_extra(method_ret_types.get(mi as i64))
        self.pool.add_extra(method_bodies.get(mi as i64))

    let node = self.pool.add_node(NodeKind.NK_TRAIT_DECL, start, self.prev_end(), name, extra_start, vis)
    if self.pending_sealed != 0:
        self.pool.mark_sealed_trait(node)
    self.pool.add_decl(node)

// ── impl/extend block ────────────────────────────────────────────

// Parse optional generic type args after an impl target type name.
// e.g., for `impl Trait for Vec[i32]`, parses `[i32]` after "Vec".
// Returns NodeKind.NK_TYPE_GENERIC node if args present, 0 otherwise.
fn Parser.parse_optional_impl_target_args(self: Parser, type_name: i32) -> NodeId:
    if self.peek() != TokenKind.TK_L_BRACKET:
        return self.poisoned_expr()
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    var args: Vec[i32] = Vec.new()
    while self.peek() != TokenKind.TK_R_BRACKET and self.peek() != TokenKind.TK_EOF:
        let ty = self.parse_type_expr()
        args.push(ty as i32)
        self.skip_newlines()
        if self.peek() != TokenKind.TK_COMMA:
            break
        self.advance()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_R_BRACKET:
            break
    self.skip_newlines()
    self.expect(TokenKind.TK_R_BRACKET)
    let extra_start = self.pool.extra_len()
    for ai in 0..args.len() as i32:
        self.pool.add_extra(args.get(ai as i64))
    self.pool.add_node(NodeKind.NK_TYPE_GENERIC, start, self.prev_end(), type_name, extra_start, args.len() as i32)

fn Parser.parse_impl_block(self: Parser, vis: i32):
    let start = self.current_start()
    if self.peek() == TokenKind.TK_KW_PUB:
        self.advance()
    if self.peek() == TokenKind.TK_KW_IMPL:
        self.advance()
    else if self.peek() == TokenKind.TK_KW_EXTEND:
        self.advance()
    else:
        return

    // Check for impl-level type parameters: impl[T: Bound] Trait for T
    var impl_tp_start = 0
    var impl_tp_count = 0
    if self.peek() == TokenKind.TK_L_BRACKET:
        impl_tp_start = self.pool.extra_len()
        impl_tp_count = self.parse_type_params()

    let first_name = self.expect_ident()
    if first_name == 0:
        return

    var trait_name = 0
    var type_name = first_name
    var target_type_node: NodeId = 0 as NodeId
    var trait_arg_extra_start = 0
    var trait_arg_count = 0
    if self.peek() == TokenKind.TK_L_BRACKET:
        self.advance()
        self.skip_newlines()
        trait_arg_extra_start = self.pool.extra_len()
        while self.peek() != TokenKind.TK_R_BRACKET and self.peek() != TokenKind.TK_EOF:
            let arg = self.parse_type_expr()
            self.pool.add_extra(arg as i32)
            trait_arg_count = trait_arg_count + 1
            self.skip_newlines()
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
                if self.peek() == TokenKind.TK_R_BRACKET:
                    break
        self.skip_newlines()
        self.expect(TokenKind.TK_R_BRACKET)
        if self.peek() != TokenKind.TK_KW_FOR:
            self.emit_error("expected 'for' after trait generic arguments in impl")
            return
        self.advance()
        trait_name = first_name
        type_name = self.expect_ident()
        if type_name == 0:
            return
        target_type_node = self.parse_optional_impl_target_args(type_name)
    else if self.peek() == TokenKind.TK_KW_FOR:
        self.advance()
        trait_name = first_name
        type_name = self.expect_ident()
        if type_name == 0:
            return
        target_type_node = self.parse_optional_impl_target_args(type_name)

    // Defensive fallback: if `for` was not consumed above, consume it now.
    if trait_name == 0 and (self.peek() == TokenKind.TK_KW_FOR or self.is_ident_named("for")):
        self.advance()
        trait_name = first_name
        type_name = self.expect_ident()
        if type_name == 0:
            return
        target_type_node = self.parse_optional_impl_target_args(type_name)

    self.parse_optional_where_clause()

    var impl_braced = false
    if self.peek() == TokenKind.TK_L_BRACE:
        impl_braced = true
        self.advance()
    else if self.peek() == TokenKind.TK_EQ or self.peek() == TokenKind.TK_COLON:
        self.advance()
    self.skip_newlines()

    var impl_assoc_names: Vec[i32] = Vec.new()
    var impl_assoc_types: Vec[i32] = Vec.new()
    let extra_start = self.pool.extra_len()
    var method_count = 0

    while self.peek() == TokenKind.TK_KW_FN or self.peek() == TokenKind.TK_KW_PUB or self.peek() == TokenKind.TK_KW_ASYNC or self.peek() == TokenKind.TK_KW_TYPE or (impl_braced and self.peek() == TokenKind.TK_R_BRACE):
        if impl_braced and self.peek() == TokenKind.TK_R_BRACE:
            break
        if not impl_braced:
            let fn_col = column_of(self.source, self.current_start())
            if fn_col == 0:
                break

        // Associated type binding: type Name = ConcreteType
        if self.peek() == TokenKind.TK_KW_TYPE:
            self.advance()
            let at_name = self.expect_ident()
            if self.expect(TokenKind.TK_EQ) == 0:
                break
            let at_type = self.parse_type_expr()
            impl_assoc_names.push(at_name)
            impl_assoc_types.push(at_type as i32)
            self.skip_newlines()
            continue

        var method_vis = vis
        let method_start = self.current_start()
        if self.peek() == TokenKind.TK_KW_PUB:
            method_vis = Visibility.Public
            self.advance()
        var m_async = 0
        if self.peek() == TokenKind.TK_KW_ASYNC:
            m_async = 1
            self.advance()
        if self.expect(TokenKind.TK_KW_FN) == 0:
            break
        let method_name_sym = self.expect_ident_or_keyword()
        if method_name_sym == 0:
            break

        // Mangle as Type.method
        let type_str = self.intern.resolve(type_name)
        let method_str = self.intern.resolve(method_name_sym)
        let mangled = self.intern.intern(type_str ++ "." ++ method_str)

        let m_tp_start = self.pool.extra_len()
        let m_tp_count = self.parse_type_params()

        var m_params_start = 0
        var param_count = 0
        var required_param_count = 0
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            param_count = self.parse_param_list()
            required_param_count = self.last_param_required_count
            if param_count > 0:
                m_params_start = self.pool.extra_len() - param_count * FN_PARAM_STRIDE
            self.expect(TokenKind.TK_R_PAREN)

        var ret_type: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_ARROW:
            self.advance()
            ret_type = self.parse_type_expr()

        self.parse_optional_where_clause()

        var body: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            body = self.parse_block_or_expr()
        else if self.peek() == TokenKind.TK_L_BRACE:
            self.advance()
            body = self.parse_braced_body()
        else:
            self.emit_error("expected ':' or '{'")
            break

        var flags = 0
        if method_vis == Visibility.Public:
            flags = flags + FnFlags.PUB
        if m_async != 0:
            flags = flags + FnFlags.ASYNC

        let fn_node = self.pool.add_node(NodeKind.NK_FN_DECL, method_start, self.prev_end(), mangled, body, flags)
        let meta_flags = flags + required_param_count * FN_META_REQUIRED_UNIT
        let final_m_tp_start = if m_tp_count > 0: m_tp_start else: 0
        self.pool.add_fn_meta(fn_node, meta_flags, ret_type, m_params_start, param_count, final_m_tp_start, m_tp_count)
        if self.pending_iter_of_self != 0:
            self.pool.mark_iter_of_self_fn(fn_node)
            self.pending_iter_of_self = 0
        self.pool.add_decl(fn_node)
        method_count = method_count + 1
        self.skip_newlines()

    if impl_braced:
        self.expect(TokenKind.TK_R_BRACE)
    // Emit impl_decl node. Store assoc types + method_count in extra.
    let impl_extra = self.pool.extra_len()
    let impl_assoc_count = impl_assoc_names.len() as i32
    self.pool.add_extra(impl_assoc_count)
    for iai in 0..impl_assoc_count:
        self.pool.add_extra(impl_assoc_names.get(iai as i64))
        self.pool.add_extra(impl_assoc_types.get(iai as i64))
    self.pool.add_extra(method_count)
    let impl_node = self.pool.add_node(NodeKind.NK_IMPL_DECL, start, self.prev_end(), type_name, impl_extra, trait_name)
    self.pool.add_decl(impl_node)

    // Store impl type params if present (blanket impl)
    if impl_tp_count > 0:
        self.pool.add_impl_type_params(impl_node, impl_tp_start, impl_tp_count)

    // Store impl target type node if generic (e.g., impl Trait for Vec[i32])
    if target_type_node != 0:
        self.pool.add_impl_target_type_node(impl_node, target_type_node)

    // Store impl trait type args if present (e.g., impl IntoIter[i32] for Type)
    if trait_arg_count > 0:
        self.pool.add_impl_trait_type_args(impl_node, trait_arg_extra_start, trait_arg_count)

// ── Expression parsing ───────────────────────────────────────────

fn Parser.parse_expr(self: Parser) -> NodeId:
    let lhs = self.parse_precedence(0)
    if lhs == 0:
        return self.poisoned_expr()

    // Assignment: lhs = rhs
    if self.peek() == TokenKind.TK_EQ:
        self.advance()
        self.skip_newlines()
        let rhs = self.parse_expr()
        return self.pool.add_node(NodeKind.NK_ASSIGN, self.pool.get_start(lhs), self.prev_end(), lhs, rhs, 0)

    // Compound assignment: += -= *= /= %=
    let cop = self.compound_assign_op()
    if cop >= 0:
        self.advance()
        self.skip_newlines()
        let rhs = self.parse_expr()
        let bin = self.pool.add_node(NodeKind.NK_BINARY, self.pool.get_start(lhs), self.prev_end(), cop, lhs, rhs)
        return self.pool.add_node(NodeKind.NK_ASSIGN, self.pool.get_start(lhs), self.prev_end(), lhs, bin, 0)

    lhs

fn Parser.compound_assign_op(self: Parser) -> i32:
    let t = self.peek()
    if t == TokenKind.TK_PLUS_EQ: return BinaryOp.OP_ADD
    if t == TokenKind.TK_MINUS_EQ: return BinaryOp.OP_SUB
    if t == TokenKind.TK_STAR_EQ: return BinaryOp.OP_MUL
    if t == TokenKind.TK_SLASH_EQ: return BinaryOp.OP_DIV
    if t == TokenKind.TK_PERCENT_EQ: return BinaryOp.OP_MOD
    if t == TokenKind.TK_AMP_EQ: return BinaryOp.OP_BIT_AND
    if t == TokenKind.TK_PIPE_EQ: return BinaryOp.OP_BIT_OR
    if t == TokenKind.TK_CARET_EQ: return BinaryOp.OP_BIT_XOR
    if t == TokenKind.TK_LT_LT_EQ: return BinaryOp.OP_SHL
    if t == TokenKind.TK_GT_GT_EQ: return BinaryOp.OP_SHR
    if t == TokenKind.TK_PLUS_WRAP_EQ: return BinaryOp.OP_ADD_WRAP
    if t == TokenKind.TK_MINUS_WRAP_EQ: return BinaryOp.OP_SUB_WRAP
    if t == TokenKind.TK_STAR_WRAP_EQ: return BinaryOp.OP_MUL_WRAP
    if t == TokenKind.TK_PLUS_SAT_EQ: return BinaryOp.OP_ADD_SAT
    if t == TokenKind.TK_MINUS_SAT_EQ: return BinaryOp.OP_SUB_SAT
    if t == TokenKind.TK_STAR_SAT_EQ: return BinaryOp.OP_MUL_SAT
    -1

// ── Pratt precedence climbing ────────────────────────────────────

fn Parser.parse_precedence(self: Parser, min_prec: i32) -> NodeId:
    var lhs = self.parse_primary()
    if lhs == 0:
        return self.poisoned_expr()
    lhs = self.parse_postfix(lhs)

    while true:
        if self.peek() == TokenKind.TK_NEWLINE:
            let next = self.peek_past_newlines()
            if next == TokenKind.TK_PIPE_GT or next == TokenKind.TK_LT_PIPE or next == TokenKind.TK_QUESTION_QUESTION:
                self.skip_newlines()

        let info = self.infix_op()
        if info == 0:
            break
        let prec = info / 1000
        let op_code = info % 1000
        if prec < min_prec:
            break
        self.advance()

        // not in: consume second token
        if op_code == BinaryOp.OP_NOT_IN:
            self.advance()
        self.skip_newlines()

        // Pipeline into match
        if op_code == 500 and self.peek() == TokenKind.TK_KW_MATCH:
            self.advance()
            self.skip_newlines()
            let arm_count = self.parse_match_arms()
            let arms_start = if arm_count > 0: self.pool.extra_len() - arm_count else: self.pool.extra_len()
            lhs = self.pool.add_node(NodeKind.NK_MATCH, self.pool.get_start(lhs), self.prev_end(), lhs, arms_start, arm_count)
            continue

        let next_prec = if op_code == BinaryOp.OP_DEFAULT or op_code == 501: prec else: prec + 1
        let rhs = self.parse_precedence(next_prec)

        if op_code == 500:  // pipeline
            lhs = self.pool.add_node(NodeKind.NK_PIPELINE, self.pool.get_start(lhs), self.prev_end(), lhs, rhs, 0)
        else if op_code == 501:  // reverse pipeline
            lhs = self.pool.add_node(NodeKind.NK_PIPELINE, self.pool.get_start(lhs), self.prev_end(), rhs, lhs, 0)
        else if op_code == 504:  // backward compose <<
            lhs = self.build_composed_closure(lhs, rhs, 0)
        else if op_code == 505:  // forward compose >>
            lhs = self.build_composed_closure(lhs, rhs, 1)
        else if op_code == 502:  // range ..
            lhs = self.pool.add_node(NodeKind.NK_RANGE, self.pool.get_start(lhs), self.prev_end(), lhs, rhs, 0)
        else if op_code == 503:  // range ..=
            lhs = self.pool.add_node(NodeKind.NK_RANGE, self.pool.get_start(lhs), self.prev_end(), lhs, rhs, 1)
        else:
            lhs = self.pool.add_node(NodeKind.NK_BINARY, self.pool.get_start(lhs), self.prev_end(), op_code, lhs, rhs)
            // Chained comparisons: a < b < c → (a < b) and (b < c)
            if op_code >= BinaryOp.OP_LT and op_code <= BinaryOp.OP_GTE:
                var last_cmp = lhs  // track the latest comparison node
                var chain_info = self.infix_op()
                while chain_info != 0:
                    let chain_prec = chain_info / 1000
                    let chain_op = chain_info % 1000
                    if chain_op < BinaryOp.OP_LT or chain_op > BinaryOp.OP_GTE:
                        break
                    if chain_prec < min_prec:
                        break
                    // Extract shared operand (RHS of last comparison)
                    let shared = self.pool.get_data2(last_cmp)
                    // If shared is non-trivial, introduce a temporary
                    let shared_kind = self.pool.kind(shared)
                    var shared_ref: NodeId = shared as NodeId
                    var let_node: NodeId = 0 as NodeId
                    if shared_kind != NodeKind.NK_IDENT and shared_kind != NodeKind.NK_INT_LIT and shared_kind != NodeKind.NK_FLOAT_LIT and shared_kind != NodeKind.NK_BOOL_LIT:
                        let tmp_name = f"__chain_{self.pos}"
                        let tmp_sym = self.intern.intern(tmp_name)
                        let_node = self.pool.add_node(NodeKind.NK_LET_BINDING, self.pool.get_start(shared), self.pool.get_end(shared), tmp_sym, shared, 0)
                        shared_ref = self.pool.add_node(NodeKind.NK_IDENT, self.pool.get_start(shared), self.pool.get_end(shared), tmp_sym, 0, 0)
                        // Update previous comparison RHS to use the tmp
                        self.pool.set_data2(last_cmp, shared_ref)
                    self.advance()
                    self.skip_newlines()
                    let chain_rhs = self.parse_precedence(chain_prec + 1)
                    let new_cmp = self.pool.add_node(NodeKind.NK_BINARY, self.pool.get_start(shared_ref), self.prev_end(), chain_op, shared_ref, chain_rhs)
                    lhs = self.pool.add_node(NodeKind.NK_BINARY, self.pool.get_start(lhs), self.prev_end(), BinaryOp.OP_AND, lhs, new_cmp)
                    last_cmp = new_cmp
                    // Wrap in block with let binding if we introduced a temp
                    if let_node != 0:
                        let blk_extra = self.pool.extra_len()
                        self.pool.add_extra(let_node)
                        lhs = self.pool.add_node(NodeKind.NK_BLOCK, self.pool.get_start(lhs), self.prev_end(), blk_extra, 1, lhs)
                    chain_info = self.infix_op()

    lhs

// Returns encoded info: prec * 1000 + op_code, or 0 if not infix
fn Parser.infix_op(self: Parser) -> i32:
    let t = self.peek()
    if t == TokenKind.TK_KW_OR: return 1 * 1000 + BinaryOp.OP_OR
    if t == TokenKind.TK_KW_AND: return 2 * 1000 + BinaryOp.OP_AND
    if t == TokenKind.TK_EQ_EQ: return 3 * 1000 + BinaryOp.OP_EQ
    if t == TokenKind.TK_BANG_EQ: return 3 * 1000 + BinaryOp.OP_NEQ
    if t == TokenKind.TK_KW_IN: return 3 * 1000 + BinaryOp.OP_IN
    if t == TokenKind.TK_KW_NOT:
        if self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) == TokenKind.TK_KW_IN:
            return 3 * 1000 + BinaryOp.OP_NOT_IN
        return 0
    if t == TokenKind.TK_LT: return 4 * 1000 + BinaryOp.OP_LT
    if t == TokenKind.TK_GT: return 4 * 1000 + BinaryOp.OP_GT
    if t == TokenKind.TK_LT_EQ: return 4 * 1000 + BinaryOp.OP_LTE
    if t == TokenKind.TK_GT_EQ: return 4 * 1000 + BinaryOp.OP_GTE
    if t == TokenKind.TK_DOT_DOT: return 5 * 1000 + 502
    if t == TokenKind.TK_DOT_DOT_EQ: return 5 * 1000 + 503
    if t == TokenKind.TK_PIPE_GT: return 6 * 1000 + 500
    if t == TokenKind.TK_LT_PIPE: return 6 * 1000 + 501
    if t == TokenKind.TK_LT_LT: return 10 * 1000 + BinaryOp.OP_SHL
    if t == TokenKind.TK_GT_GT: return 10 * 1000 + BinaryOp.OP_SHR
    if t == TokenKind.TK_AMPERSAND: return 7 * 1000 + BinaryOp.OP_BIT_AND
    if t == TokenKind.TK_CARET: return 8 * 1000 + BinaryOp.OP_BIT_XOR
    if t == TokenKind.TK_PIPE: return 9 * 1000 + BinaryOp.OP_BIT_OR
    if t == TokenKind.TK_QUESTION_QUESTION: return 10 * 1000 + BinaryOp.OP_DEFAULT
    if t == TokenKind.TK_PLUS: return 11 * 1000 + BinaryOp.OP_ADD
    if t == TokenKind.TK_PLUS_PLUS: return 11 * 1000 + BinaryOp.OP_CONCAT
    if t == TokenKind.TK_MINUS: return 11 * 1000 + BinaryOp.OP_SUB
    if t == TokenKind.TK_PLUS_WRAP: return 11 * 1000 + BinaryOp.OP_ADD_WRAP
    if t == TokenKind.TK_MINUS_WRAP: return 11 * 1000 + BinaryOp.OP_SUB_WRAP
    if t == TokenKind.TK_PLUS_SAT: return 11 * 1000 + BinaryOp.OP_ADD_SAT
    if t == TokenKind.TK_MINUS_SAT: return 11 * 1000 + BinaryOp.OP_SUB_SAT
    if t == TokenKind.TK_STAR: return 12 * 1000 + BinaryOp.OP_MUL
    if t == TokenKind.TK_SLASH: return 12 * 1000 + BinaryOp.OP_DIV
    if t == TokenKind.TK_PERCENT: return 12 * 1000 + BinaryOp.OP_MOD
    if t == TokenKind.TK_STAR_WRAP: return 12 * 1000 + BinaryOp.OP_MUL_WRAP
    if t == TokenKind.TK_STAR_SAT: return 12 * 1000 + BinaryOp.OP_MUL_SAT
    // @ operator for matmul — distinguish from @[annotation] by checking next token
    if t == TokenKind.TK_AT:
        if self.pos + 1 < self.tokens.len():
            if self.tokens.get_tag(self.pos + 1) != TokenKind.TK_L_BRACKET:
                return 12 * 1000 + BinaryOp.OP_MATMUL
    0

// ── Primary expression ──────────────────────────────────────────

fn Parser.parse_primary(self: Parser) -> NodeId:
    let t = self.peek()
    if t == TokenKind.TK_INT_LIT: return self.parse_int_literal()
    if t == TokenKind.TK_FLOAT_LIT: return self.parse_float_literal()
    if t == TokenKind.TK_STRING_LIT: return self.parse_string_literal()
    if t == TokenKind.TK_C_STRING_LIT: return self.parse_c_string_literal()
    if t == TokenKind.TK_CHAR_LIT: return self.parse_char_literal()
    if t == TokenKind.TK_TRUE or t == TokenKind.TK_FALSE: return self.parse_bool_literal()
    if t == TokenKind.TK_KW_NULL:
        let ns = self.current_start()
        let ne = self.current_end()
        self.advance()
        return self.pool.add_node(NodeKind.NK_NULL_LIT, ns, ne, 0, 0, 0)
    if t == TokenKind.TK_IDENT:
        // comptime_error("msg") → NodeKind.NK_COMPTIME_ERROR
        if self.is_ident_named("comptime_error"):
            return self.parse_comptime_error_expr()
        if self.suppress_fat_arrow_closure == 0 and self.pos + 1 < self.tokens.len():
            if self.tokens.get_tag(self.pos + 1) == TokenKind.TK_FAT_ARROW:
                return self.parse_fat_arrow_single()
        return self.parse_ident_or_call()
    if t == TokenKind.TK_KW_IT:
        let start = self.current_start()
        let end_pos = self.current_end()
        self.advance()
        if self.implicit_it_depth > 0:
            let err_span = Span { file: self.file_id, start: start, end: end_pos }
            self.diags.emit(Diagnostic.err("nested implicit closure is ambiguous; use explicit parameter for inner closure", err_span))
        self.saw_implicit_it = 1
        self.implicit_it_depth = self.implicit_it_depth + 1
        let sym = self.intern.intern("__it")
        let node = self.pool.add_node(NodeKind.NK_IDENT, start, end_pos, sym, 0, 0)
        return self.parse_postfix(node)
    if t == TokenKind.TK_DOT_IDENT: return self.parse_variant_shorthand()
    if t == TokenKind.TK_L_PAREN: return self.parse_grouped_or_tuple()
    if t == TokenKind.TK_MINUS: return self.parse_unary_negate()
    if t == TokenKind.TK_TILDE: return self.parse_unary_bit_not()
    if t == TokenKind.TK_KW_NOT: return self.parse_unary_not()
    if t == TokenKind.TK_AMPERSAND: return self.parse_ref_of()
    if t == TokenKind.TK_STAR: return self.parse_deref_expr()
    if t == TokenKind.TK_KW_IF: return self.parse_if_expr()
    if t == TokenKind.TK_KW_WHILE: return self.parse_while(0)
    if t == TokenKind.TK_KW_LOOP: return self.parse_loop(0)
    if t == TokenKind.TK_KW_FOR: return self.parse_for(0)
    if t == TokenKind.TK_KW_RETURN: return self.parse_return()
    if t == TokenKind.TK_KW_BREAK: return self.parse_break()
    if t == TokenKind.TK_KW_CONTINUE: return self.parse_continue()
    if t == TokenKind.TK_KW_GOTO: return self.parse_goto()
    if t == TokenKind.TK_LABEL: return self.parse_labeled_statement()
    if t == TokenKind.TK_KW_UNSAFE: return self.parse_unsafe()
    if t == TokenKind.TK_KW_ASM: return self.parse_asm_expr()
    if t == TokenKind.TK_KW_DEFER: return self.parse_defer()
    if t == TokenKind.TK_KW_ERRDEFER: return self.parse_errdefer()
    if t == TokenKind.TK_KW_SPAWN: return self.parse_spawn()
    if t == TokenKind.TK_KW_ASYNC: return self.parse_async_expr()
    if t == TokenKind.TK_KW_YIELD: return self.parse_yield()
    if t == TokenKind.TK_KW_COMPTIME: return self.parse_comptime_expr()
    if t == TokenKind.TK_KW_SELECT: return self.parse_select_await()
    if t == TokenKind.TK_L_BRACKET:
        let arr = self.parse_array_literal()
        return self.parse_postfix(arr)
    if t == TokenKind.TK_KW_LET or t == TokenKind.TK_KW_VAR: return self.parse_let_binding()
    if t == TokenKind.TK_KW_CONST: return self.parse_const_binding()
    if t == TokenKind.TK_KW_MATCH: return self.parse_match_expr()
    if t == TokenKind.TK_KW_WITH: return self.parse_with_expr()
    if t == TokenKind.TK_L_BRACE: return self.parse_record_update()
    if t == TokenKind.TK_PIPE:
        self.emit_error("use 'x => body' instead of '|x| body'")
        self.advance()
        return self.poisoned_expr()
    if t == TokenKind.TK_KW_MOVE:
        self.advance()
        // move IDENT => expr
        if self.peek() == TokenKind.TK_IDENT:
            if self.pos + 1 < self.tokens.len():
                if self.tokens.get_tag(self.pos + 1) == TokenKind.TK_FAT_ARROW:
                    let node = self.parse_fat_arrow_single()
                    if node != 0: self.pool.mark_move_closure(node)
                    return node
        // move (params) => expr
        if self.peek() == TokenKind.TK_L_PAREN:
            let save = self.pos
            self.advance()
            self.skip_newlines()
            var is_closure = 0
            if self.peek() == TokenKind.TK_R_PAREN:
                self.advance()
                if self.peek() == TokenKind.TK_FAT_ARROW or self.peek() == TokenKind.TK_ARROW:
                    is_closure = 1
            else:
                is_closure = self.scan_is_paren_closure()
            self.pos = save
            if is_closure == 1:
                let node = self.parse_fat_arrow_paren_closure()
                if node != 0: self.pool.mark_move_closure(node)
                return node
        self.emit_error("'move' must be followed by a closure")
        return self.poisoned_expr()

    self.emit_error("expected expression")
    // Skip to next statement boundary for recovery
    self.recover_to_statement()
    self.poisoned_expr()

// ── Literal parsing ─────────────────────────────────────────────

fn numeric_literal_suffix_start(text: str, suffix: str) -> i32:
    let len = text.len() as i32
    let slen = suffix.len() as i32
    if len <= slen:
        return 0 - 1
    let direct_start = len - slen
    if text.slice(direct_start as i64, len as i64) == suffix:
        return direct_start
    if len > slen + 1 and text.byte_at((len - slen - 1) as i64) == 95:
        let legacy_start = len - slen - 1
        if text.slice((legacy_start + 1) as i64, len as i64) == suffix:
            return legacy_start
    0 - 1

fn numeric_literal_suffix_code(text: str) -> i32:
    if numeric_literal_suffix_start(text, "usize") >= 0: return LiteralSuffix.Usize
    if numeric_literal_suffix_start(text, "isize") >= 0: return LiteralSuffix.Isize
    if numeric_literal_suffix_start(text, "u128") >= 0: return LiteralSuffix.U128
    if numeric_literal_suffix_start(text, "i128") >= 0: return LiteralSuffix.I128
    if numeric_literal_suffix_start(text, "u64") >= 0: return LiteralSuffix.U64
    if numeric_literal_suffix_start(text, "i64") >= 0: return LiteralSuffix.I64
    if numeric_literal_suffix_start(text, "u32") >= 0: return LiteralSuffix.U32
    if numeric_literal_suffix_start(text, "i32") >= 0: return LiteralSuffix.I32
    if numeric_literal_suffix_start(text, "u16") >= 0: return LiteralSuffix.U16
    if numeric_literal_suffix_start(text, "i16") >= 0: return LiteralSuffix.I16
    if numeric_literal_suffix_start(text, "u8") >= 0: return LiteralSuffix.U8
    if numeric_literal_suffix_start(text, "i8") >= 0: return LiteralSuffix.I8
    if numeric_literal_suffix_start(text, "f64") >= 0: return LiteralSuffix.F64
    if numeric_literal_suffix_start(text, "f32") >= 0: return LiteralSuffix.F32
    LiteralSuffix.None

fn numeric_literal_core(text: str) -> str:
    let suffix = numeric_literal_suffix_code(text)
    if suffix == LiteralSuffix.None:
        return text
    if suffix == LiteralSuffix.Usize:
        return text.slice(0, numeric_literal_suffix_start(text, "usize") as i64)
    if suffix == LiteralSuffix.Isize:
        return text.slice(0, numeric_literal_suffix_start(text, "isize") as i64)
    if suffix == LiteralSuffix.U128:
        return text.slice(0, numeric_literal_suffix_start(text, "u128") as i64)
    if suffix == LiteralSuffix.I128:
        return text.slice(0, numeric_literal_suffix_start(text, "i128") as i64)
    if suffix == LiteralSuffix.U64:
        return text.slice(0, numeric_literal_suffix_start(text, "u64") as i64)
    if suffix == LiteralSuffix.I64:
        return text.slice(0, numeric_literal_suffix_start(text, "i64") as i64)
    if suffix == LiteralSuffix.U32:
        return text.slice(0, numeric_literal_suffix_start(text, "u32") as i64)
    if suffix == LiteralSuffix.I32:
        return text.slice(0, numeric_literal_suffix_start(text, "i32") as i64)
    if suffix == LiteralSuffix.U16:
        return text.slice(0, numeric_literal_suffix_start(text, "u16") as i64)
    if suffix == LiteralSuffix.I16:
        return text.slice(0, numeric_literal_suffix_start(text, "i16") as i64)
    if suffix == LiteralSuffix.U8:
        return text.slice(0, numeric_literal_suffix_start(text, "u8") as i64)
    if suffix == LiteralSuffix.I8:
        return text.slice(0, numeric_literal_suffix_start(text, "i8") as i64)
    if suffix == LiteralSuffix.F64:
        return text.slice(0, numeric_literal_suffix_start(text, "f64") as i64)
    if suffix == LiteralSuffix.F32:
        return text.slice(0, numeric_literal_suffix_start(text, "f32") as i64)
    text

fn int_literal_core_radix(core: str) -> i32:
    if core.len() > 2 and core.byte_at(0) == 48 and (core.byte_at(1) == 120 or core.byte_at(1) == 88):
        return 16
    if core.len() > 2 and core.byte_at(0) == 48 and (core.byte_at(1) == 98 or core.byte_at(1) == 66):
        return 2
    if core.len() > 2 and core.byte_at(0) == 48 and (core.byte_at(1) == 111 or core.byte_at(1) == 79):
        return 8
    10

fn int_literal_core_digit_start(core: str) -> i32:
    let radix = int_literal_core_radix(core)
    if radix == 10:
        return 0
    2

fn normalize_int_literal_digits(core: str) -> str:
    let len = core.len() as i32
    let start = int_literal_core_digit_start(core)
    var digits = ""
    var i = start
    while i < len:
        let ch = core.byte_at(i as i64)
        if ch != 95:
            digits = digits ++ str_from_byte(ch)
        i = i + 1
    digits

fn int_literal_fast_i64(core: str) -> ExactIntI64:
    let digits = normalize_int_literal_digits(core)
    exact_int_try_i64(exact_int_parse_digits(digits, int_literal_core_radix(core)))

fn Parser.build_int_literal_node(self: Parser, start: i32, end: i32, text: str) -> NodeId:
    let suffix = numeric_literal_suffix_code(text)
    let core = numeric_literal_core(text)
    let digits = normalize_int_literal_digits(core)
    let radix = int_literal_core_radix(core)
    let fast = exact_int_try_i64(exact_int_parse_digits(digits, radix))
    let node = self.pool.add_node(
        NodeKind.NK_INT_LIT,
        start,
        end,
        ast_int_part0(if fast.ok != 0: fast.value else: 0),
        ast_int_part1(if fast.ok != 0: fast.value else: 0),
        ast_int_part2(if fast.ok != 0: fast.value else: 0)
    )
    self.pool.set_literal_suffix(node, suffix)
    self.pool.set_int_literal_exact(node, self.pool.add_string(digits), radix)
    node

fn Parser.parse_int_literal(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    self.advance()
    self.build_int_literal_node(start, end, text)

fn Parser.parse_float_literal(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    let suffix = numeric_literal_suffix_code(text)
    let core = numeric_literal_core(text)
    self.advance()
    let str_idx = self.pool.add_string(core)
    let node = self.pool.add_node(NodeKind.NK_FLOAT_LIT, start, end, str_idx, 0, 0)
    self.pool.set_literal_suffix(node, suffix)
    node

fn Parser.parse_comptime_error_expr(self: Parser) -> NodeId:
    let ce_s = self.current_start()
    self.advance()
    self.advance()
    let ce_msg = self.intern_current()
    self.advance()
    if self.peek() == TokenKind.TK_R_PAREN:
        self.advance()
    self.pool.add_node(NodeKind.NK_COMPTIME_ERROR, ce_s, self.prev_end(), ce_msg, 0, 0)

fn Parser.parse_string_literal(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    var content = strip_string_token_text(text)
    if is_raw_string_token_text(text):
        content = "\x01raw\x01" ++ content
        let sym = self.intern.intern(content)
        self.advance()
        let node = self.pool.add_node(NodeKind.NK_STRING_LIT, start, end, sym, 0, 0)
        return self.parse_postfix(node)
    // f"..." prefix triggers string interpolation
    if is_fstring_token_text(text):
        self.advance()
        return self.desugar_interpolated_string(content, start, end)
    let sym = self.intern.intern(content)
    self.advance()
    let node = self.pool.add_node(NodeKind.NK_STRING_LIT, start, end, sym, 0, 0)
    return self.parse_postfix(node)

fn Parser.desugar_interpolated_string(self: Parser, content: str, start: i32, end: i32) -> NodeId:
    // Emit NodeKind.NK_FSTRING with segments in extra_data.
    // d0 = segment_count, d1 = extra_start, d2 = 0
    //
    // IMPORTANT: Parse all expression sub-parsers FIRST, collecting their
    // node indices. Then write all segment data contiguously to the extra
    // pool. This avoids interleaving sub-parser extra data with segment
    // records (sub-parsers may add to the extra pool during parse_expr).
    let clen = content.len() as i32

    // Phase 1: Scan content, parse expressions, collect segment info.
    // seg_kinds: 0=literal, 1=expr
    // seg_data1: sym (literal) or expr_node (expr)
    // seg_data2: 0 (literal) or spec_node (expr)
    let seg_kinds: Vec[i32] = Vec.new()
    let seg_data1: Vec[i32] = Vec.new()
    let seg_data2: Vec[i32] = Vec.new()
    var seg_start = 0
    var i = 0
    while i < clen:
        let ch = content.byte_at(i as i64)
        if ch == 123:  // {
            // Check for {{ (escaped brace → literal {)
            if i + 1 < clen and content.byte_at((i + 1) as i64) == 123:
                i = i + 2
                continue
            // Check for \{ (backslash-escaped brace → literal {)
            if i > 0 and content.byte_at((i - 1) as i64) == 92:
                i = i + 1
                continue
            // Collect text segment before the {
            if i > seg_start:
                let seg_text = self.interp_clean_segment(content, seg_start, i)
                let sym = self.intern.intern(seg_text)
                seg_kinds.push(FStringSegmentKind.LITERAL)
                seg_data1.push(sym)
                seg_data2.push(0)
            // Find matching }. Track the first top-level colon as a fallback
            // format-spec split point, but give the whole hole expression
            // precedence later so constructs like `unsafe: *p` parse as real
            // expressions instead of being mistaken for `{expr:spec}`.
            var depth = 1
            var expr_start_pos = i + 1
            var j = expr_start_pos
            var colon_pos = -1
            var in_string = false
            var in_char = false
            while j < clen and depth > 0:
                let jch = content.byte_at(j as i64)
                if in_string:
                    if jch == 92:
                        let bs_start = j
                        while j < clen and content.byte_at(j as i64) == 92:
                            j = j + 1
                        if j < clen and content.byte_at(j as i64) == 34:
                            let src_bs = interp_quote_source_backslash_count(j - bs_start)
                            if src_bs % 2 == 0:
                                in_string = false
                            j = j + 1
                            continue
                        continue
                    j = j + 1
                    continue
                if in_char:
                    if jch == 92 and j + 1 < clen:
                        j = j + 2
                        continue
                    if jch == 39:
                        in_char = false
                    j = j + 1
                    continue
                if jch == 92:
                    let bs_start = j
                    while j < clen and content.byte_at(j as i64) == 92:
                        j = j + 1
                    if j < clen and content.byte_at(j as i64) == 34:
                        let src_bs = interp_quote_source_backslash_count(j - bs_start)
                        if src_bs == 0:
                            in_string = true
                        j = j + 1
                        continue
                    continue
                if jch == 39:
                    in_char = true
                    j = j + 1
                    continue
                if jch == 123: depth = depth + 1
                if jch == 125: depth = depth - 1
                if depth == 1 and jch == 58 and colon_pos == -1:
                    colon_pos = j
                if depth > 0: j = j + 1
            var spec_node: NodeId = 0 as NodeId
            let hole_text = content.slice(expr_start_pos as i64, j as i64)
            var expr_node: NodeId = 0 as NodeId
            if colon_pos > 0:
                // Parse the full hole first. Only fall back to `{expr:spec}`
                // splitting when the full text is not a complete expression.
                let full_attempt = self.parse_interpolated_expr_attempt(hole_text, 0)
                self.intern = full_attempt.intern
                self.pool = full_attempt.pool
                if full_attempt.consumed_all != 0 and full_attempt.had_errors == 0:
                    expr_node = full_attempt.node
                else:
                    let expr_text = content.slice(expr_start_pos as i64, colon_pos as i64)
                    expr_node = self.parse_interpolated_expr(expr_text, start)
                    let spec_text = content.slice((colon_pos + 1) as i64, j as i64)
                    spec_node = self.parse_format_spec_text(spec_text, start, end)
            else:
                expr_node = self.parse_interpolated_expr(hole_text, start)
            seg_kinds.push(FStringSegmentKind.EXPR)
            seg_data1.push(expr_node as i32)
            seg_data2.push(spec_node as i32)
            i = j + 1
            seg_start = i
        else if ch == 125 and i + 1 < clen and content.byte_at((i + 1) as i64) == 125:
            i = i + 2
            continue
        else:
            i = i + 1
    // Collect trailing text segment
    if seg_start < clen:
        let seg_text = self.interp_clean_segment(content, seg_start, clen)
        let sym = self.intern.intern(seg_text)
        seg_kinds.push(FStringSegmentKind.LITERAL)
        seg_data1.push(sym)
        seg_data2.push(0)
    // Handle empty f-string
    if seg_kinds.len() == 0:
        let sym = self.intern.intern("")
        seg_kinds.push(FStringSegmentKind.LITERAL)
        seg_data1.push(sym)
        seg_data2.push(0)

    // Phase 2: Write all segment records contiguously to extra pool.
    let extra_start = self.pool.extra_len()
    let seg_count = seg_kinds.len() as i32
    for si in 0..seg_count:
        let kind = seg_kinds.get(si as i64)
        if kind == FStringSegmentKind.LITERAL:
            self.pool.add_extra(FStringSegmentKind.LITERAL)
            self.pool.add_extra(seg_data1.get(si as i64))
        else:
            self.pool.add_extra(FStringSegmentKind.EXPR)
            self.pool.add_extra(seg_data1.get(si as i64))
            self.pool.add_extra(seg_data2.get(si as i64))

    let node = self.pool.add_node(NodeKind.NK_FSTRING, start, end, seg_count, extra_start, 0)
    self.parse_postfix(node)

fn interp_brace_char(code: i32) -> str:
    str_from_byte(code)

fn interp_quote_source_backslash_count(raw_backslashes: i32) -> i32:
    raw_backslashes / 2

fn Parser.interp_normalize_expr_text(self: Parser, text: str) -> str:
    // Re-lexed f-string hole expressions still contain the outer string's
    // escape layer. Strip that layer so holes like {id(\"x\")} reparse as
    // the user expression id("x"), and inner string escapes like \\ become
    // the original source-level backslashes again.
    var out = ""
    let len = text.len() as i32
    var i = 0
    while i < len:
        if text.byte_at(i as i64) == 92:
            if i + 1 < len:
                out = out ++ text.slice((i + 1) as i64, (i + 2) as i64)
                i = i + 2
                continue
            out = out ++ interp_brace_char(92)
            i = i + 1
            continue
        out = out ++ text.slice(i as i64, (i + 1) as i64)
        i = i + 1
    out

fn Parser.interp_clean_segment(self: Parser, content: str, from: i32, to: i32) -> str:
    // Replace {{ → { and }} → } in literal segments (Python-style brace escaping).
    var out = ""
    var i = from
    while i < to:
        let ch = content.byte_at(i as i64)
        if ch == 123 and i + 1 < to and content.byte_at((i + 1) as i64) == 123:
            out = out ++ interp_brace_char(123)
            i = i + 2
            continue
        if ch == 125 and i + 1 < to and content.byte_at((i + 1) as i64) == 125:
            out = out ++ interp_brace_char(125)
            i = i + 2
            continue
        out = out ++ content.slice(i as i64, (i + 1) as i64)
        i = i + 1
    out

fn Parser.parse_format_spec_text(self: Parser, spec_text: str, start: i32, end: i32) -> NodeId:
    // Parse format spec grammar: [[fill]align][sign]['#']['0'][width]['.' precision][mode]
    // Returns NodeKind.NK_FSTRING_SPEC node, or 0 if empty
    let slen = spec_text.len() as i32
    if slen == 0:
        return self.poisoned_expr()
    var fill: i32 = 32  // space
    var align: i32 = 0  // 0=default, 1=left, 2=right, 3=center
    var sign_plus: i32 = 0
    var alternate: i32 = 0
    var zero_pad: i32 = 0
    var width: i32 = 0
    var precision: i32 = -1
    var mode: i32 = 0
    var pos = 0
    // Check for [fill]align: if pos+1 < slen and char[pos+1] is <, >, ^
    if pos + 1 < slen:
        let next_ch = spec_text.byte_at((pos + 1) as i64)
        if next_ch == 60 or next_ch == 62 or next_ch == 94:  // <, >, ^
            fill = spec_text.byte_at(pos as i64) as i32
            if next_ch == 60: align = 1
            else if next_ch == 62: align = 2
            else: align = 3
            pos = pos + 2
    // Check for bare align: <, >, ^
    if align == 0 and pos < slen:
        let ch = spec_text.byte_at(pos as i64)
        if ch == 60:
            align = 1
            pos = pos + 1
        else if ch == 62:
            align = 2
            pos = pos + 1
        else if ch == 94:
            align = 3
            pos = pos + 1
    // Sign: + or -
    if pos < slen:
        let ch = spec_text.byte_at(pos as i64)
        if ch == 43:
            sign_plus = 1
            pos = pos + 1
        else if ch == 45:
            pos = pos + 1
    // Alternate: #
    if pos < slen and spec_text.byte_at(pos as i64) == 35:
        alternate = 1
        pos = pos + 1
    // Zero-pad: 0 (only if followed by digit for width, or is the only remaining char)
    if pos < slen and spec_text.byte_at(pos as i64) == 48:
        // 0 is zero-pad if next char is a digit or end of spec or mode letter
        if pos + 1 >= slen or (spec_text.byte_at((pos + 1) as i64) >= 48 and spec_text.byte_at((pos + 1) as i64) <= 57) or spec_text.byte_at((pos + 1) as i64) == 46:
            zero_pad = 1
            pos = pos + 1
    // Width: digits
    while pos < slen and spec_text.byte_at(pos as i64) >= 48 and spec_text.byte_at(pos as i64) <= 57:
        width = width * 10 + (spec_text.byte_at(pos as i64) as i32 - 48)
        pos = pos + 1
    // Precision: . then digits
    if pos < slen and spec_text.byte_at(pos as i64) == 46:
        pos = pos + 1
        precision = 0
        while pos < slen and spec_text.byte_at(pos as i64) >= 48 and spec_text.byte_at(pos as i64) <= 57:
            precision = precision * 10 + (spec_text.byte_at(pos as i64) as i32 - 48)
            pos = pos + 1
    // Mode: single letter at end
    if pos < slen:
        let ch = spec_text.byte_at(pos as i64) as i32
        // Valid modes: d, x, X, b, o, f, e, g, s, ?
        if ch == 100 or ch == 120 or ch == 88 or ch == 98 or ch == 111 or ch == 102 or ch == 101 or ch == 103 or ch == 115 or ch == 63:
            mode = ch
            pos = pos + 1
    // Pack flags into d0: mode(0-7), fill(8-15), align(16-17), sign_plus(18), alternate(19), zero_pad(20)
    let flags = mode | ((fill & 255) << 8) | ((align & 3) << 16) | ((sign_plus & 1) << 18) | ((alternate & 1) << 19) | ((zero_pad & 1) << 20)
    self.pool.add_node(NodeKind.NK_FSTRING_SPEC, start, end, flags, width, precision)

fn Parser.parse_interpolated_expr(self: Parser, expr_text: str, base_start: i32) -> NodeId:
    let attempt = self.parse_interpolated_expr_attempt(expr_text, 1)
    self.intern = attempt.intern
    self.pool = attempt.pool
    attempt.node

fn Parser.parse_interpolated_expr_attempt(self: Parser, expr_text: str, use_shared_diags: i32) -> InterpolatedExprParseAttempt:
    // Re-lex and parse the expression text.
    let source_text = self.interp_normalize_expr_text(expr_text)
    var lexer = Lexer.init(source_text, 0)
    let tokens = lexer.tokenize()
    let local_diags = DiagnosticList.init()
    let parse_diags = if use_shared_diags != 0: self.diags else: local_diags
    var sub_parser = Parser.init_with_pool(tokens, source_text, 0, self.intern, parse_diags, self.pool)
    let result = sub_parser.parse_expr()
    sub_parser.skip_newlines()
    let consumed_all = if sub_parser.peek() == TokenKind.TK_EOF: 1 else: 0
    let had_errors = if use_shared_diags != 0: 0 else if local_diags.has_errors(): 1 else: 0
    InterpolatedExprParseAttempt {
        node: result,
        consumed_all,
        had_errors,
        pool: sub_parser.pool,
        intern: sub_parser.intern,
    }

fn Parser.parse_c_string_literal(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    var raw = ""
    if text.len() >= 3:
        raw = text.slice(2, text.len() as i64 - 1)
    let sym = self.intern.intern(raw)
    self.advance()
    let node = self.pool.add_node(NodeKind.NK_C_STRING_LIT, start, end, sym, 0, 0)
    self.parse_postfix(node)

fn Parser.parse_bool_literal(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let val = if self.peek() == TokenKind.TK_TRUE: 1 else: 0
    self.advance()
    self.pool.add_node(NodeKind.NK_BOOL_LIT, start, end, val, 0, 0)

fn Parser.parse_char_literal(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    self.advance()
    // Stage0 parity: char literals lower to integer literals.
    // Supported escapes mirror bootstrap parser behavior.
    var value = 0
    // Support b'X' byte literals as a char-literal token form.
    let base = if text.len() >= 1 and text.byte_at(0 as i64) == 98: 2 else: 1
    if text.len() >= base + 3 and text.byte_at(base as i64) == 92:  // '\'
        let esc = text.byte_at((base + 1) as i64)
        if esc == 110:  // n
            value = 10
        else if esc == 114:  // r
            value = 13
        else if esc == 116:  // t
            value = 9
        else if esc == 48:  // 0
            value = 0
        else if esc == 120 and text.len() >= base + 4:  // xNN
            let hi = hex_digit_value(text.byte_at((base + 2) as i64))
            let lo = if text.len() >= base + 5: hex_digit_value(text.byte_at((base + 3) as i64)) else: -1
            if hi >= 0 and lo >= 0:
                value = hi * 16 + lo
            else:
                value = 0
        else if esc == 92:  // \
            value = 92
        else if esc == 39:  // '
            value = 39
        else if esc == 34:  // "
            value = 34
        else:
            value = esc as i32
    else if text.len() >= base + 2:
        value = text.byte_at(base as i64) as i32
    let value64 = value as i64
    self.pool.add_node(NodeKind.NK_INT_LIT, start, end, ast_int_part0(value64), ast_int_part1(value64), ast_int_part2(value64))

fn strip_string_token_text(text: str) -> str:
    // f"..." → content between f" and closing "
    if text.len() >= 3 and text.byte_at(0) == 102 and text.byte_at(1) == 34:  // f"
        return text.slice(2, text.len() as i64 - 1)
    if text.len() >= 2 and text.byte_at(0 as i64) == 114:  // r
        var i = 1
        while i < text.len() as i32 and text.byte_at(i as i64) == 35:  // #
            i = i + 1
        if i < text.len() as i32 and text.byte_at(i as i64) == 34:  // opening "
            let content_start = i + 1
            var end_q = text.len() as i32 - 1
            while end_q >= content_start and text.byte_at(end_q as i64) == 35:
                end_q = end_q - 1
            if end_q >= content_start and text.byte_at(end_q as i64) == 34:
                return text.slice(content_start as i64, end_q as i64)

    if text.len() >= 6 and text.slice(0, 3) == "\"\"\"":
        var content = text.slice(3, text.len() as i64 - 3)
        if content.len() > 0 and content.byte_at(0 as i64) == 10:
            content = content.slice(1, content.len())
        if content.len() > 0 and content.byte_at((content.len() as i32 - 1) as i64) == 10:
            content = content.slice(0, content.len() - 1)
        return dedent_multiline(content)

    if text.len() >= 2:
        return text.slice(1, text.len() as i64 - 1)
    ""

fn is_fstring_token_text(text: str) -> bool:
    if text.len() < 3:
        return false
    text.byte_at(0) == 102 and text.byte_at(1) == 34  // f"

fn is_raw_string_token_text(text: str) -> bool:
    if text.len() < 3:
        return false
    if text.byte_at(0 as i64) != 114:  // r
        return false
    var i = 1
    while i < text.len() as i32 and text.byte_at(i as i64) == 35:  // #
        i = i + 1
    if i < text.len() as i32 and text.byte_at(i as i64) == 34:  // "
        return true
    false

fn dedent_multiline(text: str) -> str:
    let len = text.len() as i32
    var min_indent = 0 - 1
    var line_start = 0
    var i = 0
    while i <= len:
        if i == len or text.byte_at(i as i64) == 10:
            var j = line_start
            while j < i and (text.byte_at(j as i64) == 32 or text.byte_at(j as i64) == 9):
                j = j + 1
            var has_non_ws = 0
            var k = j
            while k < i:
                if text.byte_at(k as i64) != 32 and text.byte_at(k as i64) != 9:
                    has_non_ws = 1
                k = k + 1
            if has_non_ws != 0:
                let indent = j - line_start
                if min_indent < 0 or indent < min_indent:
                    min_indent = indent
            line_start = i + 1
        i = i + 1

    if min_indent <= 0:
        return text

    var out = ""
    line_start = 0
    i = 0
    while i <= len:
        if i == len or text.byte_at(i as i64) == 10:
            var cut = min_indent
            var j = line_start
            while cut > 0 and j < i and (text.byte_at(j as i64) == 32 or text.byte_at(j as i64) == 9):
                j = j + 1
                cut = cut - 1
            out = out ++ text.slice(j as i64, i as i64)
            if i != len:
                out = out ++ "\n"
            line_start = i + 1
        i = i + 1
    out

fn hex_digit_value(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 97 and ch <= 102:
        return ch - 87
    if ch >= 65 and ch <= 70:
        return ch - 55
    0 - 1

fn Parser.parse_ident_or_call(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let sym = self.intern_current()
    self.advance()
    let node = self.pool.add_node(NodeKind.NK_IDENT, start, end, sym, 0, 0)
    self.parse_postfix(node)

// ── Postfix parsing ──────────────────────────────────────────────

fn Parser.parse_postfix(self: Parser, lhs_in: i32) -> NodeId:
    var lhs: NodeId = lhs_in as NodeId
    while true:
        let t = self.peek()
        if t == TokenKind.TK_L_PAREN:
            lhs = self.parse_call(lhs)
        else if t == TokenKind.TK_DOT:
            lhs = self.parse_dot(lhs)
        else if t == TokenKind.TK_DOT_IDENT:
            // Type.Variant — treat dot-ident as field access when postfix
            let start = self.current_start()
            let end = self.current_end()
            let text = self.source.slice((start + 1) as i64, end as i64)
            let field = self.intern.intern(text)
            self.advance()
            lhs = self.pool.add_node(NodeKind.NK_FIELD_ACCESS, self.pool.get_start(lhs), end, lhs, field, 0)
        else if t == TokenKind.TK_L_BRACE:
            if self.suppress_brace != 0:
                return lhs
            if self.pool.kind(lhs) != NodeKind.NK_IDENT:
                return lhs
            lhs = self.parse_struct_literal(lhs)
        else if t == TokenKind.TK_COLON:
            if self.suppress_brace != 0:
                return lhs
            if self.pool.kind(lhs) != NodeKind.NK_IDENT:
                return lhs
            if self.pos + 1 >= self.tokens.len():
                return lhs
            if self.tokens.get_tag(self.pos + 1) != TokenKind.TK_NEWLINE:
                return lhs
            lhs = self.parse_block_struct_literal(lhs)
        else if t == TokenKind.TK_L_BRACKET:
            lhs = self.parse_index_or_slice(lhs)
        else if t == TokenKind.TK_KW_AS:
            if self.suppress_as != 0:
                return lhs
            self.advance()
            let target_type = self.parse_type_expr()
            lhs = self.pool.add_node(NodeKind.NK_CAST, self.pool.get_start(lhs), self.prev_end(), lhs, target_type, 0)
        else if t == TokenKind.TK_QUESTION:
            let qend = self.current_end()
            self.advance()
            lhs = self.pool.add_node(NodeKind.NK_UNARY, self.pool.get_start(lhs), qend, UnaryOp.UOP_TRY, lhs, 0)
        else if t == TokenKind.TK_QUESTION_DOT:
            lhs = self.parse_optional_chain(lhs)
        else:
            return lhs
    lhs

fn Parser.maybe_wrap_implicit_it(self: Parser, expr: i32) -> NodeId:
    let it_sym = self.intern.intern("__it")
    let param_start = self.pool.extra_len()
    self.pool.add_extra(it_sym)
    self.pool.add_extra(0)
    self.pool.add_node(NodeKind.NK_CLOSURE, self.pool.get_start(expr), self.pool.get_end(expr), expr, param_start, 1)

fn Parser.parse_call(self: Parser, callee: i32) -> NodeId:
    self.advance()  // consume (
    let saved_suppress_brace = self.suppress_brace
    self.suppress_brace = 0
    self.skip_newlines()
    var args: Vec[i32] = Vec.new()
    var arg_names: Vec[i32] = Vec.new()  // 0 = positional, sym = named
    var has_named = 0
    var seen_named = 0
    if self.peek() != TokenKind.TK_R_PAREN:
        while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
            // Named argument: name: value
            var arg_name_sym = 0
            if self.peek() == TokenKind.TK_IDENT:
                let save = self.pos
                let name_sym = self.intern_current()
                self.advance()
                if self.peek() == TokenKind.TK_COLON:
                    self.advance()
                    self.skip_newlines()
                    arg_name_sym = name_sym
                    has_named = 1
                    seen_named = 1
                else:
                    self.pos = save
            if arg_name_sym == 0 and seen_named == 1:
                self.emit_error("positional argument cannot follow named argument")
            arg_names.push(arg_name_sym)
            let outer_it = self.saw_implicit_it
            let outer_depth = self.implicit_it_depth
            self.saw_implicit_it = 0
            var arg = self.parse_expr()
            if self.saw_implicit_it == 1:
                self.implicit_it_depth = self.implicit_it_depth - 1
                arg = self.maybe_wrap_implicit_it(arg)
            self.saw_implicit_it = outer_it
            self.implicit_it_depth = outer_depth
            args.push(arg as i32)
            self.skip_newlines()
            if self.peek() != TokenKind.TK_COMMA:
                break
            self.advance()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_R_PAREN:
                break
    self.skip_newlines()
    self.expect(TokenKind.TK_R_PAREN)
    self.suppress_brace = saved_suppress_brace
    let arg_count = args.len() as i32
    var placeholder_count = 0
    for ai in 0..arg_count:
        let arg = args.get(ai as i64)
        if self.pool.kind(arg) == NodeKind.NK_IDENT:
            let sym = self.pool.get_data0(arg)
            if self.intern.resolve(sym) == "_":
                placeholder_count = placeholder_count + 1

    let extra_start = self.pool.extra_len()
    var partial_param_syms: Vec[i32] = Vec.new()
    for ai in 0..arg_count:
        let arg = args.get(ai as i64)
        if self.pool.kind(arg) == NodeKind.NK_IDENT:
            let sym = self.pool.get_data0(arg)
            if self.intern.resolve(sym) == "_":
                let pname = f"__partial_arg_{self.pos}_{partial_param_syms.len() as i32}"
                let psym = self.intern.intern(pname)
                partial_param_syms.push(psym)
                let pnode = self.pool.add_node(NodeKind.NK_IDENT, self.pool.get_start(arg), self.pool.get_end(arg), psym, 0, 0)
                self.pool.add_extra(pnode)
                continue
        self.pool.add_extra(arg as i32)
    let call_node = self.pool.add_node(NodeKind.NK_CALL, self.pool.get_start(callee), self.prev_end(), callee, extra_start, arg_count)

    // Store named argument info if any
    if has_named != 0:
        let names_start = self.pool.extra_len()
        for ni in 0..arg_count:
            self.pool.add_extra(arg_names.get(ni as i64))
        self.pool.set_call_named_args(call_node, names_start)

    if placeholder_count == 0:
        return call_node

    let param_start = self.pool.extra_len()
    let param_count = partial_param_syms.len() as i32
    for pi in 0..param_count:
        self.pool.add_extra(partial_param_syms.get(pi as i64))
        self.pool.add_extra(0)
    self.pool.add_node(NodeKind.NK_CLOSURE, self.pool.get_start(callee), self.prev_end(), call_node, param_start, param_count)

fn Parser.parse_dot(self: Parser, lhs: i32) -> NodeId:
    self.advance()  // consume .
    // .await
    if self.peek() == TokenKind.TK_KW_AWAIT:
        self.advance()
        return self.pool.add_node(NodeKind.NK_AWAIT, self.pool.get_start(lhs), self.prev_end(), lhs, 0, 0)
    if self.peek() == TokenKind.TK_L_BRACE:
        self.advance()
        self.skip_newlines()
        let field_expr = self.parse_expr()
        if field_expr == 0:
            return self.poisoned_expr()
        self.skip_newlines()
        if self.expect(TokenKind.TK_R_BRACE) == 0:
            return self.poisoned_expr()
        return self.pool.add_node(NodeKind.NK_COMPUTED_FIELD_ACCESS, self.pool.get_start(lhs), self.prev_end(), lhs, field_expr, 0)
    // Tuple field .0 .1
    if self.peek() == TokenKind.TK_INT_LIT:
        let field = self.intern_current()
        self.advance()
        return self.pool.add_node(NodeKind.NK_FIELD_ACCESS, self.pool.get_start(lhs), self.prev_end(), lhs, field, 0)
    let field = self.expect_ident_or_keyword()
    self.pool.add_node(NodeKind.NK_FIELD_ACCESS, self.pool.get_start(lhs), self.prev_end(), lhs, field, 0)

fn Parser.build_composed_closure(self: Parser, lhs_fn: i32, rhs_fn: i32, is_forward: i32) -> NodeId:
    let param_name = f"__pipe_arg_{self.pos}"
    let param_sym = self.intern.intern(param_name)
    let param_expr = self.pool.add_node(
        NodeKind.NK_IDENT,
        self.pool.get_start(lhs_fn),
        self.pool.get_end(lhs_fn),
        param_sym,
        0,
        0,
    )

    let first_callee = if is_forward != 0: lhs_fn else: rhs_fn
    let second_callee = if is_forward != 0: rhs_fn else: lhs_fn

    let first_args = self.pool.extra_len()
    self.pool.add_extra(param_expr)
    let first_call = self.pool.add_node(
        NodeKind.NK_CALL,
        self.pool.get_start(lhs_fn),
        self.pool.get_end(rhs_fn),
        first_callee,
        first_args,
        1,
    )

    let second_args = self.pool.extra_len()
    self.pool.add_extra(first_call)
    let second_call = self.pool.add_node(
        NodeKind.NK_CALL,
        self.pool.get_start(lhs_fn),
        self.pool.get_end(rhs_fn),
        second_callee,
        second_args,
        1,
    )

    // NodeKind.NK_CLOSURE expects [name, type] pairs.
    let params_start = self.pool.extra_len()
    self.pool.add_extra(param_sym)
    self.pool.add_extra(0)
    self.pool.add_node(
        NodeKind.NK_CLOSURE,
        self.pool.get_start(lhs_fn),
        self.pool.get_end(second_call),
        second_call,
        params_start,
        1,
    )

fn Parser.is_positional_struct_literal(self: Parser) -> i32:
    if self.peek() == TokenKind.TK_R_BRACE:
        return 0
    if self.peek() != TokenKind.TK_IDENT:
        return 1
    if self.pos + 1 >= self.tokens.len():
        return 0
    let next = self.tokens.get_tag(self.pos + 1)
    if next == TokenKind.TK_COLON or next == TokenKind.TK_COMMA or next == TokenKind.TK_R_BRACE:
        return 0
    1

fn Parser.parse_struct_literal(self: Parser, lhs: i32) -> NodeId:
    let struct_name = self.pool.get_data0(lhs)
    self.advance()  // consume {
    self.skip_newlines()

    if self.is_positional_struct_literal() != 0:
        return self.parse_positional_struct_literal(lhs, struct_name)

    var fields: Vec[i32] = Vec.new()
    var field_count = 0
    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        let fname = self.expect_ident()
        if fname == 0:
            break
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            let val = self.parse_expr()
            fields.push(fname)
            fields.push(val as i32)
        else:
            // Shorthand: name means name: name
            let ident_node = self.pool.add_node(NodeKind.NK_IDENT, self.pool.get_start(lhs), self.prev_end(), fname, 0, 0)
            fields.push(fname)
            fields.push(ident_node as i32)
        field_count = field_count + 1
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    self.pool.add_node(NodeKind.NK_STRUCT_LIT, self.pool.get_start(lhs), self.prev_end(), struct_name, extra_start, field_count)

fn Parser.parse_positional_struct_literal(self: Parser, lhs: i32, struct_name: i32) -> NodeId:
    var fields: Vec[i32] = Vec.new()
    var field_count = 0
    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        let val = self.parse_expr()
        fields.push(0)
        fields.push(val as i32)
        field_count = field_count + 1
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    self.pool.add_node(NodeKind.NK_STRUCT_LIT, self.pool.get_start(lhs), self.prev_end(), struct_name, extra_start, field_count)

fn Parser.parse_block_struct_literal(self: Parser, lhs: i32) -> NodeId:
    let struct_name = self.pool.get_data0(lhs)
    self.advance()  // consume :
    self.skip_newlines()
    let block_col = column_of(self.source, self.current_start())
    var fields: Vec[i32] = Vec.new()
    var field_count = 0
    while self.peek() != TokenKind.TK_EOF:
        let cur_col = column_of(self.source, self.current_start())
        if cur_col < block_col:
            break
        if self.peek() != TokenKind.TK_IDENT:
            break
        let fname = self.expect_ident()
        if fname == 0:
            break
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            let val = self.parse_expr()
            fields.push(fname)
            fields.push(val as i32)
        else:
            let ident_node = self.pool.add_node(NodeKind.NK_IDENT, self.pool.get_start(lhs), self.prev_end(), fname, 0, 0)
            fields.push(fname)
            fields.push(ident_node as i32)
        field_count = field_count + 1
        if self.peek() == TokenKind.TK_NEWLINE:
            let save = self.pos
            self.skip_newlines()
            if self.peek() == TokenKind.TK_EOF:
                break
            let next_col = column_of(self.source, self.current_start())
            if next_col < block_col:
                self.pos = save
                break
        else:
            break
    let extra_start = self.pool.extra_len()
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    self.pool.add_node(NodeKind.NK_STRUCT_LIT, self.pool.get_start(lhs), self.prev_end(), struct_name, extra_start, field_count)

fn Parser.parse_index_or_slice(self: Parser, lhs: i32) -> NodeId:
    self.advance()  // consume [
    self.skip_newlines()

    // Multi-index detection: if first token is ':' or '...', it's multi-index
    if self.peek() == TokenKind.TK_COLON or self.peek() == TokenKind.TK_DOT_DOT_DOT:
        return self.parse_multi_index(lhs)

    let index = self.parse_index_expr()
    self.skip_newlines()

    // Slice: a[start..end]
    if self.peek() == TokenKind.TK_DOT_DOT:
        self.advance()
        self.skip_newlines()
        var end_expr: NodeId = 0 as NodeId
        if self.peek() != TokenKind.TK_R_BRACKET:
            end_expr = self.parse_expr()
            self.skip_newlines()
        self.expect(TokenKind.TK_R_BRACKET)
        return self.pool.add_node(NodeKind.NK_SLICE, self.pool.get_start(lhs), self.prev_end(), lhs, index, end_expr)

    // After first expr: if followed by ':' (slice notation) then multi-index
    if self.peek() == TokenKind.TK_COLON:
        return self.parse_multi_index_with_first(lhs, index, 1)

    // Comma-separated: check if multi-index or two-arg subscript
    if self.peek() == TokenKind.TK_COMMA:
        let save = self.pos
        self.advance()
        self.skip_newlines()
        // If next is ':' or '...', definitely multi-index
        if self.peek() == TokenKind.TK_COLON or self.peek() == TokenKind.TK_DOT_DOT_DOT:
            self.pos = save
            return self.parse_multi_index_with_first(lhs, index, 0)
        // Parse second element and check for another comma or colon
        let second = self.parse_index_expr()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COLON or self.peek() == TokenKind.TK_COMMA:
            // 3+ dimensions or second has slice → multi-index
            self.pos = save
            return self.parse_multi_index_with_first(lhs, index, 0)
        // Just two elements — existing HashMap[K,V] / two-arg subscript
        self.expect(TokenKind.TK_R_BRACKET)
        return self.pool.add_node(NodeKind.NK_INDEX, self.pool.get_start(lhs), self.prev_end(), lhs, index, second)

    self.expect(TokenKind.TK_R_BRACKET)
    self.pool.add_node(NodeKind.NK_INDEX, self.pool.get_start(lhs), self.prev_end(), lhs, index, 0 as NodeId)

fn Parser.parse_single_index_spec(self: Parser) -> NodeId:
    let start = self.current_start()
    // Ellipsis: ...
    if self.peek() == TokenKind.TK_DOT_DOT_DOT:
        self.advance()
        return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), 0, 0, INDEX_ELLIPSIS * INDEX_KIND_SHIFT)
    // newaxis check
    if self.peek() == TokenKind.TK_IDENT:
        let sym = self.intern_current()
        if self.intern.resolve(sym) == "newaxis":
            self.advance()
            return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), 0, 0, INDEX_NEWAXIS * INDEX_KIND_SHIFT)
    // Starts with ':' → slice with absent start
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        self.skip_newlines()
        // '::step'
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            let step = self.parse_index_expr()
            return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), 0, 0, step as i32 + INDEX_SLICE * INDEX_KIND_SHIFT)
        // ':' alone or ':stop' or ':stop:step'
        if self.peek() == TokenKind.TK_COMMA or self.peek() == TokenKind.TK_R_BRACKET:
            return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), 0, 0, INDEX_SLICE * INDEX_KIND_SHIFT)
        let stop = self.parse_index_expr()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            let step = self.parse_index_expr()
            return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), 0, stop, step as i32 + INDEX_SLICE * INDEX_KIND_SHIFT)
        return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), 0, stop, INDEX_SLICE * INDEX_KIND_SHIFT)
    // Starts with expr → scalar or slice with start
    let expr = self.parse_index_expr()
    self.skip_newlines()
    if self.peek() != TokenKind.TK_COLON:
        return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), expr, 0, INDEX_SCALAR * INDEX_KIND_SHIFT)
    // expr: → slice with start
    self.advance()
    self.skip_newlines()
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        self.skip_newlines()
        let step = self.parse_index_expr()
        return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), expr, 0, step as i32 + INDEX_SLICE * INDEX_KIND_SHIFT)
    if self.peek() == TokenKind.TK_COMMA or self.peek() == TokenKind.TK_R_BRACKET:
        return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), expr, 0, INDEX_SLICE * INDEX_KIND_SHIFT)
    let stop = self.parse_index_expr()
    self.skip_newlines()
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        self.skip_newlines()
        let step = self.parse_index_expr()
        return self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), expr, stop, step as i32 + INDEX_SLICE * INDEX_KIND_SHIFT)
    self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), expr, stop, INDEX_SLICE * INDEX_KIND_SHIFT)

fn Parser.parse_multi_index(self: Parser, base: i32) -> NodeId:
    let specs: Vec[i32] = Vec.new()
    while self.peek() != TokenKind.TK_R_BRACKET and self.peek() != TokenKind.TK_EOF:
        specs.push(self.parse_single_index_spec() as i32)
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
        else:
            break
    self.expect(TokenKind.TK_R_BRACKET)
    let extra_start = self.pool.extra_len()
    let count = specs.len() as i32
    for i in 0..count:
        self.pool.add_extra(specs.get(i as i64))
    self.pool.add_node(NodeKind.NK_MULTI_INDEX, self.pool.get_start(base), self.prev_end(), base, extra_start, count)

fn Parser.parse_multi_index_with_first(self: Parser, base: i32, first_expr: NodeId, has_colon: i32) -> NodeId:
    // First spec already partially parsed: we have first_expr, possibly followed by ':'
    let start = self.pool.get_start(first_expr)
    let specs: Vec[i32] = Vec.new()
    if has_colon != 0:
        // first_expr: ... → slice starting at first_expr
        self.advance()  // consume ':'
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            let step = self.parse_index_expr()
            specs.push(self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), first_expr, 0, step as i32 + INDEX_SLICE * INDEX_KIND_SHIFT) as i32)
        else if self.peek() == TokenKind.TK_COMMA or self.peek() == TokenKind.TK_R_BRACKET:
            specs.push(self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), first_expr, 0, INDEX_SLICE * INDEX_KIND_SHIFT) as i32)
        else:
            let stop = self.parse_index_expr()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_COLON:
                self.advance()
                self.skip_newlines()
                let step = self.parse_index_expr()
                specs.push(self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), first_expr, stop, step as i32 + INDEX_SLICE * INDEX_KIND_SHIFT) as i32)
            else:
                specs.push(self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), first_expr, stop, INDEX_SLICE * INDEX_KIND_SHIFT) as i32)
    else:
        // No colon: first_expr is a scalar index spec
        specs.push(self.pool.add_node(NodeKind.NK_INDEX_SPEC, start, self.prev_end(), first_expr, 0, INDEX_SCALAR * INDEX_KIND_SHIFT) as i32)
    // Continue parsing remaining specs after comma
    self.skip_newlines()
    while self.peek() == TokenKind.TK_COMMA:
        self.advance()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_R_BRACKET:
            break
        specs.push(self.parse_single_index_spec() as i32)
        self.skip_newlines()
    self.expect(TokenKind.TK_R_BRACKET)
    let extra_start = self.pool.extra_len()
    let count = specs.len() as i32
    for i in 0..count:
        self.pool.add_extra(specs.get(i as i64))
    self.pool.add_node(NodeKind.NK_MULTI_INDEX, self.pool.get_start(base), self.prev_end(), base, extra_start, count)

fn Parser.parse_index_expr(self: Parser) -> NodeId:
    self.parse_precedence(6)

fn Parser.parse_optional_chain(self: Parser, lhs: i32) -> NodeId:
    self.advance()  // consume ?.
    var member = 0
    if self.peek() == TokenKind.TK_INT_LIT:
        member = self.intern_current()
        self.advance()
    else:
        member = self.expect_ident()
    var args: Vec[i32] = Vec.new()
    if self.peek() == TokenKind.TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
            args.push(self.parse_expr() as i32)
            self.skip_newlines()
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
        self.expect(TokenKind.TK_R_PAREN)
    let extra_start = self.pool.extra_len()
    let arg_count = args.len() as i32
    self.pool.add_extra(arg_count)
    for ai in 0..arg_count:
        self.pool.add_extra(args.get(ai as i64))
    self.pool.add_node(NodeKind.NK_OPTIONAL_CHAIN, self.pool.get_start(lhs), self.prev_end(), lhs, member, extra_start)

// ── Variant shorthand ────────────────────────────────────────────

fn Parser.parse_variant_shorthand(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice((start + 1) as i64, end as i64)
    let sym = self.intern.intern(text)
    self.advance()
    var args: Vec[i32] = Vec.new()
    if self.peek() == TokenKind.TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
            // Keep shorthand construction aligned with normal call parsing:
            // `.Fatal(code: 99)` should behave like `Fatal(code: 99)`.
            if self.peek() == TokenKind.TK_IDENT:
                let save = self.pos
                self.advance()
                if self.peek() == TokenKind.TK_COLON:
                    self.advance()
                    self.skip_newlines()
                else:
                    self.pos = save
            args.push(self.parse_expr() as i32)
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
        self.skip_newlines()
        self.expect(TokenKind.TK_R_PAREN)
    let extra_start = self.pool.extra_len()
    let arg_count = args.len() as i32
    for ai in 0..arg_count:
        self.pool.add_extra(args.get(ai as i64))
    self.pool.add_node(NodeKind.NK_VARIANT_SHORTHAND, start, self.prev_end(), sym, extra_start, arg_count)

// ── Grouped / tuple ──────────────────────────────────────────────

fn Parser.parse_grouped_or_tuple(self: Parser) -> NodeId:
    let start = self.current_start()
    let open_paren_pos = self.pos
    self.advance()  // consume (
    self.skip_newlines()

    if self.peek() == TokenKind.TK_R_PAREN:
        let end = self.current_end()
        self.advance()
        // () => expr or () -> Type => expr is a zero-param closure
        if self.peek() == TokenKind.TK_FAT_ARROW or self.peek() == TokenKind.TK_ARROW:
            self.pos = open_paren_pos
            return self.parse_fat_arrow_paren_closure()
        let node = self.pool.add_node(NodeKind.NK_TUPLE, start, end, self.pool.extra_len(), 0, 0)
        return self.parse_postfix(node)

    // Check if (params) => closure
    if self.scan_is_paren_closure() == 1:
        self.pos = open_paren_pos
        return self.parse_fat_arrow_paren_closure()

    let first = self.parse_expr()
    if self.peek() == TokenKind.TK_COMMA:
        var elems: Vec[i32] = Vec.new()
        elems.push(first as i32)
        while self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_R_PAREN:
                break
            let elem = self.parse_expr()
            elems.push(elem as i32)
        self.expect(TokenKind.TK_R_PAREN)
        let extra_start = self.pool.extra_len()
        for ei in 0..elems.len() as i32:
            self.pool.add_extra(elems.get(ei as i64))
        let count = elems.len() as i32
        let node = self.pool.add_node(NodeKind.NK_TUPLE, start, self.prev_end(), extra_start, count, 0)
        return self.parse_postfix(node)

    self.expect(TokenKind.TK_R_PAREN)
    let node = self.pool.add_node(NodeKind.NK_GROUPED, start, self.prev_end(), first, 0, 0)
    self.parse_postfix(node)

// ── Unary expressions ────────────────────────────────────────────

fn Parser.parse_unary_negate(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    if self.peek() == TokenKind.TK_INT_LIT:
        let end = self.current_end()
        let text = self.source.slice(start as i64 + 1, end as i64)
        if numeric_literal_suffix_code(text) == LiteralSuffix.None:
            let fast = int_literal_fast_i64(text)
            if fast.ok != 0:
                let value = 0 - fast.value
                self.advance()
                return self.pool.add_node(NodeKind.NK_INT_LIT, start, end, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value))
    let operand = self.parse_primary()
    self.pool.add_node(NodeKind.NK_UNARY, start, self.prev_end(), UnaryOp.UOP_NEGATE, operand, 0)

fn Parser.parse_unary_bit_not(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    let operand = self.parse_primary()
    self.pool.add_node(NodeKind.NK_UNARY, start, self.prev_end(), UnaryOp.UOP_BIT_NOT, operand, 0)

fn Parser.parse_unary_not(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    let operand = self.parse_primary()
    self.pool.add_node(NodeKind.NK_UNARY, start, self.prev_end(), UnaryOp.UOP_NOT, operand, 0)

fn Parser.build_unary_with_outer_cast(self: Parser, start: i32, op: i32, operand: i32) -> NodeId:
    if operand == 0:
        return self.pool.add_node(NodeKind.NK_UNARY, start, self.prev_end(), op, operand, 0)

    let cast_targets: Vec[i32] = Vec.new()
    let cast_ends: Vec[i32] = Vec.new()
    var inner = operand
    while inner != 0 and self.pool.kind(inner) == NodeKind.NK_CAST:
        cast_targets.push(self.pool.get_data1(inner))
        cast_ends.push(self.pool.get_end(inner))
        inner = self.pool.get_data0(inner)

    var out = self.pool.add_node(NodeKind.NK_UNARY, start, self.pool.get_end(inner), op, inner, 0)
    var i = cast_targets.len() as i32 - 1
    while i >= 0:
        out = self.pool.add_node(NodeKind.NK_CAST, start, cast_ends.get(i as i64), out, cast_targets.get(i as i64), 0)
        i = i - 1
    out

fn Parser.parse_ref_of(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    var op = UnaryOp.UOP_REF
    // docs/mut.md Rev 8 §13.2 — `&raw const P` / `&raw mut P`.
    // `raw` is contextual: only treated as the raw-address-of marker when it
    // immediately follows `&` AND the next token after it is `const` or `mut`.
    // The two-token lookahead avoids stealing `&raw` where `raw` is an
    // ordinary identifier (e.g., `&raw as *const T`).
    var matched_raw = false
    if self.is_ident_named("raw") and self.pos + 1 < self.tokens.len():
        let next_tag = self.tokens.get_tag(self.pos + 1)
        if next_tag == TokenKind.TK_KW_CONST or next_tag == TokenKind.TK_KW_MUT:
            self.advance()  // consume `raw`
            if next_tag == TokenKind.TK_KW_CONST:
                op = UnaryOp.UOP_RAW_REF_CONST
            else:
                op = UnaryOp.UOP_RAW_REF_MUT
            self.advance()  // consume `const` or `mut`
            matched_raw = true
    if not matched_raw and self.peek() == TokenKind.TK_KW_MUT:
        op = UnaryOp.UOP_MUT_REF
        self.advance()
    let operand = self.parse_primary()
    self.build_unary_with_outer_cast(start, op, operand)

fn Parser.parse_deref_expr(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    let operand = self.parse_primary()
    self.build_unary_with_outer_cast(start, UnaryOp.UOP_DEREF, operand)

// ── Control flow expressions ─────────────────────────────────────

// Returns 1 if the token at `pos` is the first non-whitespace on its line.
fn is_first_on_line(source: str, pos: i32) -> i32:
    var p = pos - 1
    while p >= 0:
        let ch = source.byte_at(p as i64)
        if ch == 10:
            return 1
        if ch != 32 and ch != 9:
            return 0
        p = p - 1
    1

fn Parser.parse_if_expr(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()  // consume if
    self.skip_newlines()

    if self.peek() == TokenKind.TK_KW_LET:
        return self.parse_if_let(start)

    let saved_sb = self.suppress_brace
    self.suppress_brace = 1
    let cond = self.parse_expr()
    self.suppress_brace = saved_sb

    let if_col = column_of(self.source, start)
    let is_stmt_if = is_first_on_line(self.source, start) != 0
    var use_then = false
    var then_body: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_KW_THEN:
        self.advance()
        use_then = true
        then_body = self.parse_expr()
    else:
        then_body = self.parse_body()
    var else_body: NodeId = 0 as NodeId
    let save = self.pos
    self.skip_newlines()
    let crossed_newline = self.pos != save
    if self.peek() == TokenKind.TK_KW_ELSE:
        let else_col = column_of(self.source, self.current_start())
        if crossed_newline and is_stmt_if and else_col != if_col:
            self.pos = save
        else:
            self.advance()
            if self.peek() == TokenKind.TK_KW_IF:
                else_body = self.parse_if_expr()
            else if use_then:
                else_body = self.parse_expr()
            else:
                else_body = self.parse_body()
    else:
        self.pos = save

    self.pool.add_node(NodeKind.NK_IF_EXPR, start, self.prev_end(), cond, then_body, else_body)

fn Parser.parse_if_let(self: Parser, start: i32) -> NodeId:
    self.advance()  // consume first 'let'
    let pat = self.parse_pattern()
    if self.expect(TokenKind.TK_EQ) == 0:
        return self.poisoned_expr()
    let saved_sb = self.suppress_brace
    self.suppress_brace = 1
    let subject = self.parse_expr()
    self.suppress_brace = saved_sb

    // Store clauses as flat triples: (kind, data0, data1).
    // kind=0 → let clause (data0=pattern, data1=subject)
    // kind=1 → cond clause (data0=cond_expr, data1=0)
    var clauses: Vec[i32] = Vec.new()
    clauses.push(0)
    clauses.push(pat as i32)
    clauses.push(subject as i32)

    // Chained form: `if let A = x, let B = y, cond, ...`
    while self.peek() == TokenKind.TK_COMMA:
        self.advance()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_KW_LET:
            self.advance()  // consume 'let'
            let p = self.parse_pattern()
            if self.expect(TokenKind.TK_EQ) == 0:
                return self.poisoned_expr()
            let s = self.parse_expr()
            clauses.push(0)
            clauses.push(p as i32)
            clauses.push(s as i32)
        else:
            let cond = self.parse_expr()
            clauses.push(1)
            clauses.push(cond as i32)
            clauses.push(0)

    let if_col = column_of(self.source, start)
    let is_stmt_if = is_first_on_line(self.source, start) != 0
    var use_then = false
    var then_body: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_KW_THEN:
        self.advance()
        use_then = true
        then_body = self.parse_expr()
    else:
        then_body = self.parse_body()

    var else_body: NodeId = 0 as NodeId
    let save = self.pos
    self.skip_newlines()
    let crossed_newline = self.pos != save
    if self.peek() == TokenKind.TK_KW_ELSE:
        let else_col = column_of(self.source, self.current_start())
        if crossed_newline and is_stmt_if and else_col != if_col:
            self.pos = save
        else:
            self.advance()
            if self.peek() == TokenKind.TK_KW_IF:
                else_body = self.parse_if_expr()
            else if use_then:
                else_body = self.parse_expr()
            else:
                else_body = self.parse_body()
    else:
        self.pos = save
    if else_body == 0:
        else_body = self.pool.add_node(NodeKind.NK_INT_LIT, start, start, 0, 0, 0)

    // Desugar chained if-let into nested match/if expressions from right to left.
    var acc = then_body
    let clause_count = clauses.len() as i32 / 3
    var ci = clause_count - 1
    while ci >= 0:
        let kind = clauses.get((ci * 3) as i64)
        let d0 = clauses.get((ci * 3 + 1) as i64)
        let d1 = clauses.get((ci * 3 + 2) as i64)
        if kind == 0:
            // Let clause → match d1 { d0 -> acc, _ -> else_body }
            let extra_start = self.pool.extra_len()
            let arm1 = self.pool.add_node(NodeKind.NK_MATCH_ARM, start, self.prev_end(), d0, acc, 0)
            self.pool.add_extra(arm1)
            let wildcard = self.pool.add_node(NodeKind.NK_PAT_WILDCARD, start, start, 0, 0, 0)
            let arm2 = self.pool.add_node(NodeKind.NK_MATCH_ARM, start, self.prev_end(), wildcard, else_body, 0)
            self.pool.add_extra(arm2)
            acc = self.pool.add_node(NodeKind.NK_MATCH, start, self.prev_end(), d1, extra_start, 2)
        else:
            // Cond clause → if d0 then acc else: else_body
            acc = self.pool.add_node(NodeKind.NK_IF_EXPR, start, self.prev_end(), d0, acc, else_body)
        ci = ci - 1
    acc

fn Parser.parse_return(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    var value: NodeId = 0 as NodeId
    let t = self.peek()
    if t != TokenKind.TK_NEWLINE and t != TokenKind.TK_SEMICOLON and t != TokenKind.TK_EOF and t != TokenKind.TK_R_PAREN and t != TokenKind.TK_R_BRACE:
        value = self.parse_expr()
    self.pool.add_node(NodeKind.NK_RETURN, start, self.prev_end(), value, 0, 0)

fn Parser.parse_defer(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    let body = self.parse_body()
    self.pool.add_node(NodeKind.NK_DEFER, start, self.prev_end(), body, 0, 0)

fn Parser.parse_errdefer(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    let body = self.parse_body()
    self.pool.add_node(NodeKind.NK_ERRDEFER, start, self.prev_end(), body, 0, 0)

fn Parser.parse_unsafe(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    var body: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_L_BRACE or self.peek() == TokenKind.TK_COLON:
        body = self.parse_body()
    else:
        body = self.parse_expr()
    self.pool.add_node(NodeKind.NK_UNSAFE_BLOCK, start, self.prev_end(), body, 0, 0)

fn Parser.parse_asm_expr(self: Parser) -> NodeId:
    // asm("template" : outputs : inputs : clobbers)
    // asm volatile("template" ::: "memory")
    let start = self.current_start()
    self.advance()  // consume 'asm'
    var flags: i32 = 0
    // Check for 'volatile' identifier
    if self.peek() == TokenKind.TK_IDENT:
        let vol_text = self.source.slice(self.current_start() as i64, self.current_end() as i64)
        if vol_text == "volatile":
            flags = flags | 1  // bit 0 = volatile
            self.advance()
    self.expect(TokenKind.TK_L_PAREN)
    // Parse template string
    if self.peek() != TokenKind.TK_STRING_LIT:
        self.emit_error("expected assembly template string")
        return self.pool.add_node(NodeKind.NK_POISONED_EXPR, start, self.prev_end(), 0, 0, 0)
    let tmpl_raw = self.source.slice(self.current_start() as i64, self.current_end() as i64)
    let tmpl_text = strip_string_token_text(tmpl_raw)
    let tmpl_sym = self.intern.intern(tmpl_text)
    self.advance()
    // Build LLVM constraint string and collect input expression nodes.
    // LLVM format: "output_constraints,input_constraints,~{clobber1},~{clobber2}"
    var constraints_str = ""
    var has_output = false
    var output_type_node: NodeId = 0 as NodeId
    let input_exprs: Vec[NodeId] = Vec.new()
    var first_constraint = true
    // Section 1: outputs
    var rw_output_sym: i32 = 0  // read-write output variable symbol
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        // Parse output: ident("constraint") -> type
        //   or read-write: ident("+r") ident  (same variable as input+output)
        if self.peek() == TokenKind.TK_IDENT and self.peek() != TokenKind.TK_COLON:
            let out_name_sym = self.intern_current()
            self.advance()
            if self.peek() == TokenKind.TK_L_PAREN:
                self.advance()
                if self.peek() == TokenKind.TK_STRING_LIT:
                    let out_raw = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                    let out_reg = strip_string_token_text(out_raw)
                    // Read-write constraint: "+r" passes through directly.
                    // The variable is both input and output.
                    if out_reg.len() > 1 and out_reg.byte_at(0) == 43:  // '+'
                        constraints_str = out_reg
                        rw_output_sym = out_name_sym
                    else:
                        constraints_str = "={" ++ out_reg ++ "}"
                    first_constraint = false
                    self.advance()
                self.expect(TokenKind.TK_R_PAREN)
            if rw_output_sym != 0:
                // Read-write: the variable is the output, infer type as i64,
                // and add the variable as an implicit input expression.
                has_output = true
                flags = flags | 2
            else if self.peek() == TokenKind.TK_ARROW:
                self.advance()
                output_type_node = self.parse_type_expr()
                has_output = true
                flags = flags | 2  // bit 1 = has_output
        // Section 2: inputs
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            // Parse inputs: ident("constraint") expr, ...
            while self.peek() == TokenKind.TK_IDENT:
                self.advance()  // consume input name
                if self.peek() == TokenKind.TK_L_PAREN:
                    self.advance()
                    if self.peek() == TokenKind.TK_STRING_LIT:
                        let in_raw = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                        let in_reg = strip_string_token_text(in_raw)
                        if not first_constraint:
                            constraints_str = constraints_str ++ ","
                        constraints_str = constraints_str ++ "{" ++ in_reg ++ "}"
                        first_constraint = false
                        self.advance()
                    self.expect(TokenKind.TK_R_PAREN)
                // Parse the input value expression
                let in_expr = self.parse_expr()
                input_exprs.push(in_expr)
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
            // Section 3: clobbers
            if self.peek() == TokenKind.TK_COLON:
                self.advance()
                while self.peek() == TokenKind.TK_STRING_LIT:
                    let clob_raw = self.source.slice(self.current_start() as i64, self.current_end() as i64)
                    let clob = strip_string_token_text(clob_raw)
                    if not first_constraint:
                        constraints_str = constraints_str ++ ","
                    constraints_str = constraints_str ++ "~{" ++ clob ++ "}"
                    first_constraint = false
                    self.advance()
                    if self.peek() == TokenKind.TK_COMMA:
                        self.advance()
    self.expect(TokenKind.TK_R_PAREN)
    // For read-write constraints: add the variable as an implicit input
    if rw_output_sym != 0:
        let rw_ident = self.pool.add_node(NodeKind.NK_IDENT, start, self.prev_end(), rw_output_sym, 0, 0)
        input_exprs.push(rw_ident)
    let constr_sym = self.intern.intern(constraints_str)
    // Store input expressions and output type in extras
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(output_type_node as i32)
    self.pool.add_extra(input_exprs.len() as i32)
    for i in 0..input_exprs.len() as i32:
        self.pool.add_extra(input_exprs.get(i as i64) as i32)
    // d0=template_sym, d1=constraints_sym, d2=flags | (extra_start << 8)
    let packed_d2 = flags | (extra_start << 8)
    self.pool.add_node(NodeKind.NK_ASM_EXPR, start, self.prev_end(), tmpl_sym, constr_sym, packed_d2)

fn Parser.parse_yield(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    let value = self.parse_expr()
    self.pool.add_node(NodeKind.NK_YIELD, start, self.prev_end(), value, 0, 0)

fn Parser.parse_comptime_expr(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    var inner: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_L_BRACE or self.peek() == TokenKind.TK_COLON:
        inner = self.parse_body()
    else:
        inner = self.parse_expr()
    self.pool.add_node(NodeKind.NK_COMPTIME, start, self.prev_end(), inner, 0, 0)

fn Parser.parse_spawn(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    let value = self.parse_expr()
    self.pool.add_node(NodeKind.NK_SPAWN, start, self.prev_end(), value, 0, 0)

fn Parser.parse_async_expr(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    if self.is_ident_named("scope"):
        self.advance()
        var scope_name = self.intern.intern("s")
        if self.peek() == TokenKind.TK_IDENT:
            // async scope s => ...
            scope_name = self.expect_ident()
            if self.peek() == TokenKind.TK_FAT_ARROW:
                self.advance()
        else if self.peek() == TokenKind.TK_PIPE:
            // async scope |s| ... (deprecated)
            self.advance()
            if self.peek() == TokenKind.TK_IDENT:
                scope_name = self.expect_ident()
            self.expect(TokenKind.TK_PIPE)
        var body: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_L_BRACE:
            self.advance()
            body = self.parse_braced_body()
        else:
            if self.peek() == TokenKind.TK_COLON:
                self.advance()
            body = self.parse_block_or_expr()
        return self.pool.add_node(NodeKind.NK_ASYNC_SCOPE, start, self.prev_end(), scope_name, body, 0)

    var body: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_L_BRACE:
        self.advance()
        body = self.parse_braced_body()
    else:
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
        body = self.parse_block_or_expr()
    self.pool.add_node(NodeKind.NK_ASYNC_BLOCK, start, self.prev_end(), body, 0, 0)

fn Parser.parse_select_await(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()  // consume select
    self.expect(TokenKind.TK_KW_AWAIT)
    var select_braced = false
    if self.peek() == TokenKind.TK_L_BRACE:
        select_braced = true
        self.advance()
    else if self.peek() == TokenKind.TK_COLON:
        self.advance()
    self.skip_newlines()

    var arm_entries: Vec[i32] = Vec.new()
    var arm_count = 0
    var arm_col = -1

    while self.peek() != TokenKind.TK_EOF:
        if select_braced and self.peek() == TokenKind.TK_R_BRACE:
            break
        if self.peek() != TokenKind.TK_IDENT:
            break
        if not select_braced:
            let cur_col = column_of(self.source, self.current_start())
            if arm_col >= 0 and cur_col != arm_col:
                break
            if arm_col < 0:
                arm_col = cur_col
        if self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) != TokenKind.TK_EQ:
            break
        let name_sym = self.expect_ident()
        if self.peek() != TokenKind.TK_EQ:
            break
        self.advance()
        self.skip_newlines()
        let task_expr = self.parse_ident_or_call()
        self.expect(TokenKind.TK_FAT_ARROW)
        let body = self.parse_block_or_expr()
        arm_entries.push(name_sym)
        arm_entries.push(task_expr as i32)
        arm_entries.push(body as i32)
        arm_count = arm_count + 1

        if select_braced:
            self.skip_newlines()
            if self.peek() == TokenKind.TK_R_BRACE:
                break
        else:
            let save = self.pos
            self.skip_newlines()
            if self.peek() == TokenKind.TK_IDENT and self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) == TokenKind.TK_EQ:
                let next_col = column_of(self.source, self.current_start())
                if arm_col >= 0 and next_col == arm_col:
                    continue
            self.pos = save
            break

    if select_braced:
        self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    for ei in 0..arm_entries.len() as i32:
        self.pool.add_extra(arm_entries.get(ei as i64))
    self.pool.add_node(NodeKind.NK_SELECT_AWAIT, start, self.prev_end(), extra_start, arm_count, 0)

// ── Loop expressions ─────────────────────────────────────────────

fn Parser.parse_while(self: Parser, label: i32) -> NodeId:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()

    if self.peek() == TokenKind.TK_KW_LET:
        return self.parse_while_let(start)

    let saved_sb = self.suppress_brace
    self.suppress_brace = 1
    let cond = self.parse_expr()
    self.suppress_brace = saved_sb
    let body = self.parse_body()
    self.pool.add_node(NodeKind.NK_WHILE, start, self.prev_end(), cond, body, label)

fn Parser.parse_while_let(self: Parser, start: i32) -> NodeId:
    self.advance()  // consume let
    let pat = self.parse_pattern()
    if self.expect(TokenKind.TK_EQ) == 0:
        return self.poisoned_expr()
    let saved_sb = self.suppress_brace
    self.suppress_brace = 1
    let subject = self.parse_expr()
    self.suppress_brace = saved_sb
    let body = self.parse_body()

    // Desugar to: loop: match subject { pat -> body, _ -> break }
    let break_node = self.pool.add_node(NodeKind.NK_BREAK, start, start, 0, 0, 0)
    let extra_start = self.pool.extra_len()
    let arm1 = self.pool.add_node(NodeKind.NK_MATCH_ARM, start, self.prev_end(), pat, body, 0)
    self.pool.add_extra(arm1)
    let wildcard = self.pool.add_node(NodeKind.NK_PAT_WILDCARD, start, start, 0, 0, 0)
    let arm2 = self.pool.add_node(NodeKind.NK_MATCH_ARM, start, self.prev_end(), wildcard, break_node, 0)
    self.pool.add_extra(arm2)
    let match_node = self.pool.add_node(NodeKind.NK_MATCH, start, self.prev_end(), subject, extra_start, 2)
    self.pool.add_node(NodeKind.NK_LOOP, start, self.prev_end(), match_node, 0, 0)

fn Parser.parse_loop(self: Parser, label: i32) -> NodeId:
    let start = self.current_start()
    self.advance()
    let body = self.parse_body()
    self.pool.add_node(NodeKind.NK_LOOP, start, self.prev_end(), body, label, 0)

fn Parser.parse_for(self: Parser, label: i32) -> NodeId:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    var binding = 0
    var index_binding = 0

    if self.peek() == TokenKind.TK_L_PAREN:
        // Tuple destructuring - simplified: parse as pattern
        let pat = self.parse_pattern()
        binding = pat as i32
    else:
        binding = self.expect_ident()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            index_binding = self.expect_ident()

    if self.expect(TokenKind.TK_KW_IN) == 0:
        return self.poisoned_expr()
    self.skip_newlines()
    let saved_sb = self.suppress_brace
    self.suppress_brace = 1
    let iterable = self.parse_expr()
    self.suppress_brace = saved_sb

    // For-comprehension: if followed by ';', parse as monadic chaining
    if self.peek() == TokenKind.TK_SEMICOLON:
        return self.parse_for_comprehension(start, binding, iterable)

    let body = self.parse_body()

    var for_node = self.pool.add_node(NodeKind.NK_FOR, start, self.prev_end(), binding, iterable, body)
    self.pool.add_for_meta(for_node, index_binding, label)

    // Parse optional else: clause: for x in iter: ... else: ...
    // Only match else: at the same column as the for keyword.
    // Desugar to: { var __for_ran = false; for x in iter: { __for_ran = true; body }; if not __for_ran: else_body }
    let for_col = column_of(self.source, start)
    let save_pos = self.pos
    self.skip_newlines()
    let else_col = column_of(self.source, self.current_start())
    if self.peek() == TokenKind.TK_KW_ELSE and else_col == for_col:
        self.advance()
        let else_body = self.parse_body()
        // Build: var __for_ran: bool = false
        let flag_sym = self.intern.intern("__for_ran")
        let false_lit = self.pool.add_node(NodeKind.NK_BOOL_LIT, start, start, 0, 0, 0)
        let flag_decl = self.pool.add_node(NodeKind.NK_LET_BINDING, start, start, flag_sym, false_lit, 1)
        // Wrap original for body in: { __for_ran = true; original_body }
        let flag_ident = self.pool.add_node(NodeKind.NK_IDENT, start, start, flag_sym, 0, 0)
        let true_lit = self.pool.add_node(NodeKind.NK_BOOL_LIT, start, start, 1, 0, 0)
        let flag_set = self.pool.add_node(NodeKind.NK_ASSIGN, start, start, flag_ident, true_lit, 0)
        let wrapped_extra = self.pool.extra_len()
        self.pool.add_extra(flag_set)
        let wrapped_body = self.pool.add_node(NodeKind.NK_BLOCK, start, start, wrapped_extra, 1, body)
        // Rebuild for node with wrapped body
        for_node = self.pool.add_node(NodeKind.NK_FOR, start, self.prev_end(), binding, iterable, wrapped_body)
        self.pool.add_for_meta(for_node, index_binding, label)
        // Build: if not __for_ran: else_body
        let flag_read = self.pool.add_node(NodeKind.NK_IDENT, start, start, flag_sym, 0, 0)
        let not_flag = self.pool.add_node(NodeKind.NK_UNARY, start, start, 1, flag_read, 0)
        let if_else = self.pool.add_node(NodeKind.NK_IF_EXPR, start, self.prev_end(), not_flag, else_body, 0)
        // Build block: { flag_decl; for_node; if_else }
        let block_extra = self.pool.extra_len()
        self.pool.add_extra(flag_decl)
        self.pool.add_extra(for_node)
        for_node = self.pool.add_node(NodeKind.NK_BLOCK, start, self.prev_end(), block_extra, 2, if_else)
    else:
        self.pos = save_pos

    for_node

// For-comprehension: for x in a; y in b(x): yield f(x, y)
// Desugars to nested match on Option (Some/None).
fn Parser.parse_for_comprehension(self: Parser, start: i32, first_binding: i32, first_expr: NodeId) -> NodeId:
    // Collect all bindings: Vec of (binding_sym, source_expr)
    let bind_syms: Vec[i32] = Vec.new()
    let bind_exprs: Vec[i32] = Vec.new()
    // 0 = binding, 1 = guard
    let bind_kinds: Vec[i32] = Vec.new()
    bind_syms.push(first_binding)
    bind_exprs.push(first_expr as i32)
    bind_kinds.push(0)

    while self.peek() == TokenKind.TK_SEMICOLON:
        self.advance()
        self.skip_newlines()
        // Guard: if expr
        if self.peek() == TokenKind.TK_KW_IF:
            self.advance()
            self.skip_newlines()
            let guard_expr = self.parse_expr()
            bind_syms.push(0)
            bind_exprs.push(guard_expr as i32)
            bind_kinds.push(1)
            continue
        // Binding: ident in expr
        let bsym = self.expect_ident()
        if self.expect(TokenKind.TK_KW_IN) == 0:
            return self.poisoned_expr()
        self.skip_newlines()
        let bexpr = self.parse_expr()
        bind_syms.push(bsym)
        bind_exprs.push(bexpr as i32)
        bind_kinds.push(0)

    var comp_braced = false
    if self.peek() == TokenKind.TK_L_BRACE:
        comp_braced = true
        self.advance()
    else if self.peek() == TokenKind.TK_COLON:
        self.advance()
    self.skip_newlines()

    // Check for yield keyword
    var has_yield = 0
    if self.peek() == TokenKind.TK_KW_YIELD:
        has_yield = 1
        self.advance()
        self.skip_newlines()

    var body_expr: NodeId = 0 as NodeId
    if comp_braced:
        body_expr = self.parse_braced_body()
    else:
        body_expr = self.parse_block_or_expr()

    // Build nested match from inside out
    // Use placeholder variant names — sema resolves to Some/None or Ok/Err
    // based on the match subject's type (Option vs Result).
    let some_sym = self.intern.intern("_Payload")
    let none_sym = self.intern.intern("_Empty")

    // Innermost: wrap body in Some(body) if yield
    var inner: NodeId = body_expr
    if has_yield != 0:
        // Some(body_expr) — construct as a call to Some
        let some_callee = self.pool.add_node(NodeKind.NK_IDENT, start, start, some_sym, 0, 0)
        let some_extra = self.pool.extra_len()
        self.pool.add_extra(body_expr)
        inner = self.pool.add_node(NodeKind.NK_CALL, start, self.prev_end(), some_callee, some_extra, 1)

    // Build nested matches from last binding to first
    var bi = bind_syms.len() as i32 - 1
    while bi >= 0:
        let bkind = bind_kinds.get(bi as i64)
        if bkind == 1:
            // Guard: if guard_expr: inner else: None (or void for imperative)
            let guard_expr = bind_exprs.get(bi as i64)
            var guard_else: NodeId = 0 as NodeId
            if has_yield != 0:
                guard_else = self.pool.add_node(NodeKind.NK_VARIANT_SHORTHAND, start, start, none_sym, 0, 0)
            else:
                guard_else = self.pool.add_node(NodeKind.NK_BLOCK, start, start, 0, 0, 0)
            inner = self.pool.add_node(NodeKind.NK_IF_EXPR, start, self.prev_end(), guard_expr, inner, guard_else)
        else:
            // Binding: match source: Some(sym) => inner, None => None/void
            let source = bind_exprs.get(bi as i64)
            let bsym = bind_syms.get(bi as i64)
            // Build Some(bsym) pattern — use NK_PAT_IDENT for correct binding
            let bind_pat = self.pool.add_node(NodeKind.NK_PAT_IDENT, start, start, bsym, 0, 0)
            let pat_extra = self.pool.extra_len()
            self.pool.add_extra(bind_pat)
            let some_pat = self.pool.add_node(NodeKind.NK_PAT_VARIANT, start, start, some_sym, pat_extra, 1)
            // Build Some arm: Some(bsym) => inner
            let some_arm = self.pool.add_node(NodeKind.NK_MATCH_ARM, start, self.prev_end(), some_pat, inner, 0)
            // Build failure arm: at-binding pattern (___fail @ _) captures the
            // entire matched value. Body returns ___fail — propagating None or
            // Err(e) unchanged regardless of which enum type it is.
            let fail_sym = self.intern.intern(f"___fail_{bi}")
            let wild = self.pool.add_node(NodeKind.NK_PAT_WILDCARD, start, start, 0, 0, 0)
            let none_pat = self.pool.add_node(NodeKind.NK_PAT_AT_BINDING, start, start, fail_sym, wild, 0)
            var none_body: NodeId = 0 as NodeId
            if has_yield != 0:
                none_body = self.pool.add_node(NodeKind.NK_IDENT, start, start, fail_sym, 0, 0)
            else:
                none_body = self.pool.add_node(NodeKind.NK_BLOCK, start, start, 0, 0, 0)
            let none_arm = self.pool.add_node(NodeKind.NK_MATCH_ARM, start, self.prev_end(), none_pat, none_body, 0)
            // Build match
            let arms_extra = self.pool.extra_len()
            self.pool.add_extra(some_arm)
            self.pool.add_extra(none_arm)
            inner = self.pool.add_node(NodeKind.NK_MATCH, start, self.prev_end(), source, arms_extra, 2)
        bi = bi - 1
    inner

fn Parser.finish_labeled_block(self: Parser, start: i32, label_sym: i32, body: NodeId) -> NodeId:
    if body != 0 and self.pool.kind(body) == NodeKind.NK_BLOCK:
        self.pool.set_start(body, start)
        self.pool.add_block_meta(body, label_sym)
        return body
    let block = self.pool.add_node(NodeKind.NK_BLOCK, start, self.prev_end(), self.pool.extra_len(), 0, body as i32)
    self.pool.add_block_meta(block, label_sym)
    block

fn Parser.parse_labeled_statement(self: Parser) -> NodeId:
    let start = self.current_start()
    let label_end = self.current_end()
    let label_text = self.source.slice((start + 1) as i64, label_end as i64)
    let label_sym = self.intern.intern(label_text)
    self.advance()
    self.skip_separators()

    let t = self.peek()
    var stmt: NodeId = 0 as NodeId
    if t == TokenKind.TK_KW_FOR:
        stmt = self.parse_for(label_sym)
        return self.pool.add_node(NodeKind.NK_LABEL, start, self.pool.get_end(stmt), label_sym, stmt, 0)
    if t == TokenKind.TK_KW_WHILE:
        stmt = self.parse_while(label_sym)
        return self.pool.add_node(NodeKind.NK_LABEL, start, self.pool.get_end(stmt), label_sym, stmt, 0)
    if t == TokenKind.TK_KW_LOOP:
        stmt = self.parse_loop(label_sym)
        return self.pool.add_node(NodeKind.NK_LABEL, start, self.pool.get_end(stmt), label_sym, stmt, 0)
    if t == TokenKind.TK_L_BRACE:
        self.advance()
        let body = self.parse_braced_body()
        stmt = self.finish_labeled_block(start, label_sym, body)
        return self.pool.add_node(NodeKind.NK_LABEL, start, self.pool.get_end(stmt), label_sym, stmt, 0)
    if t == TokenKind.TK_COLON:
        self.advance()
        let body = self.parse_block_or_expr()
        stmt = self.finish_labeled_block(start, label_sym, body)
        return self.pool.add_node(NodeKind.NK_LABEL, start, self.pool.get_end(stmt), label_sym, stmt, 0)
    if t == TokenKind.TK_EOF or t == TokenKind.TK_DEDENT or t == TokenKind.TK_R_BRACE:
        self.emit_error("label must be followed by a statement")
        return self.poisoned_expr()

    stmt = self.parse_expr()
    self.pool.add_node(NodeKind.NK_LABEL, start, self.pool.get_end(stmt), label_sym, stmt, 0)

fn Parser.parse_goto(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    if self.peek() != TokenKind.TK_LABEL:
        self.emit_error("expected label after 'goto'")
        return self.poisoned_expr()
    let ls = self.current_start()
    let le = self.current_end()
    let label = self.intern.intern(self.source.slice((ls + 1) as i64, le as i64))
    self.advance()
    self.pool.add_node(NodeKind.NK_GOTO, start, self.prev_end(), label, 0, 0)

fn Parser.parse_break(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    var label = 0
    if self.peek() == TokenKind.TK_LABEL:
        let ls = self.current_start()
        let le = self.current_end()
        label = self.intern.intern(self.source.slice((ls + 1) as i64, le as i64))
        self.advance()
    var value: NodeId = 0 as NodeId
    let t = self.peek()
    if t != TokenKind.TK_NEWLINE and t != TokenKind.TK_SEMICOLON and t != TokenKind.TK_EOF and t != TokenKind.TK_R_BRACE and t != TokenKind.TK_R_PAREN and t != TokenKind.TK_R_BRACKET:
        value = self.parse_expr()
    self.pool.add_node(NodeKind.NK_BREAK, start, self.prev_end(), value, label, 0)

fn Parser.parse_continue(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    var label = 0
    if self.peek() == TokenKind.TK_LABEL:
        let ls = self.current_start()
        let le = self.current_end()
        label = self.intern.intern(self.source.slice((ls + 1) as i64, le as i64))
        self.advance()
    self.pool.add_node(NodeKind.NK_CONTINUE, start, self.prev_end(), label, 0, 0)

// ── Match expression ─────────────────────────────────────────────

fn Parser.parse_match_expr(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    let saved_suppress_brace = self.suppress_brace
    self.suppress_brace = 1
    let subject = self.parse_expr()
    self.suppress_brace = saved_suppress_brace
    var inline_match = false
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    else if self.peek() == TokenKind.TK_L_BRACE:
        inline_match = true
        self.advance()
    else:
        self.emit_error("expected ':' or '{' after match subject")
        return self.poisoned_expr()
    if not inline_match:
        self.skip_newlines()
    let arm_count = if inline_match: self.parse_inline_match_arms() else: self.parse_match_arms()
    let extra_start = if arm_count > 0: self.pool.extra_len() - arm_count else: self.pool.extra_len()
    self.pool.add_node(NodeKind.NK_MATCH, start, self.prev_end(), subject, extra_start, arm_count)

fn Parser.parse_match_arms(self: Parser) -> i32:
    var arms: Vec[i32] = Vec.new()
    var arm_col = -1

    while self.peek() != TokenKind.TK_EOF:
        let t = self.peek()
        if not self.is_arm_token(t):
            break

        let cur_col = column_of(self.source, self.current_start())
        if arm_col >= 0 and cur_col != arm_col:
            break
        if arm_col < 0:
            arm_col = cur_col

        let arm_start = self.current_start()
        var pattern: NodeId = 0 as NodeId
        var in_guard_expr: NodeId = 0 as NodeId

        // `in expr` pattern: desugar to `__v if __v in expr`
        if self.peek() == TokenKind.TK_KW_IN:
            self.advance()
            let collection_expr = self.parse_expr()
            // Create binding pattern `__v`
            let bind_sym = self.intern.intern("__v")
            pattern = self.pool.add_node(NodeKind.NK_PAT_IDENT, arm_start, arm_start, bind_sym, 0, 0)
            // Build guard: `__v in collection`
            let bind_ref = self.pool.add_node(NodeKind.NK_IDENT, arm_start, arm_start, bind_sym, 0, 0)
            in_guard_expr = self.pool.add_node(NodeKind.NK_BINARY, arm_start, self.prev_end(), BinaryOp.OP_IN, bind_ref, collection_expr)
        else:
            pattern = self.parse_pattern()

        // Or-pattern: A | B | C
        if self.peek() == TokenKind.TK_PIPE:
            let or_patterns: Vec[i32] = Vec.new()
            or_patterns.push(pattern as i32)
            while self.peek() == TokenKind.TK_PIPE:
                self.advance()
                self.skip_newlines()
                let alt = self.parse_pattern()
                or_patterns.push(alt as i32)
            let or_start = self.pool.extra_len()
            let or_count = or_patterns.len() as i32
            for oi in 0..or_count:
                self.pool.add_extra(or_patterns.get(oi as i64))
            pattern = self.pool.add_node(NodeKind.NK_PAT_OR, arm_start, self.prev_end(), or_start, or_count, 0)

        // Guard clause
        var guard: NodeId = 0 as NodeId
        if in_guard_expr != 0:
            guard = in_guard_expr
        else if self.peek() == TokenKind.TK_KW_IF:
            self.advance()
            let saved_sfa = self.suppress_fat_arrow_closure
            self.suppress_fat_arrow_closure = 1
            guard = self.parse_expr()
            self.suppress_fat_arrow_closure = saved_sfa

        if self.expect(TokenKind.TK_FAT_ARROW) == 0:
            break
        var body: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_L_BRACE:
            self.advance()
            body = self.parse_braced_body()
        else:
            // Preserve a leading newline so parse_block_or_expr can recognize an
            // indented multi-statement arm body instead of truncating it to the
            // first expression and treating the tail as outer scope.
            body = self.parse_block_or_expr()

        let arm = self.pool.add_node(NodeKind.NK_MATCH_ARM, arm_start, self.prev_end(), pattern, body, guard)
        arms.push(arm as i32)

        let save = self.pos
        self.skip_newlines()
        if self.peek() == TokenKind.TK_EOF:
            break
        if not self.is_arm_token(self.peek()):
            self.pos = save
            break
        let next_col = column_of(self.source, self.current_start())
        if arm_col >= 0 and next_col != arm_col:
            self.pos = save
            break

    let arm_count = arms.len() as i32
    for ai in 0..arm_count:
        self.pool.add_extra(arms.get(ai as i64))
    arm_count

fn Parser.parse_inline_match_arms(self: Parser) -> i32:
    var arms: Vec[i32] = Vec.new()
    self.skip_newlines()
    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        let arm_start = self.current_start()
        var pattern: NodeId = 0 as NodeId
        var in_guard_expr: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_KW_IN:
            self.advance()
            let collection_expr = self.parse_expr()
            let bind_sym = self.intern.intern("__v")
            pattern = self.pool.add_node(NodeKind.NK_PAT_IDENT, arm_start, arm_start, bind_sym, 0, 0)
            let bind_ref = self.pool.add_node(NodeKind.NK_IDENT, arm_start, arm_start, bind_sym, 0, 0)
            in_guard_expr = self.pool.add_node(NodeKind.NK_BINARY, arm_start, self.prev_end(), BinaryOp.OP_IN, bind_ref, collection_expr)
        else:
            pattern = self.parse_pattern()
        if self.peek() == TokenKind.TK_PIPE:
            let or_patterns: Vec[i32] = Vec.new()
            or_patterns.push(pattern as i32)
            while self.peek() == TokenKind.TK_PIPE:
                self.advance()
                self.skip_newlines()
                let alt = self.parse_pattern()
                or_patterns.push(alt as i32)
            let or_start = self.pool.extra_len()
            let or_count = or_patterns.len() as i32
            for oi in 0..or_count:
                self.pool.add_extra(or_patterns.get(oi as i64))
            pattern = self.pool.add_node(NodeKind.NK_PAT_OR, arm_start, self.prev_end(), or_start, or_count, 0)
        var guard: NodeId = 0 as NodeId
        if in_guard_expr != 0:
            guard = in_guard_expr
        else if self.peek() == TokenKind.TK_KW_IF:
            self.advance()
            let saved_sfa2 = self.suppress_fat_arrow_closure
            self.suppress_fat_arrow_closure = 1
            guard = self.parse_expr()
            self.suppress_fat_arrow_closure = saved_sfa2
        if self.expect(TokenKind.TK_FAT_ARROW) == 0:
            break
        var body: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_L_BRACE:
            self.advance()
            body = self.parse_braced_body()
        else:
            body = self.parse_expr()
        let arm = self.pool.add_node(NodeKind.NK_MATCH_ARM, arm_start, self.prev_end(), pattern, body, guard)
        arms.push(arm as i32)
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
        else:
            break
    if self.peek() == TokenKind.TK_R_BRACE:
        self.advance()
    else:
        self.emit_error("expected '}' to close inline match")
    let arm_count = arms.len() as i32
    for ai in 0..arm_count:
        self.pool.add_extra(arms.get(ai as i64))
    arm_count

fn Parser.is_arm_token(self: Parser, t: i32) -> bool:
    t == TokenKind.TK_IDENT or t == TokenKind.TK_INT_LIT or t == TokenKind.TK_DOT_IDENT or t == TokenKind.TK_TRUE or t == TokenKind.TK_FALSE or t == TokenKind.TK_STRING_LIT or t == TokenKind.TK_MINUS or t == TokenKind.TK_L_BRACKET or t == TokenKind.TK_L_PAREN or t == TokenKind.TK_L_BRACE or t == TokenKind.TK_KW_IN

// ── Pattern parsing ──────────────────────────────────────────────

fn Parser.parse_pattern(self: Parser) -> NodeId:
    let start = self.current_start()
    let end = self.current_end()
    let t = self.peek()

    if t == TokenKind.TK_INT_LIT:
        let text = self.source.slice(start as i64, end as i64)
        self.advance()
        // Use full i64 parsing (parse_int clamps to i32 range, which silently
        // truncates pattern literals like META_END = 0x80000000 to i32 max,
        // breaking match dispatch on every value >= 2^31).
        let val64 = parse_i64(text)
        if self.peek() == TokenKind.TK_DOT_DOT or self.peek() == TokenKind.TK_DOT_DOT_EQ:
            let inclusive = if self.peek() == TokenKind.TK_DOT_DOT_EQ: 1 else: 0
            self.advance()
            let es = self.current_start()
            let ee = self.current_end()
            let etext = self.source.slice(es as i64, ee as i64)
            self.expect(TokenKind.TK_INT_LIT)
            let eval = parse_int(etext)
            return self.pool.add_node(NodeKind.NK_PAT_RANGE, start, self.prev_end(), val64 as i32, eval, inclusive)
        // Store the i64 value across d0/d1/d2 using the same 3-part encoding
        // as NK_INT_LIT, so int_lit_value() can decode it uniformly.
        return self.pool.add_node(NodeKind.NK_PAT_INT, start, end, ast_int_part0(val64), ast_int_part1(val64), ast_int_part2(val64))

    if t == TokenKind.TK_TRUE:
        let pat_end = self.current_end()
        self.advance()
        return self.pool.add_node(NodeKind.NK_PAT_BOOL, start, pat_end, 1, 0, 0)
    if t == TokenKind.TK_FALSE:
        let pat_end = self.current_end()
        self.advance()
        return self.pool.add_node(NodeKind.NK_PAT_BOOL, start, pat_end, 0, 0, 0)
    if t == TokenKind.TK_STRING_LIT:
        let pat_end = self.current_end()
        let raw = self.source.slice((start + 1) as i64, (pat_end - 1) as i64)
        let sym = self.intern.intern(raw)
        self.advance()
        return self.pool.add_node(NodeKind.NK_PAT_STRING, start, pat_end, sym, 0, 0)
    if t == TokenKind.TK_MINUS:
        self.advance()
        let ns = self.current_start()
        let ne = self.current_end()
        let text = self.source.slice(ns as i64, ne as i64)
        self.expect(TokenKind.TK_INT_LIT)
        let val64_neg = 0 - parse_i64(text)
        let val = val64_neg as i32
        if self.peek() == TokenKind.TK_DOT_DOT or self.peek() == TokenKind.TK_DOT_DOT_EQ:
            let inclusive = if self.peek() == TokenKind.TK_DOT_DOT_EQ: 1 else: 0
            self.advance()
            var eval = 0
            if self.peek() == TokenKind.TK_MINUS:
                self.advance()
                let es = self.current_start()
                let ee = self.current_end()
                let etext = self.source.slice(es as i64, ee as i64)
                self.expect(TokenKind.TK_INT_LIT)
                eval = 0 - parse_int(etext)
            else:
                let es = self.current_start()
                let ee = self.current_end()
                let etext = self.source.slice(es as i64, ee as i64)
                self.expect(TokenKind.TK_INT_LIT)
                eval = parse_int(etext)
            return self.pool.add_node(NodeKind.NK_PAT_RANGE, start, self.prev_end(), val, eval, inclusive)
        return self.pool.add_node(NodeKind.NK_PAT_INT, start, self.prev_end(), ast_int_part0(val64_neg), ast_int_part1(val64_neg), ast_int_part2(val64_neg))

    if t == TokenKind.TK_IDENT:
        let name = self.expect_ident()
        let name_str = self.intern.resolve(name)
        if name_str == "_":
            return self.pool.add_node(NodeKind.NK_PAT_WILDCARD, start, self.prev_end(), 0, 0, 0)
        if self.peek() == TokenKind.TK_DOT or self.peek() == TokenKind.TK_DOT_IDENT:
            var variant_name = 0
            if self.peek() == TokenKind.TK_DOT:
                self.advance()
                variant_name = self.expect_ident()
                if variant_name == 0:
                    return self.poisoned_expr()
            else:
                let dot_start = self.current_start()
                let dot_end = self.current_end()
                let dot_text = self.source.slice((dot_start + 1) as i64, dot_end as i64)
                variant_name = self.intern.intern(dot_text)
                self.advance()
            if self.peek() == TokenKind.TK_L_PAREN:
                self.advance()
                self.skip_newlines()
                let payload_patterns: Vec[i32] = Vec.new()
                while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    let inner = self.parse_pattern()
                    payload_patterns.push(inner as i32)
                    self.skip_newlines()
                    if self.peek() == TokenKind.TK_COMMA:
                        self.advance()
                        self.skip_newlines()
                self.skip_newlines()
                self.expect(TokenKind.TK_R_PAREN)
                let extra_start = self.pool.extra_len()
                let binding_count = payload_patterns.len() as i32
                for pi in 0..binding_count:
                    self.pool.add_extra(payload_patterns.get(pi as i64))
                let pat = self.pool.add_node(NodeKind.NK_PAT_VARIANT, start, self.prev_end(), variant_name, extra_start, binding_count)
                self.pool.add_pattern_qualifier(pat, name)
                return pat
            let pat = self.pool.add_node(NodeKind.NK_PAT_VARIANT, start, self.prev_end(), variant_name, 0, 0)
            self.pool.add_pattern_qualifier(pat, name)
            return pat
        // Variant with payload
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            self.skip_newlines()
            let payload_patterns: Vec[i32] = Vec.new()
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                let inner = self.parse_pattern()
                payload_patterns.push(inner as i32)
                self.skip_newlines()
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
            self.skip_newlines()
            self.expect(TokenKind.TK_R_PAREN)
            let extra_start = self.pool.extra_len()
            let binding_count = payload_patterns.len() as i32
            for pi in 0..binding_count:
                self.pool.add_extra(payload_patterns.get(pi as i64))
            return self.pool.add_node(NodeKind.NK_PAT_VARIANT, start, self.prev_end(), name, extra_start, binding_count)
        // Uppercase = unit variant
        if name_str.len() > 0 and name_str.byte_at(0 as i64) >= 65 and name_str.byte_at(0 as i64) <= 90:
            if self.peek() == TokenKind.TK_L_BRACE:
                return self.parse_struct_pattern(name, start)
            return self.pool.add_node(NodeKind.NK_PAT_VARIANT, start, self.prev_end(), name, 0, 0)
        // At-binding
        if self.peek() == TokenKind.TK_AT:
            self.advance()
            let inner = self.parse_pattern()
            return self.pool.add_node(NodeKind.NK_PAT_AT_BINDING, start, self.prev_end(), name, inner, 0)
        // Typed binding: ident: Type (for dyn trait matching)
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            let type_sym = self.expect_ident()
            return self.pool.add_node(NodeKind.NK_PAT_TYPED_BIND, start, self.prev_end(), name, type_sym, 0)
        // Variable binding
        return self.pool.add_node(NodeKind.NK_PAT_IDENT, start, self.prev_end(), name, 0, 0)

    if t == TokenKind.TK_DOT_IDENT:
        let dot_end = self.current_end()
        let text = self.source.slice((start + 1) as i64, dot_end as i64)
        let name = self.intern.intern(text)
        self.advance()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            self.skip_newlines()
            let payload_patterns: Vec[i32] = Vec.new()
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                let inner = self.parse_pattern()
                payload_patterns.push(inner as i32)
                self.skip_newlines()
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
            self.skip_newlines()
            self.expect(TokenKind.TK_R_PAREN)
            let extra_start = self.pool.extra_len()
            let binding_count = payload_patterns.len() as i32
            for pi in 0..binding_count:
                self.pool.add_extra(payload_patterns.get(pi as i64))
            return self.pool.add_node(NodeKind.NK_PAT_ENUM_SHORTHAND, start, self.prev_end(), name, extra_start, binding_count)
        return self.pool.add_node(NodeKind.NK_PAT_ENUM_SHORTHAND, start, self.prev_end(), name, 0, 0)

    if t == TokenKind.TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        let tuple_patterns: Vec[i32] = Vec.new()
        var saw_comma = false
        if self.peek() != TokenKind.TK_R_PAREN:
            let p = self.parse_pattern()
            tuple_patterns.push(p as i32)
            self.skip_newlines()
            while self.peek() == TokenKind.TK_COMMA:
                saw_comma = true
                self.advance()
                self.skip_newlines()
                if self.peek() == TokenKind.TK_R_PAREN:
                    break
                let p2 = self.parse_pattern()
                tuple_patterns.push(p2 as i32)
                self.skip_newlines()
        self.skip_newlines()
        self.expect(TokenKind.TK_R_PAREN)
        let extra_start = self.pool.extra_len()
        let count = tuple_patterns.len() as i32
        if count == 1 and not saw_comma:
            return tuple_patterns.get(0) as NodeId
        for ti in 0..count:
            self.pool.add_extra(tuple_patterns.get(ti as i64))
        return self.pool.add_node(NodeKind.NK_PAT_TUPLE, start, self.prev_end(), extra_start, count, 0)

    if t == TokenKind.TK_L_BRACE:
        return self.parse_struct_pattern(0, start)

    if t == TokenKind.TK_L_BRACKET:
        return self.parse_slice_pattern(start)

    self.emit_error("expected pattern")
    if self.peek() != TokenKind.TK_EOF:
        self.advance()
    self.poisoned_expr()

fn Parser.parse_struct_pattern(self: Parser, type_name: i32, start: i32) -> NodeId:
    self.advance()  // consume {
    self.skip_newlines()
    let field_entries: Vec[i32] = Vec.new()
    var has_rest = 0

    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        self.skip_newlines()
        if self.peek() == TokenKind.TK_DOT_DOT:
            has_rest = 1
            self.advance()
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
            self.skip_newlines()
            continue
        let fname = self.expect_ident()
        var fpat: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            fpat = self.parse_pattern()
        field_entries.push(fname)
        field_entries.push(fpat as i32)
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()

    self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(has_rest)
    let field_count = (field_entries.len() as i32) / 2
    for fi in 0..field_entries.len() as i32:
        self.pool.add_extra(field_entries.get(fi as i64))
    self.pool.add_node(NodeKind.NK_PAT_STRUCT, start, self.prev_end(), type_name, extra_start, field_count)

fn Parser.parse_slice_pattern(self: Parser, start: i32) -> NodeId:
    self.advance()  // consume [
    self.skip_newlines()
    let extra_start = self.pool.extra_len()
    var head_count = 0
    var rest_sym = 0
    var has_rest = 0
    let tail_syms: Vec[i32] = Vec.new()
    // Placeholder slots: has_rest, head_count will be set after
    let has_rest_idx = self.pool.add_extra(0)

    while self.peek() != TokenKind.TK_R_BRACKET and self.peek() != TokenKind.TK_EOF:
        if self.peek() == TokenKind.TK_DOT_DOT:
            has_rest = 1
            self.advance()
            if self.peek() == TokenKind.TK_IDENT:
                rest_sym = self.expect_ident()
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
            self.skip_newlines()
            continue
        if self.peek() == TokenKind.TK_IDENT:
            let name = self.expect_ident()
            if has_rest != 0:
                tail_syms.push(name)
            else:
                self.pool.add_extra(name)
                head_count = head_count + 1
        else:
            break
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()

    self.skip_newlines()
    self.expect(TokenKind.TK_R_BRACKET)
    self.pool.state.extra.set_i32(has_rest_idx as i64, has_rest)
    self.pool.add_extra(tail_syms.len() as i32)
    for ti in 0..tail_syms.len() as i32:
        self.pool.add_extra(tail_syms.get(ti as i64))
    self.pool.add_node(NodeKind.NK_PAT_SLICE, start, self.prev_end(), extra_start, head_count, rest_sym)

// ── Let binding expression ───────────────────────────────────────

fn Parser.parse_let_binding(self: Parser) -> NodeId:
    let start = self.current_start()
    let is_var = self.peek() == TokenKind.TK_KW_VAR
    self.advance()
    var is_mut = is_var
    if not is_var and self.peek() == TokenKind.TK_KW_MUT:
        self.emit_error("'let mut' is not supported; use 'var' for mutable bindings")
        is_mut = true
        self.advance()

    // Tuple destructuring (supports identifier, wildcard, and ..rest bindings).
    if self.peek() == TokenKind.TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        let names: Vec[i32] = Vec.new()
        while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
            // Rest pattern: ..name or ..
            if self.peek() == TokenKind.TK_DOT_DOT:
                self.advance()
                if self.peek() == TokenKind.TK_IDENT:
                    let rest_sym = self.intern_current()
                    self.advance()
                    // Use negative sym to mark rest binding
                    names.push(0 - rest_sym)
                else:
                    // .. without name: just discard remaining
                    names.push(0)
            else if self.peek() == TokenKind.TK_IDENT:
                let n_sym = self.intern_current()
                self.advance()
                if self.intern.resolve(n_sym) == "_":
                    names.push(0)
                else:
                    names.push(n_sym)
            else:
                self.emit_error("tuple destructuring requires identifier bindings")
                while self.peek() != TokenKind.TK_COMMA and self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    self.advance()

            self.skip_newlines()
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
            else:
                break

        self.expect(TokenKind.TK_R_PAREN)
        if self.expect(TokenKind.TK_EQ) == 0:
            return self.poisoned_expr()
        self.skip_newlines()
        let value = self.parse_expr()
        let extra_start = self.pool.extra_len()
        for ni in 0..names.len() as i32:
            self.pool.add_extra(names.get(ni as i64))
        return self.pool.add_node(NodeKind.NK_TUPLE_DESTRUCTURE, start, self.prev_end(), extra_start, names.len() as i32, value)

    // Let-else: with variant shorthand: let .Some(v) = expr else: body
    if self.peek() == TokenKind.TK_DOT_IDENT:
        let dot_start = self.current_start()
        let dot_end = self.current_end()
        let dot_text = self.source.slice((dot_start + 1) as i64, dot_end as i64)
        let dot_sym = self.intern.intern(dot_text)
        self.advance()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            self.skip_newlines()
            let extra_start = self.pool.extra_len()
            var binding_count = 0
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                let b = self.expect_ident()
                let pat_node = self.pool.add_node(NodeKind.NK_PAT_IDENT, self.prev_start(), self.prev_end(), b, 0, 0)
                self.pool.add_extra(pat_node)
                binding_count = binding_count + 1
                self.skip_newlines()
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
            self.skip_newlines()
            self.expect(TokenKind.TK_R_PAREN)
            if self.expect(TokenKind.TK_EQ) == 0:
                return self.poisoned_expr()
            self.skip_newlines()
            let value = self.parse_expr()
            self.expect(TokenKind.TK_KW_ELSE)
            if self.peek() == TokenKind.TK_COLON: self.advance()
            self.skip_newlines()
            let else_body = self.parse_block_or_expr()
            let pat = self.pool.add_node(NodeKind.NK_PAT_ENUM_SHORTHAND, dot_start, self.prev_end(), dot_sym, extra_start, binding_count)
            return self.pool.add_node(NodeKind.NK_LET_ELSE, start, self.prev_end(), pat, value, else_body)
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            let value = self.parse_expr()
            if self.peek() == TokenKind.TK_KW_ELSE:
                self.advance()
                if self.peek() == TokenKind.TK_COLON: self.advance()
                self.skip_newlines()
                let else_body = self.parse_block_or_expr()
                let pat = self.pool.add_node(NodeKind.NK_PAT_ENUM_SHORTHAND, dot_start, self.prev_end(), dot_sym, 0, 0)
                return self.pool.add_node(NodeKind.NK_LET_ELSE, start, self.prev_end(), pat, value, else_body)

    let name_sym = self.expect_ident()
    if name_sym == 0:
        return self.poisoned_expr()
    let name_str = self.intern.resolve(name_sym)
    let is_upper = name_str.len() > 0 and name_str.byte_at(0 as i64) >= 65 and name_str.byte_at(0 as i64) <= 90

    // Let-else: variant: let Some(x) = expr else: body
    if is_upper and self.peek() == TokenKind.TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        let extra_start = self.pool.extra_len()
        var binding_count = 0
        while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
            let b = self.expect_ident()
            let pat_node = self.pool.add_node(NodeKind.NK_PAT_IDENT, self.prev_start(), self.prev_end(), b, 0, 0)
            self.pool.add_extra(pat_node)
            binding_count = binding_count + 1
            self.skip_newlines()
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
        self.skip_newlines()
        self.expect(TokenKind.TK_R_PAREN)
        if self.expect(TokenKind.TK_EQ) == 0:
            return self.poisoned_expr()
        self.skip_newlines()
        let value = self.parse_expr()
        self.expect(TokenKind.TK_KW_ELSE)
        if self.peek() == TokenKind.TK_COLON: self.advance()
        self.skip_newlines()
        let else_body = self.parse_block_or_expr()
        let pat = self.pool.add_node(NodeKind.NK_PAT_VARIANT, start, self.prev_end(), name_sym, extra_start, binding_count)
        return self.pool.add_node(NodeKind.NK_LET_ELSE, start, self.prev_end(), pat, value, else_body)

    if is_upper and self.peek() == TokenKind.TK_EQ:
        self.advance()
        self.skip_newlines()
        let value = self.parse_expr()
        if self.peek() == TokenKind.TK_KW_ELSE:
            self.advance()
            if self.peek() == TokenKind.TK_COLON: self.advance()
            self.skip_newlines()
            let else_body = self.parse_block_or_expr()
            let pat = self.pool.add_node(NodeKind.NK_PAT_VARIANT, start, self.prev_end(), name_sym, 0, 0)
            return self.pool.add_node(NodeKind.NK_LET_ELSE, start, self.prev_end(), pat, value, else_body)
        // Normal let binding
        var flags = 0
        if is_mut:
            flags = 1
        return self.pool.add_node(NodeKind.NK_LET_BINDING, start, self.prev_end(), name_sym, value, flags)

    var type_ann: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        type_ann = self.parse_type_expr()

    // var x: T (no initializer) — zero-initialized if mutable with type annotation
    if self.peek() != TokenKind.TK_EQ:
        if is_mut and type_ann != 0:
            var flags = 1  // mut
            let type_extra = self.pool.extra_len()
            self.pool.add_extra(type_ann)
            flags = flags + (type_extra + 1) * 2
            return self.pool.add_node(NodeKind.NK_LET_BINDING, start, self.prev_end(), name_sym, 0, flags)
        if not is_mut:
            self.emit_error("let binding requires initializer")
            return self.poisoned_expr()
        self.emit_error("var without initializer requires type annotation")
        return self.poisoned_expr()

    self.advance()  // consume '='
    self.skip_newlines()
    let value = self.parse_expr()
    var flags = 0
    if is_mut:
        flags = 1
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        // Keep bit 0 for mut; encode optional type at bit 1+.
        flags = flags + (type_extra + 1) * 2
    self.pool.add_node(NodeKind.NK_LET_BINDING, start, self.prev_end(), name_sym, value, flags)

fn Parser.parse_const_binding(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()  // consume 'const'
    let name_sym = self.expect_ident()
    if name_sym == 0:
        return self.poisoned_expr()

    if self.peek() != TokenKind.TK_COLON:
        self.emit_error("const declaration requires a type annotation")
        return self.poisoned_expr()
    self.advance()
    let type_ann = self.parse_type_expr()

    if self.expect(TokenKind.TK_EQ) == 0:
        return self.poisoned_expr()
    self.skip_newlines()
    let raw_value = self.parse_expr()
    // const desugars to comptime-wrapped immutable let
    let value = self.pool.add_node(NodeKind.NK_COMPTIME, start, self.prev_end(), raw_value, 0, 0)

    var flags = 0
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        flags = flags + (type_extra + 1) * 2
    self.pool.add_node(NodeKind.NK_LET_BINDING, start, self.prev_end(), name_sym, value, flags)

// ── With expression ──────────────────────────────────────────────

fn Parser.parse_with_expr(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    // New syntax: with name(expr): body → NK_WITH_IMPLICIT
    if self.peek() == TokenKind.TK_IDENT:
        let save = self.pos
        let binding_name = self.intern_current()
        self.advance()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            self.skip_newlines()
            let source = self.parse_expr()
            self.skip_newlines()
            self.expect(TokenKind.TK_R_PAREN)
            let body = self.parse_body()
            return self.pool.add_node(NodeKind.NK_WITH_IMPLICIT, start, self.prev_end(), source, body, binding_name)
        self.pos = save
    // Existing syntax: with expr as name: body
    self.suppress_as = 1
    let source = self.parse_expr()
    self.suppress_as = 0
    if self.peek() != TokenKind.TK_KW_AS:
        self.emit_error("expected 'as' in with expression")
        return self.poisoned_expr()
    self.advance()
    var is_mut = 0
    if self.peek() == TokenKind.TK_KW_MUT:
        is_mut = 1
        self.advance()
    if self.peek() == TokenKind.TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        let names: Vec[i32] = Vec.new()
        while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
            if self.peek() == TokenKind.TK_IDENT:
                let n_sym = self.intern_current()
                self.advance()
                if self.intern.resolve(n_sym) == "_":
                    names.push(0)
                else:
                    names.push(n_sym)
            else:
                self.emit_error("tuple destructuring in 'with' requires identifier bindings")
                break
            self.skip_newlines()
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
            else:
                break
        self.expect(TokenKind.TK_R_PAREN)
        let tbody = self.parse_body()
        let extra_start = self.pool.extra_len()
        self.pool.add_extra(names.len() as i32)
        self.pool.add_extra(is_mut)
        for ni in 0..names.len() as i32:
            self.pool.add_extra(names.get(ni as i64))
        return self.pool.add_node(NodeKind.NK_WITH_TUPLE, start, self.prev_end(), source, tbody, extra_start)
    let name = self.expect_ident()
    let body = self.parse_body()
    let encoded_name = encode_with_binding(name, is_mut)
    self.pool.add_node(NodeKind.NK_WITH_EXPR, start, self.prev_end(), source, body, encoded_name)

// ── Record update ────────────────────────────────────────────────

fn Parser.parse_record_update(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()  // consume {
    self.skip_newlines()
    let source = self.parse_expr()
    if self.peek() != TokenKind.TK_KW_WITH:
        self.emit_error("expected 'with' in record update")
        return self.poisoned_expr()
    self.advance()
    self.skip_newlines()

    var fields: Vec[i32] = Vec.new()
    var field_count = 0
    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        let fname = self.expect_ident()
        var val: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            val = self.parse_expr()
        else:
            val = self.pool.add_node(NodeKind.NK_IDENT, start, self.prev_end(), fname, 0, 0)
        fields.push(fname)
        fields.push(val as i32)
        field_count = field_count + 1
        self.skip_newlines()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TokenKind.TK_R_BRACE)
    let extra_start = self.pool.extra_len()
    for fi in 0..fields.len() as i32:
        self.pool.add_extra(fields.get(fi as i64))
    self.pool.add_node(NodeKind.NK_RECORD_UPDATE, start, self.prev_end(), source, extra_start, field_count)

// ── Array literal / comprehension ────────────────────────────────

fn Parser.parse_array_literal(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()  // consume [
    self.skip_newlines()
    var elems: Vec[i32] = Vec.new()

    if self.peek() != TokenKind.TK_R_BRACKET:
        let first = self.parse_expr()

        // Array fill: [value; N]
        if self.peek() == TokenKind.TK_SEMICOLON:
            self.advance()  // consume ;
            let count_expr = self.parse_expr()
            self.expect(TokenKind.TK_R_BRACKET)
            // Desugar [value; N] to NodeKind.NK_ARRAY_LIT with N copies of value
            // For now, evaluate N as a constant and emit N copies
            var fill_count = 0
            if self.pool.kind(count_expr) == NodeKind.NK_INT_LIT:
                let fast = self.pool.int_literal_fast_i64(count_expr)
                if fast.ok != 0:
                    fill_count = fast.value as i32
            if fill_count <= 0:
                fill_count = 1
            let extra_start = self.pool.extra_len()
            for fi in 0..fill_count:
                self.pool.add_extra(first as i32)
            return self.pool.add_node(NodeKind.NK_ARRAY_LIT, start, self.prev_end(), extra_start, fill_count, 0)

        // Comprehension: [expr for x in iter]
        if self.peek() == TokenKind.TK_KW_FOR:
            self.advance()
            let binding = self.expect_ident()
            self.expect(TokenKind.TK_KW_IN)
            let iterable = self.parse_expr()
            var filter: NodeId = 0 as NodeId
            if self.peek() == TokenKind.TK_KW_IF:
                self.advance()
                filter = self.parse_expr()
            self.expect(TokenKind.TK_R_BRACKET)
            return self.pool.add_node(NodeKind.NK_ARRAY_COMPREHENSION, start, self.prev_end(), first, binding, iterable)

        elems.push(first as i32)

        while self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_R_BRACKET:
                break
            elems.push(self.parse_expr() as i32)

    self.expect(TokenKind.TK_R_BRACKET)
    let extra_start = self.pool.extra_len()
    let count = elems.len() as i32
    for ei in 0..count:
        self.pool.add_extra(elems.get(ei as i64))
    self.pool.add_node(NodeKind.NK_ARRAY_LIT, start, self.prev_end(), extra_start, count, 0)

// ── Closure ──────────────────────────────────────────────────────

// Scan ahead (non-consuming) to check if we're inside a paren closure.
// Called after consuming '(' (and possibly newlines).
// Returns 1 if matching ')' is followed by '=>' or '->', 0 otherwise.
fn Parser.scan_is_paren_closure(self: Parser) -> i32:
    var scan = self.pos
    var depth = 1
    while scan < self.tokens.len():
        let tag = self.tokens.get_tag(scan)
        if tag == TokenKind.TK_L_PAREN:
            depth = depth + 1
        else if tag == TokenKind.TK_R_PAREN:
            depth = depth - 1
            if depth == 0:
                let next = scan + 1
                if next < self.tokens.len():
                    let nt = self.tokens.get_tag(next)
                    if nt == TokenKind.TK_FAT_ARROW: return 1
                    if nt == TokenKind.TK_ARROW: return 1
                return 0
        else if tag == TokenKind.TK_EOF:
            return 0
        scan = scan + 1
    0

// Parse: IDENT => expr (single untyped parameter fat-arrow closure)
fn Parser.parse_fat_arrow_single(self: Parser) -> NodeId:
    let start = self.current_start()
    let param_sym = self.expect_ident()
    self.expect(TokenKind.TK_FAT_ARROW)
    let extra_start = self.pool.extra_len()
    self.pool.add_extra(param_sym)
    self.pool.add_extra(0)
    let body = self.parse_block_or_expr()
    self.pool.add_node(NodeKind.NK_CLOSURE, start, self.prev_end(), body, extra_start, 1)

// Parse: (params) [-> RetType] => expr (paren fat-arrow closure)
// Starts at '(' token.
fn Parser.parse_fat_arrow_paren_closure(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()  // consume (
    self.skip_newlines()
    let extra_start = self.pool.extra_len()
    var param_count = 0
    while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
        if self.peek() == TokenKind.TK_KW_IT:
            self.emit_error("'it' is a reserved keyword and cannot be used as a parameter name")
            self.advance()
            self.pool.add_extra(0)
            self.pool.add_extra(0)
            param_count = param_count + 1
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
            continue
        let p = self.expect_ident()
        if p == 0:
            self.advance()
            continue
        self.pool.add_extra(p as i32)
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            let ty = self.parse_type_expr()
            self.pool.add_extra(ty as i32)
        else:
            self.pool.add_extra(0)
        param_count = param_count + 1
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TokenKind.TK_R_PAREN)
    self.skip_newlines()
    // Optional return type
    if self.peek() == TokenKind.TK_ARROW:
        self.advance()
        self.parse_type_expr()
        self.skip_newlines()
    self.expect(TokenKind.TK_FAT_ARROW)
    let body = self.parse_block_or_expr()
    self.pool.add_node(NodeKind.NK_CLOSURE, start, self.prev_end(), body, extra_start, param_count)

fn Parser.parse_closure(self: Parser) -> NodeId:
    let start = self.current_start()
    self.expect(TokenKind.TK_PIPE)
    let extra_start = self.pool.extra_len()
    var param_count = 0
    while self.peek() != TokenKind.TK_PIPE and self.peek() != TokenKind.TK_EOF:
        if self.peek() == TokenKind.TK_KW_IT:
            self.emit_error("'it' is a reserved keyword and cannot be used as a parameter name")
            self.advance()
            self.pool.add_extra(0)
            self.pool.add_extra(0)
            param_count = param_count + 1
            if self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
            continue
        let p = self.expect_ident()
        if p == 0:
            self.advance()
            continue
        self.pool.add_extra(p as i32)
        // Optional type
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            let ty = self.parse_type_expr()
            self.pool.add_extra(ty as i32)
        else:
            self.pool.add_extra(0)
        param_count = param_count + 1
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
    self.expect(TokenKind.TK_PIPE)
    self.skip_newlines()

    // Optional return type
    if self.peek() == TokenKind.TK_ARROW:
        self.advance()
        self.parse_type_expr()
        self.skip_newlines()

    var body: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_L_BRACE:
        self.advance()
        body = self.parse_braced_body()
    else if self.peek() == TokenKind.TK_COLON:
        self.advance()
        body = self.parse_block_or_expr()
    else:
        body = self.parse_expr()
    self.pool.add_node(NodeKind.NK_CLOSURE, start, self.prev_end(), body, extra_start, param_count)

fn Parser.parse_move_closure(self: Parser) -> NodeId:
    let node = self.parse_closure()
    if node != 0:
        self.pool.mark_move_closure(node)
    node

// ── Block / indentation parsing ──────────────────────────────────

fn Parser.parse_body(self: Parser) -> NodeId:
    if self.peek() == TokenKind.TK_L_BRACE:
        self.advance()
        return self.parse_braced_body()
    else if self.peek() == TokenKind.TK_COLON:
        self.advance()
        return self.parse_block_or_expr()
    else:
        self.emit_error("expected ':' or '{' to introduce body")
        return self.parse_block_or_expr()

fn Parser.parse_block_or_expr(self: Parser) -> NodeId:
    if self.peek() != TokenKind.TK_NEWLINE:
        return self.parse_expr()

    self.skip_newlines()
    if self.peek() == TokenKind.TK_EOF:
        self.emit_error("expected expression")
        return self.poisoned_expr()

    let block_col = column_of(self.source, self.current_start())
    var stmts: Vec[i32] = Vec.new()
    var last_expr = self.parse_expr()

    while true:
        let cur = self.peek()
        if cur == TokenKind.TK_EOF:
            break
        // After error recovery, the current token may be a statement keyword
        // (not a newline). Check column to decide if it's still in this block.
        if cur != TokenKind.TK_NEWLINE and cur != TokenKind.TK_SEMICOLON:
            let cur_col = column_of(self.source, self.current_start())
            if cur_col >= block_col and (cur == TokenKind.TK_KW_LET or cur == TokenKind.TK_KW_VAR or cur == TokenKind.TK_KW_RETURN or cur == TokenKind.TK_KW_IF or cur == TokenKind.TK_KW_FOR or cur == TokenKind.TK_KW_WHILE or cur == TokenKind.TK_KW_MATCH or cur == TokenKind.TK_KW_BREAK or cur == TokenKind.TK_KW_CONTINUE or cur == TokenKind.TK_KW_GOTO or cur == TokenKind.TK_LABEL or cur == TokenKind.TK_KW_DEFER):
                stmts.push(last_expr as i32)
                last_expr = self.parse_expr()
                continue
            break

        let save = self.pos
        self.skip_separators()
        if self.peek() == TokenKind.TK_EOF:
            break
        let next_col = column_of(self.source, self.current_start())
        if next_col < block_col:
            self.pos = save
            break

        stmts.push(last_expr as i32)
        last_expr = self.parse_expr()

    if stmts.len() == 0:
        return last_expr

    let extra_start = self.pool.extra_len()
    for i in 0..stmts.len() as i32:
        self.pool.add_extra(stmts.get(i as i64))

    let stmt_count = stmts.len() as i32
    let blk_node = self.pool.add_node(NodeKind.NK_BLOCK, self.pool.get_start(stmts.get(0)), self.pool.get_end(last_expr), extra_start, stmt_count, last_expr)
    blk_node

fn Parser.parse_braced_body(self: Parser) -> NodeId:
    let brace_start = self.prev_end()
    self.skip_separators()
    if self.peek() == TokenKind.TK_R_BRACE:
        let end = self.current_end()
        self.advance()
        return self.pool.add_node(NodeKind.NK_BLOCK, brace_start, end, 0, 0, 0)

    var stmts: Vec[i32] = Vec.new()
    var last_expr = self.parse_expr()

    while true:
        let cur = self.peek()
        if cur == TokenKind.TK_EOF or cur == TokenKind.TK_R_BRACE:
            break
        if cur == TokenKind.TK_NEWLINE or cur == TokenKind.TK_SEMICOLON:
            while self.peek() == TokenKind.TK_NEWLINE or self.peek() == TokenKind.TK_SEMICOLON:
                self.advance()
            if self.peek() == TokenKind.TK_R_BRACE or self.peek() == TokenKind.TK_EOF:
                break
            stmts.push(last_expr as i32)
            last_expr = self.parse_expr()
            continue
        break

    self.expect(TokenKind.TK_R_BRACE)

    if stmts.len() == 0:
        return last_expr

    let extra_start = self.pool.extra_len()
    for i in 0..stmts.len() as i32:
        self.pool.add_extra(stmts.get(i as i64))
    let stmt_count = stmts.len() as i32
    self.pool.add_node(NodeKind.NK_BLOCK, self.pool.get_start(stmts.get(0)), self.pool.get_end(last_expr), extra_start, stmt_count, last_expr)

// ── Type expression parsing ──────────────────────────────────────

fn Parser.parse_type_expr(self: Parser) -> NodeId:
    let t = self.peek()
    let start = self.current_start()

    // @TypeOf(expr) — compile-time type of expression
    if t == TokenKind.TK_AT:
        self.advance()
        if self.is_ident_named("TypeOf"):
            self.advance()
            if self.expect(TokenKind.TK_L_PAREN) == 0:
                return self.poisoned_expr()
            self.skip_newlines()
            let inner = self.parse_expr()
            self.skip_newlines()
            if self.expect(TokenKind.TK_R_PAREN) == 0:
                return self.poisoned_expr()
            return self.pool.add_node(NodeKind.NK_TYPE_TYPEOF, start, self.prev_end(), inner, 0, 0)
        self.emit_error("expected 'TypeOf' after '@' in type position")
        return self.poisoned_expr()

    if t == TokenKind.TK_AMPERSAND:
        self.advance()
        var is_mut = 0
        if self.peek() == TokenKind.TK_KW_MUT:
            is_mut = 1
            self.advance()
        let pointee = self.parse_type_expr()
        return self.pool.add_node(NodeKind.NK_TYPE_REF, start, self.prev_end(), pointee, is_mut, 0)

    if t == TokenKind.TK_QUESTION:
        self.advance()
        let inner = self.parse_type_expr()
        return self.pool.add_node(NodeKind.NK_TYPE_OPTIONAL, start, self.prev_end(), inner, 0, 0)

    if t == TokenKind.TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        var elems: Vec[i32] = Vec.new()
        if self.peek() != TokenKind.TK_R_PAREN:
            let ty = self.parse_type_expr()
            elems.push(ty as i32)
            self.skip_newlines()
            while self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
                if self.peek() == TokenKind.TK_R_PAREN:
                    break
                let ty2 = self.parse_type_expr()
                elems.push(ty2 as i32)
                self.skip_newlines()
        self.skip_newlines()
        self.expect(TokenKind.TK_R_PAREN)
        let extra_start = self.pool.extra_len()
        for ei in 0..elems.len() as i32:
            self.pool.add_extra(elems.get(ei as i64))
        let count = elems.len() as i32
        return self.pool.add_node(NodeKind.NK_TYPE_TUPLE, start, self.prev_end(), extra_start, count, 0)

    if t == TokenKind.TK_KW_FN:
        self.advance()
        self.expect(TokenKind.TK_L_PAREN)
        self.skip_newlines()
        var params: Vec[i32] = Vec.new()
        if self.peek() != TokenKind.TK_R_PAREN:
            let ty = self.parse_type_expr()
            params.push(ty as i32)
            self.skip_newlines()
            while self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
                if self.peek() == TokenKind.TK_R_PAREN:
                    break
                let ty2 = self.parse_type_expr()
                params.push(ty2 as i32)
                self.skip_newlines()
        self.skip_newlines()
        self.expect(TokenKind.TK_R_PAREN)
        self.expect(TokenKind.TK_ARROW)
        let ret = self.parse_type_expr()
        let extra_start = self.pool.extra_len()
        for pi in 0..params.len() as i32:
            self.pool.add_extra(params.get(pi as i64))
        let count = params.len() as i32
        return self.pool.add_node(NodeKind.NK_TYPE_FN, start, self.prev_end(), extra_start, count, ret)

    if t == TokenKind.TK_STAR:
        self.advance()
        var is_mut = 0
        var is_volatile = 0
        if self.peek() == TokenKind.TK_KW_MUT:
            is_mut = 1
            self.advance()
        else if self.peek() == TokenKind.TK_KW_CONST:
            self.advance()
        else if self.is_ident_named("volatile"):
            is_mut = 1
            is_volatile = 1
            self.advance()
        let pointee = self.parse_type_expr()
        return self.pool.add_node(NodeKind.NK_TYPE_PTR, start, self.prev_end(), pointee, is_mut, is_volatile)

    if t == TokenKind.TK_L_BRACKET:
        self.advance()
        self.skip_newlines()
        // []T → slice type
        if self.peek() == TokenKind.TK_R_BRACKET:
            self.advance()
            self.skip_newlines()
            let elem = self.parse_type_expr()
            return self.pool.add_node(NodeKind.NK_TYPE_SLICE, start, self.prev_end(), elem, 0, 0)
        // [N]T → fixed array (legacy), detect by leading int literal
        if self.peek() == TokenKind.TK_INT_LIT:
            let ss = self.current_start()
            let se = self.current_end()
            let size_text = self.source.slice(ss as i64, se as i64)
            let size = parse_int(size_text)
            self.advance()
            self.skip_newlines()
            self.expect(TokenKind.TK_R_BRACKET)
            self.skip_newlines()
            let elem = self.parse_type_expr()
            return self.pool.add_node(NodeKind.NK_TYPE_ARRAY, start, self.prev_end(), elem, size, 0)
        // [T; N] → fixed array (spec syntax), OR [T] → slice
        let elem = self.parse_type_expr()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_SEMICOLON:
            self.advance()  // consume ;
            self.skip_newlines()
            if self.peek() != TokenKind.TK_INT_LIT:
                self.emit_error("expected array size after ';'")
                return self.poisoned_expr()
            let ss = self.current_start()
            let se = self.current_end()
            let size_text = self.source.slice(ss as i64, se as i64)
            let size = parse_int(size_text)
            self.advance()
            self.skip_newlines()
            self.expect(TokenKind.TK_R_BRACKET)
            return self.pool.add_node(NodeKind.NK_TYPE_ARRAY, start, self.prev_end(), elem, size, 0)
        // [T] → slice type
        self.skip_newlines()
        self.expect(TokenKind.TK_R_BRACKET)
        return self.pool.add_node(NodeKind.NK_TYPE_SLICE, start, self.prev_end(), elem, 0, 0)

    if t == TokenKind.TK_KW_DYN:
        self.advance()
        if self.peek() != TokenKind.TK_IDENT:
            self.emit_error("expected trait name after 'dyn'")
            return self.poisoned_expr()
        let sym = self.intern_current()
        self.advance()
        return self.pool.add_node(NodeKind.NK_TYPE_TRAIT_OBJ, start, self.prev_end(), sym, 0, 0)

    if t == TokenKind.TK_KW_IMPL:
        self.advance()
        if self.peek() != TokenKind.TK_IDENT:
            self.emit_error("expected trait name after 'impl'")
            return self.poisoned_expr()
        let sym = self.intern_current()
        self.advance()
        if self.peek() == TokenKind.TK_KW_FOR:
            self.advance()
        let target = self.parse_type_expr()
        if target == 0:
            return self.poisoned_expr()
        return self.pool.add_node(NodeKind.NK_TYPE_TRAIT_OBJ, start, self.prev_end(), sym, 0, 0)

    if t == TokenKind.TK_IDENT:
        let sym = self.intern_current()
        self.advance()
        if self.peek() == TokenKind.TK_DOT_IDENT:
            // Self.Output — dot + uppercase ident combined by lexer
            let dot_s = self.current_start()
            let dot_e = self.current_end()
            let assoc_text = self.source.slice((dot_s + 1) as i64, dot_e as i64)
            let assoc_sym = self.intern.intern(assoc_text)
            self.advance()
            return self.pool.add_node(NodeKind.NK_TYPE_ASSOC, start, self.prev_end(), sym, assoc_sym, 0)
        if self.peek() == TokenKind.TK_DOT:
            // Self.output — dot + lowercase ident are separate tokens
            self.advance()
            let assoc_sym = self.expect_ident()
            return self.pool.add_node(NodeKind.NK_TYPE_ASSOC, start, self.prev_end(), sym, assoc_sym, 0)
        if self.peek() == TokenKind.TK_L_BRACKET:
            self.advance()
            self.skip_newlines()
            var args: Vec[i32] = Vec.new()
            if self.peek() != TokenKind.TK_R_BRACKET:
                while self.peek() != TokenKind.TK_R_BRACKET and self.peek() != TokenKind.TK_EOF:
                    let ty = self.parse_type_expr()
                    args.push(ty as i32)
                    self.skip_newlines()
                    if self.peek() != TokenKind.TK_COMMA:
                        break
                    self.advance()
                    self.skip_newlines()
                    if self.peek() == TokenKind.TK_R_BRACKET:
                        break
            self.skip_newlines()
            self.expect(TokenKind.TK_R_BRACKET)
            let extra_start = self.pool.extra_len()
            for ai in 0..args.len() as i32:
                self.pool.add_extra(args.get(ai as i64))
            let count = args.len() as i32
            return self.pool.add_node(NodeKind.NK_TYPE_GENERIC, start, self.prev_end(), sym, extra_start, count)
        return self.pool.add_node(NodeKind.NK_TYPE_NAMED, start, self.prev_end(), sym, 0, 0)

    self.emit_error("expected type")
    if self.peek() != TokenKind.TK_EOF:
        self.advance()
    self.poisoned_expr()

// ── Parameter list ───────────────────────────────────────────────

fn Parser.parse_param_attrs(self: Parser) -> i32:
    var flags = 0
    while self.peek() == TokenKind.TK_AT:
        self.advance()
        if self.peek() != TokenKind.TK_L_BRACKET:
            self.emit_error("expected '[' after '@' in parameter attribute")
            break
        self.advance()

        if self.peek() == TokenKind.TK_IDENT:
            let attr_start = self.current_start()
            let attr_end = self.current_end()
            let attr_text = self.source.slice(attr_start as i64, attr_end as i64)
            if attr_text == "noalias":
                flags = flags + FN_PARAM_FLAG_NOALIAS
            else:
                self.emit_error("unknown parameter attribute")
            self.advance()
        else:
            self.emit_error("expected parameter attribute name")
        self.expect(TokenKind.TK_R_BRACKET)
        self.skip_newlines()
    flags

fn Parser.parse_param_list(self: Parser) -> i32:
    var params: Vec[i32] = Vec.new()
    var default_nodes: Vec[i32] = Vec.new()
    let pattern_start = self.pool.fn_param_patterns_len()
    var pattern_count = 0
    var required_count = 0
    self.last_param_pattern_start = pattern_start
    self.last_param_pattern_count = 0
    self.last_param_required_count = 0
    self.skip_newlines()
    if self.peek() == TokenKind.TK_R_PAREN or self.peek() == TokenKind.TK_DOT_DOT_DOT:
        return 0
    while true:
        self.skip_newlines()
        let param_flags = self.parse_param_attrs()
        var is_mut = 0
        if self.peek() == TokenKind.TK_KW_MUT:
            is_mut = 1
            self.advance()

        var name = 0
        var param_pattern: NodeId = 0 as NodeId
        if self.peek() == TokenKind.TK_IDENT:
            name = self.expect_ident()
        else:
            let t = self.peek()
            if t == TokenKind.TK_L_PAREN or t == TokenKind.TK_L_BRACE or t == TokenKind.TK_L_BRACKET or t == TokenKind.TK_DOT_IDENT:
                param_pattern = self.parse_pattern()
                let synth = f"__param_pat_{self.pos}_{(params.len() / (FN_PARAM_STRIDE as i64)) as i32}"
                name = self.intern.intern(synth)
            else:
                name = self.expect_ident()
        if name == 0:
            break

        var type_node: NodeId = 0 as NodeId
        var extra_flags = 0
        // docs/mut.md Rev 8 §5.1 — `mut self: Self` is a receiver-place mode.
        // Tag the param so later sema phases can require a mutable place at
        // the call site without re-inspecting the AST.
        if is_mut == 1 and name != 0 and self.intern.resolve(name) == "self":
            extra_flags = extra_flags + FN_PARAM_FLAG_MUT_SELF
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            // Check for 'implicit' keyword before type
            if self.peek() == TokenKind.TK_IDENT:
                let maybe_implicit = self.intern_current()
                if self.intern.resolve(maybe_implicit) == "implicit":
                    extra_flags = extra_flags + FN_PARAM_FLAG_IMPLICIT
                    self.advance()
                    self.skip_newlines()
            type_node = self.parse_type_expr()

        // Default value
        var default_node = 0
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            default_node = self.parse_expr() as i32
        if default_node == 0:
            required_count = required_count + 1

        params.push(name)
        params.push(type_node as i32)
        params.push(param_flags + extra_flags)
        default_nodes.push(default_node)
        self.pool.add_fn_param_pattern_value(param_pattern)
        pattern_count = pattern_count + 1

        if self.peek() != TokenKind.TK_COMMA:
            break
        self.advance()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_R_PAREN or self.peek() == TokenKind.TK_DOT_DOT_DOT:
            break

    let count = (params.len() / (FN_PARAM_STRIDE as i64)) as i32
    let param_start = self.pool.extra_len()
    for pi in 0..params.len() as i32:
        self.pool.add_extra(params.get(pi as i64))
    // Store default value nodes for params that have them
    for di in 0..default_nodes.len() as i32:
        let def = default_nodes.get(di as i64)
        if def != 0:
            self.pool.set_fn_param_default(param_start, di, def)
    self.last_param_pattern_start = pattern_start
    self.last_param_pattern_count = pattern_count
    self.last_param_required_count = required_count
    count

fn Parser.parse_one_param(self: Parser) -> i32:
    let param_flags = self.parse_param_attrs()
    var is_mut = 0
    if self.peek() == TokenKind.TK_KW_MUT:
        is_mut = 1
        self.advance()
    let name = self.expect_ident()
    if name == 0:
        return 0
    var type_node: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        type_node = self.parse_type_expr()
    // Default value
    if self.peek() == TokenKind.TK_EQ:
        self.advance()
        self.parse_expr()
    self.pool.add_extra(name)
    self.pool.add_extra(type_node as i32)
    self.pool.add_extra(param_flags)
    1

// ── Type parameters ──────────────────────────────────────────────

fn Parser.parse_type_params(self: Parser) -> i32:
    if self.peek() != TokenKind.TK_L_BRACKET:
        return 0
    self.advance()
    self.skip_newlines()
    var count = 0
    if self.peek() != TokenKind.TK_R_BRACKET:
        count = count + self.parse_one_type_param()
        while self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_R_BRACKET:
                break
            count = count + self.parse_one_type_param()
    self.skip_newlines()
    self.expect(TokenKind.TK_R_BRACKET)
    count

fn Parser.parse_one_type_param(self: Parser) -> i32:
    if self.peek() == TokenKind.TK_KW_CONST:
        self.emit_error("const generics are reserved for future use")
        self.advance()
    let name = self.expect_ident()
    self.pool.add_extra(name)
    let count_idx = self.pool.add_extra(0)
    var bound_count = 0
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        self.skip_newlines()
        let b = self.parse_type_bound_symbol()
        self.pool.add_extra(b)
        bound_count = bound_count + 1
        while self.peek() == TokenKind.TK_PLUS:
            self.advance()
            self.skip_newlines()
            let b2 = self.parse_type_bound_symbol()
            self.pool.add_extra(b2)
            bound_count = bound_count + 1
    self.pool.state.extra.set_i32(count_idx as i64, bound_count)
    1

fn Parser.parse_type_bound_symbol(self: Parser) -> i32:
    if self.peek() == TokenKind.TK_IDENT:
        let sym = self.expect_ident()
        // Consume optional parameterized bound: Trait[Item=Type, ...] or Trait[T]
        if self.peek() == TokenKind.TK_L_BRACKET:
            self.advance()
            var depth = 1
            while depth > 0 and self.peek() != TokenKind.TK_EOF:
                if self.peek() == TokenKind.TK_L_BRACKET:
                    depth = depth + 1
                if self.peek() == TokenKind.TK_R_BRACKET:
                    depth = depth - 1
                    if depth == 0:
                        self.advance()
                        break
                self.advance()
        return sym
    if self.peek() == TokenKind.TK_KW_TYPE:
        self.advance()
        return self.intern.intern("type")
    self.emit_error("expected type bound name")
    0

fn Parser.parse_optional_where_clause(self: Parser):
    self.last_where_start = 0
    self.last_where_count = 0
    if self.peek() != TokenKind.TK_KW_WHERE and not self.is_ident_named("where"):
        return
    self.advance()
    // Collect all where clause entries into local vecs first
    var wp_syms: Vec[i32] = Vec.new()
    var wp_bound_starts: Vec[i32] = Vec.new()
    var wp_bound_counts: Vec[i32] = Vec.new()
    var wp_bounds_flat: Vec[i32] = Vec.new()
    while self.peek() == TokenKind.TK_IDENT:
        let type_param = self.intern_current()
        self.advance()
        self.expect(TokenKind.TK_COLON)
        wp_syms.push(type_param)
        wp_bound_starts.push(wp_bounds_flat.len() as i32)
        var bound_count = 0
        let b = self.parse_type_bound_symbol()
        if b != 0:
            wp_bounds_flat.push(b)
            bound_count = bound_count + 1
        while self.peek() == TokenKind.TK_PLUS:
            self.advance()
            let b2 = self.parse_type_bound_symbol()
            if b2 != 0:
                wp_bounds_flat.push(b2)
                bound_count = bound_count + 1
        wp_bound_counts.push(bound_count)
        if self.peek() != TokenKind.TK_COMMA:
            break
        self.advance()
    // Now write to extra pool: [type_param, bound_count, bounds...]*
    self.last_where_start = self.pool.extra_len()
    self.last_where_count = wp_syms.len() as i32
    for wi in 0..self.last_where_count:
        self.pool.add_extra(wp_syms.get(wi as i64))
        let bc = wp_bound_counts.get(wi as i64)
        self.pool.add_extra(bc)
        let bs = wp_bound_starts.get(wi as i64)
        for bi in 0..bc:
            self.pool.add_extra(wp_bounds_flat.get((bs + bi) as i64))

// ── Integer parsing helper ───────────────────────────────────────

fn parse_int(text: str) -> i32:
    let value = parse_i64(text)
    if value < -2147483648:
        return (0 - 2147483648) as i32
    if value > 2147483647:
        return 2147483647
    value as i32

fn parse_i64(text: str) -> i64:
    let base_text = numeric_literal_core(text)
    let len = base_text.len() as i32
    if len == 0:
        return 0
    if len > 2 and base_text.byte_at(0) == 48 and (base_text.byte_at(1) == 120 or base_text.byte_at(1) == 88):
        var val: i64 = 0
        var i = 2
        while i < len:
            let ch = base_text.byte_at(i as i64)
            if ch == 95:
                i = i + 1
                continue
            var digit: i64 = 0
            if ch >= 48 and ch <= 57:
                digit = (ch - 48) as i64
            else if ch >= 97 and ch <= 102:
                digit = (ch - 87) as i64
            else if ch >= 65 and ch <= 70:
                digit = (ch - 55) as i64
            val = val * 16 + digit
            i = i + 1
        return val
    if len > 2 and base_text.byte_at(0) == 48 and (base_text.byte_at(1) == 98 or base_text.byte_at(1) == 66):
        var val: i64 = 0
        var i = 2
        while i < len:
            let ch = base_text.byte_at(i as i64)
            if ch == 95:
                i = i + 1
                continue
            let digit = if ch == 49: 1 else: 0
            val = val * 2 + digit
            i = i + 1
        return val
    if len > 2 and base_text.byte_at(0) == 48 and (base_text.byte_at(1) == 111 or base_text.byte_at(1) == 79):
        var val: i64 = 0
        var i = 2
        while i < len:
            let ch = base_text.byte_at(i as i64)
            if ch == 95:
                i = i + 1
                continue
            let digit = (ch - 48) as i64
            val = val * 8 + digit
            i = i + 1
        return val
    var clean = ""
    var i = 0
    while i < len:
        let ch = base_text.byte_at(i as i64)
        if ch != 95:
            clean = clean ++ str_from_byte(ch)
        i = i + 1
    with_parse_i64(clean)
