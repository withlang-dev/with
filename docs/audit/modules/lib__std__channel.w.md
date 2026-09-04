# Primary verification — `lib/std/channel.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `544edd9a8eb9396dc371da68eef77b30b20d330d5349b4cf10d5d4e5d8a8f7f2`
Source examined: all 32 lines (primary read complete)

## Scope examined

Channel surface types: `Sender[T]`/`Receiver[T]` handles (`:23-24`), Drop
impls releasing each endpoint (`:26-32`), extern runtime declarations
(`:12-18`). `chan[T](capacity)` construction is a compiler builtin
(CodegenDispatch.w); close-on-last-sender-drop flows through
`with_channel_release_sender` (runtime).

Applicable overview targets examined: 4 (blocking/yield — delegated to
runtime), 10 (stdlib surface), 23 (silent-drop fallbacks). No logic beyond
delegation lives here; the queue behavior belongs to the already-completed
`rt/channel_runtime.w` module.

## Behavioral matrix

Probes in `docs/audit/probes/chan_sync_surface/`, re-run by primary with seed
stage1 at 450733e5:

- `chan_sync_fallbacks.w`: `check` ok rc=0; `run` prints `recv1-ok` /
  `recv2-none-ok` rc=0 — bounded `chan[i32](1)`, second send silently
  dropped, recv on empty-open returns None. Filed #1000.
- `chan_fiber_close_drain.w` (child): 0..999 fiber close-drain exact
  (499500) — close/drop path sound in the fiber context; consistent with
  the non-finding below.

## CHAN-002 — sync-context silent drop + None ambiguity (filed #1000)

Classification: **Confirmed silent-loss + doc falsehood; reported as #1000**
Severity: **Medium** — deterministic, success-shaped, doc-contradicting
Confidence: **Very high** (full surface + runtime read, probe re-runs)

`channel.w:7` documents "`None` once closed and drained", but recv on an
empty-but-OPEN channel also yields None (`rt/channel_runtime.w:203-204`),
and a send to a full bounded channel outside the fiber runtime returns
silently (`:179-180`). Cooperative `channel_block_until_progress` has
nothing to cooperate with in sync context, so both ops degrade to silent
no-ops instead of diagnosing misuse.

## Notes (no finding)

- Endpoint lifecycle is sound-directioned: Drop releases exactly one
  endpoint refcount; last-sender-drop closes (`rt:248-249`); free happens
  only when both counts hit zero (`rt:98-100`). Child's close-drain probe
  (exact sum) corroborates. Distinct from #672 (closed issue) and #991
  (multi-worker race, unrelated to this surface).
- No send/recv/close logic in this file to misbehave — the surface is a
  thin typed wrapper; all findings in this leg attach to the runtime layer.
