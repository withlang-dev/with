# Weld: The ML Library for With (v5)

**Built on:** Crux (compute substrate)
**Goal:** PyTorch-level productivity, tinygrad-level simplicity,
hardware-agnostic and distributed-native from day one.

**Naming:**
```
use crux              // substrate (Weld users rarely touch directly)
use weld              // tensors, ops, autograd
use weld.nn           // modules: Linear, LayerNorm, Attention
use weld.optim        // optimizers: Adam, SGD, AdamW
use weld.distributed  // data parallel, tensor parallel, FSDP
use weld.data         // safetensors, GGUF, tokenizers
use weld.serve        // inference engine (separate doc)
```

**Design principles:**
- Weld is a thin layer. Every operation delegates to Crux.
- Weld adds exactly four things Crux doesn't have: tensor ownership,
  automatic differentiation, a PyTorch-familiar API, and distributed
  orchestration.
- There is no dispatcher — just functions.
- Weld is eager. Every dispatch is real. No lazy evaluation, no
  graph tracing, no JIT. Forever.
- A Tensor lives on one device. Always. Distributed patterns are
  orchestration of single-device operations + Crux collectives.
- Distributed is native. No external libraries.
- Resource cleanup is automatic via With's `@[drop]`.
- All operations borrow inputs (`&Tensor`), return owned outputs
  (`Tensor`). With's auto-referencing makes the `&` invisible at
  call sites. The user writes value-style code; the compiler
  manages ownership.

---

## Part 1: Ownership Model

This is the most important section in the entire spec. It resolves
the tension between RAII (automatic cleanup) and value-style ergonomics.

### The problem

Tensor implements `Drop` to manage Storage refcounts. A type with
`Drop` cannot be `Copy`. A non-Copy type is moved on assignment.
If operations consume Tensors by value, using a tensor twice is a
compile error:

```
// BROKEN: x moved into rms_norm, can't use in add
let h = add(ctx, x, rms_norm(ctx, x, weight, eps))
```

### The solution

All Weld operations take inputs by reference (`&Tensor`) and return
owned results (`Tensor`). With's auto-referencing (Section 3.8)
automatically inserts `&` at call sites, so the user never writes it:

```
// What the user writes (no & anywhere):
let h = add(ctx, x, rms_norm(ctx, x, weight, eps))

// What the compiler sees:
let h = add(&ctx, &x, &rms_norm(&ctx, &x, &weight, eps))
```

### The rules

1. **Inputs are borrowed.** Every function parameter that receives
   a Tensor takes `&Tensor`. The function reads the tensor but
   does not consume it. The caller retains ownership.

2. **Outputs are owned.** Every function that produces a Tensor
   returns `Tensor` (owned). The caller takes ownership. A new
   Storage is allocated with refcount = 1.

3. **View ops share Storage.** `reshape`, `transpose`, `slice` etc.
   return an owned `Tensor` that points to the same Storage as the
   input (refcount incremented). The input is borrowed, not consumed.

4. **Temporaries are auto-dropped.** When an intermediate Tensor
   goes out of scope (including expression temporaries), `Drop`
   is called, which decrements the Storage refcount. At refcount 0,
   Crux memory is freed.

5. **Return transfers ownership.** A Tensor returned from a function
   is moved to the caller. Drop is NOT called on the returned value
   in the callee's scope.

6. **Auto-referencing is invisible.** The user writes `add(ctx, a, b)`.
   The compiler sees `add(&ctx, &a, &b)`. No `&` in user code. No
   `.clone()`. The API reads like PyTorch.

### Concrete example

```
impl Module for TransformerBlock:
    fn forward(self: &Self, ctx: &Context, x: &Tensor) -> Tensor:
        let h = add(ctx, x, self.attention.forward(ctx,
                    rms_norm(ctx, x, self.norm1.weight, self.norm1.eps)))
        add(ctx, h, self.ffn.forward(ctx,
            rms_norm(ctx, h, self.norm2.weight, self.norm2.eps)))
```

What happens at each step:

1. `x` is `&Tensor` — borrowed from caller, never consumed.
2. `rms_norm(ctx, x, ...)` — borrows `x`, returns owned Tensor (temporary).
3. `self.attention.forward(ctx, ...)` — borrows the temporary, returns owned Tensor.
4. `add(ctx, x, ...)` — borrows `x` again (still valid), borrows attention output, returns owned Tensor bound to `h`.
5. Temporaries from steps 2-3 are dropped — Storage refcount decremented.
6. Second line: `h` is borrowed twice (by `rms_norm` and `add`). Still valid.
7. Final `add` returns owned Tensor — moved to caller as the function return value.
8. `h` is dropped at scope exit — Storage refcount decremented.

No leaks. No clones. No manual cleanup. No `&` in user code.

### Operator overloading

Operator traits take `&Self`:

```
trait Add:
    fn add(self: &Self, rhs: &Self) -> Self

// Usage — auto-ref'd:
let c = a + b       // borrows a and b, c is new owned Tensor
let d = a + c       // a reused (still borrowed), d is new
let e = a + b + c   // all borrowed, e is new
```

No moved-value errors. No `&` visible. Chaining works naturally.

---

## Part 2: Tensor

### The core type

```
@[drop]
type Tensor = {
    storage: *mut Storage,     // shared, refcounted memory
    view: View,                // Crux view (shape, strides, dtype, offset)
    grad_meta: *mut GradMeta,  // null during inference
}

impl Drop for Tensor:
    fn drop(self: &mut Self):
        if self.storage != null:
            storage_release(self.storage)
        if self.grad_meta != null:
            grad_meta_release(self.grad_meta)
```

Tensor is small: one pointer, one inline View, one nullable pointer.
Device is accessed via `storage.device` — not stored on Tensor
(single source of truth).

### Storage (refcounted memory)

```
type Storage = {
    memory: *mut Memory,       // Crux memory handle
    device: *mut Device,       // single source of truth for device
    refcount: i32,
    size: usize,
}

fn storage_new(device: *mut Device, size: usize) -> *mut Storage
fn storage_retain(s: *mut Storage)
fn storage_release(s: *mut Storage)  // free Crux memory at refcount 0
```

### GradMeta (autograd sidecar)

```
type GradMeta = {
    grad: *mut Tensor,         // accumulated gradient
    grad_fn: *mut GradNode,    // null for leaves
    requires_grad: bool,
    is_leaf: bool,
}
```

Allocated only when `requires_grad = true`.

### Construction

```
fn tensor(data: &[f32], shape: Shape, device: *mut Device) -> Tensor
fn tensor_i32(data: &[i32], shape: Shape, device: *mut Device) -> Tensor
fn tensor_f16(data: &[f32], shape: Shape, device: *mut Device) -> Tensor
fn zeros(shape: Shape, dtype: DType, device: *mut Device) -> Tensor
fn ones(shape: Shape, dtype: DType, device: *mut Device) -> Tensor
fn full(shape: Shape, value: f64, dtype: DType, device: *mut Device) -> Tensor
fn rand(shape: Shape, dtype: DType, device: *mut Device) -> Tensor
fn randn(shape: Shape, dtype: DType, device: *mut Device) -> Tensor
fn arange(start: f64, end: f64, step: f64, dtype: DType, device: *mut Device) -> Tensor
fn eye(n: usize, dtype: DType, device: *mut Device) -> Tensor
```

Constructors return owned Tensors. Data slices are borrowed.

### Properties

```
fn shape(t: &Tensor) -> Shape
fn dtype(t: &Tensor) -> DType
fn device(t: &Tensor) -> *mut Device    // reads storage.device
fn ndim(t: &Tensor) -> i32
fn numel(t: &Tensor) -> usize
fn is_contiguous(t: &Tensor) -> bool
fn requires_grad(t: &Tensor) -> bool
```

### Device transfer and copies

```
fn to(t: &Tensor, device: *mut Device) -> Tensor
fn cpu(t: &Tensor) -> Tensor
fn contiguous(t: &Tensor) -> Tensor
fn detach(t: &Tensor) -> Tensor         // shared storage, no grad
fn clone(t: &Tensor) -> Tensor          // new storage, full copy
```

All take `&Tensor`, return owned `Tensor`.
- `detach` shares Storage (refcount++), clears grad_meta.
- `clone` allocates new Storage, copies data.

### Data access

```
fn item(t: &Tensor) -> f64
fn to_vec_f32(t: &Tensor) -> Vec[f32]
fn to_vec_i32(t: &Tensor) -> Vec[i32]
fn data_ptr(t: &Tensor) -> *mut u8
```

### Memory semantics

1. **Construction** allocates Storage. refcount = 1. Returns owned Tensor.
2. **View ops** share Storage. refcount++. Returns owned Tensor.
3. **Compute ops** allocate new Storage. refcount = 1. Returns owned Tensor.
4. **Drop** (automatic) calls `storage_release`. At refcount 0, Crux memory freed.
5. **Borrow** (`&Tensor`) does not affect refcount. Caller keeps ownership.

---

## Part 3: Context

```
type Context = {
    device: *mut Device,
    stream: *mut Stream,
    programs: ProgramRegistry,
    grad_stack: Vec[bool],       // push/pop for nested no_grad
    current_layer: i32,          // for FSDP hooks, -1 when not in use
}

fn context(device: *mut Device) -> Context
fn context_default() -> Context
fn context_destroy(ctx: *mut Context)
```

### Gradient mode (push/pop stack)

```
fn no_grad(ctx: &mut Context):
    ctx.grad_stack.push(false)

fn enable_grad(ctx: &mut Context):
    ctx.grad_stack.push(true)

fn restore_grad(ctx: &mut Context):
    ctx.grad_stack.pop()

fn grad_enabled(ctx: &Context) -> bool:
    if ctx.grad_stack.is_empty(): return true
    ctx.grad_stack.last()
```

Usage with defer:

```
fn run_inference(ctx: &mut Context):
    no_grad(ctx)
    defer: restore_grad(ctx)
    // all code runs without grad, restored on any exit path
```

---

## Part 4: Operations

### Design rule

Every operation borrows its inputs (`&Tensor`) and returns an owned
result (`Tensor`). No operation consumes its input. With's
auto-referencing makes the borrows invisible at call sites.

The user writes `matmul(ctx, a, b)`.
The compiler sees `matmul(&ctx, &a, &b)`.

### Elementwise

```
// Unary — borrow input, return new
fn neg(ctx: &Context, t: &Tensor) -> Tensor
fn abs(ctx: &Context, t: &Tensor) -> Tensor
fn exp(ctx: &Context, t: &Tensor) -> Tensor
fn log(ctx: &Context, t: &Tensor) -> Tensor
fn sqrt(ctx: &Context, t: &Tensor) -> Tensor
fn rsqrt(ctx: &Context, t: &Tensor) -> Tensor
fn tanh(ctx: &Context, t: &Tensor) -> Tensor
fn sigmoid(ctx: &Context, t: &Tensor) -> Tensor
fn relu(ctx: &Context, t: &Tensor) -> Tensor
fn gelu(ctx: &Context, t: &Tensor) -> Tensor
fn silu(ctx: &Context, t: &Tensor) -> Tensor
fn reciprocal(ctx: &Context, t: &Tensor) -> Tensor
fn clamp(ctx: &Context, t: &Tensor, lo: f64, hi: f64) -> Tensor

// Binary — borrow both, return new (all support broadcasting)
fn add(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
fn sub(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
fn mul(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
fn div(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
fn pow(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
fn maximum(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
fn minimum(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
fn where_(ctx: &Context, cond: &Tensor, a: &Tensor, b: &Tensor) -> Tensor

// Scalar — borrow tensor, scalar by value (preferred fast path)
fn add_scalar(ctx: &Context, t: &Tensor, s: f64) -> Tensor
fn mul_scalar(ctx: &Context, t: &Tensor, s: f64) -> Tensor
fn div_scalar(ctx: &Context, t: &Tensor, s: f64) -> Tensor
fn pow_scalar(ctx: &Context, t: &Tensor, s: f64) -> Tensor
```

Broadcasting follows NumPy exactly. Right-align shapes, expand
size-1 dims to match, stride=0 for broadcast — no data copy.
Scalar ops use Crux spec constants (scalar in registers, not memory).

### Reduction

```
fn sum(ctx: &Context, t: &Tensor, dim: i32) -> Tensor
fn sum_all(ctx: &Context, t: &Tensor) -> Tensor
fn mean(ctx: &Context, t: &Tensor, dim: i32) -> Tensor
fn max(ctx: &Context, t: &Tensor, dim: i32) -> Tensor
fn min(ctx: &Context, t: &Tensor, dim: i32) -> Tensor
fn argmax(ctx: &Context, t: &Tensor, dim: i32) -> Tensor
fn argmin(ctx: &Context, t: &Tensor, dim: i32) -> Tensor
```

### Matrix ops

```
fn matmul(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
    // [M, K] × [K, N] → [M, N]
    // Batched: [B, M, K] × [B, K, N] → [B, M, N]
    // Broadcast: [B, M, K] × [K, N] → [B, M, N]

fn linear(ctx: &Context, input: &Tensor, weight: &Tensor, bias: &Tensor) -> Tensor
    // input @ weight.T + bias — fused, one Crux dispatch

fn bmm(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
```

### Shape ops (zero cost — borrow input, return new owned Tensor sharing Storage)

```
fn reshape(t: &Tensor, shape: Shape) -> Tensor
fn transpose(t: &Tensor, dim0: i32, dim1: i32) -> Tensor
fn permute(t: &Tensor, order: [i32; 8]) -> Tensor
fn expand(t: &Tensor, shape: Shape) -> Tensor
fn squeeze(t: &Tensor, dim: i32) -> Tensor
fn unsqueeze(t: &Tensor, dim: i32) -> Tensor
fn flatten(t: &Tensor, start: i32, end: i32) -> Tensor
fn slice(t: &Tensor, dim: i32, start: usize, end: usize) -> Tensor
fn narrow(t: &Tensor, dim: i32, start: usize, length: usize) -> Tensor
```

These borrow the input, retain its Storage (refcount++), and return
a new owned Tensor with a different View. No dispatch, no new
allocation (except the Tensor struct). Zero cost.

### Shape ops (require dispatch)

```
fn cat(ctx: &Context, tensors: &[Tensor], dim: i32) -> Tensor
fn stack(ctx: &Context, tensors: &[Tensor], dim: i32) -> Tensor
fn gather(ctx: &Context, t: &Tensor, dim: i32, index: &Tensor) -> Tensor
fn scatter(ctx: &Context, t: &Tensor, dim: i32, index: &Tensor, src: &Tensor) -> Tensor
fn index_select(ctx: &Context, t: &Tensor, dim: i32, index: &Tensor) -> Tensor
fn repeat(ctx: &Context, t: &Tensor, repeats: Shape) -> Tensor
fn pad(ctx: &Context, t: &Tensor, padding: [usize; 8], value: f64) -> Tensor
fn tril(ctx: &Context, t: &Tensor, diagonal: i32) -> Tensor
fn triu(ctx: &Context, t: &Tensor, diagonal: i32) -> Tensor
```

### Type casting

```
fn to_dtype(ctx: &Context, t: &Tensor, dtype: DType) -> Tensor
fn float(ctx: &Context, t: &Tensor) -> Tensor      // → Float32
fn half(ctx: &Context, t: &Tensor) -> Tensor       // → Float16
fn bfloat16(ctx: &Context, t: &Tensor) -> Tensor   // → BFloat16
fn int(ctx: &Context, t: &Tensor) -> Tensor        // → Int32
```

### Fused neural network ops (single Crux dispatch each)

```
fn softmax(ctx: &Context, t: &Tensor, dim: i32) -> Tensor
fn log_softmax(ctx: &Context, t: &Tensor, dim: i32) -> Tensor
fn layer_norm(ctx: &Context, t: &Tensor, shape: Shape, weight: &Tensor, bias: &Tensor, eps: f64) -> Tensor
fn rms_norm(ctx: &Context, t: &Tensor, weight: &Tensor, eps: f64) -> Tensor
fn embedding(ctx: &Context, weight: &Tensor, indices: &Tensor) -> Tensor
fn rope(ctx: &Context, t: &Tensor, freqs: &Tensor) -> Tensor
fn cross_entropy(ctx: &Context, logits: &Tensor, targets: &Tensor) -> Tensor
fn dropout(ctx: &Context, t: &Tensor, p: f64, training: bool) -> Tensor
fn scaled_dot_product_attention(ctx: &Context, q: &Tensor, k: &Tensor, v: &Tensor,
                                 mask: &Tensor, scale: f64) -> Tensor
```

`scaled_dot_product_attention` is the flash attention kernel.
One Crux dispatch. No intermediate attention matrix materialized.

---

## Part 5: Broadcasting

Broadcasting follows NumPy/PyTorch exactly:

1. Shapes are right-aligned.
2. Dimensions of size 1 are expanded to match.
3. Missing dimensions on the left are treated as size 1.

```
fn broadcast_shapes(a: Shape, b: Shape) -> Result[Shape, WeldError]:
    let rank = max(a.rank, b.rank)
    var out = shape_zero(rank)
    for i in 0..rank:
        let da = if i < a.rank: shape_get(a, a.rank - 1 - i) else: 1
        let db = if i < b.rank: shape_get(b, b.rank - 1 - i) else: 1
        if da == db:
            shape_set(&out, rank - 1 - i, da)
        else if da == 1:
            shape_set(&out, rank - 1 - i, db)
        else if db == 1:
            shape_set(&out, rank - 1 - i, da)
        else:
            return Err(WeldError.ShapeMismatch(
                "cannot broadcast {a} with {b}"))
    Ok(out)
```

Implementation: compute broadcast shape, create broadcast views
via `crux.view_broadcast` (stride=0 on expanded dims), allocate
output, dispatch one Crux program. No data copy for broadcasting.

---

## Part 6: Autograd

### Design

Tape-based reverse-mode AD. Only active when `grad_enabled(ctx)`.
Operations on `requires_grad = true` tensors record GradNodes.
`backward()` traverses in reverse.

### Graph structure

```
type GradNode = {
    backward_fn: i32,                  // enum dispatch
    input_metas: Vec[*mut GradMeta],
    input_shapes: Vec[Shape],          // for unbroadcast
    saved: SavedState,
    output_meta: *mut GradMeta,
    refcount: i32,
    layer_idx: i32,                    // for FSDP hooks
}
```

### SavedState (lightweight — no full Tensor)

```
type SavedTensor = {
    storage: *mut Storage,     // shared, refcount incremented
    view: View,                // the view at save time
}

type SavedState = {
    tensors: Vec[SavedTensor],     // NOT full Tensors
    shapes: Vec[Shape],
    scalars: Vec[f64],
}

fn save_tensor(t: &Tensor) -> SavedTensor:
    storage_retain(t.storage)
    SavedTensor { storage: t.storage, view: t.view }

fn release_saved(s: &SavedTensor):
    storage_release(s.storage)
```

SavedTensor is two fields: storage pointer and view. No grad_meta,
no device (read from storage). Smaller and cheaper than saving
full Tensors.

### What gets saved per op

```
AddBackward:          nothing (passthrough)
MulBackward:          save_tensor(a), save_tensor(b)
MatmulBackward:       save_tensor(a), save_tensor(b)
ReluBackward:         save_tensor(output)
SoftmaxBackward:      save_tensor(output)
CrossEntropyBackward: save_tensor(softmax_out), save_tensor(targets)
LayerNormBackward:    save_tensor(input), scalars: [mean, rstd]
EmbeddingBackward:    save_tensor(indices)
LinearBackward:       save_tensor(input), save_tensor(weight)
```

### How autograd interacts with borrowing

Operations borrow their Tensor inputs. If autograd needs to save
a tensor for backward, it calls `save_tensor(t)` which borrows `t`
and increments the Storage refcount. This keeps the memory alive
even if the original Tensor is dropped:

```
fn mul(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor:
    let out = mul_forward(ctx, a, b)      // Crux dispatch
    if grad_enabled(ctx) and (has_grad(a) or has_grad(b)):
        // save_tensor borrows a and b — retains storage, doesn't consume
        let saved = SavedState {
            tensors: [save_tensor(a), save_tensor(b)],
            shapes: [], scalars: [],
        }
        attach_grad_node(&out, BACKWARD_MUL,
                         [a.grad_meta, b.grad_meta],
                         [a.shape(), b.shape()],
                         saved, ctx.current_layer)
    out
    // a and b are NOT consumed — caller still owns them
```

### Backward pass

```
fn backward(ctx: &Context, loss: &Tensor):
    backward_ex(ctx, loss, retain_graph: false)

fn backward_retain(ctx: &Context, loss: &Tensor):
    backward_ex(ctx, loss, retain_graph: true)

fn backward_ex(ctx: &Context, loss: &Tensor, retain_graph: bool):
    assert numel(loss) == 1
    let meta = loss.grad_meta
    assert meta != null

    meta.grad = ones(shape(loss), dtype(loss), device(loss))

    let order = topo_sort(meta.grad_fn)

    for node in order.reversed():
        let grad_out = node.output_meta.grad
        let grads = apply_backward(node.backward_fn, grad_out, &node.saved, ctx)

        for i in 0..node.input_metas.len():
            let in_meta = node.input_metas[i]
            if in_meta == null or not in_meta.requires_grad: continue
            var g = grads[i]
            if g.shape() != node.input_shapes[i]:
                g = unbroadcast(ctx, g, node.input_shapes[i])
            if in_meta.grad == null:
                in_meta.grad = g
            else:
                in_meta.grad = add(ctx, in_meta.grad, g)

    if not retain_graph:
        free_graph(order)
```

### Graph lifecycle

**Rules:**
- `backward()` frees the graph after completion (default).
- `backward_retain()` keeps the graph alive for multiple backward passes.
- Calling `backward()` twice on a freed graph is a runtime error.
- GradNodes are refcounted. A node shared by multiple outputs
  is freed when all outputs release it.
- `free_graph` releases all SavedTensors (decrementing Storage
  refcount) and frees GradNode objects at refcount 0.
- Between forward and backward, saved tensor Storage stays alive.

`backward` takes `&Tensor` — it borrows the loss to read grad_meta.
The loss Tensor survives backward. Only the graph is freed.

### Gradient reduction for broadcasting

```
fn unbroadcast(ctx: &Context, grad: &Tensor, original_shape: Shape) -> Tensor:
    var g = clone(grad)
    while ndim(g) > original_shape.rank:
        g = sum(ctx, g, 0)
    for i in 0..original_shape.rank:
        if shape_get(original_shape, i) == 1 and shape_get(shape(g), i) != 1:
            g = sum(ctx, g, i)  // keepdim
    g
```

### Gradient hooks (for distributed)

```
type BackwardHook = {
    pre_layer: fn(layer_idx: i32, ctx: &Context),
    post_layer: fn(layer_idx: i32, ctx: &Context),
}

fn backward_with_hooks(ctx: &Context, loss: &Tensor, hooks: BackwardHook):
    // Same as backward, but calls hooks at layer boundaries.
    // Layer boundaries determined by GradNode.layer_idx.
    // ctx.current_layer is set during forward to annotate nodes.
```

---

## Part 7: nn Modules

### Module trait

```
trait Module =
    fn forward(self: &Self, ctx: &Context, input: &Tensor) -> Tensor
    fn parameters(self: &Self) -> Vec[*mut Tensor]
    fn named_parameters(self: &Self) -> Vec[(str, *mut Tensor)]
    fn to_device(self: &mut Self, device: *mut Device)
    fn train(self: &mut Self)
    fn eval(self: &mut Self)
```

`forward` borrows `self` and `input`, returns owned Tensor.
`named_parameters` is essential for distributed weight sharding
and loading.

### Core modules

```
type Linear = {
    weight: Tensor,      // [out_features, in_features]
    bias: Tensor,        // [out_features] or null
    in_features: usize,
    out_features: usize,
}

fn linear_new(in_features: usize, out_features: usize,
              bias: bool, device: *mut Device) -> Linear:
    let w = randn(shape2(out_features, in_features), Float32, device)
    w = mul_scalar(w, 1.0 / sqrt(in_features as f64))  // kaiming init
    w.grad_meta = alloc_grad_meta(requires_grad: true, is_leaf: true)
    let b = if bias: zeros(shape1(out_features), Float32, device) else: null_tensor()
    if b.storage != null:
        b.grad_meta = alloc_grad_meta(requires_grad: true, is_leaf: true)
    Linear { weight: w, bias: b, in_features, out_features }

impl Module for Linear:
    fn forward(self: &Self, ctx: &Context, input: &Tensor) -> Tensor:
        linear(ctx, input, self.weight, self.bias)
        // auto-ref: linear(&ctx, &input, &self.weight, &self.bias)

    fn parameters(self: &Self) -> Vec[*mut Tensor]:
        var params = Vec.new()
        params.push(&self.weight)
        if self.bias.storage != null:
            params.push(&self.bias)
        params
```

```
type LayerNorm = {
    weight: Tensor,
    bias: Tensor,
    normalized_shape: Shape,
    eps: f64,
}

fn layer_norm_new(shape: Shape, device: *mut Device) -> LayerNorm:
    let w = ones(shape, Float32, device)
    w.grad_meta = alloc_grad_meta(requires_grad: true, is_leaf: true)
    let b = zeros(shape, Float32, device)
    b.grad_meta = alloc_grad_meta(requires_grad: true, is_leaf: true)
    LayerNorm { weight: w, bias: b, normalized_shape: shape, eps: 1e-5 }

impl Module for LayerNorm:
    fn forward(self: &Self, ctx: &Context, input: &Tensor) -> Tensor:
        layer_norm(ctx, input, self.normalized_shape, self.weight, self.bias, self.eps)
```

```
type RMSNorm = {
    weight: Tensor,
    eps: f64,
}

type Embedding = {
    weight: Tensor,
    vocab_size: usize,
    embed_dim: usize,
}

impl Module for Embedding:
    fn forward(self: &Self, ctx: &Context, indices: &Tensor) -> Tensor:
        embedding(ctx, self.weight, indices)
```

```
type MultiHeadAttention = {
    q_proj: Linear,
    k_proj: Linear,
    v_proj: Linear,
    o_proj: Linear,
    num_heads: i32,
    head_dim: usize,
}

impl Module for MultiHeadAttention:
    fn forward(self: &Self, ctx: &Context, x: &Tensor) -> Tensor:
        let b = shape_get(shape(x), 0)
        let n = shape_get(shape(x), 1)

        let q = self.q_proj.forward(ctx, x)       // borrows x
        let k = self.k_proj.forward(ctx, x)       // borrows x again
        let v = self.v_proj.forward(ctx, x)       // borrows x again

        // reshape + transpose: view ops, share Storage
        let q = transpose(reshape(q, shape4(b, n, self.num_heads, self.head_dim)), 1, 2)
        let k = transpose(reshape(k, shape4(b, n, self.num_heads, self.head_dim)), 1, 2)
        let v = transpose(reshape(v, shape4(b, n, self.num_heads, self.head_dim)), 1, 2)

        let scale = 1.0 / sqrt(self.head_dim as f64)
        let attn_out = scaled_dot_product_attention(ctx, q, k, v, null, scale)

        // [B, H, N, D] → [B, N, H*D]
        let out = reshape(transpose(attn_out, 1, 2),
                         shape3(b, n, self.num_heads * self.head_dim))
        self.o_proj.forward(ctx, out)
        // q, k, v intermediates dropped automatically
```

```
type FFN = {
    gate_proj: Linear,   // for SwiGLU
    up_proj: Linear,
    down_proj: Linear,
}

impl Module for FFN:
    fn forward(self: &Self, ctx: &Context, x: &Tensor) -> Tensor:
        let gate = silu(ctx, self.gate_proj.forward(ctx, x))
        let up = self.up_proj.forward(ctx, x)     // borrows x again
        self.down_proj.forward(ctx, mul(ctx, gate, up))
        // gate, up dropped at scope exit

type TransformerBlock = {
    attention: MultiHeadAttention,
    ffn: FFN,
    norm1: RMSNorm,
    norm2: RMSNorm,
}

impl Module for TransformerBlock:
    fn forward(self: &Self, ctx: &Context, x: &Tensor) -> Tensor:
        let h = add(ctx, x, self.attention.forward(ctx,
                    rms_norm(ctx, x, self.norm1.weight, self.norm1.eps)))
        add(ctx, h, self.ffn.forward(ctx,
            rms_norm(ctx, h, self.norm2.weight, self.norm2.eps)))
        // x borrowed 3 times — all valid
        // h borrowed 3 times — all valid
        // temporaries auto-dropped

type Transformer = {
    embed: Embedding,
    blocks: Vec[TransformerBlock],
    norm: RMSNorm,
    lm_head: Linear,
    config: ModelConfig,
}

type ModelConfig = {
    vocab_size: usize,
    dim: usize,
    num_heads: i32,
    num_kv_heads: i32,
    num_layers: i32,
    intermediate_size: usize,
    max_seq_len: usize,
    rope_theta: f64,
}

impl Module for Transformer:
    fn forward(self: &Self, ctx: &Context, tokens: &Tensor) -> Tensor:
        var h = embedding(ctx, self.embed.weight, tokens)
        for i in 0..self.blocks.len():
            h = self.blocks[i].forward(ctx, h)
            // old h dropped on reassignment — Storage released
        h = rms_norm(ctx, h, self.norm.weight, self.norm.eps)
        linear(ctx, h, self.lm_head.weight, self.lm_head.bias)

    fn parameters(self: &Self) -> Vec[*mut Tensor]:
        var params = self.embed.parameters()
        for block in self.blocks:
            params.extend(block.parameters())
        params.extend(self.norm.parameters())
        params.extend(self.lm_head.parameters())
        params
```

Module authors write single-device code. Always. Distributed
wrappers handle multi-device orchestration without modifying
the module.

---

## Part 8: Distributed

### Philosophy

Distributed is native. Not an afterthought, not an external
library, not a separate install. `weld.distributed` ships with
Weld. It provides four parallelism strategies:

```
DataParallel      — same model on every device, different data
TensorParallel    — model split across devices per-layer
FSDP              — parameters, gradients, optimizer state all sharded
PipelineParallel  — model split by layers across devices
```

Each is an orchestration wrapper. The Module doesn't change.
The Tensor doesn't change. The autograd doesn't change.

### 8.1 World

```
type World = {
    devices: Vec[*mut Device],
    contexts: Vec[Context],
    streams: Vec[*mut Stream],
    size: i32,
}

fn world_from_devices(devices: Vec[*mut Device]) -> World:
    var contexts = Vec.new()
    var streams = Vec.new()
    for d in devices:
        contexts.push(context(d))
        streams.push(crux.stream_create(d))
    World { devices, contexts, size: devices.len() as i32, streams }

fn world_default() -> World:
    world_from_devices(crux.devices())

fn world_destroy(w: *mut World)
```

### 8.2 Data Parallel

Same model on every device. Each device processes a different
shard of the batch. Gradients are allreduced after backward.

```
type DataParallel = {
    world: *mut World,
    replicas: Vec[Transformer],
}

fn data_parallel(model: &Transformer, world: *mut World) -> DataParallel:
    var replicas = Vec.new()
    for i in 0..world.size:
        let replica = clone_model_to(model, world.devices[i])
        replicas.push(replica)
    DataParallel { world, replicas }
```

Training step:

```
fn dp_train_step(dp: &mut DataParallel, batches: &[Tensor],
                 targets: &[Tensor], opt: &mut Adam):
    var losses = Vec.new()

    // Forward on each device
    for i in 0..dp.world.size:
        let ctx = &dp.world.contexts[i]
        let logits = dp.replicas[i].forward(ctx, batches[i])
        losses.push(cross_entropy(ctx, logits, targets[i]))

    // Backward on each device
    for i in 0..dp.world.size:
        backward(&dp.world.contexts[i], losses[i])

    // Allreduce gradients
    dp_sync_gradients(dp)

    // Each device updates independently (same grads → same weights)
    for i in 0..dp.world.size:
        opt.step(&dp.world.contexts[i])
        opt.zero_grad()

fn dp_sync_gradients(dp: &DataParallel):
    let params = dp.replicas[0].parameters()
    for pi in 0..params.len():
        for i in 0..dp.world.size:
            let grad = dp.replicas[i].parameters()[pi].grad_meta.grad
            crux.allreduce_sum(dp.world.streams[0], grad.view, grad.view)
        crux.stream_sync(dp.world.streams[0])
    // Divide by world size for mean
    for i in 0..dp.world.size:
        for pi in 0..params.len():
            let grad = dp.replicas[i].parameters()[pi].grad_meta.grad
            *grad = div_scalar(&dp.world.contexts[i], *grad,
                              dp.world.size as f64)
```

### 8.3 Tensor Parallel

Model split across devices. Each device holds a column or row
shard of each linear layer. Communication happens mid-layer
(allreduce after each parallel region).

```
type TensorParallel = {
    world: *mut World,
    shards: Vec[TransformerShard],
}

type TransformerShard = {
    embed: Embedding,                // replicated
    blocks: Vec[TransformerBlockShard],
    norm: RMSNorm,                   // replicated
    lm_head_shard: Linear,           // column-sharded
}

type TransformerBlockShard = {
    attention: MultiHeadAttentionShard,
    ffn: FFNShard,
    norm1: RMSNorm,
    norm2: RMSNorm,
}

// Attention: Q/K/V column-sharded, O row-sharded
type MultiHeadAttentionShard = {
    q_proj: Linear,    // [dim/N, dim]
    k_proj: Linear,    // [dim/N, dim]
    v_proj: Linear,    // [dim/N, dim]
    o_proj: Linear,    // [dim, dim/N] — row shard
    num_heads: i32,    // total heads / N
    head_dim: usize,
}

// FFN: gate/up column-sharded, down row-sharded
type FFNShard = {
    gate_proj: Linear,  // [intermediate/N, dim]
    up_proj: Linear,    // [intermediate/N, dim]
    down_proj: Linear,  // [dim, intermediate/N] — row shard
}
```

Sharding a model:

```
fn tensor_parallel(model: &Transformer, world: *mut World) -> TensorParallel:
    let n = world.size as usize
    var shards = Vec.new()
    for i in 0..n:
        let device = world.devices[i]
        var block_shards = Vec.new()
        for b in 0..model.blocks.len():
            let block = &model.blocks[b]
            block_shards.push(TransformerBlockShard {
                attention: shard_attention(&block.attention, i, n, device),
                ffn: shard_ffn(&block.ffn, i, n, device),
                norm1: clone_to(&block.norm1, device),
                norm2: clone_to(&block.norm2, device),
            })
        shards.push(TransformerShard {
            embed: clone_to(&model.embed, device),
            blocks: block_shards,
            norm: clone_to(&model.norm, device),
            lm_head_shard: shard_linear_column(&model.lm_head, i, n, device),
        })
    TensorParallel { world, shards }

fn shard_linear_column(l: &Linear, rank: usize, world_size: usize,
                        device: *mut Device) -> Linear:
    let shard_size = l.out_features / world_size
    let w = slice(l.weight, 0, rank * shard_size, (rank + 1) * shard_size)
    let w = to(w, device)
    let b = if l.bias.storage != null:
        to(slice(l.bias, 0, rank * shard_size, (rank + 1) * shard_size), device)
    else: null_tensor()
    Linear { weight: w, bias: b, in_features: l.in_features,
             out_features: shard_size }

fn shard_linear_row(l: &Linear, rank: usize, world_size: usize,
                     device: *mut Device) -> Linear:
    let shard_size = l.in_features / world_size
    let w = slice(l.weight, 1, rank * shard_size, (rank + 1) * shard_size)
    Linear { weight: to(w, device), bias: to(l.bias, device),
             in_features: shard_size, out_features: l.out_features }
```

Forward with communication:

```
fn tp_block_forward(shard: &TransformerBlockShard, ctx: &Context,
                     world: *mut World, rank: i32, x: &Tensor) -> Tensor:
    // Attention: column-parallel Q/K/V, local attention, row-parallel O
    let normed = rms_norm(ctx, x, shard.norm1.weight, shard.norm1.eps)

    let q = linear(ctx, normed, shard.attention.q_proj.weight, shard.attention.q_proj.bias)
    let k = linear(ctx, normed, shard.attention.k_proj.weight, shard.attention.k_proj.bias)
    let v = linear(ctx, normed, shard.attention.v_proj.weight, shard.attention.v_proj.bias)

    // ... reshape, attention, reshape back ...
    let attn_out = scaled_dot_product_attention(ctx, q, k, v, null, scale)
    var out = linear(ctx, attn_out, shard.attention.o_proj.weight, shard.attention.o_proj.bias)

    // Allreduce: each device has partial result from its row shard
    crux.allreduce_sum(world.streams[rank], out.view, out.view)
    crux.stream_sync(world.streams[rank])

    let h = add(ctx, x, out)

    // FFN: same pattern
    let normed2 = rms_norm(ctx, h, shard.norm2.weight, shard.norm2.eps)
    let gate = silu(ctx, linear(ctx, normed2, shard.ffn.gate_proj.weight, shard.ffn.gate_proj.bias))
    let up = linear(ctx, normed2, shard.ffn.up_proj.weight, shard.ffn.up_proj.bias)
    var ffn_out = linear(ctx, mul(ctx, gate, up),
                         shard.ffn.down_proj.weight, shard.ffn.down_proj.bias)

    crux.allreduce_sum(world.streams[rank], ffn_out.view, ffn_out.view)
    crux.stream_sync(world.streams[rank])

    add(ctx, h, ffn_out)

fn tp_forward(tp: &TensorParallel, tokens: &Tensor) -> Tensor:
    var h = Vec.new()
    for i in 0..tp.world.size:
        h.push(to(tokens, tp.world.devices[i]))

    for i in 0..tp.world.size:
        h[i] = embedding(&tp.world.contexts[i], tp.shards[i].embed.weight, h[i])

    for block_idx in 0..tp.shards[0].blocks.len():
        for i in 0..tp.world.size:
            h[i] = tp_block_forward(&tp.shards[i].blocks[block_idx],
                                    &tp.world.contexts[i], tp.world, i, h[i])

    let ctx = &tp.world.contexts[0]
    h[0] = rms_norm(ctx, h[0], tp.shards[0].norm.weight, tp.shards[0].norm.eps)
    linear(ctx, h[0], tp.shards[0].lm_head_shard.weight,
           tp.shards[0].lm_head_shard.bias)
```

### 8.4 FSDP (Fully Sharded Data Parallel / ZeRO-3)

Every device holds 1/N of every parameter, 1/N of every gradient,
and 1/N of every optimizer state. Parameters are gathered layer-by-
layer during forward and backward, then immediately discarded.

```
type ShardedParam = {
    shard: Tensor,
    full_shape: Shape,
    name: str,
    world_size: i32,
}

type FSDP = {
    world: *mut World,
    sharded_params: Vec[Vec[ShardedParam]],  // [layer_idx][param_idx]
    module_config: ModelConfig,
    num_layers: i32,
}

fn fsdp(model: &Transformer, world: *mut World) -> FSDP:
    let n = world.size as usize
    var all_sharded = Vec.new()

    for layer_idx in 0..model.num_layers():
        let params = model.layer_parameters(layer_idx)
        var layer_sharded = Vec.new()
        for (name, param) in params:
            let total_elems = numel(param)
            let shard_elems = total_elems / n
            var shards = Vec.new()
            for rank in 0..n:
                let start = rank * shard_elems
                let end = (rank + 1) * shard_elems
                let flat = flatten(param, 0, -1)
                let shard_data = slice(flat, 0, start, end)
                let shard = to(shard_data, world.devices[rank])
                shard.grad_meta = alloc_grad_meta(requires_grad: true, is_leaf: true)
                shards.push(ShardedParam {
                    shard,
                    full_shape: shape(param),
                    name,
                    world_size: n as i32,
                })
            layer_sharded.push(shards)
        all_sharded.push(layer_sharded)

    FSDP {
        world,
        sharded_params: all_sharded,
        module_config: model.config,
        num_layers: model.blocks.len() as i32,
    }
```

Core FSDP operations — gather and scatter:

```
fn fsdp_gather_layer(fsdp: &FSDP, layer_idx: i32, rank: i32) -> Vec[Tensor]:
    let ctx = &fsdp.world.contexts[rank]
    var full_params = Vec.new()

    for sp_group in &fsdp.sharded_params[layer_idx]:
        let sp = &sp_group[rank]
        let full_size = sp.full_shape.elem_count() * dtype_size(dtype(sp.shard))
        let full_stor = storage_new(ctx.device, full_size)
        let full_view = view_contiguous(full_stor.memory, sp.full_shape, dtype(sp.shard))
        let full = tensor_from_storage(full_stor, full_view, ctx.device)

        crux.allgather(fsdp.world.streams[rank], sp.shard.view, full.view)
        crux.stream_sync(fsdp.world.streams[rank])

        full_params.push(full)
    full_params

fn fsdp_release_layer(full_params: Vec[Tensor]):
    // With @[drop], this is automatic — just let them go out of scope.
    // Each Tensor's Drop decrements Storage refcount → Crux memory freed.

fn fsdp_reduce_scatter_grads(fsdp: &FSDP, layer_idx: i32, rank: i32,
                              full_grads: &[Tensor]):
    for i in 0..full_grads.len():
        let sp = &fsdp.sharded_params[layer_idx][i][rank]
        let shard_grad = zeros(shape(sp.shard), dtype(sp.shard),
                               fsdp.world.devices[rank])
        crux.reduce_scatter(fsdp.world.streams[rank],
                           full_grads[i].view, shard_grad.view)
        crux.stream_sync(fsdp.world.streams[rank])
        sp.shard.grad_meta.grad = shard_grad
```

FSDP forward — gather one layer at a time:

```
fn fsdp_forward(fsdp: &FSDP, rank: i32, input: &Tensor) -> Tensor:
    let ctx = &fsdp.world.contexts[rank]
    var h = clone(input)

    for layer_idx in 0..fsdp.num_layers:
        ctx.current_layer = layer_idx
        let full_params = fsdp_gather_layer(fsdp, layer_idx, rank)

        let block = build_temp_block(full_params, fsdp.module_config)
        h = block.forward(ctx, h)
        // full_params dropped at end of loop body — memory freed via Drop
    ctx.current_layer = -1
    h
```

FSDP backward — re-gather per layer, reduce-scatter grads:

```
fn fsdp_backward(fsdp: &FSDP, rank: i32, loss: &Tensor):
    let ctx = &fsdp.world.contexts[rank]

    backward_with_hooks(ctx, loss, BackwardHook {
        pre_layer: fn(layer_idx: i32, ctx: &Context):
            let full = fsdp_gather_layer(fsdp, layer_idx, rank)
            stash_full_params(layer_idx, full)

        post_layer: fn(layer_idx: i32, ctx: &Context):
            let full = get_stashed_params(layer_idx)
            let grads = extract_grads(full)
            fsdp_reduce_scatter_grads(fsdp, layer_idx, rank, grads)
            // full dropped here — memory freed via Drop
    })
```

FSDP optimizer — works on shards only:

```
type ShardedAdam = {
    world: *mut World,
    fsdp: *mut FSDP,
    lr: f64,
    beta1: f64,
    beta2: f64,
    eps: f64,
    weight_decay: f64,
    m: Vec[Vec[Tensor]],   // [layer][param] — 1/N sized
    v: Vec[Vec[Tensor]],   // [layer][param] — 1/N sized
    t: i64,
}

fn sharded_adam(fsdp: &FSDP, world: *mut World, lr: f64) -> ShardedAdam:
    // Initialize m, v as zeros matching each shard's shape
    ...

impl Optimizer for ShardedAdam:
    fn step(self: &mut Self, rank: i32):
        self.t = self.t + 1
        let ctx = &self.world.contexts[rank]
        for layer in 0..self.fsdp.num_layers:
            for pi in 0..self.fsdp.sharded_params[layer].len():
                let sp = &self.fsdp.sharded_params[layer][pi][rank]
                let grad = sp.shard.grad_meta.grad
                // Fused Adam on the 1/N shard — same kernel as single-device
                fused_adam_step(ctx, &sp.shard, grad,
                               &self.m[layer][pi], &self.v[layer][pi],
                               self.lr, self.beta1, self.beta2,
                               self.eps, self.t)
```

Memory accounting:

```
// 7B parameter model, float32, 4 GPUs
//
// Without FSDP (data parallel):
//   Per GPU: 28 GB params + 28 GB grads + 56 GB optimizer = 112 GB
//
// With FSDP:
//   Per GPU: 7 GB param shards + 7 GB grad shards + 14 GB opt state = 28 GB
//   Temporary: one layer gathered ≈ 200 MB
//   Peak: ~28.2 GB per GPU
//
// 70B model, 8 GPUs:
//   Per GPU: 35 GB shards + 35 GB grad + 70 GB opt = 140 GB
//   Mixed precision (bf16 params, fp32 opt):
//   Per GPU: 17.5 GB + 17.5 GB + 70 GB = 105 GB
```

### 8.5 Pipeline Parallel

For very large models that don't fit on one device even with FSDP.
Split the model by layers.

```
type PipelineParallel = {
    world: *mut World,
    stage_modules: Vec[Vec[TransformerBlock]],
    stage_boundaries: Vec[i32],
    num_microbatches: i32,
}

fn pipeline_parallel(model: &Transformer, world: *mut World,
                      splits: Vec[i32]) -> PipelineParallel:
    // splits = [8, 16, 24, 32] → device 0 gets layers 0-7, etc.
    ...

fn pp_forward(pp: &PipelineParallel, input: &Tensor) -> Tensor:
    let microbatches = chunk(input, pp.num_microbatches, 0)

    // Pipeline schedule: 1F1B (one forward, one backward)
    // Stage 0: F0 F1 F2 F3 B3 B2 B1 B0
    // Stage 1:    F0 F1 F2 B2 F3 B1 B0 B3
    // Stage 2:       F0 F1 B1 F2 B0 F3 B2 B3
    // Stage 3:          F0 B0 F1 B1 F2 B2 F3 B3
    for mb in microbatches:
        var h = mb
        for stage in 0..pp.world.size:
            let ctx = &pp.world.contexts[stage]
            if stage > 0:
                h = to(h, ctx.device)   // send activation to next stage
            for block in &pp.stage_modules[stage]:
                h = block.forward(ctx, h)
    // ... interleave forward and backward for pipeline efficiency
```

### 8.6 Combining strategies

Real-world large model training combines multiple strategies:

```
// LLaMA 70B on 32 GPUs:
//   - 4-way tensor parallel (within node)
//   - 8-way FSDP (across nodes)
//   = 4 × 8 = 32 GPUs

type HybridParallel = {
    tp_world: World,      // 4 GPUs within a node
    fsdp_world: World,    // 8 nodes
}
```

The composability comes from the fact that each strategy is
independent orchestration. TP handles intra-layer communication.
FSDP handles parameter sharding. PP handles inter-layer pipelining.
They compose because they operate on different axes.

### 8.7 Distributed inference

Inference uses tensor parallel only (no gradient sharding needed):

```
fn distributed_generate(tp: &TensorParallel, tokenizer: &Tokenizer,
                         prompt: &str, max_tokens: i32) -> str:
    for ctx in &tp.world.contexts:
        no_grad(ctx)

    let tokens = encode(tokenizer, prompt)
    var input = tensor_i32(tokens, shape2(1, tokens.len()),
                           tp.world.devices[0])

    var output_tokens = Vec.new()
    for i in 0..max_tokens:
        let logits = tp_forward(tp, input)
        let next = argmax(&tp.world.contexts[0], logits, -1)
        output_tokens.push(item(next) as i32)
        input = cat(&tp.world.contexts[0],
                    [input, unsqueeze(next, 0)], 1)

    decode(tokenizer, output_tokens)
```

---

## Part 9: Optimizers

```
trait Optimizer =
    fn step(self: &mut Self, ctx: &Context)
    fn zero_grad(self: &mut Self)

type Adam = {
    params: Vec[*mut Tensor],
    lr: f64,
    beta1: f64,
    beta2: f64,
    eps: f64,
    weight_decay: f64,
    m: Vec[Tensor],
    v: Vec[Tensor],
    t: i64,
}

fn adam(params: Vec[*mut Tensor], lr: f64) -> Adam:
    Adam {
        params, lr,
        beta1: 0.9, beta2: 0.999, eps: 1e-8, weight_decay: 0.0,
        m: Vec.new(),  // lazily initialized
        v: Vec.new(),
        t: 0,
    }

impl Optimizer for Adam:
    fn step(self: &mut Self, ctx: &Context):
        self.t = self.t + 1
        for i in 0..self.params.len():
            let p = self.params[i]
            let g = p.grad_meta.grad
            if g == null: continue

            // AdamW weight decay
            if self.weight_decay != 0.0:
                *p = sub(ctx, *p, mul_scalar(ctx, *p, self.lr * self.weight_decay))

            // Update moments
            self.m[i] = add(ctx, mul_scalar(ctx, self.m[i], self.beta1),
                           mul_scalar(ctx, g, 1.0 - self.beta1))
            self.v[i] = add(ctx, mul_scalar(ctx, self.v[i], self.beta2),
                           mul_scalar(ctx, mul(ctx, g, g), 1.0 - self.beta2))

            // Bias correction
            let m_hat = div_scalar(ctx, self.m[i], 1.0 - pow(self.beta1, self.t as f64))
            let v_hat = div_scalar(ctx, self.v[i], 1.0 - pow(self.beta2, self.t as f64))

            // Update params
            *p = sub(ctx, *p, mul_scalar(ctx, div(ctx, m_hat, add_scalar(ctx, sqrt(ctx, v_hat), self.eps)), self.lr))

    fn zero_grad(self: &mut Self):
        for p in self.params:
            p.grad_meta.grad = null
```

### Fused optimizer kernel

The naive Adam above issues ~15 dispatches per parameter per step.
The fused version is one dispatch:

```
program fused_adam(
    param: inout [N] f32,
    grad: in [N] f32,
    m: inout [N] f32,
    v: inout [N] f32,
    lr: constant f32,
    beta1: constant f32,
    beta2: constant f32,
    eps: constant f32,
    t: constant i32
):
    parallel i in 0..N:
        let g = load(grad, [i])
        let mi = fma(beta1, load(m, [i]), (1.0 - beta1) * g)
        let vi = fma(beta2, load(v, [i]), (1.0 - beta2) * g * g)
        store(m, [i], mi)
        store(v, [i], vi)
        let m_hat = mi / (1.0 - pow(beta1, t))
        let v_hat = vi / (1.0 - pow(beta2, t))
        store(param, [i], load(param, [i]) - lr * m_hat / (sqrt(v_hat) + eps))
```

One dispatch per parameter per step. The ShardedAdam for FSDP uses
the exact same kernel — just on 1/N-sized tensors.

---

## Part 10: Data Loading

### Safetensors

```
type SafetensorsFile = {
    path: str,
    metadata: HashMap[str, TensorInfo],
}

type TensorInfo = {
    dtype: DType,
    shape: Shape,
    offset_start: usize,
    offset_end: usize,
}

fn load_safetensors(path: &str) -> SafetensorsFile
fn load_tensor(file: &SafetensorsFile, name: &str, device: *mut Device) -> Tensor
fn load_weights(model: &mut Transformer, file: &SafetensorsFile, device: *mut Device)
```

### Sharded weight loading (for distributed)

```
fn load_weights_sharded(fsdp: &mut FSDP, file: &SafetensorsFile):
    for layer_idx in 0..fsdp.num_layers:
        for sp_group in &fsdp.sharded_params[layer_idx]:
            let name = sp_group[0].name
            let full_tensor = load_tensor(file, name, cpu_device())
            let flat = flatten(full_tensor, 0, -1)
            for rank in 0..fsdp.world.size:
                let start = rank * numel(sp_group[rank].shard)
                let end = start + numel(sp_group[rank].shard)
                let shard_data = slice(flat, 0, start, end)
                sp_group[rank].shard = to(shard_data, fsdp.world.devices[rank])

fn load_weights_tp(tp: &mut TensorParallel, file: &SafetensorsFile):
    // Load full weights, shard per tensor parallel config
    for i in 0..tp.world.size:
        for block_idx in 0..tp.shards[i].blocks.len():
            // Column-shard Q/K/V/gate/up, row-shard O/down
            ...
```

### GGUF

```
fn load_gguf(path: &str) -> GGUFFile
fn load_gguf_tensor(file: &GGUFFile, name: &str, device: *mut Device) -> Tensor
```

### Tokenizer

```
type Tokenizer = {
    vocab: Vec[str],
    merges: Vec[(i32, i32)],
    special_tokens: HashMap[str, i32],
}

fn tokenizer_from_file(path: &str) -> Tokenizer
fn encode(tok: &Tokenizer, text: &str) -> Vec[i32]
fn decode(tok: &Tokenizer, tokens: &[i32]) -> str
```

---

## Part 11: The Dispatch Path

```
1. matmul(ctx, a, b) called
   — compiler auto-refs to matmul(&ctx, &a, &b)
2. Validate: shapes, dtypes, same device (via storage.device)
3. Compute output shape
4. Allocate output Storage (new, refcount = 1)
5. Create output View
6. Look up program (key: op + dtype + tile, NOT shapes)
7. Build bindings (borrow input views)
8. crux.dispatch(ctx.stream, program, bindings)
9. If grad_enabled(ctx) and inputs require grad:
     save_tensor on needed inputs (borrows, retains Storage)
     Create GradNode (layer_idx from ctx.current_layer)
     Attach to output's grad_meta
10. Return owned Tensor
    — intermediates auto-dropped on scope exit via Drop
    — Storage refcount decremented for each drop
    — at refcount 0, Crux memory freed
```

### Program key policy

Programs keyed by (op, dtype, tile_size) — NOT by input shapes.
~80 compiled programs total. Compile once, reuse forever.

---

## Part 12: What The User Sees

### Single-device training

```
let ctx = context_default()
let model = transformer_new(config, ctx.device)
let opt = adam(model.parameters(), lr: 3e-4)

for batch in dataloader:
    let logits = model.forward(ctx, batch.tokens)
    let loss = cross_entropy(ctx, logits, batch.targets)
    backward(ctx, loss)
    opt.step(ctx)
    opt.zero_grad()
    print("loss: {loss.item()}")
    // logits, loss dropped at end of loop body — memory freed
```

### Multi-GPU training (data parallel)

```
let world = world_default()
let dp = data_parallel(model, world)
let opt = adam(dp.replicas[0].parameters(), lr: 3e-4)

for batch in dataloader:
    let shards = split_batch(batch, world.size)
    dp_train_step(dp, shards.tokens, shards.targets, opt)
```

### Large model training (FSDP)

```
let world = world_default()
let model = llama_new(config_70b)
let fsdp = fsdp(model, world)
let opt = sharded_adam(fsdp, world, lr: 1e-4)

for batch in dataloader:
    let shards = split_batch(batch, world.size)
    for rank in 0..world.size:
        let input = tensor_i32(shards[rank].tokens, shards[rank].shape, world.devices[rank])
        let logits = fsdp_forward(fsdp, rank, input)
        let loss = cross_entropy(world.contexts[rank], logits, shards[rank].targets)
        fsdp_backward(fsdp, rank, loss)
    opt.step_all()
    opt.zero_grad_all()
```

### Single-device inference

```
let ctx = context_default()
no_grad(ctx)
defer: restore_grad(ctx)

let model = llama_new(config)
load_weights(model, load_safetensors("model.safetensors"), ctx.device)

let tok = tokenizer_from_file("tokenizer.json")
let tokens = encode(tok, "Hello")
var input = tensor_i32(tokens, shape2(1, tokens.len()), ctx.device)

for i in 0..100:
    let logits = model.forward(ctx, input)
    let next = argmax(ctx, slice(logits, 1, -1, 0), -1)
    input = cat(ctx, [input, unsqueeze(next, 0)], 1)
    print(decode(tok, [item(next) as i32]))
    // logits, next dropped each iteration — memory freed automatically
```

### Multi-GPU inference (tensor parallel)

```
let world = world_default()
let model = llama_new(config_70b)
let tp = tensor_parallel(model, world)
load_weights_tp(tp, load_safetensors("model.safetensors"))

let text = distributed_generate(tp, tok, "Hello", 100)
print(text)
```

### Custom Crux kernel (escape hatch always available)

```
let kernel = crux.compile(ctx.device, ProgramSource { ir_text: "...", ... })

fn custom_op(ctx: &Context, t: &Tensor) -> Tensor:
    let out = zeros(shape(t), dtype(t), device(t))
    crux.dispatch(ctx.stream, kernel,
                  bindings_from([bind("x", t.view), bind("out", out.view)]))
    out
```

**No `&` visible in any user code.** Auto-referencing handles it.

---

## Part 13: Errors

```
enum WeldError =
    | CruxError(CruxError)
    | ShapeMismatch(str)
    | DTypeMismatch(str)
    | DeviceMismatch(str)
    | GradError(str)
    | LoadError(str)
    | TokenizerError(str)
    | DistributedError(str)
```

---

## Part 14: What Weld Is NOT

**Not a graph compiler.** No lazy evaluation, no tracing, no JIT.
Every dispatch is real. If graph capture is needed, it's a separate
layer above Weld.

**Not a model zoo.** Weld ships enough to build a transformer.
Specific model definitions are separate packages.

**Not backward-compatible with PyTorch.** The API is shaped like
PyTorch but is not a drop-in.

**Not a runtime.** Weld doesn't manage threads, devices, or
scheduling. Crux does that. Weld is a library of functions.

---

## Part 15: Implementation Plan

```
Session  Deliverable
──────── ──────────────────────────────────────────────────
 14      Tensor (with Drop), Storage (refcount), Context (grad
         stack). Ownership model verification: auto-ref, drop,
         borrow patterns.

 15      Elementwise ops (all &Tensor). Broadcasting engine.
         Scalar ops with spec constant path. Type casting.

 16      Matmul, bmm, linear (fused). View ops (&Tensor →
         owned Tensor sharing Storage).

 17      Reductions. Fused: softmax, layer_norm, rms_norm,
         embedding, rope, cross_entropy, dropout.

 18      Autograd: GradNode, SavedTensor, backward, graph
         lifecycle (free after backward), gradient hooks,
         unbroadcast. Backward fns for all core ops.

 19      nn modules: Linear, LayerNorm, RMSNorm, Embedding,
         MultiHeadAttention, FFN, TransformerBlock, Transformer.
         Module trait with named_parameters. All forward methods
         take &Tensor.

 20      Optimizers: SGD, Adam, AdamW. Fused Adam kernel.

 21      Data: safetensors parser, weight loading, BPE tokenizer.

 22      GPT-2 124M forward. Numerical verification vs PyTorch.
         Token-by-token generation.

 23      KV cache: paged, pre-allocated. Attention with cache.
         Flash attention kernel.

 24      Batched inference. Continuous batching.

 25      Sampling: temperature, top-k, top-p, repetition penalty.
         End-to-end generate(). Benchmark tok/s vs llama.cpp
         and MLX.

 28      weld.distributed: World type. Data Parallel with
         allreduce gradient sync. Test on multi-GPU.

 29      Tensor Parallel: column/row sharding, allreduce after
         each layer. Distributed inference.

 30      FSDP: sharded params, allgather/reduce-scatter per
         layer, sharded optimizer. Memory verification.

 31      Pipeline Parallel (1F1B schedule). Hybrid TP + FSDP.

 32      Sharded weight loading. GGUF quantized loading.
         Distributed end-to-end training benchmark.
```

---

## Part 16: Design Decisions

| Decision | Rationale |
|---|---|
| Inputs by reference, outputs owned | Resolves Drop + ergonomics conflict. Auto-ref makes `&` invisible. |
| Auto-referencing at all call sites | The language feature that makes Choice C free. |
| Storage refcount, not Tensor | Ownership on shared memory, not the view. |
| Device on Storage, not Tensor | Single source of truth. |
| GradMeta as sidecar | Inference pays zero autograd cost. |
| SavedTensor, not full Tensor | Smaller: just storage + view. |
| Automatic drop | No manual cleanup. No leaks on error paths. |
| Grad stack (push/pop) | Nested no_grad contexts compose correctly. |
| ctx.current_layer | Thread-safe FSDP layer tracking. |
| Functions over methods | Greppable, composable, no dispatch. |
| Fused nn ops | One dispatch per op. |
| Graph freed after backward | Prevents leaks. Graph is ephemeral. |
| retain_graph explicit | Opt-in for multiple backward. |
| Debug assertions on GradNode | Catch misalignment in debug builds. |
| Program key: op+dtype+tile | Not shape. Prevents cache explosion. |
| NumPy broadcasting | Industry standard. |
| Eager forever | Predictable, debuggable. |
| Distributed is native | Ships with Weld. No external deps. |
| Tensor is single-device | Distributed is orchestration, not tensor semantics. |
| Operator traits take &Self | `a + b` borrows both, returns new. |
| Crux always accessible | Weld is convenience, not a wall. |