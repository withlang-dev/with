// D29 #750 scaffolding sweep: for each corpus file, check with a gate-aware
// compiler; on gate diagnostics, fork the import-free original into the
// quarantined D acceptance corpus (when a corpus dir is given), then apply
// tools/insert_std_uses.w and recheck to fixpoint.
//
//   with run tools/sweep_gate_corpus.w <stage1> <list_file> <diag_tmp> [d_corpus_dir]
use std.process
use std.fs

fn sh(cmd: &str) -> i32:
    let argv: Vec[str] = Vec.new()
    argv.push("/bin/sh")
    argv.push("-c")
    argv.push(cmd.clone())
    run(&argv)

fn gate_count(diag_path: &str) -> i32:
    var count = 0
    let text = read_file(diag_path).unwrap_or("".clone())
    for line in text.split("\n"):
        if line.contains("requires an explicit import"): count = count + 1
    count

let argv = args()
if argv.len() < 4:
    eprint("usage: sweep_gate_corpus <stage1> <list> <diag_tmp> [d_corpus_dir]")
    exit_code(2)
let stage1 = argv[1]
let list_file = argv[2]
let diag_tmp = argv[3]
let d_corpus = if argv.len() > 4: argv[4].clone() else: "".clone()

var affected = 0
var fixed = 0
var stuck = 0
let list_text = read_file(list_file).unwrap_or("".clone())
for f in list_text.split("\n"):
    if f.len() == 0: continue
    let _ = sh(stage1 ++ " check " ++ f ++ " 2> " ++ diag_tmp)
    var n = gate_count(diag_tmp)
    if n == 0: continue
    affected = affected + 1
    if d_corpus.len() > 0:
        let _ = sh("mkdir -p " ++ d_corpus ++ " && cp " ++ f ++ " " ++ d_corpus ++ "/")
    var pass = 0
    while n > 0 and pass < 4:
        let _ = sh("with run tools/insert_std_uses.w --apply " ++ diag_tmp ++ " > /dev/null 2>&1")
        let _ = sh(stage1 ++ " check " ++ f ++ " 2> " ++ diag_tmp)
        n = gate_count(diag_tmp)
        pass = pass + 1
    if n == 0:
        fixed = fixed + 1
        print("fixed " ++ f)
    else:
        stuck = stuck + 1
        print("STUCK " ++ f)
print(f"sweep done: affected={affected} fixed={fixed} stuck={stuck}")
