# vx-dispatch.md — running placed code on the device

The second half of `vx.md`. That plan delivers the checker: machine files,
placement in types, transfer, regions, visibility, routing and capacity,
all lowered on the host. This proposal is everything that needs a device
backend. It is written now so the checker is designed with it in view, and
it is **not approved by the ruling that approves the checker**: it gets its
own brief, after the checker has shown what it is worth on real With
programs and after the Metal question below is answered.

Why it is separate: the cost changes kind here. The checker is a bounded
campaign on the existing architecture. Dispatch is a second codegen unit
per device arch, facades over two vendor driver APIs, hardware-dependent
batteries on two boxes, and from then on every language change has a
device-backend consequence. For a one-person project with open rulings
still queued that is a standing tax, and a standing tax is a decision, not
a step.

## What it delivers

- **Codegen units per processor** (`src/compiler/CodegenUnits.w`,
  `src/TargetSpec.w:115`): bodies instantiated for a non-host processor
  (`vx.md` §3) compile in a unit for that arch's triple; the host unit
  holds the launch stub. The instance key the checker already puts in the
  symbol name is what keeps the two bodies apart. A body the device backend
  refuses is an error at the call site, as the checker already reports it;
  nothing falls back to the host.
- **Address spaces** (`src/compiler/LlvmBridge.w:737`): a pointer into a
  non-host space is an LLVM pointer in the processor's address space
  (global, shared, for nvptx); the bridge gains a pointer-type-in-address-
  space constructor. `FnAbi` is unchanged: a pointer with a space is a
  pointer (D6).
- **The CUDA facade** (`lib/std/device/cuda.w`): `c facade cuda:` over the
  driver API, with `c_import` of the vendor header as evidence and every
  ownership fact from a clause (D51): `cuMemAlloc` producer, `cuMemFree`
  destroyer, `cuMemcpyHtoD`/`DtoH`/`DtoD` and the peer copy, streams,
  events, `cuLaunchKernel`, `ok CUDA_SUCCESS`. `Buffer[T, S].drop` for a
  space `gpu[i]` owns calls the destroyer; that is the leak rule (§8) made
  real.
- **The Metal facade** (`lib/std/device/metal.w`): `c facade metal:` over
  the Metal C-callable surface (device, command queue, buffer, library,
  pipeline state, command buffer, encoder), with the same discipline.
- **Transfer lowering**: each hop of a routed transfer becomes the facade
  copy for its edge; `copy_engine` edges use the asynchronous copy and
  `async transfer` becomes a real task with a completion event behind it
  (`lib/std/task.w`). `async on` overlaps with host work; the sequential
  `on` waits at region exit. The checker's sequential forms are unchanged
  and stay correct.
- **One queue per region.** A region's launches and copies go to one
  in-order stream and never interleave; cross-region ordering is the task
  and its completion event behind `.await`. This is Crux's three
  happens-before rules with nothing left over to be a data race.
- **Kernels compile at build time.** A region body instantiated for a
  processor is compiled by the With compiler into that arch's form (PTX,
  or MSL text, below); at run time the facade builds the pipeline state
  once per kernel symbol and device and caches it. Crux's run-time
  `Program` compile and its per-process compile cache do not exist:
  specialization constants (`TILE`, a shape known at build time) are
  comptime instantiation, and a dynamic shape is a kernel argument.
- **What Crux's substrate becomes.** Its `Backend` trait's twenty methods
  are the facade surface: device enumeration and properties, allocate and
  free (the resource's producer and destroyer), copy within and between
  devices and to the host, queue create and sync, launch, event record,
  wait, query and elapsed time. `free_after` has no counterpart: a buffer
  a region captured is owned by the region's task until it completes.
  `Arena` is a library allocator over one placed `Buffer`, and its reset is
  ordinary.
- **Region traffic** (`traffic` facts, `vx.md` §10): bytes a region reads
  and writes per placed buffer, per launch, counted from MIR; one
  uncountable access makes the region's figure absent with a reason.
- **The native half of the suite**: `:placement-native` runs the CUDA and
  Metal twins where the hardware is (the Mac for Metal, `eric-5090` for
  CUDA) and asserts each fails the way its With fixture claims. A battery
  target, not a gate.
- **The measurement comparison** (`vx.md` §11): at least one working set the
  checker admits at a stated margin, run on the 5090, with measured peak
  beside predicted as a ratio, published with the description's figures.
  This is what makes the checker's margins trustworthy, and it is the
  evidence the fresh brief must carry. Crux's benchmark targets (MPS and
  MLX on the Mac, cuBLAS and llama.cpp on Linux) are the comparison set:
  the six programs against the vendor library, as ratios, beside the
  model's predictions.
- **User-written transfer lowerings**, if ever: a package implements the
  move across one edge in a handful of indexed primitives (no addresses,
  capabilities from the machine file, a barrier only at the top of the
  body). Its bounds obligations need a prover; library-maintainer tier,
  last.

## The Metal question

Reaching the Mac's GPU without a host-toolchain dependency (Law 8) is the
hardest dependency decision in either proposal, and it is asked before any
dispatch work starts:

- **Metal Shading Language through Xcode's `metal` tool at build time**
  makes the build depend on a host toolchain, which the zero-dependencies
  rule forbids for an ordinary build.
- **MSL text compiled at run time by Metal.framework** (Crux's own v1
  answer: "IR → MSL → MTLLibrary → MTLComputePipelineState"): the With
  compiler emits MSL text for a region at build time, and the program
  hands it to the OS's Metal framework at start-up, once per kernel and
  device. The compiler is part of macOS, not of Xcode, so the build reads
  only our SDK and the program needs only the OS: Law 8 holds. CUDA has
  the same shape through the driver's run-time compiler on a host that has
  the toolkit, which the Linux host-library rule already permits.
- **AIR through LLVM** means the SDK carries what it needs, but the AIR
  format is not a public contract and may change under the toolchain.
- **CUDA only, Mac as host-only** means the Mac checks and never runs placed
  code, which keeps the Mac's build pure and moves every native run to
  `eric-5090`.

Prediction: the second option for v1, with direct PTX emission on Linux
where LLVM already targets nvptx, and AIR as the long-term Metal path if
it stabilizes. The brief for this proposal confirms it with the reference
projects' evidence before the first facade is written.

## What the fresh brief must contain

1. The checker in use: Crux's six validation programs (elementwise add,
   matmul, softmax, flash attention, quantized matmul, KV cache update)
   written on `vx.md`'s surface and running host-lowered in
   `test/placement/crux/`, checked against `rtx5090_x2.w` and `m4_uma.w`,
   with every refusal classified as a real bug, a checker gap, or a
   missing ruling. Plus at least one program from the serving stack.
2. The Metal answer.
3. The dynamic-size ruling (`vx.md` Part IX) in force, since launch
   configurations are where it bites.
4. The measurement plan: which description figures become `measured:`, with
   what instrument, and the first predicted-versus-measured ratio.
5. The standing cost, stated: which gates and batteries become
   hardware-dependent, which boxes they need, and what a language change
   must re-run.

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

1. CUDA on `eric-5090`: the facade, the nvptx unit, address spaces, real
   transfers, `Buffer` drops through `cuMemFree`, `:placement-native` for
   the CUDA twins, the Crux six on the device.
2. The measurement comparison and the first `measured:` figures.
3. Real overlap for `async on` and `async transfer`.
4. Metal, per the answer to the question above.
5. Region traffic.
6. User-written lowerings, if ever.
