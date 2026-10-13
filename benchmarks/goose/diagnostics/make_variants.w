use std.fs

const ROOT = "out/benchmarks/goose/root-causes/"
fn save(name: &str, source: &str):
    if write_file(ROOT ++ name ++ ".w", source) != 0: panic("write failed")
fn load(name: &str): read_file("out/benchmarks/goose/" ++ name ++ "_medium_with.w").unwrap()

let sum = load("sum")
save("sum_index", sum.replace("for x in data: total += x ^ p", "for i in 0..data.len(): total += data[i] ^ p"))
save("sum_reserve", sum.replace("Vec.new()", "Vec.with_capacity(N)"))
save("push_reserve", load("push").replace("var items: Vec[Item] = Vec.new()", "var items: Vec[Item] = Vec.with_capacity(N)").replace("var marks: Vec[i64] = Vec.new()", "var marks: Vec[i64] = Vec.with_capacity(N / 64 + 1)"))
let materialization = "var words: Vec[str] = Vec.new()\n    for word in source.split(\" \"):\n        if word.len() > 0: words.push(word.clone())"
let direct = "var words = source.split(\" \")\n    words.pop()"
save("strlist_direct", load("strlist").replace(materialization, direct))
save("words_direct", load("words").replace(materialization, direct))
let reuse = "\nimpl Tree:\n    mut fn measure(depth: i64) -> i64:\n        self.nodes.clear()\n        let root = self.build(depth)\n        self.check(root)\n"
let trees = load("bintrees").replace("fn main:\n", "fn main:\n    var work = Tree { nodes: Vec.new() }\n").replace("print(tree_check(MAXDEPTH + 1))", "print(work.measure(MAXDEPTH + 1))").replace("sum += tree_check(depth)", "sum += work.measure(depth)")
save("bintrees_reuse", trees ++ reuse)
let calc = load("calc").replace("var nodes: i64 = 0\n", "var nodes: i64 = 0\n    var pool: Vec[Expr] = Vec.new()\n").replace("pos: 0, nodes: Vec.new()", "pos: 0, nodes: move pool").replace("nodes += parser.nodes.len()", "nodes += parser.nodes.len()\n        pool = move parser.nodes\n        pool.clear()")
save("calc_reuse", calc)
save("scene_index", load("scene").replace("for node in scene.nodes: total += (node.world.x + node.world.y + node.world.z) as i64", "for j in 0..scene.nodes.len(): total += (scene.nodes[j].world.x + scene.nodes[j].world.y + scene.nodes[j].world.z) as i64"))
save("records_index", load("records").replace("for event in log:", "for j in 0..log.len():\n            let event = log[j]"))
save("records_reserve", load("records").replace("var log: Vec[Event] = Vec.new()", "var log: Vec[Event] = Vec.with_capacity(N)"))
let graph = load("graph").replace("var esrc: Vec[i32] = Vec.new()", "var esrc: Vec[i32] = Vec.with_capacity(ne)").replace("var edst: Vec[i32] = Vec.new()", "var edst: Vec[i32] = Vec.with_capacity(ne)").replace("var start: Vec[i32] = Vec.new()", "var start: Vec[i32] = Vec.with_capacity(V + 1)").replace("var out: Vec[i32] = Vec.new()", "var out: Vec[i32] = Vec.with_capacity(ne)").replace("var dist: Vec[i32] = Vec.new()", "var dist: Vec[i32] = Vec.with_capacity(V)").replace("var q: Vec[i32] = Vec.new()", "var q: Vec[i32] = Vec.with_capacity(V)")
save("graph_reserve", graph)
save("tree_reserve", load("tree").replace("nodes: Vec.new()", "nodes: Vec.with_capacity(2097151)"))
save("interp_reserve", load("interp").replace("nodes: Vec.new()", "nodes: Vec.with_capacity(2097151)"))
