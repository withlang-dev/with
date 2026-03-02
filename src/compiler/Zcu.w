use InternPool
use Diagnostic
use Resolve

extern fn with_eprintln(s: str) -> void

// Zig Compilation Unit (ZCU) state for the With compiler.
//
// This is the canonical per-compilation owner of interned semantic state,
// diagnostics, and source/import context.
type Zcu = {
    pool: InternPool,
    diagnostics: DiagnosticList,
    imported_paths: HashMap[str, i32],
    source_dir: str,
    next_file_id: i32,
    current_source_path: str,
    current_source_text: str,
    pending_warnings: Vec[str],
    last_resolved: ResolveResult,
    resolved_root_path: str,
}

fn Zcu.init -> Zcu:
    Zcu {
        pool: InternPool.init(),
        diagnostics: DiagnosticList.init(),
        imported_paths: HashMap.new(),
        source_dir: ".",
        next_file_id: 1,
        current_source_path: "<unknown>",
        current_source_text: "",
        pending_warnings: Vec.new(),
        last_resolved: ResolveResult.init(),
        resolved_root_path: "",
    }

fn Zcu.reset_import_state(self: Zcu):
    self.imported_paths = HashMap.new()
    self.next_file_id = 1

fn Zcu.print_warnings(self: Zcu):
    for i in 0..self.pending_warnings.len() as i32:
        with_eprintln(self.pending_warnings.get(i as i64))
