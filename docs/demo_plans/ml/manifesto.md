# The Boundary

I wanted to run inference.

Take a model. Put tokens in. Get tokens out. Run it on whatever hardware I have.

That’s it.

Every system I tried could do that — under the right conditions.

But every system had the same problem:

> **The boundary between compute and ML was in the wrong place.**

---

## The Wall

A boundary drawn too high in the stack, where decisions that should be independent are fused together.

You don’t see it at first. The system works. It’s productive. It solves the problem it was designed for.

Then your problem diverges from that design, and the boundary becomes visible.

You hit the wall.

---

## PyTorch

PyTorch’s boundary is the tensor.

Tensor is memory, view, ownership, autograd, dispatch, and device placement — all in one object.

That made research ergonomic. You think in tensors, you code in tensors, everything lines up.

It also made everything inseparable.

You can’t change how memory works without touching gradients. You can’t replace the allocator without touching dispatch. You can’t swap the backend without changing how tensors are constructed.

The abstraction that made it easy to use made it impossible to decompose.

PyTorch is two million lines of C++ because every subsystem depends on every other subsystem.

---

## JAX

JAX moved the boundary up.

The program is whatever Python executed during tracing.

That enables transformations — differentiation, compilation, vectorization.

Your program isn’t what you wrote.
It’s what the tracer observed.

Control flow becomes a DSL. Dynamic behavior becomes staged. You’re writing a program that describes compute to another system.

The boundary is between Python and the compiler, and everything has to pass through it.

---

## vLLM

vLLM inherits its boundary.

It sits on PyTorch, which sits on CUDA.

So every optimization — batching, attention, scheduling — is expressed in CUDA terms.

That works as long as you’re on NVIDIA. If you’re not, the boundary isn’t configurable. It’s below you.

Every team that tries to make vLLM work on non-NVIDIA hardware spends months patching around walls they can’t move.

That’s not engineering work. That’s friction.

---

## tinygrad

tinygrad almost gets it right.

The boundary is lower. The system is small. The design is readable.

But the runtime is Python.

That’s the ceiling.

You can build kernels. You can understand the whole stack. But you can’t ship it as a binary, you can’t embed it without embedding CPython, and you can’t profile the system without profiling the interpreter.

---

## The Pattern

Different systems. Same problem.

They put the boundary in the wrong place.

Every system was solving two problems at once.

That’s where the wall comes from.

Too high, and you fuse unrelated concerns.
Too low, and you expose raw hardware.

Either way, you inherit someone else’s assumptions.

---

## The Actual Boundary

There is a natural seam in every compute system. It’s where hardware ends and intent begins.

Below the seam: memory is bytes on a device. Processors execute instructions. Operations happen in order on a queue and out of order across queues. Completion is observable.

Above the seam: tensors, gradients, layers, models, loss functions, optimizers. These are concepts humans invented to organize numerical computation. They’re useful. They’re not physical.

Every existing framework draws its primary abstraction above this seam, then reaches back down through it in ad-hoc ways — custom CUDA kernels, vendor-specific allocators, backend-specific dispatch paths.

The seam is still there.

They just built across it instead of on it.

---

## The Shift

So I stopped trying to work around the boundary.

And moved it.

---

## Crux

Six concepts. Nothing else.

Memory.
View.
Program.
Stream.
Event.
Device.

That’s Crux.

It doesn’t know what a tensor is. It doesn’t know what a model is.

It knows how to allocate memory, interpret it, execute programs, and synchronize results.

A Metal backend, a CUDA backend, a CPU backend — they each implement the same six operations.

The layer above doesn’t know which one is running.
The layer above doesn’t care.

When memory is just memory and views are just views, there’s nothing to couple.

The compute substrate is small — not because it does less, but because it only does one thing.

---

## Weld

Weld is what ML developers actually want.

Tensors. Broadcasting. Autograd. Modules.

The same names a PyTorch developer already uses — `matmul`, `softmax`, `linear`, `backward`.

But those belong above the boundary, not inside it.

Weld builds ML on top of Crux without baking ML into compute.

You can change the tensor system without touching the execution model.
You can change the backend without rewriting the abstractions.
You can replace Weld entirely and Crux still works.

The pieces are connected, not fused.

This layer is small too — because it delegates downward.

Weld doesn’t manage memory. Crux does.
Weld doesn’t dispatch to hardware. Crux does.
Weld doesn’t synchronize execution. Crux does.

What’s left is the logic that is actually about ML.

That logic isn’t two million lines.

It never was.

---

## With

To build Crux, I needed a language that didn’t impose its own boundary.

C has no structure.
C++ has too much.
Rust enforces correctness before exploration.
Zig is close, but not finished.

None of them fit the shape of the system.

So I wrote one that did.

With imports C headers with `c_import("Metal/Metal.h")` and gives you callable functions. No bindings generators. No glue code. It compiles its own compiler in twenty-six seconds. It reached fixpoint in four months — the compiler compiles itself and produces a byte-identical binary.

Fixpoint matters because it’s falsifiable. Either the compiler produces the same binary or it doesn’t.

The language isn’t a separate project.

It’s the lever.

---

## The Economics

Building bottom-up looks like more work because you see three layers instead of one.

But count the hours, not the layers.

Every team that spends three months making vLLM work on AMD is doing more total work than building the right abstraction from scratch. Every company that maintains a fork of PyTorch with custom CUDA kernels is paying ongoing tax on the wrong boundary. Every engineer who fights a framework for a week to do something the framework wasn’t designed for is spending time that doesn’t compound.

When the boundary is right, work compounds.

A fix to Crux’s Metal backend improves every model that runs on it.
A new operation in Weld works on every device Crux supports.
A language improvement makes both layers faster to develop.

Each layer multiplies the others.

When the boundary is wrong, work dissipates.

A CUDA optimization doesn’t transfer to Metal.
A PyTorch custom op doesn’t transfer to anything else.
A vLLM feature doesn’t transfer at all.

The total cost of the right abstraction, built once, is less than the cost of the wrong abstraction, patched forever.

---

## Who This Is For

This isn’t for people who are happy with PyTorch.

It’s for everyone who hit the wall.

Every team that got a quote from NVIDIA and wished they had options.
Every company trying to run models on Apple Silicon, AMD, Qualcomm, or Intel.
Every engineer who looked at their inference stack and realized the dependencies were larger than the problem.

One binary.
Any hardware.
No Python runtime.
No vendor lock-in.

---

## The Result

Crux defines compute.

Weld defines ML.

With makes both possible.

Three layers.

One decision applied consistently:

> **Put the boundary where it actually is.**

The existing stack is larger than it needs to be because the abstractions are wrong.

Fix the abstractions, and the system becomes small enough to build, fast enough to run anywhere, and simple enough to understand.

That’s not ambition.

That’s what happens when the boundary is correct.