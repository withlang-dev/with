//! expect-stdout: 8
//! expect-stdout: 12

// A labeled block allocates its blocks before the statements ahead of it
// create theirs, so a List literal declared just before it defines its
// local in a higher-numbered block than the one the labeled body reads it
// in. Codegen emits blocks in reverse postorder (the defining block first),
// where emitting by number refused the store ("cannot lower projected
// assignment") — the migrator's goto-lowered pcre2_substitute, whose
// hoisted buffers are List fills, built nothing.

type Blk { a: u32 = 0, offs: [u64; 2] = [0 as u64; 2] }

fn f(n: i32) -> u64:
    var scb: Blk = Blk {}
    var temp: List[u8] = [0; 6]
    var off: u64 = 5
    '__bb_1 {
        scb.offs[0] = off
        temp[1] = n as u8
    }
    scb.offs[0] + temp[1] as u64

fn g(n: i32) -> i32:
    var acc: List[i32] = [1, 2, 3]
    var total = 0
    'outer {
        for x in acc:
            if x == 2: break 'outer
            total = total + x
    }
    acc[2] = n
    total + acc[2] + acc[1]

fn main:
    print(f(3))
    print(g(9))
