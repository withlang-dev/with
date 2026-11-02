# D188 — `Duration` is a value type over `i64` nanoseconds, with `millis`/`secs` constructors, `Instant` and `timeout`

**Laws:** 1 (docs/mission.md); D114, D111.

**Date:** 2026-11-02. **Status:** delegated (D98, 85%) on the brief for
#2957; Eric asked whether it should be `isize` and the brief answered no.

**Ruling.** `std.time.Duration` is a value type (Copy, no identity, D111)
holding `i64` nanoseconds, the same width on every target (D114: a value
not bounded by memory takes a fixed width; `isize` is memory's width and
would overflow at 2.1 s of nanoseconds on wasm32). Constructors
`Duration.nanos/micros/millis/secs/minutes/hours`, integer extensions so
`50.millis()` and `1.secs()` read as §14 writes them, arithmetic and
comparison, `as_secs_f64()`/`as_millis()`, `Instant.now()` with
`elapsed()`, `sleep(Duration)`, and `timeout(Duration) -> Task[Unit]` so
§14.10's example exists. The grammar already says a float literal has
digits after its dot (§30 `FLOAT_LIT`), so `50.millis` is a member access
by the spec; the lexer that read `50.` as a float is corrected to the
grammar (one test spelled `10.-3.5`; it is rewritten).

**Why.** The `i32` millisecond alias came from the 2026-03-02 port with
no ruling; it overflows at 24.9 days, discards the runtime's nanosecond
resolution, and as a bare alias lets `sleep(50)` compile with no unit. Go
(`int64` ns), Rust (`u64` s + `u32` ns), Swift (128-bit) and Zig (64-bit
ns) agree on a fixed width.
