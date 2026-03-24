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

extern fn int_to_string(n: i32) -> str
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
    pending_derive_start: i32,
    pending_derive_count: i32,
    pending_sealed: i32,
    pending_flags: i32,
    pending_packed: i32,
    pending_callconv: i32,
    pending_unsafe_fn: i32,
    saw_implicit_it: i32,
    implicit_it_depth: i32,
    last_param_pattern_start: i32,
    last_param_pattern_count: i32,
    last_param_required_count: i32,
    last_where_start: i32,
    last_where_count: i32,
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
        pending_derive_start: 0,
        pending_derive_count: 0,
        pending_sealed: 0,
        pending_flags: 0,
        pending_packed: 0,
        pending_callconv: 0,
        pending_unsafe_fn: 0,
        saw_implicit_it: 0,
        implicit_it_depth: 0,
        last_param_pattern_start: 0,
        last_param_pattern_count: 0,
        last_param_required_count: 0,
        last_where_start: 0,
        last_where_count: 0,
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
    if tag == TokenKind.TK_KW_WHERE or tag == TokenKind.TK_KW_OPAQUE or tag == TokenKind.TK_KW_NULL or tag == TokenKind.TK_KW_UNION or tag == TokenKind.TK_KW_ENUM:
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

fn Parser.peek_past_newlines(self: Parser) -> i32:
    var p = self.pos
    while p < self.tokens.len() and self.tokens.get_tag(p) == TokenKind.TK_NEWLINE:
        p = p + 1
    if p < self.tokens.len():
        return self.tokens.get_tag(p)
    TokenKind.TK_EOF

fn Parser.emit_error(self: Parser, msg: str):
    let span = Span { file: self.file_id, start: self.current_start(), end: self.current_end() }
    self.diags.emit(Diagnostic.err(msg, span))

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
    self.pending_sealed = 0
    self.pending_flags = 0
    self.pending_packed = 0
    self.pending_callconv = 0
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
                    self.pending_callconv = self.intern_current()
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
    self.skip_newlines()

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
        self.skip_newlines()

    while self.peek() != TokenKind.TK_EOF:
        self.skip_newlines()
        self.skip_attributes()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_EOF:
            break

        if self.peek() == TokenKind.TK_KW_PUB:
            let saved_pos = self.pos
            self.advance()
            if self.peek() == TokenKind.TK_KW_IMPL or self.peek() == TokenKind.TK_KW_EXTEND:
                self.parse_impl_block(Visibility.Public)
                self.skip_newlines()
                continue
            if self.peek() == TokenKind.TK_KW_TRAIT:
                self.parse_trait_decl(Visibility.Public)
                self.skip_newlines()
                continue
            self.pos = saved_pos
        else if self.peek() == TokenKind.TK_KW_IMPL or self.peek() == TokenKind.TK_KW_EXTEND:
            self.parse_impl_block(Visibility.Private)
            self.skip_newlines()
            continue
        else if self.peek() == TokenKind.TK_KW_TRAIT:
            self.parse_trait_decl(Visibility.Private)
            self.skip_newlines()
            continue

        let decl = self.parse_decl()
        if decl != 0:
            self.pool.add_decl(decl)
        else:
            self.recover_to_top_level()
        self.skip_newlines()

    self.pool

// ── Declaration parsing ──────────────────────────────────────────

fn Parser.parse_decl(self: Parser) -> i32:
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
            return 0
        self.pending_unsafe_fn = 1
        let result = self.parse_fn_decl(is_pub, start, 0, 0, 0)
        self.pending_unsafe_fn = 0
        return result
    if t == TokenKind.TK_KW_COMPTIME:
        self.advance()
        if self.peek() != TokenKind.TK_KW_FN:
            self.emit_error("expected 'fn' after 'comptime'")
            return 0
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
    if t == TokenKind.TK_KW_LET or t == TokenKind.TK_KW_VAR:
        return self.parse_top_level_let(is_pub, start)
    if t == TokenKind.TK_KW_EXTERN:
        return self.parse_extern_decl(start)
    if t == TokenKind.TK_KW_ERROR:
        return self.parse_error_decl(is_pub, start)
    if t == TokenKind.TK_KW_CONST:
        return self.parse_const_decl(is_pub, start)

    self.emit_error("expected declaration (fn, type, enum, let, use, extern)")
    0

// ── fn decl ──────────────────────────────────────────────────────

fn Parser.parse_fn_decl(self: Parser, is_pub: i32, start: i32, is_async: i32, is_gen: i32, is_comptime: i32) -> i32:
    if self.expect(TokenKind.TK_KW_FN) == 0:
        return 0
    var name = self.expect_ident_or_keyword()
    if name == 0:
        return 0

    // Method syntax: fn Type.method(...)
    if self.peek() == TokenKind.TK_DOT:
        self.advance()
        let method_name = self.expect_ident_or_keyword()
        if method_name == 0:
            return 0
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
            return 0

    // Return type
    var ret_type = 0
    if self.peek() == TokenKind.TK_ARROW:
        self.advance()
        ret_type = self.parse_type_expr()

    // Where clause
    self.parse_optional_where_clause()

    // Body
    if self.peek() == TokenKind.TK_EQ or self.peek() == TokenKind.TK_COLON:
        self.advance()
    else:
        self.emit_error("expected '=' or ':'")
        return 0
    let body = self.parse_block_or_expr()
    if body == 0:
        return 0

    // Build flags
    var flags = 0
    if is_pub == Visibility.Public:
        flags = flags + FnFlags.FN_FLAG_PUB
    if is_async != 0:
        flags = flags + FnFlags.FN_FLAG_ASYNC
    if is_gen != 0:
        flags = flags + FnFlags.FN_FLAG_GEN
    if is_comptime != 0:
        flags = flags + FnFlags.FN_FLAG_COMPTIME
    if self.pending_tailrec != 0:
        flags = flags + FnFlags.FN_FLAG_TAILREC
    if self.pending_must_use != 0:
        flags = flags + FnFlags.FN_FLAG_MUST_USE
    if self.pending_inline != 0:
        flags = flags + FnFlags.FN_FLAG_INLINE
    if self.pending_noinline != 0:
        flags = flags + FnFlags.FN_FLAG_NOINLINE
    if self.pending_panic_handler != 0:
        flags = flags + FnFlags.FN_FLAG_PANIC_HANDLER
    if self.pending_entry != 0:
        flags = flags + FnFlags.FN_FLAG_ENTRY
    if self.pending_no_main != 0:
        flags = flags + FnFlags.FN_FLAG_NO_MAIN
    if self.pending_test != 0:
        flags = flags + FnFlags.FN_FLAG_TEST
    if self.pending_before != 0:
        flags = flags + FnFlags.FN_FLAG_BEFORE
    if self.pending_after != 0:
        flags = flags + FnFlags.FN_FLAG_AFTER

    // Store extra: type params then params already in extra from parsing.
    // We encode: d0=name, d1=body, d2=flags
    // For unsafe fn, wrap body in NodeKind.NK_UNSAFE_BLOCK
    var final_body = body
    if self.pending_unsafe_fn != 0:
        final_body = self.pool.add_node(NodeKind.NK_UNSAFE_BLOCK, self.pool.get_start(body), self.pool.get_end(body), body, 0, 0)
    let fn_node = self.pool.add_node(NodeKind.NK_FN_DECL, start, self.pool.get_end(body), name, final_body, flags)
    let meta_flags = flags + required_param_count * FN_META_REQUIRED_UNIT
    self.pool.add_fn_meta(fn_node, meta_flags, ret_type, params_start, param_count, tp_start, tp_count)
    self.pool.add_fn_param_pattern_meta(fn_node, self.last_param_pattern_start, self.last_param_pattern_count)
    if self.last_where_count > 0:
        self.pool.add_where_meta(fn_node, self.last_where_start, self.last_where_count)
    fn_node

// ── extern fn ────────────────────────────────────────────────────

fn Parser.parse_extern_decl(self: Parser, start: i32) -> i32:
    if self.expect(TokenKind.TK_KW_EXTERN) == 0:
        return 0
    // Optional ABI string: extern "C" fn ...
    if self.peek() == TokenKind.TK_STRING_LIT:
        self.advance()
    // extern let NAME: TYPE  or  extern var NAME: TYPE
    if self.peek() == TokenKind.TK_KW_LET or self.peek() == TokenKind.TK_KW_VAR:
        let is_mut = if self.peek() == TokenKind.TK_KW_VAR: 1 else: 0
        self.advance()
        let ev_name = self.expect_ident()
        if ev_name == 0: return 0
        if self.expect(TokenKind.TK_COLON) == 0: return 0
        let ev_type = self.parse_type_expr()
        return self.pool.add_node(NodeKind.NK_EXTERN_VAR, start, self.prev_end(), ev_name, ev_type, is_mut)
    if self.expect(TokenKind.TK_KW_FN) == 0:
        return 0
    let name = self.expect_ident()
    if name == 0:
        return 0
    if self.expect(TokenKind.TK_L_PAREN) == 0:
        return 0

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
        return 0

    var ret_type = 0
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

fn Parser.parse_type_decl(self: Parser, is_pub: i32, start: i32) -> i32:
    if self.expect(TokenKind.TK_KW_TYPE) == 0:
        return 0
    let name = self.expect_ident()
    if name == 0:
        return 0

    let tp_start = self.pool.extra_len()
    let tp_count = self.parse_type_params()
    self.parse_optional_where_clause()

    var repr_type_node = 0
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
        let node = self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), name, extra_start, struct_kind)
        return self.finish_type_decl(node)

    if self.peek() != TokenKind.TK_EQ:
        self.emit_error("expected type body")
        return 0

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
            return 0
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
    0

fn Parser.parse_enum_decl(self: Parser, is_pub: i32, start: i32) -> i32:
    if self.expect(TokenKind.TK_KW_ENUM) == 0:
        return 0
    let name = self.expect_ident()
    if name == 0:
        return 0

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

fn Parser.parse_enum_named_decl(self: Parser, start: i32, name: i32, is_pub: i32, tp_start: i32, tp_count: i32, is_ephemeral: i32) -> i32:
    var repr_type_node = 0
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
                    return 0
    else:
        if self.peek() == TokenKind.TK_L_BRACE:
            use_braced_body = 1
        else:
            self.emit_error("expected enum body")
            return 0

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

fn Parser.finish_type_decl(self: Parser, node: i32) -> i32:
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
        var field_default = 0
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            field_default = self.parse_expr()

        fields.push(field_name)
        fields.push(field_type)
        fields.push(field_default)
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
        var field_default = 0
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            field_default = self.parse_expr()

        fields.push(field_name)
        fields.push(field_type)
        fields.push(field_default)
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
                payloads.push(pty)
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
                payloads.push(pty)
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
                payloads.push(pty)
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
                payloads.push(pty)
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
                payloads.push(pty)
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
                payloads.push(pty)
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

fn Parser.parse_use_decl(self: Parser, start: i32) -> i32:
    if self.expect(TokenKind.TK_KW_USE) == 0:
        return 0

    // use c_import("header.h")
    if self.peek() == TokenKind.TK_KW_C_IMPORT:
        return self.parse_c_import(start)

    let extra_start = self.pool.extra_len()
    var path_count = 0

    let first = self.peek()
    if first == TokenKind.TK_IDENT or parser_is_keyword_tag(first):
        let sym = self.expect_use_path_segment()
        if sym == 0:
            return 0
        self.pool.add_extra(sym)
        path_count = path_count + 1

    while true:
        if self.peek() == TokenKind.TK_DOT:
            self.advance()
            let next = self.peek()
            if next == TokenKind.TK_IDENT or parser_is_keyword_tag(next):
                let sym = self.expect_use_path_segment()
                if sym == 0:
                    return 0
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
        return 0

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

fn Parser.parse_c_import(self: Parser, start: i32) -> i32:
    self.advance()  // consume c_import
    if self.expect(TokenKind.TK_L_PAREN) == 0:
        return 0
    if self.peek() != TokenKind.TK_STRING_LIT:
        self.emit_error("expected string literal after c_import(")
        return 0
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
            return 0
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

fn Parser.parse_top_level_let(self: Parser, is_pub: i32, start: i32) -> i32:
    let is_var = self.peek() == TokenKind.TK_KW_VAR
    self.advance()
    var is_mut = is_var
    if not is_var and self.peek() == TokenKind.TK_KW_MUT:
        is_mut = true
        self.advance()
    let name = self.expect_ident()
    if name == 0:
        return 0

    var type_ann = 0
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        type_ann = self.parse_type_expr()

    if self.expect(TokenKind.TK_EQ) == 0:
        return 0
    self.skip_newlines()
    let value = self.parse_expr()
    if value == 0:
        return 0

    var flags = 0
    if is_mut:
        flags = flags + 1
    if is_pub == Visibility.Public:
        flags = flags + 2
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        // Keep lower 2 bits for mut/pub; encode optional type at bit 2+.
        flags = flags + (type_extra + 1) * 4

    self.pool.add_node(NodeKind.NK_LET_DECL, start, self.prev_end(), name, value, flags)

fn Parser.parse_const_decl(self: Parser, is_pub: i32, start: i32) -> i32:
    self.advance()  // consume 'const'
    let name = self.expect_ident()
    if name == 0:
        return 0

    if self.peek() != TokenKind.TK_COLON:
        self.emit_error("const declaration requires a type annotation")
        return 0
    self.advance()
    let type_ann = self.parse_type_expr()

    if self.expect(TokenKind.TK_EQ) == 0:
        return 0
    self.skip_newlines()
    let raw_value = self.parse_expr()
    if raw_value == 0:
        return 0
    // const desugars to comptime-wrapped immutable let
    let value = self.pool.add_node(NodeKind.NK_COMPTIME, start, self.prev_end(), raw_value, 0, 0)

    var flags = 0
    if is_pub == Visibility.Public:
        flags = flags + 2
    if type_ann != 0:
        let type_extra = self.pool.extra_len()
        self.pool.add_extra(type_ann)
        flags = flags + (type_extra + 1) * 4

    self.pool.add_node(NodeKind.NK_LET_DECL, start, self.prev_end(), name, value, flags)

// ── error decl (desugars to enum) ────────────────────────────────

fn Parser.parse_error_decl(self: Parser, is_pub: i32, start: i32) -> i32:
    self.advance()  // consume 'error'
    let err_name = self.expect_ident()
    if err_name == 0:
        return 0

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
        self.pool.extra.set_i32(count_idx as i64, variant_count)
        self.pool.add_extra(is_pub)
        self.pool.add_extra(0)
        self.pool.add_extra(0)
        return self.pool.add_node(NodeKind.NK_TYPE_DECL, start, self.prev_end(), err_name, extra_start, pack_type_decl_kind(TypeDeclKind.Enum, 0))

    // error Name = Variant1, Variant2(payload), ...
    if self.expect(TokenKind.TK_EQ) == 0:
        return 0
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
    if self.peek() == TokenKind.TK_EQ or self.peek() == TokenKind.TK_COLON:
        self.advance()
    else:
        self.emit_error("expected '=' or ':'")
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

    while self.peek() == TokenKind.TK_KW_FN or self.peek() == TokenKind.TK_KW_PUB or self.peek() == TokenKind.TK_KW_TYPE or self.peek() == TokenKind.TK_KW_ASYNC:
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
            var default_ty = 0
            if self.peek() == TokenKind.TK_EQ:
                self.advance()
                default_ty = self.parse_type_expr()
            assoc_names.push(at_name)
            assoc_bound_starts.push(bound_start)
            assoc_bound_counts.push(bound_count)
            assoc_default_types.push(default_ty)
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

        var ret_type = 0
        if self.peek() == TokenKind.TK_ARROW:
            self.advance()
            ret_type = self.parse_type_expr()

        self.parse_optional_where_clause()

        var method_body = 0
        if self.peek() == TokenKind.TK_EQ or self.peek() == TokenKind.TK_COLON:
            self.advance()
            method_body = self.parse_block_or_expr()

        method_names.push(mname)
        method_param_starts.push(params_start)
        method_param_counts.push(param_count)
        method_ret_types.push(ret_type)
        method_bodies.push(method_body)
        var mflags = 0
        if is_async_method != 0:
            mflags = mflags + 1
        if is_pub_method != 0:
            mflags = mflags + 2
        if m_tp_count > 0:
            mflags = mflags + 4
        method_flags.push(mflags)
        self.skip_newlines()

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
fn Parser.parse_optional_impl_target_args(self: Parser, type_name: i32) -> i32:
    if self.peek() != TokenKind.TK_L_BRACKET:
        return 0
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    var args: Vec[i32] = Vec.new()
    while self.peek() != TokenKind.TK_R_BRACKET and self.peek() != TokenKind.TK_EOF:
        let ty = self.parse_type_expr()
        args.push(ty)
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
    var target_type_node = 0
    var trait_arg_extra_start = 0
    var trait_arg_count = 0
    if self.peek() == TokenKind.TK_L_BRACKET:
        self.advance()
        self.skip_newlines()
        trait_arg_extra_start = self.pool.extra_len()
        while self.peek() != TokenKind.TK_R_BRACKET and self.peek() != TokenKind.TK_EOF:
            let arg = self.parse_type_expr()
            self.pool.add_extra(arg)
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

    if self.peek() == TokenKind.TK_EQ or self.peek() == TokenKind.TK_COLON:
        self.advance()
    self.skip_newlines()

    var impl_assoc_names: Vec[i32] = Vec.new()
    var impl_assoc_types: Vec[i32] = Vec.new()
    let extra_start = self.pool.extra_len()
    var method_count = 0

    while self.peek() == TokenKind.TK_KW_FN or self.peek() == TokenKind.TK_KW_PUB or self.peek() == TokenKind.TK_KW_ASYNC or self.peek() == TokenKind.TK_KW_TYPE:
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
            impl_assoc_types.push(at_type)
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

        var ret_type = 0
        if self.peek() == TokenKind.TK_ARROW:
            self.advance()
            ret_type = self.parse_type_expr()

        self.parse_optional_where_clause()

        if self.peek() == TokenKind.TK_EQ or self.peek() == TokenKind.TK_COLON:
            self.advance()
        else:
            self.emit_error("expected '=' or ':'")
            break
        let body = self.parse_block_or_expr()

        var flags = 0
        if method_vis == Visibility.Public:
            flags = flags + FnFlags.FN_FLAG_PUB
        if m_async != 0:
            flags = flags + FnFlags.FN_FLAG_ASYNC

        let fn_node = self.pool.add_node(NodeKind.NK_FN_DECL, method_start, self.prev_end(), mangled, body, flags)
        let meta_flags = flags + required_param_count * FN_META_REQUIRED_UNIT
        self.pool.add_fn_meta(fn_node, meta_flags, ret_type, m_params_start, param_count, m_tp_start, m_tp_count)
        self.pool.add_decl(fn_node)
        method_count = method_count + 1
        self.skip_newlines()

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

fn Parser.parse_expr(self: Parser) -> i32:
    let lhs = self.parse_precedence(0)
    if lhs == 0:
        return 0

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
    -1

// ── Pratt precedence climbing ────────────────────────────────────

fn Parser.parse_precedence(self: Parser, min_prec: i32) -> i32:
    var lhs = self.parse_primary()
    if lhs == 0:
        return 0
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
    if t == TokenKind.TK_STAR: return 12 * 1000 + BinaryOp.OP_MUL
    if t == TokenKind.TK_SLASH: return 12 * 1000 + BinaryOp.OP_DIV
    if t == TokenKind.TK_PERCENT: return 12 * 1000 + BinaryOp.OP_MOD
    if t == TokenKind.TK_STAR_WRAP: return 12 * 1000 + BinaryOp.OP_MUL_WRAP
    0

// ── Primary expression ──────────────────────────────────────────

fn Parser.parse_primary(self: Parser) -> i32:
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
        if self.pos + 1 < self.tokens.len():
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
    if t == TokenKind.TK_LABEL: return self.parse_labeled_loop()
    if t == TokenKind.TK_KW_UNSAFE: return self.parse_unsafe()
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
        return 0
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
        return 0

    self.emit_error("expected expression")
    0

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

fn Parser.parse_int_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    let suffix = numeric_literal_suffix_code(text)
    let core = numeric_literal_core(text)
    self.advance()
    let val = parse_i64(core)
    let node = self.pool.add_node(NodeKind.NK_INT_LIT, start, end, ast_int_part0(val), ast_int_part1(val), ast_int_part2(val))
    self.pool.set_literal_suffix(node, suffix)
    node

fn Parser.parse_float_literal(self: Parser) -> i32:
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

fn Parser.parse_comptime_error_expr(self: Parser) -> i32:
    let ce_s = self.current_start()
    self.advance()
    self.advance()
    let ce_msg = self.intern_current()
    self.advance()
    if self.peek() == TokenKind.TK_R_PAREN:
        self.advance()
    self.pool.add_node(NodeKind.NK_COMPTIME_ERROR, ce_s, self.prev_end(), ce_msg, 0, 0)

fn Parser.parse_string_literal(self: Parser) -> i32:
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

fn Parser.desugar_interpolated_string(self: Parser, content: str, start: i32, end: i32) -> i32:
    // Emit NodeKind.NK_FSTRING with segments in extra_data.
    // d0 = segment_count, d1 = extra_start, d2 = 0
    let clen = content.len() as i32
    let extra_start = self.pool.extra_len()
    var seg_count = 0
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
            // Emit text segment before the {
            if i > seg_start:
                let seg_text = self.interp_clean_segment(content, seg_start, i)
                let sym = self.intern.intern(seg_text)
                self.pool.add_extra(FSTR_SEG_LITERAL)
                self.pool.add_extra(sym)
                seg_count = seg_count + 1
            // Find matching } while tracking colon for format spec
            var depth = 1
            var expr_start_pos = i + 1
            var j = expr_start_pos
            var colon_pos = -1
            while j < clen and depth > 0:
                let jch = content.byte_at(j as i64)
                if jch == 123: depth = depth + 1
                if jch == 125: depth = depth - 1
                // Track top-level colon (only at depth==1, before closing })
                if depth == 1 and jch == 58 and colon_pos == -1:
                    colon_pos = j
                if depth > 0: j = j + 1
            // Extract expression text (up to colon or closing brace)
            var expr_end_pos = j
            if colon_pos > 0:
                expr_end_pos = colon_pos
            let expr_text = content.slice(expr_start_pos as i64, expr_end_pos as i64)
            let expr_node = self.parse_interpolated_expr(expr_text, start)
            // Parse format spec if colon present
            var spec_node = 0
            if colon_pos > 0:
                let spec_text = content.slice((colon_pos + 1) as i64, j as i64)
                spec_node = self.parse_format_spec_text(spec_text, start, end)
            // Emit FSTR_SEG_EXPR: kind, expr_node, spec_node
            self.pool.add_extra(FSTR_SEG_EXPR)
            self.pool.add_extra(expr_node)
            self.pool.add_extra(spec_node)
            seg_count = seg_count + 1
            i = j + 1  // skip past }
            seg_start = i
        else if ch == 125 and i + 1 < clen and content.byte_at((i + 1) as i64) == 125:
            // }} → literal }
            i = i + 2
            continue
        else:
            i = i + 1
    // Emit trailing text segment
    if seg_start < clen:
        let seg_text = self.interp_clean_segment(content, seg_start, clen)
        let sym = self.intern.intern(seg_text)
        self.pool.add_extra(FSTR_SEG_LITERAL)
        self.pool.add_extra(sym)
        seg_count = seg_count + 1
    // Handle empty f-string
    if seg_count == 0:
        let sym = self.intern.intern("")
        self.pool.add_extra(FSTR_SEG_LITERAL)
        self.pool.add_extra(sym)
        seg_count = 1
    let node = self.pool.add_node(NodeKind.NK_FSTRING, start, end, seg_count, extra_start, 0)
    self.parse_postfix(node)

fn Parser.interp_clean_segment(self: Parser, content: str, from: i32, to: i32) -> str:
    // Extract raw segment. Escaped {{ and }} stay as-is for now — the lexer
    // already consumed them. The desugar loop skips over {{ and }} pairs,
    // so they don't appear in segments adjacent to holes.
    content.slice(from as i64, to as i64)

fn Parser.parse_format_spec_text(self: Parser, spec_text: str, start: i32, end: i32) -> i32:
    // Parse format spec grammar: [[fill]align][sign]['#']['0'][width]['.' precision][mode]
    // Returns NodeKind.NK_FSTRING_SPEC node, or 0 if empty
    let slen = spec_text.len() as i32
    if slen == 0:
        return 0
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

fn Parser.parse_interpolated_expr(self: Parser, expr_text: str, base_start: i32) -> i32:
    // Re-lex and parse the expression text
    var lexer = Lexer.init(expr_text, 0)
    let tokens = lexer.tokenize()
    var sub_parser = Parser.init_with_pool(tokens, expr_text, 0, self.intern, self.diags, self.pool)
    let result = sub_parser.parse_expr()
    // Sync the intern pool back
    self.intern = sub_parser.intern
    self.pool = sub_parser.pool
    result

fn Parser.parse_c_string_literal(self: Parser) -> i32:
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

fn Parser.parse_bool_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let val = if self.peek() == TokenKind.TK_TRUE: 1 else: 0
    self.advance()
    self.pool.add_node(NodeKind.NK_BOOL_LIT, start, end, val, 0, 0)

fn Parser.parse_char_literal(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let text = self.source.slice(start as i64, end as i64)
    self.advance()
    // Stage0 parity: char literals lower to integer literals.
    // Supported escapes mirror bootstrap parser behavior.
    var value = 0
    // Support b'X' byte literals as a char-literal token form.
    let base = if text.len() >= 1 and text.byte_at((0) as i64) == 98: 2 else: 1
    if text.len() >= base + 3 and text.byte_at((base) as i64) == 92:  // '\'
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
        value = text.byte_at((base) as i64) as i32
    let value64 = value as i64
    self.pool.add_node(NodeKind.NK_INT_LIT, start, end, ast_int_part0(value64), ast_int_part1(value64), ast_int_part2(value64))

fn strip_string_token_text(text: str) -> str:
    // f"..." → content between f" and closing "
    if text.len() >= 3 and text.byte_at(0) == 102 and text.byte_at(1) == 34:  // f"
        return text.slice(2, text.len() as i64 - 1)
    if text.len() >= 2 and text.byte_at((0) as i64) == 114:  // r
        var i = 1
        while i < text.len() as i32 and text.byte_at((i) as i64) == 35:  // #
            i = i + 1
        if i < text.len() as i32 and text.byte_at((i) as i64) == 34:  // opening "
            let content_start = i + 1
            var end_q = text.len() as i32 - 1
            while end_q >= content_start and text.byte_at((end_q) as i64) == 35:
                end_q = end_q - 1
            if end_q >= content_start and text.byte_at((end_q) as i64) == 34:
                return text.slice(content_start as i64, end_q as i64)

    if text.len() >= 6 and text.slice(0, 3) == "\"\"\"":
        var content = text.slice(3, text.len() as i64 - 3)
        if content.len() > 0 and content.byte_at((0) as i64) == 10:
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
    if text.byte_at((0) as i64) != 114:  // r
        return false
    var i = 1
    while i < text.len() as i32 and text.byte_at((i) as i64) == 35:  // #
        i = i + 1
    if i < text.len() as i32 and text.byte_at((i) as i64) == 34:  // "
        return true
    false

fn dedent_multiline(text: str) -> str:
    let len = text.len() as i32
    var min_indent = 0 - 1
    var line_start = 0
    var i = 0
    while i <= len:
        if i == len or text.byte_at((i) as i64) == 10:
            var j = line_start
            while j < i and (text.byte_at((j) as i64) == 32 or text.byte_at((j) as i64) == 9):
                j = j + 1
            var has_non_ws = 0
            var k = j
            while k < i:
                if text.byte_at((k) as i64) != 32 and text.byte_at((k) as i64) != 9:
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
        if i == len or text.byte_at((i) as i64) == 10:
            var cut = min_indent
            var j = line_start
            while cut > 0 and j < i and (text.byte_at((j) as i64) == 32 or text.byte_at((j) as i64) == 9):
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

fn Parser.parse_ident_or_call(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let sym = self.intern_current()
    self.advance()
    let node = self.pool.add_node(NodeKind.NK_IDENT, start, end, sym, 0, 0)
    self.parse_postfix(node)

// ── Postfix parsing ──────────────────────────────────────────────

fn Parser.parse_postfix(self: Parser, lhs_in: i32) -> i32:
    var lhs = lhs_in
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
            // Struct literal only when lhs is an identifier
            if self.pool.kind(lhs) != NodeKind.NK_IDENT:
                return lhs
            lhs = self.parse_struct_literal(lhs)
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

fn Parser.maybe_wrap_implicit_it(self: Parser, expr: i32) -> i32:
    let it_sym = self.intern.intern("__it")
    let param_start = self.pool.extra_len()
    self.pool.add_extra(it_sym)
    self.pool.add_extra(0)
    self.pool.add_node(NodeKind.NK_CLOSURE, self.pool.get_start(expr), self.pool.get_end(expr), expr, param_start, 1)

fn Parser.parse_call(self: Parser, callee: i32) -> i32:
    self.advance()  // consume (
    self.skip_newlines()
    var args: Vec[i32] = Vec.new()
    if self.peek() != TokenKind.TK_R_PAREN:
        while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
            // Named argument: name: value → skip the name label
            if self.peek() == TokenKind.TK_IDENT:
                let save = self.pos
                self.advance()
                if self.peek() == TokenKind.TK_COLON:
                    self.advance()
                    self.skip_newlines()
                else:
                    self.pos = save
            let outer_it = self.saw_implicit_it
            let outer_depth = self.implicit_it_depth
            self.saw_implicit_it = 0
            var arg = self.parse_expr()
            if self.saw_implicit_it == 1:
                self.implicit_it_depth = self.implicit_it_depth - 1
                arg = self.maybe_wrap_implicit_it(arg)
            self.saw_implicit_it = outer_it
            self.implicit_it_depth = outer_depth
            args.push(arg)
            self.skip_newlines()
            if self.peek() != TokenKind.TK_COMMA:
                break
            self.advance()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_R_PAREN:
                break
    self.skip_newlines()
    self.expect(TokenKind.TK_R_PAREN)
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
        self.pool.add_extra(arg)
    let call_node = self.pool.add_node(NodeKind.NK_CALL, self.pool.get_start(callee), self.prev_end(), callee, extra_start, arg_count)

    if placeholder_count == 0:
        return call_node

    let param_start = self.pool.extra_len()
    let param_count = partial_param_syms.len() as i32
    for pi in 0..param_count:
        self.pool.add_extra(partial_param_syms.get(pi as i64))
        self.pool.add_extra(0)
    self.pool.add_node(NodeKind.NK_CLOSURE, self.pool.get_start(callee), self.prev_end(), call_node, param_start, param_count)

fn Parser.parse_dot(self: Parser, lhs: i32) -> i32:
    self.advance()  // consume .
    // .await
    if self.peek() == TokenKind.TK_KW_AWAIT:
        self.advance()
        return self.pool.add_node(NodeKind.NK_AWAIT, self.pool.get_start(lhs), self.prev_end(), lhs, 0, 0)
    // Tuple field .0 .1
    if self.peek() == TokenKind.TK_INT_LIT:
        let field = self.intern_current()
        self.advance()
        return self.pool.add_node(NodeKind.NK_FIELD_ACCESS, self.pool.get_start(lhs), self.prev_end(), lhs, field, 0)
    let field = self.expect_ident_or_keyword()
    self.pool.add_node(NodeKind.NK_FIELD_ACCESS, self.pool.get_start(lhs), self.prev_end(), lhs, field, 0)

fn Parser.build_composed_closure(self: Parser, lhs_fn: i32, rhs_fn: i32, is_forward: i32) -> i32:
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

fn Parser.parse_struct_literal(self: Parser, lhs: i32) -> i32:
    let struct_name = self.pool.get_data0(lhs)
    self.advance()  // consume {
    self.skip_newlines()
    var fields: Vec[i32] = Vec.new()
    var field_count = 0
    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        let fname = self.expect_ident()
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            let val = self.parse_expr()
            fields.push(fname)
            fields.push(val)
        else:
            // Shorthand: name means name: name
            let ident_node = self.pool.add_node(NodeKind.NK_IDENT, self.pool.get_start(lhs), self.prev_end(), fname, 0, 0)
            fields.push(fname)
            fields.push(ident_node)
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

fn Parser.parse_index_or_slice(self: Parser, lhs: i32) -> i32:
    self.advance()  // consume [
    self.skip_newlines()
    let index = self.parse_index_expr()
    self.skip_newlines()
    if self.peek() == TokenKind.TK_DOT_DOT:
        self.advance()
        self.skip_newlines()
        var end_expr = 0
        if self.peek() != TokenKind.TK_R_BRACKET:
            end_expr = self.parse_expr()
            self.skip_newlines()
        self.expect(TokenKind.TK_R_BRACKET)
        return self.pool.add_node(NodeKind.NK_SLICE, self.pool.get_start(lhs), self.prev_end(), lhs, index, end_expr)
    // Support two-arg subscript for HashMap[K, V].new() syntax
    var second = 0
    if self.peek() == TokenKind.TK_COMMA:
        self.advance()
        self.skip_newlines()
        second = self.parse_index_expr()
        self.skip_newlines()
    self.expect(TokenKind.TK_R_BRACKET)
    self.pool.add_node(NodeKind.NK_INDEX, self.pool.get_start(lhs), self.prev_end(), lhs, index, second)

fn Parser.parse_index_expr(self: Parser) -> i32:
    self.parse_precedence(6)

fn Parser.parse_optional_chain(self: Parser, lhs: i32) -> i32:
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
            args.push(self.parse_expr())
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

fn Parser.parse_variant_shorthand(self: Parser) -> i32:
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
            args.push(self.parse_expr())
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

fn Parser.parse_grouped_or_tuple(self: Parser) -> i32:
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
        elems.push(first)
        while self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_R_PAREN:
                break
            let elem = self.parse_expr()
            elems.push(elem)
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

fn Parser.parse_unary_negate(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    if self.peek() == TokenKind.TK_INT_LIT:
        let end = self.current_end()
        let text = self.source.slice(start as i64 + 1, end as i64)
        if numeric_literal_suffix_code(text) == LiteralSuffix.None:
            let value = 0 - parse_i64(text)
            self.advance()
            return self.pool.add_node(NodeKind.NK_INT_LIT, start, end, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value))
    let operand = self.parse_primary()
    self.pool.add_node(NodeKind.NK_UNARY, start, self.prev_end(), UnaryOp.UOP_NEGATE, operand, 0)

fn Parser.parse_unary_bit_not(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let operand = self.parse_primary()
    self.pool.add_node(NodeKind.NK_UNARY, start, self.prev_end(), UnaryOp.UOP_BIT_NOT, operand, 0)

fn Parser.parse_unary_not(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let operand = self.parse_primary()
    self.pool.add_node(NodeKind.NK_UNARY, start, self.prev_end(), UnaryOp.UOP_NOT, operand, 0)

fn Parser.build_unary_with_outer_cast(self: Parser, start: i32, op: i32, operand: i32) -> i32:
    if operand != 0 and self.pool.kind(operand) == NodeKind.NK_CAST:
        let inner = self.pool.get_data0(operand)
        let target_type = self.pool.get_data1(operand)
        let unary = self.pool.add_node(NodeKind.NK_UNARY, start, self.pool.get_end(inner), op, inner, 0)
        return self.pool.add_node(NodeKind.NK_CAST, start, self.pool.get_end(operand), unary, target_type, 0)
    self.pool.add_node(NodeKind.NK_UNARY, start, self.pool.get_end(operand), op, operand, 0)

fn Parser.parse_ref_of(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    var op = UnaryOp.UOP_REF
    if self.peek() == TokenKind.TK_KW_MUT:
        op = UnaryOp.UOP_MUT_REF
        self.advance()
    let operand = self.parse_primary()
    self.build_unary_with_outer_cast(start, op, operand)

fn Parser.parse_deref_expr(self: Parser) -> i32:
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

fn Parser.parse_if_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume if
    self.skip_newlines()

    if self.peek() == TokenKind.TK_KW_LET:
        return self.parse_if_let(start)

    let cond = self.parse_expr()
    var use_block = false
    if self.peek() == TokenKind.TK_KW_THEN:
        self.advance()
        self.skip_newlines()
    else if self.peek() == TokenKind.TK_COLON:
        self.advance()
        use_block = true
    else:
        self.skip_newlines()

    let if_col = column_of(self.source, start)
    // Dangling-else resolution: for block-form if that starts a new line,
    // only accept else at the same column. This prevents a nested if from
    // stealing an outer if's else. Inline ifs and else-if chains are exempt.
    let is_stmt_if = use_block and is_first_on_line(self.source, start) != 0
    let then_body = if use_block: self.parse_block_or_expr() else: self.parse_expr()
    var else_body = 0
    let save = self.pos
    self.skip_newlines()
    let crossed_newline = self.pos != save
    if self.peek() == TokenKind.TK_KW_ELSE:
        let else_col = column_of(self.source, self.current_start())
        if crossed_newline and is_stmt_if and else_col != if_col:
            self.pos = save
        else:
            self.advance()
            if self.peek() == TokenKind.TK_COLON:
                self.advance()
            else_body = self.parse_block_or_expr()
    else:
        self.pos = save

    self.pool.add_node(NodeKind.NK_IF_EXPR, start, self.prev_end(), cond, then_body, else_body)

fn Parser.parse_if_let(self: Parser, start: i32) -> i32:
    self.advance()  // consume first 'let'
    let pat = self.parse_pattern()
    if self.expect(TokenKind.TK_EQ) == 0:
        return 0
    let subject = self.parse_expr()

    // Store clauses as flat triples: (kind, data0, data1).
    // kind=0 → let clause (data0=pattern, data1=subject)
    // kind=1 → cond clause (data0=cond_expr, data1=0)
    var clauses: Vec[i32] = Vec.new()
    clauses.push(0)
    clauses.push(pat)
    clauses.push(subject)

    // Chained form: `if let A = x, let B = y, cond, ...`
    while self.peek() == TokenKind.TK_COMMA:
        self.advance()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_KW_LET:
            self.advance()  // consume 'let'
            let p = self.parse_pattern()
            if self.expect(TokenKind.TK_EQ) == 0:
                return 0
            let s = self.parse_expr()
            clauses.push(0)
            clauses.push(p)
            clauses.push(s)
        else:
            let cond = self.parse_expr()
            clauses.push(1)
            clauses.push(cond)
            clauses.push(0)

    var use_block = false
    if self.peek() == TokenKind.TK_KW_THEN:
        self.advance()
        self.skip_newlines()
    else if self.peek() == TokenKind.TK_COLON:
        self.advance()
        use_block = true
    else:
        self.skip_newlines()

    let if_col = column_of(self.source, start)
    let is_stmt_if = use_block and is_first_on_line(self.source, start) != 0
    let then_body = if use_block: self.parse_block_or_expr() else: self.parse_expr()

    var else_body = 0
    let save = self.pos
    self.skip_newlines()
    let crossed_newline = self.pos != save
    if self.peek() == TokenKind.TK_KW_ELSE:
        let else_col = column_of(self.source, self.current_start())
        if crossed_newline and is_stmt_if and else_col != if_col:
            self.pos = save
        else:
            self.advance()
            if self.peek() == TokenKind.TK_COLON:
                self.advance()
            else_body = self.parse_block_or_expr()
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
            // Cond clause → if d0 then acc else else_body
            acc = self.pool.add_node(NodeKind.NK_IF_EXPR, start, self.prev_end(), d0, acc, else_body)
        ci = ci - 1
    acc

fn Parser.parse_return(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    var value = 0
    let t = self.peek()
    if t != TokenKind.TK_NEWLINE and t != TokenKind.TK_EOF and t != TokenKind.TK_R_PAREN and t != TokenKind.TK_R_BRACE:
        value = self.parse_expr()
    self.pool.add_node(NodeKind.NK_RETURN, start, self.prev_end(), value, 0, 0)

fn Parser.parse_defer(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let body = self.parse_expr()
    self.pool.add_node(NodeKind.NK_DEFER, start, self.prev_end(), body, 0, 0)

fn Parser.parse_errdefer(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let body = self.parse_expr()
    self.pool.add_node(NodeKind.NK_ERRDEFER, start, self.prev_end(), body, 0, 0)

fn Parser.parse_unsafe(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    self.pool.add_node(NodeKind.NK_UNSAFE_BLOCK, start, self.prev_end(), body, 0, 0)

fn Parser.parse_yield(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let value = self.parse_expr()
    self.pool.add_node(NodeKind.NK_YIELD, start, self.prev_end(), value, 0, 0)

fn Parser.parse_comptime_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let inner = self.parse_expr()
    self.pool.add_node(NodeKind.NK_COMPTIME, start, self.prev_end(), inner, 0, 0)

fn Parser.parse_spawn(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    let value = self.parse_expr()
    self.pool.add_node(NodeKind.NK_SPAWN, start, self.prev_end(), value, 0, 0)

fn Parser.parse_async_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    if self.is_ident_named("scope"):
        self.advance()
        var scope_name = self.intern.intern("s")
        if self.peek() == TokenKind.TK_PIPE:
            self.advance()
            if self.peek() == TokenKind.TK_IDENT:
                scope_name = self.expect_ident()
            self.expect(TokenKind.TK_PIPE)
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
        let body = self.parse_block_or_expr()
        return self.pool.add_node(NodeKind.NK_ASYNC_SCOPE, start, self.prev_end(), scope_name, body, 0)

    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    self.pool.add_node(NodeKind.NK_ASYNC_BLOCK, start, self.prev_end(), body, 0, 0)

fn Parser.parse_select_await(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume select
    self.expect(TokenKind.TK_KW_AWAIT)
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    self.skip_newlines()

    var arm_entries: Vec[i32] = Vec.new()
    var arm_count = 0
    var arm_col = -1

    while self.peek() != TokenKind.TK_EOF:
        if self.peek() != TokenKind.TK_IDENT:
            break
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
        let task_expr = self.parse_expr()
        self.expect(TokenKind.TK_FAT_ARROW)
        let body = self.parse_block_or_expr()
        arm_entries.push(name_sym)
        arm_entries.push(task_expr)
        arm_entries.push(body)
        arm_count = arm_count + 1

        let save = self.pos
        self.skip_newlines()
        if self.peek() == TokenKind.TK_IDENT and self.pos + 1 < self.tokens.len() and self.tokens.get_tag(self.pos + 1) == TokenKind.TK_EQ:
            let next_col = column_of(self.source, self.current_start())
            if arm_col >= 0 and next_col == arm_col:
                continue
        self.pos = save
        break

    let extra_start = self.pool.extra_len()
    for ei in 0..arm_entries.len() as i32:
        self.pool.add_extra(arm_entries.get(ei as i64))
    self.pool.add_node(NodeKind.NK_SELECT_AWAIT, start, self.prev_end(), extra_start, arm_count, 0)

// ── Loop expressions ─────────────────────────────────────────────

fn Parser.parse_while(self: Parser, label: i32) -> i32:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()

    if self.peek() == TokenKind.TK_KW_LET:
        return self.parse_while_let(start)

    let cond = self.parse_expr()
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    self.pool.add_node(NodeKind.NK_WHILE, start, self.prev_end(), cond, body, label)

fn Parser.parse_while_let(self: Parser, start: i32) -> i32:
    self.advance()  // consume let
    let pat = self.parse_pattern()
    if self.expect(TokenKind.TK_EQ) == 0:
        return 0
    let subject = self.parse_expr()
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()

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

fn Parser.parse_loop(self: Parser, label: i32) -> i32:
    let start = self.current_start()
    self.advance()
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    self.pool.add_node(NodeKind.NK_LOOP, start, self.prev_end(), body, label, 0)

fn Parser.parse_for(self: Parser, label: i32) -> i32:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    var binding = 0
    var index_binding = 0

    if self.peek() == TokenKind.TK_L_PAREN:
        // Tuple destructuring - simplified: parse as pattern
        let pat = self.parse_pattern()
        binding = pat
    else:
        binding = self.expect_ident()
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            index_binding = self.expect_ident()

    if self.expect(TokenKind.TK_KW_IN) == 0:
        return 0
    self.skip_newlines()
    let iterable = self.parse_expr()
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()

    var for_node = self.pool.add_node(NodeKind.NK_FOR, start, self.prev_end(), binding, iterable, body)
    self.pool.add_for_meta(for_node, index_binding, label)

    // Parse optional else clause: for x in iter: ... else: ...
    // Only match else at the same column as the for keyword.
    // Desugar to: { var __for_ran = false; for x in iter: { __for_ran = true; body }; if not __for_ran: else_body }
    let for_col = column_of(self.source, start)
    let save_pos = self.pos
    self.skip_newlines()
    let else_col = column_of(self.source, self.current_start())
    if self.peek() == TokenKind.TK_KW_ELSE and else_col == for_col:
        self.advance()
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
        let else_body = self.parse_block_or_expr()
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

fn Parser.parse_labeled_loop(self: Parser) -> i32:
    let start = self.current_start()
    let label_end = self.current_end()
    let label_text = self.source.slice((start + 1) as i64, label_end as i64)
    let label_sym = self.intern.intern(label_text)
    self.advance()

    if self.peek() != TokenKind.TK_COLON:
        self.emit_error("expected ':' after loop label")
        return 0
    self.advance()
    self.skip_newlines()

    let t = self.peek()
    if t == TokenKind.TK_KW_FOR: return self.parse_for(label_sym)
    if t == TokenKind.TK_KW_WHILE: return self.parse_while(label_sym)
    if t == TokenKind.TK_KW_LOOP: return self.parse_loop(label_sym)
    self.emit_error("expected 'for', 'while', or 'loop' after label")
    0

fn Parser.parse_break(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    var label = 0
    if self.peek() == TokenKind.TK_LABEL:
        let ls = self.current_start()
        let le = self.current_end()
        label = self.intern.intern(self.source.slice((ls + 1) as i64, le as i64))
        self.advance()
    var value = 0
    let t = self.peek()
    if t != TokenKind.TK_NEWLINE and t != TokenKind.TK_EOF and t != TokenKind.TK_R_BRACE and t != TokenKind.TK_R_PAREN and t != TokenKind.TK_R_BRACKET:
        value = self.parse_expr()
    self.pool.add_node(NodeKind.NK_BREAK, start, self.prev_end(), value, label, 0)

fn Parser.parse_continue(self: Parser) -> i32:
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

fn Parser.parse_match_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    let subject = self.parse_expr()
    self.skip_newlines()
    let arm_count = self.parse_match_arms()
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
        var pattern = 0
        var in_guard_expr = 0

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
            let or_start = self.pool.extra_len()
            self.pool.add_extra(pattern)
            var or_count = 1
            while self.peek() == TokenKind.TK_PIPE:
                self.advance()
                self.skip_newlines()
                let alt = self.parse_pattern()
                self.pool.add_extra(alt)
                or_count = or_count + 1
            pattern = self.pool.add_node(NodeKind.NK_PAT_OR, arm_start, self.prev_end(), or_start, or_count, 0)

        // Guard clause
        var guard = 0
        if in_guard_expr != 0:
            guard = in_guard_expr
        else if self.peek() == TokenKind.TK_KW_IF:
            self.advance()
            guard = self.parse_expr()

        if self.expect(TokenKind.TK_FAT_ARROW) == 0:
            break
        self.skip_newlines()
        let body = self.parse_block_or_expr()

        let arm = self.pool.add_node(NodeKind.NK_MATCH_ARM, arm_start, self.prev_end(), pattern, body, guard)
        arms.push(arm)

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

fn Parser.is_arm_token(self: Parser, t: i32) -> bool:
    t == TokenKind.TK_IDENT or t == TokenKind.TK_INT_LIT or t == TokenKind.TK_DOT_IDENT or t == TokenKind.TK_TRUE or t == TokenKind.TK_FALSE or t == TokenKind.TK_STRING_LIT or t == TokenKind.TK_MINUS or t == TokenKind.TK_L_BRACKET or t == TokenKind.TK_L_PAREN or t == TokenKind.TK_L_BRACE or t == TokenKind.TK_KW_IN

// ── Pattern parsing ──────────────────────────────────────────────

fn Parser.parse_pattern(self: Parser) -> i32:
    let start = self.current_start()
    let end = self.current_end()
    let t = self.peek()

    if t == TokenKind.TK_INT_LIT:
        let text = self.source.slice(start as i64, end as i64)
        self.advance()
        let val = parse_int(text)
        // Range pattern
        if self.peek() == TokenKind.TK_DOT_DOT or self.peek() == TokenKind.TK_DOT_DOT_EQ:
            let inclusive = if self.peek() == TokenKind.TK_DOT_DOT_EQ: 1 else: 0
            self.advance()
            let es = self.current_start()
            let ee = self.current_end()
            let etext = self.source.slice(es as i64, ee as i64)
            self.expect(TokenKind.TK_INT_LIT)
            let eval = parse_int(etext)
            return self.pool.add_node(NodeKind.NK_PAT_RANGE, start, self.prev_end(), val, eval, inclusive)
        return self.pool.add_node(NodeKind.NK_PAT_INT, start, end, val, 0, 0)

    if t == TokenKind.TK_TRUE:
        self.advance()
        return self.pool.add_node(NodeKind.NK_PAT_BOOL, start, end, 1, 0, 0)
    if t == TokenKind.TK_FALSE:
        self.advance()
        return self.pool.add_node(NodeKind.NK_PAT_BOOL, start, end, 0, 0, 0)
    if t == TokenKind.TK_STRING_LIT:
        let raw = self.source.slice((start + 1) as i64, (end - 1) as i64)
        let sym = self.intern.intern(raw)
        self.advance()
        return self.pool.add_node(NodeKind.NK_PAT_STRING, start, end, sym, 0, 0)
    if t == TokenKind.TK_MINUS:
        self.advance()
        let ns = self.current_start()
        let ne = self.current_end()
        let text = self.source.slice(ns as i64, ne as i64)
        self.expect(TokenKind.TK_INT_LIT)
        let val = 0 - parse_int(text)
        // Check for range pattern after negative number
        if self.peek() == TokenKind.TK_DOT_DOT or self.peek() == TokenKind.TK_DOT_DOT_EQ:
            let inclusive = if self.peek() == TokenKind.TK_DOT_DOT_EQ: 1 else: 0
            self.advance()
            // Parse range end (may also be negative)
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
        return self.pool.add_node(NodeKind.NK_PAT_INT, start, self.prev_end(), val, 0, 0)

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
                    return 0
            else:
                let dot_start = self.current_start()
                let dot_end = self.current_end()
                let dot_text = self.source.slice((dot_start + 1) as i64, dot_end as i64)
                variant_name = self.intern.intern(dot_text)
                self.advance()
            if self.peek() == TokenKind.TK_L_PAREN:
                self.advance()
                self.skip_newlines()
                let extra_start = self.pool.extra_len()
                var binding_count = 0
                while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                    let inner = self.parse_pattern()
                    self.pool.add_extra(inner)
                    binding_count = binding_count + 1
                    self.skip_newlines()
                    if self.peek() == TokenKind.TK_COMMA:
                        self.advance()
                        self.skip_newlines()
                self.skip_newlines()
                self.expect(TokenKind.TK_R_PAREN)
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
            let extra_start = self.pool.extra_len()
            var binding_count = 0
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                let inner = self.parse_pattern()
                self.pool.add_extra(inner)
                binding_count = binding_count + 1
                self.skip_newlines()
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
            self.skip_newlines()
            self.expect(TokenKind.TK_R_PAREN)
            return self.pool.add_node(NodeKind.NK_PAT_VARIANT, start, self.prev_end(), name, extra_start, binding_count)
        // Uppercase = unit variant
        if name_str.len() > 0 and name_str.byte_at((0) as i64) >= 65 and name_str.byte_at((0) as i64) <= 90:
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
        let text = self.source.slice((start + 1) as i64, end as i64)
        let name = self.intern.intern(text)
        self.advance()
        if self.peek() == TokenKind.TK_L_PAREN:
            self.advance()
            self.skip_newlines()
            let extra_start = self.pool.extra_len()
            var binding_count = 0
            while self.peek() != TokenKind.TK_R_PAREN and self.peek() != TokenKind.TK_EOF:
                let b = self.expect_ident()
                self.pool.add_extra(b)
                binding_count = binding_count + 1
                self.skip_newlines()
                if self.peek() == TokenKind.TK_COMMA:
                    self.advance()
                    self.skip_newlines()
            self.skip_newlines()
            self.expect(TokenKind.TK_R_PAREN)
            return self.pool.add_node(NodeKind.NK_PAT_ENUM_SHORTHAND, start, self.prev_end(), name, extra_start, binding_count)
        return self.pool.add_node(NodeKind.NK_PAT_ENUM_SHORTHAND, start, self.prev_end(), name, 0, 0)

    if t == TokenKind.TK_L_PAREN:
        self.advance()
        self.skip_newlines()
        let extra_start = self.pool.extra_len()
        var count = 0
        if self.peek() != TokenKind.TK_R_PAREN:
            let p = self.parse_pattern()
            self.pool.add_extra(p)
            count = count + 1
            self.skip_newlines()
            while self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
                if self.peek() == TokenKind.TK_R_PAREN:
                    break
                let p2 = self.parse_pattern()
                self.pool.add_extra(p2)
                count = count + 1
                self.skip_newlines()
        self.skip_newlines()
        self.expect(TokenKind.TK_R_PAREN)
        return self.pool.add_node(NodeKind.NK_PAT_TUPLE, start, self.prev_end(), extra_start, count, 0)

    if t == TokenKind.TK_L_BRACE:
        return self.parse_struct_pattern(0, start)

    if t == TokenKind.TK_L_BRACKET:
        return self.parse_slice_pattern(start)

    self.emit_error("expected pattern")
    0

fn Parser.parse_struct_pattern(self: Parser, type_name: i32, start: i32) -> i32:
    self.advance()  // consume {
    self.skip_newlines()
    let extra_start = self.pool.extra_len()
    let has_rest_idx = self.pool.add_extra(0)
    var field_count = 0
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
        var fpat = 0
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            fpat = self.parse_pattern()
        self.pool.add_extra(fname)
        self.pool.add_extra(fpat)
        field_count = field_count + 1
        if self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()

    self.expect(TokenKind.TK_R_BRACE)
    self.pool.extra.set_i32(has_rest_idx as i64, has_rest)
    self.pool.add_node(NodeKind.NK_PAT_STRUCT, start, self.prev_end(), type_name, extra_start, field_count)

fn Parser.parse_slice_pattern(self: Parser, start: i32) -> i32:
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
    self.pool.extra.set_i32(has_rest_idx as i64, has_rest)
    self.pool.add_extra(tail_syms.len() as i32)
    for ti in 0..tail_syms.len() as i32:
        self.pool.add_extra(tail_syms.get(ti as i64))
    self.pool.add_node(NodeKind.NK_PAT_SLICE, start, self.prev_end(), extra_start, head_count, rest_sym)

// ── Let binding expression ───────────────────────────────────────

fn Parser.parse_let_binding(self: Parser) -> i32:
    let start = self.current_start()
    let is_var = self.peek() == TokenKind.TK_KW_VAR
    self.advance()
    var is_mut = is_var
    if not is_var and self.peek() == TokenKind.TK_KW_MUT:
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
            return 0
        self.skip_newlines()
        let value = self.parse_expr()
        let extra_start = self.pool.extra_len()
        for ni in 0..names.len() as i32:
            self.pool.add_extra(names.get(ni as i64))
        return self.pool.add_node(NodeKind.NK_TUPLE_DESTRUCTURE, start, self.prev_end(), extra_start, names.len() as i32, value)

    // Let-else with variant shorthand: let .Some(v) = expr else body
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
                return 0
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
        return 0
    let name_str = self.intern.resolve(name_sym)
    let is_upper = name_str.len() > 0 and name_str.byte_at((0) as i64) >= 65 and name_str.byte_at((0) as i64) <= 90

    // Let-else variant: let Some(x) = expr else body
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
            return 0
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

    var type_ann = 0
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        type_ann = self.parse_type_expr()

    if self.expect(TokenKind.TK_EQ) == 0:
        return 0
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

fn Parser.parse_const_binding(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume 'const'
    let name_sym = self.expect_ident()
    if name_sym == 0:
        return 0

    if self.peek() != TokenKind.TK_COLON:
        self.emit_error("const declaration requires a type annotation")
        return 0
    self.advance()
    let type_ann = self.parse_type_expr()

    if self.expect(TokenKind.TK_EQ) == 0:
        return 0
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

fn Parser.parse_with_expr(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()
    self.skip_newlines()
    self.suppress_as = 1
    let source = self.parse_expr()
    self.suppress_as = 0
    if self.peek() != TokenKind.TK_KW_AS:
        self.emit_error("expected 'as' in with expression")
        return 0
    self.advance()
    var is_mut = 0
    if self.peek() == TokenKind.TK_KW_MUT:
        is_mut = 1
        self.advance()
    let name = self.expect_ident()
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
    let body = self.parse_block_or_expr()
    let encoded_name = encode_with_binding(name, is_mut)
    self.pool.add_node(NodeKind.NK_WITH_EXPR, start, self.prev_end(), source, body, encoded_name)

// ── Record update ────────────────────────────────────────────────

fn Parser.parse_record_update(self: Parser) -> i32:
    let start = self.current_start()
    self.advance()  // consume {
    self.skip_newlines()
    let source = self.parse_expr()
    if self.peek() != TokenKind.TK_KW_WITH:
        self.emit_error("expected 'with' in record update")
        return 0
    self.advance()
    self.skip_newlines()

    var fields: Vec[i32] = Vec.new()
    var field_count = 0
    while self.peek() != TokenKind.TK_R_BRACE and self.peek() != TokenKind.TK_EOF:
        let fname = self.expect_ident()
        var val = 0
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            val = self.parse_expr()
        else:
            val = self.pool.add_node(NodeKind.NK_IDENT, start, self.prev_end(), fname, 0, 0)
        fields.push(fname)
        fields.push(val)
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

fn Parser.parse_array_literal(self: Parser) -> i32:
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
                fill_count = self.pool.int_lit_value(count_expr) as i32
            if fill_count <= 0:
                fill_count = 1
            let extra_start = self.pool.extra_len()
            for fi in 0..fill_count:
                self.pool.add_extra(first)
            return self.pool.add_node(NodeKind.NK_ARRAY_LIT, start, self.prev_end(), extra_start, fill_count, 0)

        // Comprehension: [expr for x in iter]
        if self.peek() == TokenKind.TK_KW_FOR:
            self.advance()
            let binding = self.expect_ident()
            self.expect(TokenKind.TK_KW_IN)
            let iterable = self.parse_expr()
            var filter = 0
            if self.peek() == TokenKind.TK_KW_IF:
                self.advance()
                filter = self.parse_expr()
            self.expect(TokenKind.TK_R_BRACKET)
            return self.pool.add_node(NodeKind.NK_ARRAY_COMPREHENSION, start, self.prev_end(), first, binding, iterable)

        elems.push(first)

        while self.peek() == TokenKind.TK_COMMA:
            self.advance()
            self.skip_newlines()
            if self.peek() == TokenKind.TK_R_BRACKET:
                break
            elems.push(self.parse_expr())

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
fn Parser.parse_fat_arrow_single(self: Parser) -> i32:
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
fn Parser.parse_fat_arrow_paren_closure(self: Parser) -> i32:
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
        self.pool.add_extra(p)
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            let ty = self.parse_type_expr()
            self.pool.add_extra(ty)
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

fn Parser.parse_closure(self: Parser) -> i32:
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
        self.pool.add_extra(p)
        // Optional type
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            let ty = self.parse_type_expr()
            self.pool.add_extra(ty)
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

    let body = if self.peek() == TokenKind.TK_COLON:
        self.advance()
        self.parse_block_or_expr()
    else:
        self.parse_expr()
    self.pool.add_node(NodeKind.NK_CLOSURE, start, self.prev_end(), body, extra_start, param_count)

fn Parser.parse_move_closure(self: Parser) -> i32:
    let node = self.parse_closure()
    if node != 0:
        self.pool.mark_move_closure(node)
    node

// ── Block / indentation parsing ──────────────────────────────────

fn Parser.parse_block_or_expr(self: Parser) -> i32:
    if self.peek() != TokenKind.TK_NEWLINE:
        return self.parse_expr()

    self.skip_newlines()
    if self.peek() == TokenKind.TK_EOF:
        self.emit_error("expected expression")
        return 0

    let block_col = column_of(self.source, self.current_start())
    var stmts: Vec[i32] = Vec.new()
    var last_expr = self.parse_expr()

    while true:
        if self.peek() != TokenKind.TK_NEWLINE and self.peek() != TokenKind.TK_EOF:
            break
        if self.peek() == TokenKind.TK_EOF:
            break

        let save = self.pos
        self.skip_newlines()
        if self.peek() == TokenKind.TK_EOF:
            break
        let next_col = column_of(self.source, self.current_start())
        if next_col < block_col:
            self.pos = save
            break

        stmts.push(last_expr)
        last_expr = self.parse_expr()

    if stmts.len() == 0:
        return last_expr

    let extra_start = self.pool.extra_len()
    for i in 0..stmts.len() as i32:
        self.pool.add_extra(stmts.get(i as i64))

    let stmt_count = stmts.len() as i32
    let blk_node = self.pool.add_node(NodeKind.NK_BLOCK, self.pool.get_start(stmts.get(0)), self.pool.get_end(last_expr), extra_start, stmt_count, last_expr)
    blk_node

// ── Type expression parsing ──────────────────────────────────────

fn Parser.parse_type_expr(self: Parser) -> i32:
    let t = self.peek()
    let start = self.current_start()

    // @TypeOf(expr) — compile-time type of expression
    if t == TokenKind.TK_AT:
        self.advance()
        if self.is_ident_named("TypeOf"):
            self.advance()
            if self.expect(TokenKind.TK_L_PAREN) == 0:
                return 0
            self.skip_newlines()
            let inner = self.parse_expr()
            self.skip_newlines()
            if self.expect(TokenKind.TK_R_PAREN) == 0:
                return 0
            return self.pool.add_node(NodeKind.NK_TYPE_TYPEOF, start, self.prev_end(), inner, 0, 0)
        self.emit_error("expected 'TypeOf' after '@' in type position")
        return 0

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
            elems.push(ty)
            self.skip_newlines()
            while self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
                if self.peek() == TokenKind.TK_R_PAREN:
                    break
                let ty2 = self.parse_type_expr()
                elems.push(ty2)
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
            params.push(ty)
            self.skip_newlines()
            while self.peek() == TokenKind.TK_COMMA:
                self.advance()
                self.skip_newlines()
                if self.peek() == TokenKind.TK_R_PAREN:
                    break
                let ty2 = self.parse_type_expr()
                params.push(ty2)
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
                return 0
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
            return 0
        let sym = self.intern_current()
        self.advance()
        return self.pool.add_node(NodeKind.NK_TYPE_TRAIT_OBJ, start, self.prev_end(), sym, 0, 0)

    if t == TokenKind.TK_KW_IMPL:
        self.advance()
        if self.peek() != TokenKind.TK_IDENT:
            self.emit_error("expected trait name after 'impl'")
            return 0
        let sym = self.intern_current()
        self.advance()
        if self.peek() == TokenKind.TK_KW_FOR:
            self.advance()
        let target = self.parse_type_expr()
        if target == 0:
            return 0
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
                    args.push(ty)
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
    0

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
        var param_pattern = 0
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

        var type_node = 0
        if self.peek() == TokenKind.TK_COLON:
            self.advance()
            self.skip_newlines()
            type_node = self.parse_type_expr()

        // Default value
        var has_default = 0
        if self.peek() == TokenKind.TK_EQ:
            self.advance()
            self.skip_newlines()
            self.parse_expr()
            has_default = 1
        if has_default == 0:
            required_count = required_count + 1

        params.push(name)
        params.push(type_node)
        params.push(param_flags)
        self.pool.add_fn_param_pattern_value(param_pattern)
        pattern_count = pattern_count + 1

        if self.peek() != TokenKind.TK_COMMA:
            break
        self.advance()
        self.skip_newlines()
        if self.peek() == TokenKind.TK_R_PAREN or self.peek() == TokenKind.TK_DOT_DOT_DOT:
            break

    let count = (params.len() / (FN_PARAM_STRIDE as i64)) as i32
    for pi in 0..params.len() as i32:
        self.pool.add_extra(params.get(pi as i64))
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
    var type_node = 0
    if self.peek() == TokenKind.TK_COLON:
        self.advance()
        type_node = self.parse_type_expr()
    // Default value
    if self.peek() == TokenKind.TK_EQ:
        self.advance()
        self.parse_expr()
    self.pool.add_extra(name)
    self.pool.add_extra(type_node)
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
    self.pool.extra.set_i32(count_idx as i64, bound_count)
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
