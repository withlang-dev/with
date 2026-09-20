module build.zlib

use std.build
use build.corpus

// zlib 1.3.2 (madler/zlib release tarball), the second .wo bundle
// (docs/wo_bundles.md "Conforming pcre2 and zlib"). The generic pipeline
// (build/corpora.w) fetches, migrates, checks, promotes and bundles it;
// this module holds the facts, the staging hook, the migrate hook (the two
// test programs are migrated one at a time after the library) and the
// corpus's own lanes: upstream's example and minigzip round trip.

const ZLIB_RELEASE: str = "zlib-1.3.2"
const ZLIB_SHA256: str = "bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16"

pub fn zlib_corpus() -> Corpus:
    Corpus {
        name: "zlib", stem: "zlib", package: "std.zl",
        corpus_rel: "std/zl", corpus_dir: "lib/std/zl",
        upstream: upstream_release("zlib", ZLIB_RELEASE, "https://zlib.net/fossils/" ++ ZLIB_RELEASE ++ ".tar.gz", ZLIB_SHA256),
        license: "",
        // example and minigzip are the harness, never the bundle; example.w
        // takes the .gz scratch file as its one argument, spelled inside the
        // drift dir so the harness never writes at the root
        harness: ["example", "minigzip"], drift_harness: "example.w", drift_harness_arg: "out/wo-drift/zlib/example.gz",
        module_floor: 21, defines: Vec.new(), excludes: Vec.new(), declared_externs: Vec.new(),
        promote_after: ["zlib-test"], test_lane: "",
        prepare_reference: corpus_no_prepare, stage: zlib_stage,
        migrate: zlib_migrate, finish_generated: corpus_no_finish,
        verify_generated: corpus_no_verify, lanes: zlib_lanes,
    }

fn zlib_source_files() -> Vec[str]:
    ["adler32.c", "compress.c", "crc32.c", "crc32.h", "deflate.c", "deflate.h",
     "gzclose.c", "gzguts.h", "gzlib.c", "gzread.c", "gzwrite.c", "infback.c",
     "inffast.c", "inffast.h", "inffixed.h", "inflate.c", "inflate.h",
     "inftrees.c", "inftrees.h", "trees.c", "trees.h", "uncompr.c", "zconf.h",
     "zlib.h", "zutil.c", "zutil.h"]

// contrib/minizip, from the same release: the ZIP container over the
// library's raw inflate — reader (unzip), repair (mztools) and their stream
// callbacks (ioapi). The writer (zip.c with skipset.h) waits on
// setjmp/longjmp, which zipAlreadyThere uses as its out-of-memory landing
// pad and the migrator refuses. The two command-line programs and the Win32
// stream layer (iowin32) stay out.
fn zlib_minizip_files() -> Vec[str]:
    ["crypt.h", "ints.h", "ioapi.c", "ioapi.h", "mztools.c", "mztools.h",
     "unzip.c", "unzip.h"]

// The library's units and headers, flat. The test programs are not staged:
// migrated as part of the directory they would become library modules.
fn zlib_stage(ctx: &ActionCtx, corpus: &Corpus, reference: &str, source: &str) -> i32:
    for file in zlib_source_files():
        let path = reference ++ "/" ++ file
        if not ctx.fs().exists(path) or ctx.fs().read_text(path).len() == 0:
            return corpus_fail(ctx, "reference tree lacks " ++ path)
        if corpus_copy(ctx, path, source ++ "/" ++ file) != 0: return 1
    for file in zlib_minizip_files():
        let path = reference ++ "/contrib/minizip/" ++ file
        if not ctx.fs().exists(path): return corpus_fail(ctx, "reference tree lacks " ++ path)
        if corpus_copy(ctx, path, source ++ "/" ++ file) != 0: return 1
    0

// One test program migrated on its own against the library's shared defs:
// staged beside the library for the migration and removed after, so the
// next one sees the same sources.
fn zlib_migrate_one(ctx: &ActionCtx, corpus: &Corpus, source: &str, generated: &str, basename: &str) -> i32:
    let staged = source ++ "/" ++ basename
    if corpus_copy(ctx, corpus.upstream.reference ++ "/test/" ++ basename, staged) != 0: return 1
    let label = "zlib-migrate-" ++ corpus_module_name(basename)
    var options = corpus_migrate_options(corpus, source, generated)
    options.migrate_one = basename.clone()
    options.shared_fragment = corpus_scratch(ctx) ++ "/" ++ label ++ ".shared-fragment"
    if corpus_run_migration(ctx, label, options) != 0: return 1
    if ctx.fs().remove_file(staged) != 0: return corpus_fail(ctx, "cannot remove staged " ++ basename)
    0

fn zlib_migrate(ctx: &ActionCtx, corpus: &Corpus, source: &str, generated: &str) -> i32:
    if corpus_migrate_directory(ctx, corpus, source, generated) != 0: return 1
    for program in ["example.c", "minigzip.c"]:
        if zlib_migrate_one(ctx, corpus, source, generated, program) != 0: return 1
    0

pub fn run_zlib_build_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let migrated = ctx.inputs()[0]
    let output = ctx.output()
    if not fs.is_dir(migrated): return corpus_fail(ctx, "missing migrated zlib directory: " ++ migrated ++ " - run zlib-migrate deliberately")
    let tmp = corpus_scratch(ctx) ++ "/build"
    let zl = tmp ++ "/lib/std/zl"
    let bin = tmp ++ "/bin"
    if corpus_reset_dir(ctx, tmp) != 0: return 1
    if fs.mkdir_all(zl) != 0 or fs.mkdir_all(bin) != 0: return corpus_fail(ctx, "could not create temp build directories under " ++ tmp)
    if corpus_copy_w_files(ctx, migrated, zl) != 0: return 1
    if corpus_compile_binary(ctx, "zlib-build-example", zl ++ "/example.w", bin ++ "/zlib_example") != 0: return 1
    if corpus_compile_binary(ctx, "zlib-build-minigzip", zl ++ "/minigzip.w", bin ++ "/minigzip") != 0: return 1
    if fs.exists(output) and fs.remove_tree(output) != 0: return corpus_fail(ctx, "cannot replace " ++ output)
    if fs.rename(tmp, output) != 0: return corpus_fail(ctx, "could not move temp tree to " ++ output)
    print("built migrated zlib tests: " ++ corpus_abs(ctx, output ++ "/bin/zlib_example"))
    0

pub fn run_zlib_test_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let inputs = ctx.inputs()
    let output = ctx.output()
    if inputs.len() < 3: return corpus_fail(ctx, "requires migrated-dir, example binary and minigzip binary inputs")
    let example_bin = inputs.get(1)
    let minigzip_bin = inputs.get(2)
    if not fs.exists(example_bin): return corpus_fail(ctx, "missing zlib example binary: " ++ example_bin)
    if not fs.exists(minigzip_bin): return corpus_fail(ctx, "missing minigzip binary: " ++ minigzip_bin)
    let run_dir = output ++ "/current"
    if corpus_reset_dir(ctx, run_dir) != 0: return 1
    var example_args: Vec[str] = Vec.new()
    example_args.push(corpus_abs(ctx, example_bin))
    example_args.push("foo.gz")
    let example = ctx.process_runner().run_capture_cwd(example_args, corpus_abs(ctx, run_dir ++ "/example.stdout"), corpus_abs(ctx, run_dir ++ "/example.stderr"), 120000, corpus_abs(ctx, run_dir))
    if example.rc != 0:
        return corpus_fail(ctx, f"zlib example failed with exit code {example.rc}; stdout=" ++ run_dir ++ "/example.stdout stderr=" ++ run_dir ++ "/example.stderr")
    let input_path = run_dir ++ "/minigzip-input.txt"
    if fs.write_text(input_path, "hello, hello!\n") != 0: return corpus_fail(ctx, "could not write minigzip input")
    var gzip_args: Vec[str] = Vec.new()
    gzip_args.push(corpus_abs(ctx, minigzip_bin))
    gzip_args.push("minigzip-input.txt")
    let gzip = ctx.process_runner().run_capture_cwd(gzip_args, corpus_abs(ctx, run_dir ++ "/minigzip-compress.stdout"), corpus_abs(ctx, run_dir ++ "/minigzip-compress.stderr"), 120000, corpus_abs(ctx, run_dir))
    if gzip.rc != 0: return corpus_fail(ctx, f"minigzip compress failed with exit code {gzip.rc}")
    if not fs.exists(run_dir ++ "/minigzip-input.txt.gz"): return corpus_fail(ctx, "minigzip did not produce compressed file")
    var gunzip_args: Vec[str] = Vec.new()
    gunzip_args.push(corpus_abs(ctx, minigzip_bin))
    gunzip_args.push("-d")
    gunzip_args.push("minigzip-input.txt.gz")
    let gunzip = ctx.process_runner().run_capture_cwd(gunzip_args, corpus_abs(ctx, run_dir ++ "/minigzip-decompress.stdout"), corpus_abs(ctx, run_dir ++ "/minigzip-decompress.stderr"), 120000, corpus_abs(ctx, run_dir))
    if gunzip.rc != 0: return corpus_fail(ctx, f"minigzip decompress failed with exit code {gunzip.rc}")
    if fs.read_text(input_path) != "hello, hello!\n": return corpus_fail(ctx, "minigzip round-trip content mismatch")
    print("VERIFIED: migrated zlib example and minigzip tests pass")
    0

fn zlib_lanes(out: Build, ctx: &BuildCtx, corpus: &Corpus, release_compiler: &str) -> Build:
    var graph = out
    var build = target_new(.Action, "zlib-build", "").output("out/zlib_build")
    build.action = run_zlib_build_action
    build = build.write_scope("out/tmp/action-scratch/zlib-build")
    build = build.input("out/zlib_migrated").dep("build").dep("zlib-migrate")
    graph = graph.add_target(build)
    var test = target_new(.Action, "zlib-test", "").output("out/corpus/zlib-test")
    test.action = run_zlib_test_action
    test = test.input("out/zlib_migrated").input("out/zlib_build/bin/zlib_example").input("out/zlib_build/bin/minigzip").dep("zlib-build")
    graph.add_target(test)
