// Lexer — Tokenizer: source bytes to token stream.
//
// The lexer scans source text character-by-character and produces
// a flat list of tokens with source spans. Whitespace (except
// significant newlines) is consumed silently. Comments are skipped.

use Token
use Span

type Lexer = {
    source: str,
    pos: i32,
    file_id: i32,
    token_start: i32,
}

fn Lexer.init(source: str, file_id: i32) -> Lexer:
    Lexer { source, pos: 0, file_id, token_start: 0 }

// Tokenize the entire source, returning a token list ending with EOF.
fn Lexer.tokenize(self: Lexer) -> TokenList:
    var tokens = TokenList.new()
    loop:
        let tag = self.next_token()
        tokens.append(tag, self.token_start, self.pos)
        if tag == TK_EOF():
            break
    tokens

// Produce the next token. Sets token_start/pos and returns the tag.
fn Lexer.next_token(self: Lexer) -> i32:
    self.skip_whitespace()

    let src = self.source
    let slen = src.len() as i32

    self.token_start = self.pos

    if self.pos >= slen:
        return TK_EOF()

    let ch = src[self.pos]

    // Newline
    if ch == 10:
        self.pos = self.pos + 1
        return TK_NEWLINE()

    // Single-character delimiters and punctuation
    if ch == 40:  // (
        self.pos = self.pos + 1
        return TK_L_PAREN()
    if ch == 41:  // )
        self.pos = self.pos + 1
        return TK_R_PAREN()
    if ch == 91:  // [
        self.pos = self.pos + 1
        return TK_L_BRACKET()
    if ch == 93:  // ]
        self.pos = self.pos + 1
        return TK_R_BRACKET()
    if ch == 123:  // {
        self.pos = self.pos + 1
        return TK_L_BRACE()
    if ch == 125:  // }
        self.pos = self.pos + 1
        return TK_R_BRACE()
    if ch == 44:  // ,
        self.pos = self.pos + 1
        return TK_COMMA()
    if ch == 59:  // ;
        self.pos = self.pos + 1
        return TK_SEMICOLON()
    if ch == 58:  // :
        self.pos = self.pos + 1
        return TK_COLON()
    if ch == 126:  // ~
        self.pos = self.pos + 1
        return TK_TILDE()
    if ch == 64:  // @
        self.pos = self.pos + 1
        return TK_AT()
    if ch == 94:  // ^
        self.pos = self.pos + 1
        return TK_CARET()
    if ch == 38:  // &
        self.pos = self.pos + 1
        return TK_AMPERSAND()

    // + compound operators
    if ch == 43:  // +
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 43:  // ++
                self.pos = self.pos + 1
                return TK_PLUS_PLUS()
            if c2 == 37:  // +%
                self.pos = self.pos + 1
                return TK_PLUS_WRAP()
            if c2 == 61:  // +=
                self.pos = self.pos + 1
                return TK_PLUS_EQ()
        return TK_PLUS()

    // - compound operators
    if ch == 45:  // -
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 62:  // ->
                self.pos = self.pos + 1
                return TK_ARROW()
            if c2 == 37:  // -%
                self.pos = self.pos + 1
                return TK_MINUS_WRAP()
            if c2 == 61:  // -=
                self.pos = self.pos + 1
                return TK_MINUS_EQ()
        return TK_MINUS()

    // * compound operators
    if ch == 42:  // *
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 37:  // *%
                self.pos = self.pos + 1
                return TK_STAR_WRAP()
            if c2 == 61:  // *=
                self.pos = self.pos + 1
                return TK_STAR_EQ()
        return TK_STAR()

    // % compound
    if ch == 37:  // %
        self.pos = self.pos + 1
        if self.pos < slen:
            if src[self.pos] == 61:  // %=
                self.pos = self.pos + 1
                return TK_PERCENT_EQ()
        return TK_PERCENT()

    // = compound
    if ch == 61:  // =
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 61:  // ==
                self.pos = self.pos + 1
                return TK_EQ_EQ()
            if c2 == 62:  // =>
                self.pos = self.pos + 1
                return TK_FAT_ARROW()
        return TK_EQ()

    // ! compound
    if ch == 33:  // !
        self.pos = self.pos + 1
        if self.pos < slen and src[self.pos] == 61:  // !=
            self.pos = self.pos + 1
            return TK_BANG_EQ()
        return TK_BANG()

    // ? compound
    if ch == 63:  // ?
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 46:  // ?.
                self.pos = self.pos + 1
                return TK_QUESTION_DOT()
            if c2 == 63:  // ??
                self.pos = self.pos + 1
                return TK_QUESTION_QUESTION()
        return TK_QUESTION()

    // < compound
    if ch == 60:  // <
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 61:  // <=
                self.pos = self.pos + 1
                return TK_LT_EQ()
            if c2 == 60:  // <<
                self.pos = self.pos + 1
                return TK_LT_LT()
            if c2 == 124:  // <|
                self.pos = self.pos + 1
                return TK_LT_PIPE()
        return TK_LT()

    // > compound
    if ch == 62:  // >
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 61:  // >=
                self.pos = self.pos + 1
                return TK_GT_EQ()
            if c2 == 62:  // >>
                self.pos = self.pos + 1
                return TK_GT_GT()
        return TK_GT()

    // | compound
    if ch == 124:  // |
        self.pos = self.pos + 1
        if self.pos < slen and src[self.pos] == 62:  // |>
            self.pos = self.pos + 1
            return TK_PIPE_GT()
        return TK_PIPE()

    // / and //
    if ch == 47:  // /
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 47:  // // comment
                // Skip the rest of the line (comment is dropped)
                while self.pos < slen and src[self.pos] != 10:
                    self.pos = self.pos + 1
                // Recurse to get the next real token
                return self.next_token()
            if c2 == 61:  // /=
                self.pos = self.pos + 1
                return TK_SLASH_EQ()
        return TK_SLASH()

    // . compound
    if ch == 46:  // .
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src[self.pos]
            if c2 == 46:  // ..
                self.pos = self.pos + 1
                if self.pos < slen and src[self.pos] == 61:  // ..=
                    self.pos = self.pos + 1
                    return TK_DOT_DOT_EQ()
                if self.pos < slen and src[self.pos] == 46:  // ...
                    self.pos = self.pos + 1
                    return TK_DOT_DOT_DOT()
                return TK_DOT_DOT()
            // .Uppercase = dot identifier
            if c2 >= 65 and c2 <= 90:
                return self.lex_dot_ident()
        return TK_DOT()

    // String literal
    if ch == 34:  // "
        return self.lex_string()

    // Number literal
    if ch >= 48 and ch <= 57:  // 0-9
        return self.lex_number()

    // Identifier or keyword
    if is_ident_start(ch):
        return self.lex_ident()

    // Character literal or label: 'x' / 'name
    if ch == 39:  // '
        self.pos = self.pos + 1
        // Try char literal first: 'x' or '\x'
        if self.pos < slen and src[self.pos] == 92:  // backslash
            // Escape sequence: '\n', '\\', '\'' etc.
            if self.pos + 2 < slen and src[self.pos + 2] == 39:
                self.pos = self.pos + 3
                return TK_CHAR_LIT()
        if self.pos + 1 < slen and src[self.pos + 1] == 39:
            // Single char: 'a' or escaped quote handled above.
            self.pos = self.pos + 2
            return TK_CHAR_LIT()
        // Label: 'name
        if self.pos < slen and is_ident_start(src[self.pos]):
            while self.pos < slen and is_ident_continue(src[self.pos]):
                self.pos = self.pos + 1
            return TK_LABEL()
        return TK_INVALID()

    // Unknown character
    self.pos = self.pos + 1
    TK_INVALID()


// --- Internal helpers ---

fn Lexer.skip_whitespace(self: Lexer):
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen:
        let ch = src[self.pos]
        if not (ch == 32 or ch == 9 or ch == 13):
            break
        self.pos = self.pos + 1

fn Lexer.lex_string(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    self.pos = self.pos + 1  // skip opening "

    // Check for triple-quoted multi-line string: """..."""
    if self.pos + 1 < slen and src[self.pos] == 34 and src[self.pos + 1] == 34:
        self.pos = self.pos + 2  // skip the two additional quotes
        // Skip optional leading newline after opening """
        if self.pos < slen and src[self.pos] == 10:
            self.pos = self.pos + 1
        while self.pos + 2 < slen:
            if src[self.pos] == 34 and src[self.pos + 1] == 34 and src[self.pos + 2] == 34:
                self.pos = self.pos + 3
                return TK_STRING_LIT()
            if src[self.pos] == 92:  // backslash
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        // Unterminated multi-line string
        return TK_STRING_LIT()

    // Track brace depth so that `"` inside interpolation holes `{...}` is not
    // treated as the end of the string.
    var brace_depth = 0
    while self.pos < slen:
        let ch = src[self.pos]
        if ch == 123 and brace_depth == 0:  // {
            // Don't count escaped braces.
            if self.pos > 0 and src[self.pos - 1] != 92:
                brace_depth = brace_depth + 1
                self.pos = self.pos + 1
                continue
        if ch == 123 and brace_depth > 0:  // {
            brace_depth = brace_depth + 1
            self.pos = self.pos + 1
            continue
        if ch == 125 and brace_depth > 0:  // }
            brace_depth = brace_depth - 1
            self.pos = self.pos + 1
            continue
        if ch == 34 and brace_depth == 0:  // closing "
            self.pos = self.pos + 1
            return TK_STRING_LIT()
        if ch == 34 and brace_depth > 0:
            // Inside an interpolation hole: skip nested string literal.
            self.pos = self.pos + 1
            while self.pos < slen and src[self.pos] != 34:
                if src[self.pos] == 92:
                    self.pos = self.pos + 1
                self.pos = self.pos + 1
            if self.pos < slen:
                self.pos = self.pos + 1
            continue
        if ch == 92:  // backslash escape
            self.pos = self.pos + 1
        self.pos = self.pos + 1
    // Unterminated
    TK_STRING_LIT()

fn Lexer.lex_number(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    let start = self.token_start
    var is_float = false

    // Check for 0x, 0b, 0o prefixes
    if src[self.pos] == 48 and self.pos + 1 < slen:
        let prefix = src[self.pos + 1]
        if prefix == 120 or prefix == 88:  // x, X
            self.pos = self.pos + 2
            while self.pos < slen and is_hex_digit(src[self.pos]):
                self.pos = self.pos + 1
            return TK_INT_LIT()
        if prefix == 98 or prefix == 66:  // b, B
            self.pos = self.pos + 2
            while self.pos < slen and (src[self.pos] == 48 or src[self.pos] == 49 or src[self.pos] == 95):
                self.pos = self.pos + 1
            return TK_INT_LIT()
        if prefix == 111 or prefix == 79:  // o, O
            self.pos = self.pos + 2
            while self.pos < slen and ((src[self.pos] >= 48 and src[self.pos] <= 55) or src[self.pos] == 95):
                self.pos = self.pos + 1
            return TK_INT_LIT()

    // Decimal digits
    while self.pos < slen and (is_digit(src[self.pos]) or src[self.pos] == 95):
        self.pos = self.pos + 1

    // Check for decimal point (but not .. range)
    if self.pos < slen and src[self.pos] == 46:
        if self.pos + 1 < slen and src[self.pos + 1] != 46:
            is_float = true
            self.pos = self.pos + 1
            while self.pos < slen and (is_digit(src[self.pos]) or src[self.pos] == 95):
                self.pos = self.pos + 1

    // Check for type suffix: 100_i64, 3.14_f32, etc.
    if self.pos > start and self.pos < slen and src[self.pos - 1] == 95:
        let ch2 = src[self.pos]
        if ch2 == 105 or ch2 == 117 or ch2 == 102:  // i, u, f
            if suffix_accept(src, self.pos, slen, "i8", 2):
                self.pos = self.pos + 2
            else:
                if suffix_accept(src, self.pos, slen, "i16", 3):
                    self.pos = self.pos + 3
                else:
                    if suffix_accept(src, self.pos, slen, "i32", 3):
                        self.pos = self.pos + 3
                    else:
                        if suffix_accept(src, self.pos, slen, "i64", 3):
                            self.pos = self.pos + 3
                        else:
                            if suffix_accept(src, self.pos, slen, "u8", 2):
                                self.pos = self.pos + 2
                            else:
                                if suffix_accept(src, self.pos, slen, "u16", 3):
                                    self.pos = self.pos + 3
                                else:
                                    if suffix_accept(src, self.pos, slen, "u32", 3):
                                        self.pos = self.pos + 3
                                    else:
                                        if suffix_accept(src, self.pos, slen, "u64", 3):
                                            self.pos = self.pos + 3
                                        else:
                                            if suffix_accept(src, self.pos, slen, "f32", 3):
                                                self.pos = self.pos + 3
                                                is_float = true
                                            else:
                                                if suffix_accept(src, self.pos, slen, "f64", 3):
                                                    self.pos = self.pos + 3
                                                    is_float = true

    if is_float:
        return TK_FLOAT_LIT()
    TK_INT_LIT()

fn suffix_accept(src: str, pos: i32, slen: i32, suffix: str, suf_len: i32) -> bool:
    if pos + suf_len > slen:
        return false
    for i in 0..suf_len:
        if src[pos + i] != suffix[i]:
            return false
    // Make sure it's not followed by more identifier chars.
    if pos + suf_len < slen and is_ident_continue(src[pos + suf_len]):
        return false
    true

fn Lexer.lex_ident(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    let start = self.token_start
    while self.pos < slen and is_ident_continue(src[self.pos]):
        self.pos = self.pos + 1
    let text = src.slice(start as i64, self.pos as i64)

    // c"..." -> C-string literal
    if text == "c" and self.pos < slen and src[self.pos] == 34:
        self.pos = self.pos + 1  // skip opening "
        while self.pos < slen and src[self.pos] != 34:
            if src[self.pos] == 92:
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        if self.pos < slen:
            self.pos = self.pos + 1  // skip closing "
        return TK_C_STRING_LIT()

    let kw = tag_from_keyword(text)
    if kw != -1:
        return kw
    TK_IDENT()

fn Lexer.lex_dot_ident(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen and is_ident_continue(src[self.pos]):
        self.pos = self.pos + 1
    TK_DOT_IDENT()


// --- Character classification ---

fn is_ident_start(ch: i32) -> bool:
    (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122) or ch == 95

fn is_ident_continue(ch: i32) -> bool:
    is_ident_start(ch) or (ch >= 48 and ch <= 57)

fn is_digit(ch: i32) -> bool:
    ch >= 48 and ch <= 57

fn is_hex_digit(ch: i32) -> bool:
    (ch >= 48 and ch <= 57) or (ch >= 65 and ch <= 70) or (ch >= 97 and ch <= 102) or ch == 95

// Compute the 0-based column of a byte offset by scanning backward.
fn column_of(source: str, pos: i32) -> i32:
    var p = pos
    while p > 0:
        p = p - 1
        if source[p] == 10:
            return pos - p - 1
    pos
