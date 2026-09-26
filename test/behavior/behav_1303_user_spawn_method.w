//! expect-stdout: 1
//! expect-stdout: 2

// #1303 (§18.2): a type's own `spawn` method wins over the scope-handle
// builtin; the builtin applies only when nothing else resolves.

type World { next_id: i32 = 0 }

extend World:
    mut fn spawn(name: str) -> i32:
        self.next_id += 1
        self.next_id
    mut fn spawn_player() -> i32:
        self.spawn("player")

fn main:
    var w = World {}
    print(f"{w.spawn_player()}")
    print(f"{w.spawn("npc")}")
