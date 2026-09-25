// Binary trees: allocation-heavy recursive tree build and check, depth 18.
// Timed region: everything. Checksum: sum of all node counts.
const MIN_DEPTH: u32 = 4;
const MAX_DEPTH: u32 = 18;

struct Node { left: Option<Box<Node>>, right: Option<Box<Node>> }

fn bottom_up(depth: u32) -> Box<Node> {
    if depth == 0 {
        Box::new(Node { left: None, right: None })
    } else {
        Box::new(Node { left: Some(bottom_up(depth - 1)), right: Some(bottom_up(depth - 1)) })
    }
}

fn check(node: &Node) -> i64 {
    let left = node.left.as_ref().map_or(0, |c| check(c));
    let right = node.right.as_ref().map_or(0, |c| check(c));
    1 + left + right
}

fn main() {
    let start = std::time::Instant::now();
    let mut total: i64 = 0;
    let stretch = bottom_up(MAX_DEPTH + 1);
    total += check(&stretch);
    drop(stretch);
    let long_lived = bottom_up(MAX_DEPTH);
    let mut depth = MIN_DEPTH;
    while depth <= MAX_DEPTH {
        let iterations = 1u32 << (MAX_DEPTH - depth + MIN_DEPTH);
        for _ in 0..iterations {
            let tree = bottom_up(depth);
            total += check(&tree);
        }
        depth += 2;
    }
    total += check(&long_lived);
    let elapsed_ms = start.elapsed().as_secs_f64() * 1000.0;
    println!("max_depth {}", MAX_DEPTH);
    println!("elapsed_ms {:.3}", elapsed_ms);
    println!("checksum {}", total);
}
