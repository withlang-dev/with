use std.rc

type SharedCell {
    value: Arc[i32],
}

type LocalCell {
    value: Rc[i32],
}

type NestedArcRc = Arc[Rc[i32]]

const I32_SEND: bool = comptime i32.implements(Send)
const I32_SYNC: bool = comptime i32.implements(Sync)
const I32_SCOPED: bool = comptime i32.implements(ScopedSend)
const ARC_SEND: bool = comptime Arc[i32].implements(Send)
const ARC_SYNC: bool = comptime Arc[i32].implements(Sync)
const ARC_SCOPED: bool = comptime Arc[i32].implements(ScopedSend)
const RC_SEND: bool = comptime Rc[i32].implements(Send)
const RC_SYNC: bool = comptime Rc[i32].implements(Sync)
const RC_SCOPED: bool = comptime Rc[i32].implements(ScopedSend)
const ARC_RC_SEND: bool = comptime NestedArcRc.implements(Send)
const SHARED_CELL_SEND: bool = comptime SharedCell.implements(Send)
const SHARED_CELL_SYNC: bool = comptime SharedCell.implements(Sync)
const LOCAL_CELL_SEND: bool = comptime LocalCell.implements(Send)

fn main:
    if I32_SEND and I32_SYNC and I32_SCOPED and ARC_SEND and ARC_SYNC and ARC_SCOPED and not RC_SEND and not RC_SYNC and not RC_SCOPED and not ARC_RC_SEND and SHARED_CELL_SEND and SHARED_CELL_SYNC and not LOCAL_CELL_SEND:
        print("send-sync-structural")
    else:
        print("bad")
