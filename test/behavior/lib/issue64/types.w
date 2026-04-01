pub type ImportedInner {
    tags: Vec[i32],
    label: str,
}

pub type ImportedList = Vec[ImportedInner]

pub type ImportedOuter {
    items: Vec[ImportedInner],
}

pub type ImportedContext {
    outer: ImportedOuter,
}

pub fn imported_inner(label: str) -> ImportedInner:
    ImportedInner { tags: Vec.new(), label }

pub fn imported_filled_inner(label: str, value: i32) -> ImportedInner:
    let item = imported_inner(label)
    item.tags.push(value)
    item

pub fn imported_list() -> ImportedList:
    let items: ImportedList = Vec.new()
    items.push(imported_inner("imported"))
    items

pub fn imported_context() -> ImportedContext:
    let items: ImportedList = Vec.new()
    items.push(imported_inner("context"))
    ImportedContext { outer: ImportedOuter { items } }
