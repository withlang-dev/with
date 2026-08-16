// Generate immutable nightly/test release metadata for GitHub Actions.
// The workflow supplies only run facts; release wording lives here in With.

extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32
use std.process

fn write_file(path: &str, data: &str):
    if unsafe { with_fs_write_file(path, data) } != 0:
        eprint("error: could not write " ++ path)
        exit_code(1)

let argv = args()
if argv.len() != 13:
    eprint("usage: nightly_release_metadata <event> <requested-channel> <yyyymmdd> <yyyy-mm-dd> <run-id> <attempt> <sha> <server-url> <repository> <version> <github-output> <notes-output>")
    exit_code(1)

let event = argv.get(1)
let requested_channel = argv.get(2)
let compact_date = argv.get(3)
let display_date = argv.get(4)
let run_id = argv.get(5)
let attempt = argv.get(6)
let source_sha = argv.get(7)
let server_url = argv.get(8)
let repository = argv.get(9)
let version = argv.get(10)
let github_output = argv.get(11)
let notes_output = argv.get(12)

if source_sha.len() < 12:
    eprint("error: source commit must contain at least 12 characters")
    exit_code(1)

var channel = requested_channel.clone()
if event == "schedule":
    channel = "nightly"

let short_sha = source_sha.slice(0, 12)
var tag = ""
var title = ""
if channel == "test":
    tag = "nightly-test-" ++ run_id ++ "-" ++ attempt
    title = "Disposable nightly release test " ++ run_id ++ "." ++ attempt
else if channel == "nightly":
    tag = "nightly-" ++ compact_date ++ "-" ++ run_id ++ "-" ++ attempt ++ "-" ++ short_sha
    title = "With nightly " ++ display_date ++ " (" ++ short_sha ++ ")"
else:
    eprint("error: unsupported release channel: " ++ channel)
    exit_code(1)

let workflow_url = server_url ++ "/" ++ repository ++ "/actions/runs/" ++ run_id
let prior_output = unsafe { with_fs_read_file(github_output) }
let step_output =
    prior_output ++
    "channel=" ++ channel ++ "\n" ++
    "tag=" ++ tag ++ "\n" ++
    "title=" ++ title ++ "\n"
write_file(github_output, step_output)

let notes =
    "Automated " ++ channel ++ " compiler prerelease.\n\n" ++
    "Source commit: " ++ source_sha ++ "\n" ++
    "Workflow run: " ++ workflow_url ++ "\n" ++
    "Compiler version: " ++ version ++ "\n" ++
    "Platforms: darwin-aarch64, linux-x86_64\n\n" ++
    "Release contents:\n\n" ++
    "- Fixpoint-verified compiler binaries with SHA-256 sidecars\n" ++
    "- Checksum-pinned LLVM 22.1.6 SDK archives, SHA-256 sidecars, and manifests\n\n" ++
    "Verification gates on each platform:\n\n" ++
    "- `WITH_VERSION=" ++ version ++ " with build`\n" ++
    "- `WITH_VERSION=" ++ version ++ " with build :fixpoint`\n" ++
    "- Fixpoint-verified `out/release/bin/with` copied to each platform asset with a SHA-256 sidecar\n" ++
    "- The same verified SDK inputs used by each build attached without rebuilding\n"
write_file(notes_output, notes)
