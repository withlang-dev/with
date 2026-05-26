module build.seed

use std.build
use std.process

fn seed_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if right.len() == 0:
        return left
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn seed_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn seed_abs(root: str, path: str) -> str:
    if path.len() > 0 and path.byte_at(0) == 47:
        return path
    seed_join(root, path)

fn seed_fail(ctx: ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn seed_tool_from_env(env_name: str, fallback: str) -> str:
    let value = env(env_name)
    if value.len() > 0:
        return value
    fallback

fn seed_split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if i > start:
                lines.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start < text.len() as i32:
        lines.push(text.slice(start as i64, text.len()))
    lines

fn seed_json_line_value(line: str, key: str) -> str:
    let needle = "\"" ++ key ++ "\""
    var pos = -1
    var i = 0
    while i <= line.len() as i32 - needle.len() as i32:
        if line.slice(i as i64, (i + needle.len() as i32) as i64) == needle:
            pos = i + needle.len() as i32
            break
        i = i + 1
    if pos < 0:
        return ""
    while pos < line.len() as i32:
        let ch = line.byte_at(pos as i64)
        if ch != 32 and ch != 9:
            break
        pos = pos + 1
    if pos >= line.len() as i32 or line.byte_at(pos as i64) != 58:
        return ""
    pos = pos + 1
    while pos < line.len() as i32:
        let ch = line.byte_at(pos as i64)
        if ch != 32 and ch != 9:
            break
        pos = pos + 1
    if pos >= line.len() as i32 or line.byte_at(pos as i64) != 34:
        return ""
    let start = pos + 1
    var end = start
    var escaped = false
    while end < line.len() as i32:
        let ch = line.byte_at(end as i64)
        if escaped:
            escaped = false
        else if ch == 92:
            escaped = true
        else if ch == 34:
            return line.slice(start as i64, end as i64)
        end = end + 1
    ""

fn seed_release_from_api(ctx: ActionCtx, repo: str, asset_name: str) -> str:
    let fs = ctx.fs()
    let root = ctx.project_info().project_root()
    let tmp_dir = seed_join("out/tmp", "seed-download")
    if fs.mkdir_all(tmp_dir) != 0:
        return ""
    let body_path = seed_join(tmp_dir, "releases.json")
    let stdout_path = seed_join(tmp_dir, "releases.stdout")
    let stderr_path = seed_join(tmp_dir, "releases.stderr")
    var args: Vec[str] = Vec.new()
    args |> push(seed_tool_from_env("CURL", "curl"))
    args |> push("-L")
    args |> push("--fail")
    args |> push("--show-error")
    args |> push("--output")
    args |> push(seed_abs(root, body_path))
    args |> push("https://api.github.com/repos/" ++ repo ++ "/releases?per_page=10")
    let result = ctx.process_runner().run_capture(args, seed_abs(root, stdout_path), seed_abs(root, stderr_path), 120000)
    if result.rc != 0:
        let _ = seed_fail(ctx, f"could not query releases for {repo}; curl exit code {result.rc}; stderr=" ++ stderr_path)
        return ""
    let body = fs.read_text(body_path)
    let _remove_body = fs.remove_file(body_path)
    let _remove_stdout = fs.remove_file(stdout_path)
    let _remove_stderr = fs.remove_file(stderr_path)
    let lines = seed_split_nonempty_lines(body)
    var current_tag = ""
    for li in 0..lines.len() as i32:
        let line = lines.get(li as i64)
        let tag = seed_json_line_value(line, "tag_name")
        if tag.len() > 0:
            current_tag = tag
        let name = seed_json_line_value(line, "name")
        if current_tag.len() > 0 and name == asset_name:
            return current_tag
    ""

pub fn run_seed_download_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let args = ctx.args()
    let output_path = ctx.output()
    let root = ctx.project_info().project_root()
    if args.len() < 2 or output_path.len() == 0:
        return seed_fail(ctx, "requires repo arg, asset arg, and output path")
    let repo = args.get(0)
    let asset_name = args.get(1)
    if fs.exists(output_path):
        print("seed binary already exists: " ++ output_path)
        print("remove it first if you want to re-download")
        return 0
    var tag = env("SEED_VERSION")
    if tag.len() == 0:
        tag = seed_release_from_api(ctx, repo, asset_name)
        if tag.len() == 0:
            ctx.diagnostics().error("seed: could not find a release containing asset '" ++ asset_name ++ "'")
            ctx.diagnostics().error("set SEED_VERSION to a release tag to download a specific seed")
            return 1
        print("latest seed release: " ++ tag)
    let url = "https://github.com/" ++ repo ++ "/releases/download/" ++ tag ++ "/" ++ asset_name
    let output_dir = seed_dirname(output_path)
    if fs.mkdir_all(output_dir) != 0:
        return seed_fail(ctx, "could not create output directory: " ++ output_dir)
    let tmp_dir = seed_join("out/tmp", "seed-download")
    if fs.mkdir_all(tmp_dir) != 0:
        return seed_fail(ctx, "could not create temp directory: " ++ tmp_dir)
    let tmp_path = seed_join(tmp_dir, asset_name ++ ".tmp")
    let _remove_tmp = fs.remove_file(tmp_path)
    print("downloading seed from: " ++ url)
    var curl_args: Vec[str] = Vec.new()
    curl_args |> push(seed_tool_from_env("CURL", "curl"))
    curl_args |> push("-L")
    curl_args |> push("--fail")
    curl_args |> push("--show-error")
    curl_args |> push("--output")
    curl_args |> push(seed_abs(root, tmp_path))
    curl_args |> push(url)
    let curl_rc = ctx.process_runner().run(curl_args)
    if curl_rc != 0:
        return seed_fail(ctx, f"curl failed with exit code {curl_rc}")
    if fs.rename(tmp_path, output_path) != 0:
        return seed_fail(ctx, "could not publish seed: " ++ output_path)
    if fs.chmod(output_path, 0o755) != 0:
        return seed_fail(ctx, "could not chmod seed: " ++ output_path)
    print("seed installed: " ++ output_path)
    0
