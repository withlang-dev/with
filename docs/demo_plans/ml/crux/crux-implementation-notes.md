# Crux — Implementation Notes

**Companion to:** crux-design.md
**Audience:** The agent implementing this system in With.
**Purpose:** Practical details, API mappings, gotchas, and
session-by-session guidance.

---

## Naming

The compute substrate is called **Crux**. The ML library built on
top is called **Weld**. All substrate types, files, and APIs use
the `crux_` prefix for C bridge functions and `Crux` prefix for
With types where disambiguation is needed.

```
lib/crux/              # substrate library root
lib/weld/              # ML library root (future)
crux_metal_bridge.c    # C bridge file naming
CruxDevice             # With type naming (when needed)
```

```
use crux          // substrate: memory, programs, streams, devices
use weld          // ML library: tensors, autograd, nn modules
use weld.serve    // inference engine: batching, KV cache, API
```

The core Crux types (Device, Memory, View, Program, Stream, Event)
do NOT get a Crux prefix in With code — they are the primary
vocabulary of the library and should be unadorned:

```
let device = default_device()
let mem = alloc(device, 1024)?
let view = view_contiguous(mem, shape(256), Float32)
```

---

## Foundational Rules (decided, not negotiable)

These rules were established during design review. They prevent
drift and ambiguity. Violating any of them is a bug.

### Rule 1: All handles are pointers cast to i64

No Vec indices. No mixed representations. Every opaque handle
(Device, Memory, Program, Stream, Event, Arena) is a heap-allocated
object whose pointer is cast to `i64`.

```
// CPU: malloc → pointer → i64
let mem_ptr = unsafe: malloc(size) as *mut u8
let handle = mem_ptr as i64

// Metal: ObjC bridge → C struct pointer → i64
int64_t handle = (int64_t)(intptr_t)ctx;

// Arena sub-alloc: struct { buffer_ptr, offset } → pointer → i64
typedef struct { int64_t buffer; int64_t offset; int64_t size; } SubAlloc;
SubAlloc* sub = malloc(sizeof(SubAlloc));
return (int64_t)(intptr_t)sub;
```

No exceptions. This makes every handle dereferenceable, freeable,
and debuggable via a single convention.

### Rule 2: Strides are in bytes

All strides throughout the entire system are byte strides.
No element strides anywhere in the substrate layer.

Element strides are computed at the backend boundary when setting
up shader arguments. This computation happens exactly once per
dispatch, inside the backend.

```
// Byte stride (stored in View):
byte_offset = v.offset + sum(indices[i] * strides[i])

// Element stride (computed at dispatch for shader):
elem_stride[i] = byte_stride[i] / dtype_size(dtype)
```

### Rule 3: View.offset arithmetic never multiplies by dtype_size

Since strides are bytes, all offset computation is pure:

```
// view_slice:
new_offset = v.offset + start * v.strides[dim]
// NO dtype_size multiplication

// view_offset_of:
byte_offset = v.offset + sum(indices[i] * strides[i])
// NO dtype_size multiplication
```

This was a caught bug from the review. The original implementation
notes had `start * strides[dim] * dtype_size(dtype)` which is WRONG
when strides are already in bytes.

### Rule 4: Param references are negative, value references are non-negative

In the IR instruction encoding:

```
d0, d1, d2, d3 values:
  >= 0  →  instruction index (value produced by that instruction)
  < 0   →  parameter index (-1 = param 0, -2 = param 1, etc.)
```

This is unambiguous and requires no side-channel to distinguish
params from values. Every codegen path checks the sign.

### Rule 5: Grid validation happens at the API layer, before backend

`dispatch_grid` validates grid dimensions against `device_info.max_grid_dims`
BEFORE calling the backend. The backend may also validate (defense
in depth) but the API layer is the authoritative check. This ensures
consistent error behavior across all backends.

### Rule 6: Shared memory is validated at compile time

When compiling IR to a backend, the compiler sums all `local`
declarations and checks against `device_info.max_shared_memory`.
Exceeding the limit produces `CompileError`, not a runtime failure.

```
fn validate_shared_memory(prog: IRProgram, device_info: DeviceInfo) -> Result[void, SubstrateError]:
    var total_shared: usize = 0
    for inst in prog.insts:
        if inst.op == IROp.Local:
            total_shared += compute_local_size(inst, prog.aux)
    if total_shared > device_info.max_shared_memory:
        return Err(CompileError("shared memory exceeds device limit: "
            ++ total_shared ++ " > " ++ device_info.max_shared_memory))
    Ok(())
```

### Rule 7: Compilation cache key includes backend version

```
cache_key = hash(
    device_id,
    ir_bytes,
    spec_constant_values,
    backend_version_string,    // e.g., "metal-1.0" or "cuda-12.4"
)
```

This prevents stale pipelines after driver or backend updates.

### Rule 8: Collectives are stream-level operations

The primary collective API is at the stream level (`allreduce_sum`,
`allgather`, etc.), not inside IR programs. The backend decides the
mechanism:

- Multi-GPU: invokes NCCL/RCCL directly
- TPU: may compile an IR program containing IR-level collective ops
- Single device: no-op or local copy

IR-level collective ops (`CollectiveAllReduceSum`, etc.) exist for
backends that need intra-kernel collectives (TPU, Tenstorrent).
Programs using IR-level collectives are backend-aware — they're the
escape hatch, not the default.

### Rule 9: Placement is about bytes, not dimensions

`MemoryPlacement.Partitioned(N)` means "split this allocation across
N regions." Crux doesn't know which tensor dimension maps to which
partition. That's Weld's concern.

```
// Weld decides: shard dim 0 of a [4096, 4096] tensor across 8 regions
// Weld calls: alloc_placed(device, 4096 * 4096 * 4 / 8, Partitioned(8))
// Crux sees: 8 regions, each with 8MB. That's all.
```

### Rule 10: Single-device programs work everywhere unchanged

A program that uses only `parallel`, `parallel[grid]`,
`parallel[workgroup]`, and `parallel[subgroup]` — without
`parallel[mesh]` or IR-level collectives — runs identically on
a single GPU, a TPU pod, or a multi-GPU node. The backend maps
execution to available resources.

Programs that use `parallel[mesh]` or IR-level collectives are
explicitly distributed and require a composite device.

---

## File Structure

```
lib/crux/
├── core.w                  # Shape, Strides, View, DType, Scalar, Bindings
├── error.w                 # CruxError enum
├── device.w                # Device API (dispatches to backend)
├── memory.w                # alloc, free, free_after, Arena, MemoryPlacement
├── view.w                  # View constructors and operations
├── program.w               # compile, ProgramSource, ProgramSig
├── stream.w                # Stream, Event, dispatch
├── collective.w            # allreduce, allgather, broadcast, reduce_scatter
├── ir.w                    # IROp, IRInst, IR builder, IR validation
├── ir_text.w               # Text parser (debug/testing only)
├── backend/
│   ├── backend.w           # Backend trait / vtable definition
│   ├── cpu.w               # CPU backend
│   ├── cpu_compiler.w      # IR → C emission + dlopen
│   ├── cpu_interp.w        # IR interpreter (correctness reference)
│   ├── metal.w             # Metal backend
│   └── metal_compiler.w    # IR → MSL emission
├── runtime/
│   └── crux_metal_bridge.m # Objective-C Metal bridge
├── test/
│   ├── test_view.w         # View arithmetic tests
│   ├── test_cpu.w          # CPU backend tests
│   ├── test_metal.w        # Metal backend tests
│   ├── test_ir.w           # IR parsing/validation tests
│   ├── test_elementwise.w  # Elementwise kernel tests
│   ├── test_matmul.w       # Matmul correctness tests
│   ├── test_softmax.w      # Softmax correctness tests
│   ├── test_collective.w   # Collective operation tests
│   └── bench/
│       ├── bench_elementwise.w
│       ├── bench_matmul.w
│       └── bench_softmax.w
└── kernels/
    ├── elementwise.ir      # Text IR for elementwise ops
    ├── matmul.ir           # Text IR for matrix multiply
    ├── softmax.ir          # Text IR for fused softmax
    └── attention.ir        # Text IR for flash attention
```

---

## Session 1: Type Definitions

### Shape and Strides

With does not have fixed-size arrays. Use a struct with 8 named
fields:

```
type Shape = {
    d0: usize, d1: usize, d2: usize, d3: usize,
    d4: usize, d5: usize, d6: usize, d7: usize,
    rank: i32,
}

fn shape_get(s: Shape, i: i32) -> usize:
    if i == 0: return s.d0
    if i == 1: return s.d1
    if i == 2: return s.d2
    if i == 3: return s.d3
    if i == 4: return s.d4
    if i == 5: return s.d5
    if i == 6: return s.d6
    if i == 7: return s.d7
    0

fn shape_set(s: Shape, i: i32, v: usize) -> Shape:
    var out = s
    if i == 0: out = Shape { d0: v, d1: s.d1, d2: s.d2, d3: s.d3, d4: s.d4, d5: s.d5, d6: s.d6, d7: s.d7, rank: s.rank }
    else if i == 1: out = Shape { d0: s.d0, d1: v, d2: s.d2, d3: s.d3, d4: s.d4, d5: s.d5, d6: s.d6, d7: s.d7, rank: s.rank }
    // ... etc for all 8
    out
```

This is ugly but encapsulated. Every access goes through `shape_get`
and `shape_set`, so the representation can be swapped to real
fixed-size arrays when With supports them.

**Convenience constructors:**

```
fn shape1(d0: usize) -> Shape:
    Shape { d0, d1: 0, d2: 0, d3: 0, d4: 0, d5: 0, d6: 0, d7: 0, rank: 1 }

fn shape2(d0: usize, d1: usize) -> Shape:
    Shape { d0, d1, d2: 0, d3: 0, d4: 0, d5: 0, d6: 0, d7: 0, rank: 2 }

fn shape3(d0: usize, d1: usize, d2: usize) -> Shape:
    Shape { d0, d1, d2, d3: 0, d4: 0, d5: 0, d6: 0, d7: 0, rank: 3 }

fn shape4(d0: usize, d1: usize, d2: usize, d3: usize) -> Shape:
    Shape { d0, d1, d2, d3, d4: 0, d5: 0, d6: 0, d7: 0, rank: 4 }
```

Same pattern for `Strides` with `isize` fields.

### Strides — the math

```
fn contiguous_strides(shape: Shape, dtype: DType) -> Strides:
    let esize = dtype_size(dtype) as isize
    var st = strides_zero()
    if shape.rank == 0:
        return st
    // Last dimension stride = element size in bytes
    st = strides_set(st, shape.rank - 1, esize)
    var i = shape.rank - 2
    while i >= 0:
        let next = strides_get(st, i + 1) * shape_get(shape, i + 1) as isize
        st = strides_set(st, i, next)
        i = i - 1
    st.rank = shape.rank
    st
```

Example: `shape(3, 4, 5)` with Float32 (4 bytes):
```
strides = [80, 20, 4]
// dim 2: 4 bytes (one f32)
// dim 1: 5 * 4 = 20 bytes (one row)
// dim 0: 4 * 20 = 80 bytes (one matrix)
```

### DType

```
let DTYPE_INT8: i32 = 0
let DTYPE_INT16: i32 = 1
let DTYPE_INT32: i32 = 2
let DTYPE_INT64: i32 = 3
let DTYPE_UINT8: i32 = 4
let DTYPE_UINT16: i32 = 5
let DTYPE_UINT32: i32 = 6
let DTYPE_UINT64: i32 = 7
let DTYPE_FLOAT16: i32 = 8
let DTYPE_FLOAT32: i32 = 9
let DTYPE_FLOAT64: i32 = 10
let DTYPE_BFLOAT16: i32 = 11

fn dtype_size(d: i32) -> usize:
    if d == DTYPE_INT8 or d == DTYPE_UINT8: return 1
    if d == DTYPE_INT16 or d == DTYPE_UINT16 or d == DTYPE_FLOAT16 or d == DTYPE_BFLOAT16: return 2
    if d == DTYPE_INT32 or d == DTYPE_UINT32 or d == DTYPE_FLOAT32: return 4
    if d == DTYPE_INT64 or d == DTYPE_UINT64 or d == DTYPE_FLOAT64: return 8
    4
```

Use integer constants if With's enum dispatch is too slow or
awkward. Can be migrated to a real enum later.

### Scalar

If union types work:
```
@[repr(C)]
type Scalar = union {
    i8_val: i8,
    i16_val: i16,
    i32_val: i32,
    i64_val: i64,
    f32_val: f32,
    f64_val: f64,
    bits: u64,
}
```

If union types cause issues, fall back to:
```
type Scalar = {
    bits: u64,
    dtype: i32,
}
```

### MemoryPlacement

```
let PLACEMENT_LOCAL: i32 = 0
let PLACEMENT_REPLICATED: i32 = 1
let PLACEMENT_PARTITIONED: i32 = 2

type MemoryPlacement = {
    kind: i32,
    regions: usize,    // only meaningful for PARTITIONED
}

fn placement_local() -> MemoryPlacement:
    MemoryPlacement { kind: PLACEMENT_LOCAL, regions: 1 }

fn placement_replicated() -> MemoryPlacement:
    MemoryPlacement { kind: PLACEMENT_REPLICATED, regions: 0 }

fn placement_partitioned(n: usize) -> MemoryPlacement:
    MemoryPlacement { kind: PLACEMENT_PARTITIONED, regions: n }
```

On a single-region device, all placements behave identically.
`alloc` without placement defaults to `Local`.

### DeviceInfo topology fields

```
// Single GPU / CPU:
//   region_count = 1, topology_rank = 0, topology_dims = [1, 1, 1]
//
// Multi-GPU (4x A100):
//   region_count = 4, topology_rank = 1, topology_dims = [4, 1, 1]
//
// TPU v4 pod (8x8 mesh):
//   region_count = 64, topology_rank = 2, topology_dims = [8, 8, 1]
//
// Tenstorrent Wormhole (8x8 grid):
//   region_count = 64, topology_rank = 2, topology_dims = [8, 8, 1]
```

The topology describes the physical mesh shape. The IR's
`parallel[mesh]` iterates over regions. The backend maps mesh
iterations to physical regions using the topology.

### View

```
type View = {
    memory: i64,        // opaque handle (pointer cast to i64, Rule 1)
    offset: usize,      // byte offset from start of memory
    shape: Shape,
    strides: Strides,
    dtype: i32,         // DType as integer
}
```

### View operations

All offset math follows Rule 2 (byte strides) and Rule 3 (no dtype
multiplication in offset arithmetic):

```
fn view_contiguous(mem: i64, shape: Shape, dtype: i32) -> View:
    View {
        memory: mem,
        offset: 0,
        shape,
        strides: contiguous_strides(shape, dtype),
        dtype,
    }

fn view_slice(v: View, dim: i32, start: usize, end: usize) -> View:
    var out = v
    out.offset = v.offset + start * strides_get(v.strides, dim) as usize
    out.shape = shape_set(v.shape, dim, end - start)
    // strides unchanged
    out

fn view_transpose(v: View, dim0: i32, dim1: i32) -> View:
    var out = v
    let s0 = strides_get(v.strides, dim0)
    let s1 = strides_get(v.strides, dim1)
    out.strides = strides_set(strides_set(v.strides, dim0, s1), dim1, s0)
    let d0 = shape_get(v.shape, dim0)
    let d1 = shape_get(v.shape, dim1)
    out.shape = shape_set(shape_set(v.shape, dim0, d1), dim1, d0)
    out

fn view_broadcast(v: View, target: Shape) -> Result[View, i32]:
    var out = v
    for i in 0..target.rank:
        let vd = shape_get(v.shape, i)
        let td = shape_get(target, i)
        if vd == 1 and td > 1:
            out.strides = strides_set(out.strides, i, 0)
            out.shape = shape_set(out.shape, i, td)
        else if vd != td:
            return Err(1)  // incompatible
    Ok(out)

fn view_is_contiguous(v: View) -> bool:
    v.strides.is_contiguous(v.shape, v.dtype)

fn view_is_broadcasted(v: View) -> bool:
    for i in 0..v.shape.rank:
        if strides_get(v.strides, i) == 0 and shape_get(v.shape, i) > 1:
            return true
    false

fn view_elem_count(v: View) -> usize:
    v.shape.elem_count()

fn view_byte_size(v: View) -> usize:
    v.shape.elem_count() * dtype_size(v.dtype)

fn view_offset_of(v: View, indices: Shape) -> usize:
    var off = v.offset
    for i in 0..v.shape.rank:
        off = off + shape_get(indices, i) * strides_get(v.strides, i) as usize
    off
```

### Unit tests for session 1

```
test "shape elem_count":
    assert shape2(3, 4).elem_count() == 12
    assert shape3(2, 3, 4).elem_count() == 24
    assert shape1(0).elem_count() == 0

test "contiguous strides f32":
    let st = contiguous_strides(shape3(3, 4, 5), DTYPE_FLOAT32)
    assert strides_get(st, 0) == 80    // 4*5*4
    assert strides_get(st, 1) == 20    // 5*4
    assert strides_get(st, 2) == 4     // 4

test "contiguous strides f64":
    let st = contiguous_strides(shape2(3, 4), DTYPE_FLOAT64)
    assert strides_get(st, 0) == 32    // 4*8
    assert strides_get(st, 1) == 8     // 8

test "view_slice offset":
    let v = view_contiguous(0, shape2(10, 20), DTYPE_FLOAT32)
    let sliced = view_slice(v, 0, 2, 5)
    assert sliced.offset == 2 * 80     // 2 * stride[0]
    assert shape_get(sliced.shape, 0) == 3
    assert shape_get(sliced.shape, 1) == 20

test "view_transpose swaps":
    let v = view_contiguous(0, shape2(3, 4), DTYPE_FLOAT32)
    let vt = view_transpose(v, 0, 1)
    assert shape_get(vt.shape, 0) == 4
    assert shape_get(vt.shape, 1) == 3
    assert strides_get(vt.strides, 0) == 4     // was stride[1]
    assert strides_get(vt.strides, 1) == 16    // was stride[0]

test "view_broadcast sets stride 0":
    let v = view_contiguous(0, shape2(1, 4), DTYPE_FLOAT32)
    let vb = view_broadcast(v, shape2(3, 4)).unwrap()
    assert shape_get(vb.shape, 0) == 3
    assert strides_get(vb.strides, 0) == 0
    assert view_is_broadcasted(vb) == true

test "view_offset_of":
    let v = view_contiguous(0, shape2(3, 4), DTYPE_FLOAT32)
    // element [1, 2] = offset + 1*16 + 2*4 = 24
    assert view_offset_of(v, shape2(1, 2)) == 24
```

---

## Session 2: CPU Backend

### Handle convention (Rule 1)

All handles are pointers cast to i64:

```
type CPUMemory = {
    ptr: *mut u8,
    size: usize,
}

fn cpu_alloc(size: usize) -> i64:
    let raw = unsafe: malloc(sizeof[CPUMemory]()) as *mut CPUMemory
    let data = unsafe: malloc(size) as *mut u8
    if data == null:
        return 0  // OOM
    unsafe:
        (*raw).ptr = data
        (*raw).size = size
    raw as i64

fn cpu_free(handle: i64):
    let mem = handle as *mut CPUMemory
    unsafe:
        free((*mem).ptr as *mut c_void)
        free(mem as *mut c_void)

fn cpu_memory_ptr(handle: i64) -> *mut u8:
    let mem = handle as *mut CPUMemory
    unsafe: (*mem).ptr

fn cpu_memory_size(handle: i64) -> usize:
    let mem = handle as *mut CPUMemory
    unsafe: (*mem).size
```

No Vec registry. Pointers only.

### Stream (CPU is synchronous)

```
type CPUStream = {
    device: i64,
}

fn cpu_stream_create(device: i64) -> i64:
    let s = unsafe: malloc(sizeof[CPUStream]()) as *mut CPUStream
    unsafe: (*s).device = device
    s as i64

fn cpu_stream_sync(handle: i64):
    // No-op: CPU is synchronous
    return
```

### Event (always done on CPU)

```
type CPUEvent = {
    done: i32,
}

fn cpu_event_create() -> i64:
    let e = unsafe: malloc(sizeof[CPUEvent]()) as *mut CPUEvent
    unsafe: (*e).done = 1
    e as i64

fn cpu_event_is_done(handle: i64) -> bool:
    true  // CPU is synchronous

fn cpu_event_wait(handle: i64):
    return  // already done
```

### Binding validation

```
fn validate_bindings(sig: ProgramSig, bindings: Bindings) -> Result[i32, SubstrateError]:
    for pi in 0..sig.params.len():
        let param = sig.params.get(pi)
        var found = false
        for bi in 0..bindings.entries.len():
            let entry = bindings.entries.get(bi)
            if entry.name == param.name:
                found = true
                if entry.view.dtype != param.dtype:
                    return Err(DTypeMismatch("param " ++ param.name))
                if entry.view.shape.rank != param.rank:
                    return Err(ShapeMismatch("rank mismatch: " ++ param.name))
                if (param.mode == PARAM_OUT or param.mode == PARAM_INOUT):
                    if view_is_broadcasted(entry.view):
                        return Err(BroadcastWriteViolation)
                break
        if not found:
            return Err(ShapeMismatch("missing binding: " ++ param.name))
    Ok(0)
```

---

## Session 3: IR Definition

### IRInst layout

```
type IRInst = {
    op: i32,        // IROp
    dtype: i32,     // DType
    d0: i32,        // operand 0
    d1: i32,        // operand 1
    d2: i32,        // operand 2
    d3: i32,        // operand 3
}
// 24 bytes per instruction
```

### IRProgram

```
type IRProgram = {
    insts: Vec[IRInst],
    aux: Vec[i32],              // variable-length data (index tuples, shapes)
    param_names: Vec[i32],      // interned name symbols
    param_modes: Vec[i32],      // ParamMode
    param_ranks: Vec[i32],
    param_dtypes: Vec[i32],
    num_params: i32,
}
```

### Encoding (Rule 4: negative = param, non-negative = value)

```
// Load: op=Load, d0=param_ref (negative), d1=aux_base (index tuple start)
//   indices stored in aux[d1..d1+rank]
//   each index entry is a value ref or loop var ref

// Store: op=Store, d0=param_ref, d1=aux_base, d2=value_ref

// BinOp: op=Add/Sub/etc, d0=lhs_ref, d1=rhs_ref

// UnOp: op=Neg/Abs/etc, d0=operand_ref

// FMA: op=FMA, d0=a_ref, d1=b_ref, d2=c_ref

// Cast: op=Cast, d0=operand_ref, dtype=target_type

// Loop: op=Loop, d0=var_inst_idx, d1=start_ref, d2=end_ref, d3=body_block_id
// Parallel: same as Loop, op=ParallelGrid/ParallelWorkgroup/ParallelSubgroup
// ParallelMesh: same as Loop, op=ParallelMesh — iterates over device regions

// If: op=If, d0=cond_ref, d1=then_block, d2=else_block

// ReduceSum/Max/Min/Prod: op=ReduceSum, d0=var_inst, d1=start, d2=end, d3=body_expr_ref

// CollectiveAllReduceSum: op=CollectiveAllReduceSum, d0=value_ref
// CollectiveAllReduceMax: op=CollectiveAllReduceMax, d0=value_ref
// CollectiveAllGather: op=CollectiveAllGather, d0=value_ref
// CollectiveBroadcast: op=CollectiveBroadcast, d0=value_ref, d1=root_region
// CollectiveReduceScatter: op=CollectiveReduceScatter, d0=value_ref
// NOTE: IR-level collectives are backend-aware (Rule 8). Most users
// should use stream-level collective API instead.

// Local: op=Local, d0=name_sym, d1=aux_base (shape), d2=rank, dtype=element type

// Barrier: op=Barrier (no operands)

// BlockBegin: op=BlockBegin, d0=block_id
// BlockEnd: op=BlockEnd, d0=block_id

// Constant literal: op=Const, dtype=type, d0=low_bits, d1=high_bits
```

### Text format

One instruction per line. `%N` references value N.
Parameters are declared at top. Indentation shows block nesting.

```
param a in [M, K] f32
param b in [K, N] f32
param out out [M, N] f32

parallel_grid i 0 M
  parallel_grid j 0 N
    %0 = const f32 0.0
    loop k 0 K
      %1 = load a [i, k]
      %2 = load b [k, j]
      %3 = fma %1 %2 %0
      %0 = %3
    store out [i, j] %0
```

The text parser is <300 lines. Tokenize by whitespace, map to IROp,
build IRInst/aux arrays.

### IR validation pass

Before compilation, check:

1. **Value refs in range:** All non-negative d0/d1/d2/d3 < instruction count
2. **Param refs in range:** All negative refs: abs(ref) - 1 < num_params
3. **Block nesting:** BlockBegin/BlockEnd matched
4. **Type consistency:** Binop operands same dtype, store value matches param dtype
5. **Reduction ops valid:** Only ReduceSum/Max/Min/Prod
6. **Local inside parallel:** Local declarations only inside grid/workgroup body
7. **Barrier inside workgroup:** Barrier only inside parallel[workgroup] body
8. **Shared memory total:** Sum of local declarations ≤ device max (Rule 6)
9. **Mesh inside program top level:** parallel[mesh] only at outermost parallel nesting
10. **Collective inside mesh:** IR-level collectives only inside parallel[mesh] body
11. **Collective consistency:** All mesh regions must execute identical collective sequence (statically verifiable for simple cases, UB for dynamic divergence)

Return list of `(instruction_index, error_message)`.

---

## Session 4: IR → CPU (Interpreter First)

### Interpreter architecture

Walk the IR linearly. Maintain a value table (parallel arrays,
not Scalar structs — per review feedback):

```
type Interp = {
    values: Vec[u64],       // raw bits for each value
    dtypes: Vec[i32],       // dtype for each value
    loop_vars: Vec[i64],    // current loop variable values
    params: Vec[View],      // bound views
    param_ptrs: Vec[i64],   // memory handles
}
```

**Why parallel arrays instead of Vec[Scalar]:**
- No union overhead
- No struct copying
- Faster: no branching on dtype for storage, only for compute
- Raw bits (`u64`) hold any scalar value

### Interpreter dispatch

```
fn interp_exec(interp: Interp, prog: IRProgram):
    var ip = 0
    while ip < prog.insts.len():
        let inst = prog.insts.get(ip)
        match inst.op:
            IROP_LOAD:
                let param_idx = (0 - inst.d0) - 1
                let view = interp.params.get(param_idx)
                let ptr = interp.param_ptrs.get(param_idx)
                let indices = read_indices(interp, prog, inst.d1, view.shape.rank)
                let byte_off = compute_offset(view, indices)
                let mem_ptr = cpu_memory_ptr(ptr)
                let val = read_raw(mem_ptr, byte_off, view.dtype)
                interp.values.push(val)
                interp.dtypes.push(view.dtype)

            IROP_ADD:
                let a = interp.values.get(inst.d0)
                let b = interp.values.get(inst.d1)
                let dt = interp.dtypes.get(inst.d0)
                let result = scalar_add_raw(a, b, dt)
                interp.values.push(result)
                interp.dtypes.push(dt)

            IROP_STORE:
                let param_idx = (0 - inst.d0) - 1
                let view = interp.params.get(param_idx)
                let ptr = interp.param_ptrs.get(param_idx)
                let indices = read_indices(interp, prog, inst.d1, view.shape.rank)
                let byte_off = compute_offset(view, indices)
                let mem_ptr = cpu_memory_ptr(ptr)
                let val = interp.values.get(inst.d2)
                write_raw(mem_ptr, byte_off, val, view.dtype)

            IROP_LOOP:
                // Execute body block repeatedly
                let var_idx = inst.d0
                let start = get_i64(interp, inst.d1)
                let end = get_i64(interp, inst.d2)
                let body_block = inst.d3
                for iter in start..end:
                    set_loop_var(interp, var_idx, iter)
                    exec_block(interp, prog, body_block)
            // ... etc
        ip = ip + 1
```

### scalar_add_raw (typed arithmetic on raw bits)

```
fn scalar_add_raw(a: u64, b: u64, dtype: i32) -> u64:
    if dtype == DTYPE_FLOAT32:
        let fa = transmute[f32](a as u32)
        let fb = transmute[f32](b as u32)
        return transmute[u32](fa + fb) as u64
    if dtype == DTYPE_FLOAT64:
        let fa = transmute[f64](a)
        let fb = transmute[f64](b)
        return transmute[u64](fa + fb)
    if dtype == DTYPE_INT32:
        return ((a as i32) + (b as i32)) as u64
    if dtype == DTYPE_INT64:
        return ((a as i64) + (b as i64)) as u64
    // ... etc
    0
```

Same pattern for sub, mul, div, etc. Each is ~20 lines of dtype dispatch.

### Test: elementwise add via interpreter

```
fn test_interp_add():
    let N = 16
    let a_mem = cpu_alloc(N * 4)
    let b_mem = cpu_alloc(N * 4)
    let out_mem = cpu_alloc(N * 4)

    // Fill a with 1.0, b with 2.0
    let a_ptr = cpu_memory_ptr(a_mem)
    let b_ptr = cpu_memory_ptr(b_mem)
    for i in 0..N:
        write_f32(a_ptr, i * 4, 1.0)
        write_f32(b_ptr, i * 4, 2.0)

    let a_view = view_contiguous(a_mem, shape1(N), DTYPE_FLOAT32)
    let b_view = view_contiguous(b_mem, shape1(N), DTYPE_FLOAT32)
    let out_view = view_contiguous(out_mem, shape1(N), DTYPE_FLOAT32)

    let prog = parse_ir("
        param a in [N] f32
        param b in [N] f32
        param out out [N] f32
        parallel i 0 N
          %0 = load a [i]
          %1 = load b [i]
          %2 = add %0 %1
          store out [i] %2
    ")

    interp_dispatch(prog, [a_view, b_view, out_view])

    let out_ptr = cpu_memory_ptr(out_mem)
    for i in 0..N:
        assert read_f32(out_ptr, i * 4) == 3.0

    cpu_free(a_mem)
    cpu_free(b_mem)
    cpu_free(out_mem)
```

---

## Session 5: Metal Backend

### Objective-C bridge (crux_metal_bridge.m)

Compile with: `clang -c -x objective-c -fobjc-arc crux_metal_bridge.m -o crux_metal_bridge.o -framework Metal`

Core functions:

```c
// crux_metal_bridge.m

#import <Metal/Metal.h>

typedef struct {
    id<MTLDevice> device;
    id<MTLCommandQueue> queue;
} CruxMetalCtx;

// Device
int64_t crux_metal_create_device(void);
void crux_metal_destroy_device(int64_t ctx);
int64_t crux_metal_device_max_threadgroup_size(int64_t ctx);
int64_t crux_metal_device_max_shared_memory(int64_t ctx);

// Memory
int64_t crux_metal_alloc(int64_t ctx, int64_t size);
void crux_metal_free(int64_t buffer);
void* crux_metal_buffer_ptr(int64_t buffer);
int64_t crux_metal_buffer_size(int64_t buffer);

// Program (MSL compilation)
int64_t crux_metal_compile(int64_t ctx, const char* msl_source, const char* entry);
void crux_metal_destroy_program(int64_t pipeline);

// Stream (command buffer)
int64_t crux_metal_create_stream(int64_t ctx);
int64_t crux_metal_begin_command(int64_t stream);
void crux_metal_dispatch(int64_t cmd, int64_t pipeline,
                         int64_t* buffers, int64_t* offsets, int32_t buf_count,
                         int64_t* metadata_buf, int64_t metadata_offset,
                         uint32_t gx, uint32_t gy, uint32_t gz,
                         uint32_t tx, uint32_t ty, uint32_t tz);
int64_t crux_metal_commit(int64_t cmd);   // returns event handle
void crux_metal_wait(int64_t event);
int32_t crux_metal_event_done(int64_t event);
double crux_metal_event_elapsed(int64_t start_event, int64_t end_event);
void crux_metal_stream_sync(int64_t stream);
```

### Metal buffer binding layout (per review: use metadata struct)

Instead of one Metal buffer per stride array, pack all metadata
into a single buffer:

```c
// Metadata buffer layout:
// [param_count]
// For each param:
//   [rank, stride[0], stride[1], ..., stride[7]]
//   [shape[0], shape[1], ..., shape[7]]
// [spec_const_count]
// For each constant:
//   [value_bits_low, value_bits_high]
```

Metal buffer slots (max 31):
```
Buffer 0..N-1:  data buffers (one per param)
Buffer N:       metadata buffer (all strides, shapes, constants)
```

This scales to any number of parameters without hitting the 31-slot
limit, because metadata is packed into a single buffer.

### Memory model (Apple Silicon)

Use `MTLResourceStorageModeShared` for session 5. The CPU can
read/write buffer contents directly via `[buffer contents]`. No
staging buffers needed on unified memory.

Optimization (later): `MTLResourceStorageModePrivate` for GPU-only
intermediates (KV cache, activation buffers). Requires explicit
GPU-side copy for initialization.

### Stream model (session 5: simple)

One `MTLCommandBuffer` per dispatch. Commit immediately.
`event_wait` calls `[commandBuffer waitUntilCompleted]`.

Optimization (later): batch multiple dispatches into one command
buffer, commit on stream_sync or when buffer count reaches threshold.

---

## Session 6: IR → MSL Compiler

### MSL kernel template

```metal
#include <metal_stdlib>
using namespace metal;

struct Metadata {
    int param_count;
    // ... packed strides, shapes, constants
};

kernel void ENTRY_NAME(
    device const float* param_0 [[buffer(0)]],
    device float* param_1 [[buffer(1)]],
    // ... one per parameter
    constant Metadata& meta [[buffer(LAST)]],
    uint3 gid [[threadgroup_position_in_grid]],
    uint3 tid [[thread_position_in_threadgroup]],
    uint simd_lane [[thread_index_in_simdgroup]]
) {
    // ... generated code
}
```

### IR → MSL translation rules

```
parallel[grid] i in 0..N
    → uint i = gid.x;
      // (or gid.y, gid.z for nested grid parallels)

parallel[workgroup] j in 0..TILE
    → uint j = tid.x;

parallel[subgroup] lane in 0..SG
    → uint lane = simd_lane;

for k in 0..K
    → for (uint k = 0; k < K; k++) { ... }

load(a, [i, k])
    → param_0[i * meta.strides_0[0] + k * meta.strides_0[1]]
    // element strides computed from byte strides at dispatch

store(out, [i, j], v)
    → param_1[i * meta.strides_1[0] + j * meta.strides_1[1]] = v;

local tile: [TILE, TILE] f32
    → threadgroup float tile[TILE * TILE];

private acc: [D] f32
    → float acc[D];

barrier()
    → threadgroup_barrier(mem_flags::mem_threadgroup);

reduce[sum](i, 0..N, expr)
    → threadgroup float shared[THREADGROUP_SIZE];
      shared[tid.x] = expr;
      threadgroup_barrier(...);
      for (uint s = THREADGROUP_SIZE/2; s > 0; s >>= 1) {
          if (tid.x < s) shared[tid.x] += shared[tid.x + s];
          threadgroup_barrier(...);
      }
      float result = shared[0];

reduce[max](i, 0..N, expr)
    → same pattern with max() instead of +

fma(a, b, c)
    → fma(a, b, c)   // Metal has native fma

select(c, t, f)
    → select(f, t, c)   // Metal select has reversed arg order!
```

### Grid/threadgroup size computation

For 1D kernels (elementwise):
```
threadgroup_size = min(256, pipeline.maxTotalThreadsPerThreadgroup)
grid_size = ceil_div(N, threadgroup_size)
dispatch: grid=[grid_size, 1, 1], threadgroup=[threadgroup_size, 1, 1]
```

For 2D kernels (matmul tiled):
```
grid_x = ceil_div(M, TILE)
grid_y = ceil_div(N, TILE)
dispatch: grid=[grid_x, grid_y, 1], threadgroup=[TILE, TILE, 1]
```

### MSL string building

Build MSL as a With string via concatenation:

```
fn emit_msl(prog: IRProgram, device_info: DeviceInfo) -> str:
    var msl = "#include <metal_stdlib>\nusing namespace metal;\n\n"
    msl = msl ++ emit_metadata_struct(prog)
    msl = msl ++ emit_kernel_signature(prog)
    msl = msl ++ emit_kernel_body(prog, device_info)
    msl
```

Each `emit_*` function walks the IR and appends MSL text.
The whole compiler is ~500-800 lines.

---

## Sessions 7-8: Copy, Arena, Timing

### Cross-device copy (Apple Silicon)

On unified memory, CPU↔GPU copy is memcpy through `[buffer contents]`:

```c
void crux_metal_copy_to_device(int64_t dst_buf, int64_t dst_offset,
                                const void* src, int64_t size) {
    id<MTLBuffer> buffer = (__bridge id<MTLBuffer>)(void*)(intptr_t)dst_buf;
    memcpy((uint8_t*)[buffer contents] + dst_offset, src, (size_t)size);
    // On macOS with managed mode, would need didModifyRange here
}

void crux_metal_copy_from_device(void* dst, int64_t src_buf,
                                  int64_t src_offset, int64_t size) {
    id<MTLBuffer> buffer = (__bridge id<MTLBuffer>)(void*)(intptr_t)src_buf;
    memcpy(dst, (uint8_t*)[buffer contents] + src_offset, (size_t)size);
}
```

### Arena (Metal)

```c
typedef struct {
    id<MTLBuffer> buffer;
    int64_t size;
    int64_t used;
} CruxMetalArena;

int64_t crux_metal_arena_alloc(int64_t arena_handle, int64_t size, int64_t align) {
    CruxMetalArena* arena = (CruxMetalArena*)(intptr_t)arena_handle;
    int64_t aligned = (arena->used + align - 1) & ~(align - 1);
    if (aligned + size > arena->size) return 0;  // OOM

    // Create sub-alloc descriptor
    typedef struct { int64_t buffer; int64_t offset; int64_t size; } SubAlloc;
    SubAlloc* sub = malloc(sizeof(SubAlloc));
    sub->buffer = (int64_t)(intptr_t)arena->buffer;
    sub->offset = aligned;
    sub->size = size;
    arena->used = aligned + size;
    return (int64_t)(intptr_t)sub;
}
```

**Metal alignment:** Buffer offsets for `setBuffer:offset:atIndex:`
must be 256-byte aligned. Arena alloc uses `align=256` by default.

### Event timing

```c
double crux_metal_event_elapsed(int64_t start_handle, int64_t end_handle) {
    id<MTLCommandBuffer> start = (__bridge id<MTLCommandBuffer>)(void*)(intptr_t)start_handle;
    id<MTLCommandBuffer> end_buf = (__bridge id<MTLCommandBuffer>)(void*)(intptr_t)end_handle;
    return [end_buf GPUEndTime] - [start GPUStartTime];
}
```

### Compilation cache

```
type CompileCache = {
    keys: Vec[u64],
    values: Vec[i64],   // pipeline handles
}

fn compile_cache_key(prog: IRProgram, device_id: i64, backend_version: str) -> u64:
    var h: u64 = 14695981039346656037   // FNV offset basis
    h = fnv_hash_i64(h, device_id)
    for i in 0..prog.insts.len():
        h = fnv_hash_bytes(h, inst_as_bytes(prog.insts.get(i)), 24)
    for c in prog.spec_constants:
        h = fnv_hash_u64(h, c.value.bits)
    h = fnv_hash_str(h, backend_version)
    h
```

---

## Correctness Testing Pattern

For every kernel, the reference is the CPU interpreter. Test flow:

```
1. Create input data (known values or random)
2. Run interpreter on CPU → expected output
3. Compile for Metal
4. Dispatch on Metal → actual output
5. Copy Metal output to CPU
6. Compare element-by-element with tolerance
```

Tolerances:
```
Float32:  atol=1e-6,  rtol=1e-5
Float16:  atol=1e-3,  rtol=1e-2
BFloat16: atol=1e-2,  rtol=1e-1
Int types: exact match
```

---

## Performance Targets

| Session | Kernel | Target | Reference |
|---|---|---|---|
| 8 | Elementwise add (N=1M) | >80% mem bandwidth | ~0.12ms on M2 |
| 11 | Matmul 4096×4096 | >50% of MPS | ~38ms on M2 |
| 12 | Softmax (B=64, N=4096) | <1ms | MPS reference |
| 23 | Flash attention | within 3x of MLX | measure MLX |
| 25 | GPT-2 124M tok/s | within 2x llama.cpp | ~100 tok/s on M2 |

---

## Key Gotchas

### 1. With value semantics

Every struct assignment is a copy. Backend state MUST be opaque
handles (i64), not With structs passed by value. View is safe to
copy (it's a value type by design).

### 2. No closures/function pointers

Backend trait dispatch uses manual vtable:
```
type BackendVtable = {
    alloc_fn: i64,
    free_fn: i64,
    compile_fn: i64,
    dispatch_fn: i64,
    sync_fn: i64,
    // ...
}
```

Route through `backend_dispatch(vtable, ...)` wrappers.

### 3. Metal shader compilation errors

Always log the full MSL source on compilation failure.
`[error localizedDescription]` gives the Metal compiler error.
This is the #1 debugging scenario.

### 4. BFloat16 in Metal

Not native. Store as `uint16_t`. Convert in shader:
```metal
float bf16_to_f32(ushort bf) {
    return as_type<float>(uint(bf) << 16);
}
ushort f32_to_bf16(float f) {
    return ushort(as_type<uint>(f) >> 16);
}
```

### 5. Metal select() argument order

Metal's `select(a, b, cond)` returns `a` when cond is false,
`b` when true. This is reversed from C's `cond ? t : f`.
The IR → MSL compiler must swap arguments:
```
IR: select(cond, true_val, false_val)
MSL: select(false_val, true_val, cond)
```

### 6. Thread safety

- Programs: immutable, safe across streams and CPU threads
- Streams: NOT safe across CPU threads
- Events: safe to wait on from any thread
- Device: safe to use from any thread (Metal handles locking)
- Memory: the handle is safe to pass around; concurrent access
  to the underlying data follows the aliasing/happens-before rules

---

## Dependencies on With Language Features

| Feature | Needed by | Status | Workaround |
|---|---|---|---|
| `usize` / `isize` | Session 1 | Implemented | Use i64 |
| Opaque types | Session 1 | Implemented | N/A |
| Union types | Session 1 (Scalar) | Implemented | Use u64 + dtype tag |
| `unsafe` blocks | Session 2 | Implemented | N/A |
| Raw pointer arithmetic | Session 2 | Implemented | N/A |
| `null` literal | Session 2 | Implemented | Use 0 as i64 |
| `sizeof[T]()` | Session 2 | Implemented | N/A |
| `transmute[T]()` | Session 4 | Implemented | N/A |
| `extern var` | Session 5 | Implemented | Use extern fn getters |
| `c_import` | Session 5 | Working | Use C bridge |
| `@[repr(C)]` | Session 5 | Implemented | N/A |
| `@[packed]` | Session 5 | Implemented | N/A |
| Fixed-size arrays | Session 1 | NOT implemented | Struct with N fields |
| Trait dynamic dispatch | Session 5 | Partial | Manual vtable |
| `comptime if` | Multi-backend | NOT implemented | Runtime if |
| Generic functions | Session 9+ | Working | N/A |
| `Result` type | Session 1 | Working | N/A |
| `Option` type | Session 1 | Working | N/A |

The most impactful missing feature is fixed-size arrays. Everything
else has a workable path.