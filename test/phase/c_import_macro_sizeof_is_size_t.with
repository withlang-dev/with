//! expect-check-stdout: ok

// #1417: C's sizeof is a size_t, unsigned, and C's `~` keeps its operand's
// type. winnt.h's TOKEN_INTEGRITY_LEVEL_MAX_SIZE,
// `((((DWORD)(sizeof(T)) + sizeof(PVOID) - 1) & ~(sizeof(PVOID)-1)) + ...)`,
// imported with With's signed sizeof and `~x` spelled `0 - x - 1`: "bitwise
// operands with mixed signedness require explicit `as` cast". An imported
// object macro's sizeof now crosses as `usize` and `~` as `~`. (A macro
// whose operands are all constants is folded by clang instead; this one
// reads an extern variable, as a system header's macro is never folded.)

use c_import("typedef struct Rec { void *p; unsigned int n; } Rec;\nextern unsigned long long g_extra;\n#define REC_MAX_SIZE ((((unsigned long long)(sizeof(Rec)) + sizeof(void *) - 1) & ~(sizeof(void *) - 1)) + g_extra)\n")

fn main:
    let size: c_ulonglong = REC_MAX_SIZE
    print(f"{size}")
