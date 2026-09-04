// with run tools/bump_seed_pins.w
//
// Rewrites every seed pin in .github/workflows/*.yml from seed.lock: each
// `seed_version:` / `WITH_SEED_VERSION:` line takes the lock's version and
// each `seed_sha256:` / `WITH_SEED_SHA256:` line takes the lock's digest for
// the asset named on the nearest `seed_asset:` / `WITH_SEED_ASSET:` line of
// the same block (the asset line sits between the version and the digest in
// every block shape we have). `with build :seed-compat` refuses while any
// pin disagrees with the lock, so bumping a seed is: edit seed.lock, run
// this, commit both.
use std.fs
use std.process
use std.builtins.write

fn lock_value(lock: &str, key: &str) -> str:
    for line in lock.split("\n"):
        let l = line.trim()
        if l.starts_with("#") or l.len() == 0: continue
        let eq = l.index_of("=")
        if eq > 0 and l.slice(0, eq) == key: return l.slice(eq + 1, l.len())
    ""

fn value_after(line: &str, key: &str) -> str:
    let at = line.index_of(key)
    if at < 0: return ""
    line.slice(at + key.len(), line.len()).trim()

fn key_prefix(line: &str, key: &str) -> str:
    let at = line.index_of(key)
    line.slice(0, at + key.len())

/// The seed version an asset is pinned to: `<asset>.version=` when the lock
/// carries one (a platform that cannot bootstrap the newest seed yet), else
/// `version=`.
fn version_for(lock: &str, asset: &str) -> str:
    let own = lock_value(lock, asset ++ ".version")
    if own.len() > 0: own else: lock_value(lock, "version")

/// The asset named by the pin block whose version line is `lines[i]`: the
/// asset line within the next few lines (every block shape names the asset
/// after the version and before the digest).
fn block_asset(lines: &Vec[str], i: i64) -> str:
    var j = i + 1
    while j < lines.len() and j <= i + 4:
        for akey in ["seed_asset:", "WITH_SEED_ASSET:"]:
            if lines.get(j).contains(akey): return value_after(lines.get(j), akey)
        j = j + 1
    ""

/// The file with its pins rewritten, or "" when a digest line names an asset
/// the lock does not carry (reported on stderr).
fn rewrite(path: &str, text: &str, lock: &str) -> str:
    let lines = text.split("\n")
    var pending_asset = ""
    var out = ""
    for i in 0..lines.len():
        let line = lines.get(i)
        let nr = i + 1
        var emitted = line ++ ""
        if not line.contains("${{"):
            for vkey in ["seed_version:", "WITH_SEED_VERSION:"]:
                if line.contains(vkey):
                    // The block's asset: named after the version in most blocks,
                    // before it (with comments between) in selfhost-linux-aarch64.
                    var asset = block_asset(&lines, i)
                    if asset.len() == 0: asset = pending_asset ++ ""
                    emitted = key_prefix(line, vkey) ++ " " ++ version_for(lock, asset)
            for akey in ["seed_asset:", "WITH_SEED_ASSET:"]:
                if line.contains(akey): pending_asset = value_after(line, akey)
            for skey in ["seed_sha256:", "WITH_SEED_SHA256:"]:
                if line.contains(skey):
                    let digest = lock_value(lock, pending_asset)
                    if digest.len() != 64:
                        eprint(f"{path}:{nr}: no 64-hex digest in seed.lock for asset '{pending_asset}'")
                        return ""
                    emitted = key_prefix(line, skey) ++ " " ++ digest
        out = out ++ emitted ++ "\n"
    if text.ends_with("\n") and out.ends_with("\n\n"): out = out.slice(0, out.len() - 1)
    out

let lock = read_file("seed.lock") ?? ""
let version = lock_value(lock, "version")
if version.len() == 0:
    eprint("seed.lock has no version= line")
    exit_code(2)
var changed = 0
var failed = 0
for path in list_files_text(".github/workflows").split("\n"):
    if not path.ends_with(".yml"): continue
    let text = read_file(path) ?? ""
    let out = rewrite(path, text, lock)
    if out.len() == 0:
        failed = failed + 1
        continue
    if out != text:
        if write_file(path, out) != 0:
            eprint("could not write " ++ path)
            exit_code(1)
        print("bumped " ++ path)
        changed = changed + 1
if failed > 0: exit_code(1)
print(f"seed pins at {version}: {changed} file(s) changed")
