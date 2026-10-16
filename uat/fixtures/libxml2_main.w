// Release UAT: libxml2 over the facade `with get` wrote from the package's
// own evidence (D121, spec §16.2b.15). The program an application developer
// writes after `with get c.libxml2`: no hand facade, no `unsafe`, no raw
// pointer. The document is a resource freed by its scope; the nodes are
// borrows of it whose origin is bound per call (D134, §16.2b.6); attribute
// values and content are new text the caller owns, released through
// `xmlFree` on every path (§16.2b.8); the encoding is an optional C string
// the registry states nullable (§16.2b.15 item 3).
use facades.libxml2
use std.fs

fn main:
    write_file("library.xml", "<library><book title=\"Dune\">Herbert</book><!-- a comment --><book title=\"Emma\">Austen</book></library>")
    let Some(doc) = XmlDoc.read_file("library.xml", None, 0) else:
        print("libxml2 parse failed")
        return 1
    let Some(root) = doc.get_root_element() else:
        print("libxml2 has no root element")
        return 1
    if root.child_element_count() != 2:
        print(f"libxml2 child count mismatch: {root.child_element_count()}")
        return 1
    var seen: List[str] = List.new()
    var book = root.first_element_child()
    while let Some(b) = book:
        let Some(title) = b.get_prop("title") else:
            print("libxml2 book has no title")
            return 1
        let Some(author) = b.get_content() else:
            print("libxml2 book has no content")
            return 1
        seen.push(title ++ " by " ++ author)
        book = b.next_element_sibling()
    if seen.len() != 2 or seen[0] != "Dune by Herbert" or seen[1] != "Emma by Austen":
        print("libxml2 walk mismatch:")
        for line in seen: print(line)
        return 1
    print("libxml2 UAT passed")
