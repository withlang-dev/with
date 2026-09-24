// Regenerate src/InitTemplates.w from docs/with_for_ai.md.
// Run after any edit to the guide: with run tools/gen_init_templates.w
// The cli-selfhost-project-tests lane compares `with init` output against
// the doc byte-for-byte, so the embedded template must match exactly.

use std.fs
use std.process

fn esc(chunk: str) -> str:
    var out = ""
    for i in 0..chunk.len() as i32:
        let b = chunk[i]
        if b == 92:
            out = out ++ "\\\\"
        else if b == 34:
            out = out ++ "\\\""
        else if b == 10:
            out = out ++ "\\n"
        else if b == 9:
            out = out ++ "\\t"
        else if b == 13:
            out = out ++ "\\r"
        else:
            out = out ++ chunk.slice(i as i64, (i + 1) as i64)
    out

let doc = read_file("docs/with_for_ai.md").unwrap_or("")
if doc.len() == 0:
    eprint("error: could not read docs/with_for_ai.md")
    exit_code(1)
var body = ""
var pos: i64 = 0
let chunk_size: i64 = 4000
var first = 1
while pos < doc.len():
    var end = pos + chunk_size
    if end > doc.len():
        end = doc.len()
    let segment = esc(doc.slice(pos, end))
    if first != 0:
        body = body ++ "    \"" ++ segment ++ "\""
        first = 0
    else:
        body = body ++ " ++\n    \"" ++ segment ++ "\""
    pos = end
let out =
    "// Embedded project templates for `with init`.\n" ++
    "// Generated from docs/with_for_ai.md by tools/gen_init_templates.w;\n" ++
    "// rerun that tool whenever the guide changes.\n\n" ++
    "pub fn init_ai_guide_template -> str:\n" ++ body ++ "\n"
if write_file("src/InitTemplates.w", out) != 0:
    eprint("error: could not write src/InitTemplates.w")
    exit_code(1)
print(f"wrote src/InitTemplates.w ({doc.len()} bytes embedded)")
