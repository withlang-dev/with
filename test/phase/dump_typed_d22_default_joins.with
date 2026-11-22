//! args: --dump-typed
//! expect-check-stdout: bind borrowed_default: &i32
//! expect-check-stdout: bind owned_default: i32
//! expect-check-stdout: bind pinned_default: i32
//! expect-check-stdout: bind borrowed_unwrap_or: &i32
//! expect-check-stdout: bind owned_unwrap_or: i32
//! expect-check-stdout: bind borrowed_lazy: &i32
//! expect-check-stdout: bind owned_lazy: i32
//! expect-check-stdout: role=carrier-payload kind=materialized-ref
//! expect-check-stdout: role=lazy-result kind=view
//! expect-check-stdout: role=expression kind=diverging

fn early_return(carrier: Option[&i32], fallback: &i32) -> &i32:
    carrier ?? return fallback

fn early_break(carrier: Option[&i32]) -> i32:
    var result = 0
    loop:
        let view: &i32 = carrier ?? break
        result = view
        break
    result

fn main:
    let left = 126
    let right = 127

    let carrier1: Option[&i32] = Some(&left)
    let borrowed_default: &i32 = carrier1 ?? &right
    let carrier2: Option[&i32] = Some(&left)
    let owned_default = carrier2 ?? 128
    let carrier3: Option[&i32] = Some(&left)
    let pinned_default: i32 = carrier3 ?? &right

    let carrier4: Option[&i32] = Some(&left)
    let borrowed_unwrap_or: &i32 = carrier4.unwrap_or(&right)
    let carrier5: Option[&i32] = Some(&left)
    let owned_unwrap_or = carrier5.unwrap_or(129)
    let carrier6: Option[&i32] = Some(&left)
    let borrowed_lazy: &i32 = carrier6.unwrap_or_else(() => &right)
    let carrier7: Option[&i32] = Some(&left)
    let owned_lazy = carrier7.unwrap_or_else(() => 130)

    let ok1: Result[&i32, str] = Ok(&left)
    let result_owned = ok1.unwrap_or(131)
    let ok2: Result[&i32, str] = Ok(&left)
    let result_borrowed = ok2.unwrap_or(&right)
    let ok3: Result[&i32, str] = Ok(&left)
    let result_lazy = ok3.unwrap_or_else((_) => 132)

    let carrier8: Option[&i32] = Some(&left)
    let returned = early_return(carrier8, &right)
    let carrier9: Option[&i32] = Some(&left)
    let broken = early_break(carrier9)

