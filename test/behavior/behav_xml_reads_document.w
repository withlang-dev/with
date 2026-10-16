//! expect-stdout: ok

use std.encoding.xml

// std.xml reads the shapes a GObject-introspection file uses: a declaration,
// a comment, a document type declaration, namespace-prefixed names, nested
// elements with attributes in either quote, character data with the
// predefined entities and numeric references, CDATA, and a processing
// instruction inside content. Malformed input names its line.
fn document() -> str:
    "<?xml version=\"1.0\"?>\n" ++
    "<!-- the GLib namespace, abridged -->\n" ++
    "<!DOCTYPE repository [ <!ENTITY x \"y\"> ]>\n" ++
    "<repository version=\"1.2\" xmlns:c=\"http://www.gtk.org/introspection/c/1.0\">\n" ++
    "  <namespace name=\"GLib\" c:identifier-prefixes='G'>\n" ++
    "    <record name=\"Bytes\" c:type=\"GBytes\" free-function=\"g_bytes_unref\" />\n" ++
    "    <function name=\"new\" c:identifier=\"g_bytes_new\">\n" ++
    "      <doc xml:space=\"preserve\">a &lt;b&gt; &amp; c &#169; &#x1F600; d<?pi here?></doc>\n" ++
    "      <return-value transfer-ownership=\"full\"><type name=\"Bytes\"/></return-value>\n" ++
    "      <parameters><parameter name=\"data\" transfer-ownership=\"none\"/></parameters>\n" ++
    "    </function>\n" ++
    "    <raw><![CDATA[<not & parsed>]]> tail</raw>\n" ++
    "  </namespace>\n" ++
    "</repository>\n" ++
    "<!-- trailing -->\n"

fn expect_error(source: &str, line: i32, needle: &str):
    match XmlDocument.parse(source):
        Ok(_) => assert(false)
        Err(e) =>
            assert(e.message.contains(needle))
            assert(e.line == line)

fn main:
    let doc = XmlDocument.parse(document()).unwrap()
    let root = &doc.root
    assert(root.name == "repository")
    assert(root.attr("version").unwrap() == "1.2")
    assert(root.attr("xmlns:c").unwrap() == "http://www.gtk.org/introspection/c/1.0")
    assert(not root.has_attr("name"))
    assert(root.text.trim() == "")
    let ns = root.child("namespace").unwrap()
    assert(ns.attr("c:identifier-prefixes").unwrap() == "G")
    assert(ns.children.len() == 3)
    assert(ns.count("record") == 1)
    let record = ns.child("record").unwrap()
    assert(record.attr("free-function").unwrap() == "g_bytes_unref")
    assert(record.children.len() == 0)
    let func = ns.child("function").unwrap()
    assert(func.attr("c:identifier").unwrap() == "g_bytes_new")
    assert(func.child("doc").unwrap().text == "a <b> & c © 😀 d")
    assert(func.child("return-value").unwrap().attr("transfer-ownership").unwrap() == "full")
    assert(func.child("return-value").unwrap().child("type").unwrap().attr("name").unwrap() == "Bytes")
    let param = func.child("parameters").unwrap().child("parameter").unwrap()
    assert(param.attr("transfer-ownership").unwrap() == "none")
    assert(func.child("missing").is_none())
    assert(ns.child("raw").unwrap().text == "<not & parsed> tail")

    expect_error("<a>\n<b>\n</a>", 3, "</a> closes <b> opened on line 2")
    expect_error("<a>\n<b>", 2, "unterminated element <b>")
    expect_error("<a x=\"1\" x=\"2\"/>", 1, "attribute x repeated")
    expect_error("<a>&nope;</a>", 1, "undefined entity &nope;")
    expect_error("<a>&#xZZ;</a>", 1, "malformed character reference")
    expect_error("<a v=\"1\"></a><b/>", 1, "content after the root element")
    expect_error("<a v=1/>", 1, "expected a quoted attribute value")
    expect_error("<a><!-- open\n\n", 1, "unterminated comment")
    expect_error("", 1, "no root element")
    print("ok")
