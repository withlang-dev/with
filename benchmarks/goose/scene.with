use common

const DEPTH: i64 = 12 // BENCH_N
type Xf { m: [f32; 9], x: f32, y: f32, z: f32 }
impl Copy for Xf
type Node { id: i32, local: Xf, world: Xf, kids: [i32; 4], count: i64 }
type Scene { nodes: Vec[Node] }

fn identity() -> Xf:
    Xf { m: [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0], x: 0.0, y: 0.0, z: 0.0 }

fn rotation(seed: u64) -> [f32; 9]:
    let axis = xs_mod(seed, 3)
    let quarter = xs_mod(seed >> 8, 4)
    var c: f32 = 1.0
    var s: f32 = 0.0
    if quarter == 1:
        c = 0.0
        s = 1.0
    else if quarter == 2:
        c = -1.0
    else if quarter == 3:
        c = 0.0
        s = -1.0
    if axis == 0: return [1.0, 0.0, 0.0, 0.0, c, 0.0 - s, 0.0, s, c]
    if axis == 1: return [c, 0.0, s, 0.0, 1.0, 0.0, 0.0 - s, 0.0, c]
    [c, 0.0 - s, 0.0, s, c, 0.0, 0.0, 0.0, 1.0]

fn compose(p: &Xf, l: &Xf) -> Xf:
    var w = identity()
    for i in 0..3:
        for j in 0..3:
            var s: f32 = 0.0
            for k in 0..3: s = s + p.m[i * 3 + k] * l.m[k * 3 + j]
            w.m[i * 3 + j] = s
    w.x = p.m[0] * l.x + p.m[1] * l.y + p.m[2] * l.z + p.x
    w.y = p.m[3] * l.x + p.m[4] * l.y + p.m[5] * l.z + p.y
    w.z = p.m[6] * l.x + p.m[7] * l.y + p.m[8] * l.z + p.z
    w

impl Scene:
    mut fn build(depth: i64, seed: u64) -> i32:
        let r = xs_next(seed)
        let id = self.nodes.len() as i32
        self.nodes.push(Node { id: id, local: Xf { m: rotation(r), x: xs_mod(r >> 16, 9) as f32, y: xs_mod(r >> 24, 9) as f32, z: xs_mod(r >> 32, 9) as f32 }, world: identity(), kids: [-1; 4], count: 0 })
        if depth > 0:
            let n = 1 + xs_mod(r >> 40, 4)
            for i in 0..n:
                let child = self.build(depth - 1, xs_next(r +% (i as u64)))
                self.nodes[id].kids[i] = child
            self.nodes[id].count = n
        id

    mut fn update(index: i32, parent: Xf):
        let local: Xf = self.nodes[index].local
        let world = compose(parent, local)
        self.nodes[index].world = world
        let count: i64 = self.nodes[index].count
        for i in 0..count:
            let child: i32 = self.nodes[index].kids[i]
            self.update(child, world)

fn main:
    var scene = Scene { nodes: Vec.new() }
    let root = scene.build(DEPTH, 12345)
    var total: i64 = 0
    for frame in 0..16:
        let step = (frame % 5) as f32
        for i in 0..scene.nodes.len():
            if scene.nodes[i].id % 7 == frame % 7:
                scene.nodes[i].local.x = step
                scene.nodes[i].local.z = 8.0 - step
        scene.update(root, identity())
        for node in scene.nodes: total += (node.world.x + node.world.y + node.world.z) as i64
    print(scene.nodes.len())
    print(total)
