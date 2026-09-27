# The WebAssembly target

`--target=wasm32` (also spelled `wasm32-unknown-unknown`, `wasm32-wasi`,
`wasm32-wasip1`) compiles a With program to a WebAssembly module plus a
JavaScript host that runs it. With's runtime does not use libc, so there is
no wasi-libc or emscripten musl underneath: the platform layer of the With
runtime speaks WASI preview1 directly, and the emitted host is the
"userspace" that serves those system calls, emscripten-style.

```
with build --target=wasm32 prog.w -o prog.wasm    # prog.wasm + prog.js
node prog.js a b c                                 # run under node
with run --target=wasm32 prog.w a b c              # build and run (node)
with test --target=wasm32 test/wasm/hello.w        # test fixtures under node
```

Any WASI preview1 host also runs the module directly (`wasmtime prog.wasm`,
node's `wasi` module), because the imports are the standard ones.

## Layout of the work

| Piece | Where | What it does |
|---|---|---|
| target kind 7 (`wasm32`) | `src/TargetSpec.w`, `src/compiler/DriverOptions.w`, `src/BuildGraphKinds.w`, `lib/std/build.w` | triple `wasm32-unknown-unknown`, OS `Wasi`, arch `wasm32`, 4-byte pointers (`target_spec_ptr_bytes`) |
| pointer-width-aware layout | `src/TypeLayout.w` | pointer, reference, fn and trait-object sizes read the target's pointer width; `str`/slices stay 16 bytes (i64 length keeps its 8-byte alignment) |
| `@[import_module("ns")]` | `src/Parser.w`, `src/Codegen.w`, `src/compiler/LlvmBridge.w` | an extern fn imported from a wasm namespace (clang's `import_module`); codegen attaches `wasm-import-module` / `wasm-import-name` |
| `_start` entry | `src/Codegen.w` `wrap_main_for_exit` | on wasm the wrapper is wasm-ld's `_start()`: `with_wasm_startup` fills argc/argv, main runs, `with_wasm_exit` leaves through `proc_exit` |
| link stage | `src/compiler/Link.w` | `wasm-ld` beside the SDK's lld, `--stack-first -z stack-size=8MiB` (`WITH_WASM_STACK_SIZE`), no archives, output `<stem>.wasm`, emits the JS host, refuses async programs |
| platform runtime | `rt/wasm.w` | the `rt_*` contract over WASI: files/dirs through preopens, env/args, clocks, sleep, randomness, the page allocator behind `rt_mmap` (`memory.grow`), `malloc`/`free`/`_exit`/`abort`/`memcmp` and compiler-rt's `__multi3` |
| JS host | `src/compiler/WasmHost.w` | `<prog>.js`: WASI preview1 over node's real filesystem/stdio/argv/env, or over an in-memory filesystem + console in a browser |
| build | `build.w` `:cross-rt-wasm` | compiles the runtime objects into `out/lib/cross/wasm32/` |
| driver | `src/main.w` | `with run`/`with test` execute wasm programs through `node <prog>.js` (`WITH_NODE` overrides the interpreter) |

`wasm64` is modeled as kind 8 but refused by the driver: the runtime is the
wasm32 flavour (32-bit WASI sizes, 8-byte iovecs) and the JS host reads
32-bit pointers.

## Paths

WASI opens every path relative to a preopened directory. The runtime makes
each path absolute against its cwd (`PWD` from the environment when it is
absolute, else `/`), normalizes it, and picks the longest preopen name that
prefixes it; the remainder is what the host sees. The emitted host preopens
`/` and passes `PWD=process.cwd()`, so a program under node reads and writes
the real filesystem exactly as a native binary would. In a browser the
filesystem is in memory, seeded from `run({ files: { '/data/in.txt': '...' } })`.

WASI errnos are translated to the POSIX numbers `rt_core.w` and `std.fs`
expect (`ENOENT` 44 → 2, and so on), so error paths behave as on Linux.

## What is not there

- **Async/fibers.** WebAssembly has no stack switching. A wasm program links
  `fiber_stubs.o`, which answers the lifecycle references every program
  makes; one that actually spawns a task or uses a channel fails at the
  wasm-ld step with the undefined `with_fiber_spawn` / `with_channel_*`
  symbols only the fiber core defines.
- **Threads, processes, signals, sockets.** `rt_thread_spawn`, the
  `rt_compat_exec_*` family and the `with_net_*` family report failure the
  way a failed native call does; `rt_raise` exits with `128+sig`.
- **`c_import`.** There is no libc to import against; a wasm program is
  pure With. `cimport_stubs.o` is not part of the wasm runtime set.
- **Embedded corpus bundles** (`std.regex`, `std.zlib`) are host objects
  and are not yet built for wasm32; a program that pulls one in fails at
  the wasm-ld step.

## What wasm exposed in the native compiler

WebAssembly checks every call against the callee's declared signature, so
it turned two native "works by luck" inconsistencies into hard failures.
Both are fixed for every target:

- An explicit `-> Unit` lowered to an `i32` result while an absent return
  type lowered to `void` (Codegen `resolve_named_type` carries `Unit` as
  `i32` for value positions). Definitions and declarations of the same
  runtime symbol disagreed; native ABIs ignore an unused return register.
  Return positions now lower `Unit` to `void` (`resolve_return_type`;
  ABI v5 in `docs/with-abi.md`).
- Codegen declared the HashMap runtime helpers with a one-pointer
  placeholder prototype and called them with the real arguments. A wasm
  object records the declaration as the import signature. The helpers now
  get their real prototypes (`ensure_hm_fn`), and the wasm link runs with
  `--fatal-warnings` so any remaining mismatch fails the link instead of
  trapping at the first call.

## Pre-existing bug found on the way

Formatting an `Option[&T]` in an f-string (`print(f"{m.get("k")}")` with a
`HashMap`, or `let o: Option[&i32] = ...; print(f"{o}")`) segfaulted the
compiler (`LLVMTypeOf` on a null value) on every target: the enum
formatter walked the nullable-pointer niche representation as a
tag + payload struct. Not wasm-specific; fixed on its own in #1216.
`test/wasm/wasm_alloc.w` predates that fix and unwraps instead.

## Spec items awaiting a ruling

The specification leads the implementation, and only Eric blesses
normative wording. This work extends the surface in two places that
§16.13 and §18.5 do not yet describe; both are implemented and need
wording ruled on:

- `@[target("wasm32")]` / `@[target("wasm64")]` as architecture guards
  beside `"aarch64"` and `"x86_64"` (§16.13).
- `@[import_module("ns")]` on an `extern fn`: the WebAssembly import
  namespace, clang's `import_module`; the symbol keeps its With name as
  the import name. Meaningless on non-wasm targets (ignored there).
- `--target=wasm32` and its spellings in the §18.5 target list, with the
  `wasm32` name in `std.build.BuildTarget`.

Until that wording lands, `with build :test`'s `spec-inventory-check`
reports `attributes: implementation has unspec'd import_module` and stays
red by design: the check is the spec-leads rule mechanized and is not to
be weakened.

## Verifying

### Source-built SDK on every host

`with build :sdk-package` rebuilds Ninja, CMake, LLVM/Clang and lld from
pinned sources using the existing With SDK as the bootstrap toolchain. The
LLVM target set includes `AArch64;X86;WebAssembly`; an override omitting
WebAssembly is rejected. No separate WASI SDK or emscripten is needed.

SDK installation and packaging require all six `LLVMWebAssembly*` static
archives, the `lldWasm` static archive, and `wasm-ld` (`wasm-ld.exe` on Windows). Unix archives preserve
the `wasm-ld -> lld` symlink. Windows x86_64 and ARM64 packages include the
native executable and `.lib` archives.
The package also carries CMake's `share/cmake-<major.minor>` modules, so
the installed SDK can configure the next source build without host CMake.

The five native CI lanes build and upload the SDK archive, digest and
manifest, unpack that archive, build the compiler against it, and run
`:wasm-tests` under Node. `:sdk-contract-tests` also checks the packaging
rules for all five platforms on each host. An input-keyed cache reuses
source-built SDK artifacts when SDK build inputs are unchanged; extraction,
digest verification, compiler builds and wasm fixtures still run.
Publishing these artifacts and
updating the pinned bootstrap SDK digests is a separate release step;
existing downloaded SDKs are not silently upgraded.

CI first builds `:dev` with the pinned seed and uses that current driver for
`:sdk-package`: old seeds embed the old whole-archive writer. The current
driver streams tar extraction and gzip creation using With's own zlib code,
so the LLVM source tree and SDK archive do not exceed the build memory gate.
Archive paths use USTAR's prefix field for long CMake module names. File
sizes are counted with bounded-memory stdio reads; archive I/O never mixes
UCRT descriptors with the Windows runtime's separate handle table.

### Compiler and runtime

```
with build :dev                      # stage1 with the target
with build :cross-rt-wasm            # out/lib/cross/wasm32/*.o
with test --target=wasm32 test/wasm/*.w
```

The fixtures in `test/wasm/` cover stdout/stderr and exit codes, argv and
environment, allocation-heavy code (`Vec`, `str`, `HashMap`), f64 formatting,
overflow-checked multiplication (`__multi3`), and file I/O through the node
host.
