# Primary verification — `rt/channel_runtime.w`

Status: **Complete**
Primary verifier: root agent
Source revision: `450733e5`
Source SHA-256: `ea0dfb8a94dc876bc2d6b04000eaa1d7a1223042d76330137cdade9717c14199`
Source examined: all 260 lines

## Scope examined

The complete module was read inline. It owns the channel queue: packed
56-byte handle layout (`:21-45`), field accessors, queued-drop/free,
unbounded grow, blocking send/recv/try_recv, close/destroy, and
sender/receiver refcount release. Blocking uses cooperative yield
(`channel_block_until_progress`, `:136-141`); the file contains zero
synchronization primitives — no atomics, no locks, no fences.

Applicable overview targets examined: 4 (blocking/yield discipline), 15
(runtime foundations), 23 (silent-drop fallbacks). Memory management is
`with_alloc_origin`/`with_free` only; every freesite was traced.

## Behavioral matrix

Probe `docs/audit/probes/chan_race_w4/main.w` (1 producer sends 0..19999 over an
unbounded channel, 1 consumer sums; expected 199990000), rebuilt fresh from
the pinned source with seed stage1 `-O1`, run in `/tmp/chantest`:

- `fiber_worker_count = 4`: segfault (rc=139) on one run; five further runs
  gave 163067621, 149429199, 193716473, 142003897, 129341744 — all wrong,
  nondeterministic.
- `fiber_worker_count = 1`: 199990000, 199990000 (exact).

The segfault was recorded on upstream #991 as a comment; it promotes the
grow-path UAF from predicted to observed.

## CHAN-001 — unsynchronized queue under work stealing (filed #991)

Classification: **Confirmed data race; reported upstream as #991**
Severity: **High** — silent message loss + observed crash
Confidence: **Very high** (execution + full source read)

Exact source branches (all plain non-atomic read-modify-write):

1. Send claims a slot via unsynchronized TAIL/COUNT (`:185-190`); two
   senders take the same slot, one message is lost.
2. Recv/try_recv advance HEAD and decrement COUNT unsynchronized
   (`:207-212`, `:224-229`); two receivers duplicate one message and COUNT
   drifts, sticking later messages or overfilling the ring.
3. `channel_grow` (`:102-134`) memcpys `count` elements, frees the old
   buffer (`:129`), then publishes buffer/capacity/head/tail (`:130-133`).
   A concurrent recv between the copy and the publish reads freed memory
   (UAF — now observed as the w4 segfault), and a concurrent send's COUNT++
   after the copy is lost. The 1P/1C probe grows (unbounded from 16) while
   the consumer reads, so this path is live with a single producer.
4. `channel_release_if_unreferenced` (`:98-100`) decrements refcounts in the
   caller and tests `<= 0` here — non-atomic check-then-free across the two
   release functions; premature free or leak under concurrent sender/
   receiver teardown (not separately demonstrated; same root cause).

Why single-worker is safe: yields happen only inside
`channel_block_until_progress`, so each send/recv/grow body runs to its next
loop check without preemption. The spec sanctions `fiber_worker_count = 4`
with cross-thread stealing, which breaks that assumption — the defect is the
missing synchronization, not the test configuration.

## Notes (no finding)

- Send/recv on a closed or never-created handle return silently
  (`:166-170`, `:182-183`, `:194-197`, `:232-240`). Read as channel
  close-semantics (a `Sender`/`Receiver` surface question for the stdlib
  `channel.w` module review), not a runtime defect: the runtime reports what
  the handle says, and close is explicit.
- `channel_drop_queued` (`:71-88`) walks `(head + i) % cap` for `count`
  entries then zeroes count. `cap >= 16` invariantly (create `:150`, grow
  `:109-111`), so no division by zero; under-race `count > cap` still
  indexes in-range via `%`. Correct under the single-writer assumption the
  race finding already breaks.
- Bounded-full send with no live fibers to make progress returns silently
  (`:179-180`). Fail-loud would be preferable, but a full bounded channel
  with no consumer is a program-level deadlock the scheduler cannot fix;
  noted for the stdlib surface review rather than retained here.
- `with_channel_create` failure paths free partial state (`:145-154`) —
  correct cleanup direction, no leak on the failure path.
