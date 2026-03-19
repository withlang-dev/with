# Weld — Implementation Notes (v3)

**Companion to:** weld-design.md (v5)
**Audience:** The agent implementing Weld in With.

---

## Foundational Rules

### Rule 1: All handles are pointers cast to i64
Same as Crux. No Vec registries.

### Rule 2: Tensor is small
Two pointers + inline View. Device read from `storage.device`.

### Rule 3: Storage owns the refcount
Multiple Tensors share one Storage. One retain path, one release path.

### Rule 4: GradMeta is allocated lazily
Never when `grad_enabled(ctx)` is false.

### Rule 5: Graph freed after backward (default)
`retain_graph = true` is explicit opt-in.

### Rule 6: Context is explicit
No global mutable state. Every op takes `&Context`.

### Rule 7: Distributed is orchestration
No distributed metadata on Tensor.

### Rule 8: Drop handles cleanup
With's `@[drop]` on Tensor and Storage. Automatic on scope exit.

### Rule 9: Program keys exclude shapes
Keyed by (op, dtype, tile). ~80 total programs.

### Rule 10: SavedTensor is minimal
`SavedTensor { storage, view }`. No grad_meta, no device.

### Rule 11: Inputs are borrowed, outputs are owned
Every Weld operation takes `&Tensor` inputs and returns `Tensor`.
With's auto-referencing makes `&` invisible at call sites. This
is the rule that resolves the Drop + ergonomics conflict.

**What the user writes:**
```
let c = add(ctx, a, b)
```

**What the compiler sees:**
```
let c = add(&ctx, &a, &b)
```

**What this means for implementation:**
- Function signatures: all Tensor params are `&Tensor`
- Inside the function: you read through the reference, never consume
- Return values: always owned `Tensor`, never `&Tensor`
- View ops: borrow input, retain storage, return new owned Tensor
- Compute ops: borrow inputs, allocate new storage, return owned
- save_tensor: borrows input, retains storage, no consumption

---

## File Structure

```
lib/weld/
├── tensor.w                # Tensor, Storage, refcount, Drop impl
├── grad.w                  # GradMeta, GradNode, SavedTensor, SavedState
├── context.w               # Context, ProgramRegistry, grad stack
├── ops/
│   ├── elementwise.w       # add, sub, mul, neg, exp, relu, etc.
│   ├── reduce.w            # sum, mean, max, min, argmax
│   ├── matmul.w            # matmul, bmm, linear (fused)
│   ├── view_ops.w          # reshape, transpose, permute, slice
│   ├── data_ops.w          # cat, stack, gather, scatter, pad
│   ├── cast.w              # to_dtype, float, half, bfloat16
│   ├── fused.w             # softmax, layer_norm, rms_norm, etc.
│   └── broadcast.w         # broadcast_shapes, unbroadcast
├── backward/
│   ├── engine.w            # backward(), topo_sort, free_graph, hooks
│   ├── grad_add.w          # AddBackward
│   ├── grad_mul.w          # MulBackward
│   ├── grad_matmul.w       # MatmulBackward
│   ├── grad_relu.w         # ReluBackward
│   ├── grad_softmax.w      # SoftmaxBackward
│   ├── grad_ce.w           # CrossEntropyBackward
│   ├── grad_layernorm.w    # LayerNormBackward
│   ├── grad_embedding.w    # EmbeddingBackward
│   └── grad_linear.w       # LinearBackward
├── nn/
│   ├── module.w            # Module trait
│   ├── linear.w
│   ├── norm.w
│   ├── embedding.w
│   ├── attention.w
│   ├── ffn.w
│   ├── transformer.w
│   └── init.w
├── optim/
│   ├── optimizer.w
│   ├── sgd.w
│   ├── adam.w
│   └── fused_adam.ir
├── distributed/
│   ├── world.w
│   ├── data_parallel.w
│   ├── tensor_parallel.w
│   ├── fsdp.w
│   ├── pipeline.w
│   └── hybrid.w
├── data/
│   ├── safetensors.w
│   ├── gguf.w
│   ├── tokenizer.w
│   └── sharded_loader.w
├── error.w
└── test/
    ├── test_tensor.w
    ├── test_ownership.w    # NEW: borrow/drop/refcount verification
    ├── test_ops.w
    ├── test_broadcast.w
    ├── test_autograd.w
    ├── test_nn.w
    ├── test_distributed.w
    └── bench/
```

---

## Session 14: Tensor, Storage, Context, Ownership

This is the most critical session. It establishes the ownership
model that every subsequent session depends on.

### Storage

```
type Storage = {
    memory: i64,        // Crux memory handle
    device: i64,        // Crux device handle — single source of truth
    refcount: i32,
    size: usize,
}

fn storage_new(device: i64, size: usize) -> *mut Storage:
    let mem = crux_alloc(device, size)
    if mem == 0: return null
    let s = unsafe: malloc(sizeof[Storage]()) as *mut Storage
    unsafe:
        (*s).memory = mem
        (*s).refcount = 1
        (*s).size = size
        (*s).device = device
    s

fn storage_retain(s: *mut Storage):
    unsafe: (*s).refcount = (*s).refcount + 1

fn storage_release(s: *mut Storage):
    unsafe:
        (*s).refcount = (*s).refcount - 1
        if (*s).refcount == 0:
            crux_free((*s).memory)
            free(s as *mut c_void)
```

### Tensor with Drop

```
@[drop]
type Tensor = {
    storage: *mut Storage,
    view: View,
    grad_meta: *mut GradMeta,
}

impl Drop for Tensor:
    fn drop(self: &mut Self):
        if self.storage != null:
            storage_release(self.storage)
        if self.grad_meta != null:
            grad_meta_release(self.grad_meta)
```

**What Drop buys us:** When a Tensor goes out of scope on ANY
exit path — normal return, early return, `?` propagation, loop
break — the compiler inserts the drop call. Storage refcount
decrements. At refcount 0, Crux memory is freed. No manual cleanup.

**What move semantics mean:** When a Tensor is assigned to a new
binding or returned from a function, it is MOVED — the old binding
becomes invalid, and Drop is NOT called on it (the new owner is
responsible). This prevents double-free:

```
fn make_tensor() -> Tensor:
    let t = zeros(shape2(3, 4), Float32, device)
    t   // moved to caller — Drop NOT called here
    // if we did NOT return t, Drop WOULD be called here

fn use_tensor():
    let a = make_tensor()       // a owns the Tensor
    let b = a                   // MOVE: a is now invalid
    // using a here is a compile error
    // b is dropped at scope exit — refcount decremented
```

### How borrowing works in practice

The critical pattern: operations borrow inputs, return owned outputs.

```
fn add(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor:
    // a and b are borrowed — we can READ them but don't own them
    // the caller still owns the original Tensors

    let out_shape = broadcast_shapes(a.view.shape, b.view.shape)
    let out_size = shape_elem_count(out_shape) * dtype_size(a.view.dtype)
    let out_stor = storage_new(a.storage.device, out_size)
    let out_view = crux_view_contiguous(out_stor.memory, out_shape, a.view.dtype)

    // Dispatch — reads a.view and b.view through the references
    let prog = registry_get_or_compile(ctx.programs, elementwise_key(OP_ADD, a.view.dtype))
    crux_dispatch(ctx.stream, prog,
                  bindings_from([bind("a", a.view), bind("b", b.view),
                                bind("out", out_view)]))

    // Create owned output
    let out = Tensor { storage: out_stor, view: out_view, grad_meta: null }

    // Autograd — borrows a and b to read grad_meta
    if grad_enabled(ctx) and (has_grad(a) or has_grad(b)):
        attach_grad_node(&out, BACKWARD_ADD,
                         [a.grad_meta, b.grad_meta],
                         [a.view.shape, b.view.shape],
                         SavedState.empty(), ctx.current_layer)

    out  // moved to caller
    // a and b are NOT dropped — we only borrowed them
```

**At the call site:**

```
let x = zeros(shape2(3, 4), Float32, device)
let y = ones(shape2(3, 4), Float32, device)
let z = add(ctx, x, y)   // auto-refs: add(&ctx, &x, &y)
// x and y are still valid — they were borrowed, not consumed
// z is new, owned, refcount = 1

let w = add(ctx, x, z)   // x borrowed AGAIN — still valid
// z borrowed — still valid

// scope exit: w dropped, z dropped, y dropped, x dropped (LIFO)
// each drop decrements its Storage refcount
```

### View ops: borrow input, share storage

```
fn reshape(t: &Tensor, shape: Shape) -> Tensor:
    assert crux_view_is_contiguous(t.view)
    assert shape_elem_count(shape) == shape_elem_count(t.view.shape)
    let new_strides = contiguous_strides(shape, t.view.dtype)
    let new_view = View {
        memory: t.view.memory,
        offset: t.view.offset,
        shape,
        strides: new_strides,
        dtype: t.view.dtype,
    }
    storage_retain(t.storage)   // shared storage, refcount++
    Tensor { storage: t.storage, view: new_view, grad_meta: null }

fn transpose(t: &Tensor, dim0: i32, dim1: i32) -> Tensor:
    let new_view = crux_view_transpose(t.view, dim0, dim1)
    storage_retain(t.storage)
    Tensor { storage: t.storage, view: new_view, grad_meta: null }

fn slice(t: &Tensor, dim: i32, start: usize, end: usize) -> Tensor:
    let new_view = crux_view_slice(t.view, dim, start, end)
    storage_retain(t.storage)
    Tensor { storage: t.storage, view: new_view, grad_meta: null }
```

All view ops: borrow input (`&Tensor`), retain storage, return
new owned Tensor. The input survives. The output shares memory.
When either is dropped, refcount decrements. Memory freed at 0.

### Device access

```
fn device(t: &Tensor) -> *mut Device:
    t.storage.device
```

Borrows the Tensor to read its storage pointer. No ownership change.

### detach and clone

```
fn detach(t: &Tensor) -> Tensor:
    storage_retain(t.storage)
    Tensor { storage: t.storage, view: t.view, grad_meta: null }
    // Shared storage, no grad. Input still valid (borrowed).

fn clone(t: &Tensor) -> Tensor:
    let new_stor = storage_new(device(t), t.storage.size)
    crux_copy_bytes(crux_default_stream(device(t)),
                    t.storage.memory, 0,
                    new_stor.memory, 0,
                    t.storage.size)
    Tensor { storage: new_stor, view: t.view, grad_meta: null }
    // New storage, independent. Input still valid (borrowed).
```

### GradMeta

```
type GradMeta = {
    grad: *mut Tensor,
    grad_fn: *mut GradNode,
    requires_grad: i32,
    is_leaf: i32,
    refcount: i32,
}

fn alloc_grad_meta(requires_grad: bool, is_leaf: bool) -> *mut GradMeta:
    let gm = unsafe: malloc(sizeof[GradMeta]()) as *mut GradMeta
    unsafe:
        (*gm).grad = null
        (*gm).grad_fn = null
        (*gm).requires_grad = if requires_grad: 1 else: 0
        (*gm).is_leaf = if is_leaf: 1 else: 0
        (*gm).refcount = 1
    gm

fn grad_meta_release(gm: *mut GradMeta):
    unsafe:
        (*gm).refcount = (*gm).refcount - 1
        if (*gm).refcount == 0:
            if (*gm).grad != null:
                // grad is an owned Tensor — trigger its drop
                tensor_drop_explicit((*gm).grad)
            free(gm as *mut c_void)
```

### Context

```
type Context = {
    device: i64,
    stream: i64,
    programs: i64,
    grad_stack: Vec[i32],
    current_layer: i32,
}

fn grad_enabled(ctx: &Context) -> bool:
    if ctx.grad_stack.len() == 0: return true
    ctx.grad_stack.get(ctx.grad_stack.len() - 1) != 0

fn no_grad(ctx: &mut Context):
    ctx.grad_stack.push(0)

fn enable_grad(ctx: &mut Context):
    ctx.grad_stack.push(1)

fn restore_grad(ctx: &mut Context):
    if ctx.grad_stack.len() > 0:
        ctx.grad_stack.pop()
```

### Ownership model tests (session 14 — CRITICAL)

These tests verify the ownership model works correctly. They must
all pass before any other session begins.

```
test "borrow does not consume":
    let a = zeros(shape2(3, 4), Float32, device)
    let b = add(ctx, a, a)        // a borrowed twice — must compile
    let c = add(ctx, a, b)        // a borrowed again — still valid
    assert c.storage != a.storage  // c has new storage
    // a, b, c dropped at scope exit — three refcount decrements

test "view op shares storage":
    let a = zeros(shape2(3, 4), Float32, device)
    let b = transpose(a, 0, 1)    // a borrowed, b shares storage
    assert a.storage == b.storage
    assert storage_refcount(a.storage) == 2
    // a and b dropped — refcount goes 2→1→0, memory freed

test "move transfers ownership":
    let a = zeros(shape2(3, 4), Float32, device)
    let b = a                      // MOVE — a is now invalid
    // assert a.storage ...        // COMPILE ERROR if we try to use a
    // b dropped — refcount 1→0, freed

test "return moves, does not drop":
    fn make() -> Tensor:
        let t = zeros(shape2(3, 4), Float32, device)
        t   // moved to caller
    let x = make()
    assert storage_refcount(x.storage) == 1
    // x dropped at scope exit — freed

test "intermediate temporaries are dropped":
    let a = zeros(shape2(3, 4), Float32, device)
    let b = ones(shape2(3, 4), Float32, device)
    // relu(ctx, add(ctx, a, b)):
    //   add returns temporary T1 (refcount 1)
    //   relu borrows T1, returns T2 (refcount 1)
    //   T1 dropped at end of expression — refcount 1→0, freed
    let c = relu(ctx, add(ctx, a, b))
    // only c's storage is alive, the intermediate from add is freed
    assert storage_refcount(c.storage) == 1

test "reassignment drops old value":
    var h = zeros(shape2(3, 4), Float32, device)
    let old_storage = h.storage
    h = ones(shape2(3, 4), Float32, device)
    // old h was dropped — old_storage refcount decremented
    // new h has different storage

test "no grad meta during inference":
    no_grad(ctx)
    defer: restore_grad(ctx)
    let a = zeros(shape2(3, 4), Float32, device)
    let b = relu(ctx, a)
    assert b.grad_meta == null

test "save_tensor retains storage":
    let a = zeros(shape2(3, 4), Float32, device)
    let saved = save_tensor(a)    // borrows a, retains storage
    assert storage_refcount(a.storage) == 2
    release_saved(saved)
    assert storage_refcount(a.storage) == 1

test "nested no_grad":
    assert grad_enabled(ctx) == true
    no_grad(ctx)
    assert grad_enabled(ctx) == false
    enable_grad(ctx)
    assert grad_enabled(ctx) == true
    restore_grad(ctx)
    assert grad_enabled(ctx) == false
    restore_grad(ctx)
    assert grad_enabled(ctx) == true
```

---

## Session 15: Elementwise + Broadcasting

### Binary op pattern

All binary ops use one factored helper:

```
fn binary_elementwise(ctx: &Context, a: &Tensor, b: &Tensor,
                       op: i32, backward_id: i32,
                       make_saved: fn(&Tensor, &Tensor) -> SavedState) -> Tensor:
    assert device(a) == device(b)
    assert a.view.dtype == b.view.dtype

    let out_shape = broadcast_shapes(a.view.shape, b.view.shape)
    let a_view = crux_view_broadcast(a.view, out_shape)
    let b_view = crux_view_broadcast(b.view, out_shape)

    let out_size = shape_elem_count(out_shape) * dtype_size(a.view.dtype)
    let out_stor = storage_new(device(a), out_size)
    let out_view = crux_view_contiguous(out_stor.memory, out_shape, a.view.dtype)

    let key = elementwise_key(op, a.view.dtype)
    let prog = registry_get_or_compile(ctx.programs, key, op, a.view.dtype)
    crux_dispatch(ctx.stream, prog,
                  bindings_from([bind("a", a_view), bind("b", b_view),
                                bind("out", out_view)]))

    var out = Tensor { storage: out_stor, view: out_view, grad_meta: null }
    if grad_enabled(ctx) and (has_grad(a) or has_grad(b)):
        let saved = make_saved(a, b)  // borrows a, b — still valid
        attach_grad_node(&out, backward_id,
                         [a.grad_meta, b.grad_meta],
                         [a.view.shape, b.view.shape],
                         saved, ctx.current_layer)
    out
```

**Note:** `make_saved` receives `&Tensor` — it borrows the inputs
to call `save_tensor`, which retains their Storage. The inputs are
NOT consumed by the saved state creation.

Then each op is trivial:

```
fn add(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor:
    binary_elementwise(ctx, a, b, OP_ADD, BACKWARD_ADD,
                       fn(a: &Tensor, b: &Tensor): SavedState.empty())

fn mul(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor:
    binary_elementwise(ctx, a, b, OP_MUL, BACKWARD_MUL,
                       fn(a: &Tensor, b: &Tensor): SavedState {
                           tensors: [save_tensor(a), save_tensor(b)],
                           shapes: [], scalars: [],
                       })

fn sub(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor:
    binary_elementwise(ctx, a, b, OP_SUB, BACKWARD_SUB,
                       fn(a: &Tensor, b: &Tensor): SavedState.empty())
```

### Unary op pattern

```
fn unary_elementwise(ctx: &Context, t: &Tensor,
                      op: i32, backward_id: i32,
                      make_saved: fn(&Tensor) -> SavedState) -> Tensor:
    let out_size = shape_elem_count(t.view.shape) * dtype_size(t.view.dtype)
    let out_stor = storage_new(device(t), out_size)
    let out_view = crux_view_contiguous(out_stor.memory, t.view.shape, t.view.dtype)

    let key = elementwise_key(op, t.view.dtype)
    let prog = registry_get_or_compile(ctx.programs, key, op, t.view.dtype)
    crux_dispatch(ctx.stream, prog,
                  bindings_from([bind("x", t.view), bind("out", out_view)]))

    var out = Tensor { storage: out_stor, view: out_view, grad_meta: null }
    if grad_enabled(ctx) and has_grad(t):
        let saved = make_saved(t)
        attach_grad_node(&out, backward_id,
                         [t.grad_meta], [t.view.shape],
                         saved, ctx.current_layer)
    out

fn relu(ctx: &Context, t: &Tensor) -> Tensor:
    let out = unary_elementwise(ctx, t, OP_RELU, BACKWARD_RELU,
                                fn(t: &Tensor): SavedState.empty())
    // ReluBackward actually needs the OUTPUT, so we fix up saved:
    // (implementation detail — save output after creation)
    out

fn exp(ctx: &Context, t: &Tensor) -> Tensor:
    unary_elementwise(ctx, t, OP_EXP, BACKWARD_EXP,
                      fn(t: &Tensor): SavedState.empty())
```

### Scalar ops (spec constant path)

```
fn add_scalar(ctx: &Context, t: &Tensor, s: f64) -> Tensor:
    let out_size = shape_elem_count(t.view.shape) * dtype_size(t.view.dtype)
    let out_stor = storage_new(device(t), out_size)
    let out_view = crux_view_contiguous(out_stor.memory, t.view.shape, t.view.dtype)

    let key = scalar_key(OP_ADD, t.view.dtype)
    let prog = registry_get_or_compile_scalar(ctx.programs, key, OP_ADD, t.view.dtype, s)
    crux_dispatch(ctx.stream, prog,
                  bindings_from([bind("x", t.view), bind("out", out_view)]))

    Tensor { storage: out_stor, view: out_view, grad_meta: null }
```

Scalar is a Crux spec constant. In registers, not memory.

---

## Session 16: Matmul + View Ops

### Matmul

```
fn matmul(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor:
    assert device(a) == device(b)
    assert a.view.dtype == b.view.dtype

    let M = shape_get(a.view.shape, a.view.shape.rank - 2)
    let K = shape_get(a.view.shape, a.view.shape.rank - 1)
    let N = shape_get(b.view.shape, b.view.shape.rank - 1)
    assert K == shape_get(b.view.shape, b.view.shape.rank - 2)

    let out_shape = matmul_output_shape(a.view.shape, b.view.shape)
    let out_stor = storage_new(device(a),
                               shape_elem_count(out_shape) * dtype_size(a.view.dtype))
    let out_view = crux_view_contiguous(out_stor.memory, out_shape, a.view.dtype)

    let TILE = if M >= 32 and N >= 32 and K >= 32: 16 else: 0
    let key = matmul_key(a.view.dtype, TILE)
    let prog = registry_get_or_compile(ctx.programs, key, ...)
    let grid = compute_matmul_grid(M, N, TILE)
    crux_dispatch_grid(ctx.stream, prog,
                       bindings_from([bind("a", a.view), bind("b", b.view),
                                     bind("out", out_view)]),
                       grid)

    var out = Tensor { storage: out_stor, view: out_view, grad_meta: null }
    if grad_enabled(ctx) and (has_grad(a) or has_grad(b)):
        // save_tensor borrows a and b — retains storage, doesn't consume
        let saved = SavedState {
            tensors: [save_tensor(a), save_tensor(b)],
            shapes: [], scalars: [],
        }
        attach_grad_node(&out, BACKWARD_MATMUL,
                         [a.grad_meta, b.grad_meta],
                         [a.view.shape, b.view.shape],
                         saved, ctx.current_layer)
    out
```

### linear (fused)

```
fn linear(ctx: &Context, input: &Tensor, weight: &Tensor, bias: &Tensor) -> Tensor:
    // Fused matmul + bias — one Crux dispatch
    // input: [*, in_features]
    // weight: [out_features, in_features]
    // bias: [out_features] (nullable — check storage != null)
    ...
```

---

## Session 18: Autograd

### SavedTensor and SavedState

```
type SavedTensor = {
    storage: *mut Storage,
    view: View,
}

fn save_tensor(t: &Tensor) -> SavedTensor:
    // Borrows t — reads storage pointer and view
    // Retains storage — keeps memory alive for backward
    storage_retain(t.storage)
    SavedTensor { storage: t.storage, view: t.view }

fn release_saved(s: &SavedTensor):
    storage_release(s.storage)
```

**Key point:** `save_tensor` takes `&Tensor`. It borrows the
tensor to read its storage and view. It does NOT consume the
tensor. The caller keeps ownership. The saved state shares
storage via refcount.

### GradNode

```
type GradNode = {
    backward_fn: i32,
    input_metas: Vec[*mut GradMeta],
    input_shapes: Vec[Shape],
    saved: SavedState,
    output_meta: *mut GradMeta,
    refcount: i32,
    layer_idx: i32,
}
```

### attach_grad_node

```
fn attach_grad_node(out: &mut Tensor, backward_fn: i32,
                     input_metas: Vec[*mut GradMeta],
                     input_shapes: Vec[Shape],
                     saved: SavedState, layer_idx: i32):
    debug_assert(input_metas.len() == input_shapes.len())
    debug_assert(backward_fn > 0 and backward_fn < BACKWARD_MAX)

    let node = alloc_grad_node()
    node.backward_fn = backward_fn
    node.input_metas = input_metas
    node.input_shapes = input_shapes
    node.saved = saved
    node.refcount = 1
    node.layer_idx = layer_idx

    out.grad_meta = alloc_grad_meta(requires_grad: true, is_leaf: false)
    out.grad_meta.grad_fn = node
    node.output_meta = out.grad_meta
```

Note: `out` is `&mut Tensor` — we borrow it mutably to set its
grad_meta. The caller still owns the tensor.

### backward

```
fn backward(ctx: &Context, loss: &Tensor):
    backward_ex(ctx, loss, false)

fn backward_retain(ctx: &Context, loss: &Tensor):
    backward_ex(ctx, loss, true)

fn backward_ex(ctx: &Context, loss: &Tensor, retain_graph: bool):
    assert numel(loss) == 1
    let meta = loss.grad_meta
    assert meta != null

    // Seed gradient — creates an owned Tensor
    meta.grad = box_tensor(ones(shape(loss), dtype(loss), device(loss)))

    let order = topo_sort(meta.grad_fn)

    var i = order.len() as i32 - 1
    while i >= 0:
        let node = order.get(i as usize) as *mut GradNode
        let grad_out = unbox_tensor(node.output_meta.grad)

        // Apply backward — borrows grad_out and saved state
        let grads = apply_backward(node.backward_fn, grad_out, &node.saved, ctx)

        for j in 0..node.input_metas.len():
            let in_meta = node.input_metas.get(j)
            if in_meta == null or in_meta.requires_grad == 0: continue

            var g = grads.get(j)
            let orig_shape = node.input_shapes.get(j)
            if shape_ne(shape(&g), orig_shape):
                g = unbroadcast(ctx, g, orig_shape)

            if in_meta.grad == null:
                in_meta.grad = box_tensor(g)
            else:
                let existing = unbox_tensor(in_meta.grad)
                in_meta.grad = box_tensor(add(ctx, existing, g))
                // old existing is dropped — refcount decremented
        i = i - 1

    if not retain_graph:
        free_graph(order)
```

**Note:** `loss` is `&Tensor` — borrowed. The loss tensor survives
backward. Only the graph is freed.

**Note:** `add(ctx, existing, g)` — both are `&Tensor` via auto-ref.
Neither is consumed. The result is a new owned Tensor that replaces
the old gradient.

### backward_with_hooks (FSDP)

```
fn backward_with_hooks(ctx: &Context, loss: &Tensor,
                        hooks: BackwardHook, retain_graph: bool):
    // Same as backward_ex but calls hooks at layer boundaries
    // Layer boundaries detected from GradNode.layer_idx
    // ctx.current_layer was set during forward
```

### free_graph

```
fn free_graph(order: Vec[*mut GradNode]):
    for node in order:
        for st in node.saved.tensors:
            release_saved(&st)     // decrement saved storage refcount
        node.refcount = node.refcount - 1
        if node.refcount == 0:
            free(node as *mut c_void)
```

### Backward functions

All backward functions take `&Tensor` for grad_out and read
saved state by reference:

```
fn backward_add(grad_out: &Tensor, saved: &SavedState, ctx: &Context) -> Vec[Tensor]:
    [clone(grad_out), clone(grad_out)]

fn backward_mul(grad_out: &Tensor, saved: &SavedState, ctx: &Context) -> Vec[Tensor]:
    // saved.tensors[0] = a, saved.tensors[1] = b
    let a_view = saved.tensors[0].view
    let b_view = saved.tensors[1].view
    let a_ref = tensor_from_saved(&saved.tensors[0])  // temporary borrow
    let b_ref = tensor_from_saved(&saved.tensors[1])
    [mul(ctx, grad_out, b_ref), mul(ctx, grad_out, a_ref)]
    // a_ref, b_ref are lightweight views — dropped here

fn backward_matmul(grad_out: &Tensor, saved: &SavedState, ctx: &Context) -> Vec[Tensor]:
    let a_ref = tensor_from_saved(&saved.tensors[0])
    let b_ref = tensor_from_saved(&saved.tensors[1])
    let grad_a = matmul(ctx, grad_out, transpose(b_ref, -2, -1))
    let grad_b = matmul(ctx, transpose(a_ref, -2, -1), grad_out)
    [grad_a, grad_b]

fn backward_softmax(grad_out: &Tensor, saved: &SavedState, ctx: &Context) -> Vec[Tensor]:
    let y_ref = tensor_from_saved(&saved.tensors[0])  // softmax output
    let dy_y = mul(ctx, grad_out, y_ref)
    let s = sum(ctx, dy_y, -1)
    let s_exp = unsqueeze(s, -1)
    [mul(ctx, y_ref, sub(ctx, grad_out, expand(s_exp, shape(y_ref))))]

fn backward_cross_entropy(grad_out: &Tensor, saved: &SavedState, ctx: &Context) -> Vec[Tensor]:
    let sm_ref = tensor_from_saved(&saved.tensors[0])
    let tgt_ref = tensor_from_saved(&saved.tensors[1])
    [mul(ctx, sub(ctx, sm_ref, tgt_ref), grad_out)]
```

**`tensor_from_saved` helper:** Creates a temporary Tensor from a
SavedTensor for use in backward ops. Does NOT retain storage
(the SavedTensor already holds the retain). The temporary is only
valid within the backward function scope.

```
fn tensor_from_saved(st: &SavedTensor) -> Tensor:
    // Lightweight: shares storage but does NOT retain
    // Only valid while the SavedTensor is alive
    Tensor { storage: st.storage, view: st.view, grad_meta: null }
    // WARNING: this Tensor must NOT be dropped via Drop
    // (it would double-release storage)
    // Solution: mark as non-owning, or use a separate type
```

**Implementation note:** `tensor_from_saved` is tricky because the
returned Tensor would trigger Drop on scope exit, decrementing
refcount that it doesn't own. Two solutions:

**Option A:** Use a separate `TensorView` type that doesn't implement Drop:
```
type TensorView = {
    storage: *mut Storage,  // borrowed, NOT refcounted
    view: View,
}
// No Drop impl — goes out of scope silently
```

Then backward functions use `TensorView` for saved state access,
and ops accept both `&Tensor` and `&TensorView`.

**Option B:** Use raw View + storage pointer in backward functions,
bypass Tensor entirely:
```
fn backward_mul(grad_out: &Tensor, saved: &SavedState, ctx: &Context) -> Vec[Tensor]:
    let a_view = saved.tensors[0].view
    let b_view = saved.tensors[1].view
    // Call Crux directly with views, skip Tensor wrapper
```

**Recommendation:** Option A is cleaner. `TensorView` is the
non-owning view type used only inside backward functions.

### Numerical gradient verification

```
fn check_grad(ctx: &Context, f: fn(&Context, &Tensor) -> Tensor,
               x: &Tensor, eps: f64, atol: f64, rtol: f64):
    enable_grad(ctx)
    defer: restore_grad(ctx)

    var x_param = clone(x)
    x_param.grad_meta = alloc_grad_meta(true, true)

    let y = f(ctx, x_param)
    let loss = sum_all(ctx, y)
    backward(ctx, loss)

    let analytical = get_grad_tensor(x_param.grad_meta)
    let numerical = numerical_gradient(ctx, f, x, eps)
    assert_allclose(analytical, numerical, atol, rtol)
```

Run for EVERY backward function. Tolerances:
- Float32: atol=1e-3, rtol=1e-3, eps=1e-4
- Float64: atol=1e-6, rtol=1e-5, eps=1e-6

---

## Sessions 28-32: Distributed

### FSDP layer tracking

```
fn fsdp_forward(fsdp: &FSDP, rank: i32, input: &Tensor) -> Tensor:
    let ctx = &fsdp.world.contexts[rank]
    var h = clone(input)   // own a copy on this device
    for layer_idx in 0..fsdp.num_layers:
        ctx.current_layer = layer_idx
        let full = fsdp_gather_layer(fsdp, layer_idx, rank)
        let block = build_temp_block(full, fsdp.module_config)
        h = block.forward(ctx, h)
        // old h dropped (reassignment), full dropped (scope exit)
        // memory freed automatically via Drop
    ctx.current_layer = -1
    h  // moved to caller
```

Drop makes FSDP's gather-compute-release pattern automatic. The
gathered full parameters are dropped when `full` goes out of scope
at the end of each loop iteration. No manual `fsdp_release_layer`.

---

## Performance Targets

| Session | Metric | Target |
|---|---|---|
| 15 | Elementwise add 1M f32 | >80% bandwidth |
| 16 | Matmul [4096,4096] | >50% of MPS |
| 17 | Softmax [64,4096] | <1ms |
| 22 | GPT-2 124M forward | <50ms |
| 25 | GPT-2 tok/s | within 2x llama.cpp |
| 28 | DP gradient sync 4 GPU | <10ms overhead |
| 30 | FSDP 7B 4 GPU | <32GB/GPU peak |

---

## Key Gotchas

### 1. tensor_from_saved needs a non-owning type
Creating a Tensor from SavedTensor is tricky — Drop would double-
release storage. Use `TensorView` (non-owning) or raw views.

### 2. Saved tensors are read-only
SavedTensors share Storage. Backward must never modify them.

### 3. Softmax backward saves output, not input
`dX = Y * (dY - sum(dY * Y))` where Y is softmax output.

### 4. Cross-entropy backward is fused
`dlogits = softmax(logits) - one_hot(targets)`.

### 5. matmul batch unbroadcast
`matmul([B,M,K], [K,N])` → grad_b requires `sum(dim=0)`.

### 6. Reassignment drops the old value
`var h = ...; h = new_value` — the old `h` is dropped (refcount
decremented). This is correct and desirable for the transformer
loop `h = block.forward(ctx, h)` — each iteration frees the
previous activation.

### 7. Expression temporaries are dropped at statement end
`let c = relu(ctx, add(ctx, a, b))` — the intermediate from
`add` is dropped after `relu` returns. Its storage is freed if
refcount reaches 0. This is correct — the intermediate is not
needed after relu has read it.

### 8. Metal has no NCCL
Distributed starts on CUDA.

---

## Dependencies on With Language Features

| Feature | Session | Priority | Notes |
|---|---|---|---|
| **`@[drop]` / RAII** | **14** | **CRITICAL** | The ownership model depends on this |
| **Auto-referencing** | **14** | **CRITICAL** | Makes `&` invisible at call sites |
| **Move semantics** | **14** | **CRITICAL** | Prevents double-free |
| Fixed-size arrays | 14 | High | Shape/Strides |
| `defer` | 14 | High | For restore_grad |
| `?` operator | 14 | High | Error propagation |
| `for` with usize | 14 | High | Iteration |
| String interpolation | 15 | Medium | Code generation |
| Trait dynamic dispatch | 19 | Medium | Module/Optimizer traits |
| Closures | 15 | Medium | make_saved callbacks |
| Generic functions | 15 | Working | N/A |
| `Vec[T]`, `HashMap` | 14 | Working | N/A |
| `unsafe`, raw ptrs | 14 | Working | N/A |
| `transmute`, `sizeof` | 14 | Working | N/A |