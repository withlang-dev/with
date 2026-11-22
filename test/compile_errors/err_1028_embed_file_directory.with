//! expect-check-fail: is a directory; embed_file embeds one file
// #1028: embed_file of a directory read it as "" and embedded that with no
// word; the directory here is the one this file sits in.
const HERE: str = embed_file(".")

fn main:
    print(HERE.len())
