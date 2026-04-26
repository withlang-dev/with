// Fmt — source code formatter for the With language.
//
// Token-level formatter: preserves comments and normalizes whitespace,
// indentation, blank lines, and operator spacing. Does NOT modify the AST.

use Lexer
use Token

extern fn with_str_len(s: str) -> i64
extern fn with_str_byte_at(s: str, index: i64) -> i32
extern fn with_str_slice(s: str, start: i64, end: i64) -> str

// ── Spacing classification ──────────────────────────────────────

fn is_binary_op(tag: i32) -> bool:
    if tag == TokenKind.TK_PLUS: return true
    if tag == TokenKind.TK_MINUS: return true
    if tag == TokenKind.TK_STAR: return true
    if tag == TokenKind.TK_SLASH: return true
    if tag == TokenKind.TK_PERCENT: return true
    if tag == TokenKind.TK_PLUS_WRAP: return true
    if tag == TokenKind.TK_MINUS_WRAP: return true
    if tag == TokenKind.TK_STAR_WRAP: return true
    if tag == TokenKind.TK_EQ_EQ: return true
    if tag == TokenKind.TK_BANG_EQ: return true
    if tag == TokenKind.TK_LT: return true
    if tag == TokenKind.TK_GT: return true
    if tag == TokenKind.TK_LT_EQ: return true
    if tag == TokenKind.TK_GT_EQ: return true
    if tag == TokenKind.TK_AMPERSAND: return true
    if tag == TokenKind.TK_PIPE: return true
    if tag == TokenKind.TK_CARET: return true
    if tag == TokenKind.TK_KW_AND: return true
    if tag == TokenKind.TK_KW_OR: return true
    if tag == TokenKind.TK_GT_GT: return true
    if tag == TokenKind.TK_LT_LT: return true
    if tag == TokenKind.TK_PLUS_PLUS: return true
    if tag == TokenKind.TK_PIPE_GT: return true
    if tag == TokenKind.TK_LT_PIPE: return true
    if tag == TokenKind.TK_DOT_DOT: return true
    if tag == TokenKind.TK_DOT_DOT_EQ: return true
    if tag == TokenKind.TK_QUESTION_QUESTION: return true
    false

fn is_assign_op(tag: i32) -> bool:
    if tag == TokenKind.TK_EQ: return true
    if tag == TokenKind.TK_PLUS_EQ: return true
    if tag == TokenKind.TK_MINUS_EQ: return true
    if tag == TokenKind.TK_STAR_EQ: return true
    if tag == TokenKind.TK_SLASH_EQ: return true
    if tag == TokenKind.TK_PERCENT_EQ: return true
    if tag == TokenKind.TK_AMP_EQ: return true
    if tag == TokenKind.TK_PIPE_EQ: return true
    if tag == TokenKind.TK_CARET_EQ: return true
    if tag == TokenKind.TK_LT_LT_EQ: return true
    if tag == TokenKind.TK_GT_GT_EQ: return true
    if tag == TokenKind.TK_PLUS_WRAP_EQ: return true
    if tag == TokenKind.TK_MINUS_WRAP_EQ: return true
    false

fn is_open_delim(tag: i32) -> bool:
    tag == TokenKind.TK_L_PAREN or tag == TokenKind.TK_L_BRACKET or tag == TokenKind.TK_L_BRACE

fn is_close_delim(tag: i32) -> bool:
    tag == TokenKind.TK_R_PAREN or tag == TokenKind.TK_R_BRACKET or tag == TokenKind.TK_R_BRACE

// Whether this token is a unary-only prefix (not also binary).
fn is_unary_prefix(tag: i32, prev: i32) -> bool:
    if tag == TokenKind.TK_KW_NOT: return true
    if tag == TokenKind.TK_TILDE: return true
    // &, *, - are unary when preceded by operator, open delim, keyword, or start-of-line
    if tag == TokenKind.TK_AMPERSAND or tag == TokenKind.TK_STAR or tag == TokenKind.TK_MINUS:
        if prev == 0: return true
        if is_binary_op(prev) or is_assign_op(prev): return true
        if is_open_delim(prev): return true
        if prev == TokenKind.TK_COMMA or prev == TokenKind.TK_COLON: return true
        if prev == TokenKind.TK_KW_RETURN or prev == TokenKind.TK_KW_IN: return true
        if prev == TokenKind.TK_FAT_ARROW: return true
        return true
    false

// ── Block keyword detection ─────────────────────────────────────

fn is_block_keyword(tag: i32) -> bool:
    if tag == TokenKind.TK_KW_FN: return true
    if tag == TokenKind.TK_KW_IF: return true
    if tag == TokenKind.TK_KW_ELSE: return true
    if tag == TokenKind.TK_KW_WHILE: return true
    if tag == TokenKind.TK_KW_FOR: return true
    if tag == TokenKind.TK_KW_LOOP: return true
    if tag == TokenKind.TK_KW_UNSAFE: return true
    false

fn next_is_newline_or_eof(tokens: TokenList, pos: i32, count: i32) -> bool:
    var j = pos + 1
    while j < count:
        let t = tokens.get_tag(j)
        if t == TokenKind.TK_COMMENT:
            j = j + 1
            continue
        return t == TokenKind.TK_NEWLINE or t == TokenKind.TK_SEMICOLON or t == TokenKind.TK_EOF
    true

fn emit_indent(indent: i32) -> str:
    var s = ""
    for sp in 0..indent:
        s = s ++ " "
    s

// ── Core formatter ──────────────────────────────────────────────

// style: 0=preserve, 1=prefer-colon, 2=prefer-brace
fn format_source_styled(source: str, style: i32) -> str:
    var lexer = Lexer.init(source, 0)
    let tokens = lexer.tokenize_with_comments()
    let count = tokens.len()
    var out = ""
    var at_line_start = true
    var blank_lines = 0
    var prev_tag = 0
    var prev_was_newline = false
    var line_indent = 0
    var block_kw_active = false
    var close_stack: Vec[i32] = Vec.new()
    var suppress_stack: Vec[i32] = Vec.new()
    var brace_depth = 0
    var semi_indent = -1

    var i = 0
    while i < count:
        let tag = tokens.get_tag(i)
        let start = tokens.get_start(i)
        let end = tokens.get_end(i)

        if tag == TokenKind.TK_EOF:
            break

        if tag == TokenKind.TK_NEWLINE or tag == TokenKind.TK_SEMICOLON:
            if not at_line_start:
                if tag == TokenKind.TK_SEMICOLON and semi_indent < 0:
                    semi_indent = line_indent
                out = out ++ "\n"
                at_line_start = true
                prev_was_newline = true
            else:
                if tag == TokenKind.TK_NEWLINE:
                    blank_lines = blank_lines + 1
                    semi_indent = -1
            i = i + 1
            continue

        if is_block_keyword(tag):
            block_kw_active = true

        if at_line_start:
            if semi_indent >= 0:
                line_indent = semi_indent
                semi_indent = -1
            else:
                line_indent = column_of(source, start)

            // prefer-brace: close blocks when indent drops
            if style == 2:
                while close_stack.len() > 0:
                    let top = close_stack.get(close_stack.len() - 1)
                    if line_indent > top:
                        break
                    let _ = close_stack.pop()
                    if tag == TokenKind.TK_KW_ELSE and top == line_indent:
                        if blank_lines > 0 and prev_tag != 0:
                            out = out ++ "\n"
                        blank_lines = 0
                        out = out ++ emit_indent(top) ++ "} "
                        at_line_start = false
                        prev_was_newline = false
                        prev_tag = TokenKind.TK_R_BRACE
                        break
                    else:
                        out = out ++ emit_indent(top) ++ "}\n"
                        prev_tag = TokenKind.TK_R_BRACE

            // prefer-colon: suppress } at line start
            if style == 1 and at_line_start and tag == TokenKind.TK_R_BRACE:
                let after_brace = brace_depth - 1
                if suppress_stack.len() > 0 and suppress_stack.get(suppress_stack.len() - 1) == after_brace:
                    let _ = suppress_stack.pop()
                    brace_depth = after_brace
                    var j = i + 1
                    while j < count and (tokens.get_tag(j) == TokenKind.TK_NEWLINE or tokens.get_tag(j) == TokenKind.TK_SEMICOLON):
                        j = j + 1
                    if j < count and tokens.get_tag(j) == TokenKind.TK_KW_ELSE:
                        if blank_lines > 0 and prev_tag != 0:
                            out = out ++ "\n"
                        blank_lines = 0
                        out = out ++ emit_indent(line_indent)
                        out = out ++ "else"
                        block_kw_active = true
                        prev_tag = TokenKind.TK_KW_ELSE
                        at_line_start = false
                        prev_was_newline = false
                        i = j + 1
                        continue
                    blank_lines = 0
                    i = i + 1
                    if i < count and (tokens.get_tag(i) == TokenKind.TK_NEWLINE or tokens.get_tag(i) == TokenKind.TK_SEMICOLON):
                        i = i + 1
                    continue

            if at_line_start:
                if blank_lines > 0 and prev_tag != 0:
                    out = out ++ "\n"
                blank_lines = 0
                for sp in 0..line_indent:
                    out = out ++ " "
                at_line_start = false
                prev_was_newline = false
        else:
            // Determine effective tag for spacing (colon conversion)
            var space_tag = tag
            if style == 1 and tag == TokenKind.TK_L_BRACE and block_kw_active:
                if next_is_newline_or_eof(tokens, i, count):
                    space_tag = TokenKind.TK_COLON
            let space = needs_space_before(space_tag, prev_tag)
            if space:
                out = out ++ " "

        // prefer-brace: convert block-introducing : to {
        if style == 2 and tag == TokenKind.TK_COLON and block_kw_active:
            if next_is_newline_or_eof(tokens, i, count):
                out = out ++ " {"
                close_stack.push(line_indent)
                block_kw_active = false
                prev_tag = TokenKind.TK_L_BRACE
                i = i + 1
                continue

        // prefer-colon: convert block-introducing { to :
        if style == 1 and tag == TokenKind.TK_L_BRACE and block_kw_active:
            if next_is_newline_or_eof(tokens, i, count):
                out = out ++ ":"
                suppress_stack.push(brace_depth)
                brace_depth = brace_depth + 1
                block_kw_active = false
                prev_tag = TokenKind.TK_COLON
                i = i + 1
                continue

        if tag == TokenKind.TK_L_BRACE:
            brace_depth = brace_depth + 1
        if tag == TokenKind.TK_R_BRACE:
            brace_depth = brace_depth - 1

        if tag == TokenKind.TK_L_BRACE:
            block_kw_active = false

        let text = with_str_slice(source, start as i64, end as i64)
        out = out ++ text
        prev_tag = tag
        i = i + 1

    // prefer-brace: close any remaining open blocks
    if style == 2:
        while close_stack.len() > 0:
            let top = close_stack.pop()
            out = out ++ emit_indent(top) ++ "}\n"

    // Ensure file ends with exactly one newline
    if out.len() > 0:
        while out.len() > 0 and with_str_byte_at(out, with_str_len(out) - 1) == 10:
            out = with_str_slice(out, 0, with_str_len(out) - 1)
        out = out ++ "\n"
    out

fn format_source(source: str) -> str:
    format_source_styled(source, 0)

// Decide whether to emit a space before `cur` given `prev`.
fn needs_space_before(cur: i32, prev: i32) -> bool:
    // No space after open delim
    if is_open_delim(prev): return false
    // No space before close delim
    if is_close_delim(cur): return false
    // No space around dot
    if cur == TokenKind.TK_DOT or prev == TokenKind.TK_DOT: return false
    if cur == TokenKind.TK_QUESTION_DOT or prev == TokenKind.TK_QUESTION_DOT: return false
    if cur == TokenKind.TK_DOT_IDENT: return false
    // No space before comma
    if cur == TokenKind.TK_COMMA: return false
    // Space after comma
    if prev == TokenKind.TK_COMMA: return true
    // No space before colon, space after colon
    if cur == TokenKind.TK_COLON: return false
    if prev == TokenKind.TK_COLON: return true
    // Space around arrow, fat arrow, assignment
    if cur == TokenKind.TK_ARROW or prev == TokenKind.TK_ARROW: return true
    if cur == TokenKind.TK_FAT_ARROW or prev == TokenKind.TK_FAT_ARROW: return true
    if is_assign_op(cur) or is_assign_op(prev): return true
    // Space around binary ops
    if is_binary_op(cur) or is_binary_op(prev): return true
    // Space after keywords
    if prev == TokenKind.TK_KW_FN or prev == TokenKind.TK_KW_LET: return true
    if prev == TokenKind.TK_KW_VAR or prev == TokenKind.TK_KW_IF: return true
    if prev == TokenKind.TK_KW_ELSE or prev == TokenKind.TK_KW_THEN: return true
    if prev == TokenKind.TK_KW_MATCH or prev == TokenKind.TK_KW_FOR: return true
    if prev == TokenKind.TK_KW_IN or prev == TokenKind.TK_KW_WHILE: return true
    if prev == TokenKind.TK_KW_RETURN or prev == TokenKind.TK_KW_TYPE: return true
    if prev == TokenKind.TK_KW_TRAIT or prev == TokenKind.TK_KW_IMPL: return true
    if prev == TokenKind.TK_KW_EXTEND or prev == TokenKind.TK_KW_USE: return true
    if prev == TokenKind.TK_KW_PUB or prev == TokenKind.TK_KW_EXTERN: return true
    if prev == TokenKind.TK_KW_ASYNC or prev == TokenKind.TK_KW_AWAIT: return true
    if prev == TokenKind.TK_KW_SPAWN or prev == TokenKind.TK_KW_UNSAFE: return true
    if prev == TokenKind.TK_KW_COMPTIME or prev == TokenKind.TK_KW_DEFER: return true
    if prev == TokenKind.TK_KW_AS or prev == TokenKind.TK_KW_CONST: return true
    if prev == TokenKind.TK_KW_BREAK or prev == TokenKind.TK_KW_CONTINUE: return true
    if prev == TokenKind.TK_KW_GOTO: return true
    if prev == TokenKind.TK_KW_MUT or prev == TokenKind.TK_KW_DYN: return true
    if prev == TokenKind.TK_KW_GEN or prev == TokenKind.TK_KW_YIELD: return true
    if prev == TokenKind.TK_KW_ERRDEFER or prev == TokenKind.TK_KW_MOVE: return true
    if prev == TokenKind.TK_KW_WHERE or prev == TokenKind.TK_KW_OPAQUE: return true
    if prev == TokenKind.TK_KW_UNION or prev == TokenKind.TK_KW_SELECT: return true
    if prev == TokenKind.TK_KW_LOOP: return true
    // Space before keyword (if preceded by non-keyword identifier or literal)
    if cur == TokenKind.TK_KW_AS or cur == TokenKind.TK_KW_IN: return true
    if cur == TokenKind.TK_KW_ELSE or cur == TokenKind.TK_KW_THEN: return true
    // No space before [ after ident (indexing: x[0])
    if cur == TokenKind.TK_L_BRACKET and prev == TokenKind.TK_IDENT: return false
    if cur == TokenKind.TK_L_BRACKET and prev == TokenKind.TK_R_BRACKET: return false
    if cur == TokenKind.TK_L_BRACKET and prev == TokenKind.TK_R_PAREN: return false
    // No space before ( after ident (call: f(x))
    if cur == TokenKind.TK_L_PAREN and prev == TokenKind.TK_IDENT: return false
    if cur == TokenKind.TK_L_PAREN and prev == TokenKind.TK_R_PAREN: return false
    if cur == TokenKind.TK_L_PAREN and prev == TokenKind.TK_R_BRACKET: return false
    // No space before ? (postfix)
    if cur == TokenKind.TK_QUESTION: return false
    // No space before ! (postfix)
    if cur == TokenKind.TK_BANG and (prev == TokenKind.TK_IDENT or prev == TokenKind.TK_R_PAREN): return false
    // No space between @ and [
    if cur == TokenKind.TK_L_BRACKET and prev == TokenKind.TK_AT: return false
    // Default: space between tokens
    true
