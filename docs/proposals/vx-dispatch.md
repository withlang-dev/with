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
  evidence the fresh brief must carry.
- **User-written transfer lowerings**, if ever: a package implements the
  move across one edge in a handful of indexed primitives (no addresses,
  capabilities from the machine file, a barrier only at the top of the
  body). Its bounds obligations need a prover; library-maintainer tier,
  last.

## The Metal question

Reaching the Mac's GPU without a host-toolchain dependency (Law 8) is the
hardest dependency decision in either proposal, and it is asked before any
dispatch work starts:

- **Metal Shading Language through Apple's compiler** means the build
  depends on Xcode's `metal` tool, which the zero-dependencies rule
  forbids for an ordinary build.
- **AIR through LLVM** means the SDK carries what it needs, but the AIR
  format is not a public contract and may change under the toolchain.
- **CUDA only, Mac as host-only** means the Mac checks and never runs placed
  code, which keeps the Mac's build pure and moves every native run to
  `eric-5090`.

The brief for this proposal answers that question with the reference
projects' evidence and a prediction, before the first facade is written.

## What the fresh brief must contain

1. The checker in use: at least one real With program from the serving
   stack or the kernel library, checked against `rtx5090_x2.w`, with the
   refusals it produced and whether each was a real bug.
2. The Metal answer.
3. The dynamic-size ruling (`vx.md` Part IX) in force, since launch
   configurations are where it bites.
4. The measurement plan: which description figures become `measured:`, with
   what instrument, and the first predicted-versus-measured ratio.
5. The standing cost, stated: which gates and batteries become
   hardware-dependent, which boxes they need, and what a language change
   must re-run.

## Order, if approved

1. CUDA on `eric-5090`: the facade, the nvptx unit, address spaces, real
   transfers, `Buffer` drops through `cuMemFree`, `:placement-native` for
   the CUDA twins.
2. The measurement comparison and the first `measured:` figures.
3. Real overlap for `async on` and `async transfer`.
4. Metal, per the answer to the question above.
5. Region traffic.
6. User-written lowerings, if ever.
