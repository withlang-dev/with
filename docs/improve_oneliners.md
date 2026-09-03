# Why With One-Liners Are Longer

This document groups every `POSSIBLE_IMPROVE` entry in
[`with_oneliners.md`](with_oneliners.md) by the primary reason the With command
is more than 20% longer than its Perl 6 counterpart in
`.reference/perl_oneliners.md`.

> **D22 status (2026-07-23):** keyed-map reads in these recipes follow the
> accepted uniform-view contract and use explicit `.cloned()` for owned
> non-Copy results. Implementation is still in progress; do not revert the
> recipes to owned lookup to accommodate the current compiler.

The grouping is diagnostic, not a claim that character count is the only
design goal. Several commands fit more than one group; each appears once under
the cause that accounts for the largest share of its extra text. The commands
below are the exact original With one-liners from the cookbook, not proposed
replacements.

| Primary cause | Recipes |
|---|---:|
| Explicit line topic and output plumbing | 13 |
| Missing whole-stream queries and aggregators | 19 |
| Explicit parsing, typing, and empty-case handling | 6 |
| Missing math, combinatoric, and random algorithms | 12 |
| Missing safe date and time surface | 8 |
| Missing Unicode and text conveniences | 11 |
| Missing collection-analysis vocabulary | 10 |
| Missing codecs, serializers, and HTML tools | 8 |
| Missing domain value types | 4 |
| Limited range and sequence generation | 3 |
| Explicit numeric formatting policy | 2 |
| **Total** | **96** |

## sed, awk, coreutils, and jq parity audit (2026-09-03)

The goal is that a With one-liner replaces perl, sed, awk, jq, cut, tr, sort
and friends outright (CLAUDE.md: never reach for sed; a transform that cannot
be a one-liner is a bug to file). The cookbook above measures length against
Perl; this audit measures *possibility* against the tools' idioms. Method:
every idiom below was run as a real `with -n`/`-p`/`-e` one-liner on the
installed compiler (v0.15.1.7-g54651442e) over a seven-line fixture, and each
failing row became an issue. Verdicts are from the run, not from reading the
spec.

### What already works (and the cheat-sheet did not say)

| tool idiom | With one-liner |
|---|---|
| `sed -n 'A,Bp' file` | `with -n 'if nr >= A and nr <= B: print(line)' < file` |
| `sed '/pat/d'` | `with -n 'if not line.contains("pat"): print(line)'` |
| `sed 's/old/new/g'` | `with -p 'line = line.replace("old", "new")'` (all occurrences) |
| `sed -E 's/^(\w+) +(\d+)/\2 \1/'` | `with -p 'line = /^(\w+)\s+(\d+)/.replace(line, "$2 $1")'` |
| `sed '3i text'` | `with -n 'if nr == 3: print("text")` ⏎ `print(line)'` |
| `awk 'NR % 2 == 0'` | `with -n 'if nr % 2 == 0: print(line)'` |
| `grep -i pat` | `with -n 'if line =~ /pat/i: print(line)'` |
| `perl -ne 'print $1 if /(\d+)/'` | `with -n 'if line =~ /(\d+)/: print($1)'` |
| `head -n 2` | `with -n 'if nr <= 2: print(line)'` |
| `tr a-z A-Z` | `with -p 'line = line.upper()'` |
| `sed 'y/xy/XY/'` | `with -p 'line = line.replace("x", "X").replace("y", "Y")'` |
| `cut -c1-5` | `with -p 'line = line.slice(0, if line.len() < 5: line.len() else: 5)'` |
| `paste -sd,` | `with -e 'print(stdin.lines().join(","))'` |
| `perl -0777` (slurp) | `with -e '… read_all() …'` |
| `grep -c pat`, `sort \| uniq -c` | `-e` with a counter / a `HashMap[str, i32]` over `stdin.lines()` |
| `printf "%-8s\|%5d"` | `f"{name:<8}\|{n:>5}"` |
| `jq -r .a`, `jq -r .b.c` | `with -e 'use std.json` ⏎ `print(JsonDocument.parse(read_all()).root().field("b").field("c").raw())'` |

`nr` has been in §18.5b all along; the sed habit came from a cheat-sheet that
mapped `grep`, `s///` and `cut` and nothing else. The regex-literal
`.replace` with `$N` backreferences works directly in `-p`, so "complex regex
needs a `with run` script" was also wrong.

### What does not work, by cause

Each row was run and failed with the diagnostic shown; the issue carries the
proposal and the acceptance rows.

**1. No persistent state and no END in `-n`/`-p` (#957).** A snippet runs
inside the per-line loop (§18.5b.3's desugaring), so a `var` it declares is
re-created per line, an undeclared assignment is "undefined variable", and
there is no `last`/END. Blocked: `sed '$p'`, `sed -n '/START/,/END/p'`,
`awk '{s+=$2} END{print s}'`, `awk '!seen[$0]++'`, `wc -l`, `tail -n 1`. All
are expressible in `-e` with a loop over `stdin.lines()`, which already
materializes the input as `Vec[str]`, so `last`/END cost nothing. Proposal:
hoist a snippet's top-level `var` declarations out of the loop and bind
`last: bool`.

**2. No file operands and no `-i` (#958).** `with -n CODE file` and
`with -p -i CODE file` are refused with "cannot combine one-liner code with a
source file" — §18.5b's own sentence, so the fix is a spec edit (trailing
operands are inputs; `filename`/`fnr` bindings; `-i` through a temp sibling
and rename).

**3. No whitespace-run fields and no integer parse on `str` (#959).**
`line.split(" ")` yields an empty field for a double space (awk's `$N`
ignores runs; `wc -w` overcounts the fixture 18 for 17), `fields()` does not
exist, and the only integer parser is the free function
`std.string.parse(s) -> i32`. Blocked: `awk '{print $2}'`, `awk -F: NF`,
`$2 + 0`.

**4. No `Vec.sort` and no `str.reverse` (#960).** `sort` and `rev` have no
spelling; aggregation (`uniq -c`) does.

**5. `std.json` stops at `field`/`raw` (#961).** `.a` and `.b.c` work;
`.xs[1]`, `.xs[]`, `keys`, and pretty-printing have no method, only the
token-pointer functions, and `std.json` is not an implicit one-liner import.

**Found along the way.** Writing the rewrite script for the cheat-sheet as a
`with run` tool exposed two compiler defects, filed with repros: `let p =
args().get(1)` is a view into a temporary that dies at the end of the
statement and reads as `""` instead of being rejected (#962, the D27/§5.4
origin rule), and `with check` refuses an implicit-main file that `with run`
and `with build` accept (#963), so a tool script cannot be typechecked
before it runs.

### Cheat-sheet consequences

CLAUDE.md's one-liner cheat-sheet now maps the range, delete, backreference,
awk-field (with the exact-separator caveat until #959), END-style, and jq
idioms, so the next reader reaches for `nr` instead of `sed -n`.

## Explicit line topic and output plumbing

Perl's `-n` and `-p` modes combine several terse conventions: `$_` is the
current line, a leading method call targets that implicit value, `.say` both
formats and emits, statement modifiers put a condition after the action, and
operators such as `.=` update the topic in place. With deliberately names the
bindings `line` and `nr`, but then makes the command repeat `line`, `print`, and
often an assignment. That fixed plumbing dominates otherwise tiny recipes.

Affected one-liners (13):

```sh
# Uppercase with -p in the tutorial
with -p 'line=line.upper()' </path/to/file.txt

# N-space a file
with -p 'line=line++"\n".repeat(3)' <example.txt

# Remove all blank lines
with -n 'if line =~ /\S/:print(line)' <example.txt

# Count comma-separated elements on each line
with -n 'print_i64(line.split(",").len())' <example.txt

# Convert all text to uppercase
with -p 'line=line.upper()' <example.txt

# Convert all text to lowercase
with -p 'line=line.lower()' <example.txt

# Replace every ut with foo
with -p 'line=line.replace("ut","foo")' <example.txt

# Replace every ut with foo on lines containing Lorem
with -p 'if line.contains("Lorem"):line=line.replace("ut","foo")' <example.txt

# Print the first line
with -n 'if nr==1:print(line)' <example.txt

# Print lines containing a vowel
with -n 'if line =~ /[aeiou]/:print(line)' <example.txt

# Print lines containing a number
with -n 'if line =~ /\d/:print(line)' <example.txt

# Print lines containing only a number
with -n 'if line =~ /^\d+$/:print(line)' <example.txt

# Print an approximately 5% random sample
with -e 'use std.random;for l in stdin.lines():if chance(5):print(l)' </usr/share/dict/words
```

Potential design changes:

- Let `-p` print the value of a single expression, so a transform can be
  written as `with -p 'line.upper()'` without mutating `line`. Statement bodies
  could keep today's behavior.
- Add a small CLI-only topic shorthand rather than a language-wide magical
  variable. For example, `it.upper()` in `-n`/`-p` could mean the current line
  while ordinary With remains explicit.
- Allow `print` to format primitive scalar values directly. This removes
  `print_i32`/`print_i64` from many small scripts without weakening typing.
- Consider concise, general helpers such as `emit_if(condition, value)` or an
  iterator `filter` pipeline before adding Perl-style postfix syntax.
- Add a string repeat operator or compound concatenation form if it is useful
  outside one-liners; the N-spacing recipe should not alone justify a new
  operator.

The named `line` binding is easier to teach and search for than `$_`. The best
gain is therefore likely expression-result behavior in `-p` plus generic
printing, not importing Perl's entire implicit-topic model.

## Missing whole-stream queries and aggregators

Perl exposes `lines` directly and layers compact operations such as `grep`,
`elems`, `min`, `max`, end-relative slicing, and stateful hashes over it. With
has the raw ingredients, but many whole-input questions still require
`stdin.lines()`, a mutable accumulator, a loop, and a final typed print. Tail,
duplicate, and between-pattern operations have no named abstraction at all, so
the one-liner spells the state machine.

Affected one-liners (19):

```sh
# Number only non-empty lines
with -e 'var n=0;for l in stdin.lines():if l!=""{n+=1;print(f"{n} {l}")}' <example.txt

# Count all lines
with -e 'print_i64(stdin.lines().len())' <example.txt

# Count non-empty lines
with -e 'print_i32(stdin.lines().fold(0,(n,x)=>n+(if x!="":1 else:0)))' <example.txt

# Count empty or whitespace-only lines
with -e 'print_i32(stdin.lines().fold(0,(n,x)=>n+(if x =~ /^\s*$/:1 else:0)))' <example.txt

# Sum all tab-separated fields on all lines
with -e 'var s=0;for l in stdin.lines():s+=l.split("\t").fold(0,(a,x)=>a+parse(x));print_i32(s)' <example.txt

# Find the lexical minimum over all lines
with -e 'print(read_all().trim().replace("\n","\t").split("\t").iter().min().unwrap())' <example.txt

# Find the lexical maximum over all lines
with -e 'print(read_all().trim().replace("\n","\t").split("\t").iter().max().unwrap())' <example.txt

# Count tab-separated fields on all lines
with -e 'var n=0;for l in stdin.lines():n+=l.split("\t").len32();print_i32(n)' <example.txt

# Count words on all lines
with -e 'var n=0;for l in stdin.lines():n+=(/\S+/.find_all(l).len32());print_i32(n)' <example.txt

# Count tab-separated fields that match a pattern
with -e 'var n=0;for l in stdin.lines():for x in l.split("\t"):if x =~ /pattern/:n+=1;print_i32(n)' <example.txt

# Count words that match a pattern
with -e 'var n=0;for l in stdin.lines():for x in /\S+/.find_all(l):if x.text =~ /pattern/:n+=1;print_i32(n)' <example.txt

# Count lines that match a pattern
with -e 'var n=0;for l in stdin.lines():if l =~ /in/:n+=1;print_i32(n)' <example.txt

# Print the last line
with -e 'let l=stdin.lines();print(l[l.len()-1])' <example.txt

# Print the last five lines
with -e 'let l=stdin.lines();for i in max(0,l.len()-5)..l.len():print(l[i])' <example.txt

# Print the inclusive range between two regexes
with -e 'var p=false;for l in stdin.lines(){if l =~ /^Lorem/:p=true;if p:print(l);if l =~ /laborum\.$/:p=false}' <example.txt

# Print the length of the longest line
with -e 'var n=0;for l in stdin.lines(){let c=/\X/g.find_all(l);n=max(n,c.len32())};print_i32(n)' <example.txt

# Print the longest line
with -e 'var m="";for l in stdin.lines(){if l.len()>m.len():m=l};print(m)' <example.txt

# Print repeated lines once each
with -e 'var c:HashMap[str,i32]=[:];for l in stdin.lines(){c.increment(l);if c.get(l).unwrap()==2:print(l)}' <example.txt

# Print unique lines, keeping the first
with -e 'var c:HashMap[str,i32]=[:];for l in stdin.lines(){c.increment(l);if c.get(l).unwrap()==1:print(l)}' <example.txt
```

Potential design changes:

- Complete the iterator vocabulary with `count`, `count_where`, `sum`,
  `sum_by`, `last`, `take_last`, `max_by_key`, `frequencies`, `unique`, and
  `duplicates`.
- Add `flat_map` or a delimiter-aware `fields()` iterator so field totals do
  not require nested loops or newline-to-tab rewriting.
- Provide an inclusive `between(start_predicate, end_predicate)` stream
  adapter instead of a special flip-flop operator. It expresses the behavior
  directly and remains useful outside regexes.
- Make `stdin.lines()` lazy, or add `stdin.line_iter()`, so these helpers can
  stream. `last` needs one retained value, `take_last(5)` needs a five-element
  ring, and neither should materialize the whole file.
- Let the compiler infer a one-liner's result formatter so a terminal scalar
  can be emitted without selecting `print_i32` or `print_i64`.

An implicit global `lines` binding would save characters, but a strong lazy
iterator API removes more ceremony across normal With programs as well. That
is the higher-leverage design.

## Explicit parsing, typing, and empty-case handling

Perl freely coerces strings to numbers, lets `say` format any value, and keeps
many empty-collection cases implicit. With requires numeric parsing, a concrete
numeric type, and an explicit decision for `Option` returned by `min` or `max`.
Those checks account for real safety, but their current spelling is expensive
in a one-liner.

Affected one-liners (6):

```sh
# Sum tab-separated fields on each line
with -n 'print_i32(line.split("\t").fold(0,(s,x)=>s+parse(x)))' <example.txt

# Find the lexical minimum on each non-empty line
with -n 'if line!="":print(line.split("\t").iter().min().unwrap())' <example.txt

# Find the lexical maximum on each non-empty line
with -n 'if line!="":print(line.split("\t").iter().max().unwrap())' <example.txt

# Find the numeric minimum on each non-empty line
with -n 'if line!="":print_i32(line.split("\t").map(x=>parse(x)).iter().min().unwrap())' <example.txt

# Find the numeric maximum on each non-empty line
with -n 'if line!="":print_i32(line.split("\t").map(x=>parse(x)).iter().max().unwrap())' <example.txt

# Replace each field with its absolute value
with -n 'print(line.split("\t").map(x=>f"{abs(parse(x))}").join("\t"))' <example.txt
```

Potential design changes:

- Support concise typed parsing such as `x.parse[i32]?`, with the type inferred
  from the fold or comparison when possible.
- Let implicit one-liner `main` propagate `Result`, so `?` is usable without a
  hand-written function signature.
- Add `min_or`, `max_or`, or a concise `Option` propagation path. Do not make
  `min` silently invent a default for an empty iterator.
- Add generic scalar printing and joining over values that implement a
  compiler-known formatting trait.
- Consider a clearly opt-in one-liner mode where parse failure exits with a
  diagnostic. It can be terse without becoming lossy.

This is the group where copying Perl most directly would be a mistake. Silent
numeric coercion and silent empty defaults would shorten the examples by
discarding With's safety promise. The opportunity is to make the safe decision
short, especially through inference and `?`.

## Missing math, combinatoric, and random algorithms

Perl 6 includes unusually dense mathematical and sequence operations:
`.is-prime`, reduction metaoperators, `gcd`, `lcm`, `roll`, `pick`,
`permutations`, and `combinations`. With currently implements several of these
recipes from first principles, including Fisher-Yates shuffling and recursive
permutation generation.

Affected one-liners (12):

```sh
# Check whether 7 is prime
with -e 'let n=7;var p=n>1;for d in 2..n{if n%d==0:p=false};if p:print(f"{n} is prime")'

# Shuffle fields on every line
with -e 'use std.random;for line in stdin.lines(){var a=line.split("\t");var i=a.len32();while i>1{i-=1;let j=range_i32(0,i+1);let x=a[i];a[i]=a[j];a[j]=x};print(a.join("\t"))}' <example.txt

# Calculate 5 factorial
with -e 'var n=1;for i in 1..=5{n*=i};print_i32(n)'

# Calculate the GCD of 20, 35, and 50
with -e 'let n:Vec[i32]=[20,35,50];var g=n[0];for x in n{var b=x;while b!=0{let t=b;b=g%b;g=t}};print_i32(g)'

# Calculate the GCD of 20 and 35 with Euclid's algorithm
with -e 'var a=20;var b=35;while b!=0{let t=b;b=a%b;a=t};print_i32(a)'

# Calculate the LCM of 20 and 35
with -e 'var a=20;var b=35;while b!=0{let t=b;b=a%b;a=t};print_i32(20*35/a)'

# Generate ten random numbers in 5..<15
with -e 'use std.random;for _ in 0..10:print_i32(range_i32(5,15))'

# Print every permutation of 12345
with -e 'fn p(s:str,r:str){if r=="":print(s);for i in 0..r.len32(){p(s++r.slice(i,i+1),r.slice(0,i)++r.slice(i+1,r.len32()))}};p("","12345")'

# Print the power set of 1, 2, and 3
with -e 'for m in 0..8{var s="";for i in 0..3{if m&(1<<i as u32)!=0:s=s++f"{i+1}"};print(s)}'

# Generate a random ten-character lowercase string
with -e 'use std.random;var s=FixedString[10].new();for _ in 0..10:s.push_byte(range_i32(97,123) as u8);write(s.as_view())'

# Generate a random fifteen-character ASCII password
with -e 'use std.random;var s=FixedString[15].new();for _ in 0..15:s.push_byte(range_i32(48,123) as u8);write(s.as_view())'

# Pick five random words from every line
with -e 'use std.random;for line in stdin.lines(){var a=/\s+/.split(line);var i=a.len32();while i>1{i-=1;let j=range_i32(0,i+1);let x=a[i];a[i]=a[j];a[j]=x};let p=[a[j] for j in 0..min(5,a.len32())];print(p.join(" "))}' <example.txt
```

Potential design changes:

- Add iterator `sum` and `product`, integer `gcd`, `lcm`, and `is_prime` to the
  appropriate standard modules.
- Add `shuffle`, `choose`, `choose_multiple`, and reservoir `sample` to
  `std.random`, implemented once and tested for bias.
- Add lazy `permutations()` and `combinations()` iterators. Lazy results avoid
  forcing factorial-size allocations and compose with `take`.
- Add random string generation from an explicit alphabet, for example
  `random_string(10, ascii_lowercase)`.
- Provide a cryptographically secure RNG and require it for password helpers.
  The shorter API must not make a non-cryptographic password generator look
  safe.

These are library gaps, not evidence that the core language needs more syntax.
One well-designed method can collapse dozens of characters while improving
correctness and reuse.

## Missing safe date and time surface

Perl's `DateTime` and timezone modules provide wall time, calendar fields,
formatting, timezone conversion, and calendar arithmetic. With's cookbook must
drop through `c_import("time.h")`, raw pointers, `unsafe`, C field names, and
manual formatting. Even Unix epoch seconds use `std.libc` because
`std.time.now()` currently returns the wrong clock and unit, tracked in
[#657](https://github.com/withlang-dev/with/issues/657).

Affected one-liners (8):

```sh
# Print Unix epoch seconds
with -e 'use std.libc;print_i64(time(null))'

# Print GMT
with -e 'use c_import("time.h");var t=unsafe{time(null)};let x=unsafe{gmtime(&raw mut t)};print(f"{unsafe{x.tm_year}+1900}-{unsafe{x.tm_mon}+1:02}-{unsafe{x.tm_mday}:02} {unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02} GMT")'

# Print local computer time
with -e 'use c_import("time.h");var t=unsafe{time(null)};let x=unsafe{localtime(&raw mut t)};print(f"{unsafe{x.tm_year}+1900}-{unsafe{x.tm_mon}+1:02}-{unsafe{x.tm_mday}:02} {unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}")'

# Print local time as H:M:S
with -e 'use c_import("time.h");var t=unsafe{time(null)};let x=unsafe{localtime(&raw mut t)};print(f"{unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}")'

# Print yesterday's date
with -e 'use c_import("time.h");var t=unsafe{time(null)}-86400;let x=unsafe{localtime(&raw mut t)};print(f"{unsafe{x.tm_year}+1900}-{unsafe{x.tm_mon}+1:02}-{unsafe{x.tm_mday}:02}")'

# Print the local date and time 14 months, 9 days, and 7 seconds ago
with -e 'use c_import("time.h");var t=unsafe{time(null)};var x=unsafe{localtime(&raw mut t)};unsafe{x.tm_mon=x.tm_mon-14;x.tm_mday=x.tm_mday-9};t=unsafe{mktime(x)}-7;x=unsafe{localtime(&raw mut t)};print(f"{unsafe{x.tm_year}+1900}-{unsafe{x.tm_mon}+1:02}-{unsafe{x.tm_mday}:02} {unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}")'

# Prepend GMT timestamps
with -e 'use c_import("time.h");fn stamp(u:bool){var t=unsafe{time(null)};let x=if u:unsafe{gmtime(&raw mut t)} else:unsafe{localtime(&raw mut t)};f"{unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}"};for l in stdin.lines():print(stamp(true)++"\t"++l)' <logfile

# Prepend local timestamps
with -e 'use c_import("time.h");fn stamp(u:bool){var t=unsafe{time(null)};let x=if u:unsafe{gmtime(&raw mut t)} else:unsafe{localtime(&raw mut t)};f"{unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}"};for l in stdin.lines():print(stamp(false)++"\t"++l)' <logfile
```

Potential design changes:

- Fix `std.time.now()` to return Unix seconds and keep monotonic nanoseconds on
  a distinct `Instant`/clock API.
- Add `SystemTime`, `DateTime`, `Utc`, local timezone conversion, and a safe
  calendar-field view.
- Add concise, checked formatting for common ISO and time-only forms, plus a
  general format API.
- Model calendar periods separately from fixed durations. “One day ago” and
  “14 months ago” must respect timezone transitions and month lengths rather
  than subtracting a guessed number of seconds.
- Add a reusable line timestamp adapter after the underlying clock and timezone
  semantics are correct.

This is the clearest high-priority group: the verbosity comes almost entirely
from crossing an unsafe C boundary that ordinary users should never need to
see.

## Missing Unicode and text conveniences

Perl has compact, Unicode-aware operations such as `.chars`, `.words`,
`.wordcase`, `.trim-leading`, `.trim-trailing`, and transliteration. With can
perform the same work, but currently reaches for regex match vectors, capture
objects, manual byte loops, or replacement regexes. The correct distinction
between bytes, code points, and grapheme clusters is valuable; the missing part
is a pleasant API for each level.

Affected one-liners (11):

```sh
# Count grapheme clusters on each line
with -n 'print_i64(/\X/g.find_all(line).len())' <example.txt

# Count words on each line
with -n 'print_i64(/\S+/.find_all(line).len())' <example.txt

# Find a string's length in grapheme clusters
with -e 'print_i64(/\X/g.find_all("storm in a teacup").len())'

# ROT13 a file
with -e 'let a="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";let b="NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm";for line in stdin.lines():print(/[A-Za-z]/g.replace_all_fn(line,(c:&Captures)=>b.slice(a.index_of(c.get(0).unwrap().text),a.index_of(c.get(0).unwrap().text)+1)))' <example.txt

# Uppercase the first word of each line
with -p 'if line =~ /^(\w+)/:line=/^\w+/.replace(line,$1.upper())' <example.txt

# Invert ASCII letter case
with -e 'for l in stdin.lines(){var s="";for i in 0..l.len(){let c=l.byte_at(i);s=s++str_from_byte(if is_lower(c):c-32 else if is_upper(c):c+32 else:c)};print(s)}' <example.txt

# Word-case each line
with -e 'for line in stdin.lines():print(/\b\w/g.replace_all_fn(line,(c:&Captures)=>c.get(0).unwrap().text.upper()))' <example.txt

# Strip leading whitespace
with -p 'line=/^\s+/.replace(line,"")' <example.txt

# Strip trailing whitespace
with -p 'line=/\s+$/.replace(line,"")' <example.txt

# Print lines at least 80 grapheme clusters long
with -n 'if /\X/g.find_all(line).len()>=80:print(line)' <example.txt

# Print the first word of each line
with -n 'if line =~ /(\S+)/:print($1)' <example.txt
```

Potential design changes:

- Add `graphemes()`, `grapheme_len()`, and a documented Unicode `words()`
  iterator. Keep `len()` byte-oriented or otherwise unambiguous.
- Add `trim_start`, `trim_end`, `wordcase`, and `swapcase` methods with precise
  Unicode semantics.
- Add `translate(from, to)` for one-to-one character mapping; ROT13 then becomes
  data rather than a regex callback program.
- Make regex replacement callbacks expose the whole-match text directly, so
  callers do not need `c.get(0).unwrap().text`.
- Add `first_word()` only if its segmentation policy is clear; a general
  `words().next()` is more composable.

Unicode convenience must not turn `len()` into a context-dependent mystery.
Separate byte, scalar, and grapheme APIs can be both explicit and concise.

## Missing collection-analysis vocabulary

Perl's `comb`, `rotor`, `Set`, `Bag`, set operators, and `invert` make short
work of n-grams, frequency tables, similarity coefficients, containment, and
position indexes. With has typed maps and sets, but the one-liners must build
every intermediate collection and every counting/indexing loop manually.

Affected one-liners (10):

```sh
# Print unique n-grams
with -e 'let s="banana";let n=2;let g:BTreeSet[str]=[s.slice(i,i+n) for i in 0..=s.len32()-n];for x in g.items():print(x)'

# Print n-gram occurrence counts
with -e 'let s="banana";let n=2;var c:BTreeMap[str,i32]=BTreeMap.new();for i in 0..=s.len32()-n{let g=s.slice(i,i+n);c.insert(g,c.get(g).unwrap_or(0)+1)};for (g,k) in c.items():print(f"{g} {k}")'

# Print word occurrence counts
with -e 'let w=/\s+/.split(stdin.lines()[0]);var c:BTreeMap[str,i32]=BTreeMap.new();for x in w:c.insert(x,c.get(x).unwrap_or(0)+1);for (x,n) in c.items():print(f"{x} {n}")' <example.txt

# Print the Dice coefficient over sets of 1-grams
with -e 'fn s(a:str)->BTreeSet[str]:[a.slice(i,i+1) for i in 0..a.len()];let x=s("banana");let y=s("anna");let z=x.intersection(&y);print(f"{2.0*z.len() as f64/(x.len()+y.len()) as f64}")'

# Print the Jaccard coefficient over sets of 1-grams
with -e 'fn s(a:str)->BTreeSet[str]:[a.slice(i,i+1) for i in 0..a.len()];let x=s("banana");let y=s("anna");let z=x.intersection(&y);let u=x.union(&y);print(f"{z.len() as f64/u.len() as f64}")'

# Print the overlap coefficient over sets of 1-grams
with -e 'fn s(a:str)->BTreeSet[str]:[a.slice(i,i+1) for i in 0..a.len()];let x=s("banana");let y=s("anna");let z=x.intersection(&y);print(f"{z.len() as f64/min(x.len(),y.len()) as f64}")'

# Print cosine similarity over sets of 1-grams
with -e 'fn s(a:str)->BTreeSet[str]:[a.slice(i,i+1) for i in 0..a.len()];let x=s("banana");let y=s("anna");let z=x.intersection(&y);print(f"{z.len() as f64/sqrt_f64((x.len()*y.len()) as f64)}")'

# Build an index of character positions
with -e 'let s="banana";var m:BTreeMap[str,str]=BTreeMap.new();for i in 0..s.len(){let c=s.slice(i,i+1);let v=m.get(c).cloned().unwrap_or("");m.insert(c,v++if v=="":f"{i}" else:f" {i}")};for (c,i) in m.items():print(f"{c}: {i}")'

# Build an index of word positions
with -e 'let w=/\s+/.split(stdin.lines()[0]);var m:BTreeMap[str,str]=BTreeMap.new();for i in 0..w.len(){let x=w[i];let v=m.get(x).cloned().unwrap_or("");m.insert(x,v++if v=="":f"{i}" else:f" {i}")};for (x,i) in m.items():print(f"{x}: {i}")' <example.txt

# Print lines containing all vowels
with -n 'if line.contains("a") and line.contains("e") and line.contains("i") and line.contains("o") and line.contains("u"):print(line)' <example.txt
```

Potential design changes:

- Add lazy `ngrams(n)` over graphemes, scalars, bytes, and generic iterators.
- Add `frequencies()` returning a typed map and `positions_by_value()` returning
  a map of values to position vectors.
- Add `to_set`, `contains_all`, and concise set construction with element type
  inference.
- Consider a `Bag[T]`/multiset if frequency algebra is common enough; otherwise
  a frequency-map helper gives most of the value with less surface area.
- Put Dice, Jaccard, overlap, and cosine formulas in an analysis package rather
  than the core language. The standard library mainly needs the set and
  frequency primitives that make such packages small.

The repeated similarity commands reveal a missing reusable abstraction, but
not necessarily four missing standard-library functions. Strong collection
building blocks plus ecosystem packages fit With's mission better than a
grab-bag of metrics in the prelude.

## Missing codecs, serializers, and HTML tools

The Perl commands load mature modules for Base64, URI encoding, HTML entities,
JSON, and HTML stripping. With either lacks the equivalent module or exposes
only a low-level writer. The cookbook consequently implements byte-level codecs
and JSON framing inside the shell command. The standard-library plan already
calls out `std.encoding.base64`; this group is strong evidence for that
priority.

Affected one-liners (8):

```sh
# Base64-encode each line
with -e 'fn c(t:str,n:i32):t.slice(n,n+1);let t="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";for s in stdin.lines(){var o="";var i=0;while i<s.len32(){let a=s.byte_at(i);let h=i+1<s.len32();let b=if h:s.byte_at(i+1) else:0;let k=i+2<s.len32();let d=if k:s.byte_at(i+2) else:0;o=o++c(t,a>>2)++c(t,(a&3)<<4|b>>4)++(if h:c(t,(b&15)<<2|d>>6) else:"=")++(if k:c(t,d&63) else:"=");i+=3};print(o)}' <example.txt

# Base64-decode each line
with -e 'fn v(c:i32):if c<65:c+4 else if c<91:c-65 else if c<97:c/4+50 else:c-71;for s in stdin.lines(){var o=StringBuilder.new();var i=0;while i<s.len32(){let a=v(s.byte_at(i));let b=v(s.byte_at(i+1));let c=s.byte_at(i+2);let d=s.byte_at(i+3);o.push_byte((a<<2|b>>4) as u8);if c!=61:o.push_byte((b<<4|v(c)>>2) as u8);if d!=61:o.push_byte((v(c)<<6|v(d)) as u8);i+=4};print(o.to_str())}' <base64.txt

# URL-escape a string
with -e 'let s="a b/c?d=é";var o=StringBuilder.new();for i in 0..s.len32(){let c=s.byte_at(i);if is_alnum(c) or c==45 or c==46 or c==95 or c==126:o.push_byte(c as u8) else:o.push_str(f"%{c:02X}")};print(o.to_str())'

# URL-unescape a string
with -e 'fn h(c:i32):if c<58:c-48 else:c%32+9;let s="a%20b%2Fc%3Fd%3D%C3%A9";var o=StringBuilder.new();var i=0;while i<s.len32(){if s.byte_at(i)==37{o.push_byte((h(s.byte_at(i+1))*16+h(s.byte_at(i+2))) as u8);i+=3}else{o.push_byte(s.byte_at(i) as u8);i+=1}};print(o.to_str())'

# HTML-encode a string
with -e 'let s="<a href=\"x\">Tom & Sue</a>";print(s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("\x27","&#39;"))'

# Convert input lines to a JSON array
with -e 'use std.json;var s="[";var n=0;for l in stdin.lines(){if n>0:s=s++",";s=s++JsonWriter.new().value_str(l).finish();n+=1};print(s++"]")' <example.txt

# JSON-encode the files in the current directory
ls | with -e 'use std.json;var s="[";var n=0;for l in stdin.lines(){if n>0:s=s++",";s=s++JsonWriter.new().value_str(l).finish();n+=1};print(s++"]")'

# Download a page and strip HTML tags
with -e 'use std.http;write(/<[^>]+>/g.replace_all(https_get("https://example.com"),""))'
```

Potential design changes:

- Implement `std.encoding.base64` with checked standard and URL-safe variants.
- Add standards-named percent-encoding operations that distinguish a full URL,
  a path segment, a query component, and form encoding.
- Add `std.encoding.html.escape` and a real HTML text tokenizer/extractor.
  Regex tag stripping is not correct for script/style content, comments, or
  malformed markup.
- Implement generic `Serialize` for `Vec[T]` and a top-level `json.encode(value)`
  so arrays do not require manual commas and quoting.
- Make package-qualified `use` in one-liners able to resolve and fetch ecosystem
  codecs, analogous to Perl's module loading but integrated with With's package
  model.

Codec APIs need explicit error behavior and standards profiles. A short decoder
that accepts malformed Base64 or invalid percent escapes silently would only
move the bug out of sight. Full HTML entity decoding remains in
[`impossible_oneliners.md`](impossible_oneliners.md) until a complete reusable
implementation exists.

## Missing domain value types

IP addresses and colors are structured values, but the With recipes manipulate
their textual or packed representation directly. Perl's radix, buffer, and
formatting facilities make that manipulation compact; a better With design
would make it unnecessary.

Affected one-liners (4):

```sh
# Convert an IP address to an unsigned integer
with -e 'let a="127.0.0.1".split(".");print(f"{a.fold(0u32,(n,x)=>n*256+parse(x) as u32)}")'

# Convert an unsigned integer to an IP address
with -e 'let n=2130706433u32;print(f"{n>>24}.{n>>16&255}.{n>>8&255}.{n&255}")'

# Convert an HTML color to decimal RGB
echo '#ffff00' | with -e 'fn h(c:i32):if c<58:c-48 else:c%32+9;for s in stdin.lines():print(f"{h(s.byte_at(1))*16+h(s.byte_at(2))} {h(s.byte_at(3))*16+h(s.byte_at(4))} {h(s.byte_at(5))*16+h(s.byte_at(6))}")'

# Convert decimal RGB to an HTML color
echo '255 255 0' | with -n 'let a=line.split(" ");print(f"#{parse(a[0]):02x}{parse(a[1]):02x}{parse(a[2]):02x}")'
```

Potential design changes:

- Finish the planned `IpAddr`/`Ipv4Addr` surface with checked parsing,
  formatting, `from_u32_be`, and `to_u32_be`.
- Add a small `Rgb` or `Color` type in an ecosystem graphics/color package,
  with checked HTML parsing and formatting.
- Add general radix parsing and byte-order helpers for lower-level code, while
  keeping them underneath the domain types.
- Let destructuring expose components concisely: an `Rgb` value should make
  `(r, g, b)` available without reparsing its source text.

The byte order must be in the API name or type contract. A magically short
`IpAddr as u32` cast would be ambiguous across network and host order and is not
an ergonomic win.

## Limited range and sequence generation

Perl ranges can walk characters and lexicographic strings, and its sequence
operators combine naturally with filtering and output. With currently uses
ASCII integer ranges, `str_from_byte`, nested loops, and an allocated formatted
vector.

Affected one-liners (3):

```sh
# Generate the alphabet
with -e 'for c in 97..123:print(str_from_byte(c))'

# Generate every string from a through zz
with -e 'fn c(x:i32):str_from_byte(x);for a in 97..123:print(c(a));for a in 97..123{for b in 97..123:print(c(a)++c(b))}'

# Generate the even numbers from 1 through 100
with -e 'let a=[f"{x}" for x in 1..=100 if x%2==0];print(a.join(" "))'
```

Potential design changes:

- Add a real Unicode scalar/`char` type and ranges over it, so `'a'..='z'` is
  typed character iteration rather than integer-to-string conversion.
- Add `step_by` to ranges and iterators.
- Let generic display/join formatting print an iterator or collected numeric
  vector without first mapping every element to an f-string.
- Put spreadsheet-like lexicographic string sequences in a named library
  iterator. Extending the range operator from `"a"` to `"zz"` raises questions
  about alphabets, case, Unicode, and carry rules that syntax alone cannot
  answer.

Character ranges are a broadly useful language feature. Arbitrary string
ranges are much more policy-heavy and should earn their place through real use
cases beyond matching Perl's character count.

## Explicit numeric formatting policy

Perl's generic `say` chooses a compact default rendering for mathematical
constants. With output functions accept strings, and exact decimal precision is
spelled with an f-string format specification. These two commands cross the
20% threshold even though the absolute difference is small.

Affected one-liners (2):

```sh
# Print PI to 15 decimal places
with -e 'print(f"{PI:.15f}")'

# Print E to 15 decimal places
with -e 'print(f"{E:.15f}")'
```

Potential design changes:

- Let `print` accept primitive numeric values through compiler-known `Display`
  formatting.
- Define a documented shortest-round-trip default for floats, enabling
  `print(PI)` when exact fixed precision is not required.
- Consider concise named formatting helpers only if they improve ordinary code;
  the existing f-string is explicit and composable.

This is likely acceptable verbosity. The recipes specifically request 15
decimal places, and `:.15f` records that requirement instead of relying on a
runtime default. `POSSIBLE_IMPROVE` identifies a size difference, not an
automatic mandate to remove useful precision.

## Cross-cutting priorities

The largest gains do not require making With look like Perl. They come from a
small number of reusable surfaces:

1. Finish lazy iterator aggregation and stream adapters.
2. Add generic scalar printing while keeping formatting explicit when output
   shape matters.
3. Fill the planned Base64, time, IP-address, and Unicode-library gaps.
4. Add frequency, n-gram, selection, and shuffle helpers to collections and
   iterators.
5. Make `-p` expression results useful as transforms without introducing a
   language-wide implicit topic.
6. Close the parity gaps the 2026-09-03 audit filed: persistent state and
   `last`/END in `-n`/`-p` (#957), file operands and `-i` (#958),
   `str.fields()` and `parse_i64` (#959), `Vec.sort` and `str.reverse`
   (#960), the jq surface on `JsonView` and `std.json` as an implicit import
   (#961) — each with its matrix rows as a `cli-selfhost-one-liner-tests`
   case, so parity is a battery invariant.

The markers are most valuable as an abstraction audit. Repeated manual loops
usually identify a missing library primitive; repeated `unsafe` identifies a
missing safe boundary; repeated `unwrap` or `parse` identifies safety ceremony
that should become concise but must not disappear. Optimizing only the shell
spelling would miss those deeper causes.
