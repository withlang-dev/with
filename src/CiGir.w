// CiGir — D121 step 3 (§16.2b.15 item 2): the ownership facts a package's
// GObject-introspection files (`*.gir`) declare, read for the facade proof
// engine (CiFacadeDraft.w).
//
// A `.gir` is XML keyed by C identifier, so it joins the corpus the way the
// header attributes do. The facts kept, per function (`function`,
// `constructor`, `method`): the return's `transfer-ownership` (`full`: the
// caller owns it; `none`: it stays the callee's, a borrow; `container`: the
// container is the caller's and its elements are not), whether the return
// is nullable, the return's introspected type name (`utf8`, `filename`, a
// record), the index of the instance parameter when the function is a
// method, and each parameter's transfer in C parameter order (`full`: the
// callee takes it). Per record or class: the function the file names as
// its destroyer (`free-function`, `glib:unref-func`, `glib:free-func`).
// Everything else a `.gir` says (callbacks, closures, out-parameters,
// ref-functions) is not a fact the facade language states; the engine
// reports it raw with its reason.
//
// Reading a file that is not well-formed XML, or an element the format
// does not have, is an error with its line: nothing is repaired.

use std.encoding.xml

type GirFn {
    pub c_name: str,
    // `ret=<full|none|container|->;rnull=<0|1>;rtype=<name>;inst=<-1|0>;p=<t,t,…>`
    pub facts: str,
}

type GirFacts {
    pub fns: List[GirFn],
    // The functions the files name as a record's or class's destroyer.
    pub drops: List[str],
}

fn GirFacts.new() -> GirFacts: GirFacts { fns: List.new(), drops: List.new() }

impl GirFacts:
    /// The facts for the C function named `c_name`, or "".
    fn facts_of(c_name: &str) -> str:
        for f in self.fns:
            if f.c_name == c_name: return f.facts
        ""

    fn names_drop(c_name: &str) -> bool: self.drops.contains(c_name)

fn gir_attr_or(el: &XmlElement, name: &str, fallback: &str) -> str:
    match el.attr(name):
        Some(v) => v
        None => fallback

fn gir_transfer(el: &XmlElement) -> str: gir_attr_or(el, "transfer-ownership", "-")

fn gir_fn_facts(el: &XmlElement) -> str:
    var ret = "-"
    var rnull = "0"
    var rtype = ""
    var inst = "-1"
    var params = ""
    for c in el.children:
        if c.name == "return-value":
            ret = gir_transfer(c)
            if gir_attr_or(c, "nullable", "0") == "1": rnull = "1"
            for t in c.children:
                if t.name == "type" or t.name == "array": rtype = gir_attr_or(t, "name", "")
        if c.name == "parameters":
            var index = 0
            for p in c.children:
                if p.name == "instance-parameter": inst = f"{index}"
                params = params ++ (if index > 0: "," else: "") ++ gir_transfer(p)
                index += 1
    "ret=" ++ ret ++ ";rnull=" ++ rnull ++ ";rtype=" ++ rtype ++ ";inst=" ++ inst ++ ";p=" ++ params

fn gir_walk(el: &XmlElement, out: GirFacts) -> GirFacts:
    var facts = out
    if el.name == "function" or el.name == "constructor" or el.name == "method":
        if let Some(c_name) = el.attr("c:identifier"):
            facts.fns.push(GirFn { c_name: c_name, facts: gir_fn_facts(el) })
    if el.name == "record" or el.name == "class" or el.name == "union" or el.name == "interface":
        for key in ["free-function", "glib:unref-func", "glib:free-func"]:
            if let Some(f) = el.attr(key):
                if not facts.drops.contains(f): facts.drops.push(f)
    for c in el.children: facts = gir_walk(c, facts)
    facts

/// Reads every `.gir` in `paths` into one fact set.
fn gir_read_files(paths: &List[str]) -> Result[GirFacts, str]:
    var facts = GirFacts.new()
    for path in paths:
        let doc = match XmlDocument.parse_file(path):
            Ok(d) => d
            Err(e) => return Err(path ++ f":{e.line}: " ++ e.message)
        if doc.root.name != "repository": return Err(path ++ ": not a GObject-introspection repository (root element <" ++ doc.root.name ++ ">)")
        facts = gir_walk(doc.root, facts)
    Ok(facts)

/// The value of `key` in a facts string, or "".
fn gir_fact(facts: &str, key: &str) -> str:
    for entry in facts.split(";"):
        if entry.starts_with(key ++ "="): return entry.slice(key.len() + 1, entry.len())
    ""

/// Parameter `index`'s transfer in a facts string: `full`, `none`,
/// `container`, or `-` when the file states none.
fn gir_param_transfer(facts: &str, index: i32) -> str:
    let params = gir_fact(facts, "p").split(",")
    if index < 0 or index >= params.len(): return "-"
    params[index]
