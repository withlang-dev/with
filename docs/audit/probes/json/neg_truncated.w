use std.json

// Audit probe (loud-failure): truncated document must panic, not stub.
fn main():
    let doc = JsonDocument.parse("{\"key\":")
    print(doc.root().raw() ++ "\n")
