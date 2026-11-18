//! expect-stdout: first 1 150 150
//! expect-stdout: rest 1 150 150 44
//! expect-stdout: failed Failed(7)

// #3173, D210 (§16.2b.8, §16.2b.4): a pointer resource, an 8-bit count
// field and an 'ok' with two statuses. A slice longer than the count field
// can state is passed in part and the result says how much moved; it is
// never truncated silently. With several 'ok' statuses the one that matched
// is in the result; another status is the operation's error.
use c_import("enum { ST_OK = 0, ST_END = 1 };\ntypedef struct { const unsigned char *next_in; unsigned char avail_in; unsigned char *next_out; unsigned char avail_out; } narrow;\nstatic inline narrow *narrowNew(void) { static narrow n; n.next_in = 0; n.avail_in = 0; n.next_out = 0; n.avail_out = 0; return &n; }\nstatic inline void narrowFree(narrow *s) { s->avail_in = 0; }\nstatic inline int narrowCopy(narrow *s) { while (s->avail_in > 0 && s->avail_out > 0) { *s->next_out++ = *s->next_in++; s->avail_in--; s->avail_out--; } return s->avail_in == 0 ? ST_END : ST_OK; }\nstatic inline int narrowFail(narrow *s) { return 7; }\n")

c contract nr:
    resource Narrow wraps *mut narrow
        from narrowNew
        drop narrowFree
    fn narrowCopy
        lend
        rename pump
        ok ST_OK, ST_END
        buffer field next_in remaining field avail_in
        buffer field next_out remaining field avail_out
    fn narrowFail
        lend
        rename fail
        ok ST_OK
        buffer field next_in remaining field avail_in

fn main:
    let n = Narrow.new().unwrap()
    var input: [u8; 300] = [0; 300]
    for i in 0..300: input[i] = (i % 200) as u8
    var output: [u8; 300] = [0; 300]
    let a = n.pump(input, output).unwrap()
    print(f"first {a.status} {a.consumed} {a.produced}")
    var rest: [u8; 300] = [0; 300]
    let b = n.pump(input[150..], rest).unwrap()
    print(f"rest {b.status} {b.consumed} {b.produced} {rest[94]}")
    match n.fail(input):
        Ok(_) => print("unexpected")
        Err(e) => print(f"failed {e}")
