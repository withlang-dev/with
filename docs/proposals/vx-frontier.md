# vx-frontier.md — what the checker and dispatch make possible

The third of three. `vx.md` is the checker (machines, placement, regions,
capacity, host-lowered). `vx-dispatch.md` runs placed code on devices.
This document holds what neither should carry: ideas that are real,
that the same machinery enables, and that each need something the first
two do not yet provide before they can be briefed. Nothing here is
approved by approving the other two, and nothing here is scheduled. Each
entry says what it is, why it belongs to With rather than to any other
language, what it waits on, and what its brief must contain.

The through-line: Vx made placement a refusal. With's instincts are to
infer what is known, advise where a refusal is not needed, migrate rather
than rewrite, cancel rather than leak, and measure rather than assert. The
same machine model and the same placed types, under those instincts, are
tools a person reaches for before they have a bug.

## 1. Static search over kernel variants

**What.** A kernel-generating scheduler of the tinygrad kind (a small op
set, a lazy graph, fusion into kernels, a search over loop
transformations that keeps the fastest variant) pays for its search by
compiling and running candidates, and a large share fail for reasons the
machine file states: a tile that overflows the scratchpad after granule
rounding, a workgroup over `workgroup max`, an element type the processor
does not declare. With the checker, the same search space is pruned before
a candidate is built, and with traffic facts the survivors are ranked by
roofline before any of them runs. Search becomes "measure the three that
could win". A winner, once measured, is pinned as a `measured:` fact the
build can trust.

**Why With.** The machine file is a comptime value and admission is a
comptime-callable predicate; a search can run while compiling, with the
machine as the cost model, and the winning kernel is compiled into the
binary with its footprint in its type.

**Waits on.** Crux's Part 8 scheduler as the customer; `vx-dispatch.md`'s
kernels-as-values and traffic facts; a ruling on exposing admission as a
library predicate (`Machine.fits(...)`).

**Brief must contain.** The predicate's surface; evidence on the Crux six
that pruning removes most failing candidates; the pin-the-winner
mechanism and how a changed machine file invalidates it.

## 2. Confidential placement

**What.** `sees` is a visibility set, and visibility is a security
property. A space declared for an enclave processor or a confidential
GPU, with no transfer edge to any host-visible space, holds a key or a
weight that cannot reach the host by any spelling the checker accepts.
Confidential inference ("the operator of the host cannot read the
weights") becomes something the type system refuses to violate rather
than something an attestation document promises.

**Why With.** The mechanism already exists in the machine model; nothing
is added to the language.

**Waits on.** A threat model. A type-level claim about security is only as
strong as the backend's enforcement: no host mapping of the space, no
debug readback, no spill to a visible space by the lowering, and a stated
position on side channels and on what a compromised driver can do.
Without those, "provably never flows" over-claims, and Law 7 forbids the
plausible wrong thing in a security claim more than anywhere.

**Brief must contain.** The threat model; the backend obligations and how
each is tested; what the checker proves (no accepted spelling moves the
bytes) versus what it does not (hardware and driver behavior); a
differential pair where the host-side program reads the weight and the
With program is refused.

## 3. Storage tiers with real semantics

**What.** `vx.md` lets a machine file declare NVMe, a CXL pool or a remote
node's memory as spaces, and the checker treats them as spaces. Giving
those edges semantics is the work: a transfer over a file-backed edge is
I/O with failure modes a copy engine does not have, a fabric edge has a
peer that can disappear, and both are asynchronous in a way the task
model must represent. Done, a tiered KV cache is a program whose moves are
explicit, whose admission is checked across the hierarchy, and whose
eviction policy is ordinary With over placed buffers; "does the cache for
batch 64 at 128k context fit this box" is answered by `with check` before
the hardware is rented.

**Why With.** Transport is not duplication and a transfer transfers (Law
5) hold across a file boundary exactly as across a bus.

**Waits on.** The `async transfer` task shape from dispatch; a ruling on
how a transfer's failure is typed (a `Result` on the task, as I/O is
elsewhere); the remote-region identity question Vx recorded (identity is
worker plus address, never an address alone).

**Brief must contain.** The failure typing; the identity rule for remote
spaces; one tiered-cache program checked against a declared two-tier
machine, host-lowered.

## 4. Rendering a scheduler's output as With

**What.** A tinygrad-style renderer emits source text per backend. Emit
With instead: a scheduler's `realize` produces `on gpu:` regions with
`parallel[workgroup]` loops and scratchpad buffers, and the With compiler
checks, admits and compiles them. Everything the scheduler generates gets
placement checking for free, and the generated kernels are ordinary With
a person can read and keep.

**Why With.** The checker is the thing a generated kernel most needs and
least often has.

**Waits on.** Item 1's scheduler, or an external one willing to target
With. This is a customer's project, not the toolchain's.

## 5. Kernel generation as the default, vendor libraries as the exception

**What.** tinygrad's bet is that generated kernels beat hand-written ones
for most shapes; the pragmatic truth is that cuBLAS wins at some. With can
hold both: regions generate, and a `c facade` over the vendor library is
called where it wins, with the compiler refusing a host pointer where a
device pointer is demanded (`vx.md` IV.7) and the facade's ownership
clauses making the call safe. The decision of which to use per shape is
data from item 1's measurements, not a hard-coded preference.

**Waits on.** Dispatch's facades and item 1.

## 6. The model checked against ten million devices

**What.** An edge target is a machine file (`vx.md` IV.1). The frontier is
the fleet: a project pins a set of machine files and `with check` admits
the program against all of them in one run, reporting the matrix of
verdicts, so a model is known to fit every device class it ships to
before it ships. The same run is the differential suite's harness for
"portable by proof".

**Waits on.** The checker; a `machines = [...]` form of the pin and a
matrix report in `with analyze`.

**Brief must contain.** The report shape; the cost of checking N machines
(instantiation per processor is per machine, so the cost is linear and
should be measured).

## What is deliberately not here

- A JIT, a runtime shader compiler as the default, or a per-process
  compile cache: dispatch compiles kernels at build time and keeps the
  driver's compiler as the spelled exception.
- Any claim the hardware cannot back: cancellation of a running kernel,
  security against a side channel the threat model has not named.
- Shapes in types. Still a separate decision, and the strided-view
  library of Crux's Part 8 does not need it.
