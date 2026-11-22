//! expect-stdout: ok

use Lexer
use Token

fn assert_deterministic(src: str):
    var la = Lexer.init(src, 0)
    var a = la.tokenize()
    var lb = Lexer.init(src, 0)
    var b = lb.tokenize()

    assert(a.len() == b.len())
    for i in 0..a.len():
        assert(a.get_tag(i) == b.get_tag(i))
        assert(a.get_start(i) == b.get_start(i))
        assert(a.get_end(i) == b.get_end(i))

fn main:
    assert_deterministic("")
    assert_deterministic("$")
    assert_deterministic("'")
    assert_deterministic("'\\x4'")
    assert_deterministic("\"unterminated")
    assert_deterministic("r###\"unterminated")
    assert_deterministic("\"\"\"unterminated")
    assert_deterministic("0x__GG")
    assert_deterministic("fn main:\n    let =\n    @@@\n")
    assert_deterministic("use c_import(\"int broken( ;\")\n")
    assert_deterministic("a |> |> b")
    assert_deterministic("?? ?? ..= ... << >>")

    print("ok")
