# vx-dispatch.md — running placed code on the device

The second half of `vx.md`. That plan delivers the checker: machine files,
placement in types, transfer, regions, visibility, routing and capacity,
all lowered on the host. This proposal is everything that needs a device
backend. It is written now so the checker is designed with it in view, and
it is **not approved by the ruling that approves the checker**: it gets its
own brief, after the checker has shown what it is worth on real With
programs and after the run-time compiler question below is answered.

Why it is separate: the cost changes kind here. The checker is a bounded
campaign on the existing architecture. Dispatch is a codegen unit per
device arch, facades over vendors' driver APIs, hardware-dependent
batteries on real boxes, and from then on every language change has a
device-backend consequence. For a one-person project with open rulings
still queued that is a standing tax, and a standing tax is a decision, not
a step.

## No vendor in the compiler

The rule this proposal is built under: the compiler knows device archs as
entries of an open list (what LLVM can target, plus platforms with their
own path) and knows a device through its machine file and its facade.
Every vendor fact — an API, a header, a memory map, a link, a run-time
compiler, a tuned library — lives in a facade or a machine file. Adding a
vendor is an arch entry, a facade and a machine file, never a change to a
rule, a diagnostic or a lowering decision. The first backend is built on
the hardware at hand; the second is built to prove nothing in the first
leaked into the design; and the plan is not done until a third vendor's
box runs the same programs from its own machine file.

## What it delivers

- **Codegen units per processor** (`src/compiler/CodegenUnits.w`,
  `src/TargetSpec.w:115`): bodies instantiated for a non-host processor
  (`vx.md` §3) compile in a unit for that arch's target; the host unit
  holds the launch stub. The instance key the checker already puts in the
  symbol name is what keeps the two bodies apart. A body the device backend
  refuses is an error at the call site, as the checker already reports it;
  nothing falls back to the host.
- **Address spaces** (`src/compiler/LlvmBridge.w:737`): a pointer into a
  non-host space is an LLVM pointer in the address space the arch assigns
  to that kind of memory (global, workgroup-local, private, in each
  target's own numbering); the bridge gains a pointer-type-in-address-space
  constructor and the arch entry supplies the numbers. `FnAbi` is
  unchanged: a pointer with a space is a pointer (D6).
- **The device facades** (`lib/std/device/<platform>.w`), one per platform
  API, each a `c facade` over the vendor's header with `c_import` as the
  evidence and every ownership fact from a clause (D51). The surface is
  the same for every platform, because it is Crux's `Backend` trait
  generalized: device enumeration and properties; allocate (a resource
  producer) and free (its destroyer); copy within a device, between
  devices, and to and from the host; queue create, submit and sync;
  launch; event record, wait, query and elapsed time; a status `ok`
  value. `Buffer[T, S].drop` for a space a device owns calls that
  platform's destroyer: the leak rule (§8) made real. The first facade is
  written for the hardware at hand; the second must fit the same shape
  without changing the shape, or the shape was wrong.
- **Transfer lowering**: each hop of a routed transfer becomes the facade
  copy for its edge; `copy_engine` edges use the asynchronous copy and
  `async transfer` becomes a real task with a completion event behind it
  (`lib/std/task.w`). A `peers` access (`vx.md` IV.1) is a plain load or
  store through the mapped link. `async on` overlaps with host work; the
  sequential `on` waits at region exit. The checker's sequential forms
  are unchanged and stay correct.
- **One queue per region.** A region's launches and copies go to one
  in-order queue and never interleave; cross-region ordering is the task
  and its completion event behind `.await`. This is Crux's three
  happens-before rules with nothing left over to be a data race.
- **Kernels compile at build time.** A region body instantiated for a
  processor is compiled by the With compiler into that arch's form (an
  ISA or IR the driver finalizes, or source text for a platform that only
  accepts source, below); at run time the facade builds the pipeline
  state once per kernel symbol and device and caches it. Crux's run-time
  `Program` compile and its per-process compile cache do not exist:
  specialization constants (`TILE`, a shape known at build time) are
  comptime instantiation, and a dynamic shape is a kernel argument.
- **What Crux's substrate becomes.** Its twenty backend methods are the
  facade surface above. `free_after` has no counterpart: a buffer a region
  captured is owned by the region's task until it completes. `Arena` is a
  library allocator over one placed `Buffer`, and its reset is ordinary.
- **Cancellation, stated honestly.** Regions inside an async scope cancel
  as a unit when a sibling fails or the scope is dropped (§14.22), which
  is what a speculative-decode pipeline or a two-device stage needs and
  what no vendor runtime offers. What cancellation means on a device:
  queued launches are never submitted, nothing is awaited, and the
  buffers a cancelled region captured are released only after the device
  has drained the work already running. No runtime stops a running
  kernel, and the plan does not claim to.
- **Kernels as values.** A region instantiated for a processor is a
  symbol in the device unit; a `Kernel` value naming it can be stored,
  passed and chosen among (`[Kernel]` a scheduler picks from by
  `Processor.Current`), with its footprint and placement already
  admitted. Driver-side compilation of source text at run time is the
  exception a program must spell, never the default.
- **Advisory facts, after traffic.** `with analyze 'roofline:<region>'`
  divides the region's counted traffic by the machine's declared
  bandwidths and reports arithmetic intensity against the ridge point,
  per machine, from source: "memory-bound at 11% of device-memory peak on
  two_gpu_box". Two caveats are part of the fact: traffic counts touches,
  not footprint, so the intensity is a bound; and bandwidth is a `spec:`
  or `measured:` figure, so the number is advisory and never a gate (§4).
  `with analyze 'suggest:placement'` reads the same facts and says where a
  buffer should have been placed ("`weights` is read by three regions on
  gpu[0] and never by the host; placing it in HBM at declaration removes
  two transfers"). The transfer stays written (Law 5); the compiler says
  where. Vx refuses; With advises.
- **The kernel migrator, after the Crux six.** `with migrate` for device
  source in the vendors' kernel languages (the C-with-attributes family:
  CUDA C, HIP, OpenCL C; and MSL), the C migrator's method applied to
  device code: a kernel entry attribute to `on gpu:`, a workgroup-shared
  array declaration to a scratchpad `Buffer`, thread, block and grid
  index builtins to `parallel[workgroup]` and `parallel[grid]` bindings,
  the workgroup barrier to `barrier()`, subgroup shuffles and atomics to
  their std forms, the host-side copy call to `transfer` with the route
  derived, device pointer parameters to `in S` with nullability by
  evidence. Each language is a table in the migrator, not a rule in the
  compiler. Its product is the migration diff: every latent "this faults
  on a smaller card" in a real library (an inference engine's kernels, a
  flash-attention implementation, the simpler layers of a vendor's
  template library) reported as a refusal with a fix-it. Its failure mode
  is Law 7's exact trap: a construct it cannot lower is a loud refusal
  naming the kernel and the line, never a plausible approximation of a
  barrier or an atomic. It needs a device to validate its output, so it
  is dispatch work; what the checker plan owes it now is a spelling in
  IV.5a for every construct it will meet.
- **The probe's device half.** `with machine probe` reads the platform's
  own topology report (which devices see which, whether a link is mapped
  or copy-only, through the driver's query API), measures bandwidth with
  a copy loop per edge, measures peer rates and contention ratios, writes
  them as `measured:` figures beside the `spec:` ones with the
  prerequisites they depended on (`vx.md` IV.1), and refuses any figure
  that cannot physically be true. This closes the loop Vx left open: the
  thing that verifies the model ships with it.
- **Region traffic** (`traffic` facts, `vx.md` §10): bytes a region reads
  and writes per placed buffer, per launch, counted from MIR; one
  uncountable access makes the region's figure absent with a reason.
- **The native half of the suite**: `:placement-native` runs each With
  fixture's native twin (the same mistake in the platform's own kernel
  language) where the hardware is, and asserts it fails the way the With
  fixture claims. A battery target, not a gate; the set of platforms it
  covers is the set of boxes available, named in the battery's report.
- **The measurement comparison** (`vx.md` §11): at least one working set
  the checker admits at a stated margin, run on a device, with measured
  peak beside predicted as a ratio, published with the description's
  figures. This is what makes the checker's margins trustworthy, and it
  is the evidence the fresh brief must carry. Crux's benchmark targets,
  generalized, are the comparison set: each platform's tuned vendor
  library and one well-known inference engine on that platform, the six
  programs against them as ratios, beside the model's predictions.
- **User-written transfer lowerings**, if ever: a package implements the
  move across one edge in a handful of indexed primitives (no addresses,
  capabilities from the machine file, a barrier only where every thread
  reaches it). Its bounds obligations need a prover; library-maintainer
  tier, last.

## The run-time compiler question

Reaching a device without a host-toolchain dependency (Law 8) is the
hardest dependency decision in either proposal, and it is asked per arch
before any dispatch work starts. Every platform offers some of three
routes:

- **The vendor's source compiler in a host toolkit at build time** (a
  shader compiler from an IDE, a kernel-language compiler from an SDK)
  makes the build depend on a host toolchain, which the zero-dependencies
  rule forbids for an ordinary build. Never.
- **An ISA or IR that LLVM emits and the driver finalizes** (an LLVM
  target the SDK already carries; the driver's own finalizer is always
  present with the driver). The build reads only our SDK and the program
  needs only the OS and its driver: Law 8 holds with nothing to decide.
  Preferred wherever the arch is an LLVM target.
- **Source text compiled at run time by a compiler the OS ships** (a
  platform whose only public contract is its shading language, handed to
  the OS framework at start-up, once per kernel and device; Crux's own v1
  answer for one such platform). The compiler is part of the OS, not of a
  toolkit, so Law 8 holds; the cost is a start-up compile and a
  dependency on the text format staying accepted. Taken where the second
  route does not exist, as the spelled exception the kernels-as-values
  rule names.

Prediction: the second route for every arch that is an LLVM target, the
third for a platform that offers only source text, the first never, and
any platform's private binary IR only if it becomes a public contract.
The brief for this proposal confirms it per arch with the reference
projects' evidence before the first facade is written.

## What the fresh brief must contain

1. The checker in use: Crux's six validation programs (elementwise add,
   matmul, softmax, flash attention, quantized matmul, KV cache update)
   written on `vx.md`'s surface and running host-lowered in
   `test/placement/crux/`, checked against both shipped machine shapes,
   with every refusal classified as a real bug, a checker gap, or a
   missing ruling. Plus at least one program from the serving stack.
2. The run-time compiler answer, per arch the first two backends cover.
3. The dynamic-size ruling (`vx.md` Part IX) in force, since launch
   configurations are where it bites.
4. The measurement plan: which description figures become `measured:`, with
   what instrument, and the first predicted-versus-measured ratio.
5. The standing cost, stated: which gates and batteries become
   hardware-dependent, which boxes they need, and what a language change
   must re-run.
6. The vendor-neutrality evidence: the second backend fitting the first's
   facade shape and arch entry without a rule changing, and the plan for
   the third.

## Crux, after this

Crux is rewritten from scratch on top of this proposal, and most of its
planned size does not return: Phase 1's substrate core (eight sessions)
and Phase 5's backends are the facades and the codegen units; Phase 2's
core programs are the Crux six plus the elementwise and data-movement
kernels written as regions; the Program IR, its text parser, its
validation pass, its compile cache and its register allocation are MIR
and the codegen unit. What remains Crux's is Part 8: strided views over
`Buffer` views, the tensor library, autograd, the modules, the paged KV
cache and the inference engine, with none of Part 4's "is UB".

## Order, if approved

1. The first discrete-GPU backend, on the hardware at hand: its facade,
   its codegen unit and address spaces, real transfers, `Buffer` drops
   through its destroyer, `:placement-native` for its twins, the Crux six
   on the device.
2. The measurement comparison, the probe's device half, and the first
   `measured:` figures.
3. Real overlap for `async on` and `async transfer`, with cancellation as
   stated above; kernels as values.
4. The unified-memory backend, per the run-time compiler answer for its
   platform: the second facade, which must fit the first's shape.
5. Region traffic, then the advisory facts (`roofline`, `suggest`).
6. The kernel migrator, with a real library as its acceptance.
7. A third vendor's backend as soon as a box exists, as the neutrality
   test; user-written lowerings, if ever.

What comes after both proposals, and what each needs before it is
briefed, is `vx-frontier.md`.
