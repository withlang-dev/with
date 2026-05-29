// Spec test: Section 3.8 — Auto-Referencing (formerly 25.91)

fn auto_ref_len(s: &str) -> i64:
    s.len()

type AutoRefPoint { x: i32, y: i32 }

impl AutoRefPoint:
    fn sum(self: &Self) -> i32:
        self.x + self.y

fn test_auto_ref_shared_borrow_parameter:
    let name: str = "Alice"
    assert(auto_ref_len(name) == 5)

fn test_auto_ref_method_receiver:
    let p = AutoRefPoint { x: 3, y: 4 }
    assert(p.sum() == 7)
