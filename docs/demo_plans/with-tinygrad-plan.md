# withgrad — Porting tinygrad to With

**Source:** tinygrad @ a pinned commit (pick the latest stable tag)
**Target:** Match tinygrad's functionality in idiomatic With
**Goal:** Train MNIST, run inference on LLaMA, match tinygrad's
API feel. Beat Python on performance. Match Python on readability.

---

## 0. Why This is Hard (and Why It's Worth It)

tinygrad leans *hard* on Python's dynamism:

- **Duck typing everywhere.** UOps carry `arg: Any`. Pattern matchers
  dispatch on runtime types. The scheduler builds graphs of
  heterogeneous node types without declaring interfaces.
- **Runtime code generation.** The renderer emits strings of C/CUDA/
  Metal shader code. Python's string interpolation and dynamic
  dispatch make this feel natural.
- **Metaclasses and decorators.** `PatternMatcher` uses Python's
  introspection to build rewrite rule tables.
- **Weak references.** Tensor tracking uses `WeakKeyDictionary` for
  lazy realization without memory leaks.

The port must solve each of these with static-typing equivalents.
The good news: With's enum variants, comptime, `c_import`, and
string interpolation cover most of it. The hard part is the
pattern matcher.

**Why it's worth it:** A statically typed, compiled, GC-free tinygrad
would have genuinely better performance characteristics for training
workloads. Python's GIL, GC pauses, and interpreter overhead are
real problems in ML. And the story — "same API, same line count,
10x faster framework overhead" — is irresistible to ML developers.

---

## 1. Architecture Map: Python → With

```
tinygrad (Python ~14,500 lines)          withgrad (With)
─────────────────────────────────        ──────────────────────────

LAYER 1 — Frontend
  tinygrad/tensor.py (~2000 lines)       src/tensor.w
  tinygrad/mixin/*.py                    src/tensor_ops.w
  tinygrad/nn/*.py                       src/nn.w
  tinygrad/gradient.py                   src/gradient.w

LAYER 2 — Graph Representation
  tinygrad/uop/ops.py (~800 lines)       src/uop.w
  tinygrad/uop/spec.py                   src/uop_spec.w
  tinygrad/uop/symbolic.py               src/symbolic.w
  tinygrad/dtype.py                      src/dtype.w
  tinygrad/helpers.py                    src/helpers.w
  tinygrad/shape/shapetracker.py         src/shape.w
  tinygrad/shape/view.py                 src/view.w

LAYER 3 — Scheduling
  tinygrad/engine/schedule.py            src/schedule.w
  tinygrad/engine/realize.py             src/realize.w
  tinygrad/engine/memory.py              src/memory.w
  tinygrad/engine/jit.py                 src/jit.w
  tinygrad/schedule/*.py                 src/schedule_passes.w

LAYER 4 — Code Generation
  tinygrad/codegen/__init__.py           src/codegen.w
  tinygrad/codegen/opt.py                src/codegen_opt.w
  tinygrad/codegen/simplify.py           src/codegen_simplify.w
  tinygrad/codegen/lowerer.py            src/lowerer.w

LAYER 5 — Rendering
  tinygrad/renderer/__init__.py          src/renderer.w
  tinygrad/renderer/cstyle.py            src/render_c.w
  tinygrad/renderer/ptx.py              src/render_ptx.w
  tinygrad/renderer/wgsl.py             src/render_wgsl.w

LAYER 6 — Device Runtime
  tinygrad/device.py                     src/device.w
  tinygrad/runtime/ops_clang.py          src/runtime/clang.w
  tinygrad/runtime/ops_cuda.py           src/runtime/cuda.w
  tinygrad/runtime/ops_metal.py          src/runtime/metal.w
  tinygrad/runtime/ops_gpu.py            src/runtime/opencl.w
  tinygrad/runtime/ops_amd.py            src/runtime/amd.w
  tinygrad/runtime/ops_nv.py             src/runtime/nv.w
```

---

## 2. The Hard Translation Problems

### 2.1 UOp: `arg: Any` → Typed Variants

This is the single biggest design decision. In Python:

```python
class UOp:
    op: Ops
    dtype: DType
    src: tuple[UOp, ...]
    arg: Any              # could be int, float, str, tuple, None...
```

`arg` is `Any`. Its type depends on `op`. This is the heart of
Python duck typing — a single field that carries whatever the
operation needs.

**With solution: enum payload or union type.**

```with
type UOpArg =
    | None
    | Int(i64)
    | Float(f64)
    | Str(str)
    | Shape(Vec[i64])
    | Strides(Vec[i64])
    | VarDef(name: str, min: i64, max: i64)
    | ReduceAxis(Vec[i32])
    | BinaryOp(BinOp)
    | TernaryOp(TernOp)
    | DeviceName(str)
    | View(ShapeTracker)
    | DTypeArg(DType)
    | TensorCoreArg(TensorCore)

type UOp = {
    op: Ops,
    dtype: DType,
    src: Vec[Handle[UOp]],    // arena-allocated
    arg: UOpArg,
}
```

This is more verbose than Python, but the compiler catches
every `arg` type mismatch at compile time. In Python, wrong
arg types are silent runtime bugs.

### 2.2 PatternMatcher → Comptime Rule Tables

tinygrad's `PatternMatcher` is a list of `(pattern, rewrite_fn)`
pairs that match UOp graph shapes and apply transformations. In
Python, patterns use `UPat` objects with runtime type matching.

**With solution: match expressions + comptime registration.**

```with
// Define rewrite rules as functions
fn fold_const_add(a: &UOp, b: &UOp) -> Option[UOp] =
    if let (.Const, .Int(va)) = (a.op, &a.arg),
       let (.Const, .Int(vb)) = (b.op, &b.arg):
        Some(UOp.const(a.dtype, .Int(va + vb)))
    else:
        None

// Register rules in a table (comptime-built)
const ADD_RULES: Vec[RewriteRule] = vec![
    rule(.Add, fold_const_add),
    rule(.Add, canonicalize_add),
    rule(.Add, fold_add_zero),
    // ...
]

// Pattern matcher applies rules until fixpoint
fn rewrite(graph: &mut UOpGraph, rules: &[RewriteRule]) =
    var changed = true
    while changed:
        changed = false
        for node in graph.nodes_mut():
            for rule in rules:
                if rule.op == node.op:
                    if let Some(replacement) = (rule.apply)(node):
                        *node = replacement
                        changed = true
                        break
```

This is slightly more explicit than Python's pattern DSL, but
it's fully type-checked and the rule table can be built at
comptime.

### 2.3 Lazy Evaluation and Weak References

Python tinygrad tracks all tensors via weak references in a global
set. When `realize()` is called, it walks the set to find what
needs computing.

**With solution: arena + generation counter.**

```with
type TensorPool = {
    tensors: Vec[Option[TensorInner]],   // None = freed slot
    generation: Vec[u32],                 // detect stale handles
    free_list: Vec[u32],
}

type TensorHandle = {
    index: u32,
    generation: u32,    // stale if pool.generation[index] != this
}
```

No GC, no weak refs. Tensors are arena-allocated. Stale handles
are detected by generation mismatch. `realize()` walks the arena.

### 2.4 Runtime Code Generation (Renderers)

Python renderers build strings of C/CUDA/Metal code:

```python
def render_const(val, dtype) -> str:
    return f"(({dtype.name})({val}))"
```

**With translation is nearly 1:1** thanks to string interpolation:

```with
fn render_const(val: f64, dtype: DType) -> str =
    "(({dtype.name})({val}))"
```

This is one area where With matches Python's ergonomics exactly.
The renderers will be the most straightforward modules to port.

### 2.5 Dynamic Dispatch → Trait Objects

Python uses duck typing for device backends. Any object with
`compile()` and `exec()` methods works.

**With uses `dyn Trait`:**

```with
trait DeviceRuntime {
    fn allocate(self: &mut Self, size: usize) -> Buffer
    fn free(self: &mut Self, buf: Buffer)
    fn compile(self: &Self, src: &str) -> CompiledKernel
    fn exec(self: &mut Self, kernel: &CompiledKernel, bufs: &[Buffer])
}

// Each backend implements the trait
type ClangRuntime = { /* ... */ }
impl DeviceRuntime for ClangRuntime { /* ... */ }

type CudaRuntime = { /* ... */ }
impl DeviceRuntime for CudaRuntime { /* ... */ }

// Device singleton holds dyn trait
type Device = {
    runtime: Box[dyn DeviceRuntime],
    renderer: Box[dyn Renderer],
    compiler: Box[dyn Compiler],
}
```

---

## 3. Porting Order

Bottom-up. Each wave produces a testable artifact.

### Wave 1: Foundation

```
src/dtype.w          — DType enum, type properties, casting rules
src/helpers.w        — Utility functions (flatten, dedup, ceildiv, etc.)
src/shape.w          — ShapeTracker, View, symbolic shape math
src/view.w           — View operations (reshape, permute, expand, pad)
src/symbolic.w       — Symbolic integer math (for dynamic shapes)
```

**Test:** Port tinygrad's `test_symbolic.py` and `test_shapetracker.py`.
These are pure math — no devices, no tensors. If shape math is
wrong, everything downstream breaks.

**Key design decision here:** tinygrad's symbolic math uses Python
operator overloading heavily (`__add__`, `__mul__` on `UOp`). In With,
you implement the `Add`, `Mul`, etc. traits. The syntax is the same
(`a + b`) but the implementation is explicit.

### Wave 2: UOp Graph

```
src/uop.w           — UOp type, Ops enum, UOpArg, graph construction
src/uop_spec.w      — UOp validation (type checking on UOp graphs)
```

**The Ops enum is the heart of tinygrad.** It has ~80 variants.
Port it carefully:

```with
type Ops =
    // Buffer ops
    | Buffer | Load | Store | Const | VConst
    // Unary ops
    | Neg | Exp2 | Log2 | Sin | Sqrt | Recip
    // Binary ops
    | Add | Mul | IDiv | Mod | CmpLt | CmpEq | Xor | Or | And
    // Ternary
    | Where | MulAcc
    // Reduce
    | ReduceSum | ReduceMax
    // Movement
    | Reshape | Expand | Permute | Pad | Shrink | Stride | Flip
    // Control flow
    | Range | If | Barrier
    // Special
    | Special | Define_Var | Assign | View | Device | Unique | Multi
    | Copy | Contiguous
    // ... etc (full list from ops.py)
```

**Test:** Build UOp graphs by hand. Verify `graph_rewrite` produces
correct transformations. Port `test_uop.py`.

### Wave 3: Scheduling

```
src/schedule.w       — create_schedule, ExecItem, fusion analysis
src/schedule_passes.w — rangeify, multi-device scheduling
src/memory.w         — Memory planner (buffer reuse optimization)
```

The scheduler breaks the lazy UOp DAG into discrete kernels. This
is where fusion happens — multiple element-wise ops get merged
into a single kernel.

**Python-specific challenge:** The scheduler uses `set()` operations
extensively on UOps (which are hashable in Python via `__hash__`).
In With, you'll implement `Hash` and `Eq` on `Handle[UOp]` (hash
by arena index).

**Test:** Given known UOp graphs, verify the schedule produces the
expected number of kernels with the right fusion boundaries. Port
`test_schedule.py`.

### Wave 4: Code Generation

```
src/codegen.w          — Kernel optimization (tiling, vectorization)
src/codegen_opt.w      — OptOps, hand-coded optimizations, BEAM search
src/codegen_simplify.w — Graph simplification passes
src/lowerer.w          — UOp DAG → linearized UOp list
```

This is where the pattern matcher lives. The rewrite rules that
transform high-level UOps (Add, Mul) into low-level UOps (Range,
Load, Store, ALU) with loop structures.

**Test:** Given a simple matmul UOp graph, verify the lowered output
has the expected loop structure. Port `test_linearizer.py`.

### Wave 5: Renderers

```
src/renderer.w       — Renderer base trait
src/render_c.w       — C code renderer (for CPU backend)
src/render_ptx.w     — PTX renderer (for NVIDIA CUDA)
src/render_wgsl.w    — WGSL renderer (for WebGPU, if desired)
```

Each renderer takes a linearized UOp list and emits a string of
source code in the target language.

**This is the most fun module to port.** It's string building with
With's interpolation:

```with
fn render_kernel(name: &str, uops: &[UOp]) -> str =
    var src = "void {name}("
    // ... render arguments ...
    for uop in uops:
        match uop.op
            .Range -> src += "for (int {uop.name} = {uop.arg.lo}; ..."
            .Load  -> src += "{uop.name} = data[{uop.idx}];\n"
            .Add   -> src += "{uop.name} = {uop.a} + {uop.b};\n"
            .Store -> src += "data[{uop.idx}] = {uop.val};\n"
            // ...
    src
```

**Test:** Render known kernels, compile them with clang, execute,
verify output matches Python tinygrad's output.

### Wave 6: Device Runtimes

```
src/device.w              — Device singleton, Buffer, Compiled trait
src/runtime/clang.w       — CPU backend (compile C → dlopen → run)
src/runtime/cuda.w        — CUDA backend (nvcc → cuModuleLoad → run)
src/runtime/metal.w       — Metal backend (MTLDevice → compile → run)
src/runtime/opencl.w      — OpenCL backend
```

**Start with clang (CPU) only.** This is the simplest backend:
render C code, compile with clang, dlopen the .so, call the
function pointer. Everything through `c_import`:

```with
use c_import("dlfcn.h", link: "dl")

type ClangRuntime = {
    temp_dir: str,
}

extend ClangRuntime
    fn compile(self: &Self, src: &str) -> CompiledKernel =
        let path = "{self.temp_dir}/kernel.c"
        fs.write_file(path, src)

        // Compile with clang
        process.run("clang", ["-shared", "-O2", "-o",
            "{self.temp_dir}/kernel.so", path])

        // Load the shared library
        let handle = dlopen("{self.temp_dir}/kernel.so".as_cstr(), RTLD_NOW)
        let func = dlsym(handle, "kernel".as_cstr())

        CompiledKernel { handle, func }
```

**Add CUDA second** — it's the backend ML people care about:

```with
use c_import("cuda.h", link: "cuda")

extend CudaRuntime
    fn compile(self: &Self, ptx: &str) -> CompiledKernel =
        var module: CUmodule = null
        cuModuleLoadData(&mut module, ptx.as_cstr())
        var func: CUfunction = null
        cuModuleGetFunction(&mut func, module, "kernel".as_cstr())
        CompiledKernel { module, func }

    fn exec(self: &mut Self, kernel: &CompiledKernel, bufs: &[Buffer]) =
        var args: Vec[*mut c_void] = bufs.iter()
            |> map(|b| b.ptr as *mut c_void)
            |> collect()
        cuLaunchKernel(kernel.func,
            grid.0, grid.1, grid.2,
            block.0, block.1, block.2,
            0, null, args.as_mut_ptr(), null)
```

**This is the `c_import` showcase.** CUDA, Metal, OpenCL — all
imported in one line each, called without `unsafe` wrappers.

### Wave 7: Tensor Frontend

```
src/tensor.w         — Tensor type, creation, realize
src/tensor_ops.w     — Element-wise, reduce, movement, binary ops
src/gradient.w       — Autograd (compute_gradient)
src/nn.w             — Linear, Conv2d, BatchNorm, optimizers
```

Port the tensor API last because it depends on everything else.
The API should feel as close to tinygrad's Python API as possible:

```with
// Python tinygrad:
// x = Tensor.eye(3, requires_grad=True)
// y = Tensor([[2.0, 0, -2.0]], requires_grad=True)
// z = y.matmul(x).sum()
// z.backward()

// With:
let x = Tensor.eye(3, requires_grad: true)
let y = Tensor.from([[2.0, 0.0, -2.0]], requires_grad: true)
let z = y.matmul(x).sum()
z.backward()
println(x.grad().tolist())
println(y.grad().tolist())
```

**Operator overloading** is essential here. Implement `Add`, `Mul`,
`Sub`, `Div`, `Neg` traits on Tensor so `a + b` works.

---

## 4. Test Strategy

### 4.1 Numerical Correctness

The gold standard: for every operation, compare With output against
Python tinygrad output (which itself is tested against PyTorch).

```bash
# Generate golden outputs from Python tinygrad
python3 generate_golden.py  # produces golden/*.npz

# Run With version, compare
withgrad test --golden golden/
```

Tolerance: `atol=1e-6, rtol=1e-5` for float32.

### 4.2 Kernel Equivalence

For the same input graph, With and Python should produce the
same (or semantically equivalent) kernel code.

```bash
# Python: dump generated kernels
DEBUGGER=1 python3 test_ops.py > kernels_python.txt

# With: dump generated kernels
DEBUGGER=1 withgrad test ops > kernels_with.txt

diff kernels_python.txt kernels_with.txt
```

### 4.3 Progressive Test Milestones

| Milestone | Test | Proves |
|-----------|------|--------|
| M1 | `Tensor(2) + Tensor(3) == 5` | UOp graph + schedule + C render + clang runtime |
| M2 | Matrix multiply 4×4 matches numpy | Fusion, loop structure, indexing |
| M3 | MNIST trains to 95%+ | Autograd, optimizer, full pipeline |
| M4 | LLaMA 7B inference runs | Large model, memory management, perf |
| M5 | CUDA backend passes test_ops | GPU code generation |
| M6 | Training perf matches Python tinygrad | No Python overhead regression |

**M1 is the "hello world."** When `2 + 3 = 5` works end-to-end,
every layer of the stack has been exercised.

**M3 is the "it's real" moment.** MNIST training means autograd
works, optimizers work, the JIT works, and numerical stability
is correct.

---

## 5. What With Gains from This

### 5.1 Missing Features You'll Discover

Porting will expose gaps in the language. Likely candidates:

- **Operator overloading** — you'll need `Add`, `Mul`, etc. traits
  to make `Tensor + Tensor` work. Make sure the spec supports this
  cleanly for user-defined types.
- **Variadic generics** — tensor shapes are variable-length tuples.
  Python handles this naturally. With may need `Vec[i64]` instead.
- **Global mutable state** — tinygrad uses module-level globals
  (`Device.DEFAULT`, `all_tensors`). With probably needs a context
  object passed explicitly, or module-level `var`.
- **Hash and equality on complex types** — UOps need `Hash` and `Eq`
  for set operations. `@[derive(Hash, Eq)]` must work on nested enums.

### 5.2 The API Comparison

The blog post writes itself:

```
# Python tinygrad (14,500 lines, GC pauses, GIL-limited)
x = Tensor.rand(1024, 1024)
y = Tensor.rand(1024, 1024)
z = (x @ y).relu().sum()
z.backward()

# withgrad (same line count, no GC, no GIL, 10x faster overhead)
let x = Tensor.rand(1024, 1024)
let y = Tensor.rand(1024, 1024)
let z = (x.matmul(y)).relu().sum()
z.backward()
```

Same readability. Same API shape. No garbage collector. No
interpreter overhead. The kernel code is identical — both
generate the same C/CUDA/Metal. The difference is everything
around the kernel: graph construction, scheduling, and memory
management run at native speed instead of CPython speed.

---

## 6. What NOT to Port

- **`extra/`** — model zoo, datasets, ONNX import. Skip entirely
  for v1. These are applications of the library, not the library.
- **`viz/`** — visualization server. Skip. Nice to have later.
- **`runtime/autogen/`** — Python stubs generated from C headers by
  clang2py. You don't need these — With has `c_import`.
- **`ops_python.py`** — The Python reference runtime. Its purpose
  is to define UOp semantics in pure Python. Your C backend
  replaces this.
- **AMD/NV userspace drivers** — `ops_amd.py` and `ops_nv.py` are
  full userspace GPU drivers written in Python (HCQ API). These are
  thousands of lines and extremely complex. Skip for v1. Use the
  standard CUDA/OpenCL/Metal APIs via `c_import` instead.

### Focus: Core + Clang + CUDA + Metal

That's it. Four backends cover: CPU development, NVIDIA training,
Apple inference. Everything else is a bonus for later.

---

## 7. The Pitch

> **withgrad** — a tinygrad port in With.
>
> Same API. Same kernels. No garbage collector. No interpreter.
> Graph construction is 10x faster. Memory management is
> deterministic. Trains MNIST in the same time, but your framework
> overhead is measured in microseconds, not milliseconds.
>
> And you can read every line of it.

The target audience isn't "people who want to switch from PyTorch."
It's "people who are curious about tinygrad, curious about With,
and want to see what a statically-typed, compiled, GC-free ML
framework looks like." That Venn diagram is small but loud. They'll
share it.

---

*withgrad — Plan v0.1*