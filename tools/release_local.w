// tools/release_local.w — the local-first half of cutting a release.
//
//   with run tools/release_local.w vX.Y.Z [--channel release|test] [--skip-darwin] [--skip-linux-aarch64]
//
// Run from the release checkout on the maintainer's Mac after `src/version`
// says vX.Y.Z and the `vX.Y.Z` tag is pushed (publish-first refuses a commit
// the repository does not have). It builds, verifies, packages and publishes
// the two platforms a Mac can produce:
//
//   darwin-aarch64   natively: the seed-driven gates (build, :fixpoint,
//                    :test, :test-green, :last-green), then the rebuilt
//                    compiler's :release-uat, :package-current-host,
//                    :package-llvm-sdk and :publish-release-asset.
//   linux-aarch64    in the native linux/arm64 container from
//                    tools/docker/linux-aarch64 (see the release runbook,
//                    "Linux aarch64 Release Host"): the same gates and
//                    publish, driven inside the container.
//
// The `v*` tag push then makes CI build and append only the platforms a Mac
// cannot: linux-x86_64, windows-x86_64 and windows-aarch64
// (.github/workflows/nightly-release.yml gates the local-first jobs on
// `github.event_name != 'push'`).
//
// Pins come from where they already live: seed.lock (the linux-aarch64 seed
// version and digest) and .github/workflows/selfhost-linux-aarch64.yml (the
// SDK release and the seed's runtime bundle). GH_TOKEN must be set.
use std.process
use std.fs

fn fail(message: &str) -> i32:
    eprint("release_local: " ++ message ++ "\n")
    1

/// The file's text, or "" when it cannot be read (callers check emptiness).
fn text_of(path: &str) -> str:
    let r = read_file(path)
    if r.is_err(): return ""
    r.unwrap()

/// Run one command with the current environment; print it first.
fn step(label: &str, argv: &Vec[str]) -> i32:
    var shown = ""
    for a in argv: shown = shown ++ a ++ " "
    print("== " ++ label ++ ": " ++ shown)
    let rc = run(argv)
    if rc != 0: eprint("release_local: " ++ label ++ " failed with exit code " ++ f"{rc}" ++ "\n")
    rc

fn argv2(a: &str, b: &str) -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push(a ++ "")
    v.push(b ++ "")
    v

fn argv3(a: &str, b: &str, c: &str) -> Vec[str]:
    var v = argv2(a, b)
    v.push(c ++ "")
    v

/// `key=value` lines: the value for `key`, or "".
fn lock_value(text: &str, key: &str) -> str:
    for line in text.split("\n"):
        let l = line.trim()
        if l.starts_with(key ++ "="): return l.slice(key.len() + 1, l.len()).trim()
    ""

/// `  KEY: value` YAML env lines: the value for `key`, or "".
fn yaml_env_value(text: &str, key: &str) -> str:
    for line in text.split("\n"):
        let l = line.trim()
        if l.starts_with(key ++ ":"): return l.slice(key.len() + 1, l.len()).trim()
    ""

fn publish_env(version: &str, channel: &str, assets: &str, extras: &str, builder: &str):
    set_env("RELEASE_TAG", version)
    set_env("RELEASE_TITLE", "With " ++ version)
    set_env("RELEASE_CHANNEL", channel)
    set_env("RELEASE_ASSETS", assets)
    set_env("RELEASE_EXTRA_FILES", extras)
    set_env("RELEASE_BUILDER", builder)
    set_env("RELEASE_REPO", "withlang-dev/with")

fn darwin_leg(version: &str, channel: &str) -> i32:
    let root = env("PWD")
    let seed = root ++ "/src/main"
    let release = root ++ "/out/release/bin/with"
    set_env("WITH_VERSION", version)
    // The pinned seed drives the gates (seed-driver refuses any other driver).
    set_env("WITH", seed)
    var gates: Vec[str] = Vec.new()
    gates.push(":fixpoint")
    gates.push(":test")
    gates.push(":test-green")
    gates.push(":last-green")
    let build_argv = argv2(seed, "build")
    if step("darwin build", &build_argv) != 0: return 1
    for gi in 0..gates.len() as i32:
        let target = gates[gi]
        let argv = argv3(seed, "build", target)
        if step("darwin " ++ target, &argv) != 0: return 1
    // The rebuilt compiler runs the UAT, packages and publishes.
    set_env("WITH", release)
    var finals: Vec[str] = Vec.new()
    finals.push(":release-uat")
    finals.push(":package-current-host")
    finals.push(":package-llvm-sdk")
    for fi in 0..finals.len() as i32:
        let target = finals[fi]
        let argv = argv3(release, "build", target)
        if step("darwin " ++ target, &argv) != 0: return 1
    let sdk = "out/release/with-llvm-sdk-22.1.6-darwin-aarch64.tar.gz"
    publish_env(version, channel, "out/release/with-darwin-aarch64",
        sdk ++ "," ++ sdk ++ ".sha256," ++ sdk ++ ".manifest,scripts/install.sh,scripts/install.ps1,scripts/install.cmd",
        "local darwin-aarch64 (the release host)")
    let publish_argv = argv3(release, "build", ":publish-release-asset")
    step("darwin :publish-release-asset", &publish_argv)

/// The in-container script: bootstrap exactly as the linux-aarch64 lane
/// does, then the same gates, packaging and publish. One string, one sh -c.
fn linux_aarch64_script(version: &str, channel: &str, sha: &str, seed_version: &str, seed_sha: &str, rt_asset: &str, rt_version: &str, rt_sha: &str) -> str:
    "set -eu\n" ++
    "cd /work\n" ++
    "if [ ! -d with/.git ]; then git clone -q https://github.com/withlang-dev/with.git with; fi\n" ++
    "cd with && git fetch -q origin && git checkout -q " ++ sha ++ "\n" ++
    "export LLVM_PREFIX=/work/with/.deps/llvm-22.1.6-linux-aarch64\n" ++
    "mkdir -p .link-shim\n" ++
    "curl -fsSL -o src/main https://github.com/withlang-dev/with/releases/download/" ++ seed_version ++ "/with-linux-aarch64\n" ++
    "echo '" ++ seed_sha ++ "  src/main' | sha256sum -c - && chmod +x src/main\n" ++
    "mkdir -p src/runtime && curl -fsSL -o /tmp/rt.tar.gz https://github.com/withlang-dev/with/releases/download/" ++ rt_version ++ "/" ++ rt_asset ++ "\n" ++
    "echo '" ++ rt_sha ++ "  /tmp/rt.tar.gz' | sha256sum -c - && tar -xzf /tmp/rt.tar.gz -C src/runtime\n" ++
    "WITH_LLVM_SDK_VERSION=sdk-linux-aarch64 WITH=/work/with/src/main ./src/main build :deps\n" ++
    "ln -sf \"$LLVM_PREFIX/bin/ld.lld\" .link-shim/ld.lld && ln -sf \"$LLVM_PREFIX/bin/ld.lld\" .link-shim/ld64.lld && ln -sf \"$LLVM_PREFIX/bin/lld\" .link-shim/lld\n" ++
    "echo \"$LLVM_PREFIX/bin/ld.lld\" > src/runtime/llvm_ld\n" ++
    "export PATH=/work/with/.link-shim:$LLVM_PREFIX/bin:$PATH LD_LIBRARY_PATH=/work/with/.link-shim WITH_OUT_DIR=/work/with/out WITH_VERSION=" ++ version ++ "\n" ++
    "for t in '' :fixpoint :test :test-green :last-green; do WITH=/work/with/src/main ./src/main build $t; done\n" ++
    "for t in :release-uat :package-current-host :package-llvm-sdk; do WITH=/work/with/out/release/bin/with ./out/release/bin/with build $t; done\n" ++
    "SDK=out/release/with-llvm-sdk-22.1.6-linux-aarch64.tar.gz\n" ++
    "RELEASE_TAG=" ++ version ++ " RELEASE_TITLE='With " ++ version ++ "' RELEASE_CHANNEL=" ++ channel ++ " RELEASE_ASSETS=out/release/with-linux-aarch64 " ++
    "RELEASE_EXTRA_FILES=$SDK,$SDK.sha256,$SDK.manifest RELEASE_BUILDER='local linux-aarch64 (docker on the release host)' RELEASE_REPO=withlang-dev/with " ++
    "WITH=/work/with/out/release/bin/with ./out/release/bin/with build :publish-release-asset\n"

fn linux_aarch64_leg(version: &str, channel: &str) -> i32:
    let docker_version = argv2("docker", "--version")
    if step("docker available", &docker_version) != 0: return fail("docker is required for the linux-aarch64 leg")
    let lock = text_of("seed.lock")
    let lane = text_of(".github/workflows/selfhost-linux-aarch64.yml")
    let seed_sha = lock_value(lock, "with-linux-aarch64")
    var seed_version = lock_value(lock, "with-linux-aarch64.version")
    if seed_version.len() == 0: seed_version = lock_value(lock, "version")
    let rt_asset = yaml_env_value(lane, "WITH_RUNTIME_ASSET")
    let rt_version = yaml_env_value(lane, "WITH_RUNTIME_VERSION")
    let rt_sha = yaml_env_value(lane, "WITH_RUNTIME_SHA256")
    if seed_sha.len() != 64 or seed_version.len() == 0: return fail("seed.lock has no linux-aarch64 seed pin")
    if rt_asset.len() == 0 or rt_version.len() == 0 or rt_sha.len() != 64: return fail("selfhost-linux-aarch64.yml has no runtime bundle pin (WITH_RUNTIME_*)")
    let sha = env("RELEASE_SOURCE_SHA")
    if sha.len() == 0: return fail("set RELEASE_SOURCE_SHA to the tagged commit (git rev-parse " ++ version ++ ")")
    var build_args: Vec[str] = Vec.new()
    build_args.push("docker")
    build_args.push("build")
    build_args.push("--platform")
    build_args.push("linux/arm64")
    build_args.push("-q")
    build_args.push("-t")
    build_args.push("with-aarch64-host")
    build_args.push("tools/docker/linux-aarch64")
    if step("docker image", &build_args) != 0: return 1
    var volume_args: Vec[str] = Vec.new()
    volume_args.push("docker")
    volume_args.push("volume")
    volume_args.push("create")
    volume_args.push("with-aarch64")
    if step("docker volume", &volume_args) != 0: return 1
    var run_args: Vec[str] = Vec.new()
    run_args.push("docker")
    run_args.push("run")
    run_args.push("--rm")
    run_args.push("--platform")
    run_args.push("linux/arm64")
    run_args.push("-v")
    run_args.push("with-aarch64:/work")
    run_args.push("-e")
    run_args.push("GH_TOKEN")
    run_args.push("with-aarch64-host")
    run_args.push("sh")
    run_args.push("-c")
    run_args.push(linux_aarch64_script(version, channel, sha, seed_version, seed_sha, rt_asset, rt_version, rt_sha))
    step("linux-aarch64 (container)", &run_args)

fn main -> i32:
    let argv = args()
    if argv.len() < 2: return fail("usage: with run tools/release_local.w vX.Y.Z [--channel release|test] [--skip-darwin] [--skip-linux-aarch64]")
    let version = argv.get(1).clone()
    var channel = "release"
    var do_darwin = true
    var do_aarch64 = true
    var i = 2
    while i < argv.len() as i32:
        let a = argv.get(i).clone()
        if a == "--channel" and i + 1 < argv.len() as i32:
            channel = argv.get(i + 1).clone()
            i += 1
        else if a == "--skip-darwin": do_darwin = false
        else if a == "--skip-linux-aarch64": do_aarch64 = false
        else: return fail("unknown argument " ++ a)
        i += 1
    if not version.starts_with("v"): return fail("version must look like vX.Y.Z, got " ++ version)
    if text_of("src/version").trim() != version: return fail("src/version does not say " ++ version ++ "; bump and commit it first")
    if env("GH_TOKEN").len() == 0: return fail("GH_TOKEN is not set")
    if do_darwin and darwin_leg(version, channel) != 0: return 1
    if do_aarch64 and linux_aarch64_leg(version, channel) != 0: return 1
    print("release_local: done — CI appends linux-x86_64, windows-x86_64 and windows-aarch64 on the tag push")
    0
