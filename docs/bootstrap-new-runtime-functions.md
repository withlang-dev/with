# Adding New C Runtime Functions — Bootstrap Checklist

When adding new C functions to the runtime that the compiler itself calls
(e.g., `with_http_get`, `with_cimport_add_include_path`), the self-hosting
bootstrap requires extra steps because the seed compiler's embedded runtime
doesn't have the new symbols.

## Procedure

1. **Add function to `runtime/*.c`** (e.g., `clang_bridge.c`, `helpers.c`, `with_runtime.c`)

2. **Add weak stub to `runtime/helpers.c`** (at the end of the file):
   ```c
   __attribute__((weak)) void my_new_function(with_str arg) { (void)arg; }
   ```
   This lets the linker resolve the symbol even before the real implementation
   is linked.

3. **Build without calling the new function** — temporarily comment out or
   guard any calls to the new function in `.w` source:
   ```bash
   rm -f out/lib/helpers.o out/lib/clang_bridge.o out/lib/embedded_objects.inc.h
   make build
   ```

4. **Update seed and runtime objects:**
   ```bash
   cp out/bin/with-stage2 ~/.local/bin/with
   cp out/lib/*.o ~/.local/bin/runtime/
   ```

5. **Re-enable the calls** to the new function in `.w` source.

6. **Rebuild:**
   ```bash
   rm -f out/lib/embedded_objects.inc.h
   make build
   ```

7. **Update seed again** (now with the new function embedded):
   ```bash
   cp out/bin/with-stage2 ~/.local/bin/with
   cp out/lib/*.o ~/.local/bin/runtime/
   ```

8. **Verify fixpoint:**
   ```bash
   make fixpoint
   ```

## Why This Is Needed

The compiler is self-hosting: `seed → stage1 → stage2`. When stage1
links, it uses the seed's embedded runtime objects + the on-disk runtime
objects from `~/.local/bin/runtime/`. If a new C function is referenced
by the compiler source but not present in EITHER location, linking fails.

The weak stubs in `helpers.c` provide a fallback definition that lets
linking succeed even before the real implementation is available. Once the
seed is updated with the real implementation, the weak stubs are overridden.

## Key Locations

| What | Where |
|------|-------|
| Embedded runtime source | `runtime/helpers.c`, `runtime/with_runtime.c`, etc. |
| Clang bridge (c_import) | `runtime/clang_bridge.c` |
| Built runtime objects | `out/lib/*.o` |
| Seed runtime objects | `~/.local/bin/runtime/*.o` |
| Embedded object generator | `scripts/embed_runtime_objects.sh` |
| Seed binary | `~/.local/bin/with` |
