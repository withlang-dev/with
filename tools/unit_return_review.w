// Run from the repository root: with run tools/unit_return_review.w BASE
// BASE must be the target branch (or the explicit pre-change commit).
// Git emits whole files; the With lexer compares declarations, not diff lines.
use std.fs
use std.process
use UnitReturnReview

fn review_file(path: &str, before: &str, after: &str, reviews: &str) -> i32:
    var missing = 0
    if not path.ends_with(".w"): return missing
    for signature in added_unit_returns(before, after):
        if unit_return_reviewed(reviews, path, signature):
            print("reviewed: " ++ path ++ "\t" ++ signature)
        else:
            eprint("explicit Unit needs review: " ++ path ++ "\t" ++ signature)
            missing = missing + 1
    missing

let argv = args()
if argv.len() != 2:
    eprint("usage: with run tools/unit_return_review.w BASE")
    exit_code(2)
assert(mkdir_p("out/unit-return-review") == 0)
let diff_path = "out/unit-return-review/change.diff"
let rc = command("git").arg("diff").arg("--no-ext-diff").arg("--no-textconv").arg("--no-color").arg("--no-renames").arg("--unified=2147483647").arg("--output=" ++ diff_path).arg(argv[1] ++ "").arg("--").arg("*.w").run()
if rc != 0: exit_code(rc)
let diff = read_file(diff_path).unwrap()
let reviews = read_file("docs/unit-return-reviews.tsv").unwrap()
var path = ""
var before = ""
var after = ""
var in_hunk = false
var missing = 0
for line in diff.split("\n"):
    if line.starts_with("diff --git "):
        missing = missing + review_file(path, before, after, reviews)
        path = ""
        before = ""
        after = ""
        in_hunk = false
    else if not in_hunk and line.starts_with("+++ b/"):
        path = line.slice(6, line.len())
    else if not in_hunk and line.starts_with("+++ ") and line != "+++ /dev/null":
        eprint("unit-return-review: unsupported quoted Git path: " ++ line)
        exit_code(2)
    else if line.starts_with("@@ "):
        in_hunk = true
    else if in_hunk and line.starts_with(" "):
        before = before ++ line.slice(1, line.len()) ++ "\n"
        after = after ++ line.slice(1, line.len()) ++ "\n"
    else if in_hunk and line.starts_with("-"):
        before = before ++ line.slice(1, line.len()) ++ "\n"
    else if in_hunk and line.starts_with("+"):
        after = after ++ line.slice(1, line.len()) ++ "\n"
missing = missing + review_file(path, before, after, reviews)
if missing > 0:
    eprint("Remove redundant annotations. For a necessary annotation, record its exact path, signature and semantic reason in docs/unit-return-reviews.tsv. A compiler demand is not a reason; investigate it.")
    exit_code(1)
print("unit-return-review: ok")
