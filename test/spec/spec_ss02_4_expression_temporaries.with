//! expect-stdout: ok

var TEMP_DROP_TRACE = ""

type TempDropResource { id: str }
impl Drop for TempDropResource:
    fn drop(move self: Self):
        TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "[drop " ++ self.id ++ "]"

fn make_temp_drop_resource(id: str) -> TempDropResource:
    TempDropResource { id }

fn consume_temp_drop_resource(r: TempDropResource):
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "[in-consume]"

fn peek_temp_drop_resource(r: &TempDropResource):
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "[in-peek]"

fn peek_two_temp_drop_resources(a: &TempDropResource, b: &TempDropResource):
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "[in-peek2]"

fn pass_temp_drop_resource -> TempDropResource:
    make_temp_drop_resource("R")

fn bind_moved_temp_drop_resource:
    let a = make_temp_drop_resource("A")
    let b = a
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|before-exit"

fn discard_named_temp_drop_resource:
    let t = make_temp_drop_resource("T")
    let _ = t
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|after-discard"

fn bind_returned_temp_drop_resource:
    let r = pass_temp_drop_resource()
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|before-returned-exit"

fn main:
    TEMP_DROP_TRACE = ""
    make_temp_drop_resource("S")
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|afterS"
    assert(TEMP_DROP_TRACE == "[drop S]|afterS")

    TEMP_DROP_TRACE = ""
    let n = make_temp_drop_resource("M").id.len()
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ f"|n={n}"
    assert(TEMP_DROP_TRACE == "[drop M]|n=1")

    TEMP_DROP_TRACE = ""
    peek_temp_drop_resource(make_temp_drop_resource("P"))
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|afterP"
    assert(TEMP_DROP_TRACE == "[in-peek][drop P]|afterP")

    TEMP_DROP_TRACE = ""
    consume_temp_drop_resource(make_temp_drop_resource("V"))
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|afterV"
    assert(TEMP_DROP_TRACE == "[in-consume][drop V]|afterV")

    TEMP_DROP_TRACE = ""
    peek_two_temp_drop_resources(make_temp_drop_resource("1"), make_temp_drop_resource("2"))
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|after-two"
    assert(TEMP_DROP_TRACE == "[in-peek2][drop 2][drop 1]|after-two")

    TEMP_DROP_TRACE = ""
    if make_temp_drop_resource("C").id.len() > 0:
        TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|then"
    TEMP_DROP_TRACE = TEMP_DROP_TRACE ++ "|after-if"
    assert(TEMP_DROP_TRACE == "[drop C]|then|after-if")

    TEMP_DROP_TRACE = ""
    bind_moved_temp_drop_resource()
    assert(TEMP_DROP_TRACE == "|before-exit[drop A]")

    TEMP_DROP_TRACE = ""
    discard_named_temp_drop_resource()
    assert(TEMP_DROP_TRACE == "[drop T]|after-discard")

    TEMP_DROP_TRACE = ""
    bind_returned_temp_drop_resource()
    assert(TEMP_DROP_TRACE == "|before-returned-exit[drop R]")

    print("ok")
