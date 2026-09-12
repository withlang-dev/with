//! expect-debug-alloc: leak count=0

use std.collections

var DROPS = 0
type Item { text: str }
impl Drop for Item:
    move fn drop: DROPS = DROPS + 1

fn vector:
    let word = "compiler".clone()
    let arguments: Vec[str] = [word.clone(), "build"]
    let other = "overwritten".clone()
    assert(arguments[0] == "compiler")
    assert(word == "compiler" and other == "overwritten")
    let items: Vec[Item] = [Item { text: "first".clone() }, Item { text: "second".clone() }]
    assert(DROPS == 0 and items[1].text == "second")
    assert("second" == items[1].text and items[0].text < items[1].text)
    assert(items[0].text != "second" and items[1].text > "first")
    assert(items[0].text <= "first" and "second" >= items[1].text)

fn keyed:
    let values: HashSet[str] = ["red".clone(), "green".clone(), "red".clone()]
    let noise = "overwrite freed temporary buffers".clone()
    assert(values.contains("red") and values.contains("green"))
    let entries = ["key".clone(): "value".clone()]
    assert(entries.get("key").unwrap() == "value")
    assert(noise.len() > 0)

fn replacement:
    let entries = ["key".clone(): Item { text: "old".clone() }, "key".clone(): Item { text: "new".clone() }]
    assert(DROPS == 3)
    assert(entries.get("key").unwrap().text == "new")

fn main:
    vector()
    assert(DROPS == 2)
    keyed()
    replacement()
    assert(DROPS == 4)
