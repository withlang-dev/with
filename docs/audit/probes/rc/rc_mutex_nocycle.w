// Minimal: Rc of a struct containing a Mutex, no cycle, no set.
use std.rc.Rc
use std.sync.Mutex
use std.builtins.print

type M { id: i32, link: Mutex[i32] }

fn main:
    {
        let a = Rc.new(M { id: 1, link: Mutex.new(0) })
        assert(a.strong_count() == 1)
        assert(a.id == 1)
    }
    print("rc-mutex-nocycle-ok")
