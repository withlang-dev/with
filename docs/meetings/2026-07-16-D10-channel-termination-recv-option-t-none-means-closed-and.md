# D10 — Channel termination: recv() -> Option[T]; None means closed and drained; Receiver is for-iterable

**Laws:** 1, 7 (docs/mission.md).

**Date:** 2026-07-16
**Status:** Accepted — BDFL ruling. **Deciders:** Eric (BDFL)

### The decision

`Receiver.recv()` returns `Option[T]`. Buffered messages are always
delivered first (`Some`); `None` means the channel is closed AND drained —
Rust's semantics in Swift's spelling. `Receiver` is directly for-iterable:
`for msg in rx:` receives until termination and falls out with zero
ceremony (desugars through recv's Option). CHAN_RECV codegen consumes the
runtime status (previously discarded — a closed-drained recv returned an
uninitialized value).

### Context / why

Closed-and-drained is the normal termination signal of every
producer/consumer pipeline, not an error. Panic (option A) converts
routine teardown into the error machinery and taxes the most common
channel idiom with try_recv/side-channel choreography — manufactured
suffering. A Go-style zero-value sentinel (option B) is silent wrong data
— the guardrail-removal the mission forbids — and is mechanically
unavailable anyway (With has no universal default for arbitrary T).
Option C prices honesty at one `?`/unwrap, which the language's own
happy-path doctrine already declared cheap, and the compiler proves every
consumer decided what shutdown means. Reference survey: Rust
(Result::Err after drain) and Swift (AsyncStream -> nil terminates
for-await) — the two memory-safe references — chose the type-honest
signal independently; Go's sentinel needed the `, ok` form and range
special-casing to patch; Zig and Vale ship no channels. The for-iterable
Receiver is the Swift lesson: termination-as-None makes iteration simply
end, deleting the loop's residual `Some` ceremony entirely.

Known residuals, deliberately left: `try_recv` remains specified-but-
unimplemented, and its `None` will conflate "empty now" with "closed" —
needs a three-state answer or documentation when implemented. Drop-bearing
payload ownership through the for-loop binding follows the current
provisional ownership state (#608 world).

Reopen if: channels grow a select-integrated recv arm whose binding shape
conflicts with Option (spec's select examples currently show both `msg =`
and `opt_msg =` spellings — reconcile when select-over-channels lands).

---
