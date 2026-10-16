// std.encoding.xml — a strict reader for XML documents.
//
// Elements, attributes, character data, comments, processing instructions,
// CDATA sections, the five predefined entities and numeric character
// references. A namespace prefix stays on the name it qualifies
// (`c:identifier`, `glib:type-name`): a reader that knows the document's
// prefixes needs nothing else, and GObject-introspection files fix theirs.
// A document type declaration is skipped; its internal subset is not read.
// Malformed input is an error naming the line: nothing is repaired.

use std.collections
use std.result
use std.string
use std.fs

pub type XmlError {
    pub line: i32,
    pub message: str,
}

fn xml_error(line: i32, message: str): XmlError { line: line, message: message }

pub type XmlAttr {
    pub name: str,
    pub value: str,
}

/// An element: its name, attributes in document order, child elements in
/// document order, and the character data written directly inside it,
/// concatenated (child elements' text is theirs).
pub type XmlElement {
    pub name: str,
    pub attrs: List[XmlAttr],
    pub children: List[XmlElement],
    pub text: str,
}

pub type XmlDocument {
    pub root: XmlElement,
}

impl XmlElement:
    /// The value of the attribute named `name`, if present.
    pub fn attr(wanted: &str) -> Option[&str]:
        for a in self.attrs:
            if a.name == wanted: return &a.value
        None

    pub fn has_attr(wanted: &str) -> bool:
        for a in self.attrs:
            if a.name == wanted: return true
        false

    /// The first child element named `name`, if any.
    pub fn child(wanted: &str) -> Option[&XmlElement]:
        for c in self.children:
            if c.name == wanted: return c
        None

    /// How many child elements are named `name`.
    pub fn count(wanted: &str) -> isize:
        var n = 0
        for c in self.children:
            if c.name == wanted: n += 1
        n

/// Parses the document in `source`.
pub fn XmlDocument.parse(source: str) -> Result[XmlDocument, XmlError]:
    var p = XmlParser { src: source, pos: 0, line: 1 }
    p.skip_prolog()?
    if p.at_end(): return Err(xml_error(p.line, "no root element"))
    let root = p.parse_element()?
    p.skip_misc()?
    if not p.at_end(): return Err(xml_error(p.line, "content after the root element"))
    Ok(XmlDocument { root: root })

/// Parses the document in the file at `path`.
pub fn XmlDocument.parse_file(path: &str) -> Result[XmlDocument, XmlError]:
    let source = match read_file(path):
        Ok(s) => s
        Err(_) => return Err(xml_error(0, "cannot read " ++ path))
    XmlDocument.parse(source)

type XmlParser {
    src: str,
    pos: isize,
    line: i32,
}

fn xml_is_name_start(c: i32) -> bool:
    is_alpha(c) or c == '_' or c == ':' or c >= 128

fn xml_is_name_char(c: i32) -> bool:
    xml_is_name_start(c) or is_digit(c) or c == '-' or c == '.'

fn xml_push_utf8(sb: StringBuilder, cp: i32) -> StringBuilder:
    var out = sb
    if cp < 0x80:
        out.push_char(cp)
    else if cp < 0x800:
        out.push_char(0xC0 | (cp >> 6))
        out.push_char(0x80 | (cp & 0x3F))
    else if cp < 0x10000:
        out.push_char(0xE0 | (cp >> 12))
        out.push_char(0x80 | ((cp >> 6) & 0x3F))
        out.push_char(0x80 | (cp & 0x3F))
    else:
        out.push_char(0xF0 | (cp >> 18))
        out.push_char(0x80 | ((cp >> 12) & 0x3F))
        out.push_char(0x80 | ((cp >> 6) & 0x3F))
        out.push_char(0x80 | (cp & 0x3F))
    out

impl XmlParser:
    fn at_end() -> bool: self.pos >= self.src.len()

    fn peek() -> i32:
        if self.pos < self.src.len(): self.src[self.pos] else: -1

    fn peek_at(ahead: isize) -> i32:
        if self.pos + ahead < self.src.len(): self.src[self.pos + ahead] else: -1

    fn looking_at(s: &str) -> bool:
        if self.pos + s.len() > self.src.len(): return false
        self.src.slice(self.pos, self.pos + s.len()) == s

    mut fn advance(n: isize):
        for i in 0..n:
            if self.src[self.pos + i] == '\n': self.line += 1
        self.pos += n

    mut fn skip_space():
        while not self.at_end() and is_space(self.peek()): self.advance(1)

    // Advances past `close`, counting lines; an error when it never comes.
    mut fn skip_past(close: &str, what: &str) -> Result[Unit, XmlError]:
        let start_line: i32 = self.line
        let at = self.src.find(close, self.pos)
        if at < 0: return Err(xml_error(start_line, "unterminated " ++ what))
        self.advance(at + close.len() - self.pos)
        Ok(())

    // Comments, processing instructions and whitespace between markup.
    mut fn skip_misc() -> Result[Unit, XmlError]:
        while true:
            self.skip_space()
            if self.looking_at("<!--"): self.skip_past("-->", "comment")?
            else if self.looking_at("<?"): self.skip_past("?>", "processing instruction")?
            else: return Ok(())
        Ok(())

    // The XML declaration, misc, and a document type declaration.
    mut fn skip_prolog() -> Result[Unit, XmlError]:
        self.skip_misc()?
        if self.looking_at("<!DOCTYPE"):
            let start_line: i32 = self.line
            var depth = 0
            while true:
                if self.at_end(): return Err(xml_error(start_line, "unterminated document type declaration"))
                let c = self.peek()
                if c == '[': depth += 1
                else if c == ']': depth -= 1
                else if c == '>' and depth == 0:
                    self.advance(1)
                    return self.skip_misc()
                self.advance(1)
        Ok(())

    mut fn parse_name() -> Result[str, XmlError]:
        if not xml_is_name_start(self.peek()): return Err(xml_error(self.line, "expected a name"))
        let start: isize = self.pos
        while xml_is_name_char(self.peek()): self.advance(1)
        Ok(self.src.slice(start, self.pos))

    // `&...;` with the cursor on the ampersand; the decoded text is appended.
    mut fn parse_reference(sb: StringBuilder) -> Result[StringBuilder, XmlError]:
        var out = sb
        let semi = self.src.find(";", self.pos)
        if semi < 0 or semi - self.pos > 12: return Err(xml_error(self.line, "unterminated entity reference"))
        let body = self.src.slice(self.pos + 1, semi)
        if body == "lt": out.push_char('<')
        else if body == "gt": out.push_char('>')
        else if body == "amp": out.push_char('&')
        else if body == "quot": out.push_char('"')
        else if body == "apos": out.push_char('\'')
        else if body.starts_with("#x") or body.starts_with("#"):
            let hex = body.starts_with("#x")
            let digits = body.slice(if hex: 2 else: 1, body.len())
            if digits.len() == 0: return Err(xml_error(self.line, "empty character reference"))
            var cp = 0
            for i in 0..digits.len():
                let d: i32 = digits[i]
                let v = if is_digit(d): d - '0' else if hex and is_xdigit(d): to_lower(d) - 'a' + 10 else: -1
                if v < 0 or (not hex and v > 9): return Err(xml_error(self.line, "malformed character reference &" ++ body ++ ";"))
                cp = cp * (if hex: 16 else: 10) + v
                if cp > 0x10FFFF: return Err(xml_error(self.line, "character reference out of range &" ++ body ++ ";"))
            out = xml_push_utf8(out, cp)
        else: return Err(xml_error(self.line, "undefined entity &" ++ body ++ ";"))
        self.advance(semi + 1 - self.pos)
        Ok(out)

    // Attribute value with the cursor on the opening quote.
    mut fn parse_attr_value() -> Result[str, XmlError]:
        let quote = self.peek()
        if quote != '"' and quote != '\'': return Err(xml_error(self.line, "expected a quoted attribute value"))
        self.advance(1)
        var sb = StringBuilder.new()
        while true:
            let c = self.peek()
            if c < 0: return Err(xml_error(self.line, "unterminated attribute value"))
            if c == quote: break
            if c == '<': return Err(xml_error(self.line, "'<' in an attribute value"))
            if c == '&': sb = self.parse_reference(sb)?
            else:
                sb.push_char(c)
                self.advance(1)
        self.advance(1)
        Ok(sb.to_str())

    // Character data up to the next `<`, decoded.
    mut fn parse_text(sb: StringBuilder) -> Result[StringBuilder, XmlError]:
        var out = sb
        while true:
            let start: isize = self.pos
            while not self.at_end() and self.peek() != '<' and self.peek() != '&': self.advance(1)
            if self.pos > start: out.push_str(self.src.slice(start, self.pos))
            if self.peek() == '&': out = self.parse_reference(out)?
            else: break
        Ok(out)

    // With the cursor on the `<` of a start tag.
    mut fn parse_element() -> Result[XmlElement, XmlError]:
        let open_line: i32 = self.line
        self.advance(1)
        let name = self.parse_name()?
        var attrs: List[XmlAttr] = List.new()
        var children: List[XmlElement] = List.new()
        var sb = StringBuilder.new()
        while true:
            self.skip_space()
            let c = self.peek()
            if c == '/':
                if self.peek_at(1) != '>': return Err(xml_error(self.line, "expected '/>' in <" ++ name ++ ">"))
                self.advance(2)
                return Ok(XmlElement { name: name, attrs: attrs, children: children, text: "" })
            if c == '>':
                self.advance(1)
                break
            if c < 0: return Err(xml_error(open_line, "unterminated start tag <" ++ name ++ ">"))
            let attr_name = self.parse_name()?
            self.skip_space()
            if self.peek() != '=': return Err(xml_error(self.line, "expected '=' after attribute " ++ attr_name))
            self.advance(1)
            self.skip_space()
            let value = self.parse_attr_value()?
            for a in attrs:
                if a.name == attr_name: return Err(xml_error(self.line, "attribute " ++ attr_name ++ " repeated in <" ++ name ++ ">"))
            attrs.push(XmlAttr { name: attr_name, value: value })
        // Content.
        while true:
            if self.at_end(): return Err(xml_error(open_line, "unterminated element <" ++ name ++ ">"))
            if self.looking_at("</"):
                self.advance(2)
                let close = self.parse_name()?
                if close != name: return Err(xml_error(self.line, "</" ++ close ++ "> closes <" ++ name ++ "> opened on line " ++ with_i32_to_str(open_line)))
                self.skip_space()
                if self.peek() != '>': return Err(xml_error(self.line, "expected '>' in </" ++ name ++ ">"))
                self.advance(1)
                break
            if self.looking_at("<!--"): self.skip_past("-->", "comment")?
            else if self.looking_at("<?"): self.skip_past("?>", "processing instruction")?
            else if self.looking_at("<![CDATA["):
                let start_line: i32 = self.line
                self.advance(9)
                let end = self.src.find("]]>", self.pos)
                if end < 0: return Err(xml_error(start_line, "unterminated CDATA section"))
                sb.push_str(self.src.slice(self.pos, end))
                self.advance(end + 3 - self.pos)
            else if self.peek() == '<': children.push(self.parse_element()?)
            else: sb = self.parse_text(sb)?
        Ok(XmlElement { name: name, attrs: attrs, children: children, text: sb.to_str() })
