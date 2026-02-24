# Example: JSON Parser

Recursive descent JSON parser. Demonstrates algebraic data types for tree
representation, pattern matching for parsing, generators for lazy traversal,
and pipeline operators for composition.

## Files

```
json.w    Tokenizer, parser, accessors, tree walker, demo
```

## What It Demonstrates

**Algebraic data types** — `JsonValue` is an enum with six variants: `Null`,
`Bool(bool)`, `Number(f64)`, `Str(str)`, `Array(Vec[JsonValue])`,
`Object(Vec[(str, JsonValue)])`. The type system enforces exhaustive handling.

**Recursive descent parsing** — The parser consumes tokens and recursively
builds the tree. `parse_value()` dispatches on the current token to
`parse_object()`, `parse_array()`, or a leaf constructor.

**Error types with positional context** — `JsonError` variants carry the byte
position and contextual description. Every error message tells you *where*
and *what went wrong*.

**Generator-based tree traversal** — `gen fn walk_leaves(value, path)` lazily
walks the JSON tree, yielding `(path_string, leaf_value)` pairs. The generator
recurses through arrays and objects, building dotted paths like `meta.stats.stars`.

**Optional chaining with borrowed helper accessors** — `get()` / `index()`
return `Option[&JsonValue]`. Since auto-generated enum `.as_variant()` accessors
consume by value (§4.4), this example adds `as_str_ref()`, `as_number_ref()`,
and `as_array_ref()` for borrowed tree traversal. Combined with `?.` and `??`,
this enables `value.get("name")?.as_str_ref() ?? "unknown"`.

## Language Features

| Feature | Location |
|---------|----------|
| Algebraic data types (enum) | `JsonValue` — 6 variants with associated data |
| Recursive pattern matching | `parse_value`, `walk_leaves` — nested match on variants |
| Or-patterns | Tokenizer — `Some(b' ') \| Some(b'\\t') \| ...` |
| Match guards | Tokenizer — `Some(ch) if ch >= b'0' and ch <= b'9'` |
| Error enums | `JsonError` — 5 variants with position info |
| `?` propagation | Throughout — `tokenizer.next_token()?`, `parser.parse_value()?` |
| `.Variant` shorthand | Throughout — `.Null`, `.TString(s)`, `.UnexpectedEof(...)` |
| Borrowed helper accessors | `JsonValue` — `.as_str_ref()`, `.as_number_ref()`, `.as_array_ref()` |
| Generators (`gen fn`) | `walk_leaves` — lazy recursive tree traversal |
| Pipeline operators `\|>` | `to_string` — `iter \|> map \|> collect \|> join` |
| `with` blocks (mutation) | `read_string`, `parse_array`, `parse_object` — buffer building |
| Optional chaining (`?.`) | Main demo — `value.get("name")?.as_str_ref()` |
| `??` coalescing | Main demo — `?? "unknown"`, `?? 0.0` |
| String interpolation | `walk_leaves` — `"{path}[{i}]"`, `"{path}.{key}"` |
| Default field values | `Tokenizer { pos: usize = 0 }` |
| Implicit `for` iteration | `for (key, val) in entries:`, `for (input, description) in bad_inputs:` |
