error LocalErr =
    Bad(msg: str)
    Empty

enum Token { Text(str) | End }

fn id(s: str) -> str:
    s

fn main:
    assert(f"{\"raw\"}" == "raw")
    assert(f"{id(\"call\")}" == "call")

    assert(f"{LocalErr.Bad(\"nope\")}" == "Bad(nope)")
    assert(f"{Token.Text(\"hi\")}" == "Text(hi)")

    assert(f"{id(\"a:b\")}" == "a:b")
    assert(f"{id(\"{\")}" == "{")
    assert(f"{id(\"a\\\"b\")}" == "a\"b")
    assert(f"{id(\"a\\\\b\")}" == "a\\b")

    print("ok")
