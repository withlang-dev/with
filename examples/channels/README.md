# Example: Channel Pipeline

Producer-consumer pipeline demonstrating channel-based concurrency.
Covers simple pipelines, fan-out/fan-in with multiple workers, and
`select`-based multiplexing with timeouts.

## Files

```
pipeline.w    Three demos: simple pipeline, fan-out, select
```

## What It Demonstrates

**Buffered channels** — `chan[T](buffer: N)` creates a bounded channel,
returning `(Sender[T], Receiver[T])`. Sending moves ownership into the
channel; receiving moves it out.

**Fan-out / fan-in** — Multiple workers share a single `&Receiver` and
each get their own `Sender` clone. When all sender clones are dropped,
the channel closes and workers exit their receive loops.

**Select with timeout** — `select await` races multiple async expressions,
firing the first branch that completes. The two-source demo races a recv
against a deadline; the three-source demo multiplexes fast and slow
producers with a 1-second timeout.

**Structured concurrency** — All producers and workers are spawned inside
an `async scope`. The scope guarantees every fiber completes before
`main()` continues.

## Language Features

| Feature | Location |
|---------|----------|
| `chan[T](buffer: N)` | All demos — buffered channels |
| `Sender` / `Receiver` types | Ownership-based channel endpoints |
| `async scope` + `s.track()` | All demos — structured fiber management |
| `select await` | `collect_results` — recv vs timeout; `demo_select` — 3-way |
| `let ... else` in select branches | `collect_results`, `demo_select` — `let Some(msg) = opt else break` |
| `async:` blocks | `demo_select` — inline producer fibers |
| `with` blocks (mutation) | `collect_results`, `demo_fan_out` — building Vec, HashMap |
| Pipeline operators `\|>` | `compute_stats` — filter/count chains |
| Default field values | `Stats { total: u64 = 0, ... }` |
| String interpolation | `"task-{i}"`, `"fast-{i}"`, worker output |
| `.len64()` | `compute_stats` — result count as u64 |
| Implicit `for` iteration | `for r in results:`, `for (wid, count) in worker_counts:` |
