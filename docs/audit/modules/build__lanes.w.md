# Primary verification — `build/emit_c.w` + `build/package.w` + `build/runtime.w` + `build/seed.w` + `build/compiler.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: emit_c `39727ed8bbd4cf8e960bc497c9e4f05bc5953565afd7c2cb1f9e407d6bb5ceee`;
package `55e9f3dab002ee4f6aa0ffbbe27f1aa911919869c984bd84bfb5dce3f82ce305`;
runtime `ef644436c2d00e50691c8bd4815cb1abdb9e0bc9e18859e4e0c1b75df83f588c`;
seed `d1ad509a7e6a6a1b9b206732bd1c7553b6cd47746de1956db51048fe3f75c43f`;
compiler `673a5684e03bc3bee99c304f9a7533b6876ea4fabbb2359132db32a563e251f9`
Source examined: child all five complete (emit_c 948, package 598, runtime
376, seed 320, compiler 1966); primary: bundle-corpus threading
(Compilation.w:345-424 + emit_c lane :1453-1490, full reads), lane `check`
re-runs below

## Scope examined

Build lanes: emit-C wiring, packaging, runtime objects, compiler stages, seed provenance.

Applicable overview targets examined: T19/T21 (lanes), T23 (failures), T24 (build.w overlap).

## Behavioral matrix

- `check` rc=0: build/runtime.w, build/seed.w, build/compiler.w (re-run by primary).
- `check` rc=1 on build/emit_c.w + build/package.w is a HARNESS ARTIFACT:
  `use build.compiler` resolves only with build/ as module root (i.e. under
  the real build entry), not under standalone `check`. Not a defect — these
  files are not standalone entry points.

## Verdict: no filing — lane refuses loudly, corpus threading works

- `--bundle-corpus` IS threaded (Compilation.w:401/412/415 →
  `zcu.bundle_corpus`); it just isn't a `c_emit_module` parameter. The
  emit_c lane refuses bundles/interfaces LOUDLY (link_bundles→error,
  `.wi`→error, :1453-1462, primary-read) rather than miscompiling — the
  loud direction. Composition limits may exist; silence doesn't.
- Seed provenance + stage/stamp/codesign/llvm-metadata observations recorded
  as child evidence; no behavioral divergence attached.

## Notes

- The #955/#990/#983/#982/#1006 emit-C classes live in CCodegen emitters,
  not in this wiring — confirmed separation by this leg.
