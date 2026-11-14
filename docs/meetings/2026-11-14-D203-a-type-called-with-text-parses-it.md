# D203 — A type called with text parses it: `i32(text)` panics, `text.parse()` is the `Option`; two modes, With's notation or digits in a stated base

**Laws:** 1 (two meanings remaining, the programmer spells the choice), 2
(the demand types `text.parse()`), 9 (one spelling of one meaning: no
`parse[i32]`, `parse_i32`, `toInt` or `try_i32`), 11 (the failure policy is
the programmer's, chosen by the operation written).

**Date:** 2026-11-14. **Status:** ruled by Eric. §15.5 (spec v7.56) carries
the first sentences; the rest of the ruling is NOT YET in the spec and NOT
YET implemented. The compiler is non-compliant with all of it.

**Context.** `"42".parse[i32]()` was refused with "cannot infer generic
method type parameter 'T'". #598 had ruled explicit type arguments off free
functions; the record did not say what a method call does when no demand
reaches it. The survey (Swift `Int("42")`, Python `int("42")`, C#
`int.Parse`, Rust `parse::<i32>()`, Zig `parseInt(T, s, base)`, C `strtol`
and `strtod`) showed one language using a bracket form and the rest naming
the type as the function or the receiver. Eric chose the type as the
function, a panic on bad text, and `"42" |> i32` as the pipeline spelling.
With had no way to write infinity, NaN or a numeric limit in source; the
ruling adds them as members of the types.

**What reopens it.** A real program that needs a prefix read under an
explicit base, or a float in another base.

**Where this record differs from §15.5 as blessed earlier the same day.**
§15.5's example panic reads `panic: i32("abc"): "abc" is not an i32`; the
ruling's reads `panic: cannot parse i32 from "abc"` with the source
location on the next line. The ruling is later and governs; §15.5 is
amended by the diff that brings the rest of these rules into the spec.

The ruling follows, as Eric gave it. Its code blocks arrived with their
line breaks lost; they are restored here and nothing else is changed. Its
examples comment with `#`; With source comments with `//`.

---

I'd keep `i32(text, base: 16)`, use `base` rather than `radix`, and make the parsing rules exceptionally consistent.

The most important decision I'd make is this:

**Without `base:`, parse With's ordinary numeric notation. With `base:`, parse digits in exactly that base, without interpreting prefixes.**

That gives us two simple, predictable modes rather than a collection of exceptions.

## 1. The spelling I'd choose

**Direct conversion — panics on failure**

```
i32("42")                 # 42
f64("3.14")               # 3.14
i32("0x2A")               # 42
i32("2A", base: 16)       # 42
```

**Pipeline — same operation, different composition**

```
"42" |> i32
"2A" |> i32(base: 16)
```

**Fallible parsing — returns `Option[T]`**

```
let n: i32 = text.parse() ?? 0
let n: i32 = text.parse(base: 16) ?? 0
```

These are proposed rules, not assertions that the current compiler implements every form.

I wouldn't introduce `parse_i32`, `toInt`, `parse[i32]`, or `try_i32` as additional spellings. The three existing concepts—type construction, pipelines, and contextual `parse()`—cover the use cases.

And I'd restrict `T(text)` to types implementing `Parse`. It shouldn't automatically make `i32(3.9)` an alternative to `3.9 as i32`.

## 2. Integer parsing rules

I recommend the following precise behavior.

| Text         | Expression             | Result |
| ------------ | ---------------------- | ------ |
| `"42"`       | `i32("42")`            | 42     |
| `"-42"`      | `i32("-42")`           | -42    |
| `"+42"`      | `i32("+42")`           | 42     |
| `"042"`      | `i32("042")`           | 42     |
| `"0x2A"`     | `i32("0x2A")`          | 42     |
| `"0X2a"`     | `i32("0X2a")`          | 42     |
| `"0b101010"` | `i32("0b101010")`      | 42     |
| `"0o52"`     | `i32("0o52")`          | 42     |
| `"1_000"`    | `i32("1_000")`         | 1000   |
| `"2A"`       | `i32("2A")`            | Panic  |
| `"2A"`       | `i32("2A", base: 16)`  | 42     |
| `"0b1"`      | `i32("0b1", base: 16)` | 177    |
| `"0x1"`      | `i32("0x1", base: 16)` | Panic  |

The last two are important.

When the programmer explicitly supplies `base: 16`, **the whole text is hexadecimal digits**. In that mode, `b` is a digit and `x` isn't.

There's no need for the compiler to guess whether the programmer meant a prefix.

If they want With's prefix notation, they simply omit `base:`.

This is the rule I'd teach, and I wouldn't special-case prefix-looking text.

### Additional details

I'd accept bases **2 through 36**, with digits `0–9` and letters `A–Z`, case-insensitively.

Underscores should be accepted only between digits. Not at the beginning, end, next to a sign, or immediately after a prefix. I'd also reject consecutive underscores.

Parsing must consume the entire input. `i32("42abc")` should panic, not return 42.

Whitespace should not be silently trimmed. If the text contains spaces, the programmer can write:

```
line.trim() |> i32
```

No leading-zero octal, no locale-specific interpretation, and no numeric type suffixes inside the string.

Integer overflow or a negative value for an unsigned type should fail, not silently wrap.

## 3. Floating-point parsing

Here I'd deliberately support a little more than With's numeric literal syntax, because real-world data commonly contains infinity and NaN.

| Text             | Result            |
| ---------------- | ----------------- |
| `"3.14"`         | 3.14              |
| `"-2.5"`         | -2.5              |
| `"1e3"`          | 1000.0            |
| `"1E-3"`         | 0.001             |
| `"inf"`          | Positive infinity |
| `"-inf"`         | Negative infinity |
| `"Infinity"`     | Positive infinity |
| `"NaN"`          | Quiet NaN         |
| `"nan(payload)"` | Panic             |
| `"0x1.8p3"`      | Panic             |
| `" 3.14"`        | Panic             |

I'd accept `inf`, `infinity`, and `nan` case-insensitively.

Floats shouldn't accept `base:`. That argument is for integer parsing.

Finite decimal text should use correctly rounded IEEE floating-point conversion. I'd make overflow from a finite decimal to infinity an error; if the programmer wants infinity, they can spell it explicitly.

## 4. Numeric constants belong on their types

I agree with the direction you reached in the transcript.

```
f64.inf
-f64.inf
f64.nan
f32.inf
f32.nan
i32.min
i32.max
u64.max
f64.min
f64.max
```

All lowercase.

One detail deserves particular care: **`f64.min` should mean the most negative finite number**, not the smallest positive normal number.

That latter quantity should have a distinct name, such as `f64.min_positive_normal`, if With exposes it.

This avoids a long-standing source of confusion in numeric APIs.

## 5. Failure should be informative, not defensive

You've already chosen the distinction I prefer:

```
i32(text)     # I require this to be an integer.
text.parse()  # This might be an integer.
```

The first form panics on bad input. The second returns `None`.

That's useful because the programmer chooses the failure policy through the operation they're writing—not an extra boolean flag or an arbitrary compiler restriction.

The panic should include the target type, rejected text, and source location:

```
panic: cannot parse i32 from "abc"
  at main.w:12:17
```

For a very long input, the message can truncate the displayed text while retaining the useful location and error category. Overflow should say overflow, not merely "invalid integer."

## 6. One principle I'd make explicit

I'd give text parsing a single shared implementation that both `T(text)` and `text.parse()` use.

They should agree on every accepted string, every base, every overflow condition, and every numeric result.

The only difference should be failure handling.

That sounds like a small implementation detail, but this is exactly the craftsmanship we've been discussing. A programmer should never discover that `i32("0x2A")` understands something that `"0x2A".parse()` doesn't.

## My recommendation

I'd settle these rules without adding any more conversion syntax.

**The final API is small:**

```
i32(text)                 # Direct, panics
i32(text, base: 16)       # Explicit base, panics
text.parse()              # Contextually typed Option
text.parse(base: 16)      # Explicit base, Option
text |> i32               # Pipeline spelling
text |> i32(base: 16)     # Pipeline with base
```

And I'd keep the fundamental distinction:

**Implicit base means With numeric notation. Explicit base means digits in that base.**

It's concise, teachable, and covers ordinary strings, source-like numeric text, hexadecimal dumps, and shell pipelines without introducing competing APIs.

That's the attention to detail I think With should aim for: not the largest number of accepted formats, but **a small set of rules that feel natural, fit together, and keep behaving predictably in every context.**
