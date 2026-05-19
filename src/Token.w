// Token — Token definitions for the With language.
//
// The lexer produces a flat list of tokens. Each token carries a tag
// and a span pointing back into the source text. Literal values and
// identifier text are recovered from the source via the span.

use Span

// All token kinds produced by the lexer.
enum TokenKind: i32:
    // Literals
    TK_INT_LIT = 0
    TK_FLOAT_LIT = 1
    TK_STRING_LIT = 2
    TK_C_STRING_LIT = 3
    TK_STRING_START = 4
    TK_STRING_END = 5
    TK_STRING_FRAGMENT = 6
    TK_CHAR_LIT = 7
    TK_TRUE = 8
    TK_FALSE = 9
    // Identifiers
    TK_IDENT = 10
    TK_DOT_IDENT = 11
    TK_LABEL = 12
    // Keywords
    TK_KW_FN = 13
    TK_KW_LET = 14
    TK_KW_VAR = 15
    TK_KW_IF = 16
    TK_KW_ELSE = 17
    TK_KW_THEN = 18
    TK_KW_MATCH = 19
    TK_KW_FOR = 20
    TK_KW_IN = 21
    TK_KW_WHILE = 22
    TK_KW_LOOP = 23
    TK_KW_RETURN = 24
    TK_KW_BREAK = 25
    TK_KW_CONTINUE = 26
    TK_KW_WITH = 27
    TK_KW_AS = 28
    TK_KW_MUT = 29
    TK_KW_TYPE = 30
    TK_KW_TRAIT = 31
    TK_KW_IMPL = 32
    TK_KW_EXTEND = 33
    TK_KW_DYN = 34
    TK_KW_USE = 35
    TK_KW_MODULE = 36
    TK_KW_PUB = 37
    TK_KW_ASYNC = 38
    TK_KW_AWAIT = 39
    TK_KW_SPAWN = 40
    TK_KW_UNSAFE = 41
    TK_KW_COMPTIME = 42
    TK_KW_GEN = 43
    TK_KW_YIELD = 44
    TK_KW_DEFER = 45
    TK_KW_ERROR = 46
    TK_KW_EXTERN = 47
    TK_KW_C_IMPORT = 48
    TK_KW_EPHEMERAL = 49
    TK_KW_SELECT = 50
    TK_KW_NOT = 51
    TK_KW_AND = 52
    TK_KW_OR = 53
    // Operators
    TK_PLUS = 54
    TK_MINUS = 55
    TK_STAR = 56
    TK_SLASH = 57
    TK_PERCENT = 58
    TK_PLUS_WRAP = 59
    TK_MINUS_WRAP = 60
    TK_STAR_WRAP = 61
    TK_EQ = 62
    TK_EQ_EQ = 63
    TK_BANG = 64
    TK_BANG_EQ = 65
    TK_LT = 66
    TK_GT = 67
    TK_LT_EQ = 68
    TK_GT_EQ = 69
    TK_AMPERSAND = 70
    TK_PIPE = 71
    TK_CARET = 72
    TK_TILDE = 73
    TK_AT = 74
    TK_QUESTION = 75
    TK_QUESTION_DOT = 76
    TK_QUESTION_QUESTION = 77
    TK_ARROW = 78
    TK_FAT_ARROW = 79
    TK_DOT_DOT = 80
    TK_DOT_DOT_EQ = 81
    TK_DOT_DOT_DOT = 82
    TK_PIPE_GT = 83
    TK_LT_PIPE = 84
    TK_GT_GT = 85
    TK_LT_LT = 86
    TK_PLUS_PLUS = 87
    TK_PLUS_EQ = 88
    TK_MINUS_EQ = 89
    TK_STAR_EQ = 90
    TK_SLASH_EQ = 91
    TK_PERCENT_EQ = 92
    // Delimiters
    TK_L_PAREN = 93
    TK_R_PAREN = 94
    TK_L_BRACKET = 95
    TK_R_BRACKET = 96
    TK_L_BRACE = 97
    TK_R_BRACE = 98
    // Punctuation
    TK_COLON = 99
    TK_COMMA = 100
    TK_DOT = 101
    TK_SEMICOLON = 102
    // Structural
    TK_NEWLINE = 103
    TK_INDENT = 104
    TK_DEDENT = 105
    // Special
    TK_COMMENT = 106
    TK_EOF = 107
    TK_INVALID = 108
    // Extended keywords
    TK_KW_CONST = 109
    TK_KW_IT = 110
    TK_KW_ERRDEFER = 111
    TK_KW_MOVE = 112
    TK_KW_WHERE = 113
    TK_KW_OPAQUE = 114
    TK_KW_NULL = 115
    TK_KW_UNION = 116
    // Extended operators
    TK_AMP_EQ = 117
    TK_PIPE_EQ = 118
    TK_CARET_EQ = 119
    TK_LT_LT_EQ = 120
    TK_GT_GT_EQ = 121
    TK_PLUS_WRAP_EQ = 122
    TK_MINUS_WRAP_EQ = 123
    TK_STAR_WRAP_EQ = 124
    TK_KW_ENUM = 125
    TK_PLUS_SAT = 126
    TK_MINUS_SAT = 127
    TK_STAR_SAT = 128
    TK_PLUS_SAT_EQ = 129
    TK_MINUS_SAT_EQ = 130
    TK_STAR_SAT_EQ = 131
    TK_KW_ASM = 132
    TK_KW_GOTO = 133
    // docs/mut.md Rev 8 §12 — module-level place declarations.
    TK_KW_GLOBAL = 134
    // docs/mutability.md — call-site passing mode keywords.
    TK_KW_COPY = 135
    // Regex integration.
    TK_REGEX_LIT = 136
    TK_EQ_TILDE = 137
    TK_BANG_TILDE = 138
    TK_KW_DO = 139

// Lookup table: keyword string -> tag. Returns -1 if not a keyword.
fn tag_from_keyword(s: str) -> i32:
    if s == "fn": return TokenKind.TK_KW_FN
    if s == "let": return TokenKind.TK_KW_LET
    if s == "var": return TokenKind.TK_KW_VAR
    if s == "if": return TokenKind.TK_KW_IF
    if s == "else": return TokenKind.TK_KW_ELSE
    if s == "then": return TokenKind.TK_KW_THEN
    if s == "match": return TokenKind.TK_KW_MATCH
    if s == "for": return TokenKind.TK_KW_FOR
    if s == "in": return TokenKind.TK_KW_IN
    if s == "while": return TokenKind.TK_KW_WHILE
    if s == "loop": return TokenKind.TK_KW_LOOP
    if s == "return": return TokenKind.TK_KW_RETURN
    if s == "break": return TokenKind.TK_KW_BREAK
    if s == "continue": return TokenKind.TK_KW_CONTINUE
    if s == "with": return TokenKind.TK_KW_WITH
    if s == "as": return TokenKind.TK_KW_AS
    if s == "mut": return TokenKind.TK_KW_MUT
    if s == "type": return TokenKind.TK_KW_TYPE
    if s == "trait": return TokenKind.TK_KW_TRAIT
    if s == "impl": return TokenKind.TK_KW_IMPL
    if s == "extend": return TokenKind.TK_KW_EXTEND
    if s == "dyn": return TokenKind.TK_KW_DYN
    if s == "use": return TokenKind.TK_KW_USE
    if s == "module": return TokenKind.TK_KW_MODULE
    if s == "pub": return TokenKind.TK_KW_PUB
    if s == "async": return TokenKind.TK_KW_ASYNC
    if s == "await": return TokenKind.TK_KW_AWAIT
    if s == "spawn": return TokenKind.TK_KW_SPAWN
    if s == "unsafe": return TokenKind.TK_KW_UNSAFE
    if s == "comptime": return TokenKind.TK_KW_COMPTIME
    if s == "gen": return TokenKind.TK_KW_GEN
    if s == "yield": return TokenKind.TK_KW_YIELD
    if s == "defer": return TokenKind.TK_KW_DEFER
    if s == "error": return TokenKind.TK_KW_ERROR
    if s == "extern": return TokenKind.TK_KW_EXTERN
    if s == "c_import": return TokenKind.TK_KW_C_IMPORT
    if s == "ephemeral": return TokenKind.TK_KW_EPHEMERAL
    if s == "select": return TokenKind.TK_KW_SELECT
    if s == "true": return TokenKind.TK_TRUE
    if s == "false": return TokenKind.TK_FALSE
    if s == "not": return TokenKind.TK_KW_NOT
    if s == "and": return TokenKind.TK_KW_AND
    if s == "or": return TokenKind.TK_KW_OR
    if s == "const": return TokenKind.TK_KW_CONST
    if s == "it": return TokenKind.TK_KW_IT
    if s == "errdefer": return TokenKind.TK_KW_ERRDEFER
    if s == "move": return TokenKind.TK_KW_MOVE
    if s == "where": return TokenKind.TK_KW_WHERE
    if s == "opaque": return TokenKind.TK_KW_OPAQUE
    if s == "null": return TokenKind.TK_KW_NULL
    if s == "union": return TokenKind.TK_KW_UNION
    if s == "enum": return TokenKind.TK_KW_ENUM
    if s == "asm": return TokenKind.TK_KW_ASM
    if s == "goto": return TokenKind.TK_KW_GOTO
    if s == "global": return TokenKind.TK_KW_GLOBAL
    if s == "copy": return TokenKind.TK_KW_COPY
    if s == "do": return TokenKind.TK_KW_DO
    -1

// Returns a human-readable name for a token tag (for diagnostics).
fn tag_name(tag: i32) -> str:
    if tag == TokenKind.TK_INT_LIT: return "integer literal"
    if tag == TokenKind.TK_FLOAT_LIT: return "float literal"
    if tag == TokenKind.TK_STRING_LIT: return "string literal"
    if tag == TokenKind.TK_C_STRING_LIT: return "c-string literal"
    if tag == TokenKind.TK_STRING_START: return "string start"
    if tag == TokenKind.TK_STRING_END: return "string end"
    if tag == TokenKind.TK_STRING_FRAGMENT: return "string fragment"
    if tag == TokenKind.TK_CHAR_LIT: return "character literal"
    if tag == TokenKind.TK_TRUE: return "'true'"
    if tag == TokenKind.TK_FALSE: return "'false'"
    if tag == TokenKind.TK_IDENT: return "identifier"
    if tag == TokenKind.TK_DOT_IDENT: return "dot-identifier"
    if tag == TokenKind.TK_LABEL: return "label"
    if tag == TokenKind.TK_KW_FN: return "'fn'"
    if tag == TokenKind.TK_KW_LET: return "'let'"
    if tag == TokenKind.TK_KW_VAR: return "'var'"
    if tag == TokenKind.TK_KW_IF: return "'if'"
    if tag == TokenKind.TK_KW_ELSE: return "'else'"
    if tag == TokenKind.TK_KW_THEN: return "'then'"
    if tag == TokenKind.TK_KW_MATCH: return "'match'"
    if tag == TokenKind.TK_KW_FOR: return "'for'"
    if tag == TokenKind.TK_KW_IN: return "'in'"
    if tag == TokenKind.TK_KW_WHILE: return "'while'"
    if tag == TokenKind.TK_KW_LOOP: return "'loop'"
    if tag == TokenKind.TK_KW_RETURN: return "'return'"
    if tag == TokenKind.TK_KW_BREAK: return "'break'"
    if tag == TokenKind.TK_KW_CONTINUE: return "'continue'"
    if tag == TokenKind.TK_KW_WITH: return "'with'"
    if tag == TokenKind.TK_KW_AS: return "'as'"
    if tag == TokenKind.TK_KW_MUT: return "'mut'"
    if tag == TokenKind.TK_KW_TYPE: return "'type'"
    if tag == TokenKind.TK_KW_TRAIT: return "'trait'"
    if tag == TokenKind.TK_KW_IMPL: return "'impl'"
    if tag == TokenKind.TK_KW_EXTEND: return "'extend'"
    if tag == TokenKind.TK_KW_DYN: return "'dyn'"
    if tag == TokenKind.TK_KW_USE: return "'use'"
    if tag == TokenKind.TK_KW_MODULE: return "'module'"
    if tag == TokenKind.TK_KW_PUB: return "'pub'"
    if tag == TokenKind.TK_KW_ASYNC: return "'async'"
    if tag == TokenKind.TK_KW_AWAIT: return "'await'"
    if tag == TokenKind.TK_KW_SPAWN: return "'spawn'"
    if tag == TokenKind.TK_KW_UNSAFE: return "'unsafe'"
    if tag == TokenKind.TK_KW_COMPTIME: return "'comptime'"
    if tag == TokenKind.TK_KW_GEN: return "'gen'"
    if tag == TokenKind.TK_KW_YIELD: return "'yield'"
    if tag == TokenKind.TK_KW_DEFER: return "'defer'"
    if tag == TokenKind.TK_KW_ERROR: return "'error'"
    if tag == TokenKind.TK_KW_EXTERN: return "'extern'"
    if tag == TokenKind.TK_KW_C_IMPORT: return "'c_import'"
    if tag == TokenKind.TK_KW_EPHEMERAL: return "'ephemeral'"
    if tag == TokenKind.TK_KW_SELECT: return "'select'"
    if tag == TokenKind.TK_KW_NOT: return "'not'"
    if tag == TokenKind.TK_KW_AND: return "'and'"
    if tag == TokenKind.TK_KW_OR: return "'or'"
    if tag == TokenKind.TK_KW_CONST: return "'const'"
    if tag == TokenKind.TK_KW_IT: return "'it'"
    if tag == TokenKind.TK_KW_ERRDEFER: return "'errdefer'"
    if tag == TokenKind.TK_KW_MOVE: return "'move'"
    if tag == TokenKind.TK_KW_WHERE: return "'where'"
    if tag == TokenKind.TK_KW_OPAQUE: return "'opaque'"
    if tag == TokenKind.TK_KW_NULL: return "'null'"
    if tag == TokenKind.TK_KW_UNION: return "'union'"
    if tag == TokenKind.TK_KW_ENUM: return "'enum'"
    if tag == TokenKind.TK_PLUS: return "'+'"
    if tag == TokenKind.TK_MINUS: return "'-'"
    if tag == TokenKind.TK_STAR: return "'*'"
    if tag == TokenKind.TK_SLASH: return "'/'"
    if tag == TokenKind.TK_PERCENT: return "'%'"
    if tag == TokenKind.TK_PLUS_WRAP: return "'+%'"
    if tag == TokenKind.TK_MINUS_WRAP: return "'-%'"
    if tag == TokenKind.TK_STAR_WRAP: return "'*%'"
    if tag == TokenKind.TK_PLUS_SAT: return "'+|'"
    if tag == TokenKind.TK_MINUS_SAT: return "'-|'"
    if tag == TokenKind.TK_STAR_SAT: return "'*|'"
    if tag == TokenKind.TK_KW_ASM: return "'asm'"
    if tag == TokenKind.TK_KW_GOTO: return "'goto'"
    if tag == TokenKind.TK_KW_GLOBAL: return "'global'"
    if tag == TokenKind.TK_KW_COPY: return "'copy'"
    if tag == TokenKind.TK_KW_DO: return "'do'"
    if tag == TokenKind.TK_REGEX_LIT: return "regex literal"
    if tag == TokenKind.TK_EQ: return "'='"
    if tag == TokenKind.TK_EQ_EQ: return "'=='"
    if tag == TokenKind.TK_EQ_TILDE: return "'=~'"
    if tag == TokenKind.TK_BANG: return "'!'"
    if tag == TokenKind.TK_BANG_EQ: return "'!='"
    if tag == TokenKind.TK_BANG_TILDE: return "'!~'"
    if tag == TokenKind.TK_LT: return "'<'"
    if tag == TokenKind.TK_GT: return "'>'"
    if tag == TokenKind.TK_LT_EQ: return "'<='"
    if tag == TokenKind.TK_GT_EQ: return "'>='"
    if tag == TokenKind.TK_AMPERSAND: return "'&'"
    if tag == TokenKind.TK_PIPE: return "'|'"
    if tag == TokenKind.TK_CARET: return "'^'"
    if tag == TokenKind.TK_TILDE: return "'~'"
    if tag == TokenKind.TK_AT: return "'@'"
    if tag == TokenKind.TK_QUESTION: return "'?'"
    if tag == TokenKind.TK_QUESTION_DOT: return "'?.'"
    if tag == TokenKind.TK_QUESTION_QUESTION: return "'??'"
    if tag == TokenKind.TK_ARROW: return "'->'"
    if tag == TokenKind.TK_FAT_ARROW: return "'=>'"
    if tag == TokenKind.TK_DOT_DOT: return "'..'"
    if tag == TokenKind.TK_DOT_DOT_EQ: return "'..='"
    if tag == TokenKind.TK_DOT_DOT_DOT: return "'...'"
    if tag == TokenKind.TK_PIPE_GT: return "'|>'"
    if tag == TokenKind.TK_LT_PIPE: return "'<|'"
    if tag == TokenKind.TK_GT_GT: return "'>>'"
    if tag == TokenKind.TK_LT_LT: return "'<<'"
    if tag == TokenKind.TK_PLUS_PLUS: return "'++'"
    if tag == TokenKind.TK_PLUS_EQ: return "'+='"
    if tag == TokenKind.TK_MINUS_EQ: return "'-='"
    if tag == TokenKind.TK_STAR_EQ: return "'*='"
    if tag == TokenKind.TK_SLASH_EQ: return "'/='"
    if tag == TokenKind.TK_PERCENT_EQ: return "'%='"
    if tag == TokenKind.TK_L_PAREN: return "'('"
    if tag == TokenKind.TK_R_PAREN: return "')'"
    if tag == TokenKind.TK_L_BRACKET: return "'['"
    if tag == TokenKind.TK_R_BRACKET: return "']'"
    if tag == TokenKind.TK_L_BRACE: return "left brace"
    if tag == TokenKind.TK_R_BRACE: return "right brace"
    if tag == TokenKind.TK_COLON: return "':'"
    if tag == TokenKind.TK_COMMA: return "','"
    if tag == TokenKind.TK_DOT: return "'.'"
    if tag == TokenKind.TK_SEMICOLON: return "';'"
    if tag == TokenKind.TK_NEWLINE: return "newline"
    if tag == TokenKind.TK_INDENT: return "indent"
    if tag == TokenKind.TK_DEDENT: return "dedent"
    if tag == TokenKind.TK_COMMENT: return "comment"
    if tag == TokenKind.TK_EOF: return "end of file"
    if tag == TokenKind.TK_INVALID: return "invalid token"
    "unknown"

// A growable list of tokens stored as parallel arrays for
// cache-friendly iteration over tags alone.
type TokenList {
    tags: Vec[i32],
    starts: Vec[i32],
    ends: Vec[i32],
}

fn TokenList.new -> TokenList:
    TokenList {
        tags: Vec.new(),
        starts: Vec.new(),
        ends: Vec.new(),
    }

// No-op: reserved for future manual memory management.
fn TokenList.deinit(self: TokenList):
    return

fn TokenList.append(mut self: TokenList, tag: i32, start: i32, end: i32) -> void:
    self.tags.push(tag)
    self.starts.push(start)
    self.ends.push(end)

fn TokenList.len(self: TokenList) -> i32:
    self.tags.len() as i32

fn TokenList.get_tag(self: TokenList, index: i32) -> i32:
    self.tags.get(index as i64)

fn TokenList.get_start(self: TokenList, index: i32) -> i32:
    self.starts.get(index as i64)

fn TokenList.get_end(self: TokenList, index: i32) -> i32:
    self.ends.get(index as i64)

// Convenience: construct a Span for token at index with a given file_id.
fn TokenList.get_span(self: TokenList, index: i32, file_id: i32) -> Span:
    Span {
        file: file_id,
        start: self.starts.get(index as i64),
        end: self.ends.get(index as i64),
    }

// Also expose a keyword_lookup alias for the lexer.
fn keyword_lookup(text: str) -> i32:
    tag_from_keyword(text)
