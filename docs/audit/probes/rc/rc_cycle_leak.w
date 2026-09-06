// Probe: an Rc cycle through Mutex interior mutability is uncollectable.
// Both roots dropped, yet the two nodes keep each other alive → leak.
// There is no Weak[T] in std.rc, so this is inherent, not a bug.
use std.rc.Rc
use std.sync.Mutex
use std.builtins.print

type N { id: i32, link: Mutex[Option[Rc[N]]] }

fn main:
    {
        let e1: Option[Rc[N]] = .None
        let e2: Option[Rc[N]] = .None
        let a = Rc.new(N { id: 1, link: Mutex.new(e1) })
        let b = Rc.new(N { id: 2, link: Mutex.new(e2) })
        let ab: Option[Rc[N]] = .Some(b.clone())
        let ba: Option[Rc[N]] = .Some(a.clone())
        a.link.set(ab)
        b.link.set(ba)
        assert(a.strong_count() == 2)
        assert(b.strong_count() == 2)
    }
    print("rc-cycle-roots-dropped")
