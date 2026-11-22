//! expect-error: c_import symbol 'hidden_alias_t' was omitted: not in this import's only: list

// §16.2: the type-alias macro is emitted as `type hidden_alias_t = hidden_t`,
// and `only:` then leaves both out; a use names the only: list instead of
// reading as an unknown type.
use c_import("typedef int hidden_t;\n#define hidden_alias_t hidden_t\nint keep(int x);\n", only: ["keep"])

fn main:
    let v: hidden_alias_t = 1
    print(f"{keep(v)}")
