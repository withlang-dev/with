# D216 — A polled tagged message is a contract item

**Laws:** 1 (the program has determined the tag and the member; the contract
states the pairing once), safety (a payload is read only as the member its
tag selects, and never after it is released).

**Date:** 2026-11-18. **Status:** ruled by Eric; implemented, and the words
(§16.2b.9a, spec v7.92) blessed by him on 2026-11-25 with five edits.

**Amendment (Eric, 2026-11-25).** A message with `release` takes the facade
resource its producer receives `mut`; a union-form message does not (its
record is a copy, and the loop body may call the resource). A `release`
message whose producer receives no resource refuses a second running poll
with a panic: one atomic flag per message, taken with a swap. The poll is
presented without thread affinity; that gap is stated in the subsection.

**Context.** #2425: `SDL_PollEvent` fills a caller-owned union whose first
member, `type`, says which member is active; Steam's manual dispatch fills a
record with a tag, a payload pointer and its size, valid until the next
`FreeLastCallback`. Reading a union member is `unsafe`, so every event loop
was written under `unsafe`. The event loop is the first thing a game
writes, and the v0.17 game packages cannot ship with it under `unsafe`.

**Ruling.** A new item kind, `message Name wraps CRecord`: a polled message
is not a resource with a producer and a drop.

- **Lines.** `from f(out param N)`, `tag F`, `case Name when CONST [field f
  | : Type]`, `payload P size N`, `release f`.
- **Several tags for one member** are one named case per tag; a range
  (`when A..B`) may state a family in one line (SDL's window events).
- **The generated sum holds views**, so it is an ephemeral type (§5.5): it
  is matched, not stored.
- **The pointer form** enters a typed case only when the pointer is
  non-null, the size is sufficient, and the pointer is aligned for the
  payload type; otherwise the value is `Other(tag)`. Steam's structs are
  packed differently per platform, so the alignment check can fail.
- **`release f`** makes the message a guard that borrows the producing
  resource exclusively: "free before the next poll" cannot be got wrong.
- **`Other(tag)` is always present, and the sum is open.** `Other` protects
  against new library versions; it does not protect against new contract
  versions, where a case added later would break every exhaustive `match`.
  So a `match` on a message's kind must have a wildcard arm. A tag moving
  from `Other` to a named case changes behaviour silently, so an
  `.Other(tag)` arm that compares the tag with a constant that has a named
  case is warned.
- **A `bool` return on the producer means "produced."** No `ok return ==
  true` spelling.
- **Pointer fields inside a payload stay raw for now.** When field-level
  facts are taken up: SDL's event text is probably not tied to the message
  but lives in SDL's own temporary memory until a later pump (not checked
  in the pinned header). If so it is a domain in D208's sense, and the fact
  is a borrow from that domain, not from the event.

**For the contract work.**

- Each case is cited. SDL's event structs document which tags they serve;
  Steam's cases are generated from the SDK's own table.
- Thread affinity: SDL requires events to be pumped on the thread that
  initialized video. If a contract can state "main thread only", the poll
  carries it; if it cannot yet, that is a recorded gap, since the operation
  would be presented as safe.

**Alternatives.** A clause on `resource`: a message has no lifecycle of its
own in the SDL case. A closed sum: every contract update would be a
breaking change for its users.
