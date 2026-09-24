//! expect-stdout: independent: snapshot 11 kept past its database: c1:0 s11
//! expect-stdout: stored: 12
//! expect-stdout: link live: true
//! expect-stdout: borrows param 0: second database closed first: c3:0 l63 c2:0
//! expect-stdout: backup live: true
//! expect-stdout: two parents: b73 c4:0 c3:0
//! expect-stdout: cursors live: true true
//! expect-stdout: optional parent: k9 k8 c5:0
//! expect-stdout: iterator live: true
//! expect-stdout: in place: t10 c6:0
//! expect-stdout: ok

// D51 stage 6 (ruling §27, §28; spec §16.2b.6), the forms of dependency:
// - `independent`: a snapshot depends on nothing it was made from, so it is
//   an ordinary resource — kept past its database's scope and stored in a
//   struct;
// - `borrows param 0`: a link depends on the database it was made on, not
//   on the second one its producer also receives, so the second may close
//   while the link lives;
// - two parents by default: a backup depends on both databases and finishes
//   before either closes;
// - a cursor made over a database or blank over none: one resource whose
//   producers differ, so its parent is optional;
// - an in-place resource whose `init` receives the database.
// The C side logs every destroy: cD:open for a close with the dependents
// still open, sNN snapshot, lNN link, bNN backup, kNN cursor, tNN iterator.

use c_import("c_facade_children.h")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Snapshot wraps *mut snap
        from snap_take
        drop snap_free
        independent
    resource Link wraps *mut lk
        from link_new
        drop link_free
        borrows param 0
    resource Backup wraps *mut bk
        from backup_init
        drop backup_finish
    resource Cursor wraps *mut cur
        from cur_open
        from cur_blank
        drop cur_close
    resource Iter wraps iter_state
        init it_init(self)
        drop it_end
    fn snap_id
        lend

type Keeper { snap: Snapshot }

fn witness(l: Log) -> str:
    var out = ""
    for i in 0..log_len(l):
        let e = log_at(l, i)
        let kind = e / 1000
        let n = e % 1000
        let word = if kind == 2: f"c{n / 10}:{n % 10}" else: if kind == 4: f"s{n}" else: if kind == 5: f"l{n}" else: if kind == 6: f"b{n}" else: if kind == 7: f"k{n}" else: f"t{n}"
        out = out ++ (if out.len() > 0: " " else: "") ++ word
    out

fn take_snapshot(l: Log, id: i32) -> Snapshot:
    let db = Database.new(l, id).unwrap()
    Snapshot.take(db, 1).unwrap()

fn main:
    let l = log_new()
    let kept = take_snapshot(l, 1)
    let sid = kept.id()
    drop(kept)
    print(f"independent: snapshot {sid} kept past its database: {witness(l)}")
    log_reset(l)
    let keeper = Keeper { snap: take_snapshot(l, 2) }
    print(f"stored: {keeper.snap.id()}")
    drop(keeper)
    log_reset(l)
    if true:
        let a = Database.new(l, 2).unwrap()
        var link: Option[Link] = None
        if true:
            let b = Database.new(l, 3).unwrap()
            link = Link.link_new(a, b, 6)
        print(f"link live: {link.is_some()}")
    print(f"borrows param 0: second database closed first: {witness(l)}")
    log_reset(l)
    if true:
        let src = Database.new(l, 3).unwrap()
        let dest = Database.new(l, 4).unwrap()
        let backup = Backup.backup_init(dest, src, 7)
        print(f"backup live: {backup.is_some()}")
    print(f"two parents: {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.new(l, 5).unwrap()
        let blank = Cursor.blank(l, 8)
        let opened = Cursor.open(db, 9)
        print(f"cursors live: {blank.is_some()} {opened.is_some()}")
    print(f"optional parent: {witness(l)}")
    log_reset(l)
    if true:
        let db = Database.new(l, 6).unwrap()
        let iter = Iter.it_init(db, 10)
        print(f"iterator live: {iter.live}")
    print(f"in place: {witness(l)}")
    log_free(l)
    print("ok")
