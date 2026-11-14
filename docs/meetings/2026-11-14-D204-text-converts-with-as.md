# D204 — Text converts with `as`: `"42" as i32` panics on bad text; a type is not callable for parsing and is not a pipeline stage (amends D203)

**Laws:** 9 (one spelling of one meaning: `as` is already With's explicit
conversion), 1 (the fallible form is `text.parse()`, typed by the demand).

**Date:** 2026-11-14. **Status:** ruled by Eric, the same day as D203,
before any of D203's call form was built. §15.5 and §4.2.6 (spec v7.58)
carry it. NOT YET implemented: `"42" as i32` is still the error "cannot
cast `str` to `i32`".

**What changes from D203.** D203's spelling of the conversion, `i32(text)`,
`i32(text, base: 16)` and `text |> i32`, is withdrawn. The conversion is
`text as T`. A base is given only to `text.parse(base: N)`, which returns
`Option[T]`; with a panic it is `text.parse(base: N).unwrap()`.

**What stands from D203.** Everything else: one shared implementation
behind the cast and `parse()`; the whole text is the value; With's integer
notation with no base, digits of the stated base with one (no prefix read);
the floating-point rules with `inf`, `infinity` and `nan`; overflow fails
and says so; the panic's message; `min`, `max`, `inf` and `nan` on the
numeric types; no `parse[i32]`, `parse_i32`, `toInt` or `try_i32`.

**`as` and failure.** Text is the one cast that can fail. Every other cast
keeps what it does: an integer cast wraps, a float to an integer truncates
and saturates, a wide float to a narrow one may become infinity (D124,
D125). So `"300" as u8` panics while `300 as u8` is 44, and `"1e40" as f32`
panics while `1.0e40 as f32` is infinity: text states a value, and a value
the type cannot hold is not that type's value.

**What reopens it.** Callable types becoming a general capability of the
language for construction and conversion, decided on their own merits.

Eric's two texts follow, as he gave them. Their code blocks arrived with
their line breaks lost; they are restored here and nothing else is
changed. Their examples comment with `#`; With source comments with `//`.

---

**Yes. I think `as` may actually be the better solution, and I should have considered it before proposing callable types.**

With already has `as` for explicit conversions. Why invent `i32(text)` when the language already has a natural way of saying *convert this value to that type*?

Consider:

```
let n = "42" as i32
let pi = "3.14" as f64
let hex = "0x2A" as i32
let flag = true as i32
```

This is concise, readable, and consistent with existing With syntax.

## The distinction I'd make

**`as` means: convert this value to the requested type, or fail according to the conversion's defined rules.**

For text parsing, that means panic on invalid input.

```
"42" as i32       # 42
"abc" as i32      # Panic
"3.14" as f64     # 3.14
```

For numerical casts, existing `as` semantics remain unchanged. We shouldn't accidentally redefine numeric narrowing or distinct-type conversions just because we added string parsing.

And the fallible alternative remains:

```
let n: i32 = text.parse() ?? 0
```

That gives programmers a clean choice:

| Expression      | Meaning                                |
| --------------- | -------------------------------------- |
| `text as i32`   | I require an integer; panic if invalid |
| `text.parse()`  | Try parsing; return `Option[T]`        |
| `number as i32` | Existing numeric cast semantics        |

No implicit conversions. No extra generic syntax.

## But what about explicit bases?

This is the one complication.

```
"2A" as i32
```

Should fail because there's no prefix and decimal is the default.

The obvious explicit-base API remains:

```
let n: i32 = "2A".parse(base: 16).unwrap()
```

That's a little longer, but it expresses two independent choices: the parsing base and what happens on failure.

We could still retain `i32("2A", base: 16)` as a convenience, but then we'd have two spellings for ordinary conversion:

```
"42" as i32
i32("42")
```

And that conflicts with With's preference for one straightforward spelling of an operation.

I wouldn't introduce both without a good reason.

## What about the pipe operator?

Here's the real tradeoff.

```
"42" |> i32
```

is beautiful for pipelines.

But it implies that `i32` is callable, so With needs to decide whether callable types are a genuine general capability or merely an additional spelling for `as`.

I wouldn't introduce callable types *just* to support parsing.

If callable types eventually become useful for construction and conversion throughout With, that could justify them independently.

## My recommendation

I'd now favor:

- `text as T` — direct conversion, with text parsing panicking on failure.
- `text.parse()` — fallible parsing, using contextual type inference.
- `text.parse(base: N)` — explicit-base parsing.
- Keep existing `as` behavior for other conversions.
- Don't introduce callable numeric types merely to solve this problem.

The important benefit is that **the programmer already knows `as`**. We don't have to teach a new concept.

And that's precisely the attention to detail you've been talking about: noticing that the language may already contain the right abstraction instead of adding another one.

There's just one question I'd resolve before settling it:

**Do you want `as` to mean a general explicit conversion operation, even when that conversion can panic?**

If yes, I think `"42" as i32` is the most natural With spelling we've considered so far.

---

**Yes. That's exactly the design I'd recommend if we choose `text as T` as With's canonical conversion syntax.**

The decision should be complete, not leave behind competing spellings.

| Spelling               | Decision                                    |
| ---------------------- | ------------------------------------------- |
| `"42" as i32`          | Keep — direct conversion, panics on failure |
| `i32("42")`            | No — types aren't callable for parsing      |
| `i32("2A", base: 16)`  | No                                          |
| `"42" \|> i32`         | No — a type isn't a pipeline function       |
| `text.parse()`         | Keep — fallible, returns `Option[T]`        |
| `text.parse(base: 16)` | Keep — fallible parsing with explicit base  |

For an explicit base with panic-on-failure behavior:

```
let n: i32 = "2A".parse(base: 16).unwrap()
```

That is a little longer, but explicit-base parsing is less common, and I wouldn't add a whole second conversion syntax to shorten it.

The ordinary case becomes beautifully simple:

```
let n = "42" as i32
let pi = "3.14" as f64
```

**The pipe operator itself is unchanged.** It remains useful for chaining actual functions and transformations. We simply don't teach type conversion through pipes in the idiomatic guide.

One important implementation detail: the existing `as` semantics for numeric casts and distinct types remain intact. Only string-to-`Parse`-type conversion gains the new panic-on-failure behavior.

I'd also revise the recently added §15.5 specification passage to describe `as`, rather than leaving the callable-type rule alongside it.

**My ruling: one conversion syntax, `as`; one fallible parsing API, `parse()`. No callable-type or pipe conversion forms.**

That is more coherent than supporting all three simply because we can.
