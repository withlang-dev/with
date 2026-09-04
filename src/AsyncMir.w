// AsyncMir — Wave 9 suspend-aware IR artifact.
//
// Async-MIR is a deterministic, explicit view of async/generator lowering
// boundaries produced after MIR/borrow phases.

use InternPool
extern fn with_str_clone_ref(s: &str) -> str

// Async body flavors.
enum AsyncBodyKind: i32:
    Sync = 0
    Async = 1
    Generator = 2

// Suspension/event kinds.
enum AsyncSuspendKind: i32:
    Await = 1
    SelectAwait = 2
    Yield = 3

type AsyncMirBody {
    fn_sym: i32,
    flavor: i32,
    state_count: i32,

    suspend_kinds: Vec[i32],
    suspend_span_starts: Vec[i32],
    suspend_span_ends: Vec[i32],
    suspend_resume_bbs: Vec[i32],
    suspend_state_from: Vec[i32],
    suspend_state_to: Vec[i32],

    // Storage/drop accounting snapshot near each suspend boundary.
    suspend_live_locals: Vec[i32],
    suspend_storage_dead: Vec[i32],
    suspend_drop_counts: Vec[i32],
}

type AsyncMirModule {
    bodies: Vec[AsyncMirBody],
    body_fn_syms: Vec[i32],
}

fn AsyncMirBody.init(fn_sym: i32, flavor: i32) -> AsyncMirBody:
    AsyncMirBody {
        fn_sym,
        flavor,
        state_count: 1,
        suspend_kinds: Vec.new(),
        suspend_span_starts: Vec.new(),
        suspend_span_ends: Vec.new(),
        suspend_resume_bbs: Vec.new(),
        suspend_state_from: Vec.new(),
        suspend_state_to: Vec.new(),
        suspend_live_locals: Vec.new(),
        suspend_storage_dead: Vec.new(),
        suspend_drop_counts: Vec.new(),
    }

impl AsyncMirBody:
    fn add_suspend(kind: i32, span_start: i32, span_end: i32, resume_bb: i32, live_locals: i32, storage_dead: i32, drop_count: i32) -> Unit:
        let idx = self.suspend_kinds.len() as i32
        self.suspend_kinds.push(kind)
        self.suspend_span_starts.push(span_start)
        self.suspend_span_ends.push(span_end)
        self.suspend_resume_bbs.push(resume_bb)
        self.suspend_state_from.push(idx)
        self.suspend_state_to.push(idx + 1)
        self.suspend_live_locals.push(live_locals)
        self.suspend_storage_dead.push(storage_dead)
        self.suspend_drop_counts.push(drop_count)

    mut fn finalize_states():
        self.state_count = self.suspend_kinds.len() as i32 + 1

    fn suspend_count() -> i32:
        self.suspend_kinds.len() as i32

    fn has_kind(kind: i32) -> bool:
        for i in 0..self.suspend_kinds.len() as i32:
            if self.suspend_kinds[i] == kind:
                return true
        false

fn AsyncMirModule.init -> AsyncMirModule:
    AsyncMirModule {
        bodies: Vec.new(),
        body_fn_syms: Vec.new(),
    }

// No-op: reserved for future manual memory management.
impl AsyncMirModule:
    fn deinit():
        return

    fn add_body(body: AsyncMirBody) -> Unit:
        let fn_sym = body.fn_sym
        self.bodies.push(move body)
        self.body_fn_syms.push(fn_sym)

    fn body_count() -> i32:
        self.bodies.len() as i32

    fn total_suspend_points() -> i32:
        var total = 0
        for i in 0..self.bodies.len() as i32:
            total = total + self.bodies[i].suspend_count()
        total

    fn requires_async_runtime() -> bool:
        for i in 0..self.bodies.len() as i32:
            let body = &self.bodies[i]
            if body.flavor == AsyncBodyKind.Async:
                return true
            if body.has_kind(AsyncSuspendKind.Await) or body.has_kind(AsyncSuspendKind.SelectAwait):
                return true
        false

fn async_body_flavor_name(flavor: i32) -> str:
    if flavor == AsyncBodyKind.Async:
        return "async"
    if flavor == AsyncBodyKind.Generator:
        return "generator"
    "sync"

fn async_suspend_kind_name(kind: i32) -> str:
    if kind == AsyncSuspendKind.Await:
        return "await"
    if kind == AsyncSuspendKind.SelectAwait:
        return "select_await"
    if kind == AsyncSuspendKind.Yield:
        return "yield"
    "unknown"

fn dump_async_mir_module(mod: &AsyncMirModule, pool: InternPool) -> str:
    var out = ""
    out = out ++ f"async-mir module bodies={mod.body_count()}"
    out = out ++ f" suspend_points={mod.total_suspend_points()}\n"

    for bi in 0..mod.bodies.len() as i32:
        let body = &mod.bodies[bi]
        if bi > 0:
            out = out ++ "\n"

        let fn_name = if body.fn_sym != 0: with_str_clone_ref(pool.resolve(body.fn_sym)) else: "<anon>"
        out = out ++ "fn " ++ fn_name
        out = out ++ " flavor=" ++ async_body_flavor_name(body.flavor)
        out = out ++ f" states={body.state_count}"
        out = out ++ f" suspend_points={body.suspend_count()}\n"

        for si in 0..body.suspend_count():
            out = out ++ f"  suspend[{si}] "
            out = out ++ async_suspend_kind_name(body.suspend_kinds[si])
            out = out ++ f" span={body.suspend_span_starts[si]}"
            out = out ++ f"..{body.suspend_span_ends[si]}"
            out = out ++ f" state={body.suspend_state_from[si]}"
            out = out ++ f"->{body.suspend_state_to[si]}"
            out = out ++ f" resume_bb={body.suspend_resume_bbs[si]}"
            out = out ++ f" live={body.suspend_live_locals[si]}"
            out = out ++ f" dead={body.suspend_storage_dead[si]}"
            out = out ++ f" drops={body.suspend_drop_counts[si]}"
            out = out ++ "\n"

    out
