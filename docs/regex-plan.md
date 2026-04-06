# Regex Engine — Implementation Plan

Port of Go's `regexp` package to pure With. 19 steps, two phases.

**Reference:** `.reference/go/src/regexp/` (~5,500 LOC, 8 production files)
**Spec:** `docs/regex-spec.md`

---

## File Layout

```
lib/std/regex.w                  Public API: Regex, compile, find, replace, split
lib/std/regex/syntax.w           AST: RegexpOp, RegexpNode, RegexpFlags
lib/std/regex/parse.w            Parser: pattern string → RegexpNode
lib/std/regex/simplify.w         AST simplification (eliminate OpRepeat)
lib/std/regex/compile.w          Compiler: AST → Prog (instruction array)
lib/std/regex/prog.w             Instruction types: InstOp, Inst, Prog, EmptyOp
lib/std/regex/exec.w             NFA simulation (Thompson NFA)
lib/std/regex/backtrack.w        Memoized backtracking engine
lib/std/regex/onepass.w          One-pass DFA engine
lib/std/regex/unicode.w          Unicode tables, Perl/POSIX classes, case folding
lib/std/regex/charclass.w        Character class range-pair manipulation
```

---

## Phase 1: Library (Steps 1–15)

No compiler changes. Regex patterns passed as strings:
```
use std.regex
let re = Regex.compile("^\\d{3}-\\d{4}$").unwrap()
if re.is_match(phone):
    print("valid")
```

---

### Step 1: Core Type Definitions

**Ports:** `syntax/regexp.go` lines 17–59, `syntax/prog.go` lines 14–120
**Creates:** `lib/std/regex/syntax.w`, `lib/std/regex/prog.w`
**Depends on:** nothing
**Est:** ~150 LOC

**syntax.w — AST node types:**

```
type RegexpOp: i32
    // 19 ops, mapped 1:1 from Go
    let OP_NO_MATCH: i32 = 1
    let OP_EMPTY_MATCH: i32 = 2
    let OP_LITERAL: i32 = 3
    let OP_CHAR_CLASS: i32 = 4
    let OP_ANY_CHAR_NOT_NL: i32 = 5
    let OP_ANY_CHAR: i32 = 6
    let OP_BEGIN_LINE: i32 = 7
    let OP_END_LINE: i32 = 8
    let OP_BEGIN_TEXT: i32 = 9
    let OP_END_TEXT: i32 = 10
    let OP_WORD_BOUNDARY: i32 = 11
    let OP_NO_WORD_BOUNDARY: i32 = 12
    let OP_CAPTURE: i32 = 13
    let OP_STAR: i32 = 14
    let OP_PLUS: i32 = 15
    let OP_QUEST: i32 = 16
    let OP_REPEAT: i32 = 17
    let OP_CONCAT: i32 = 18
    let OP_ALTERNATE: i32 = 19

    // Pseudo-ops for parse stack (never in final AST)
    let OP_LEFT_PAREN: i32 = 128
    let OP_VERTICAL_BAR: i32 = 129
```

```
type RegexpNode = {
    op: i32,
    flags: i32,          // bitfield: FoldCase=1, ClassNL=4, DotNL=8, ...
    sub: Vec[i32],        // indices into NodePool
    runes: Vec[i32],      // literal runes or char class range pairs [lo,hi,...]
    min: i32,
    max: i32,             // -1 = unbounded
    cap: i32,
    name: str,
}

type NodePool = {
    nodes: Vec[RegexpNode],
}
```

Use arena/pool approach: `sub` stores indices into `NodePool.nodes`,
not child values. Avoids nested `Vec[T]` generic instantiation issues.

**prog.w — instruction types:**

```
    let INST_ALT: i32 = 0
    let INST_ALT_MATCH: i32 = 1
    let INST_CAPTURE: i32 = 2
    let INST_EMPTY_WIDTH: i32 = 3
    let INST_MATCH: i32 = 4
    let INST_FAIL: i32 = 5
    let INST_NOP: i32 = 6
    let INST_RUNE: i32 = 7
    let INST_RUNE1: i32 = 8
    let INST_RUNE_ANY: i32 = 9
    let INST_RUNE_ANY_NOT_NL: i32 = 10

    let EMPTY_BEGIN_LINE: i32 = 1
    let EMPTY_END_LINE: i32 = 2
    let EMPTY_BEGIN_TEXT: i32 = 4
    let EMPTY_END_TEXT: i32 = 8
    let EMPTY_WORD_BOUNDARY: i32 = 16
    let EMPTY_NO_WORD_BOUNDARY: i32 = 32

type Inst = {
    op: i32,
    out: i32,        // next instruction
    arg: i32,        // alt target / capture index / EmptyOp flags
    runes: Vec[i32],
}

type Prog = {
    inst: Vec[Inst],
    start: i32,
    num_cap: i32,
}
```

**Done when:** All types compile. A test instantiates each type and
accesses fields.

**Tests:** `test/behavior/behav_regex_types.w`

---

### Step 2: Character Class Utilities

**Ports:** `syntax/parse.go` lines 1920–2227
**Creates:** `lib/std/regex/charclass.w`
**Depends on:** Step 1
**Est:** ~250 LOC

Functions (all operate on `Vec[i32]` of range pairs `[lo,hi,lo,hi,...]`):

```
fn clean_class(r: &mut Vec[i32])
    // Sort range pairs by lo, merge overlapping/abutting

fn in_char_class(rune: i32, class: &Vec[i32]) -> bool
    // Binary search on sorted range pairs

fn append_range(r: &mut Vec[i32], lo: i32, hi: i32)
    // Append range, coalesce with last if abutting

fn append_literal(r: &mut Vec[i32], x: i32, flags: i32)
fn append_class(r: &mut Vec[i32], x: &Vec[i32])
fn append_negated_class(r: &mut Vec[i32], x: &Vec[i32])
fn negate_class(r: &mut Vec[i32])
fn append_table(r: &mut Vec[i32], table: &Vec[i32])
fn append_negated_table(r: &mut Vec[i32], table: &Vec[i32])
fn append_folded_range(r: &mut Vec[i32], lo: i32, hi: i32)
    // Stub: identity until Step 10 wires SimpleFold
```

Sorting: Implement inline insertion sort for range pairs (small
arrays, typically <50 pairs). Sort by lo ascending, hi descending.

**Done when:** `negate_class([0x61,0x7a])` produces
`[0,0x60, 0x7b,0x10ffff]`. `in_char_class(0x41, &[0x41,0x5a])` is true.

**Tests:** `test/behavior/behav_regex_charclass.w`

---

### Step 3: Perl/POSIX Character Class Tables

**Ports:** `syntax/perl_groups.go` (133 lines)
**Creates:** `lib/std/regex/unicode.w` (first portion)
**Depends on:** Steps 1, 2
**Est:** ~100 LOC

Static data:
- 6 Perl classes: `\d` `\D` `\s` `\S` `\w` `\W` (ASCII ranges)
- 14 POSIX classes: `[:alnum:]` through `[:xdigit:]`

```
fn perl_group(name: str) -> Option[(i32, Vec[i32])]
    // Returns (sign, ranges). sign=+1 for \d, -1 for \D.

fn posix_group(name: str) -> Option[(i32, Vec[i32])]
    // Returns (sign, ranges). Handles "[:^alpha:]" negation.
```

Tables stored as functions returning `Vec[i32]` (avoids static
initializer issues). Each function is a few lines.

**Done when:** `perl_group("\\d")` returns `(1, [0x30,0x39])`.
`posix_group("[:^digit:]")` returns `(-1, [0x30,0x39])`.

**Tests:** `test/behavior/behav_regex_tables.w`

---

### Step 4: Parser — Core

**Ports:** `syntax/parse.go` lines 127–1097
**Creates:** `lib/std/regex/parse.w`
**Depends on:** Steps 1–3
**Est:** ~500 LOC

This is the largest single step. Port the main parse loop handling:
`literals`, `.`, `^`, `$`, `|`, `()`, `*`, `+`, `?`, `{n,m}`,
basic escape `\.` `\\`.

**Key types:**

```
type RegexParser = {
    flags: i32,
    stack: Vec[i32],       // indices into pool
    pool: NodePool,
    num_cap: i32,
    whole: str,
    pos: i32,
}

type RegexError = {
    code: str,
    expr: str,
}
```

**Key functions (in implementation order):**

1. `fn RegexParser.new(flags: i32) -> RegexParser`
2. `fn RegexParser.new_node(self: &mut Self, op: i32) -> i32` — allocate in pool, return index
3. `fn RegexParser.push(self: &mut Self, idx: i32)`
4. `fn RegexParser.literal(self: &mut Self, r: i32)`
5. `fn RegexParser.op(self: &mut Self, op: i32)`
6. `fn RegexParser.maybe_concat(self: &mut Self, r: i32, flags: i32) -> bool`
7. `fn RegexParser.concat(self: &mut Self)` — finalize concat above `|` or `(`
8. `fn RegexParser.alternate(self: &mut Self)` — finalize alternation above `(`
9. `fn RegexParser.collapse(self: &mut Self, subs: Vec[i32], op: i32) -> i32`
10. `fn RegexParser.parse_vertical_bar(self: &mut Self)`
11. `fn RegexParser.parse_right_paren(self: &mut Self) -> Result[(), RegexError]`
12. `fn RegexParser.parse_repeat(self: &mut Self) -> Result[(i32,i32,i32,bool), RegexError]` — parse `{n,m}`
13. `fn RegexParser.repeat(self: &mut Self, op: i32, min: i32, max: i32, before: i32, after: i32, lastrepeat: str) -> Result[(), RegexError]`
14. `fn parse(pattern: str, flags: i32) -> Result[(NodePool, i32), RegexError]` — entry point

**The big switch** (Go's parse main loop): iterate bytes of pattern.
Each case maps:
- Default → decode rune, call `literal(r)`
- `(` → push OP_LEFT_PAREN (Perl flags deferred to Step 5)
- `|` → `parse_vertical_bar`
- `)` → `parse_right_paren`
- `^` → push BeginLine or BeginText
- `$` → push EndLine or EndText
- `.` → push AnyChar or AnyCharNotNL
- `*`, `+`, `?` → `repeat` with Star/Plus/Quest
- `{` → `parse_repeat`, then `repeat`
- `\` → basic escapes only (full escapes in Step 5)
- `[` → stub error "TODO" (full class parsing in Step 5)

**UTF-8 decoding:** Implement `fn next_rune(s: str, pos: i32) -> (i32, i32)`
returning (rune, byte_width). Manual UTF-8 decode from `s.byte_at()`.
~20 lines.

**Simplification: skip `factor()` for now.** The Go factor function
(lines 589–773) is an alternation optimization. Start with naive
collapse (just concat all subs into an Alternate node). Port factor
in Step 5 or as a later optimization.

**Done when:**
- `parse("abc", PERL)` → Literal{[0x61,0x62,0x63]}
- `parse("a|b", PERL)` → Alternate{Literal{a}, Literal{b}}
- `parse("(a)", PERL)` → Capture{cap=1, Literal{a}}
- `parse("a*", PERL)` → Star{Literal{a}}
- `parse("a{2,3}", PERL)` → Repeat{min=2, max=3, Literal{a}}
- `parse("*", PERL)` → Error

**Tests:** `test/behavior/behav_regex_parse_basic.w`

---

### Step 5: Parser — Extensions

**Ports:** `syntax/parse.go` lines 1097–1900
**Creates:** additions to `lib/std/regex/parse.w`
**Depends on:** Step 4
**Est:** ~400 LOC

Add:
1. **Perl flags:** `(?i)`, `(?:...)`, `(?P<name>...)`, `(?<name>...)`,
   `(?flags:...)`
2. **Character classes:** `[a-z]`, `[^abc]`, `[[:alpha:]]`,
   nested ranges, Perl escapes inside `[...]`
3. **All escape sequences:** `\a\f\n\r\t\v`, `\xHH`, `\x{HHHH}`,
   `\0`–`\777`, `\Q...\E`, `\.\\` etc.
4. **Unicode classes:** `\p{Latin}`, `\P{N}`, `\pL` (stub tables
   until Step 10 — use empty range and flag for later)
5. **Perl class escapes:** `\d\D\s\S\w\W` (wire to Step 3 tables)
6. **Factor function** (alternation prefix optimization)

**Key functions to add:**
```
fn RegexParser.parse_perl_flags(self: &mut Self) -> Result[(), RegexError]
fn RegexParser.parse_class(self: &mut Self) -> Result[(), RegexError]
fn RegexParser.parse_class_char(self: &mut Self, context: str) -> Result[(i32, i32), RegexError]
fn RegexParser.parse_escape(self: &mut Self) -> Result[(i32, i32), RegexError]
fn RegexParser.parse_perl_class_escape(self: &mut Self, r: &mut Vec[i32]) -> bool
fn RegexParser.parse_named_class(self: &mut Self, r: &mut Vec[i32]) -> (i32, bool)
fn RegexParser.parse_unicode_class(self: &mut Self, r: &mut Vec[i32]) -> Result[(i32, bool), RegexError]
fn RegexParser.factor(self: &mut Self, subs: Vec[i32]) -> Vec[i32]
```

**Done when:**
- `parse("(?i)abc")` → FoldCase flag set
- `parse("(?P<name>\\w+)")` → Capture with name="name"
- `parse("[a-z0-9]")` → CharClass with correct ranges
- `parse("[^\\s]")` → negated CharClass
- `parse("\\x41")` → Literal 'A'
- `parse("\\d+")` → CharClass [0x30,0x39] under Plus

**Tests:** `test/behavior/behav_regex_parse_ext.w`

---

### Step 6: Simplification

**Ports:** `syntax/simplify.go` (151 lines)
**Creates:** `lib/std/regex/simplify.w`
**Depends on:** Steps 1, 4, 5
**Est:** ~120 LOC

```
fn simplify(pool: &mut NodePool, idx: i32) -> i32
fn simplify1(pool: &mut NodePool, op: i32, flags: i32, sub_idx: i32) -> i32
```

Transformations:
- `x{0}` → EmptyMatch
- `x{n}` → Concat of n copies
- `x{n,}` → Concat of (n-1) copies + Plus
- `x{n,m}` → Concat of n copies + nested Quest
- `(x*)*` → `x*` (idempotent)
- EmptyMatch under quantifier → EmptyMatch

**Done when:** No OpRepeat nodes remain after simplification.
`simplify(parse("a{2,4}"))` → Concat(a, a, Quest(a, Quest(a))).

**Tests:** `test/behavior/behav_regex_simplify.w`

---

### Step 7: Compiler

**Ports:** `syntax/compile.go` (296 lines)
**Creates:** `lib/std/regex/compile.w`
**Depends on:** Steps 1, 6
**Est:** ~250 LOC

**Types:**

```
type PatchList = {
    head: i32,     // 0 = empty. head>>1 = inst index, head&1 = Out(0)/Arg(1)
    tail: i32,
}

type Frag = {
    i: i32,            // first instruction index
    out: PatchList,
    nullable: bool,
}

type RegexCompiler = {
    prog: Prog,
}
```

**Key functions:**

```
fn PatchList.patch(self: PatchList, prog: &mut Prog, val: i32)
fn PatchList.append(self: PatchList, prog: &Prog, other: PatchList) -> PatchList

fn RegexCompiler.compile(pool: &NodePool, idx: i32) -> Result[Prog, RegexError]
fn RegexCompiler.compile_node(self: &mut Self, pool: &NodePool, idx: i32) -> Frag
fn RegexCompiler.inst(self: &mut Self, op: i32) -> Frag
fn RegexCompiler.nop(self: &mut Self) -> Frag
fn RegexCompiler.fail(self: &mut Self) -> Frag
fn RegexCompiler.cap(self: &mut Self, arg: i32) -> Frag
fn RegexCompiler.cat(self: &mut Self, f1: Frag, f2: Frag) -> Frag
fn RegexCompiler.alt(self: &mut Self, f1: Frag, f2: Frag) -> Frag
fn RegexCompiler.quest(self: &mut Self, f1: Frag, nongreedy: bool) -> Frag
fn RegexCompiler.star(self: &mut Self, f1: Frag, nongreedy: bool) -> Frag
fn RegexCompiler.plus(self: &mut Self, f1: Frag, nongreedy: bool) -> Frag
fn RegexCompiler.loop_frag(self: &mut Self, f1: Frag, nongreedy: bool) -> Frag
fn RegexCompiler.empty(self: &mut Self, op: i32) -> Frag
fn RegexCompiler.rune(self: &mut Self, r: &Vec[i32], flags: i32) -> Frag
```

**Instruction specialization in `rune()`:**
- 1 rune, no fold → INST_RUNE1
- `[0, 0x10ffff]` → INST_RUNE_ANY
- `[0, 0x09] + [0x0b, 0x10ffff]` → INST_RUNE_ANY_NOT_NL
- Otherwise → INST_RUNE

**Done when:** `compile("a")` → [Rune1('a'), Match].
`compile("(a|b)*")` → correct Alt/Rune1/Capture/Match structure.
`prog.num_cap` correct.

**Tests:** `test/behavior/behav_regex_compile.w`

---

### Step 8: Prog Utilities

**Ports:** `syntax/prog.go` lines 75–282
**Adds to:** `lib/std/regex/prog.w`
**Depends on:** Steps 1, 7
**Est:** ~150 LOC

```
fn empty_op_context(r1: i32, r2: i32) -> i32
fn is_word_char(r: i32) -> bool
fn Inst.match_rune(self: &Inst, r: i32) -> bool
fn Inst.match_rune_pos(self: &Inst, r: i32) -> i32   // -1 if no match
fn Inst.match_empty_width(self: &Inst, before: i32, after: i32) -> bool
fn Prog.prefix(self: &Prog) -> (str, bool)
fn Prog.start_cond(self: &Prog) -> i32
```

`match_rune_pos`: linear search for ≤8 runes, binary search for
larger. Handles FoldCase via SimpleFold orbit.

**Done when:** `is_word_char('a')` true, `is_word_char(' ')` false.
`empty_op_context(-1, 'a')` includes EMPTY_BEGIN_TEXT.

**Tests:** `test/behavior/behav_regex_prog.w`

---

### Step 9: NFA Execution Engine

**Ports:** `exec.go` (554 lines)
**Creates:** `lib/std/regex/exec.w`
**Depends on:** Steps 1, 7, 8
**Est:** ~350 LOC

**Types:**

```
type Thread = {
    pc: i32,
    cap: Vec[i32],    // capture positions, -1 = unset
}

type Queue = {
    sparse: Vec[i32], // sparse set for O(1) membership
    dense: Vec[Thread],
    size: i32,
}

type NFAMachine = {
    prog: Prog,
    q0: Queue,
    q1: Queue,
    pool: Vec[Thread],
    matched: bool,
    matchcap: Vec[i32],
}
```

**Key functions:**

```
fn next_rune(s: str, pos: i32) -> (i32, i32)    // (rune, byte_width)
fn prev_rune(s: str, pos: i32) -> (i32, i32)    // for context

fn Queue.clear(self: &mut Self)
fn Queue.contains(self: &Self, pc: i32) -> bool

fn NFAMachine.new(prog: Prog, ncap: i32) -> NFAMachine
fn NFAMachine.alloc_thread(self: &mut Self, pc: i32) -> Thread
fn NFAMachine.free_thread(self: &mut Self, t: Thread)

fn NFAMachine.add(self: &mut Self, q: i32, pc: i32, pos: i32,
                   cap: &Vec[i32], cond_before: i32, cond_after: i32)
    // Epsilon closure: follow Nop, Alt, Capture, EmptyWidth without
    // consuming input. Only Rune* instructions become real threads.
    // Use while-loop to simulate Go's goto.

fn NFAMachine.step(self: &mut Self, pos: i32, next_pos: i32,
                    c: i32, next_cond_before: i32, next_cond_after: i32)
    // Process all threads in q0, add successors to q1.

fn NFAMachine.match_string(self: &mut Self, s: str, pos: i32,
                            ncap: i32) -> Vec[i32]
    // Main loop: for each rune, step + swap queues.
```

**Input abstraction:** Only string input for Phase 1. UTF-8 decoding
via `next_rune`/`prev_rune` helpers (~20 lines each).

**Sparse set trick:** `q.sparse[pc] < q.size && q.dense[q.sparse[pc]].pc == pc`
gives O(1) membership test. Clear is O(1) by setting `size = 0`.

**Thread priority:** Threads ordered by insertion. First Match wins
(leftmost-first).

**Done when:**
- `match("a", "a")` → true
- `match("a*", "")` → true
- `match("^abc$", "abc")` → true, `match("^abc$", "xabc")` → false
- `match("(a)(b)", "ab")` → captures [0,2, 0,1, 1,2]
- `match("a?{30}a{30}", "a"*30)` completes in <1s (linear guarantee)

**Tests:** `test/behavior/behav_regex_nfa.w`

---

### Step 10: Unicode Tables

**Ports:** Go's `unicode` package tables + `syntax/perl_groups.go` Unicode section
**Adds to:** `lib/std/regex/unicode.w`
**Depends on:** Steps 2, 3
**Est:** ~200 LOC + generated tables

**Approach:** Write a Python script `scripts/generate_unicode_tables.py`
that reads Go's unicode package tables (or UCD directly) and emits
`lib/std/regex/unicode_tables.w` containing:

1. **General categories** as functions returning `Vec[i32]` range pairs:
   L, Lu, Ll, Lt, Lm, Lo, M, Mn, Mc, Me, N, Nd, Nl, No,
   P, Pc, Pd, Ps, Pe, Pi, Pf, Po, S, Sc, Sk, Sm, So,
   Z, Zs, Zl, Zp, C, Cc, Cf, Co, Cs, Cn

2. **Scripts** (most common): Latin, Greek, Cyrillic, Armenian,
   Arabic, Hebrew, Devanagari, Bengali, Han, Hiragana, Katakana,
   Hangul, Thai, Georgian, Ethiopic, Cherokee, Tibetan, Myanmar

3. **SimpleFold** table: sorted array of `(rune, fold_target)`.
   Binary search for lookup.

4. **Lookup function:**
   ```
   fn unicode_table(name: str) -> Option[(Vec[i32], i32)]
       // Returns (ranges, sign). sign=+1 include, -1 negate.
       // Handles categories, scripts, aliases.
       // Special: "Any" = [0, 0x10ffff], "ASCII" = [0, 0x7f]
   ```

5. **SimpleFold:**
   ```
   fn simple_fold(r: i32) -> i32
       // Next rune in fold orbit. simple_fold('A')='a', simple_fold('a')='A'.
   ```

6. **Wire `append_folded_range`** in charclass.w to use real `simple_fold`.

**Risk mitigation:** If full Unicode tables make compilation slow or
binary too large, start with Option B: ASCII-only fold + top 10
categories + top 5 scripts. Expand later.

**Done when:** `unicode_table("Latin")` returns correct ranges.
`simple_fold('A')` returns `'a'`. `/\p{Greek}/` matches `'Ω'`.

**Tests:** `test/behavior/behav_regex_unicode.w`

---

### Step 11: Backtracking Engine

**Ports:** `backtrack.go` (365 lines)
**Creates:** `lib/std/regex/backtrack.w`
**Depends on:** Steps 1, 7, 8
**Est:** ~250 LOC

**Types:**

```
type Job = {
    pc: i32,
    arg: bool,
    pos: i32,
}

type BitState = {
    end: i32,
    cap: Vec[i32],
    matchcap: Vec[i32],
    jobs: Vec[Job],
    visited: Vec[i32],    // bit vector: visited[n/32] & (1<<(n%32))
}

let MAX_BACKTRACK_PROG: i32 = 500
let MAX_BACKTRACK_VECTOR: i32 = 262144   // 256KB
```

**Key functions:**

```
fn should_backtrack(prog: &Prog, input_len: i32) -> bool
fn BitState.new() -> BitState
fn BitState.reset(self: &mut Self, prog: &Prog, end: i32, ncap: i32)
fn BitState.should_visit(self: &mut Self, pc: i32, pos: i32) -> bool
fn BitState.push(self: &mut Self, pc: i32, pos: i32, arg: bool)
fn try_backtrack(prog: &Prog, b: &mut BitState, s: str,
                  pc: i32, pos: i32, longest: bool) -> bool
fn backtrack_match(prog: &Prog, s: str, pos: i32, ncap: i32,
                    longest: bool, prefix: str, cond: i32) -> Vec[i32]
```

Go's `goto CheckAndLoop` / `goto Skip` → `while true` + `continue`.

**Done when:** Same results as NFA for all test cases. Bit vector
prevents re-exploration of (pc, pos) pairs.

**Tests:** `test/behavior/behav_regex_backtrack.w` — verify identical
results to NFA on shared test vectors.

---

### Step 12: One-Pass DFA Engine

**Ports:** `onepass.go` (508 lines)
**Creates:** `lib/std/regex/onepass.w`
**Depends on:** Steps 1, 7, 8
**Est:** ~300 LOC

**Types:**

```
type OnePassInst = {
    op: i32,
    out: i32,
    arg: i32,
    runes: Vec[i32],
    next: Vec[i32],     // dispatch table: rune → next pc
}

type OnePassProg = {
    inst: Vec[OnePassInst],
    start: i32,
    num_cap: i32,
}
```

**Key functions:**

```
fn compile_one_pass(prog: &Prog) -> Option[OnePassProg]
fn make_one_pass(p: &mut OnePassProg) -> bool
fn merge_rune_sets(left: &Vec[i32], right: &Vec[i32],
                    left_pc: i32, right_pc: i32) -> Option[(Vec[i32], Vec[i32])]
fn one_pass_next(inst: &OnePassInst, r: i32) -> i32
fn execute_one_pass(prog: &OnePassProg, s: str, pos: i32,
                     ncap: i32, cond: i32) -> Vec[i32]
```

**Eligibility:**
- Anchored (`^` / `\A`)
- No ambiguous alternations (disjoint rune sets at every Alt)
- < 1000 instructions

**Done when:** `compile_one_pass` on `^\\d{3}-\\d{4}$` returns Some.
`compile_one_pass` on `a*` returns None. One-pass produces same
captures as NFA.

**Tests:** `test/behavior/behav_regex_onepass.w`

---

### Step 13: Public API

**Ports:** `regexp.go` (1,287 lines)
**Creates:** `lib/std/regex.w`
**Depends on:** Steps 1–12
**Est:** ~400 LOC

**Types:**

```
pub type Regex = {
    pattern: str,
    prog: Prog,
    onepass: Option[OnePassProg],
    num_subexp: i32,
    max_bit_state_len: i32,
    sub_names: Vec[str],
    prefix: str,
    prefix_end: i32,
    prefix_complete: bool,
    cond: i32,
    longest: bool,
    min_input_len: i32,
}

pub type Match = {
    start: i32,
    end: i32,
    text: str,
}

pub type Captures = {
    groups: Vec[Option[Match]],
    names: Vec[str],
}
```

**Construction:**

```
pub fn Regex.compile(pattern: str) -> Result[Regex, RegexError]
    // 1. parse(pattern, FLAGS_PERL) → (pool, root_idx)
    // 2. Extract cap count and names from AST
    // 3. simplify(pool, root_idx)
    // 4. RegexCompiler.compile(pool, root_idx) → Prog
    // 5. compile_one_pass(prog) → Option[OnePassProg]
    // 6. Extract prefix, start conditions
    // 7. Build Regex struct
```

**Strategy dispatch:**

```
fn Regex.do_execute(self: &Self, s: str, pos: i32, ncap: i32) -> Vec[i32]
    // if s.len < min_input_len: return []
    // if onepass.is_some(): try execute_one_pass
    // elif should_backtrack(prog, s.len): try backtrack_match
    // else: NFA match_string
```

**Public methods:**

```
pub fn Regex.is_match(self: &Self, text: str) -> bool
pub fn Regex.find(self: &Self, text: str) -> Option[Match]
pub fn Regex.find_all(self: &Self, text: str) -> Vec[Match]
pub fn Regex.find_at(self: &Self, text: str, start: i32) -> Option[Match]
pub fn Regex.captures(self: &Self, text: str) -> Option[Captures]
pub fn Regex.captures_all(self: &Self, text: str) -> Vec[Captures]
pub fn Captures.get(self: &Self, i: i32) -> Option[Match]
pub fn Captures.name(self: &Self, name: str) -> Option[Match]
pub fn Captures.len(self: &Self) -> i32
pub fn Regex.replace(self: &Self, text: str, repl: str) -> str
pub fn Regex.replace_all(self: &Self, text: str, repl: str) -> str
pub fn Regex.split(self: &Self, text: str) -> Vec[str]
pub fn Regex.splitn(self: &Self, text: str, n: i32) -> Vec[str]
pub fn Regex.num_captures(self: &Self) -> i32
pub fn Regex.capture_names(self: &Self) -> Vec[str]
pub fn Regex.capture_index(self: &Self, name: str) -> i32
pub fn Regex.set_longest(self: &mut Self)
```

**Replace template expansion:** Parse `$1`, `$name`, `${name}`, `$$`
in replacement strings. Port Go's `expand()`. ~60 lines.

**find_all/captures_all loop:** After each match, advance past
the match (or by 1 byte if match is empty to avoid infinite loop).
This is the `nonempty` flag pattern from Go.

**Done when:** Full end-to-end:
```
let re = Regex.compile("(\\w+)@(\\w+)").unwrap()
let caps = re.captures("user@host").unwrap()
assert(caps.get(1).unwrap().text == "user")
assert(caps.get(2).unwrap().text == "host")
assert(re.replace_all("a1b2", "[$0]") == "[a1][b2]")  // wait, this isn't right
```

**Tests:** `test/behavior/behav_regex_api.w`

---

### Step 14: Literal Prefix Optimization

**Ports:** prefix usage in `regexp.go`, `exec.go`, `backtrack.go`
**Modifies:** `lib/std/regex/exec.w`, `lib/std/regex/backtrack.w`,
`lib/std/regex.w`
**Depends on:** Step 13
**Est:** ~50 LOC

In NFA and backtrack engines: when starting an unanchored search and
a literal prefix exists, use `str.find(prefix, start_pos)` to skip
ahead instead of trying every position.

```
// In match_string, before the main loop:
if prefix.len() > 0 and not anchored:
    let idx = s.find(prefix, pos)
    if idx < 0: return not_found
    pos = idx
```

**Done when:** Matching `/hello\s+world/` against a 100KB string is
fast (skips to "hello" occurrences via str.find).

**Tests:** `test/behavior/behav_regex_prefix.w`

---

### Step 15: Test Suite

**Ports:** Go's test cases from `all_test.go`, `find_test.go`,
`syntax/parse_test.go`, `testdata/*.dat`
**Creates:** comprehensive test files
**Depends on:** Steps 1–14
**Est:** ~500 LOC of tests

**Test files:**

| File | What |
|---|---|
| `test/behavior/behav_regex_basic.w` | Basic matching: literals, dot, anchors, alternation |
| `test/behavior/behav_regex_quantifiers.w` | `*`, `+`, `?`, `{n,m}`, non-greedy |
| `test/behavior/behav_regex_classes.w` | `[a-z]`, `[^abc]`, `\d`, `\w`, POSIX classes |
| `test/behavior/behav_regex_captures.w` | `(a)(b)`, named captures, nested groups |
| `test/behavior/behav_regex_replace.w` | replace, replace_all, template `$1` `$name` |
| `test/behavior/behav_regex_split.w` | split, splitn, edge cases |
| `test/behavior/behav_regex_unicode.w` | `\p{Latin}`, `\p{Greek}`, case-insensitive |
| `test/behavior/behav_regex_edge.w` | Empty patterns, empty input, pathological `a?^n a^n` |
| `test/behavior/behav_regex_errors.w` | Invalid patterns produce correct errors |

Port at least 200 test cases from Go. Focus on the `findTests` table
in `find_test.go` and the `parseTests` table in `syntax/parse_test.go`.

**Pathological pattern test:** `a?{20}a{20}` matching `"a" * 20` must
complete in under 1 second. This validates the linear-time guarantee.

**Done when:** `make test` passes with all regex test files.

---

## Phase 2: Language Integration (Steps 16–19)

Requires compiler changes. Do after Phase 1 is working.

---

### Step 16: Lexer — `TK_REGEX_LIT`

**Modifies:** `src/Token.w`, `src/Lexer.w`
**Depends on:** Phase 1 complete
**Est:** ~80 LOC

**Token.w:** Add `TK_REGEX_LIT = 133`

**Lexer.w:** In the `/` handling:

```
fn Lexer.handle_slash(self: &mut Self):
    if self.prev_token_is_value():
        // Division
        self.emit(TK_SLASH)
    else:
        // Regex literal
        self.lex_regex()
```

`prev_token_is_value()`: returns true if previous token is
TK_IDENT, TK_INT_LIT, TK_FLOAT_LIT, TK_STRING_LIT, TK_RPAREN,
TK_RBRACKET, TK_TRUE, TK_FALSE. Returns false otherwise.

`lex_regex()`:
- Scan from current pos past opening `/`
- Track `[...]` depth (inside `[`, `/` is not a delimiter)
- Handle `\/` and `\\`
- On closing `/`, consume `[igmsxU]*` flag chars
- Emit TK_REGEX_LIT with span covering pattern+flags

**Done when:** `/abc/i` lexes as TK_REGEX_LIT. `a / b` still lexes as
division.

**Tests:** `test/behavior/behav_regex_literal.w`,
`test/compile_errors/err_regex_unterminated.w`

---

### Step 17: Parser — AST Nodes and `=~` Operator

**Modifies:** `src/Ast.w`, `src/Parser.w`
**Depends on:** Step 16
**Est:** ~150 LOC

**Ast.w:**
- `NK_REGEX_LIT = 115` (d0=pattern_sym, d1=flags_sym)
- `NK_MATCH_OP = 116` (d0=lhs, d1=rhs) — for `=~`
- `NK_NEG_MATCH_OP = 117` (d0=lhs, d1=rhs) — for `!~`
- `OP_REGEX_MATCH = 29`, `OP_REGEX_NEG_MATCH = 30` in BinaryOp

**Parser.w:**
- In `parse_primary()`: TK_REGEX_LIT → create NK_REGEX_LIT
- In `infix_op()`: recognize `=~` (TK_EQ + TK_TILDE sequence, or
  add TK_MATCH_EQ to lexer) at precedence 3 (same as ==, !=)
- In `parse_if_expr()`: when condition contains NK_MATCH_OP, inject
  capture bindings (`$0`, `$1`, ...) into body scope as let bindings
- In `parse_match_arm()`: allow NK_REGEX_LIT as arm pattern

**`$N` tokens:** Lexer treats `$` followed by digits or identifier as
a special identifier `$0`, `$1`, `$name`. These are only valid
inside `=~` if-bodies and regex match arms.

**Capture binding desugaring in if:**
```
// if line =~ /^(\w+)\s*=\s*(.+)$/:
//     use($1, $2)
// → Parser emits:
// NK_IF_EXPR(
//   cond = NK_MATCH_OP(line, /^(\w+)\s*=\s*(.+)$/),
//   body = Block(
//     NK_LET_DECL($0, ...),
//     NK_LET_DECL($1, ...),
//     NK_LET_DECL($2, ...),
//     use($1, $2)))
```

The actual binding values are filled in by codegen (Step 19).

**Done when:** `if x =~ /pattern/:` parses. `let r = /abc/i` parses.
Match arms with regex patterns parse.

**Tests:** `test/behavior/behav_regex_syntax.w`

---

### Step 18: Sema — Type Checking

**Modifies:** `src/Sema.w`
**Depends on:** Step 17
**Est:** ~80 LOC

- Regex is represented as TY_STRUCT pointing to the `Regex` type
  from `lib/std/regex.w`. No new TY_ constant needed — it's a
  normal struct type resolved via the module system.
- NK_MATCH_OP: check lhs is `str`, rhs is `Regex`, result is `bool`
- NK_NEG_MATCH_OP: same
- NK_REGEX_LIT: **validate regex pattern at compile time** by calling
  the regex parser (from lib/std/regex/parse.w, available at compile
  time via the embedded stdlib). On error, emit compile error with
  source location pointing to the regex literal.
- Capture binding `$N`: typed as `str`

**Done when:** `42 =~ /abc/` produces type error. `/[/` produces
compile error with helpful message.

**Tests:** `test/compile_errors/err_regex_type.w`,
`test/compile_errors/err_regex_invalid.w`

---

### Step 19: Codegen — Lazy Static Compilation

**Modifies:** `src/Codegen.w`
**Depends on:** Step 18
**Est:** ~100 LOC

For each regex literal:
1. Emit a module-level global `__regex_N` of type Regex
2. Emit a once-flag `__regex_N_init` (bool, initially false)
3. On first access: call `Regex.compile(pattern)`, store result,
   set flag
4. On subsequent access: load from global

**Desugaring `=~`:**
```
// Code: if line =~ /^(\w+)/:
// Emits:
//   %re = load @__regex_0 (or compile on first use)
//   %caps = call Regex.captures(%re, %line)
//   %has_match = call Option.is_some(%caps)
//   br %has_match, then_bb, else_bb
// then_bb:
//   %unwrapped = call Option.unwrap(%caps)
//   %$0 = call Captures.get(%unwrapped, 0) → Match.text
//   %$1 = call Captures.get(%unwrapped, 1) → Match.text
//   ... body ...
```

**Done when:** End-to-end works:
```
if "hello world" =~ /^(\w+)\s+(\w+)$/:
    assert($1 == "hello")
    assert($2 == "world")
```

**Tests:** `test/behavior/behav_regex_lang.w`

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `Vec[RegexpNode]` nesting fails | Medium | High | Use NodePool with index references (already in plan) |
| Unicode tables too large | Low | Medium | Start ASCII-only; add Unicode incrementally |
| UTF-8 decoding missing | Medium | High | Implement manual `next_rune` (~20 lines) |
| Deep recursion in parser | Medium | Medium | Limit depth to 1000 (same as Go) |
| HashMap generic issues | Low | Low | Use `Vec[(str, i32)]` + linear scan for capture names |
| `/` disambiguation wrong | Medium | Medium | Port exact JS algorithm; extensive test cases |
| Step 4 (parser core) too large | Medium | Medium | Split into sub-steps: basic loop first, then repeat, then grouping |

---

## Dependency Graph

```
1 ──→ 2 ──→ 3 ──→ 10
│     │           │
│     └───→ 4 ──→ 5 ──→ 6 ──→ 7 ──→ 8 ──→ 9
│                                     │     │
│                                     │     └──→ 11
│                                     └────────→ 12
│
└─────────────────────────────────────────────→ 13 ──→ 14 ──→ 15
                                                              │
                                                              └──→ 16 ──→ 17 ──→ 18 ──→ 19
```

Steps 9 (NFA), 10 (Unicode), 11 (backtrack), 12 (onepass) can
proceed in parallel after Step 8.

---

## Size Estimates

| Step | File(s) | Est. LOC |
|---|---|---|
| 1 | syntax.w, prog.w | 150 |
| 2 | charclass.w | 250 |
| 3 | unicode.w (part 1) | 100 |
| 4 | parse.w (core) | 500 |
| 5 | parse.w (extensions) | 400 |
| 6 | simplify.w | 120 |
| 7 | compile.w | 250 |
| 8 | prog.w (additions) | 150 |
| 9 | exec.w | 350 |
| 10 | unicode.w (part 2) + tables | 200 + tables |
| 11 | backtrack.w | 250 |
| 12 | onepass.w | 300 |
| 13 | regex.w (public API) | 400 |
| 14 | prefix opt | 50 |
| 15 | tests | 500 |
| 16 | Token.w, Lexer.w | 80 |
| 17 | Ast.w, Parser.w | 150 |
| 18 | Sema.w | 80 |
| 19 | Codegen.w | 100 |
| **Total** | | **~4,380 + tables + tests** |

---

## Verification

After each step:
```
make build      # compiler compiles
make fixpoint   # stage2 == stage3 (only for Phase 2 steps)
make test       # no regressions, new regex tests pass
```

After Phase 1 complete:
- `Regex.compile("...")` works for all Go test patterns
- Three execution strategies produce identical results
- Pathological patterns complete in linear time
- At least 200 ported test cases pass

After Phase 2 complete:
- `/pattern/flags` literals work
- `=~` / `!~` operators work with capture bindings
- Regex in `match` arms works
- Invalid regex literals caught at compile time
