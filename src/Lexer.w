// Lexer — Tokenizer: source bytes to token stream.
//
// The lexer scans source text character-by-character and produces
// a flat list of tokens with source spans. Whitespace (except
// significant newlines) is consumed silently. Comments are skipped.

use Token
use Span

// Named character constants for readability.
enum CharCode: i32:
    Newline = 10
    Cr = 13
    Tab = 9
    Space = 32
    Dquote = 34
    Squote = 39
    Backslash = 92
    Lbrace = 123
    Rbrace = 125
    Lparen = 40
    Rparen = 41
    Lbracket = 91
    Rbracket = 93
    Comma = 44
    Semicolon = 59
    Colon = 58
    Tilde = 126
    At = 64
    Caret = 94
    Ampersand = 38
    Plus = 43
    Minus = 45
    Star = 42
    Percent = 37
    Dollar = 36
    Eq = 61
    Bang = 33
    Question = 63
    Lt = 60
    Gt = 62
    Pipe = 124
    Slash = 47
    Dot = 46
    Hash = 35
    Underscore = 95
    D0 = 48
    D1 = 49
    D7 = 55
    D9 = 57
    A = 65
    B = 66
    E = 69
    F = 70
    O = 79
    X = 88
    Z = 90
    LowerA = 97
    LowerB = 98
    LowerE = 101
    LowerF = 102
    LowerI = 105
    LowerN = 110
    LowerO = 111
    LowerR = 114
    LowerT = 116
    LowerU = 117
    LowerX = 120
    LowerZ = 122

type Lexer {
    source: str,
    pos: i32,
    file_id: i32,
    token_start: i32,
    emit_comments: i32,
    last_sig_tag: i32,
}

fn Lexer.init(source: str, file_id: i32) -> Lexer:
    Lexer { source, pos: 0, file_id, token_start: 0, emit_comments: 0, last_sig_tag: -1 }

// Tokenize the entire source, returning a token list ending with EOF.
fn Lexer.tokenize(mut self: Lexer) -> TokenList:
    var tokens = TokenList.new()
    loop:
        let tag = self.next_token()
        tokens.append(tag, self.token_start, self.pos)
        if lexer_token_is_significant(tag) != 0:
            self.last_sig_tag = tag
        if tag == TokenKind.TK_EOF:
            break
    tokens

fn Lexer.tokenize_with_comments(mut self: Lexer) -> TokenList:
    self.emit_comments = 1
    self.tokenize()

// Produce the next token. Sets token_start/pos and returns the tag.
fn Lexer.next_token(mut self: Lexer) -> i32:
    self.skip_whitespace()

    let src = self.source
    let slen = src.len() as i32

    self.token_start = self.pos

    if self.pos >= slen:
        return TokenKind.TK_EOF

    let ch = src.byte_at((self.pos) as i64)

    // Newline
    if ch == CharCode.Newline:
        self.pos = self.pos + 1
        return TokenKind.TK_NEWLINE

    // Single-character delimiters and punctuation
    if ch == CharCode.Lparen:
        self.pos = self.pos + 1
        return TokenKind.TK_L_PAREN
    if ch == CharCode.Rparen:
        self.pos = self.pos + 1
        return TokenKind.TK_R_PAREN
    if ch == CharCode.Lbracket:
        self.pos = self.pos + 1
        return TokenKind.TK_L_BRACKET
    if ch == CharCode.Rbracket:
        self.pos = self.pos + 1
        return TokenKind.TK_R_BRACKET
    if ch == CharCode.Lbrace:
        self.pos = self.pos + 1
        return TokenKind.TK_L_BRACE
    if ch == CharCode.Rbrace:
        self.pos = self.pos + 1
        return TokenKind.TK_R_BRACE
    if ch == CharCode.Comma:
        self.pos = self.pos + 1
        return TokenKind.TK_COMMA
    if ch == CharCode.Semicolon:
        self.pos = self.pos + 1
        return TokenKind.TK_SEMICOLON
    if ch == CharCode.Colon:
        self.pos = self.pos + 1
        return TokenKind.TK_COLON
    if ch == CharCode.Tilde:
        self.pos = self.pos + 1
        return TokenKind.TK_TILDE
    if ch == CharCode.At:
        self.pos = self.pos + 1
        return TokenKind.TK_AT
    if ch == CharCode.Caret:
        self.pos = self.pos + 1
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:  // ^=
            self.pos = self.pos + 1
            return TokenKind.TK_CARET_EQ
        return TokenKind.TK_CARET
    if ch == CharCode.Ampersand:
        self.pos = self.pos + 1
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:  // &=
            self.pos = self.pos + 1
            return TokenKind.TK_AMP_EQ
        return TokenKind.TK_AMPERSAND

    // + compound operators
    if ch == CharCode.Plus:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Plus:  // ++
                self.pos = self.pos + 1
                return TokenKind.TK_PLUS_PLUS
            if c2 == CharCode.Percent:  // +% or +%=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:
                    self.pos = self.pos + 1
                    return TokenKind.TK_PLUS_WRAP_EQ
                return TokenKind.TK_PLUS_WRAP
            if c2 == CharCode.Pipe:  // +| or +|=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:
                    self.pos = self.pos + 1
                    return TokenKind.TK_PLUS_SAT_EQ
                return TokenKind.TK_PLUS_SAT
            if c2 == CharCode.Eq:  // +=
                self.pos = self.pos + 1
                return TokenKind.TK_PLUS_EQ
        return TokenKind.TK_PLUS

    // - compound operators
    if ch == CharCode.Minus:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Gt:  // ->
                self.pos = self.pos + 1
                return TokenKind.TK_ARROW
            if c2 == CharCode.Percent:  // -% or -%=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:
                    self.pos = self.pos + 1
                    return TokenKind.TK_MINUS_WRAP_EQ
                return TokenKind.TK_MINUS_WRAP
            if c2 == CharCode.Pipe:  // -| or -|=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:
                    self.pos = self.pos + 1
                    return TokenKind.TK_MINUS_SAT_EQ
                return TokenKind.TK_MINUS_SAT
            if c2 == CharCode.Eq:  // -=
                self.pos = self.pos + 1
                return TokenKind.TK_MINUS_EQ
        return TokenKind.TK_MINUS

    // * compound operators
    if ch == CharCode.Star:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Percent:  // *% or *%=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:
                    self.pos = self.pos + 1
                    return TokenKind.TK_STAR_WRAP_EQ
                return TokenKind.TK_STAR_WRAP
            if c2 == CharCode.Pipe:  // *| or *|=
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:
                    self.pos = self.pos + 1
                    return TokenKind.TK_STAR_SAT_EQ
                return TokenKind.TK_STAR_SAT
            if c2 == CharCode.Eq:  // *=
                self.pos = self.pos + 1
                return TokenKind.TK_STAR_EQ
        return TokenKind.TK_STAR

    // % compound
    if ch == CharCode.Percent:
        self.pos = self.pos + 1
        if self.pos < slen:
            if src.byte_at((self.pos) as i64) == CharCode.Eq:  // %=
                self.pos = self.pos + 1
                return TokenKind.TK_PERCENT_EQ
        return TokenKind.TK_PERCENT

    // = compound
    if ch == CharCode.Eq:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Eq:  // ==
                self.pos = self.pos + 1
                return TokenKind.TK_EQ_EQ
            if c2 == CharCode.Tilde:  // =~
                self.pos = self.pos + 1
                return TokenKind.TK_EQ_TILDE
            if c2 == CharCode.Gt:  // =>
                self.pos = self.pos + 1
                return TokenKind.TK_FAT_ARROW
        return TokenKind.TK_EQ

    // ! compound
    if ch == CharCode.Bang:
        self.pos = self.pos + 1
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:  // !=
            self.pos = self.pos + 1
            return TokenKind.TK_BANG_EQ
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Tilde:  // !~
            self.pos = self.pos + 1
            return TokenKind.TK_BANG_TILDE
        return TokenKind.TK_BANG

    // ? compound
    if ch == CharCode.Question:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Dot:  // ?.
                self.pos = self.pos + 1
                return TokenKind.TK_QUESTION_DOT
            if c2 == CharCode.Question:  // ??
                self.pos = self.pos + 1
                return TokenKind.TK_QUESTION_QUESTION
        return TokenKind.TK_QUESTION

    // < compound
    if ch == CharCode.Lt:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Eq:  // <=
                self.pos = self.pos + 1
                return TokenKind.TK_LT_EQ
            if c2 == CharCode.Lt:  // <<
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:  // <<=
                    self.pos = self.pos + 1
                    return TokenKind.TK_LT_LT_EQ
                return TokenKind.TK_LT_LT
            if c2 == CharCode.Pipe:  // <|
                self.pos = self.pos + 1
                return TokenKind.TK_LT_PIPE
        return TokenKind.TK_LT

    // > compound
    if ch == CharCode.Gt:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Eq:  // >=
                self.pos = self.pos + 1
                return TokenKind.TK_GT_EQ
            if c2 == CharCode.Gt:  // >>
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:  // >>=
                    self.pos = self.pos + 1
                    return TokenKind.TK_GT_GT_EQ
                return TokenKind.TK_GT_GT
        return TokenKind.TK_GT

    // | compound
    if ch == CharCode.Pipe:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Gt:  // |>
                self.pos = self.pos + 1
                return TokenKind.TK_PIPE_GT
            if c2 == CharCode.Eq:  // |=
                self.pos = self.pos + 1
                return TokenKind.TK_PIPE_EQ
        return TokenKind.TK_PIPE

    // / and //
    if ch == CharCode.Slash:
        if self.pos + 1 < slen:
            let c2 = src.byte_at((self.pos + 1) as i64)
            if c2 == CharCode.Slash:  // // comment
                self.pos = self.pos + 2
                while self.pos < slen and src.byte_at((self.pos) as i64) != CharCode.Newline:
                    self.pos = self.pos + 1
                if self.emit_comments != 0:
                    return TokenKind.TK_COMMENT
                return self.next_token()
            if c2 == CharCode.Eq:  // /=
                self.pos = self.pos + 2
                return TokenKind.TK_SLASH_EQ
        if lexer_slash_starts_regex(self.last_sig_tag) != 0:
            return self.lex_regex()
        self.pos = self.pos + 1
        return TokenKind.TK_SLASH

    // . compound
    if ch == CharCode.Dot:
        self.pos = self.pos + 1
        if self.pos < slen:
            let c2 = src.byte_at((self.pos) as i64)
            if c2 == CharCode.Dot:  // ..
                self.pos = self.pos + 1
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Eq:  // ..=
                    self.pos = self.pos + 1
                    return TokenKind.TK_DOT_DOT_EQ
                if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Dot:  // ...
                    self.pos = self.pos + 1
                    return TokenKind.TK_DOT_DOT_DOT
                return TokenKind.TK_DOT_DOT
            // .Uppercase = dot identifier
            if c2 >= CharCode.A and c2 <= CharCode.Z:
                return self.lex_dot_ident()
        return TokenKind.TK_DOT

    // String literal
    if ch == CharCode.Dquote:
        return self.lex_string()

    // Number literal
    if ch >= CharCode.D0 and ch <= CharCode.D9:
        return self.lex_number()

    if ch == CharCode.Dollar:
        return self.lex_capture_ident()

    // Identifier or keyword
    if is_ident_start(ch):
        return self.lex_ident()

    // Character literal or label: 'x' / 'name
    if ch == CharCode.Squote:
        self.pos = self.pos + 1
        // Try char literal first: 'x', '\n', '\x41', ...
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Backslash:
            if self.pos + 1 < slen:
                var p = self.pos + 1
                if src.byte_at(p as i64) == CharCode.LowerX and p + 2 < slen:  // xNN
                    p = p + 2
                if p + 1 < slen and src.byte_at((p + 1) as i64) == CharCode.Squote:
                    self.pos = p + 2
                    return TokenKind.TK_CHAR_LIT
        if self.pos + 1 < slen and src.byte_at((self.pos + 1) as i64) == CharCode.Squote:
            // Single char: 'a'
            self.pos = self.pos + 2
            return TokenKind.TK_CHAR_LIT
        // Label: 'name
        if self.pos < slen and is_ident_start(src.byte_at((self.pos) as i64)):
            while self.pos < slen and is_ident_continue(src.byte_at((self.pos) as i64)):
                self.pos = self.pos + 1
            return TokenKind.TK_LABEL
        return TokenKind.TK_INVALID

    // Unknown character
    self.pos = self.pos + 1
    TokenKind.TK_INVALID


// --- Internal helpers ---

fn Lexer.skip_whitespace(mut self: Lexer):
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen:
        let ch = src.byte_at((self.pos) as i64)
        if not (ch == CharCode.Space or ch == CharCode.Tab or ch == CharCode.Cr):
            break
        self.pos = self.pos + 1

fn Lexer.lex_string(mut self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    self.pos = self.pos + 1  // skip opening "

    // Check for triple-quoted multi-line string: """..."""
    if self.pos + 1 < slen and src.byte_at((self.pos) as i64) == CharCode.Dquote and src.byte_at((self.pos + 1) as i64) == CharCode.Dquote:
        self.pos = self.pos + 2  // skip the two additional quotes
        // Skip optional leading newline after opening """
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Newline:
            self.pos = self.pos + 1
        while self.pos + 2 < slen:
            if src.byte_at((self.pos) as i64) == CharCode.Dquote and src.byte_at((self.pos + 1) as i64) == CharCode.Dquote and src.byte_at((self.pos + 2) as i64) == CharCode.Dquote:
                self.pos = self.pos + 3
                return TokenKind.TK_STRING_LIT
            if src.byte_at((self.pos) as i64) == CharCode.Backslash:
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        // Unterminated multi-line string — return STRING_LIT for parser recovery.
        return TokenKind.TK_STRING_LIT

    // Regular strings: no interpolation. Scan for closing `"`, handle `\` escapes.
    while self.pos < slen:
        let ch = src.byte_at((self.pos) as i64)
        if ch == CharCode.Dquote:
            self.pos = self.pos + 1
            return TokenKind.TK_STRING_LIT
        if ch == CharCode.Backslash:
            self.pos = self.pos + 1
        self.pos = self.pos + 1
    // Unterminated — return STRING_LIT for parser recovery.
    TokenKind.TK_STRING_LIT

fn Lexer.lex_number(mut self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    var is_float = false
    var scanned_prefixed = false

    // Check for 0x, 0b, 0o prefixes
    if src.byte_at((self.pos) as i64) == CharCode.D0 and self.pos + 1 < slen:
        let prefix = src.byte_at((self.pos + 1) as i64)
        if prefix == CharCode.LowerX or prefix == CharCode.X:
            scanned_prefixed = true
            self.pos = self.pos + 2
            while self.pos < slen and (is_hex_digit(src.byte_at((self.pos) as i64)) or src.byte_at((self.pos) as i64) == CharCode.Underscore):
                self.pos = self.pos + 1
        else if prefix == CharCode.LowerB or prefix == CharCode.B:
            scanned_prefixed = true
            self.pos = self.pos + 2
            while self.pos < slen and (src.byte_at((self.pos) as i64) == CharCode.D0 or src.byte_at((self.pos) as i64) == CharCode.D1 or src.byte_at((self.pos) as i64) == CharCode.Underscore):
                self.pos = self.pos + 1
        else if prefix == CharCode.LowerO or prefix == CharCode.O:
            scanned_prefixed = true
            self.pos = self.pos + 2
            while self.pos < slen and ((src.byte_at((self.pos) as i64) >= CharCode.D0 and src.byte_at((self.pos) as i64) <= CharCode.D7) or src.byte_at((self.pos) as i64) == CharCode.Underscore):
                self.pos = self.pos + 1

    if not scanned_prefixed:
        // Decimal digits
        while self.pos < slen and (lex_is_digit(src.byte_at((self.pos) as i64)) or src.byte_at((self.pos) as i64) == CharCode.Underscore):
            self.pos = self.pos + 1

        // Check for decimal point (but not .. range)
        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Dot:
            if self.pos + 1 < slen and src.byte_at((self.pos + 1) as i64) != CharCode.Dot:
                is_float = true
                self.pos = self.pos + 1
                while self.pos < slen and (lex_is_digit(src.byte_at((self.pos) as i64)) or src.byte_at((self.pos) as i64) == CharCode.Underscore):
                    self.pos = self.pos + 1

        // Check for exponent (e/E followed by optional +/- and digits)
        if self.pos < slen:
            let exp_ch = src.byte_at((self.pos) as i64)
            if exp_ch == CharCode.LowerE or exp_ch == CharCode.E:
                is_float = true
                self.pos = self.pos + 1
                // Optional sign
                if self.pos < slen:
                    let sign_ch = src.byte_at((self.pos) as i64)
                    if sign_ch == CharCode.Plus or sign_ch == CharCode.Minus:
                        self.pos = self.pos + 1
                // Exponent digits
                while self.pos < slen and (lex_is_digit(src.byte_at((self.pos) as i64)) or src.byte_at((self.pos) as i64) == CharCode.Underscore):
                    self.pos = self.pos + 1

    // Check for type suffix: 100i64, 3.14f32, 0xFFu32.
    let suffix_pos = self.pos
    let suffix_len = numeric_suffix_len(src, suffix_pos, slen)
    if suffix_len > 0:
        let suffix_head = src.byte_at(suffix_pos as i64)
        self.pos = suffix_pos + suffix_len
        if suffix_head == CharCode.LowerF:
            is_float = true

    if is_float:
        return TokenKind.TK_FLOAT_LIT
    TokenKind.TK_INT_LIT

fn numeric_suffix_len(src: str, pos: i32, slen: i32) -> i32:
    if pos >= slen:
        return 0
    let ch = src.byte_at(pos as i64)
    if ch != CharCode.LowerI and ch != CharCode.LowerU and ch != CharCode.LowerF:
        return 0
    if suffix_accept(src, pos, slen, "usize", 5):
        return 5
    if suffix_accept(src, pos, slen, "isize", 5):
        return 5
    if suffix_accept(src, pos, slen, "u128", 4):
        return 4
    if suffix_accept(src, pos, slen, "i128", 4):
        return 4
    if suffix_accept(src, pos, slen, "u64", 3):
        return 3
    if suffix_accept(src, pos, slen, "i64", 3):
        return 3
    if suffix_accept(src, pos, slen, "u32", 3):
        return 3
    if suffix_accept(src, pos, slen, "i32", 3):
        return 3
    if suffix_accept(src, pos, slen, "u16", 3):
        return 3
    if suffix_accept(src, pos, slen, "i16", 3):
        return 3
    if suffix_accept(src, pos, slen, "f32", 3):
        return 3
    if suffix_accept(src, pos, slen, "f64", 3):
        return 3
    if suffix_accept(src, pos, slen, "u8", 2):
        return 2
    if suffix_accept(src, pos, slen, "i8", 2):
        return 2
    0

fn suffix_accept(src: str, pos: i32, slen: i32, suffix: str, suf_len: i32) -> bool:
    if pos + suf_len > slen:
        return false
    for i in 0..suf_len:
        if src.byte_at((pos + i) as i64) != suffix[i]:
            return false
    // Make sure it's not followed by more identifier chars.
    if pos + suf_len < slen and is_ident_continue(src.byte_at((pos + suf_len) as i64)):
        return false
    true

fn lex_fstring_quote_source_backslash_count(raw_backslashes: i32) -> i32:
    raw_backslashes / 2

fn Lexer.lex_ident(mut self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    let start = self.token_start
    while self.pos < slen and is_ident_continue(src.byte_at((self.pos) as i64)):
        self.pos = self.pos + 1
    let text = src.slice(start as i64, self.pos as i64)

    // c"..." -> C-string literal
    if text == "c" and self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Dquote:
        self.pos = self.pos + 1  // skip opening "
        while self.pos < slen and src.byte_at((self.pos) as i64) != CharCode.Dquote:
            if src.byte_at((self.pos) as i64) == CharCode.Backslash:
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        if self.pos < slen:
            self.pos = self.pos + 1  // skip closing "
        return TokenKind.TK_C_STRING_LIT

    // r"..." / r#"..."# -> raw string literal (no escapes/interpolation)
    if text == "r":
        let raw_tok = self.lex_raw_string_prefixed()
        if raw_tok != -1:
            return raw_tok

    // f"..." -> interpolated string literal (f prefix + normal string lexing)
    if text == "f" and self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Dquote:
        self.pos = self.pos + 1  // skip opening "
        // Lex string body with brace-depth tracking (same as normal strings)
        var f_brace_depth = 0
        var f_expr_in_string = false
        var f_expr_in_char = false
        while self.pos < slen:
            let fch = src.byte_at((self.pos) as i64)
            if f_brace_depth > 0:
                if f_expr_in_string:
                    if fch == CharCode.Backslash:
                        let bs_start = self.pos
                        while self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Backslash:
                            self.pos = self.pos + 1
                        if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Dquote:
                            let src_bs = lex_fstring_quote_source_backslash_count(self.pos - bs_start)
                            if src_bs % 2 == 0:
                                f_expr_in_string = false
                            self.pos = self.pos + 1
                            continue
                        continue
                    self.pos = self.pos + 1
                    continue
                if f_expr_in_char:
                    if fch == CharCode.Backslash and self.pos + 1 < slen:
                        self.pos = self.pos + 2
                        continue
                    if fch == CharCode.Squote:
                        f_expr_in_char = false
                    self.pos = self.pos + 1
                    continue
                if fch == CharCode.Backslash:
                    let bs_start = self.pos
                    while self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Backslash:
                        self.pos = self.pos + 1
                    if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Dquote:
                        let src_bs = lex_fstring_quote_source_backslash_count(self.pos - bs_start)
                        if src_bs == 0:
                            f_expr_in_string = true
                        self.pos = self.pos + 1
                        continue
                    continue
                if fch == CharCode.Squote:
                    f_expr_in_char = true
                    self.pos = self.pos + 1
                    continue
            if fch == CharCode.Lbrace and f_brace_depth == 0:
                if self.pos + 1 < slen and src.byte_at((self.pos + 1) as i64) == CharCode.Lbrace:
                    self.pos = self.pos + 2
                    continue
                var fbs = 0
                while fbs < self.pos and src.byte_at((self.pos - 1 - fbs) as i64) == CharCode.Backslash:
                    fbs = fbs + 1
                if fbs % 2 == 0:
                    f_brace_depth = f_brace_depth + 1
                    self.pos = self.pos + 1
                    continue
            if fch == CharCode.Lbrace and f_brace_depth > 0:
                f_brace_depth = f_brace_depth + 1
                self.pos = self.pos + 1
                continue
            if fch == CharCode.Rbrace and f_brace_depth > 0:
                f_brace_depth = f_brace_depth - 1
                self.pos = self.pos + 1
                continue
            if fch == CharCode.Rbrace and f_brace_depth == 0 and self.pos + 1 < slen and src.byte_at((self.pos + 1) as i64) == CharCode.Rbrace:
                self.pos = self.pos + 2
                continue
            if fch == CharCode.Dquote and f_brace_depth == 0:
                self.pos = self.pos + 1
                return TokenKind.TK_STRING_LIT
            if fch == CharCode.Backslash:
                self.pos = self.pos + 1
            self.pos = self.pos + 1
        return TokenKind.TK_STRING_LIT

    // b'...' -> byte literal (tokenized as char literal).
    if text == "b" and self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Squote:
        let bt = self.lex_byte_char_prefixed()
        if bt != -1:
            return bt

    let kw = tag_from_keyword(text)
    if kw != -1:
        return kw
    TokenKind.TK_IDENT

fn Lexer.lex_capture_ident(mut self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    self.pos = self.pos + 1
    if self.pos >= slen:
        return TokenKind.TK_INVALID
    let ch = src.byte_at(self.pos as i64)
    if not (is_ident_start(ch) or lex_is_digit(ch)):
        return TokenKind.TK_INVALID
    self.pos = self.pos + 1
    while self.pos < slen and is_ident_continue(src.byte_at(self.pos as i64)):
        self.pos = self.pos + 1
    TokenKind.TK_IDENT

fn Lexer.lex_regex(mut self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    self.pos = self.pos + 1  // skip opening /
    var in_class = 0
    while self.pos < slen:
        let ch = src.byte_at(self.pos as i64)
        if ch == CharCode.Backslash:
            self.pos = self.pos + 1
            if self.pos < slen:
                self.pos = self.pos + 1
            continue
        if ch == CharCode.Lbracket:
            in_class = 1
            self.pos = self.pos + 1
            continue
        if ch == CharCode.Rbracket and in_class != 0:
            in_class = 0
            self.pos = self.pos + 1
            continue
        if ch == CharCode.Slash and in_class == 0:
            self.pos = self.pos + 1
            while self.pos < slen and is_ident_continue(src.byte_at(self.pos as i64)):
                self.pos = self.pos + 1
            return TokenKind.TK_REGEX_LIT
        if ch == CharCode.Newline:
            return TokenKind.TK_INVALID
        self.pos = self.pos + 1
    TokenKind.TK_INVALID

fn Lexer.lex_dot_ident(mut self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    while self.pos < slen and is_ident_continue(src.byte_at((self.pos) as i64)):
        self.pos = self.pos + 1
    TokenKind.TK_DOT_IDENT

fn Lexer.lex_raw_string_prefixed(mut self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    var p = self.pos
    var hash_count = 0
    while p < slen and src.byte_at(p as i64) == CharCode.Hash:
        hash_count = hash_count + 1
        p = p + 1
    if p >= slen or src.byte_at(p as i64) != CharCode.Dquote:  // opening "
        return -1

    // Consume opening delimiter.
    self.pos = p + 1
    while self.pos < slen:
        if src.byte_at((self.pos) as i64) == CharCode.Dquote:
            var ok = true
            for hi in 0..hash_count:
                if self.pos + 1 + hi >= slen or src.byte_at((self.pos + 1 + hi) as i64) != CharCode.Hash:
                    ok = false
            if ok:
                self.pos = self.pos + 1 + hash_count
                return TokenKind.TK_STRING_LIT
        self.pos = self.pos + 1
    // Unterminated raw string: still emit string token for recovery.
    TokenKind.TK_STRING_LIT

fn Lexer.lex_byte_char_prefixed(mut self: Lexer) -> i32:
    let src = self.source
    let slen = src.len() as i32
    if self.pos >= slen or src.byte_at((self.pos) as i64) != CharCode.Squote:
        return -1
    self.pos = self.pos + 1  // skip opening '
    while self.pos < slen and src.byte_at((self.pos) as i64) != CharCode.Squote:
        if src.byte_at((self.pos) as i64) == CharCode.Backslash and self.pos + 1 < slen:
            self.pos = self.pos + 1
        self.pos = self.pos + 1
    if self.pos < slen and src.byte_at((self.pos) as i64) == CharCode.Squote:
        self.pos = self.pos + 1
    TokenKind.TK_CHAR_LIT


// --- Character classification ---

fn is_ident_start(ch: i32) -> bool:
    (ch >= CharCode.A and ch <= CharCode.Z) or (ch >= CharCode.LowerA and ch <= CharCode.LowerZ) or ch == CharCode.Underscore

fn is_ident_continue(ch: i32) -> bool:
    is_ident_start(ch) or (ch >= CharCode.D0 and ch <= CharCode.D9)

fn lex_is_digit(ch: i32) -> bool:
    ch >= CharCode.D0 and ch <= CharCode.D9

fn is_hex_digit(ch: i32) -> bool:
    (ch >= CharCode.D0 and ch <= CharCode.D9) or (ch >= CharCode.A and ch <= CharCode.F) or (ch >= CharCode.LowerA and ch <= CharCode.LowerF) or ch == CharCode.Underscore

fn lexer_token_is_significant(tag: i32) -> i32:
    if tag == TokenKind.TK_NEWLINE or tag == TokenKind.TK_COMMENT:
        return 0
    1

fn lexer_slash_starts_regex(prev_tag: i32) -> i32:
    if prev_tag < 0:
        return 1
    if prev_tag == TokenKind.TK_EQ or prev_tag == TokenKind.TK_EQ_EQ or prev_tag == TokenKind.TK_BANG_EQ or prev_tag == TokenKind.TK_BANG or prev_tag == TokenKind.TK_COLON:
        return 1
    if prev_tag == TokenKind.TK_COMMA or prev_tag == TokenKind.TK_SEMICOLON or prev_tag == TokenKind.TK_L_PAREN or prev_tag == TokenKind.TK_L_BRACKET or prev_tag == TokenKind.TK_L_BRACE:
        return 1
    if prev_tag == TokenKind.TK_ARROW or prev_tag == TokenKind.TK_FAT_ARROW or prev_tag == TokenKind.TK_PIPE_GT or prev_tag == TokenKind.TK_LT_PIPE:
        return 1
    if prev_tag == TokenKind.TK_PLUS or prev_tag == TokenKind.TK_MINUS or prev_tag == TokenKind.TK_STAR or prev_tag == TokenKind.TK_PERCENT:
        return 1
    if prev_tag == TokenKind.TK_PLUS_WRAP or prev_tag == TokenKind.TK_MINUS_WRAP or prev_tag == TokenKind.TK_STAR_WRAP:
        return 1
    if prev_tag == TokenKind.TK_PLUS_SAT or prev_tag == TokenKind.TK_MINUS_SAT or prev_tag == TokenKind.TK_STAR_SAT:
        return 1
    if prev_tag == TokenKind.TK_QUESTION or prev_tag == TokenKind.TK_QUESTION_DOT or prev_tag == TokenKind.TK_QUESTION_QUESTION:
        return 1
    if prev_tag == TokenKind.TK_LT or prev_tag == TokenKind.TK_GT or prev_tag == TokenKind.TK_LT_EQ or prev_tag == TokenKind.TK_GT_EQ:
        return 1
    if prev_tag == TokenKind.TK_AMPERSAND or prev_tag == TokenKind.TK_PIPE or prev_tag == TokenKind.TK_CARET:
        return 1
    if prev_tag == TokenKind.TK_KW_RETURN or prev_tag == TokenKind.TK_KW_IF or prev_tag == TokenKind.TK_KW_WHILE or prev_tag == TokenKind.TK_KW_FOR or prev_tag == TokenKind.TK_KW_MATCH:
        return 1
    if prev_tag == TokenKind.TK_KW_LET or prev_tag == TokenKind.TK_KW_VAR or prev_tag == TokenKind.TK_KW_WITH or prev_tag == TokenKind.TK_KW_IN:
        return 1
    if prev_tag == TokenKind.TK_KW_AND or prev_tag == TokenKind.TK_KW_OR or prev_tag == TokenKind.TK_KW_NOT:
        return 1
    if prev_tag == TokenKind.TK_EQ_TILDE or prev_tag == TokenKind.TK_BANG_TILDE:
        return 1
    0

// Compute the 0-based column of a byte offset by scanning backward.
fn column_of(source: str, pos: i32) -> i32:
    var p = pos
    while p > 0:
        p = p - 1
        if source.byte_at(p as i64) == CharCode.Newline:
            return pos - p - 1
    pos
