use std.fs
use std.process
use std.time
use std.string.StringBuilder

const ROOT = "out/benchmarks/goose/root-causes/"
const OUT = "out/benchmarks/goose/"
let cli = args()
let variants = if cli.len() > 1: read_file(cli[1]).unwrap() else: "sum_index|sum\nsum_reserve|sum\npush_reserve|push\nstrlist_direct|strlist\nwords_direct|words\nbintrees_reuse|bintrees\ncalc_reuse|calc\nblur|blur\nblur-stage1|blur\nsum-stage1|sum\npush-stage1|push\nstrlist-stage1|strlist\nwords-stage1|words\nbintrees-stage1|bintrees\ncalc-stage1|calc"
var result = StringBuilder.new()
result.push_str("| diagnostic | best ns | peak RSS bytes | stdout |\n|---|---:|---:|---|\n")
for row in variants.split("\n"):
    if row.len() == 0: continue
    let fields = row.split("|")
    let name = fields[0]
    let reference = read_file(OUT ++ fields[1] ++ "_medium_with.stdout").unwrap()
    var best: i64 = 9223372036854775807
    var peak: i64 = 0
    let argv: Vec[str] = [ROOT ++ name]
    for pass in 0..7:
        let start = now_ns()
        let run = run_to_files(argv, ROOT ++ name ++ ".measure.stdout", ROOT ++ name ++ ".measure.stderr", 600000)
        let elapsed = now_ns() - start
        if run.code != 0 or run.timed_out: panic(f"run failed: {name}")
        if read_file(ROOT ++ name ++ ".measure.stdout").unwrap() != reference: panic(f"checksum differs: {name}")
        if pass >= 2:
            if elapsed < best: best = elapsed
            if run.peak_rss > peak: peak = run.peak_rss
    let line = f"| {name} | {best} | {peak} | MATCH |\n"
    print(line)
    result.push_str(line)
let output = if cli.len() > 2: cli[2].clone() else: ROOT ++ "variants.md"
if write_file(output, result.to_str()) != 0: panic("write failed")
