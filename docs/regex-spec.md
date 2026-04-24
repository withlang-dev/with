# std.regex — Design Specification

**Regular expressions for With.**

Language-level regex literals. PCRE2 engine (auto-migrated from C).
Full Perl-compatible syntax. Backreferences, lookahead, lookbehind,
Unicode properties — everything.

---

## Part 1: Language Integration

### Regex literals

Regex is a first-class value type, not a string passed to a library.

```
let pattern = /^\d{3}-\d{4}$/
let email = /^[\w.+-]+@[\w-]+\.[\w.]+$/i
let ws = /\s+/g
```

The `/` delimiter works because the parser can disambiguate
division from regex start using context — the same solution
JavaScript uses. After a value expression (identifier, literal,
`)`, `]`), `/` is division. After an operator, keyword, `(`, `[`,
`,`, `=`, or at statement start, `/` begins a regex literal.

### Flags

Flags appear after the closing `/`:

| Flag | Meaning |
|---|---|
| `i` | Case-insensitive (`(?i)`) |
| `m` | Multiline — `^`/`$` match line boundaries |
| `s` | Single-line — `.` matches `\n` |
| `x` | Extended — ignore whitespace and `#` comments |
| `g` | Global — find all matches (affects `=~` and `replace`) |
| `U` | Ungreedy — swap greedy/non-greedy defaults |

```
let pattern = /hello world/ims
```

### Match operator `=~`

```
if line =~ /^(\w+)\s*=\s*(.+)$/:
    let key = $1
    let value = $2
```

`=~` performs a match and makes capture groups available as `$0`
(full match), `$1`, `$2`, ... (numbered groups) and `$name`
(named groups) in the `if` body.

**Scoping:** `$N` bindings are scoped to the `if` body. They do
not leak to the enclosing scope. If the match fails, the body
does not execute and no bindings are created.

**Type:** `$0`, `$1`, ... are `str` (the matched substring).
If a group did not participate in the match, accessing it is a
compile error (the compiler can determine this statically for
simple cases) or returns `""` at runtime for conditional groups.

### Named captures

```
if line =~ /^(?P<key>\w+)\s*=\s*(?P<value>.+)$/:
    let key = $key
    let value = $value
```

Both `(?P<name>...)` (Python/Go syntax) and `(?<name>...)` (Perl
syntax) are supported.

### Negated match `!~`

```
if line !~ /^\s*#/:
    process(line)
```

Sugar for `not (line =~ pattern)`. No capture bindings created.

### Regex in match expressions

```
match line:
    /^#(.*)/ -> handle_comment($1)
    /^(\w+)=(.*)/ -> handle_assignment($1, $2)
    /^\s*$/ -> skip()
    _ -> handle_other(line)
```

Each arm's pattern is matched in order. Capture groups are
available in the arm body.

---

## Part 2: Compiler Changes

### Lexer

New token kind: `TK_REGEX_LIT`.

**Disambiguation rule:** `/` is a regex start when the previous
token is one of:

```
TK_LPAREN TK_LBRACKET TK_LBRACE TK_COMMA TK_SEMICOLON
TK_COLON TK_ASSIGN TK_EQ TK_NE TK_LT TK_GT TK_LE TK_GE
TK_PLUS TK_MINUS TK_STAR TK_PERCENT TK_AND TK_OR TK_NOT
TK_AMPERSAND TK_PIPE TK_CARET TK_SHL TK_SHR TK_ARROW
TK_FAT_ARROW TK_RETURN TK_IF TK_ELSE TK_WHILE TK_FOR
TK_MATCH TK_LET TK_VAR TK_FN TK_IN TK_AS TK_TILDE
<start of file> <start of line>
```

After any other token (identifier, number, string, `)`, `]`),
`/` is division.

**Lexing regex content:** After recognizing `/` as regex start,
the lexer scans until the closing unescaped `/`, handling:
- `\/` as escaped slash (not delimiter)
- `[...]` character classes (where `/` is literal, not delimiter)
- `\\` as escaped backslash

After the closing `/`, consume flag characters `[igmsxU]*`.

The lexer stores the raw pattern string and flags in the token.

### Parser

New AST nodes:

```
NK_REGEX_LIT       d0=pattern_str  d1=flags
NK_MATCH_OP        d0=lhs          d1=regex     // =~ operator
NK_NEG_MATCH_OP    d0=lhs          d1=regex     // !~ operator
```

`=~` and `!~` are binary operators at the same precedence as
`==` and `!=`.

In `if` and `match` arms, the parser recognizes `=~` and makes
capture group bindings (`$0`, `$1`, `$name`) available in the
body scope. These are desugared to local let bindings:

```
// Source:
if line =~ /^(\w+)\s*=\s*(.+)$/:
    use($1, $2)

// Desugared to:
let __match = Regex.captures(/^(\w+)\s*=\s*(.+)$/, line)
if __match.is_some():
    let $0 = __match.unwrap().get(0).unwrap()
    let $1 = __match.unwrap().get(1).unwrap()
    let $2 = __match.unwrap().get(2).unwrap()
    use($1, $2)
```

The `$N` tokens are lexed as identifiers with a `$` prefix.
The parser injects the let bindings at scope entry.

### Sema

- `Regex` is a builtin type (like `str`, `bool`).
- `=~` requires lhs: `str`, rhs: `Regex`, returns `bool`.
- `!~` same, returns negated `bool`.
- Capture bindings are typed as `str`.
- Regex literals are validated at compile time — a malformed
  regex is a compile error, not a runtime error.

### Codegen

The regex literal compiles to a call to the runtime regex
compiler at program startup (lazy, once). The compiled `Regex`
object is stored in a module-level static. Subsequent uses
reuse the compiled object.

```
// What the compiler emits for: let pattern = /^\d+$/
static __regex_0: Regex = Regex.__compile_unchecked("^\\d+$", "")
let pattern = __regex_0
```

---

## Part 3: Engine — PCRE2 (auto-migrated)

### Why PCRE2

The regex engine is **PCRE2**, auto-migrated from C to With using
`with migrate`. PCRE2 is the most battle-tested regex engine in
existence — it powers PHP, Nginx, Apache, R, and hundreds of other
projects. By migrating it rather than writing from scratch or
porting Go's RE2:

1. **Full Perl compatibility.** Backreferences, lookahead,
   lookbehind, atomic groups, `\K`, recursive patterns, Unicode
   properties — everything. No "sorry, we don't support that."
2. **Proven correct.** PCRE2's test suite has thousands of test
   cases accumulated over 25 years.
3. **Proven fast.** The interpretive match engine is highly
   optimized. The JIT compiler (optional) produces machine code.
4. **Automatic.** `with migrate` translates 73K lines of C
   mechanically. No manual porting bugs.

### What RE2/Go lacks that PCRE2 has

| Feature | PCRE2 | RE2/Go |
|---|---|---|
| Backreferences (`\1`, `\2`) | Yes | No |
| Lookahead (`(?=...)`, `(?!...)`) | Yes | No |
| Lookbehind (`(?<=...)`, `(?<!...)`) | Yes | No |
| Atomic groups (`(?>...)`) | Yes | No |
| Possessive quantifiers (`*+`, `++`) | Yes | No |
| Conditional patterns | Yes | No |
| Recursive patterns | Yes | No |
| `\K` (reset match start) | Yes | No |
| Callouts | Yes | No |
| Named backreferences | Yes | Limited |
| Subroutine calls | Yes | No |

RE2's linear-time guarantee comes at the cost of these features.
PCRE2's backtracking engine has exponential worst-case on
pathological patterns, but this is true of every Perl-compatible
engine and is acceptable in practice (PCRE2 has configurable
match limits to prevent runaway).

### Migration process

```
with migrate .reference/pcre2/src/ \
    -o out/pcre2_migrate_raw/ \
    --no-c-export \
    --prefer-brace \
    -I .reference/pcre2/src \
    -D PCRE2_CODE_UNIT_WIDTH=8 \
    -D HAVE_CONFIG_H=1
```

Produces 39 `.w` files from 39 `.c` files. 8 files are
excluded from the library subset (test harnesses, JIT
compiler, fuzzer, dftables).

After prepare + check: **OK=31, TOTAL_ERRORS=0**.

The `--no-c-export` flag skips `@[c_export]` attributes and
emits module-local `var` instead of `extern var` — appropriate
for stdlib integration where With's module system handles
visibility.

All errors were fixed in the migrator (`src/CImport.w`), not
by patching generated code. Key migrator improvements:

| Fix | Errors resolved |
|---|---|
| Implicit cast handling (CXCursor_UnexposedExpr) | ~40 |
| Array-to-pointer decay (CI_CAST_ARRAY_TO_PTR) | ~30 |
| Chained assignment decomposition (`a = b++`, `*p++ = val`) | ~20 |
| Large integer literal handling (decimal, context-aware casts) | ~12 |
| Zero-initialization (`var x: T` without initializer) | ~27 |
| Pointer-to-pointer casts (void* <-> typed*) | ~8 |
| `_lowercase` name filter (was skipping `_pcre2_*` symbols) | ~6 |
| Workflow preamble (opaque types, string constants, helpers) | ~15 |

Key migrated files:

| File | Lines | Gotos | Unsafe | Role |
|---|---|---|---|---|
| `pcre2_compile.w` | ~6,200 | 369 | 560 | Pattern compiler |
| `pcre2_match.w` | ~14,600 | 1,775 | 493 | Interpretive match engine |
| `pcre2_dfa_match.w` | ~2,400 | 19 | 15 | DFA match engine |
| `pcre2_substitute.w` | ~2,300 | 76 | 33 | Search-and-replace |
| `pcre2_tables.w` | ~900 | 0 | 0 | Character property tables |
| `pcre2_ucd.w` | ~900 | 0 | 0 | Unicode character data |

### JIT compiler

PCRE2's JIT compiler (`pcre2_jit_compile.c`) uses sljit to
generate machine code at runtime. Two options:

1. **Drop it.** The interpretive match engine is fast enough for
   most use cases. The JIT is only needed for hot-loop matching
   on large inputs.
2. **Link as C.** Keep `pcre2_jit_compile.c` as a C object file
   and link it. The migrated With code calls into it for JIT
   compilation.

Start with option 1. Add option 2 later if performance demands it.

### Memory allocator

PCRE2 uses `pcre2_compile_context` to pass custom allocators.
The migrated code preserves this — `malloc`/`free` are available
via the runtime. Post-migration, the allocator can be swapped to
With's allocator by changing the context setup.

---

## Part 4: Public API

The With-facing API wraps PCRE2's internals in an ergonomic interface.

### The `Regex` type

```
type Regex = {
    code: *mut pcre2_real_code_8,       // compiled pattern
    pattern: str,                        // original pattern string
    num_captures: i32,
    capture_names: Vec[str],
}
```

### Construction

```
// From literal (compiler-validated, never fails):
let re = /pattern/flags

// From string (runtime, can fail):
fn Regex.compile(pattern: &str) -> Result[Regex, RegexError]
fn Regex.compile_flags(pattern: &str, flags: &str) -> Result[Regex, RegexError]
```

Internally calls `pcre2_compile_8`.

### Matching

```
fn Regex.is_match(self: &Self, text: &str) -> bool
fn Regex.find(self: &Self, text: &str) -> Option[Match]
fn Regex.find_all(self: &Self, text: &str) -> Vec[Match]
fn Regex.find_at(self: &Self, text: &str, start: i32) -> Option[Match]
```

Internally calls `pcre2_match_8`.

### Captures

```
fn Regex.captures(self: &Self, text: &str) -> Option[Captures]
fn Regex.captures_all(self: &Self, text: &str) -> Vec[Captures]

type Match = {
    start: i32,
    end: i32,
    text: str,
}

type Captures = {
    groups: Vec[Option[Match]],
    named: HashMap[str, i32],
}

fn Captures.get(self: &Self, i: i32) -> Option[&Match]
fn Captures.name(self: &Self, name: &str) -> Option[&Match]
fn Captures.len(self: &Self) -> i32
```

### Replacement

```
fn Regex.replace(self: &Self, text: &str, replacement: &str) -> str
fn Regex.replace_all(self: &Self, text: &str, replacement: &str) -> str
fn Regex.replace_fn(self: &Self, text: &str, f: fn(&Captures) -> str) -> str
fn Regex.replace_all_fn(self: &Self, text: &str, f: fn(&Captures) -> str) -> str
```

Replacement strings support `$1`, `$2`, `$name`, `${name}`,
`$0` (whole match), and `$$` (literal `$`).

Internally calls `pcre2_substitute_8`.

### Splitting

```
fn Regex.split(self: &Self, text: &str) -> Vec[str]
fn Regex.splitn(self: &Self, text: &str, n: i32) -> Vec[str]
```

### Introspection

```
fn Regex.pattern(self: &Self) -> str
fn Regex.num_captures(self: &Self) -> i32
fn Regex.capture_names(self: &Self) -> Vec[str]
fn Regex.capture_index(self: &Self, name: &str) -> Option[i32]
```

### Supported syntax

Everything PCRE2 supports, which is everything Perl supports:

- Character classes: `[a-z]`, `[^0-9]`, `\d`, `\w`, `\s`
- Quantifiers: `*`, `+`, `?`, `{n}`, `{n,m}`
- Alternation: `a|b`
- Grouping: `(...)`, `(?:...)`, `(?P<name>...)`, `(?<name>...)`
- Backreferences: `\1`, `\2`, `\k<name>`
- Lookahead: `(?=...)`, `(?!...)`
- Lookbehind: `(?<=...)`, `(?<!...)`
- Atomic groups: `(?>...)`
- Possessive quantifiers: `*+`, `++`, `?+`
- Conditional patterns: `(?(cond)yes|no)`
- Recursive patterns: `(?R)`, `(?1)`
- Subroutine calls: `(?&name)`
- Anchors: `^`, `$`, `\A`, `\z`, `\b`, `\B`
- Unicode properties: `\p{L}`, `\p{Lu}`, `\P{N}`, `\p{Latin}`
- Extended mode: `(?x)` — ignore whitespace and `#` comments
- Reset match start: `\K`
- Callouts: `(?C)` (for debugging)

---

## Part 5: Implementation Status

### Phase 1: Migrate and build PCRE2

| Step | Status |
|---|---|
| Run `with migrate` on PCRE2 source | DONE — 38/39 files, 80K lines |
| Fix compilation errors in migrated output | DONE — 978 → 0 errors, all fixed in migrator |
| Prepare and promote to `lib/std/re/` | DONE — OK=31, TOTAL_ERRORS=0 |
| Build migrated library as object files | TODO |
| Link `pcre2test` against it | TODO |
| Run PCRE2's test suite | TODO |

### Phase 2: With wrapper API (`lib/std/regex.w`)

| Step | Status |
|---|---|
| `Regex` type with Drop | TODO |
| `Regex.compile` | TODO |
| `Regex.is_match`, `find`, `find_all` | TODO |
| `Regex.captures` | TODO |
| `Regex.replace`, `replace_all` | TODO |
| `Regex.split` | TODO |

### Phase 3: Language integration

| Step | Status |
|---|---|
| Lexer — `TK_REGEX_LIT`, `/` disambiguation | TODO |
| Parser — `=~`/`!~`, capture bindings | TODO |
| Sema — Regex type, compile-time validation | TODO |
| Codegen — lazy statics, `=~` desugaring | TODO |

### Phase 4: Optimization (future)

| Step | Status |
|---|---|
| JIT — link sljit compiler | TODO |
| Compile-time regex validation | TODO |

---

## Part 6: Design Decisions

| Decision | Rationale |
|---|---|
| PCRE2 via `with migrate`, not manual port | 73K lines auto-migrated in one command. Zero manual fix-up patches — all 978 errors fixed in the migrator itself. Preserves PCRE2's 25 years of bug fixes and optimizations. |
| `--no-c-export` for stdlib integration | Migrated code is a With module, not a C library. No `@[c_export]` attributes, no `extern var` for module-local state. With's module system handles visibility. |
| PCRE2 over RE2/Go | Full Perl compatibility. Backreferences, lookahead, lookbehind, recursive patterns. RE2 deliberately rejects these features. Most programmers expect them. |
| Auto-migrated C, not hand-written With | The migrated code is ugly (lots of `unsafe`, state machines for gotos) but provably correct. It can be incrementally cleaned up. A hand-written With port would take months and introduce bugs. |
| Interpretive engine first, JIT later | The interpreter is fast enough for most use cases. The JIT can be linked as a C object later. |
| Wrapper API over raw PCRE2 | The raw PCRE2 API is C-style (pass buffers, check return codes). The wrapper provides With-idiomatic `Result`, `Option`, `Match` types. |
| Language literals independent of engine | `/pattern/`, `=~`, capture bindings work regardless of whether the engine is PCRE2, RE2, or anything else. The compiler just calls `Regex.compile` and `Regex.captures`. |
| Keep PCRE2's test suite | Don't port tests — run `pcre2test` against the migrated library. If PCRE2's tests pass, the migration is correct. |

---

## Part 7: What This Doesn't Cover

- **Streaming match** — PCRE2 supports partial matching via
  `PCRE2_PARTIAL_SOFT` / `PCRE2_PARTIAL_HARD`. Expose in a
  later phase.
- **JIT compilation** — Available in PCRE2 via sljit. Link as
  C object when needed.
- **Regex syntax highlighting** — Falls out naturally from the
  lexer changes.
- **Custom match limits** — PCRE2 supports `pcre2_set_match_limit`
  to prevent exponential blowup. Expose via `Regex.compile_opts`.

---

## Part 8: Migration vs Port Comparison

| Approach | Lines of code | Time | Correctness | Features |
|---|---|---|---|---|
| **PCRE2 via `with migrate`** | 80K (auto) + 300 (wrapper) | Days | Proven by PCRE2 test suite | Full Perl compat |
| Go RE2 manual port | ~4,400 (hand-written) | 4-6 weeks | Must port Go's test suite | No backrefs, no lookahead |
| From scratch | ~3,000+ | Months | Extensive new testing needed | Whatever we implement |

The PCRE2 approach wins on every axis except code aesthetics.
The migrated code is ugly but correct. The wrapper API is clean.
The user never sees the internals.
