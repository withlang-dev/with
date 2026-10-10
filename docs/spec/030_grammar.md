# 30. Formal Grammar (Informative)

This appendix collects syntactic productions from throughout the
specification into a unified reference. The normative definitions
remain in their respective sections; this is a convenience index.
If this appendix drifts from a normative section, the normative
section wins. Requirements, conformance tests, and implementation
work must cite the owning normative section; this appendix may be
cited only as related context.

### 30.1 Notation

Productions use EBNF-like notation:

- `|` alternatives
- `[ ]` optional
- `{ }` zero or more repetitions
- `( )` grouping
- `'...'` terminal tokens
- `UPPER` non-terminal symbols

### 30.2 Lexical Grammar

**Identifiers** (§29.11):

```
IDENT       := LETTER { LETTER | DIGIT | '_' }
LETTER      := 'a'..'z' | 'A'..'Z' | '_'
DIGIT       := '0'..'9'
```

**Numeric literals** (§4.2.1, §29.1):

```
INT_LIT     := DEC_LIT | HEX_LIT | BIN_LIT | OCT_LIT
DEC_LIT     := DIGIT { DIGIT | '_' } [ INT_SUFFIX ]
HEX_LIT     := '0x' HEX_DIGIT { HEX_DIGIT | '_' } [ INT_SUFFIX ]
BIN_LIT     := '0b' BIN_DIGIT { BIN_DIGIT | '_' } [ INT_SUFFIX ]
OCT_LIT     := '0o' OCT_DIGIT { OCT_DIGIT | '_' } [ INT_SUFFIX ]
FLOAT_LIT   := DIGIT { DIGIT | '_' } '.' DIGIT { DIGIT | '_' } [ FLOAT_SUFFIX ]
INT_SUFFIX   := 'i8' | 'i16' | 'i32' | 'i64' | 'u8' | 'u16' | 'u32' | 'u64' | 'usize' | 'isize'
FLOAT_SUFFIX := 'f32' | 'f64'
```

**String literals** (§15.3, §29.3, §29.4):

```
STR_LIT     := '"' { CHAR | ESCAPE } '"'
RAW_STR     := 'r' HASHES '"' { CHAR } '"' HASHES
FSTRING     := 'f"' { CHAR | ESCAPE | '{' EXPR [ ':' FMT_SPEC ] '}' } '"'
CSTR_LIT    := 'c"' { CHAR | ESCAPE } '"'
CHAR_LIT    := "'" ( CHAR | ESCAPE ) "'"
BYTE_LIT    := "b'" BYTE_OR_ESCAPE "'"
HASHES      := { '#' }
```

When the lexer sees a bare apostrophe, it tries `CHAR_LIT` before
`LABEL`. A label has no closing apostrophe.

**Labels** (§13.5a, §29.5a):

```
LABEL       := "'" IDENT
```

`LABEL` may appear as a statement prefix or as the target operand of
`goto`, `break`, and `continue`. As a statement prefix, it must be
the first token of the statement and has no trailing colon of its own.

### 30.3 Declarations

**Function declaration** (§9.1):

```
FN_DECL     := [ PUB ] 'fn' IDENT [ TYPE_PARAMS ] [ '(' PARAMS ')' ] [ '->' TYPE [ FROM_CLAUSE ] ] [ WRITES_CLAUSE ] BODY
FROM_CLAUSE := 'from' ORIGIN { ',' ORIGIN }
ORIGIN      := 'self' | PATH
WRITES_CLAUSE := 'writes' PATH { ',' PATH }
PARAMS      := PARAM { ',' PARAM } [ ',' ]
PARAM       := IDENT ':' [ 'once' ] TYPE [ '=' EXPR ]
TYPE_PARAMS := '[' IDENT { ',' IDENT } [ ':' BOUND ] ']'
PUB         := 'pub'
```

**Struct declaration** (§4.3):

```
STRUCT_DECL := [ PUB ] 'type' IDENT [ TYPE_PARAMS ] '{' FIELDS '}'
FIELDS      := FIELD { ',' FIELD } [ ',' ]
FIELD       := [ PUB ] IDENT ':' TYPE [ '=' EXPR ]
             | [ PUB ] IDENT '=' EXPR
```

**Enum declaration** (§4.4):

```
ENUM_DECL   := [ PUB ] 'enum' IDENT [ TYPE_PARAMS ] [ ':' REPR_TYPE ] ENUM_BODY
ENUM_BODY   := '{' [ '|' ] VARIANT { ( '|' | ',' ) VARIANT } '}'
             | ':' NEWLINE INDENT [ '|' ] VARIANT { NEWLINE [ '|' ] VARIANT } DEDENT
VARIANT     := IDENT [ '(' VARIANT_FIELDS ')' ] [ '=' INT_LIT ]
REPR_TYPE   := 'i8' | 'i16' | 'i32' | 'i64' | 'u8' | 'u16' | 'u32' | 'u64'
```

**Trait and impl** (§11):

```
TRAIT_DECL  := [ PUB ] [ '@[sealed]' ] 'trait' IDENT [ TYPE_PARAMS ] BODY
IMPL_DECL   := 'impl' [ TYPE_PARAMS ] [ TRAIT 'for' ] TYPE BODY
```

**Import** (§18.2):

```
USE_DECL    := 'use' MODULE_PATH [ '.' '{' IMPORT_LIST '}' ]
MODULE_PATH := IDENT { '.' IDENT }
```

**Const declaration** (§9.1b):

```
CONST_DECL  := 'const' IDENT [ ':' TYPE ] '=' EXPR
```

### 30.4 Statements

**Variable binding** (§2):

```
LET_STMT    := 'let' PATTERN [ ':' TYPE ] '=' EXPR [ LET_ELSE ]
VAR_STMT    := 'var' PATTERN [ ':' TYPE ] '=' EXPR [ LET_ELSE ]
LET_ELSE    := 'else' ( BODY | EXPR )   // EXPR on the same line; the branch must diverge (§9.7)
```

**Control flow** (§9, §13.5a, §13.5b, §13.5c):

```
STMT        := LABEL_STMT | LET_STMT | VAR_STMT | IF_STMT | MATCH_STMT
              | FOR_STMT | WHILE_STMT | DO_WHILE_STMT | WITH_STMT
              | RETURN_STMT | BREAK_STMT | CONTINUE_STMT | GOTO_STMT
              | DEFER_STMT | EXPR
LABEL_STMT  := LABEL ( STMT | COLON_BODY | BRACE_BODY )
IF_STMT     := 'if' EXPR BODY { 'else' 'if' EXPR BODY } [ 'else' BODY ]
              | 'if' 'let' PATTERN '=' EXPR BODY [ 'else' BODY ]
MATCH_STMT  := 'match' EXPR BODY_ARMS
MATCH_ARM   := PATTERN [ 'if' EXPR ] '=>' EXPR
FOR_STMT    := 'for' PATTERN 'in' EXPR BODY
WHILE_STMT  := 'while' EXPR BODY
DO_WHILE_STMT := 'do' BODY 'while' EXPR
WITH_STMT   := 'with' EXPR 'as' [ 'mut' ] IDENT BODY
RETURN_STMT := 'return' [ EXPR ]
BREAK_STMT  := 'break' [ LABEL ] [ EXPR ]   // EXPR only when targeting a loop (§13.5d)
LOOP_EXPR   := 'loop' BODY
CONTINUE_STMT := 'continue' [ LABEL ]
GOTO_STMT   := 'goto' LABEL
DEFER_STMT  := 'defer' BODY
ERRDEFER_STMT := 'errdefer' BODY
```

### 30.5 Expressions

**Operator precedence** (§9.9) — low to high:

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 1 | `or` | Left |
| 2 | `and` | Left |
| 3 | `==`, `!=`, `in`, `not in`, `=~`, `!~` | Non-associative |
| 4 | `<`, `>`, `<=`, `>=` | Chained |
| 5 | `??` (default) | Right |
| 6 | `\|>` (pipeline) | Left |
| 7 | `\|` | Left |
| 8 | `^` | Left |
| 9 | `&` | Left |
| 10 | `<<`, `>>` | Left |
| 11 | `+`, `-`, `++` | Left |
| 12 | `*`, `/`, `%`, `@` | Left |
| 13 | Unary prefix (`not`, `-`, `~`, `&`, `&raw mut`) | — |
| 14 | Postfix (`.await`, `?`, `.field`, `[i]`, `()`) | Left |

**Comprehensions** (§13.6):

```
COMPREHENSION := '[' EXPR { 'for' PATTERN 'in' EXPR } [ 'if' EXPR ] ']'
              | '[' EXPR ':' EXPR { 'for' PATTERN 'in' EXPR } [ 'if' EXPR ] ']'
MAP_LIT       := '[' EXPR ':' EXPR { ',' EXPR ':' EXPR } [ ',' ] ']'
              | '[' ':' ']'
```

### 30.6 Patterns

**Pattern syntax** (§9.7):

```
PATTERN     := LITERAL_PAT | IDENT_PAT | TUPLE_PAT | STRUCT_PAT
              | ENUM_PAT | SLICE_PAT | RANGE_PAT | OR_PAT
              | BIND_PAT | TYPED_BIND_PAT | WILDCARD | IN_PAT | REST_PAT
LITERAL_PAT := INT_LIT | STR_LIT | CHAR_LIT | 'true' | 'false'
IDENT_PAT   := IDENT
TUPLE_PAT   := '(' PATTERN { ',' PATTERN } ')'
STRUCT_PAT  := [ TYPE ] '{' FIELD_PAT { ',' FIELD_PAT } [ ',' '..' ] '}'
ENUM_PAT    := [ '.' ] IDENT [ '(' PATTERN { ',' PATTERN } ')' ]
SLICE_PAT   := '[' [ PATTERN { ',' PATTERN } [ '..' [ IDENT ] ] ] ']'
RANGE_PAT   := PATTERN '..' PATTERN | PATTERN '..=' PATTERN
OR_PAT      := PATTERN { '|' PATTERN }
BIND_PAT    := IDENT '@' PATTERN
TYPED_BIND_PAT := IDENT ':' TYPE
IN_PAT      := 'in' '[' EXPR { ',' EXPR } ']'
WILDCARD    := '_'
REST_PAT    := '..'
```

### 30.7 Format Specification

**Format spec grammar** (§15.4.1):

```
FMT_SPEC    := [ [ FILL ] ALIGN ] [ SIGN ] [ '#' ] [ '0' ] [ WIDTH ] [ '.' PRECISION ] [ MODE ]
FILL        := <any single byte except '{' '}'>
ALIGN       := '<' | '>' | '^'
SIGN        := '+' | '-'
WIDTH       := DIGIT { DIGIT }
PRECISION   := DIGIT { DIGIT }
MODE        := 'd' | 'x' | 'X' | 'b' | 'o' | 'f' | 'e' | 'g' | 's' | '?'
```

### 30.8 Block Syntax

**Body forms** (§29.13):

```
BODY          := COLON_INLINE | COLON_INDENTED | BRACE_BODY
COLON_INLINE  := ':' BLOCK_ITEM NEWLINE      // single item, same line
COLON_INDENTED := ':' NEWLINE INDENT STMT { NEWLINE STMT } DEDENT
BRACE_BODY    := '{' [ STMT { ( NEWLINE | ';' ) STMT } ] '}'
```

All three forms are interchangeable for every block-introducing
construct: `fn`, `if`, `else if`, `else`, `while`, `for`, `loop`, `with`,
`defer`, `errdefer`, `comptime`, `unsafe`, labeled blocks, and match arms.
`then EXPR` is not a body form. Missing body introducers are parse errors.

### 30.9 Reserved Keywords

The reserved keyword list is normative in §29.11. This appendix does
not maintain a separate copy.

---

*The With Programming Language — End of specification.*
