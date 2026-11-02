// tools/release_local.w — the local-first half of cutting a release.
//
//   with run tools/release_local.w vX.Y.Z [--channel release|test] [--skip-darwin] [--skip-linux-aarch64] [--skip-windows-aarch64]
//
// Run from the release checkout on the maintainer's Mac after `src/version`
// says vX.Y.Z and the `vX.Y.Z` tag is pushed (publish-first refuses a commit
// the repository does not have). It builds, verifies, packages and publishes
// the three platforms a Mac can produce:
//
//   darwin-aarch64   natively: the seed-driven gates (build, :fixpoint,
//                    :test, :test-green, :last-green), then the rebuilt
//                    compiler's :release-uat, :package-current-host,
//                    :package-llvm-sdk and :publish-release-asset.
//   linux-aarch64    in the native linux/arm64 container from
//                    tools/docker/linux-aarch64 (see the release runbook,
//                    "Linux aarch64 Release Host"): the same gates and
//                    publish, driven inside the container.
//   windows-aarch64  cross-built by the rebuilt darwin compiler against the
//                    pinned windows-aarch64 SDK (:cross-winarm-compiler, the
//                    recipe of seed-windows-aarch64.yml), finalized by
//                    :package-windows-aarch64 (cross mode) and published with the
//                    pinned SDK. D137: the arm CI lane runs the battery on
//                    the platform itself, post hoc; D180: the asset and its
//                    SDK ship with every release, from here.
//
// The `v*` tag push then makes CI build and append only the platforms a Mac
// cannot: linux-x86_64 and windows-x86_64 (.github/workflows/nightly-release.yml
// gates the local-first jobs on `github.event_name != 'push'`; its
// windows-aarch64 job is add-only, so the asset published here stands).
//
// Pins come from where they already live: seed.lock (the linux-aarch64 seed
// version and digest) and sdk.lock (the SDK, which `build :deps` installs).
// GH_TOKEN must be set.
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
fn step(label: &str, argv: &List[str]) -> i32:
    var shown = ""
    for a in argv: shown = shown ++ a ++ " "
    print("== " ++ label ++ ": " ++ shown)
    let rc = run(argv)
    if rc != 0: eprint("release_local: " ++ label ++ " failed with exit code " ++ f"{rc}" ++ "\n")
    rc

fn argv2(a: &str, b: &str) -> List[str]:
    var v: List[str] = List.new()
    v.push(a ++ "")
    v.push(b ++ "")
    v

fn argv3(a: &str, b: &str, c: &str) -> List[str]:
    var v = argv2(a, b)
    v.push(c ++ "")
    v

/// `key=value` lines: the value for `key`, or "".
fn lock_value(text: &str, key: &str) -> str:
    for line in text.split("\n"):
        let l = line.trim()
        if l.starts_with(key ++ "="): return l.slice(key.len() + 1, l.len()).trim().to_owned()
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
    // The pinned seed drives everything but the publish: seed-driver refuses
    // any other driver, and :release-uat and the package targets depend on
    // release-checks, which depends on it (#2888). The UAT exercises the
    // packaged asset whoever drives it. The steps are the release workflow's
    // own: `:test` runs selfcheck itself (#2915), so a leg here exercises the
    // same graph the CI lanes do; the #2887 hand-run `:selfcheck` hid that
    // the test group never ran it, through two tags.
    set_env("WITH", seed)
    var gates: List[str] = List.new()
    gates.push(":fixpoint")
    gates.push(":test")
    gates.push(":test-green")
    gates.push(":last-green")
    gates.push(":release-uat")
    gates.push(":package-current-host")
    gates.push(":package-llvm-sdk")
    let build_argv = argv2(seed, "build")
    if step("darwin build", &build_argv) != 0: return 1
    for gi in 0..gates.len():
        let target = gates[gi]
        let argv = argv3(seed, "build", target)
        if step("darwin " ++ target, &argv) != 0: return 1
    // The rebuilt compiler publishes.
    set_env("WITH", release)
    let sdk = "out/release/with-llvm-sdk-22.1.6-darwin-aarch64.tar.gz"
    publish_env(version, channel, "out/release/with-darwin-aarch64",
        sdk ++ "," ++ sdk ++ ".sha256," ++ sdk ++ ".manifest,scripts/install.sh,scripts/install.ps1,scripts/install.cmd",
        "local darwin-aarch64 (the release host)")
    let publish_argv = argv3(release, "build", ":publish-release-asset")
    step("darwin :publish-release-asset", &publish_argv)

/// The in-container script: bootstrap exactly as the linux-aarch64 lane
/// does, then the same gates, packaging and publish. One string, one sh -c.
fn linux_aarch64_script(version: &str, channel: &str, sha: &str, seed_version: &str, seed_sha: &str) -> str:
    "set -eu\n" ++
    "cd /work\n" ++
    "if [ ! -d with/.git ]; then git clone -q https://github.com/withlang-dev/with.git with; fi\n" ++
    "cd with && git fetch -q origin && git checkout -q " ++ sha ++ "\n" ++
    "curl -fsSL -o src/main https://github.com/withlang-dev/with/releases/download/" ++ seed_version ++ "/with-linux-aarch64\n" ++
    "echo '" ++ seed_sha ++ "  src/main' | sha256sum -c - && chmod +x src/main\n" ++
    "WITH=/work/with/src/main ./src/main build :deps\n" ++
    "export WITH_OUT_DIR=/work/with/out WITH_VERSION=" ++ version ++ "\n" ++
    "for t in '' :fixpoint :selfcheck :test :test-green :last-green; do WITH=/work/with/src/main ./src/main build $t; done\n" ++
    "LIBGL_ALWAYS_SOFTWARE=1 WITH=/work/with/src/main xvfb-run -a -s '-screen 0 1280x800x24' ./src/main build :release-uat\n" ++
    "WITH=/work/with/src/main ./src/main build :package-current-host\n" ++
    // The container extracted the pinned SDK asset (`build :deps`); it has no
    // SDK build tree for :package-llvm-sdk to package, so the release gets the
    // pinned asset itself, as every CI lane publishes it: the tag and the
    // digests of the archive and its sidecars come from sdk.lock.
    "A=with-llvm-sdk-22.1.6-linux-aarch64.tar.gz\n" ++
    "T=$(sed -n \"s/^$A.version=//p\" sdk.lock)\n" ++
    "for s in '' .sha256 .manifest; do curl -fsSL --retry 5 -o out/release/$A$s https://github.com/withlang-dev/with/releases/download/$T/$A$s; " ++
    "echo \"$(sed -n \"s/^$A$s=//p\" sdk.lock)  out/release/$A$s\" | sha256sum -c -; done\n" ++
    "SDK=out/release/$A\n" ++
    "RELEASE_TAG=" ++ version ++ " RELEASE_TITLE='With " ++ version ++ "' RELEASE_CHANNEL=" ++ channel ++ " RELEASE_ASSETS=out/release/with-linux-aarch64 " ++
    "RELEASE_EXTRA_FILES=$SDK,$SDK.sha256,$SDK.manifest RELEASE_BUILDER='local linux-aarch64 (docker on the release host)' RELEASE_REPO=withlang-dev/with " ++
    "WITH=/work/with/out/release/bin/with ./out/release/bin/with build :publish-release-asset\n"

fn linux_aarch64_leg(version: &str, channel: &str) -> i32:
    let docker_version = argv2("docker", "--version")
    if step("docker available", &docker_version) != 0: return fail("docker is required for the linux-aarch64 leg")
    let lock = text_of("seed.lock")
    let seed_sha = lock_value(lock, "with-linux-aarch64")
    var seed_version = lock_value(lock, "with-linux-aarch64.version")
    if seed_version.len() == 0: seed_version = lock_value(lock, "version")
    if seed_sha.len() != 64 or seed_version.len() == 0: return fail("seed.lock has no linux-aarch64 seed pin")
    let sha = env("RELEASE_SOURCE_SHA")
    if sha.len() == 0: return fail("set RELEASE_SOURCE_SHA to the tagged commit (git rev-parse " ++ version ++ ")")
    var build_args: List[str] = List.new()
    build_args.push("docker")
    build_args.push("build")
    build_args.push("--platform")
    build_args.push("linux/arm64")
    build_args.push("-q")
    build_args.push("-t")
    build_args.push("with-aarch64-host")
    build_args.push("tools/docker/linux-aarch64")
    if step("docker image", &build_args) != 0: return 1
    var volume_args: List[str] = List.new()
    volume_args.push("docker")
    volume_args.push("volume")
    volume_args.push("create")
    volume_args.push("with-aarch64")
    if step("docker volume", &volume_args) != 0: return 1
    var run_args: List[str] = List.new()
    run_args.push("docker")
    run_args.push("run")
    run_args.push("--rm")
    // bubblewrap (:no-host-toolchain, in :test) needs namespaces.
    run_args.push("--privileged")
    run_args.push("--platform")
    run_args.push("linux/arm64")
    run_args.push("-v")
    run_args.push("with-aarch64:/work")
    run_args.push("-e")
    run_args.push("GH_TOKEN")
    run_args.push("with-aarch64-host")
    run_args.push("sh")
    run_args.push("-c")
    run_args.push(linux_aarch64_script(version, channel, sha, seed_version, seed_sha))
    step("linux-aarch64 (container)", &run_args)

/// Fetch `url` to `path` and refuse it unless its sha256 is `digest`: the
/// pinned SDK archive and its sidecars, as the CI lanes fetch them.
fn fetch_verified(label: &str, url: &str, path: &str, digest: &str) -> i32:
    var curl: List[str] = List.new()
    for a in ["curl", "-fsSL", "--retry", "5", "-o"]: curl.push(a ++ "")
    curl.push(path ++ "")
    curl.push(url ++ "")
    if step(label, &curl) != 0: return 1
    let check = path ++ ".check"
    if write_file(check, digest ++ "  " ++ path ++ "\n") != 0: return fail("could not write " ++ check)
    var shasum: List[str] = List.new()
    for a in ["shasum", "-a", "256", "-c"]: shasum.push(a ++ "")
    shasum.push(check ++ "")
    let rc = step(label ++ " digest", &shasum)
    remove_file(check)
    rc

/// windows-aarch64, cross-built on the release host. The pinned arm SDK is
/// extracted into .deps when it is missing (its libc is what the compiler
/// links against); the rebuilt darwin compiler cross-builds and stamps the
/// arm compiler; the cross packaging finalizes it; the pinned SDK is
/// republished beside it, as every lane republishes its SDK (D180).
fn windows_aarch64_leg(version: &str, channel: &str) -> i32:
    let root = env("PWD")
    let release = root ++ "/out/release/bin/with"
    let sdk_lock = text_of("sdk.lock")
    let archive = "with-llvm-sdk-22.1.6-windows-aarch64.tar.gz"
    let tag = lock_value(sdk_lock, archive ++ ".version")
    let digest = lock_value(sdk_lock, archive)
    if tag.len() == 0 or digest.len() != 64: return fail("sdk.lock has no windows-aarch64 SDK pin")
    let base = "https://github.com/withlang-dev/with/releases/download/" ++ tag ++ "/" ++ archive
    let staged = "out/release/" ++ archive
    let prefix = ".deps/llvm-22.1.6-windows-aarch64-msvc"
    if not file_exists(prefix ++ "/libc/windows/aarch64-w64-mingw32/lib/crt2.o"):
        if fetch_verified("windows-aarch64 SDK", base, staged, digest) != 0: return 1
        remove_tree(prefix)
        var tar: List[str] = List.new()
        for a in ["tar", "-xzf"]: tar.push(a ++ "")
        tar.push(staged ++ "")
        tar.push("-C")
        tar.push(".deps")
        if step("windows-aarch64 SDK extract", &tar) != 0: return 1
    set_env("WITH", release)
    set_env("WITH_VERSION", version)
    for target in [":cross-winarm-compiler", ":package-windows-aarch64"]:
        let argv = argv3(release, "build", target)
        if step("windows-aarch64 " ++ target, &argv) != 0: return 1
    // The SDK asset and its sidecars, republished verbatim from the pinned
    // SDK release; the digests of all three come from sdk.lock.
    if not file_exists(staged) and fetch_verified("windows-aarch64 SDK", base, staged, digest) != 0: return 1
    for suffix in [".sha256", ".manifest"]:
        let side_digest = lock_value(sdk_lock, archive ++ suffix)
        if side_digest.len() != 64: return fail("sdk.lock has no digest for " ++ archive ++ suffix)
        if fetch_verified("windows-aarch64 SDK" ++ suffix, base ++ suffix, staged ++ suffix, side_digest) != 0: return 1
    publish_env(version, channel, "out/release/with-windows-aarch64.exe",
        staged ++ "," ++ staged ++ ".sha256," ++ staged ++ ".manifest,out/release/with-windows-aarch64-NOTICE.txt",
        "local windows-aarch64 (cross-built on the release host)")
    let publish_argv = argv3(release, "build", ":publish-release-asset")
    step("windows-aarch64 :publish-release-asset", &publish_argv)

fn main -> i32:
    let argv = args()
    if argv.len() < 2: return fail("usage: with run tools/release_local.w vX.Y.Z [--channel release|test] [--skip-darwin] [--skip-linux-aarch64] [--skip-windows-aarch64]")
    let version = argv[1].clone()
    var channel = "release"
    var do_darwin = true
    var do_aarch64 = true
    var do_winarm = true
    var i = 2
    while i < argv.len():
        let a = argv[i].clone()
        if a == "--channel" and i + 1 < argv.len():
            channel = argv[i + 1].clone()
            i += 1
        else if a == "--skip-darwin": do_darwin = false
        else if a == "--skip-linux-aarch64": do_aarch64 = false
        else if a == "--skip-windows-aarch64": do_winarm = false
        else: return fail("unknown argument " ++ a)
        i += 1
    if not version.starts_with("v"): return fail("version must look like vX.Y.Z, got " ++ version)
    if text_of("src/version").trim() != version: return fail("src/version does not say " ++ version ++ "; bump and commit it first")
    if env("GH_TOKEN").len() == 0: return fail("GH_TOKEN is not set")
    if do_darwin and darwin_leg(version, channel) != 0: return 1
    if do_winarm and windows_aarch64_leg(version, channel) != 0: return 1
    if do_aarch64 and linux_aarch64_leg(version, channel) != 0: return 1
    print("release_local: done — CI appends linux-x86_64 and windows-x86_64 on the tag push")
    0
