# D53 — wasm32 is a freestanding target whose "libc" is the With runtime over WASI preview1, with an emitted JS host

**Laws:** 8 (docs/mission.md).

**Date:** 2026-09-19. **Status:** implemented on the `wasm-target` branch
(fork); not yet a BDFL ruling. Design note: `docs/wasm-target.md`.

**Decision.** `--target=wasm32` compiles a pure-With program to a
WebAssembly module whose only imports are WASI preview1 system calls, plus
a generated `<prog>.js` host that serves them under node (real filesystem,
argv, env, stdio) or in a browser (in-memory filesystem, console). No
wasi-libc, no emscripten musl: `rt/wasm.w` implements the same `rt_*`
platform contract the Linux/Darwin/Windows backends implement over libc,
and additionally owns what a libc would (startup/exit, the page allocator
behind `rt_mmap` on `memory.grow`, `malloc`/`free`/`memcmp`, and
compiler-rt's `__multi3`). Pointer width is a target property
(`target_spec_ptr_bytes`, 4 on wasm32) read by `TypeLayout`. A `wasm64`
kind is reserved but refused until its runtime exists.

**Why WASI as the import ABI.** With's runtime is not libc-shaped, so
emscripten's patched musl has nothing to attach to; the platform contract
is already a thin syscall layer, and WASI preview1 is the one syscall ABI
every wasm host (wasmtime, node's `wasi`, browsers via a shim) speaks. The
emitted JS host is exactly what emscripten's JS runtime is: the userspace
that implements those imports. Using WASI names rather than a private
`env.*` set costs one attribute (`@[import_module]`, clang's
`import_module`) and buys every standalone host for free.

**Why no async.** WebAssembly has no stack switching; the fiber core is
context-switch assembly plus guard-page signal handling. A wasm program
links `fiber_stubs.o`; one that really spawns fails at wasm-ld with the
core-only symbols undefined. Stack switching (JSPI or the wasm
stack-switching proposal) reopens this.

**What it exposed.** wasm verifies call signatures, so two native
"works by luck" inconsistencies became hard failures and were fixed for
every target: `-> Unit` lowered to an `i32` result while an absent return
type lowered to `void` (ABI v5: a Unit result is always `void`), and the
HashMap runtime helpers were declared with a placeholder prototype. The
wasm link now runs with `--fatal-warnings` so this class cannot recur
silently.

**Alternatives weighed.** wasm64 first (keeps 8-byte pointers, avoids the
pointer-width audit) — rejected as the primary: browsers only recently
ship memory64 and every WASI host assumes wasm32; the pointer-width work
was small once `TypeLayout` was the single place. A private `env.*`
import set — rejected: it would make the module runnable only under the
emitted host. Silently linking the fiber stubs and trapping at spawn —
rejected: the link fails loudly instead.

**Reopens if:** a stack-switching primitive lands in engines With cares
about (async on wasm); the runtime retirement (D30) moves the platform
layer in-unit (then `rt/wasm.w` compiles like the embedded stdlib and the
cross-object directory goes away).

---
