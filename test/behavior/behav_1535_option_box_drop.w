// #1535: an Option whose payload lowers to a pointer is that pointer (null is
// None). Its drop glue must still run the payload's drop: `Option[Box[T]]`
// frees the box and drops what it owns, a moved-out payload is not dropped
// twice, and a tree linked through `Option[Box[Node]]` releases every node.
use std.box.Box
global var TRACE = ""

type Guard { id: str }
impl Drop for Guard:
    move fn drop(): TRACE = TRACE ++ self.id

type Node { left: Option[Box[Node]], right: Option[Box[Node]], tag: Guard }

fn leaf(id: str) -> Box[Node]:
    Box.new(Node { left: None, right: None, tag: Guard { id } })

fn test_option_box_drops_payload_at_scope_exit:
    TRACE = ""
    {
        let maybe: Option[Box[Guard]] = Some(Box.new(Guard { id: "A".clone() }))
        assert(maybe.is_some())
        assert(TRACE == "")
    }
    assert(TRACE == "A")

fn test_none_drops_nothing:
    TRACE = ""
    {
        let maybe: Option[Box[Guard]] = None
        assert(maybe.is_none())
    }
    assert(TRACE == "")

fn test_moved_out_payload_drops_once:
    TRACE = ""
    {
        let maybe: Option[Box[Guard]] = Some(Box.new(Guard { id: "M".clone() }))
        let Some(taken) = maybe else return
        assert(taken.id == "M")
        assert(TRACE == "")
    }
    assert(TRACE == "M")

fn test_tree_releases_every_node:
    TRACE = ""
    {
        let root = Box.new(Node {
            left: Some(Box.new(Node { left: Some(leaf("1".clone())), right: Some(leaf("2".clone())), tag: Guard { id: "L".clone() } })),
            right: Some(leaf("3".clone())),
            tag: Guard { id: "R".clone() },
        })
        assert(root.tag.id == "R")
        assert(TRACE == "")
    }
    assert(TRACE.len() == 5)
    assert(TRACE.contains("1") and TRACE.contains("2") and TRACE.contains("3"))
    assert(TRACE.contains("L") and TRACE.contains("R"))
