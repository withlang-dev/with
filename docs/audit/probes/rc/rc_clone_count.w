// Probe: Rc strong_count transitions and shared aliasing.
// Note: explicit `*rc` is rejected (unary `*` is only for &T/raw ptrs);
// the sanctioned spellings are auto-deref and as_ref()/deref().
use std.rc.Rc
use std.builtins.print

type Point { x: i32, y: i32 }

fn main:
    let a = Rc.new(Point { x: 3, y: 4 })
    assert(a.strong_count() == 1)
    {
        let b = a.clone()
        assert(a.strong_count() == 2)
        assert(b.strong_count() == 2)
        {
            let c = b.clone()
            assert(a.strong_count() == 3)
            assert(c.x == 3)
            assert(c.as_ref().y == 4)
            assert(c.deref().x == 3)
        }
        assert(a.strong_count() == 2)
        assert(b.x == 3)
        assert(b.y == 4)
    }
    assert(a.strong_count() == 1)
    assert(a.x == 3)
    assert(a.as_ref().y == 4)
    print("rc-clone-count-ok")
