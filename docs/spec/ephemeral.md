# 5. Ephemeral Types

### 5.1 Definition

`ephemeral` is a type qualifier that marks a type as second-class.

```
type StrView = ephemeral { ptr: *const u8, len: usize }
```

Ephemeral values may exist as local bindings and function parameters.
They may be returned from functions (with propagation). They may be
captured by non-escaping closures.

Ephemeral values may NOT be stored in struct fields, enum variants,
heap containers, global storage, or escaping closures.

### 5.2 Propagation

Ephemerality propagates through type constructors:

- If `T` is ephemeral, then `Option[T]`, `Result[T, E]`, `(T, U)`, and
  any generic `F[T]` — including heap containers such as `Vec[T]`,
  `HashMap[K, T]`, `Box[T]`, `Rc[T]`, `Arc[T]` — are ephemeral.
- If any field of a struct is ephemeral, the struct is ephemeral. A
  struct definition with ephemeral fields is rejected unless the
  struct itself is marked `ephemeral`.
- A container of an ephemeral element is therefore itself ephemeral,
  and obeys §5.1 like any other ephemeral value: it is a valid local
  or by-value parameter, but it may not **escape** its origin's scope.
  Returning it where the return type is not ephemeral, storing it in a
  heap container or a non-ephemeral struct field, or boxing it is a
  compile error — enforced by borrow-origin tracking, so a container
  that borrows a live outer value (e.g. a batch of handles whose fields
  are all owned, like `Vec[Workspace]`) is unrestricted, while one that
  borrows a stack local it would outlive is rejected. (BDFL ruling
  2026-07-04, revised after reference-implementation review, #625: this
  is the model of Rust lifetimes and Vale regions — control the escape,
  not the container. See `docs/meetings/2026-07-04-D2-625-containers-of-ephemerals-use-a-viral-escape-model-not-an.md` D2.)

### 5.3 Canonical Ephemeral Types

- References: `&T`
- Views: `StrView` / `&str`, `&[T]`
- Lock guards: `MutexGuard[T]`, `RwLockReadGuard[T]`, `RwLockWriteGuard[T]`
- Iterators over borrowed data

### 5.4 Views: Ephemeral vs Storable

View types are pointer-and-length values that reference memory they do
not own. They are ephemeral to prevent dangling.

For long-lived references into owned buffers, use offset-based types:

```
type BufSlice { offset: usize, len: usize } with Copy
```

Pattern: structs store `BufSlice` (storable offsets); accessor methods
compute ephemeral `&str`/`&[u8]` on demand from an owned buffer.

```
type Request {
    buf:     Bytes,
    path:    BufSlice,
    headers: Vec[Header],
}

extend Request:
    fn path_str(self: &Request) -> StrView:
        self.buf.view(self.path.offset, self.path.len)
```

---

### 5.5 Ephemeral Structs

Structs may be marked `ephemeral` to hold references and views.
This is the idiomatic pattern for parsers, tokenizers, iterators,
and any "processing context" that borrows from input data:

```
type Token = ephemeral {
    text: StrView,          // borrows from source
    kind: TokenKind,
    span: Span,
}

type Parser = ephemeral {
    source: StrView,        // borrows from input
    pos: usize,
}

extend Parser:
    fn next_token(mut self: Self) -> Option[Token]:
        // ... returns Token borrowing from self.source
```

Ephemeral structs follow all the same rules as ephemeral values
(§5.1): they can be local bindings, parameters, and return values,
but cannot be stored in long-lived containers or non-ephemeral
structs.

```
// OK: local use, pattern matching, passing around
let tok = parser.next_token()?
match tok.kind:
    .Ident   => handle_ident(tok.text)
    .Number  => handle_number(tok.text)
    .String  => handle_string(tok.text)

// OK: for-loop processes each token — tok drops at iteration end
while let Some(tok) = parser.next_token():
    process(tok)

// LIMITATION: Cannot collect ephemeral tokens into a Vec directly.
// Each Token borrows from parser.source (Rule 6, §21.1), so holding
// one Token prevents calling next_token() again.
//
// To collect, use owned tokens with offset indices:
type OwnedToken { start: u32, end: u32, kind: TokenKind, span: Span }

extend Parser:
    fn next_owned_token(mut self: Self) -> Option[OwnedToken]:
        let tok = self.next_raw_token()?
        Some(OwnedToken { start: tok.start, end: tok.end, kind: tok.kind, span: tok.span })

let tokens = with Vec.new() as mut toks:
    while let Some(tok) = parser.next_owned_token():
        toks.push(tok)    // OwnedToken is NOT ephemeral — no borrows
// tokens: Vec[OwnedToken] is storable

// ERROR: cannot store in a non-ephemeral struct
type Module { tokens: Vec[Token] }   // REJECTED: ephemeral field
```

**When to use ephemeral structs vs tuples:**

| Values | Use |
|--------|-----|
| 2 unnamed values | Tuple: `(StrView, TokenKind)` |
| 3+ values, or named fields matter | Ephemeral struct: `Token { text, kind, span }` |
| Value must outlive its borrow | Storable struct with offsets (§5.4) |

Ephemeral structs are cheap — they're stack values with no heap
allocation, just like the references they contain.

---
