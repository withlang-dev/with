# 010 — Runtime and standard-library foundations

## Audit identity

- Audit targets: overview targets 15, 16, and 20 — allocator/container
  ownership; fiber/channel/synchronization runtime; standard-library unsafe
  foundations
- Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`
- Compiler exercised: `out/bootstrap/bin/with-stage1`
- Stage1 artifact SHA-256:
  `d1f65fd87a450c24a00bf2498a9bc10f9cf55a42cb199c5d8ef667a2bb4cab1a`
- Audit date: 2026-09-01
- Production/specification files changed: none
- Overall status: **bounded pass complete; no module is safe to mark complete**

This pass confirmed one independent ownership defect in channel send failure.
It also reproduced a serious regex behavior/leak observation that was not traced
to an instruction-level root cause, and preserved several source-level risks as
candidates rather than silently promoting them to findings. Suspension defects
already proved by audit 003 are cross-linked, not duplicated.

## Verdict

| ID | Status | Severity | Reach | Confidence | Summary |
|---|---|---:|---|---|---|
| RTF-001 | Confirmed executable defect; candidate unreported | High | Every moved, drop-bearing payload rejected by channel send | Very high | `with_channel_send` returns `Unit` on failure without enqueuing, returning, or dropping the moved payload. |
| RTF-OBS-001 | Reproduced observation; root cause unresolved | Unrated | Active-host `std.regex` compile/match path | High that the behavior occurred; low on cause | A minimal successful regex compile returned `false` for `a` against `a` and leaked two allocations; the existing behavior test also aborts. |
| RTF-CAND-001 | Source-level contract candidate | High if reachable from safe code | Pool users that double-release or release a foreign/interior pointer | High on source behavior; unproved contract violation | `Pool.free` accepts any non-null pointer and may place the same address in the free list more than once. |
| RTF-CAND-002 | Source-level arithmetic/encoding candidate | Medium | Very large arena allocations, growth, zeroed products, and marks | High on source shape; runtime boundary unexercised | Arena sizes use unchecked-looking `i32` arithmetic and marks reserve a fixed one-billion offset radix. |
| RTF-CAND-003 | Unsafe-contract/documentation gap | Medium | `ArenaVec[T]` for owned/non-`Copy` `T` | High | Unsafe push/grow/get bit-copy arbitrary `T` without an explicit ownership or `Copy` contract. |

Severity describes the consequence if the path is reachable under its intended
contract. Candidate rows are not counted as confirmed defects. `RTF-001` is High,
not Critical: the observed result is a deterministic resource leak rather than
an invalid free or memory corruption, but the leaked payload can own arbitrary
memory or external resources and repeated failures are unbounded.

## Method and evidence boundaries

The repository knowledge graph was queried before fallback discovery. It did not
expose the relevant `.w` functions, so source discovery proceeded with `tilth`,
then exact bounded source sections and executable probes. Source and executable
behavior were treated as the implementation truth.

The pass covered:

1. allocator bookkeeping and raw allocation/free entry points in
   `rt/rt_core.w`;
2. `Vec`, `str`, `StringBuilder`, `Box`, `Rc`, `Arc`, map/slot storage,
   arenas, pools, and `ArenaVec` ownership boundaries;
3. channel buffers and endpoint lifecycle;
4. common fiber completion/cancellation state plus mutex, rwlock, once,
   condvar, and barrier wait loops;
5. unsafe foundations used by regex, zlib, filesystem, networking, strings,
   collections, and tasks; and
6. existing allocator/runtime/stdlib tests relevant to those surfaces.

Memory probes used the native debug allocator. No compiler build, fixpoint, or
full test suite was run: this report changes no production source, and the two
channel executions answer the finding's ownership claim directly. After the
failed-send repro, one normal-success negative control was run and probing
stopped. Only the active Linux host was executed. Windows/Darwin parity was
source-inspected only where audit 003 had already done so.

[Audit 009](../009-build-platform-harness-spec/audit.md) establishes the
repository-internal provenance of the exercised stage1: its content-hash cache
ledger, `seed-input.json`, recorded seed identity, declared compiler/runtime/
stdlib input fingerprints, produced artifact fingerprint, and process effect
bind it to the current HEAD inputs, and `build --explain stage1 :stage1`
reported `fresh`. The placeholder version string in self-host stages is an
intentional unstamped sentinel, not ancestry evidence. This is the strongest
available internal binding without a rebuild; it is not an independent
reproducible-build attestation or current fixpoint proof. Audit 009 owns the
broader stage and artifact provenance analysis.

## Source authority inventory

### Allocation and owner wrappers

- `rt/rt_core.w:1150-1410` owns native allocation headers, debug-allocation
  ledger operations, zeroing, realloc, free validation, and invalid-free/leak
  reporting.
- `rt/rt_core.w:2450-2656` owns raw `Vec` header operations, growth, byte
  transfer, clear/free, element address calculation, `str` payload-start
  ownership checks, and removal compaction.
- `lib/std/string.w` owns `StringBuilder` growth and the conversion that creates
  the independently owned `str` used by the channel probe.
- `lib/std/box.w` and `lib/std/rc.w` wrap allocation and transfer values into
  `Box`, `Rc`, and `Arc`; their current constructors use move assignment rather
  than the older undischarged raw-copy pattern.
- `lib/std/collections.w` owns high-level `Vec`, map, set, deque, and slot-map
  APIs. Raw runtime storage release is not by itself proof that element drops
  agree with codegen; audit 004 owns the compiler drop side of that seam.
- `lib/std/alloc.w:8-16,89-179,286-373` owns arena arithmetic/marks, pool free
  lists, and the unsafe `ArenaVec` byte-copy surface.

### Channels, fibers, and synchronization

- `lib/std/channel.w:12-18` declares the channel ABI. In particular,
  `with_channel_send` returns `Unit`, while receive returns a status.
- `rt/channel_runtime.w:145-163` allocates the channel and element buffer and
  stores the element drop function.
- `rt/channel_runtime.w:165-190` owns send waiting, rejection, byte transfer,
  and queue state. `192-214` owns receive status and byte transfer.
- `rt/channel_runtime.w:216-278` owns close, final buffered-element drops, and
  sender/receiver reference release.
- `rt/fiber_runtime.w:46-52` keeps await, select RNG, and detached-task state in
  file globals; `82-94` orders runtime shutdown before allocator leak reporting.
- `lib/std/sync.w:108-131` is the common scheduler-progress wait shape used by
  synchronization primitives; the individual mutex/rwlock/once/condvar/barrier
  state machines follow in the same file.

### Unsafe stdlib foundations

- `rt/regex_runtime.w:80-112` constructs a PCRE2 general/compile context,
  creates character tables, compiles, then releases the general context.
  `114-121` owns regex code copying/freeing.
- `lib/std/regex.w` owns the safe `Regex` API and compiled-code destructor.
- `lib/std/zlib.w` and its extern runtime calls were source-inspected for obvious
  acquire/fail/release asymmetry only; no conformance or corpus run was done.
- Filesystem and networking wrappers were sampled for raw descriptor/buffer
  ownership, not exhaustively tested across error, short-I/O, shutdown, and
  platform branches.

## RTF-001 — rejected channel send loses an owned payload

### Reproduction and negative control

The failed-send probe constructs a dynamically owned string, drops the only
receiver, then sends the string through the remaining sender:

```with
use std.channel
use std.string

let (tx, rx) = chan[str](1)
drop(rx)
var sb = StringBuilder.new()
sb.push_str("owned")
tx.send(sb.to_str())
print("done")
```

Observed with
`./out/bootstrap/bin/with-stage1 -e <probe> --debug-alloc --debug-alloc-filter=non-root`:

```text
done
debug-alloc: LEAK addr=<address> size=16 origin=unknown
debug-alloc: leak count=1
```

The negative control retains the receiver and consumes the value normally:

```with
use std.channel
use std.string

let (tx, rx) = chan[str](1)
var sb = StringBuilder.new()
sb.push_str("owned")
tx.send(sb.to_str())
let got = rx.recv()
print(got.unwrap())
```

Observed under the same allocator settings:

```text
owned
debug-alloc: leak count=0
```

The sole differentiator is whether send transfers the payload into a live
channel. The control rules out `StringBuilder.to_str`, ordinary channel buffer
ownership, receive, and normal endpoint teardown as sufficient explanations.

### Exact failure chain

1. `tx.send(sb.to_str())` passes an owned `str`; the sender operation consumes
   the payload under With's plain-`T` parameter ownership rule.
2. Dropping `rx` closes the channel before the call.
3. `with_channel_send`, `rt/channel_runtime.w:165-183`, has five failure exits:
   null handle (`166-167`), null buffer (`168-170`), closed while full
   (`172-174`), full with no fiber progress possible (`178-180`), and closed
   after the wait loop (`182-183`).
4. The payload is transferred to channel storage only at `184-190`, where the
   runtime byte-copies it and increments the queue count. None of the failure
   exits reaches this transfer.
5. The ABI declaration at `lib/std/channel.w:13` returns `Unit`; it cannot tell
   generated code to reclaim or return the still-owned payload.
6. Consequently the call has consumed the caller's owner, but neither the
   channel nor the runtime failure path becomes the owner. The allocator reports
   the dynamically owned string buffer at shutdown.

This is one protocol defect covering every early return, not just the closed
branch exercised above. The bounded/no-progress branch at `179-180` has the same
ownership outcome when it rejects a value.

### Five Whys

1. **Why did memory remain live?** The rejected value was neither queued nor
   destroyed.
2. **Why was it not destroyed?** Every send-failure branch returns before the
   payload copy and has no payload cleanup.
3. **Why could the caller not recover it?** The language call had already moved
   the payload.
4. **Why could generated code not distinguish failure?** The runtime send ABI
   returns `Unit` and exposes no ownership outcome.
5. **Why does the seam admit ownerless values?** Channel state transition and
   payload ownership transfer are modeled separately instead of as one
   exactly-once protocol shared by API, lowering, runtime, and drop glue.

### Impact and issue relationships

- The demonstrated leak is deterministic for an owned `str` after receiver
  closure.
- The element type is generic. The same protocol can strand nested `Vec`,
  `Box`, `Rc`/`Arc`, custom `Drop`, or handles owning non-memory resources.
- Repeated rejected sends can produce unbounded retention/resource exhaustion.
- Audit 003's SUSP-003 separately proves that a cancelled empty receive hangs and
  classifies full send/synchronization waits as source-equivalent cancellation
  candidates. That is a liveness/effect defect. RTF-001 is an independent
  payload-ownership defect on a send that returns.
- Audit 004 owns generic move/drop/codegen agreement. A repair must preserve its
  exactly-once cleanup invariants rather than adding a second special-case drop
  convention.

Live issue deduplication was outside this local audit pass, so the finding remains
**candidate unreported** until the parent audit checks the tracker.

### Proper repair boundary

The send ABI needs an explicit ownership outcome. Every exit must converge on a
single rule:

- success transfers the value into channel storage exactly once; and
- rejection either returns the still-owned `T` to the caller or consumes and
  drops it exactly once through the registered element drop glue.

The compiler/API/runtime must agree on which contract is chosen. A minimally
sound internal shape is a status-returning runtime operation followed by one
generated ownership branch: disarm the source only on successful queue transfer;
otherwise return or drop it according to the public API contract. The null,
closed, full/no-progress, cancellation, and teardown races must all use that same
path. Patching only `rt/channel_runtime.w:182-183`, or freeing bytes without
invoking type-specific drop glue, would leave sibling exits and nested resources
wrong.

This report does not select or amend normative public API wording; that is a
maintainer/spec ruling if the existing specification does not already settle
failure behavior.

## Cross-target findings intentionally not duplicated

### Suspension and cancellation

[Audit 003](../003-suspension-cancellation/audit.md) already establishes:

- SUSP-001: a cancelled may-suspend ordinary call consumes an unwritten result;
- SUSP-002: cancellation cannot complete while blocked in `select await`;
- SUSP-003: cancellation cannot complete while blocked in channel receive, with
  bounded send and synchronization waits source-equivalent;
- SUSP-004/005: `no_suspend` misses indirect callables and transitive sync waits.

The common channel loop at `rt/channel_runtime.w:172-180` and sync helper at
`lib/std/sync.w:108-113` do not consume cancellation. Those are material blockers
for target 16, but they remain audit 003 findings and are not recounted here.

The file-global await caches, select RNG state, and detached-task arrays at
`rt/fiber_runtime.w:46-52` were not proved safe for simultaneous OS-thread use.
No defect is asserted because the supported thread/concurrency contract was not
established in this pass.

### Compiler drop/storage agreement

[Audit 004](../004-move-drop-cleanup/audit.md) owns MIR drop-state and codegen
cleanup correctness. Runtime storage functions such as `with_vec_clear` merely
change raw headers; correctness for `Vec[T: Drop]` depends on generated element
cleanup running before storage release. That cross-layer matrix was not
re-executed here.

The known D22 map/slot owned-storage work remains deliberately non-compliant.
The fixture `test/non_compliant/d22/da_slotmap_owned_storage_drop.w` is evidence of
known incomplete work, not a new runtime-foundation finding.

## Unresolved observation and source candidates

### RTF-OBS-001 — regex returns the wrong match result and leaks

The following active-host probe exited normally but printed the wrong boolean:

```with
use std.regex
let r = Regex.compile("a").unwrap()
print_bool(r.is_match("a"))
```

Observed with the native debug allocator:

```text
false
debug-alloc: LEAK addr=<address> size=2048 origin=with_alloc
debug-alloc: LEAK addr=<address> size=256 origin=with_alloc
debug-alloc: leak count=2
```

The tracked `test/behavior/behav_regex_std.w` also aborts at its first successful
match assertion under the same stage1 compiler. Per audit 009, that artifact is
cache-ledger/seed/effect-bound to the current HEAD inputs; an independent rebuild
was not performed.

`with_regex_compile`, `rt/regex_runtime.w:80-112`, creates a general context and
character tables, places the tables in a stack compile context, compiles, then
frees the general context. That sequence is a plausible ownership investigation
point, but this bounded pass did **not** determine which allocation owns the
tables, why matching returns false, or the exact instruction retaining either
reported allocation. PCRE2 context/table lifetime, struct layout, match-data
construction, and generated ABI all remain competing hypotheses.

Per the repository's root-cause rule, this observation has no proposed fix and
is not classified as a confirmed root-caused defect. A follow-up must reduce the
probe and use LLDB at compile/match/free boundaries before changing code.

### RTF-CAND-001 — pool accepts duplicate and foreign releases

`Pool.free`, `lib/std/alloc.w:319-321`, pushes every non-null address directly
onto `free_list`. It does not prove slab membership, element alignment, current
allocation state, or uniqueness. `Pool.alloc`, `311-317`, pops entries without
validation. Therefore a double release places the same address into the list
twice and permits two later allocations to alias; a foreign/interior address can
also be returned as if pool-owned.

This is an exact source behavior, but the intended safety boundary for raw pool
pointers was not located. If `free` is explicitly unsafe-by-contract, the gap is
documentation/diagnostics; if safe code is entitled to allocator ownership
checking, it is a High-severity alias/corruption defect. The repair boundary would
be the allocation-state invariant, not a caller-side workaround: validate
membership/alignment and prevent duplicate free-list membership, with debug
allocator integration where appropriate.

### RTF-CAND-002 — arena arithmetic and mark radix are under-specified

- `alloc_align16` computes `n + 15` in `i32` (`lib/std/alloc.w:8-10`).
- `Arena.add_block` doubles `capacity` in `i32` (`89-103`).
- both `alloc_zeroed` variants multiply `count * size` in `i32` (`141-150`).
- `Arena.mark` encodes `block_index * 1_000_000_000 + offset`, while `offset` and
  capacity can exceed that radix (`153-161`).
- pool slab allocation likewise multiplies `item_size * count` in `i32`
  (`290-296`).

Depending on checked-overflow behavior, extreme inputs may fail loudly or may
wrap into an undersized allocation/ambiguous mark. That answer was not executed,
so no memory-safety claim is made. A complete audit needs boundary values around
alignment, doubling, products, and the one-billion mark radix, then must prove
that allocation and reset reject rather than alias/truncate.

### RTF-CAND-003 — `ArenaVec[T]` does not state its ownership contract

`arena_vec_grow` bit-copies existing elements (`lib/std/alloc.w:349-360`),
`arena_vec_push` bit-copies by-value `T` without visibly disarming the local
(`362-368`), and `arena_vec_get` returns a bit-copy (`370-373`). All operations
are unsafe, which may intentionally place the invariant on the caller, but no
`T: Copy` restriction or owned-element destruction policy is present in this
surface. It is not safe to infer that arbitrary `T: Drop` works.

This remains a contract/documentation candidate. The repair boundary is to make
one rule explicit and enforceable: restrict the structure to trivially copyable
elements, or implement real move/drop tracking for arena-owned elements.

## Regression matrix for confirmed repair work

The RTF-001 repair is incomplete until one matrix proves ownership and liveness
jointly:

| Dimension | Required cases | Required invariant |
|---|---|---|
| Element kind | integer/Copy, dynamic `str`, `Vec[str]`, `Box[T]`, `Rc`/`Arc`, custom nested `Drop` counter | Transfer or destruction occurs exactly once; allocator leaks zero |
| Channel state | open with capacity, closed before call, receiver dropped, closes while sender waits, full/no-runtime-progress | Every return has an explicit ownership outcome |
| Buffer mode | bounded capacities 1 and greater; unbounded growth | Growth does not duplicate or lose owners |
| Concurrency | producer/consumer fibers, cancelled blocked sender, endpoint teardown with buffered values | No hang, fabricated success, double drop, or leaked payload |
| Failure injection | null/failed channel allocation where safely reachable; element buffer unavailable | Loud failure or defined owned error; never silent owner loss |
| Platform | Linux active host plus Darwin and Windows runtime backends | Same state/ownership protocol on every backend |
| Compiler checks | `check --validate-all`, ownership/drop-plan traces for owned payloads | MIR and runtime agree on when the source is disarmed |

Pool/arena follow-up should separately enumerate duplicate/foreign/interior
frees, zero/negative/maximum sizes, multiplication and growth boundaries, mark
round trips across multiple large blocks, and `ArenaVec` Copy versus Drop-bearing
types.

## Existing coverage and material gaps

- Channel tests cover scalar/enum/`Option` messaging and normal fiber lifecycle;
  the inventory found no owned-payload rejected-send allocator regression.
- Existing suspension tests do not substitute for the send ownership matrix:
  SUSP-003 exercises a wait that never returns, while RTF-001 exercises a failure
  return that loses its argument.
- Arena/pool tests cover ordinary allocation/reset/reuse, not adversarial
  releases or arithmetic boundaries.
- Mutex/rwlock/once/condvar/barrier tests cover ordinary coordination. Audit 003
  remains the authority for cancellation holes in their waits.
- Regex has an existing behavior test, but it currently fails under the exercised
  stage1 artifact and no allocator/lifetime root-cause test isolates the two
  leaks.
- Zlib, filesystem, and networking unsafe foundations were source-sampled only;
  error-injection, descriptor exhaustion, short I/O, cross-platform behavior,
  and allocator-clean corpus runs remain open.

## Limitations and completion impact

- No issue tracker deduplication was performed in this local report.
- No LLDB session was run for RTF-001 because the debug allocator plus the exact
  early-return source branch and negative control fully isolate owner loss. LLDB
  remains required for the unresolved regex observation.
- No Windows or Darwin executable evidence was produced.
- No independent rebuild, fixpoint, sanitizer suite, fuzzing, or exhaustive
  stdlib corpus was run. Audit 009's internal cache binding is strong evidence,
  but an independent rebuild and current fixpoint would be stronger.
- Map/slot cleanup, generic collection drop glue, suspension/cancellation, and
  stage provenance depend on audits 004, 003, and 009 respectively.
- Nothing in this pass authorizes changing the specification. No touched spec was
  made untrue and no Observed spec prose was used as contract.

Targets 15, 16, and 20 must remain unchecked. RTF-001 is open; the regex path is
not root-caused; the pool/arena/ArenaVec contracts are unresolved; and the full
type/state/platform matrix has not been executed.
