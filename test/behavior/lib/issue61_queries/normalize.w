pub fn edge_score(name: str) -> i32:
    let lower = name.trim().to_lower()
    var total = 0
    if lower.starts_with("a"):
        total = total + 1
    if lower.ends_with("a"):
        total = total + 1
    total
