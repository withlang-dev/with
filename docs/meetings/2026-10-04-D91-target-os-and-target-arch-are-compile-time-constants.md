# D91 — `Target.os` and `Target.arch` are compile-time constants; a per-target value is an exhaustive `comptime match`

**Laws:** 8, 1 (docs/mission.md).

**Date:** 2026-10-04. **Status:** BDFL ruling (Eric: option B, with three
adjustments, which are his). Spec v7.21: §17.1a, §17.5. Issues #2060,
#2070 (D90's per-target constants). **The implementation is NON-COMPLIANT
until it catches up**: ordinary compile-time code cannot read the target
today (the evaluator answers `os`/`arch` with the target only while it
evaluates the build layer).

**The question.** D90 makes a libc constant a `std.libc` name whose value
is what the consuming function accepts on the target, and keeps a platform
`#ifdef` as a conditional on the target. `EAGAIN` is 35 on macOS and 11 on
Linux and Windows, and migrated code compares it with the raw `errno`, so
no runtime seam can translate it: the value has to differ at compile time.
The language had no way to say so.

**Decision.** `Target.os` and `Target.arch` are compile-time constants of
`std.os`'s enums `OsKind` and `ArchKind`: the operating system and the
architecture a compilation is for, never the host's. A per-target value is
a `comptime match` on them:

```
pub const EAGAIN: i32 = comptime match Target.os:
    .Macos => 35
    .Linux => 11
    .Windows => 11
```

**Why enums and a match (Eric).** Exhaustiveness. When a target is added,
every per-target value that does not handle it becomes a compile error
instead of quietly taking some default: Go's one-file-per-target guarantee
without the file explosion. A string comparison (`os() == "Windows"`)
cannot give that, and a misspelled string is silent.

**The three adjustments.**

1. **Not a builtin named `target`.** The identifier is used some 420 times
   as a variable, field or parameter in `src`, `lib` and `build`,
   `lib/std/build.w` included; a builtin of that name would be shadowed
   constantly or break code. The type-level spelling `Target.os` /
   `Target.arch` does not collide.
2. **Reuse the existing enums.** `lib/std/os.w` already declares `OsKind`
   and `ArchKind`, and `std.os` and `std.sysinfo` each have their own
   string-returning `os()` and `arch()`. `Target` uses the enums, and the
   duplicate functions fold into one place.
3. **The untaken branch is parsed, and neither name-resolved nor
   type-checked.** A Windows branch names Windows-only symbols that do not
   exist on macOS. This is the rule §17.5 already applies to a
   `comptime if` on a type parameter, not a new concept. Its cost is that a
   typo inside the Windows branch is not caught on a Mac; the answer is a
   lane that runs `with check --target <t>` for every target, which needs
   only headers and the sysroot, not a cross-linker.

**Spec.** `Target` is a declared build input under §17.1, as the
`--target` value already is, so reading it is pure, tracked comptime and
needs no capability (§17.1a).

**References (checked in their trees).** Zig switches on
`builtin.target.os.tag` (`lib/std/c.zig`). Go keeps one file per target,
selected by its name (`syscall/zerrors_linux_amd64.go` has
`EAGAIN = Errno(0xb)`, `zerrors_darwin_arm64.go` has `Errno(0x23)`). Swift
uses `#if os(Windows)` (`stdlib/public/Platform/Platform.swift`).

**Alternatives.** A: make `std.sysinfo`'s `os()` and `arch()` callable at
compile time. No new surface, and rejected for the reasons above: strings,
no exhaustiveness. One module file per target: rejected, the programmer
becomes the build system.

**Reopen if** a per-target fact cannot be a function of the OS and the
architecture alone (an ABI or libc variant within one OS): `Target` then
gains a field, by a ruling.
