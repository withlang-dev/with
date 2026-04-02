//! expect-stdout: ok

use issue65.types

fn main:
    let err = imported_bad("io")
    let missing = imported_missing("mod.w", 9)
    let empty = imported_empty()
    assert(f"{err}" == "Bad(io)")
    assert(f"{missing}" == "Missing(mod.w, 9)")
    assert(f"{empty}" == "Empty")

    let holder = imported_holder("field", 33)
    assert(f"{holder.err}" == "Bad(field)")
    assert(f"{holder.tok}" == "Int(33)")

    let nest = imported_nest("deep", 44)
    assert(f"{nest.holder.err}" == "Bad(deep)")
    assert(f"{nest.holder.tok}" == "Int(44)")

    let if_err = imported_if_err(false)
    assert(f"{if_err}" == "Bad(imported-if)")

    let match_tok = imported_match_tok(true)
    assert(f"{match_tok}" == "Text(match-yes)")

    print("ok")
