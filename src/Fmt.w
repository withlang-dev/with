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

// ── Core formatter ──────────────────────────────────────────────

fn format_source(source: str) -> str:
    var lexer = Lexer.init(source, 0)
    let tokens = lexer.tokenize_with_comments()
    let count = tokens.len()
    var out = ""
    var at_line_start = true
    var blank_lines = 0
    var prev_tag = 0
    var prev_was_newline = false
    var line_indent = 0

    var i = 0
    while i < count:
        let tag = tokens.get_tag(i)
        let start = tokens.get_start(i)
        let end = tokens.get_end(i)

        if tag == TokenKind.TK_EOF:
            break

        if tag == TokenKind.TK_NEWLINE:
            if not at_line_start:
                out = out ++ "\n"
                at_line_start = true
                prev_was_newline = true
            else:
                blank_lines = blank_lines + 1
            i = i + 1
            continue

        // Non-whitespace token on a new line
        if at_line_start:
            // Determine indentation from source column
            line_indent = column_of(source, start)
            // Allow at most 1 blank line between sections
            if blank_lines > 0 and prev_tag != 0:
                out = out ++ "\n"
            blank_lines = 0
            // Emit indentation
            for sp in 0..line_indent:
                out = out ++ " "
            at_line_start = false
            prev_was_newline = false
        else:
            // Within a line — decide spacing before this token
            let space = needs_space_before(tag, prev_tag)
            if space:
                out = out ++ " "

        // Emit token text from source
        let text = with_str_slice(source, start as i64, end as i64)
        out = out ++ text
        prev_tag = tag
        i = i + 1

    // Ensure file ends with exactly one newline
    if out.len() > 0:
        // Strip trailing newlines
        while out.len() > 0 and with_str_byte_at(out, with_str_len(out) - 1) == 10:
            out = with_str_slice(out, 0, with_str_len(out) - 1)
        out = out ++ "\n"
    out

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
