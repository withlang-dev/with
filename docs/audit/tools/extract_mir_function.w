use std.io
use std.process

let argv = args()
if argv.len() < 2:
    print("usage: extract_mir_function <name>")
    exit_code(2)

let needle = argv.get(1)
var active = false
for line in stdin.lines():
    if active and line.starts_with("fn "):
        break
    if line.starts_with("fn ") and line.contains(needle):
        active = true
    if active:
        print(line)
