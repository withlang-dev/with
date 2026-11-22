//! expect-error: `Tag` cannot be a map key: it defines its own `eq`
// §11.7 (D96): a type with its own `eq` states what that equality is about
// as a key projection; the map would hash it by its parts otherwise.
use std.collections.HashSet

type Tag { text: str }

impl Eq for Tag:
    fn eq(other: &Tag) -> bool: self.text.to_lower() == other.text.to_lower()

fn main:
    var tags: HashSet[Tag] = HashSet.new()
    tags.insert(Tag { text: "a".to_lower() })
    print(tags.len())
