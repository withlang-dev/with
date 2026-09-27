# 15.8 Regular Expressions

Regular expressions are first-class language surface, not a
CLI-only feature. (The one-liner behavior in §18.5b.6 is this
section applied to generated entry sources.)

**Regex literals.** `/pattern/flags` is a literal of type `Regex`
(`std.regex`):

```
let r = /hello/i
r.is_match("HELLO")                  // true
let words = /\w+/g
```

Flags: `g` (global), `i` (case-insensitive), `m` (multi-line),
`s` (dot matches newline), `x` (extended), `U` (ungreedy),
`u` (Unicode). An unknown flag is a compile-time error. The pattern
syntax is owned by `std.regex` (a PCRE2-derived engine; see
`docs/libstd-spec.md` for the full `Regex`, `Match`, and `Captures`
API: `compile`, `compile_flags`, `is_match`, `find`, `find_all`,
`captures`, `replace`, ...).

**Match operators.** `=~` (matches) and `!~` (does not match) test a
`str` against a `Regex`:

```
if line =~ /error/: alert(line)
if line !~ /debug/: keep(line)
```

Both produce `bool`. They sit at precedence level 3 with `==`/`in`
(§9.9) and are non-associative. The right operand may be a regex
literal or any `Regex` value.

**Capture bindings.** When the condition of an `if` (or a clause of
a chained `if let`, §9.7) is a **direct positive** match whose right
side is a regex literal, the captures bind in the success branch:
`$0` (whole match), `$1`..`$N` (numbered groups), and `$name` (named
groups, declared `(?<name>...)`):

```
if line =~ /status=(\d+)/:
    print($1)                         // scoped to this branch

if line =~ /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/:
    log(f"{$level}: {$msg}")
```

This is a refutable-binding condition form, like `if let`: the
bindings exist only where the match succeeded. The `$` sigil keeps
captures in their own namespace — they can never collide with the
no-shadowing rule (§29.8). `!~` and compound boolean conditions do
not create capture bindings (nest the logic when combining capture
use with other conditions). For everything else — iteration over
matches, replacement, splitting — use the `std.regex` API
explicitly.

---
