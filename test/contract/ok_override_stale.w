//! expect-contract: violations=0 ok
//! expect-contract: stale override at test/contract/ok_override_stale.w:18: `runs no threads`; no proof contradicts it, so `override` can be deleted
//! expect-contract: stale override at test/contract/ok_override_stale.w:20: `from` on `Engine`; no proof contradicts it, so `override` can be deleted
//! expect-contract: stale override at test/contract/ok_override_stale.w:23: `lend` on `engine_count`; no proof contradicts it, so `override` can be deleted
//! expect-contract: overrides=0 stale-overrides=3

// §31.7: `override` before a grant suppresses the contradiction error for
// that one clause. With no contradicting proof it is stale: accepted,
// reported by the audit, counted in its own bucket, and never a claim.
use c_import("typedef struct engine engine;
engine *engine_new(void);
void engine_free(engine *e);
int engine_count(engine *e);
int engine_name(engine *e);
")

c contract engine:
    override runs no threads
    resource Engine wraps *mut engine
        override from engine_new
        drop engine_free
    fn engine_count
        override lend
    fn engine_name

fn main:
    let Some(e) = Engine.new() else:
        return
    print(e.count() + e.name())
