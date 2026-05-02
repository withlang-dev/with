// Test: §2.4 user-defined IndexPlace trait dispatch

type Grid {
    data: Vec[i32],
    width: i32,
}

impl IndexPlace[i32, i32] for Grid:
    fn get(self: &Self, index: i32) -> i32:
        self.data.get(index)

    fn set(mut self: Self, index: i32, value: i32):
        with self.data.slot(index) as mut s:
            s.set(value)

fn counter_inc(p: *mut i32) -> i32:
    unsafe:
        let v = *p
        *p = v + 1
        v

fn test_index_place_read:
    var g = Grid { data: Vec.new(), width: 3 }
    g.data.push(1)
    g.data.push(2)
    g.data.push(3)
    assert(g[0] == 1)
    assert(g[1] == 2)
    assert(g[2] == 3)

fn test_index_place_write:
    var g = Grid { data: Vec.new(), width: 3 }
    g.data.push(1)
    g.data.push(2)
    g.data.push(3)
    g[1] = 42
    assert(g[1] == 42)
    assert(g[0] == 1)
    assert(g[2] == 3)

fn test_index_place_compound:
    var counter = 0
    var g = Grid { data: Vec.new(), width: 3 }
    g.data.push(1)
    g.data.push(2)
    g.data.push(3)
    g[counter_inc(&raw mut counter)] += 100
    assert(counter == 1)
    assert(g[0] == 101)
    assert(g[1] == 2)
    assert(g[2] == 3)
