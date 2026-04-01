//! expect-stdout: 012124

enum NotFlags: i32 { A | B | C }

@[flags]
enum Flags: i32 { X | Y | Z }

fn main:
    // Without flags: 0, 1, 2
    print(int_to_string(NotFlags.A))
    print(int_to_string(NotFlags.B))
    print(int_to_string(NotFlags.C))
    // With flags: should be 1, 2, 4
    print(int_to_string(Flags.X))
    print(int_to_string(Flags.Y))
    print(int_to_string(Flags.Z))
