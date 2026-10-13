use std.fs
use std.process

const ROOT = "out/benchmarks/goose/root-causes/"
const SDK = ".deps/llvm-22.1.6-darwin-arm64-release/bin/"
fn command(argv: &Vec[str]):
    let result = run_to_files(argv, ROOT ++ "diagnostic-command.stdout", ROOT ++ "diagnostic-command.stderr", 600000)
    if result.code != 0 or result.timed_out:
        print(read_file(ROOT ++ "diagnostic-command.stderr").unwrap())
        panic("diagnostic command failed")

let cases = "interp_cvp|interp|function(correlated-propagation,instcombine)\nscene_slp|scene|function(aggressive-instcombine,slp-vectorizer)\nparticles_slp|particles|function(aggressive-instcombine,slp-vectorizer)\nblur_promote|blur|cgscc(argpromotion),default<O1>\nblur_promote_vector|blur|cgscc(argpromotion),default<O1>,function(loop-vectorize,instcombine,simplifycfg)\nparticles_ranges|particles|function(correlated-propagation,constraint-elimination,instcombine,simplifycfg)"
for row in cases.split("\n"):
    let fields = row.split("|")
    let name = fields[0]
    let input = ROOT ++ fields[1] ++ ".stage1.ll"
    command([SDK ++ "opt", "-passes=" ++ fields[2], "-S", input, "-o", ROOT ++ name ++ ".ll"])
    command([SDK ++ "llc", "-O1", "-filetype=obj", ROOT ++ name ++ ".ll", "-o", ROOT ++ name ++ ".o"])
    command(["/usr/bin/cc", ROOT ++ name ++ ".o", "out/bootstrap/lib/rt_core.o", "out/bootstrap/lib/rt_darwin_aarch64.o", "out/bootstrap/lib/panic_runtime.o", "out/bootstrap/lib/fiber_stubs.o", "-Wl,-dead_strip", "-o", ROOT ++ name])
