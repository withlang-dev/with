module build.release_uat

use std.build
use std.sysinfo

// The release UATs themselves are `uat/*.uat`, run by `with uat` (spec
// §18.5d; build.w run_release_uat_action). What stays here is the one
// artifact step they consume: the platform-named release asset.

fn ruat_fail(ctx: &ActionCtx, message: &str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)

fn ruat_compiler_input_rel(ctx: &ActionCtx) -> str:
    let inputs = ctx.inputs()
    if inputs.len() == 0:
        return ""
    inputs.get(0) ++ ""

// Produce the platform-named release asset from the verified release
// compiler. The release UATs consume this asset; producing it in the build
// graph guarantees the gates always test the current build instead of a
// stale hand-copied binary (#551).
pub fn run_release_platform_asset_action(ctx: ActionCtx) -> i32:
    let compiler_rel = ruat_compiler_input_rel(ctx)
    if compiler_rel.len() == 0:
        return ruat_fail(ctx, "missing release compiler input")
    let asset = ctx.output()
    if ctx.fs().copy_file(compiler_rel, asset) != 0:
        return ruat_fail(ctx, "could not copy release compiler to platform asset: " ++ asset)
    if os() != "Windows" and ctx.fs().chmod(asset, 0o755) != 0:
        return ruat_fail(ctx, "could not chmod platform asset: " ++ asset)
    0
