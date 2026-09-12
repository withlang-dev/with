# Repeated stage1 build selects an incomplete runtime (#1115)

Route: build graph freshness inspection, then LLDB on the link-plan branch.

After `:dev`, a runtime-producing target such as `:zlib-migrate` creates
`out/lib/cimport_stubs.o` and the platform runtime object. The LLVM bridge
and metadata can still exist only in `out/bootstrap-lib`. After a compiler
edit, `:dev` recompiles stage1 but fails at link with:

```
missing LLVM static bridge (need llvm_bridge.o + llvm_ld.rsp + llvm_ld)
```

`build --explain prepare-bootstrap-link-root` reports `fresh`: the action's
cached stamp does not express that its deleted runtime probes must remain
absent. LLDB on a minimal `LLVMGetGlobalContext` caller confirms the effect:
stop in `link_stage_find_llvm_static_bridge`, then in
`link_stage_resolve_runtime_root`, disable breakpoints and step out. The
return registers are `x0 -> "out/lib"`, `x1 = 7`. The accepting condition
in `src/compiler/Link.w` is the nonempty cimport and platform probe check;
the caller subsequently rejects that root's missing LLVM bridge.

The stage1 build action now invokes the existing cleanup helper immediately
before compiling. Its declared write scope includes `out/lib`. The separate
preparation target remains for earlier bootstrap tools, but its cache cannot
suppress stage1's cleanup. Tracking the generated probe as a graph input
would introduce a stage1/runtime/stage2 dependency cycle. Linker selection
and runtime-generation rules remain unchanged.

Regression procedure: populate `out/lib` with its cimport and host platform
probes, leave its LLVM bridge absent, and run `:stage1 --no-deps` with the
existing complete bootstrap inputs. This skips the separate preparation
target and exercises stage1's own cleanup. Stage1 must link successfully;
the ordinary complete build must then regenerate its runtime and pass.
