// Every measured loss against the fastest safe Rust row is a performance bug.
// Usage: with run -O1 benchmarks/goose/compare.w <results.md> [report.md]
use std.fs
use std.process
use std.string.StringBuilder
use std.string.string_to_int

let cli = args()
if cli.len() < 2: panic("expected a results file")
let results = read_file(cli[1]).unwrap()
let manifest = read_file("benchmarks/goose/suite.manifest").unwrap()
var report = StringBuilder.new()
report.push_str("| workload | With ms | fastest safe Rust ms | Rust row | With / Rust | verdict |\n|---|---:|---:|---|---:|---|\n")
var losses: i32 = 0
for entry in manifest.split("\n"):
    if entry.len() == 0 or entry.starts_with("#"): continue
    let entry_fields = entry.split("|")
    let name = entry_fields[0]
    var with_ns: i64 = 0
    var rust_ns: i64 = 9223372036854775807
    var rust_label = ""
    for line in results.split("\n"):
        if not line.starts_with("| "): continue
        let fields = line.split("|")
        if fields.len() < 7 or fields[1].trim() != name: continue
        if fields[3].trim() != "MATCH": panic(f"incomplete result for {name}")
        let label = fields[2].trim()
        let ns = string_to_int(fields[4].trim())
        if label == "With": with_ns = ns
        else if label.starts_with("Rust ") and ns < rust_ns:
            rust_ns = ns
            rust_label = label.clone()
    if with_ns == 0 or rust_label.len() == 0: panic(f"missing With/Rust row for {name}")
    let lost = with_ns > rust_ns
    if lost: losses += 1
    let verdict = if lost: "BUG" else: "PASS"
    report.push_str(f"| {name} | {(with_ns as f64) / 1000000.0:.3} | {(rust_ns as f64) / 1000000.0:.3} | {rust_label} | {(with_ns as f64) / (rust_ns as f64):.3} | {verdict} |\n")
report.push_str(f"\nPerformance bugs: {losses}. This comparison includes process startup and representation differences; it identifies losses, not their causes.\n")
let text = report.to_str()
print(text)
if cli.len() > 2 and write_file(cli[2], text) != 0: panic("report write failed")
if losses > 0: exit_code(1)
