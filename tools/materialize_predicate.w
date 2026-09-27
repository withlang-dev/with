// Path-preserving adapter for reducers and other candidate generators.
// Materializes a candidate at the requested project-relative path, runs an argv
// command with `{file}` replaced by that path, then removes the materialized file.
// Child stdout/stderr are inherited so `with reduce --contains` can inspect them.
//
//   with run tools/materialize_predicate.w candidate.w src/Foo.__candidate.w -- \
//       with check {file}

use std.process
use std.fs

let argv = args()
if argv.len() < 5:
    print("usage: materialize_predicate <candidate> <materialized-path> -- <command> [args...]")
    exit_code(2)

var separator = -1
for i in 3..argv.len() as i32:
    if argv[i] == "--":
        separator = i
        break
if separator < 0 or separator + 1 >= argv.len() as i32:
    print("error: expected '--' followed by a command")
    exit_code(2)

let candidate = read_file(argv.get(1)).unwrap_or("".clone())
let materialized = argv.get(2).clone()
if write_file(materialized, candidate) != 0:
    print(f"error: could not materialize candidate at {materialized}")
    exit_code(2)

let child: Vec[str] = Vec.new()
for i in separator + 1..argv.len() as i32:
    let arg = argv[i]
    child.push(if arg == "{file}": materialized.clone() else: arg.clone())
let status = run(&child)
if remove_file(materialized) != 0:
    print(f"error: could not remove materialized candidate {materialized}")
    exit_code(2)
exit_code(status)
