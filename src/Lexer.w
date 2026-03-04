// Lexer — Tokenizer: source bytes to token stream.
//
// The lexer scans source text character-by-character and produces
// a flat list of tokens with source spans. Whitespace (except
// significant newlines) is consumed silently. Comments are skipped.

use Token
use Span

// Named character constants for readability.
fn CH_NEWLINE -> i32: 10
fn CH_CR -> i32: 13
fn CH_TAB -> i32: 9
fn CH_SPACE -> i32: 32
fn CH_DQUOTE -> i32: 34
fn CH_SQUOTE -> i32: 39
fn CH_BACKSLASH -> i32: 92
fn CH_LBRACE -> i32: 123
fn CH_RBRACE -> i32: 125
fn CH_LPAREN -> i32: 40
fn CH_RPAREN -> i32: 41
fn CH_LBRACKET -> i32: 91
fn CH_RBRACKET -> i32: 93
fn CH_COMMA -> i32: 44
fn CH_SEMICOLON -> i32: 59
fn CH_COLON -> i32: 58
fn CH_TILDE -> i32: 126
fn CH_AT -> i32: 64
fn CH_CARET -> i32: 94
fn CH_AMPERSAND -> i32: 38
fn CH_PLUS -> i32: 43
fn CH_MINUS -> i32: 45
fn CH_STAR -> i32: 42
fn CH_PERCENT -> i32: 37
fn CH_EQ -> i32: 61
fn CH_BANG -> i32: 33
fn CH_QUESTION -> i32: 63
fn CH_LT -> i32: 60
fn CH_GT -> i32: 62
fn CH_PIPE -> i32: 124
fn CH_SLASH -> i32: 47
fn CH_DOT -> i32: 46
fn CH_HASH -> i32: 35
fn CH_UNDERSCORE -> i32: 95
fn CH_0 -> i32: 48
fn CH_9 -> i32: 57

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
        // Try char literal first: 'x', '\n', '\x41', ...
        if self.pos < slen and src[self.pos] == 92:  // backslash
            if self.pos + 1 < slen:
                var p = self.pos + 1
                if src[p] == 120 and p + 2 < slen:  // xNN
                    p = p + 2
                if p + 1 < slen and src[p + 1] == 39:
                    self.pos = p + 2
                    return TK_CHAR_LIT()
        if self.pos + 1 < slen and src[self.pos + 1] == 39:
            // Single char: 'a'
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
        // Unterminated multi-line string — return STRING_LIT for parser recovery.
        return TK_STRING_LIT()

    // Track brace depth so that `"` inside interpolation holes `{...}` is not
    // treated as the end of the string.
    var brace_depth = 0
    while self.pos < slen:
        let ch = src[self.pos]
        if ch == 123 and brace_depth == 0:  // {
            // Don't count escaped braces. Count consecutive backslashes
            // preceding this '{' — an odd count means the brace is escaped.
            var bs = 0
            while bs < self.pos and src[self.pos - 1 - bs] == 92:
                bs = bs + 1
            if bs % 2 == 0:
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
    // Unterminated — return STRING_LIT for parser recovery.
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
            while self.pos < slen and (is_hex_digit(src[self.pos]) or src[self.pos] == 95):
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
            else if suffix_accept(src, self.pos, slen, "i16", 3):
                self.pos = self.pos + 3
            else if suffix_accept(src, self.pos, slen, "i32", 3):
                self.pos = self.pos + 3
            else if suffix_accept(src, self.pos, slen, "i64", 3):
                self.pos = self.pos + 3
            else if suffix_accept(src, self.pos, slen, "u8", 2):
                self.pos = self.pos + 2
            else if suffix_accept(src, self.pos, slen, "u16", 3):
                self.pos = self.pos + 3
            else if suffix_accept(src, self.pos, slen, "u32", 3):
                self.pos = self.pos + 3
            else if suffix_accept(src, self.pos, slen, "u64", 3):
                self.pos = self.pos + 3
            else if suffix_accept(src, self.pos, slen, "f32", 3):
                self.pos = self.pos + 3
                is_float = true
            else if suffix_accept(src, self.pos, slen, "f64", 3):
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

    // r"..." / r#"..."# -> raw string literal (no escapes/interpolation)
    if text == "r":
        let raw_tok = self.lex_raw_string_prefixed()
        if raw_tok != -1:
            return raw_tok

    // b'...' -> byte literal (tokenized as char literal).
    if text == "b" and self.pos < slen and src[self.pos] == 39:
        let bt = self.lex_byte_char_prefixed()
        if bt != -1:
            return bt

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

fn Lexer.lex_raw_string_prefixed(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    var p = self.pos
    var hash_count = 0
    while p < slen and src[p] == 35:  // #
        hash_count = hash_count + 1
        p = p + 1
    if p >= slen or src[p] != 34:  // opening "
        return -1

    // Consume opening delimiter.
    self.pos = p + 1
    while self.pos < slen:
        if src[self.pos] == 34:  // "
            var ok = true
            for hi in 0..hash_count:
                if self.pos + 1 + hi >= slen or src[self.pos + 1 + hi] != 35:
                    ok = false
            if ok:
                self.pos = self.pos + 1 + hash_count
                return TK_STRING_LIT()
        self.pos = self.pos + 1
    // Unterminated raw string: still emit string token for recovery.
    TK_STRING_LIT()

fn Lexer.lex_byte_char_prefixed(self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    if self.pos >= slen or src[self.pos] != 39:
        return -1
    self.pos = self.pos + 1  // skip opening '
    while self.pos < slen and src[self.pos] != 39:
        if src[self.pos] == 92 and self.pos + 1 < slen:
            self.pos = self.pos + 1
        self.pos = self.pos + 1
    if self.pos < slen and src[self.pos] == 39:
        self.pos = self.pos + 1
    TK_CHAR_LIT()


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
