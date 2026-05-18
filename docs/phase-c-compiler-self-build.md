# Phase C Compiler Self-Build

Status: design note. No extraction work has started.

Phase C moves project-specific build logic out of the generic compiler driver.
The compiler project itself is one of those projects, so targets such as
`with_compiler_build`, `with_compiler_ir`, `generate_compiler_entrypoints`, and
`generate_llvm_link_metadata` ultimately belong in this repository's `build.w`
or project-local build modules, not in generic `src/main.w` dispatch.

## Bootstrap Order

The safe end-state bootstrap shape is:

1. A seed compiler evaluates the repository `build.w`.
2. `build.w` declares ordinary graph nodes and project-local actions for the
   compiler build.
3. The generic driver executes standard nodes and mints action capabilities.
4. Project-local action functions implement With-repository policy: versioned
   entrypoint generation, stage compilation, IR emission, and LLVM link metadata.
5. Stage1 is built by the seed.
6. Stage1 evaluates the same `build.w` and builds stage2.
7. Stage2 evaluates the same `build.w` and builds stage3.
8. Fixpoint compares stage2 and stage3 byte-for-byte.

The important invariant is that `build.w` must remain evaluable by the current
seed before any newly built stage exists. Project-local action code can build
the compiler, but it cannot require compiler features that are absent from the
seed until the seed has been updated through the normal fixpoint path.

## Seed Sufficiency

The seed is sufficient to evaluate `build.w` if the build file uses only:

- standard `std.build` APIs already embedded in the seed;
- project-local modules that the seed can parse and typecheck;
- action capabilities already implemented in the seed;
- runtime primitives already linked into the seed.

That means extraction must be staged around seed capabilities. If a compiler
self-build action needs a new capability, the capability lands first, reaches
fixpoint, and is installed into the seed before the project build starts relying
on it.

## Chicken-And-Egg Risks

The main risks are:

- `build.w` uses a new stdlib API before the seed embeds it.
- A project-local action needs a runtime primitive before the seed can link it.
- A stage-build action shells out to compiler behavior that is being replaced
  in the same slice.
- Generated compiler entrypoints change in the same slice that changes the
  mechanism used to generate them.
- Link metadata generation moves before the generic standard nodes can express
  all required inputs, outputs, and diagnostics.

The way to break each cycle is the same: introduce generic capability first,
verify it with a small project-local consumer, install the verified compiler,
then migrate the compiler-project target that depends on it.

## Recommended Extraction Order

1. Selfhost fixtures. These are pure repository tests and already fit the
   action model. Moving them first reduces `src/main.w` dispatch without
   touching bootstrap-critical stage construction.
2. PCRE2 targets. They are project-specific migrated-library workflows. They
   exercise filesystem, process, corpus-test, promotion, and generated-source
   capabilities without being needed to build the compiler.
3. Emit-C targets. They are compiler-project verification targets, but not on
   the normal stage1/stage2/stage3 bootstrap path.
4. Seed download/update policy. This is project policy around release assets,
   but it touches recovery paths, so it should move after action/process/file
   capabilities are well exercised.
5. Compiler-project support targets that are not the main compiler build:
   `generate_compiler_entrypoints`, `generate_llvm_link_metadata`, and
   `with_compiler_ir`.
6. Main compiler stage build targets: `with_compiler_build` for stage1, stage2,
   stage3, runtime objects, and fixpoint objects. These should move last because
   they are the actual bootstrap chain.

This order removes low-risk project policy first and leaves the self-hosting
stage chain until the build-driver/action boundary has already been proven by
less critical targets.
