module build.sema_order

// Declaration-order independence of type checking (#1941): the release
// compiler checks every test/compile_errors fixture as written and with
// top-level bodies in reverse order; tools/sema_order_check.w fails on a
// difference the spec does not order (test/sema_order_allowlist.txt).

use std.build

fn so_join(left: &str, right: &str) -> str:
    if left.ends_with("/"): left ++ right else: left ++ "/" ++ right

fn so_abs(root: &str, path: &str) -> str:
    if path.len() > 0 and path[0] == '/': return path.clone()
    so_join(root, path)

pub fn run_sema_order_check_action(ctx: ActionCtx) -> i32:
    let fs = ctx.fs()
    let out_dir = ctx.output()
    if fs.mkdir_all(out_dir) != 0:
        ctx.diagnostics().error("sema-order-check: could not create " ++ out_dir)
    let root = ctx.project_info().project_root()
    let compiler = so_abs(root, ctx.inputs()[0])
    var args: List[str] = List.new()
    args.push(compiler.clone())
    args.push("run")
    args.push("tools/sema_order_check.w")
    args.push(compiler.clone())
    args.push(so_abs(root, out_dir))
    let out_rel = so_join(out_dir, "check.stdout")
    let result = ctx.process_runner().run_capture_cwd(args, so_abs(root, out_rel), so_abs(root, so_join(out_dir, "check.stderr")), 600000, root)
    let report = fs.read_text(out_rel)
    if result.rc != 0:
        ctx.diagnostics().error(f"sema-order-check: failed (rc={result.rc})\n" ++ report)
    print(report)
    0
