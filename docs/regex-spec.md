# std.regex — Design Specification

**Regular expressions for With.**

Language-level regex literals. Go's RE2 engine architecture. Perl
syntax. Linear-time guarantees.

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

Two strategies, chosen per regex:

**Strategy A: Runtime compilation (default)**

The regex literal compiles to a call to the runtime regex
compiler at program startup (lazy, once). The compiled `Regex`
object is stored in a module-level static. Subsequent uses
reuse the compiled object.

```
// What the compiler emits for: let pattern = /^\d+$/
static __regex_0: Regex = Regex.__compile_unchecked("^\\d+$", "")
let pattern = __regex_0
```

This is Go's approach. Compilation happens once, matching is fast.

**Strategy B: Compile-time compilation (optimization, future)**

For regex literals known at compile time (all of them, by
definition), the compiler can run the regex compiler at compile
time and embed the compiled instruction program directly in the
binary. This eliminates first-use compilation overhead.

This is Rust's `regex!` macro approach. It requires the regex
compiler to be available as a comptime function. Defer this to
a later phase — runtime compilation is correct and fast enough.

---

## Part 3: Engine Architecture

Port of Go's `regexp` package. Same architecture, same design
decisions, same performance characteristics.

### Data flow

```
Pattern string
    ↓ parse()
Regexp AST
    ↓ simplify()
Simplified AST
    ↓ compile()
Prog (instruction array)
    ↓ analyze()
    ├─ try one-pass DFA compilation
    ├─ check if backtracking viable
    └─ extract literal prefix
    ↓ execute (strategy selection)
    ├─ One-pass DFA      → O(n), O(1) space
    ├─ Backtracking       → O(n×m) with memoization
    └─ NFA simulation     → O(n×m) guaranteed
    ↓
Match result + capture positions
```

### 3.1 Parsing

Recursive descent parser. Converts pattern string to AST.

**AST node type:**

```
type RegexpNode = {
    op: RegexpOp,
    flags: RegexpFlags,
    sub: Vec[RegexpNode],
    runes: Vec[i32],        // literal runes or char class ranges (lo,hi pairs)
    min: i32,               // min repetition (for OpRepeat)
    max: i32,               // max repetition (-1 = unbounded)
    cap: i32,               // capture group index
    name: str,              // capture group name
}
```

**RegexpOp enum:**

```
type RegexpOp =
    | NoMatch               // matches nothing
    | EmptyMatch            // matches empty string
    | Literal               // matches runes sequence
    | CharClass             // matches runes as range pairs
    | AnyCharNotNL          // . (without s flag)
    | AnyChar               // . (with s flag)
    | BeginLine             // ^
    | EndLine               // $
    | BeginText             // \A
    | EndText               // \z
    | WordBoundary          // \b
    | NoWordBoundary        // \B
    | Capture               // (...) with cap index
    | Star                  // *
    | Plus                  // +
    | Quest                 // ?
    | Repeat                // {n,m}
    | Concat                // sequence
    | Alternate             // |
```

**RegexpFlags:**

```
@[flags]
type RegexpFlags =
    | FoldCase              // (?i)
    | LiteralMode           // treat as literal
    | ClassNL               // char classes match \n
    | DotNL                 // . matches \n
    | OneLine               // ^ $ only at text boundaries
    | NonGreedy             // (?U) swap greedy/non-greedy
    | PerlX                 // Perl extensions
    | UnicodeGroups         // \p{} \P{}
    | WasDollar             // $ vs \z tracking
```

**Supported syntax** (following Go exactly):

Perl character classes:
- `\d` `\D` `\s` `\S` `\w` `\W`

POSIX classes (inside `[...]`):
- `[:alnum:]` `[:alpha:]` `[:ascii:]` `[:blank:]` `[:cntrl:]`
  `[:digit:]` `[:graph:]` `[:lower:]` `[:print:]` `[:punct:]`
  `[:space:]` `[:upper:]` `[:word:]` `[:xdigit:]`

Unicode classes:
- `\p{Latin}` `\p{Greek}` `\p{L}` `\p{Lu}` `\P{N}` etc.
- Single-letter shorthand: `\pL` `\pN`
- All Unicode general categories, scripts, and aliases

Quantifiers:
- `*` `+` `?` `{n}` `{n,}` `{n,m}`
- Non-greedy: `*?` `+?` `??` `{n,m}?`
- Max repetition count: 1000

Grouping:
- `(re)` — capturing group
- `(?:re)` — non-capturing group
- `(?P<name>re)` — named capture (Python/Go syntax)
- `(?<name>re)` — named capture (Perl syntax)
- `(?flags)` — set flags
- `(?flags:re)` — set flags for group

Anchors:
- `^` `$` `\A` `\z` `\b` `\B`

Escapes:
- `\a` `\f` `\n` `\r` `\t` `\v`
- `\xHH` `\x{HHHH}` — hex
- `\0` through `\777` — octal
- `\Q...\E` — literal span
- `\.` `\\` etc. — escaped metacharacters

**Not supported** (following Go's RE2 decisions):
- Backreferences (`\1`, `\2`) — require exponential time
- Lookahead/lookbehind (`(?=)` `(?!)` `(?<=)` `(?<!)`) — require
  exponential time or engine complexity incompatible with
  linear-time guarantees
- Atomic groups (`(?>...)`)
- Conditional patterns
- Possessive quantifiers (`*+` `++`)

These features break the linear-time guarantee. A regex engine
that supports them must use backtracking, which has O(2^n)
worst-case behavior. Go rejected them for this reason. We follow.

### 3.2 Simplification

Transforms the AST to eliminate counted repetitions before
compilation.

```
fn simplify(re: &mut RegexpNode)
```

Transformations:
- `x{0}` → EmptyMatch
- `x{n}` → Concat(x, x, ..., x) — n copies
- `x{n,}` → Concat(x, x, ..., Plus(x)) — (n-1) copies + Plus
- `x{n,m}` → Concat(x, ..., Quest(x, Quest(x, ...))) — n required + (m-n) optional
- `(x*)*` → `x*` — idempotent collapse
- `(x+)*` → `x*`
- CharClass covering all runes → AnyChar

After simplification, the AST contains no `OpRepeat` nodes.

### 3.3 Compilation

Compiles simplified AST to an instruction program.

**Instruction set:**

```
type InstOp =
    | Alt                   // branch: Out = first, Arg = second
    | AltMatch              // branch preferring match
    | Capture               // record capture: Arg = group*2 (start) or group*2+1 (end)
    | EmptyWidth            // zero-width assertion: Arg = EmptyOp flags
    | Match                 // success
    | Fail                  // dead end
    | Nop                   // passthrough
    | Rune                  // match rune from rune set
    | Rune1                 // optimized: single rune
    | RuneAny               // optimized: any rune
    | RuneAnyNotNL          // optimized: any rune except \n

type Inst = {
    op: InstOp,
    out: u32,               // next instruction
    arg: u32,               // alt target, capture index, or empty-width flags
    runes: Vec[i32],        // character data (pairs for Rune, single for Rune1)
    fold_case: bool,        // case-insensitive matching for this inst
}

type Prog = {
    inst: Vec[Inst],
    start: i32,
    num_cap: i32,
}
```

**Compilation strategy:** Fragment-based, following Go exactly.

Each sub-expression compiles to a fragment:
```
type Frag = {
    i: u32,                 // index of first instruction
    out: PatchList,         // unfilled jump targets
    nullable: bool,         // can match empty string
}
```

Fragments are combined with `cat` (sequence), `alt` (choice),
`star`/`plus`/`quest` (quantifiers). The PatchList is a linked
list threaded through unused instruction fields, filled in when
the target is known.

**Compilation by op:**

| Op | Compilation |
|---|---|
| Literal | Chain of Rune1 instructions |
| CharClass | Single Rune instruction with range pairs |
| AnyChar | RuneAny |
| AnyCharNotNL | RuneAnyNotNL |
| BeginLine | EmptyWidth(EmptyBeginLine) |
| EndLine | EmptyWidth(EmptyEndLine) |
| BeginText | EmptyWidth(EmptyBeginText) |
| EndText | EmptyWidth(EmptyEndText) |
| WordBoundary | EmptyWidth(EmptyWordBoundary) |
| NoWordBoundary | EmptyWidth(EmptyNoWordBoundary) |
| Capture | Capture(cap*2) + compile(sub) + Capture(cap*2+1) |
| Star | Loop via Alt back to body |
| Plus | Body + loop via Alt |
| Quest | Alt between body and skip |
| Concat | cat(compile(sub[0]), compile(sub[1]), ...) |
| Alternate | alt(compile(sub[0]), compile(sub[1]), ...) |

Non-greedy quantifiers swap the Alt branch order (prefer skip
over repeat).

**Optimizations at compile time:**

1. Literal prefix extraction — scan compiled program for leading
   sequence of Rune1 instructions. Used to fast-skip input with
   string search before starting NFA simulation.

2. Anchor detection — determine if program is anchored at start
   (`^` or `\A`). Anchored programs only need to match at
   position 0.

3. One-pass eligibility — check if program is deterministic
   (see §3.4).

### 3.4 Execution strategies

Three strategies, selected per-match based on program properties
and input size. Same selection logic as Go.

#### Strategy 1: One-pass DFA

**Conditions:**
- Program is anchored
- No ambiguous alternations (at every Alt, the two branches
  accept disjoint rune sets for the next input)
- Program size < 1000 instructions

**Mechanism:**
Build a dispatch table mapping (instruction, rune) → next
instruction. Single linear scan through input. O(n) time,
O(1) space.

**When it applies:** Simple patterns like `/^\d{3}-\d{4}$/`,
`/^[a-z]+$/`, `/^(\w+)\s+(\w+)$/`. These are extremely common
in practice.

#### Strategy 2: Backtracking with memoization

**Conditions:**
- Program size ≤ 500 instructions
- Input size × program size ≤ 256KB (for the visited bit vector)
- Program is not one-pass eligible

**Mechanism:**
DFS through (instruction, input position) space. A bit vector
tracks visited states to prevent re-exploration. Job stack for
backtracking. Captures saved/restored on backtrack.

**Performance:** O(n × m) worst case, but with the bit vector
preventing duplicate work. In practice, faster than NFA for
small programs with captures because it finds the first match
without exploring all paths.

#### Strategy 3: NFA simulation

**Used when:** Program is too large for one-pass or backtracking,
or input is unbounded (streaming).

**Mechanism:**
Thompson NFA simulation. Two thread queues (current step and
next step). Each thread is (instruction pointer, capture array).
Process all active threads in lockstep on each input rune.

Key data structures:

```
type Thread = {
    pc: u32,                // instruction pointer
    cap: Vec[i32],          // capture positions (-1 = unset)
}

type Queue = {
    sparse: Vec[u32],       // sparse set for O(1) membership
    dense: Vec[Thread],     // actual threads in order
}

type Machine = {
    prog: &Prog,
    q0: Queue,              // current step
    q1: Queue,              // next step
    matched: bool,
    match_cap: Vec[i32],    // best match captures so far
}
```

**Execution loop:**

```
fn execute(m: &mut Machine, input: &str, pos: i32) -> bool:
    add(m.q0, m.prog.start, pos, cap_init)

    for (i, rune) in input.codepoints_from(pos):
        step(m, i, rune)
        swap(m.q0, m.q1)
        clear(m.q1)

        if m.q0.is_empty():
            break

    return m.matched
```

`add` handles epsilon closure — follows Nop, Alt, Capture, and
EmptyWidth instructions without consuming input. Only Rune*
instructions consume input and move to the next step.

`step` iterates all threads in q0. For each thread at a Rune*
instruction, if the rune matches, add the thread's successor
to q1.

**Thread priority:** Threads are ordered by insertion. Earlier
threads (from earlier alternation branches) have priority.
When a thread reaches Match, it's recorded as the best match.
Later threads that reach Match are ignored if the earlier match
is already found (leftmost-first semantics).

**Performance:** O(n × m) time, O(m) space. Guaranteed. No
exponential blowup regardless of pattern or input.

### 3.5 Literal prefix optimization

Before starting the NFA, check if the pattern has a literal
prefix. If so, use a fast string search (Boyer-Moore or
`string.find`) to skip ahead in the input.

```
// Pattern: /hello\s+world/
// Literal prefix: "hello"
// Strategy: find "hello" first, then run NFA from that position

fn find_literal_prefix(prog: &Prog) -> Option[str]:
    var prefix = ""
    var pc = prog.start
    loop:
        let inst = prog.inst[pc]
        match inst.op:
            Rune1 if not inst.fold_case ->
                prefix.push(inst.runes[0])
                pc = inst.out
            _ -> break
    if prefix.len() > 0: Some(prefix) else None
```

This turns `grep`-style usage (searching for a pattern in a
large file) from O(n × m) to O(n) in practice, since the
string search finds candidates and the NFA only runs at each
candidate position.

---

## Part 4: Public API

### The `Regex` type

```
type Regex = {
    prog: Prog,
    prefix: Option[str],
    prefix_end: i32,
    one_pass: Option[OnePassProg],
    num_cap: i32,
    sub_names: Vec[str],
    longest: bool,
    pattern: str,
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

Regex literals are validated at compile time. `Regex.compile` is
for patterns constructed at runtime (e.g., from user input).

### Matching

```
fn Regex.is_match(self: &Self, text: &str) -> bool
fn Regex.find(self: &Self, text: &str) -> Option[Match]
fn Regex.find_all(self: &Self, text: &str) -> Vec[Match]
fn Regex.find_at(self: &Self, text: &str, start: i32) -> Option[Match]
```

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
fn Regex.literal_prefix(self: &Self) -> (str, bool)
fn Regex.longest(self: &mut Self)
```

`longest` switches from leftmost-first to leftmost-longest
matching (POSIX semantics).

---

## Part 5: Unicode

### Character properties

Full Unicode general categories and scripts, following Go's
tables. The tables are generated from Unicode Character Database
at build time.

```
\p{L}       // Letter (any)
\p{Lu}      // Uppercase Letter
\p{Ll}      // Lowercase Letter
\p{N}       // Number (any)
\p{Nd}      // Decimal Digit
\p{P}       // Punctuation
\p{S}       // Symbol
\p{Z}       // Separator
\p{C}       // Other (control, format, etc.)

\p{Latin}   // Latin script
\p{Greek}   // Greek script
\p{Han}     // Han (CJK) script
// ... all Unicode scripts
```

### Case folding

Case-insensitive matching uses Unicode simple case folding
(`SimpleFold`). For each rune in a character class, the fold
orbit (the cycle of case-equivalent runes) is computed and all
equivalents are included.

```
// /hello/i matches "Hello", "HELLO", "hElLo", etc.
// Also handles non-ASCII: /straße/i matches "STRASSE"
```

### Table representation

Unicode tables are stored as sorted range arrays:

```
type RuneRange = {
    lo: i32,
    hi: i32,
    stride: i32,
}
```

Stride > 1 compresses regular patterns (e.g., every-other
codepoint in certain Unicode blocks). Most ranges have stride 1.

Tables are compiled into the binary. Estimated size: ~50KB for
all general categories + common scripts. This is acceptable —
Go's tables are similar size.

---

## Part 6: Implementation Plan

### Phase 1: Core engine (no language integration)

Build the regex engine as a library module `lib/std/regex.w`.
No lexer/parser changes yet — patterns are passed as strings.

```
let re = Regex.compile("^\\d{3}-\\d{4}$").unwrap()
if re.is_match(phone):
    print("valid")
```

**Files:**

| File | Contents | Est. lines |
|---|---|---|
| `lib/std/regex.w` | Public API, Regex type, strategy dispatch | 300 |
| `lib/std/regex/parse.w` | Parser: string → RegexpNode AST | 800 |
| `lib/std/regex/simplify.w` | AST simplification | 150 |
| `lib/std/regex/compile.w` | AST → Prog (instruction program) | 400 |
| `lib/std/regex/exec.w` | NFA simulation | 350 |
| `lib/std/regex/backtrack.w` | Backtracking with memoization | 250 |
| `lib/std/regex/onepass.w` | One-pass DFA compilation + execution | 300 |
| `lib/std/regex/unicode.w` | Unicode tables and category lookup | 200 + tables |

**Subtasks:**

1. **RegexpNode AST + parser** — Port Go's `syntax/parse.go`.
   Start with basic literals, character classes, quantifiers,
   alternation, grouping. Add Perl extensions, Unicode classes,
   flags. Validate against Go's test cases.

2. **Simplification** — Port `syntax/simplify.go`. Small,
   well-defined transformation.

3. **Instruction set + compiler** — Port `syntax/compile.go`.
   Fragment-based compilation. PatchList linking. Instruction
   specialization (Rune1, RuneAny).

4. **NFA execution** — Port `exec.go`. Thread queues, epsilon
   closure, step function. This is the always-correct fallback.

5. **Backtracking** — Port `backtrack.go`. Bit vector visited
   set, job stack, capture save/restore.

6. **One-pass DFA** — Port `onepass.go`. Determinism analysis,
   dispatch table construction.

7. **Literal prefix** — Extract literal prefix from compiled
   program. Use `string.find` for fast skip.

8. **Public API** — `is_match`, `find`, `find_all`, `captures`,
   `replace`, `split`. Match Go's API surface.

9. **Unicode tables** — Generate from UCD. Category lookup,
   script lookup, case folding. Build-time table generation.

10. **Testing** — Port Go's extensive test suite. Go has hundreds
    of regex test cases covering edge cases, Unicode, captures,
    and performance.

### Phase 2: Language integration

Requires compiler changes. Do this after the library is working
and tested.

1. **Lexer** — Add `TK_REGEX_LIT`. Implement `/` disambiguation.
   Handle escapes, character classes (where `/` is not a
   delimiter), and flags.

2. **Parser** — Add `NK_REGEX_LIT`, `NK_MATCH_OP`, `NK_NEG_MATCH_OP`.
   `=~` and `!~` operators. Capture group binding injection in
   `if` and `match` arms.

3. **Sema** — `Regex` as builtin type. Type-check `=~`/`!~`.
   Validate regex literals at compile time (call the parser in
   sema and report errors with source location).

4. **Codegen** — Emit lazy-initialized static for each regex
   literal. Desugar `=~` to `captures` call + Option check.
   Desugar `$N` bindings to `Captures.get(N)`.

### Phase 3: Optimization (future)

1. **Compile-time regex compilation** — Run the regex compiler
   at comptime, embed the Prog directly in the binary. Eliminates
   first-use overhead.

2. **DFA caching** — Cache DFA states across matches for hot
   patterns. Go does this lazily.

3. **SIMD acceleration** — Use SIMD for literal prefix search
   on long inputs.

---

## Part 7: Design Decisions

| Decision | Rationale |
|---|---|
| Port Go's engine, not write from scratch | Go's RE2-derived engine is battle-tested, well-documented, and has excellent test coverage. Writing a regex engine from scratch is a multi-month project with subtle correctness bugs. Porting is faster and more reliable. |
| No backreferences | They require exponential-time matching. Go rejected them. Rust's default engine rejected them. The linear-time guarantee is more valuable than Perl compatibility. |
| No lookahead/lookbehind | Same reason. These features break the Thompson NFA approach. |
| Three execution strategies | One-pass DFA for simple anchored patterns (very common). Backtracking for medium programs (good capture performance). NFA for everything else (guaranteed linear time). This matches Go's approach exactly. |
| Language-level literals | Regex is too common to require string escaping. `/pattern/` is clearer than `"pattern"` with doubled backslashes. Compile-time validation catches errors early. |
| `=~` operator with capture bindings | Pattern matching with regex is a fundamental operation. Making it syntactic (not just a method call) enables the compiler to inject capture bindings naturally. This is standard in Perl, Ruby, and Raku. |
| Regex in match arms | Pattern matching on strings with regex is a natural extension of With's match expression. Each arm gets its own capture scope. |
| Leftmost-first by default | Go's default. Most intuitive for programmers. POSIX leftmost-longest available via `.longest()`. |
| Unicode by default | All regex operations are Unicode-aware. `\w`, `\d`, etc. match ASCII only (Go's choice — predictable performance), but `\p{L}` etc. match full Unicode. Character classes operate on runes, not bytes. |
| Pure With implementation | No PCRE dependency. The engine is ~2500-3000 lines of With. Small enough to audit, fast enough for production, and works on bare metal. |

---

## Part 8: What This Doesn't Cover

- **Streaming match** — Matching against a reader/stream
  (unbounded input). Go supports this via `inputReader`. Add
  in a later phase if needed.
- **Regex syntax highlighting** — IDE/editor support for regex
  literals. This falls out naturally from the lexer changes.
- **Regex optimization passes** — Dead code elimination,
  common subexpression factoring in the compiled program.
  Go doesn't do these and performance is fine.
- **JIT compilation** — Compiling the regex to machine code
  at runtime. Massive complexity for marginal gain. Not planned.
