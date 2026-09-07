use std.json

// Audit probe (loud-failure): non-ASCII \u escape must panic loudly.
fn main():
    let doc = JsonDocument.parse("{\"s\":\"caf\\u00e9\"}")
    print(str.deserialize(doc.root().field("s")) ++ "\n")
