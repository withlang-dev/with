//! skip-on: windows issue #802: core-language behavior fails on native Windows (needs root-cause)
//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// #1423, #1435: an assembled object is made from its source and from every
// file the source pulls in by `.incbin`. An EmbedObjectFiles target's
// assembly names each blob by path only, so a blob whose bytes change leaves
// the assembly identical: early cutoff kept its dependents fresh, and the
// object kept the old bytes (stage2 embedded stale .wo bundles). The runner
// now records the incbin'd files as the object's discovered dependencies.
fn object_has(case_dir: &str, rel: &str, needle: &str) -> bool:
    read_file(p7_join(case_dir, rel)).unwrap().contains(needle)

fn main:
    let case_dir = p7_prepare_case("build_asm_incbin_inputs", "asmincbin")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    out = out.add_target(target_new(.EmbedObjectFiles, \"emb-asm\", \"\").output(\"out/emb/e.s\").input(\"src/blob.bin\").arg(\"blob\"))\n"
    build_text = build_text ++ "    out = out.add_target(target_new(.CompileAsmObject, \"emb-obj\", \"out/emb/e.s\").output(\"out/emb/e.o\").dep(\"emb-asm\"))\n"
    // A hand-written source with a relative operand: no generator in between.
    build_text = build_text ++ "    out = out.add_target(target_new(.CompileAsmObject, \"raw-obj\", \"src/raw.s\").output(\"out/raw/raw.o\"))\n"
    build_text = build_text ++ "    var all = target_new(.Group, \"all\", \"\").dep(\"emb-obj\").dep(\"raw-obj\")\n"
    build_text = build_text ++ "    out = out.add_target(move all)\n"
    build_text = build_text ++ "    out.default(\"all\")\n"
    p7_write(case_dir, "build.w", build_text)
    p7_write(case_dir, "src/raw.s", ".globl raw_blob\nraw_blob:\n    .incbin \"src/raw.bin\"\n")
    p7_write(case_dir, "src/blob.bin", "EMBED-BYTES-ONE")
    p7_write(case_dir, "src/raw.bin", "RAW-BYTES-ONE")

    let first = p7_run(case_dir, "incbin-first", p7_build_args())
    p7_assert_success(first, "first build")
    assert(object_has(case_dir, "out/emb/e.o", "EMBED-BYTES-ONE"))
    assert(object_has(case_dir, "out/raw/raw.o", "RAW-BYTES-ONE"))

    // Nothing changed: both objects stay fresh.
    let again = p7_run(case_dir, "incbin-unchanged", p7_build_args())
    p7_assert_success(again, "rebuild with nothing changed")
    assert(not again.stderr.contains("[time] emb-obj"))
    assert(not again.stderr.contains("[time] raw-obj"))

    // The blob's bytes change and its path does not: the assembly re-runs to
    // identical text (the cutoff fires), and the object is assembled anyway.
    p7_write(case_dir, "src/blob.bin", "EMBED-BYTES-TWO")
    let embed = p7_run(case_dir, "incbin-embed-changed", p7_build_args())
    p7_assert_success(embed, "rebuild after the embedded blob changed")
    assert(embed.stderr.contains("[cutoff] 'emb-asm' re-ran to identical outputs"))
    assert(embed.stderr.contains("[time] emb-obj"))
    assert(not embed.stderr.contains("[time] raw-obj"))
    assert(object_has(case_dir, "out/emb/e.o", "EMBED-BYTES-TWO"))
    assert(not object_has(case_dir, "out/emb/e.o", "EMBED-BYTES-ONE"))

    // A relative .incbin operand in a source nothing generates.
    p7_write(case_dir, "src/raw.bin", "RAW-BYTES-TWO")
    let raw = p7_run(case_dir, "incbin-raw-changed", p7_build_args())
    p7_assert_success(raw, "rebuild after the raw blob changed")
    assert(raw.stderr.contains("[time] raw-obj"))
    assert(not raw.stderr.contains("[time] emb-obj"))
    assert(object_has(case_dir, "out/raw/raw.o", "RAW-BYTES-TWO"))
    print("ok")
