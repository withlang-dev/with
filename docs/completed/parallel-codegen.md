# Parallel Codegen Units — Implementation Plan

Split the single LLVM module into N independent modules that can be
optimized and emitted in parallel, following Rust's codegen unit model.

## Current Architecture

```
gen_module()          →  single LLVM module (2,289 MIR bodies)
  ↓
wl_optimize()         →  single-threaded LLVM pass pipeline
  ↓
wl_emit_object()      →  single-threaded object emission
  ↓
link                  →  link single .o into binary
```

Profile data (self-compile at -O1):
- llvm.gen_module:   0.3s  (0.3%)
- llvm.optimize:    29.8s  (25%)
- llvm.emit_object: 65.5s  (55%)
- link:             22.0s  (19%)

IR generation is fast. The bottleneck is LLVM optimization + emission,
both single-threaded on one giant module.

## Target Architecture

```
gen_module()          →  single LLVM module (IR generation is fast)
  ↓
split_module(N)       →  N independent LLVM sub-modules
  ↓
[thread 1] optimize(module_0) → emit(module_0) → unit_0.o
[thread 2] optimize(module_1) → emit(module_1) → unit_1.o
...
[thread N] optimize(module_N) → emit(module_N) → unit_N.o
  ↓
link unit_0.o ... unit_N.o    →  binary
```

With 8 threads, the 95s optimize+emit phase drops to ~12-15s.

## LLVM C API Available

We have these in `/usr/local/llvm/include/llvm-c/`:

| Function | Header | Purpose |
|----------|--------|---------|
| `LLVMCloneModule(M)` | Core.h | Deep-copy an LLVM module |
| `LLVMLinkModules2(Dest, Src)` | Linker.h | Merge Src into Dest (consumes Src) |
| `LLVMModuleCreateWithNameInContext(name, ctx)` | Core.h | Create empty module |
| `LLVMGetFirstFunction` / `LLVMGetNextFunction` | Core.h | Iterate all functions |
| `LLVMDeleteFunction` | Core.h | Remove a function from a module |
| `LLVMSetLinkage` | Core.h | Set function linkage (external, internal, etc.) |
| `LLVMGetValueName2` | Core.h | Get function name |
| `LLVMRunPasses` | Transforms/PassBuilder.h | Run optimization passes |
| `LLVMTargetMachineEmitToFile` | TargetMachine.h | Emit object file |

There is no `LLVMSplitModule` in the C API (it's C++ only). We must
implement splitting manually using clone + delete.

## Splitting Strategy

### Approach: Clone-and-Prune

1. Generate the full module as today (single `gen_module()` call)
2. Collect all function names into N buckets (round-robin by index,
   or sorted largest-first for load balancing)
3. For each bucket:
   a. `LLVMCloneModule(full_module)` → sub_module
   b. For each function NOT in this bucket:
      - Delete the function body (replace with declaration)
      - Or delete entirely if not referenced by bucket functions
4. Each sub_module can now be optimized and emitted independently

### Why Clone-and-Prune

- The full module has all type definitions, global variables, extern
  declarations, and struct layouts. Cloning preserves all of these.
- Deleting unused function bodies is safe — cross-module calls become
  external declarations resolved at link time.
- This avoids the complexity of building N modules from scratch with
  correct type/global sharing.

### Alternative: Build N Modules Directly

Instead of generating one module and splitting, modify `gen_module()`
to distribute function bodies across N modules at IR generation time.
Each module shares type definitions but only generates bodies for its
assigned functions.

Pros: no wasted clone+delete work.
Cons: requires significant refactoring of Codegen state (type caches,
global declarations, vtables must be shared or duplicated).

Recommendation: start with clone-and-prune (simpler), switch to direct
distribution later if clone overhead is significant.

## Threading Strategy

### Approach: fork() per Codegen Unit

Use process-level parallelism (fork) rather than threads:
- Each child process gets a copy of the LLVM module (via fork COW)
- No shared mutable state, no locks, no LLVM thread-safety concerns
- Each child optimizes + emits to its own .o file, then exits
- Parent waits for all children, then links the .o files

This matches the existing `with_run_shell_command` pattern already in
`runtime/helpers.c` (line 169) and avoids LLVM thread-safety issues
(LLVM's C API is not fully thread-safe — separate contexts are needed
for true multi-threading).

### Alternative: pthreads with Separate Contexts

Create N `LLVMContextRef` instances (one per thread). Each thread
gets its own context + module. LLVM guarantees thread safety when
using separate contexts.

Pros: lower overhead than fork (no process creation, shared address space).
Cons: must create N independent contexts, serialize modules to bitcode
and deserialize in each context.

### Alternative: pthreads with Single Context

LLVM 16+ supports multi-threaded compilation within a single context
via `LLVMContextSetOpaquePointers` and careful module isolation.
Most risky option — LLVM thread safety bugs are common.

Recommendation: start with fork() (simplest, safest), consider
pthreads with separate contexts later for lower overhead.

## Implementation Phases

### Phase 1: LLVM Bridge Extensions

Add to `runtime/llvm_bridge.c`:

```c
// Clone a module (deep copy)
int64_t wl_clone_module(int64_t m) {
    return P2I(LLVMCloneModule(M(m)));
}

// Delete a function's body (keep as declaration)
void wl_delete_function_body(int64_t fn) {
    LLVMDeleteBody(V(fn));
}

// Get first/next function for iteration
int64_t wl_get_first_function(int64_t m) {
    return P2I(LLVMGetFirstFunction(M(m)));
}
int64_t wl_get_next_function(int64_t fn) {
    return P2I(LLVMGetNextFunction(V(fn)));
}

// Get function name
with_str wl_get_function_name(int64_t fn) {
    size_t len;
    const char *name = LLVMGetValueName2(V(fn), &len);
    return (with_str){name, (int64_t)len};
}

// Fork + exec wrapper for parallel emission
int32_t wl_fork_emit(int64_t tm, int64_t m, with_str path, int32_t opt_level) {
    pid_t pid = fork();
    if (pid == 0) {
        // Child: optimize + emit + exit
        if (opt_level > 0) wl_optimize(m, tm, opt_level);
        int rc = wl_emit_object(tm, m, path);
        _exit(rc);
    }
    return (int32_t)pid;  // Parent gets child PID
}
```

### Phase 2: Module Splitter in With

Add `src/compiler/ParallelEmit.w`:

```
extern fn wl_clone_module(m: i64) -> i64
extern fn wl_delete_function_body(f: i64)
extern fn wl_get_first_function(m: i64) -> i64
extern fn wl_get_next_function(f: i64) -> i64
extern fn wl_get_function_name(f: i64) -> str
extern fn wl_fork_emit(tm: i64, m: i64, path: str, opt: i32) -> i32
extern fn waitpid(pid: i32, status: *const i32, flags: i32) -> i32

fn parallel_emit(tm: i64, module: i64, base_path: str,
                 opt_level: i32, num_units: i32) -> Vec[str]:
    // 1. Collect all function names
    let fn_names: Vec[str] = Vec.new()
    var f = wl_get_first_function(module)
    while f != 0:
        fn_names.push(wl_get_function_name(f))
        f = wl_get_next_function(f)

    // 2. Assign functions to units (round-robin)
    let assignments: Vec[i32] = Vec.new()
    for i in 0..fn_names.len() as i32:
        assignments.push(i % num_units)

    // 3. Fork per unit: clone, prune, optimize, emit
    let obj_paths: Vec[str] = Vec.new()
    let pids: Vec[i32] = Vec.new()
    for unit in 0..num_units:
        let obj_path = f"{base_path}.{unit}.o"
        obj_paths.push(obj_path)
        let sub_module = wl_clone_module(module)
        // Delete bodies not assigned to this unit
        var sf = wl_get_first_function(sub_module)
        var fi = 0
        while sf != 0:
            let next = wl_get_next_function(sf)
            if fi < assignments.len() as i32 and assignments.get(fi as i64) != unit:
                wl_delete_function_body(sf)
            fi = fi + 1
            sf = next
        let pid = wl_fork_emit(tm, sub_module, obj_path, opt_level)
        pids.push(pid)

    // 4. Wait for all children
    for i in 0..pids.len() as i32:
        let _ = waitpid(pids.get(i as i64), 0 as *const i32, 0)

    obj_paths
```

### Phase 3: Backend Integration

Modify `src/compiler/Backend.w` `compile_to_object_backend`:

```
// Before:
cg.optimize(opt_level)
cg.emit_object_file(output_path)

// After:
if num_codegen_units > 1:
    let obj_paths = parallel_emit(
        cg.target_machine, cg.llmod, output_path,
        opt_level, num_codegen_units)
    // Link sub-objects into one .o via ld -r
    link_relocatable(obj_paths, output_path)
else:
    cg.optimize(opt_level)
    cg.emit_object_file(output_path)
```

### Phase 4: Linking Multiple Objects

Two options for combining the per-unit .o files:

**Option A: ld -r (relocatable link)**
Merge N .o files into one .o, then proceed with normal linking.
```
ld -r unit_0.o unit_1.o ... unit_N.o -o combined.o
```

**Option B: Pass all .o files to the final linker**
Skip the intermediate merge and just pass all unit .o files to the
final link step. Simpler, avoids extra ld invocation.

Recommendation: Option B (simpler, the linker handles multiple inputs).

## Configuration

```
WITH_CODEGEN_UNITS=8    # default: number of CPU cores
WITH_CODEGEN_UNITS=1    # disable parallel codegen (current behavior)
```

For `make build` at -O0, parallel codegen helps mainly with emission.
For release builds at -O1/-O2, it helps with both optimize + emit.

## Expected Impact

Self-compile at -O1 with 8 codegen units (8-core machine):

| Phase | Current | Parallel (8 units) | Speedup |
|-------|---------|---------------------|---------|
| llvm.optimize | 29.8s | ~4-5s | ~6x |
| llvm.emit_object | 65.5s | ~9-10s | ~7x |
| link | 22.0s | ~22s (unchanged) | 1x |
| **Total LLVM** | **117s** | **~36s** | **~3x** |

At -O0 (current dev build):

| Phase | Current | Parallel (8 units) | Speedup |
|-------|---------|---------------------|---------|
| llvm.emit_object | ~20s | ~3-4s | ~5-6x |
| link | ~22s | ~22s | 1x |
| **Total** | **~42s** | **~26s** | **~1.6x** |

The biggest win is for optimized builds. For -O0 dev builds, link
time dominates and parallel codegen has diminishing returns.

## Risks

- **Clone overhead**: `LLVMCloneModule` deep-copies the entire module
  N times. For a 50MB module, this is ~400MB for 8 clones. Memory
  pressure could slow things down on constrained machines.

- **fork() overhead on macOS**: macOS `fork()` is heavier than Linux
  due to mandatory signal handling and address space setup. Benchmark
  before committing to this approach.

- **Dead code in sub-modules**: Pruned functions become declarations.
  The linker resolves them. But unreferenced declarations bloat the
  .o files slightly. LLVM's GlobalDCE pass can clean these up but
  adds optimization time.

- **Debug info**: Debug info references functions across the module.
  Splitting may produce incomplete DWARF in sub-modules. Need to test
  with dsymutil and verify debugger experience.

- **Non-determinism**: Process scheduling order may affect .o file
  timestamps or linker input order. Ensure the final binary is
  deterministic regardless of which child finishes first.

## Not In Scope

- ThinLTO (requires LLVM bitcode serialization + global index — add
  later when optimized builds need cross-unit inlining)
- Incremental compilation (requires a build cache + dependency tracking
  — separate project)
- Pipeline parallelism (running sema concurrently with codegen —
  requires async-safe data structures)
