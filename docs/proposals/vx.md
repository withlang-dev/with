# vx.md — placement, machines and regions in With

## Why

Eric runs a serving stack and a kernel library on his own machines: 3090s, a
5090, a Mac. He wants to write that layer in With, with the placement bugs
refused at compile time: a host read of device memory, a buffer whose copy
has not landed, a scratchpad that overflows, a working set that fits in
every function and not across the call, a pointer into the wrong memory
handed to a vendor call. That is a mission reason (close to the machine,
exactly as safe, the suffering removed), it is testable on hardware he
owns, and it decides scope questions no comparison with another language
can: an eight-GPU box makes peer transfers between `gpu[0]` and `gpu[1]`
early scope, not a refinement.

Vx (github.com/vx-lang/Vx, by Aditya Kumar) is the reference for the idea
that *where a value lives* and *where code runs* are type facts checked
against a declared machine. It is read for what it establishes and where it
fell short. Nothing is copied from its repository: no code, no text, no
machine description, no test. What crosses is ideas, and With writes every
line that realizes them.

## Scope

**This plan is the checker: steps 1 to 3 of Part VI.** Machine files,
placement in types, transfer, regions, visibility, routing and capacity,
all lowered on the host against a declared test machine. It needs no GPU,
no second codegen unit and no vendor facade, it is bounded, and it stands on
its own: a program that typechecks against a declared H100 is useful before
any kernel runs on one.

**Dispatch is a separate proposal** (`vx-dispatch.md`): device codegen
units, the Metal and CUDA facades, hardware batteries on two boxes. That is
where the cost changes kind, from a campaign into a standing tax on every
later language change, and it gets its own brief once the Metal question is
answered and the checker has shown what it is worth on real With programs.
The ruling that approves this plan approves the checker and asks for that
brief; it does not approve dispatch.

Syntax below is a proposal, not a ruling. Where Vx's code and Vx's prose
disagree, this document follows the code. Paths written `Vx …` are under
`.reference/Vx`; bare paths are this repository; line numbers are as of
2026-10-07.

---

## Part I — What Vx is

### Earned by its code

- **A machine model.** Spaces: `Vx src/syntax/decl.rs:323` (`MemoryDecl`:
  parent `within`, capacity, bandwidth, clock, managed, granule, scope,
  replicas), `decl.rs:241` (exact byte sizes), `decl.rs:245` (a rate is per
  cycle or per second, never mixed without a declared clock), `decl.rs:304`
  (scope). Processors: `Vx src/arch.rs:185` (`TopologyDescriptor`: arch,
  default space, visible set, dtypes) and `arch.rs:219` (`TopologyDecl`).
  Edges: `arch.rs:108` (`TransferEdge`), `arch.rs:128` (`EdgeCost`: derived
  from endpoint bandwidths, or a declared link rate, never both;
  `arch.rs:117` is the refusal). Coherence of the model itself:
  `Vx src/hir/memory.rs:196` (`MemoryCoherenceIssue`: containment cycle,
  child larger than parent, non-positive figure, scope widening downward)
  and `arch.rs:228` (a processor that cannot see its own default space).
  Duplicate declarations across the machine file, the host file and the
  program are refused (`Vx src/diagnostic.rs:425`, E6012). The flags:
  `Vx src/driver.rs:98-128` (`--machine` for the accelerator, `--host` for
  the machine it hangs off; a host declares no capacity because host memory
  pages rather than fails). Provenance classes on every figure:
  `Vx fleet/h100-sxm.vx:16-33` (`spec:` with the document and date,
  `measured:` with the instrument and the boxes), `Vx docs/memory_algebra.md:314`.
- **Placement in the type**, one slot: `Vx src/syntax/types.rs:218`
  (`Placement { topology, space, stated }`: the source writes the device or
  the space, the other is derived at name resolution, and which half was
  written is recorded because neither projection is injective). A wrapper
  that restated it was retired (`Vx docs/lang/types.md:69-75`). Pointers
  carry the pointee's space (`types.md:42-67`). Placed values are linear and
  cannot opt into `Copy` (`Vx src/hir/check/access.rs:28`).
- **Visibility at a read**: `Vx src/hir/check/access.rs:190-215` (the E6003
  message names the value, its space, the processor's visible set, and the
  transfer that fixes it with its cost). A function pinned to one processor
  called from another: `Vx src/hir/check/calls.rs:827` (E6001). The implicit
  form, which no type in the program mentions: a kernel the backend cannot
  emit for its device would fall back to a host read of host-unreadable
  memory, refused at `Vx tests/backend/fail/placed_kernel_host_unreadable.vx`
  (header lines 8-35 record that a committed test faulted on every GPU it
  was written for before this check existed).
- **Reachability and routing**: `Vx src/arch.rs:1108` (`reachable`),
  `arch.rs:1171` (`transfer_path`: all-pairs over declared edges,
  sub-spaces routed through their containing spaces), `arch.rs:1012`
  (`is_type_accessible`). A transfer is checked in phases
  (`Vx src/hir/check/transfer.rs:14-16`): `resolve_transfer_edge`
  (`transfer.rs:1034`; no path is E6002 at `:1163`; staging through an
  undeclared host is E6014 at `:1200`), then the lowering, the route and
  traffic record, the seam obligation, and the new type
  (`check_transfer_expr`, `transfer.rs:1765`). A multi-hop route is
  rewritten into single hops (`transfer.rs:29-31`).
- **Capacity admission**: `Vx src/hir/check/transfer.rs:433` (per buffer
  and per working set, E6009/E6010), `Vx src/hir/memory.rs:98`
  (`granule_round`, one definition because two had drifted), `memory.rs:176`
  (`static_tensor_bytes`: exact `u64` folding of const dimensions, never a
  float, `None` when any extent is dynamic so the check fails closed to an
  "unverified" warning). Across calls: `Vx src/hir/check/capacity_fold.rs:8-20`
  (sequential calls compose by max, a buffer held across a call by plus),
  `capacity_fold.rs:57` (`fold_cross_call_capacity`), `:264` (a recursive
  cycle into a bounded space is refused, E6028), `:346` (Tarjan over the
  call graph). `overcommit` downgrades the refusal to a warning
  (`Vx src/diagnostic.rs:417-419`).
- **Element-type admission** (`Vx src/hir/check/transfer.rs:184-193`, E6026,
  silent unless the processor declares `dtypes`) and **pointer-space
  mismatch at a call** (`Vx src/diagnostic.rs:519-523`, E6029).
- **Region traffic**: `Vx src/hir/check/region_traffic.rs:8-30` (touches, not
  footprint; per launch; one uncountable access makes the whole region
  absent with a reason, never partial and never zero), `:341`
  (`derive_spawn_traffic`).
- **Structured verdicts**: `Vx src/diagnostics_json.rs:8-60` (the schema:
  verdict, each diagnostic with code and span, a capacity record with
  required, available, margin and tiles, each route with path, per-edge
  cost, bytes, derived cost with unit and source, and traffic).
- **A measurement record against itself**: `Vx docs/memory_algebra.md:229-290`
  (no latency term, so a 4 KiB transfer is mispredicted by 98%; the
  composition law for a multi-hop route is unsettled; contention is
  recorded but not priced; five instrument defects, all caught by "a number
  that cannot physically be true"). Its strongest validation is a predicted
  versus measured ratio on a real two-socket box; that shape of evidence,
  not only refusal fixtures, is what makes admission figures trustworthy
  (§11).

### Prose, or surface only

- Overlap of a region with later host work: designed
  (`Vx docs/spawn_on.md:20-72`), but every runtime blocks and the compiler
  emits no wait (`spawn_on.md:140-156`).
- `Verified`, `HardwareState`, `try_pin`, `effects`: unimplemented
  (`Vx docs/lang/types.md:220-278`).
- A processor as a value is an `i32` with hashed identities and collision
  refusal (`Vx docs/topology_representation.md:56-89`, `Vx src/arch.rs:389`).
- The seam prover decides a two-bit lattice over named locations with
  asserted equalities, through z3 (`Vx src/hir/seam.rs:9-36`, `:260`); a
  missing z3 once certified every seam silently (`Vx src/diagnostic.rs:488-492`).
- The flagship example places nothing and is raw-pointer code with `unsafe`
  on most lines (`Vx examples/llama.vx:19-59`, `:122-140`).
- The "differential suite" is two refusal fixtures
  (`Vx tests/backend/fail/npu_deref_on_host.vx`,
  `placed_kernel_host_unreadable.vx`) and the measurement campaign.
- `--target` was removed because one triple cannot name two machines; the
  host file is the target and the machine file is the offload target
  (`Vx docs/lang/hosts_and_machines.md:223-300`). With keeps `--target` for
  the host and adds the machine beside it, with the two required to agree.

## Part II — What With already has

- **Ownership, drops, leaks.** Vx recomputes drop points on its syntax tree
  (`Vx src/hir/check/drops.rs:8-26`, 1300 lines) and makes device buffers
  linear so a leak is visible. With's MIR owns every allocation's drop point
  (`src/MirCore.w:1111` the drop-state keys, `:1649` the per-block state,
  `src/Mir.w:639` the plan dump) and calls a leak a defect. Device memory is
  memory.
- **Regions as blocks.** `docs/spec/concurrency.md:300-330` (§14.7 and
  §14.22): an `async:` block captures under closure rules, its `Task` is
  ephemeral when it captures a view, and dropping an un-awaited task cancels
  it. `src/AsyncLower.w:62` (`lower_async_module`) is how such a block
  becomes an outlined body. A region is that block with a processor. This
  plan depends on the cancel-on-drop rule being enforced, and step 2 tests
  it (V.8).
- **Target-conditional compilation.** `docs/spec/metaprogramming.md:349-395`
  (§17.5, D91): `comptime match Target.os`, exhaustive, the untaken branch
  parsed and not compiled; `src/SemaCheck.w:23153` (`select_comptime_if_branch`)
  and `src/ComptimeTransform.w:626` do the pruning; `lib/std/os.w:40-56`
  answers `Target.os` from the `--target` value through the intrinsic at
  `src/ComptimeEval.w:7932`, never from the host; `src/TargetSpec.w:86-87`
  lists the kinds. The processor is one more such constant.
- **A declared build input.** §17.1a: a tracked input is part of the build
  key (`src/compiler/TrackedInputs.w`); `src/compiler/DriverOptions.w:41-42`
  holds the target kind and whether it was explicit; `src/main.w:1140`
  applies `--target` to `check`. A machine lands beside the target here.
- **Instantiation per parameter.** A generic body is checked once and
  compiled per instantiation (`src/Sema.w` specializations, the
  `specialization` facts). A body that runs on more than one processor is
  the same mechanism over the processor (§3).
- **One fact database.** `src/AnalysisTypes.w:17` (`AnalysisFactKind`, 28
  kinds today), `src/Analysis.w:93-780` (one collector per kind),
  `with analyze … select:kind=…` and the `lldb:` and `path:call` requests
  over the live MIR call graph. Placement, route, capacity and traffic
  become kinds 29-32; there is no second schema to version.
- **Modeled C.** `docs/spec/ffi.md:351-375` (§16.2b, the `c facade` block:
  `resource X wraps *mut T`, producers `from`, `drop`, `destroys`, `ok`);
  `src/SemaFacade.w`. When dispatch comes, the runtime is facades over the
  driver APIs, in With, not Vx's twenty C++ files under `Vx runtime/`.
- **Types instead of a solver.** `lib/std/task.w:20` (`Task[T]`) is the
  completion obligation: an asynchronous transfer is a task that becomes the
  placed value when awaited.
- **One ABI source.** `src/FnAbi.w:26` (`PassMode`, computed once). A pointer
  into another space is a pointer type with a space argument; its passing
  mode is whatever `compute_fn_abi` says for a pointer, and nothing per path.
- **The machines.** The Mac is one unified space with a CPU and a GPU that
  address it, plus threadgroup memory as a true scratchpad; the Linux box
  (`eric-5090`) has discrete GPUs with host-unreadable memory and peer
  edges between them. Descriptions of both are the first shipped ones.

## Part III — Principles

### 1. Placement is a fact about a value that owns or views bytes

A value's memory space is part of what the compiler knows about it, the way
its type and its owner are. It belongs to what owns bytes and to what views
them: buffers, slices, references, raw pointers. A scalar has no placement,
and a region's result is not placed merely for having been computed
somewhere (Vx places every spawn result, `Vx docs/lang/semantics.md:19`; that
is noise). Two values that differ only in where their bytes live are not
interchangeable. The host is the default *representation*: a program that
never names a space is a host program, unchanged, and its types intern to
the same ids they do today.

This is broader than Vx, which places tensors and pointers only, and the
breadth is a feature rather than a cost: a host function taking `&[T]`
takes a host slice, which is correct because a host function cannot read
HBM anyway. There is no space-generic code to write, because where code
runs already determines what it can see; a function that must run in two
places is instantiated per processor (§3), not abstracted over spaces.

*Laws:* 4 (which spaces exist and who can see them is declared, never
inferred from a name); 1 (the placement is carried once; no wrapper restates
it; a default picks a representation, never a meaning).

### 2. Moving between spaces is a transfer, and a transfer is explicit

Crossing from one memory space to another is an ownership event. It is
spelled by the programmer, even when the hardware makes the crossing free.
With departs from Vx's code here: Vx's transfer copies and keeps the source
(`Vx docs/lang/types.md:397-398`); With's consumes, and keeping a copy is a
clone, O(n) and spelled.

*Laws:* 5 (a transfer transfers; no second live value); 1 (an implicit
transfer would pick a meaning).

### 3. Code runs somewhere, and can only reach what that somewhere can address

A region runs on a declared processor. Everything it touches must live in a
space that processor sees. A violation names the value, its space, the
visible set, and the transfer that fixes it (the shape of
`Vx src/hir/check/access.rs:202-214`). A region the compiler cannot lower
for its processor is an error, never a silent fallback onto the host.

Where a function runs is a signature fact across a published boundary and
an inferred fact inside one, the same shape as comptime-callability (D104).
**Inside a package, a function is instantiated per processor it is called
from**: a helper called from host code and from an `on gpu` region is two
bodies, checked once and compiled twice, exactly as a generic is
instantiated per type argument. The consequences are part of the rule, not
a discovery: two bodies in the facts and in the dumps, two codegen units
once dispatch exists, and a diagnostic at the call site when the body is
fine on one processor and unlowerable on the other, naming the construct
and the processor. A `pub` function states its processor and has one body.

*Laws:* 4; 6 (declared where promised to a reader who cannot see the body,
inferred where not); 7 (no plausible wrong fallback).

### 4. The machine is described, and the description is checked

A machine is a document with the facts of Part I, checked for coherence
before any program is. With writes its own descriptions from vendor
datasheets and from measurement, each figure citing where it came from.
**Only exact facts decide acceptance:** which spaces exist, who sees what,
capacity, granule, replicas, element types. A bandwidth figure never decides
whether a program compiles; it is reported (§10) and never a gate, because
the cost terms are known to be incomplete (§12).

*Laws:* 8 (the description ships in the SDK and pins the build); 7 (an
incoherent description is refused, never patched).

### 5. Reachability and routing are derived, not assumed

A transfer with no declared path is an error naming both spaces and the
edges that exist. When a path exists the compiler picks the cheapest legal
one over the declared edges, lowers it as hops, and reports it with its
per-edge cost. Routing through a declared intermediate space is the
machine's fact; a route through a host the description never mentioned is
refused. Peer edges between two devices' spaces (`gpu[0].HBM -> gpu[1].HBM`)
are ordinary edges from the first description on, because the eight-GPU
box is the target.

*Laws:* 7; 3 (placement decided in one stage, routing in the next, dispatch
in the last; none reconstructs another's fact).

### 6. Capacity admission

The working set a region places in a space must fit, after granule
rounding, against one replica, folded across calls as Part I describes,
recursion into a bounded space refused. A placement that does not fit is
refused with required, available and margin. A programmer who knows the
buffers do not coexist says so on the space, and the refusal becomes a
warning. With reads the working set off MIR's live placed owners. Host
memory is not capacity-checked. This is the one check with no equivalent in
any other language, and the one most worth having.

Static sizes only, in this plan. Real kernels size shared memory by the
launch configuration, not by a constant, so the first real kernel will hit
the dynamic case; the rule for it is decided before step 3 (Part IX), not
after. Until then a size the compiler cannot establish is reported as
unverified, never silently admitted.

*Laws:* 4 (being wrong rejects a valid program or lets one run out of memory
at runtime; neither is unsafety); 3 (the live set has one owner); 7.

### 7. Asynchronous transfer completion is an obligation

A transfer that has not completed cannot be observed through. With needs no
prover: an asynchronous transfer produces a task that becomes the placed
value only once awaited. Nothing here is an open ruling (§14.22).

*Laws:* 5; 1 (no proof obligation the type already carries).

### 8. Device allocations obey the leak rule

With already calls every leak a defect. A space the host may not read is
freed through the device API, which is a destruction contract the facade
states (D51 §65: no safe constructor without one), never a name. In this
plan the test machine's second space is backed by host memory and freed by
the ordinary allocator; the contract shape is the same.

*Laws:* the `with`-scope paragraph of the mission; 4.

### 9. Target-conditional compilation

With has it for the target (D91). The addition is the processor a region
runs on, a compile-time constant inside the region, selected before analysis
the same way.

*Laws:* 1.

### 10. Structured verdicts

Every placement, admission and routing decision is a fact in the one
database `with analyze` serves. A figure the compiler cannot count exactly
is absent with a reason, never partial and never zero.

*Laws:* 3; 7; 10.

### 11. The differential suite, and one measurement

For each check, a pair: the same mistake in With and in CUDA or Metal, where
With refuses at compile time what the native toolchain reports at
synchronization, at allocation, or as a fault. New work, not a port. The With
side runs on the Mac against a declared machine lowered on the host; the
native side runs where the hardware is, under the dispatch proposal.

Refusals alone do not make the admission figures trustworthy. The suite
also carries at least one model-versus-measurement comparison, as a ratio:
a working set the checker admits at a stated margin against a scratchpad,
run on the 5090 under the dispatch proposal, with the measured peak beside
the predicted one. The checker's number is only worth its margin if that
ratio is published.

*Laws:* 10.

### 12. The model is honest about itself

A declared bandwidth is the vendor's peak and says so. Predictions are
compared to measurements as ratios. A measurement that cannot be true is
refused before it is reported. Vx's own record of the gap (Part I) is why §4
makes cost advisory.

*Laws:* 7, applied to the model.

## Part IV — The spellings

### IV.1 A machine file

A machine is a With source file of `machine` declarations, shipped under
`lib/std/machine/` and selectable by name, or written by the project.

```
// lib/std/machine/m4_uma.w
machine m4_uma:
    memory Unified:
        capacity 32 GiB            measured: sysctl hw.memsize, this host
        bandwidth 120 GB/s         spec: Apple M4 product page
        managed cached             // the CPU reads it; so does the GPU
    memory Threadgroup:
        within Unified
        capacity 32 KiB            spec: Metal feature set tables
        scope threadgroup
        replicas 10                // GPU cores
    processor cpu:
        arch aarch64
        memory Unified
        sees Unified
    processor gpu:
        arch metal
        memory Unified
        sees Unified, Threadgroup
        dtypes f32, f16, bf16, i32, i16, i8, u32, u16, u8
    transfer Unified -> Threadgroup
```

```
// lib/std/machine/rtx5090_x2.w (shape only; the real file cites each figure)
machine rtx5090_x2:
    memory HBM[0]:
        capacity 32 GiB            spec: <vendor datasheet, date>
        managed explicit           // the host never reads it
    memory HBM[1]: as HBM[0]
    memory SMEM[0]:
        within HBM[0]
        capacity 228 KiB
        scope sm
        granule 16 KiB
        replicas 170               measured: <probe, date>
    memory SMEM[1]: as SMEM[0], within HBM[1]
    processor gpu[0]:
        arch nvptx sm_120
        memory HBM[0]
        sees HBM[0], SMEM[0]
        dtypes f32, f16, bf16, fp8, i32, i8
    processor gpu[1]: as gpu[0], memory HBM[1], sees HBM[1], SMEM[1]
    transfer host.DRAM -> HBM[0]: 63 GB/s copy_engine    spec: PCIe Gen5 x16
    transfer HBM[0] -> host.DRAM: 63 GB/s copy_engine
    transfer HBM[0] -> HBM[1]: 63 GB/s                  policy: via host until measured
    transfer HBM[1] -> HBM[0]: 63 GB/s
    transfer HBM[0] -> SMEM[0] copy_engine
```

Rules:

- `memory NAME[index]:` items are `capacity`, `bandwidth`, `clock`,
  `within`, `managed explicit|cached`, `scope`, `granule`, `replicas`,
  `overcommit`; `as OTHER` copies another space's items and the rest
  override. Units are exact: `KiB MiB GiB` binary, `KB MB GB TB` decimal,
  `B/s`, `B/cyc` (with `clock` required to compare against `B/s`). A figure
  may carry a provenance trailer: `spec: <text>`, `measured: <text>`,
  `policy: <text>`; the trailer is a fact, and `with analyze` reports it.
- `processor NAME[index]:` items are `arch`, `memory` (its default space),
  `sees` (the visible set), `dtypes`, and `as OTHER`.
- `transfer A -> B[: rate] [copy_engine] [relaxed]`. One cost per edge: a
  declared rate on an edge whose endpoints both declare bandwidths is an
  error, as in Vx (`arch.rs:117`). Peer edges between devices are ordinary.
- The host is `host`: its spaces (`host.DRAM`) come from the `--target`
  machine, which is the host file. A host declares no capacity.
- Coherence checks on the file alone, before any program: `within` acyclic;
  child capacity ≤ parent; scope narrows downward; every figure positive;
  every processor sees its own `memory`; `sees` names declared spaces; no
  name declared twice across host, machine and program; a route that stages
  through `host` requires the host to be declared, which `--target` always
  is.

### IV.2 Selecting the machine: visible, and pinnable

```
with build                          # [machine] detected m4_uma (unambiguous)
with build --machine rtx5090_x2     # pins a shipped description
with build --machine ./fleet/box.w  # pins a project file
with check prog.w --machine rtx5090_x2 --target x86_64-linux
```

- `--target` stays what it is: the host, its triple and its spaces.
  `--machine` adds the offload processors. The machine's `arch` and the
  target must be a pair the toolchain can emit for; a mismatch is a
  diagnostic.
- **Detection is visible.** Every build prints the machine it detected
  (`[machine] detected m4_uma`) or pinned (`[machine] rtx5090_x2 (with.toml)`),
  the way it prints the compiler it ran, so two laptops never differ
  silently. Detection must be able to say "I cannot tell" and then refuses
  rather than guesses: a Linux box with no GPU detects `host only`; a box
  with two different GPUs refuses without `--machine`.
- **Anything shipped pins.** `machine = "rtx5090_x2"` in `with.toml`
  (`src/compiler/ProjectConfig.w:131`) is the pin; a project that places
  buffers and has no pin gets a warning naming the detected machine and the
  line to add. The pinned machine is a tracked input of the build key
  (§17.1a), so a changed description rebuilds.

### IV.3 Placement in types

```
let w: Buffer[f32, rtx.HBM[0]] = Buffer.zeroed(n)   // the demand binds the space (Law 2)
let x = Buffer.zeroed[f32](n)                        // host: the default representation
let y = Buffer.uninit[f32, rtx.SMEM[0]](tile)        // explicit, when nothing demands it
let s: &[f32] in rtx.SMEM[0] = y[0..tile]            // a view carries the buffer's space
extern fn cublas_sgemm(a: *const f32 in rtx.HBM[0], ...)
```

- `Buffer[T, S]` is a fixed-length owned allocation in space `S`; `Buffer[T]`
  is `Buffer[T, host.DRAM]`. `Vec[T]` stays host-only; growth is a host
  operation. Whatever tensor type With later rules on carries the same slot.
- A space is a type-level constant of the pinned machine, spelled
  `<machine>.<space>` (`rtx.HBM[0]`), or `Machine.<space>` for the pinned one
  without naming it. There are no ids, no hashing; a space no processor
  holds is a name-resolution error.
- `&T in S`, `&mut T in S`, `&[T] in S`, `*const T in S`, `*mut T in S`: the
  pointee's space, `host.DRAM` when absent. `&[f32] in host.DRAM` is the
  same type as `&[f32]`, so every existing signature is a host signature.
- `Buffer[T, S]` is never `Copy`, and a view into it is a view like any
  other (D22/D27: observing is not owning).
- Element types a processor cannot represent are refused at the placement.

### IV.4 Transfer

```
let d = transfer(w, rtx.HBM[0])            // consumes w; d: Buffer[f32, rtx.HBM[0]]
let d2 = transfer(w.clone(), rtx.HBM[0])   // keep the host copy: say so
let p = transfer(d, rtx.HBM[1])            // a peer edge, if declared; else routed through host
let t = async transfer(w, rtx.HBM[0])      // Task[Buffer[f32, rtx.HBM[0]]]
let d3 = t.await                           // only now is there a placed value
```

- `transfer` is a `std` generic, `fn transfer[T, A, B](b: Buffer[T, A]) -> Buffer[T, B]`,
  with `B` bound by the argument or the demand. It consumes.
- The route is derived over declared edges and lowered as hops; in this plan
  each hop is a host copy in the test runtime. No path is an error naming
  the spaces and the edges that exist; a route through an undeclared host
  is refused.
- `async transfer` is the `async` form of the same call, under §14.22. A
  relaxed publication (no completion wait) is library-maintainer tier and
  not in the first surface.

### IV.5 Regions

```
on rtx.gpu[0]:                           // sequential meaning; the runtime may overlap as-if
    for i in 0..n: d[i] = d[i] * 2.0

let t = async on rtx.gpu[0]:             // Task[T]; §14.22 capture rules; drop cancels
    reduce(d)

pub fn softmax(x: &[f32] in rtx.HBM[0]) on rtx.gpu:    // a published boundary declares (Law 6)
    ...

fn helper(x: &[f32] in Machine.HBM[0]):                 // package-local: instantiated per caller's processor
    ...

comptime match Processor.Current.arch:  // inside a region; selected before analysis (D91)
    .Metal => threadgroup_reduce(d)
    .Nvptx => warp_reduce(d)
```

- `on <processor>:` is a block statement or expression; its value is the
  block's value, not placed. `async on` yields a `Task`.
- Inside the block every place read or written must be in a space the
  processor `sees`. The error: `'d' lives in host.DRAM, but rtx.gpu[0] sees
  only [HBM[0], SMEM[0]]; transfer it first: let d = transfer(d, rtx.HBM[0])`.
- A call from a region to a `pub` function declared for another processor
  is an error. A call to a package-local function instantiates it for the
  region's processor (§3); if that instance cannot be lowered, the error is
  at the call, naming the construct and the processor.
- `Processor.Current` is the region's processor, a compile-time constant;
  outside any region it is the host's CPU.
- A region whose body the backend cannot lower for the processor is a
  compile error naming the construct, never a host fallback. In this plan
  every processor lowers on the host, so the check is exercised by a test
  machine whose processor declares an arch the host backend refuses.

### IV.6 Verdicts

```
with analyze prog.w 'select:kind=placement'  // owner, space, bytes, provenance of the size
with analyze prog.w 'select:kind=route'      // transfer site, path, per-edge cost, unit, source
with analyze prog.w 'select:kind=capacity'   // function, processor instance, space, required, available, margin
with analyze prog.w 'select:kind=traffic'    // region, buffer, bytes read, bytes written, or absent: <reason>
with analyze prog.w 'explain:machine'        // the pinned machine, every figure with its provenance
with analyze prog.w 'explain:route:<site>'   // why this route and not another
with analyze prog.w 'explain:instances:<fn>' // the processors a package-local function is compiled for, and why
```

### IV.7 Diagnostics

One family, each with a fix-it where one exists:

| situation | message shape |
|---|---|
| read outside visibility | `'d' lives in host.DRAM, but gpu[0] sees only […]; transfer it first` |
| no path | `no transfer path from SMEM[0] to host.DRAM on rtx5090_x2; declared edges: …` |
| undeclared host on a staged route | `the route host.DRAM -> HBM[0] stages through the host, and --target names none` |
| over capacity, one buffer | `'tile' needs 262144 B in SMEM[0], which holds 233472 B (margin -28672 B)` |
| over capacity, working set | `… places 3 buffers, 294912 B after 16 KiB granules, in SMEM[0] (233472 B)` |
| over capacity across calls | `… holds 'tile' (…) across the call to f, whose own peak in SMEM[0] is …` |
| recursion into a bounded space | `f places into SMEM[0] and calls itself; the peak is unbounded` |
| element type | `fp8 is not an element type m4.gpu declares` |
| pointer space at a call | `expected *const f32 in HBM[0], found *const f32 (host.DRAM)` |
| not lowerable, this processor | `helper is called from gpu[0], and … has no lowering there (fine on cpu)` |
| unverified size | warning: `'buf' has no static size; its placement in SMEM[0] is unverified` |
| no pin | warning: `this program places buffers; pin the machine: machine = "m4_uma" in with.toml` |
| incoherent machine | `machine rtx5090_x2: SMEM[0] (228 KiB) is larger than its parent …` |

## Part V — Architecture: where each piece lands

The pipeline is Parse → Sema (what) → MIR (where and when) → codegen (how),
with the build layer around it. Each row names the owner of the new fact
(Law 3) and the files it touches. Everything below is the checker; nothing
here needs a device backend.

### V.1 Machine files

- **Parser** (`src/Parser.w`, `src/Ast.w`): new declaration kinds
  `NK_MACHINE`, `NK_MEMORY_DECL`, `NK_PROCESSOR_DECL`, `NK_TRANSFER_DECL`,
  a size/rate literal grammar (`80 GiB`, `3.35 TB/s`, `128 B/cyc`), the
  `as OTHER` copy, and the provenance trailer as a token sequence on the
  item.
- **Loading** (`src/compiler/DriverOptions.w`, `src/main.w`,
  `src/compiler/Frontend.w:2587`, `src/compiler/Zcu.w:220`): `--machine`
  resolves a name under the embedded `lib/std/machine/` or a path, and the
  file enters the compilation as a peer module the way the prelude does. It
  is a tracked input (`src/compiler/TrackedInputs.w`), part of the build key
  and the bundle fingerprint; `with.toml` pins it
  (`src/compiler/ProjectConfig.w`). Detection lives beside
  `target_spec_host_kind` (`src/TargetSpec.w:50`), answers a name or
  "cannot tell", and is printed on every build.
- **Sema** (new `src/SemaMachine.w`): one `MachineModel` per compilation:
  spaces, processors, edges, the containment tree, the all-pairs route
  table computed once, and the coherence checks run on the model before any
  body is checked. The host's spaces come from the target. Duplicate names
  across host, machine and program are refused here.
- **Facts** (`src/AnalysisTypes.w:17`, `src/Analysis.w`): `explain:machine`.

### V.2 Placement in types

- **Types** (`src/SemaTypes.w`, `src/Sema.w`): a space is a type-level
  constant, `TypeKind.TY_SPACE`, interned by machine and name the way
  `Vector[N, T]` carries `N` in a data slot (`src/SemaVector.w:4`,
  `ensure_exact_type` at `:48`). Pointer, reference and slice type kinds gain
  a space slot; the host space is id 0 so every existing type interns to
  the same id, which is what keeps today's programs, ABI hashes and the
  fixpoint untouched. `Buffer[T, S]` is a `std` type whose second parameter
  is a space.
- **Checking** (`src/SemaCheck.w`): a `current_processor` stack set by `on`
  blocks and by an `on` clause on a signature; every place read or write
  and every call argument asks `MachineModel.sees(current_processor,
  space_of(type))`. Element-type admission at every placement site.
- **Instantiation** (`src/Sema.w` specializations): a package-local function
  reached from a region is specialized on the processor as on a type
  argument; the instance is keyed `(fn, processor)`, appears in the
  `specialization` facts and in `explain:instances`, and is checked once
  per processor so a construct unlowerable on one is reported at that
  caller. A `pub` function with an `on` clause has one instance.
- **Codegen** (`src/Codegen.w`): in this plan every instance compiles in the
  host unit; the instance key reaches the symbol name so two bodies never
  collide. Address spaces in the LLVM bridge belong to the dispatch
  proposal.

### V.3 Transfer and routing

- **std** (`lib/std/buffer.w`, new): `Buffer[T, S]` with `zeroed`, `uninit`,
  `len`, indexing, views, `Drop`; `transfer[T, A, B]`. Allocation, free and
  copy are selected by `comptime match` on the processor owning `S`; in
  this plan every arm is the host allocator and a host copy, with the
  `managed explicit` test space tagged so a host read of it is refused by
  the checker and trapped by the debug allocator if it ever happens.
- **Sema**: at each `transfer` call, `MachineModel.route(A, B)`; no route is
  the diagnostic; the route is recorded as a `route` fact with per-hop cost
  (derived from bandwidths or the declared rate, with unit and source).
- **MIR** (`src/MirLower.w`): a multi-hop transfer lowers as a chain of
  single-hop calls with the intermediate buffers as ordinary temporaries,
  dropped by the ordinary drop plan; nothing new in drop scheduling.

### V.4 Regions

- **Sema**: `on` pushes the processor; `async on` is an `async:` block with
  a processor (§14.22 capture rules, ephemeral when a view is captured).
- **MIR/async** (`src/AsyncLower.w:62`): a region body is outlined into its
  own body tagged with its processor, the way an async block is; the
  sequential form is the same outlining followed by an immediate await. The
  tag is a MIR fact that the dispatch proposal's codegen units will read;
  in this plan it selects nothing and is reported.

### V.5 Capacity

- **MIR pass** (new `src/MirCapacity.w`, reading `src/MirCore.w:1649`): per
  body instance, per space, the maximum over program points of the
  granule-rounded sum of live placed locals whose size is static; the
  summary also records, for each call, what is live across it. Sizes are
  exact integers from the type and the constant length; a non-constant
  length makes the owner "unverified" and the function's verdict a warning,
  pending the Part IX decision.
- **Fold** over the live MIR call graph (`with analyze`'s `path:call` data,
  `src/Analysis.w:707`): sequential calls by max, held-across by plus,
  strongly connected components refused when they place into a bounded
  space; `overcommit` on the space turns the refusal into a warning.
- **Facts**: `capacity` rows with required, available, margin, buffers.

### V.6 Facts and tools

- `src/AnalysisTypes.w`: `Placement = 29`, `Route = 30`, `Capacity = 31`,
  `Traffic = 32`. Collectors beside `analysis_collect_types`
  (`src/Analysis.w:292`). `explain:machine`, `explain:route:<site>`,
  `explain:instances:<fn>` dispatched in `src/compiler/Compilation.w` with
  the other explainers.
- `docs/spec/toolchain/deep-debugging-tools.md`: a placement route (the
  hunt for "why was this refused" is one `explain:route` run).

### V.7 The test machine

`test/placement/machines/two_space.w` declares a host and one `managed
explicit` device space with a scratchpad under it, a processor whose arch
is `test` (lowered on the host), and the edges; a second file declares two
such devices with a peer edge, for the routing pairs. The test runtime
backs both device spaces with host memory the checker refuses to read
directly. Every check in this plan is exercised against these two files
without a GPU.

### V.8 Tests and gates

- `test/placement/`: one With fixture per check with `//! expect-error:`
  headers; each refusal fixture names its CUDA or Metal twin and the
  native failure mode in one line, and the twins live beside them for the
  dispatch proposal's `:placement-native` target. `:placement-tests` joins
  the gate's fixed list.
- The `async on` drop test: a task from `async on` dropped un-awaited is
  cancelled (§14.22) and its placed result never exists; a behavior test
  pins it in step 2, since the plan depends on it.
- `with build :machine-check` validates every shipped description's
  coherence and provenance trailers (every figure has one); it joins
  `spec-inventory-check` in the gate.
- `:user-programs-safe` is unchanged: a user program places buffers and
  runs regions without `unsafe`.

### V.9 Spec

New chapter `docs/spec/placement.md` (§23: machines, spaces, placement,
transfer, regions, per-processor instantiation, capacity), with
projections into §4 (types), §14 (regions as async blocks), §17.5
(`Processor.Current`), §18.5 (`--machine`, detection, the pin). Only Eric's
words land there.

## Part VI — Order of work

Each step is one stack with one battery, buildable by the pinned seed.

1. **Machine files and facts.** Parser, loader, `SemaMachine`, coherence
   checks, `--machine`, detection printed on every build, the `with.toml`
   pin, `lib/std/machine/m4_uma.w` and `rtx5090_x2.w` with cited figures,
   `explain:machine`, `:machine-check`. No codegen change.
2. **Placement, transfer, regions, visibility, host-lowered.** `TY_SPACE`,
   the space slot on pointer, reference and slice types, `Buffer[T, S]`,
   `transfer`, `on` and `async on`, per-processor instantiation, the
   visibility and call checks, routing including peer edges, the
   diagnostics of IV.7, `placement` and `route` facts, the two test
   machines, the `async on` drop test.
3. **Capacity from MIR.** The Part IX dynamic-size ruling first, then
   `MirCapacity`, the fold, `capacity` facts, the over-capacity pairs.

That is this plan. Dispatch (device codegen units, the Metal and CUDA
facades, the native half of the suite, the measurement comparison, real
overlap for `async on`, region traffic, user-written lowerings) is
`vx-dispatch.md`, briefed separately after step 3.

## Part VII — Where With departs from Vx

- **Detection.** Vx holds the programmer to the machine they named, never
  the one plugged in. With detects when the answer is unambiguous, prints
  what it detected, and takes a pinned description otherwise (Law 1 to
  detect, Law 8 to pin).
- **The host.** Vx removed `--target` and made the host a file. With keeps
  `--target` as the host and adds `--machine` beside it; the two must agree.
- **Ceremony.** No wrappers that restate placement, no `self` on every
  method, no explicit returns of nothing (Laws 1 and 9).
- **Where code runs.** Inferred inside a package and instantiated per
  processor; declared at a published boundary (Law 6).
- **Transfer.** Consumes (§2).
- **Proof.** A type fact, not a solver (§7).
- **Placement everywhere bytes are.** Every owner and view, not only a
  tensor and a pointer; host signatures are host signatures.
- **Acceptance.** Exact facts only; cost is advisory (§4).

## Part VIII — What is not taken

- Solver-discharged contracts and `Verified`; `HardwareState`, `try_pin`,
  `effects(...)`: unimplemented in Vx and restating what the type and the
  signature carry.
- A processor as an integer with hashed identities; `unroll across`; the
  seam prover.
- Autodiff and the MLIR pipeline.
- Shapes in types: a separate decision.
- NUMA nodes as spaces: out of this plan; the two-socket box is the
  measurement story, not the checker's first target.
- Vx's base-language choices (explicit numeric conversions both ways,
  mandatory return types, provenance-based view detection, no supertraits,
  no `if let`): With has ruled each its own way.

## Part IX — Open questions this plan depends on

- **Dynamic sizes, decided before step 3.** Real kernels size shared memory
  by the launch configuration. Options: (a) a placement with a non-static
  size is an unverified warning (v1 as written); (b) the launch stub checks
  the size against the declared capacity at run time and panics with the
  same figures the compiler would have printed; (c) both, with the runtime
  check only where the warning fires. Prediction: (c), because a warning
  the programmer cannot discharge is ceremony (Law 1) and a silent overflow
  is the wrong plausible thing (Law 7); the run-time check is the compiler
  doing the work it could not do statically.
- `Buffer[T, S]` as a new type versus a placement slot on existing owners;
  `in S` as the spelling on views and pointers.
- Consuming iteration (the `into_iter` ruling), since a transfer of a
  collection's elements between spaces is the same shape.
- Who measures the shipped descriptions' figures, and when the `policy:`
  figures in `rtx5090_x2.w` become `measured:`.
