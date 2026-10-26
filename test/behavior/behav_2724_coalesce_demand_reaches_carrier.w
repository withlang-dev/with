//! expect-stdout: 12 24 31 43 | 8 9
// #2724 (D103): a demand on a `??` reaches its carrier as a hint, and a `??`
// in an arithmetic operand takes the peer's numeric type as one, so a
// generic call whose type parameter only its result names infers there as
// under a typed binding. Both were "cannot infer type parameter 'T'". A
// `??` over a narrower payload still widens as before (8 9).
use std.collections.HashMap

trait FromText:
    fn from_text(s: &str) -> Option[Self]
impl FromText for i64:
    fn from_text(s: &str) -> Option[i64]: if s == "12": Some(12) else if s == "7": Some(7) else: None
fn parse_as[T: FromText](s: &str) -> Option[T]: T.from_text(s)

fn main:
    let a: i64 = parse_as("12") ?? 0
    var total: i64 = a
    total = total + (parse_as("12") ?? 0)
    total += parse_as("7") ?? 0
    let c = (parse_as("12") ?? 0) + total
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("k", 3)
    let w: i64 = 5
    let z = w + (m.get("k") ?? 0)
    let y = (m.get("q") ?? 4) + w
    print(f"{a} {total - 7} {total} {c} | {z} {y}")
