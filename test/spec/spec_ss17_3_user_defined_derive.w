//! expect-stdout: ok

trait Magic:
    fn marker(self: &Self) -> i32

comptime fn derive_magic[T: type] -> str:
    "impl Magic for " ++ T.name() ++ ":\n    fn marker(self: &Self) -> i32:\n        99\n"

@[derive(Magic)]
type Spell { value: i32 }

const SPELL_HAS_MAGIC: bool = comptime Spell.implements(Magic)

fn main:
    assert(SPELL_HAS_MAGIC)
    assert(Spell { value: 1 }.marker() == 99)
    print("ok")
