//! expect-stdout: ok

// §15.4.7 / §11.9 / D61: a type with an explicit `impl Debug` is formatted by
// its debug_str at top level and nested alike (depth 0, 1, 2), a generic
// impl included. `:?` needs no derive; `@[derive(Debug)]` provides the trait
// for bounds, and its debug_str is exactly the generated form. An `error`
// declaration's generated Debug is the generated form too.

use std.collections.HashMap

type Secret { code: i32 }
impl Debug for Secret:
    fn debug_str() -> str: f"<secret {self.code}>"

enum Level:
    Low
    High(i32)
impl Debug for Level:
    fn debug_str() -> str:
        match self:
            Low => "level:low"
            High(n) => f"level:high/{n}"

type Wrap[T] { value: T }
impl[T] Debug for Wrap[T]:
    fn debug_str() -> str: "wrapped"

type Vault { owner: str, secret: Secret }
type Bank { vaults: Vec[Vault], level: Level }

@[derive(Debug)]
type Derived { name: str, secret: Secret }
@[derive(Debug)]
enum DerivedTag:
    Plain
    Named(str)

error Fault =
    Broken(reason: str)
    Missing

type Plain { name: str }

fn show[T: Debug](value: &T) -> str: value.debug_str()
fn generic_form[T](value: &T) -> str: f"{value:?}"

fn check(got: &str, want: &str):
    if got != want:
        print(f"mismatch\n  got:  {got}\n  want: {want}")
        assert(false)

fn main:
    // Depth 0.
    let s = Secret { code: 7 }
    check(f"{s:?}", "<secret 7>")
    check(f"{Level.Low:?} {Level.High(3):?}", "level:low level:high/3")
    let w = Wrap { value: "x" }
    check(f"{w:?}", "wrapped")
    // Depth 1: a field, a Vec element, a payload, a map value.
    let vault = Vault { owner: "ann", secret: Secret { code: 1 } }
    check(f"{vault:?}", r#"Vault { owner: "ann", secret: <secret 1> }"#)
    let secrets: Vec[Secret] = Vec.new()
    secrets.push(Secret { code: 2 })
    secrets.push(Secret { code: 3 })
    check(f"{secrets:?}", "[<secret 2>, <secret 3>]")
    let maybe: Option[Secret] = Some(Secret { code: 4 })
    check(f"{maybe:?}", "Some(<secret 4>)")
    var by_name: HashMap[str, Level] = HashMap.new()
    by_name.insert("b", Level.High(9))
    by_name.insert("a", Level.Low)
    check(f"{by_name:?}", r#"{"a": level:low, "b": level:high/9}"#)
    let wraps: Vec[Wrap[i32]] = Vec.new()
    wraps.push(Wrap { value: 1 })
    check(f"{wraps:?}", "[wrapped]")
    // Depth 2: a field of a struct in a Vec in a struct.
    let vaults: Vec[Vault] = Vec.new()
    vaults.push(Vault { owner: "bo", secret: Secret { code: 5 } })
    let bank = Bank { vaults, level: Level.High(2) }
    check(f"{bank:?}", r#"Bank { vaults: [Vault { owner: "bo", secret: <secret 5> }], level: level:high/2 }"#)
    // The explicit impl is also what a Debug bound calls.
    check(show(&s), "<secret 7>")

    // Derived: the generated form, through `:?` and through debug_str alike;
    // a field with an explicit impl keeps its own form inside it.
    let d = Derived { name: "q\"t", secret: Secret { code: 6 } }
    check(f"{d:?}", r#"Derived { name: "q\"t", secret: <secret 6> }"#)
    check(d.debug_str(), f"{d:?}")
    check(show(&d), f"{d:?}")
    check(f"{DerivedTag.Plain:?} {DerivedTag.Named("n"):?}", r#"Plain Named("n")"#)
    check(DerivedTag.Named("n").debug_str(), r#"Named("n")"#)

    // An error declaration: the generated form.
    let fault = Fault.Broken("disk\nfull")
    check(f"{fault:?}", r#"Broken("disk\nfull")"#)
    check(f"{Fault.Missing:?}", "Missing")

    // No derive needed: a plain type formats, in generic code too.
    let plain = Plain { name: "p" }
    check(f"{plain:?}", r#"Plain { name: "p" }"#)
    check(generic_form(&plain), r#"Plain { name: "p" }"#)
    check(generic_form(&s), "<secret 7>")
    print("ok")
