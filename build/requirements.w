module build.requirements

use std.build

type ReqSection:
    level: i32
    label: str
    title: str
    start_line: i32
    parent_title: str

type ReqItem:
    section_index: i32
    text: str
    start_line: i32
    end_line: i32
    informative: bool

type ReqPending:
    parts: Vec[str]
    lines: Vec[i32]

type ReqOldMeta:
    id: str
    box: str
    title: str
    suffix: str
    key: str

type ReqSectionPrefix:
    label: str
    prefix: str

type ReqOldState:
    meta: Vec[ReqOldMeta]
    prefixes: Vec[ReqSectionPrefix]

type ReqParseResult:
    sections: Vec[ReqSection]
    items: Vec[ReqItem]

type ReqPrefixCounter:
    prefix: str
    count: i32

type ReqCounterResult:
    counters: Vec[ReqPrefixCounter]
    ordinal: i32

fn req_fail(ctx: &ActionCtx, message: str) -> i32:
    ctx.diagnostics().error(ctx.target_name() ++ ": " ++ message)
    1

fn req_join(left: str, right: str) -> str:
    if left.len() == 0:
        return right
    if left.ends_with("/"):
        return left ++ right
    left ++ "/" ++ right

fn req_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return "."
    if last_slash == 0:
        return "/"
    path.slice(0, last_slash as i64)

fn req_trim(text: str) -> str:
    var start = 0
    var end = text.len() as i32
    while start < end:
        let ch = text.byte_at(start as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        start = start + 1
    while end > start:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        end = end - 1
    text.slice(start as i64, end as i64)

fn req_split_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            var end = i
            if end > start and text.byte_at((end - 1) as i64) == 13:
                end = end - 1
            lines.push(text.slice(start as i64, end as i64))
            start = i + 1
    if start < text.len() as i32:
        lines.push(text.slice(start as i64, text.len()))
    lines

fn req_ascii_lower(text: str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch >= 65 and ch <= 90:
            out.push_byte((ch + 32) as u8)
        else:
            out.push_byte(ch as u8)
    out.to_str()

fn req_collapse_ws(text: str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    var pending_space = false
    var wrote = false
    for i in 0..text.len() as i32:
        let ch = text.byte_at(i as i64)
        let space = ch == 9 or ch == 10 or ch == 13 or ch == 32
        if space:
            if wrote:
                pending_space = true
        else:
            if pending_space:
                out.push_byte(32 as u8)
                pending_space = false
            out.push_byte(ch as u8)
            wrote = true
    out.to_str()

fn req_strip_inline_markup(text: str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    var i = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 96 or ch == 42:
            i = i + 1
            continue
        if ch == 95 and i + 1 < text.len() as i32 and text.byte_at((i + 1) as i64) == 95:
            i = i + 2
            continue
        if ch == 91:
            var close = i + 1
            while close < text.len() as i32 and text.byte_at(close as i64) != 93:
                close = close + 1
            if close < text.len() as i32 and close + 1 < text.len() as i32 and text.byte_at((close + 1) as i64) == 40:
                var paren = close + 2
                while paren < text.len() as i32 and text.byte_at(paren as i64) != 41:
                    paren = paren + 1
                if paren < text.len() as i32:
                    out.push_str(text.slice((i + 1) as i64, close as i64))
                    i = paren + 1
                    continue
        out.push_byte(ch as u8)
        i = i + 1
    req_collapse_ws(out.to_str())

fn req_meta_key(text: str) -> str:
    req_ascii_lower(req_strip_inline_markup(text))

fn req_rstrip(text: str) -> str:
    var end = text.len() as i32
    while end > 0:
        let ch = text.byte_at((end - 1) as i64)
        if ch != 9 and ch != 10 and ch != 13 and ch != 32:
            break
        end = end - 1
    text.slice(0, end as i64)

fn req_title_text(text: str) -> str:
    let clean = req_strip_inline_markup(text)
    if clean.len() <= 78:
        return clean
    req_trim(clean.slice(0, 75)) ++ "..."

fn req_pending_new() -> ReqPending:
    ReqPending { parts: Vec.new(), lines: Vec.new() }

fn req_pending_add(pending: ReqPending, line_no: i32, text: str) -> ReqPending:
    var parts = pending.parts
    var lines = pending.lines
    parts.push(text)
    lines.push(line_no)
    ReqPending { parts, lines }

fn req_pending_text(pending: &ReqPending) -> str:
    var out = ""
    for i in 0..pending.parts.len() as i32:
        if i > 0:
            out = out ++ " "
        out = out ++ req_trim(pending.parts.get(i as i64))
    req_trim(out)

fn req_add_item(items: Vec[ReqItem], sections: &Vec[ReqSection], section_index: i32, text: str, start_line: i32, end_line: i32) -> Vec[ReqItem]:
    var out = items
    let clean = req_trim(text)
    if clean.len() == 0 or clean == "---":
        return out
    let section = sections.get(section_index as i64)
    out.push(ReqItem { section_index, text: clean, start_line, end_line, informative: section.label.starts_with("30") })
    out

fn req_sentence_start(ch: i32) -> bool:
    (ch >= 65 and ch <= 90) or ch == 96 or ch == 42 or ch == 95 or ch == 34 or ch == 39 or ch == 40 or ch == 91

fn req_flush_paragraph(items: Vec[ReqItem], sections: &Vec[ReqSection], section_index: i32, pending: &ReqPending) -> Vec[ReqItem]:
    var out = items
    if section_index < 0 or pending.parts.len() == 0:
        return out
    let text = req_collapse_ws(req_pending_text(pending))
    let start_line = pending.lines.get(0)
    let end_line = pending.lines.get(pending.lines.len() - 1)
    var start = 0
    var i = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 46 or ch == 33 or ch == 63:
            var next = i + 1
            while next < text.len() as i32 and text.byte_at(next as i64) == 32:
                next = next + 1
            if next > i + 1 and next < text.len() as i32 and req_sentence_start(text.byte_at(next as i64)):
                out = req_add_item(out, sections, section_index, text.slice(start as i64, (i + 1) as i64), start_line, end_line)
                start = next
                i = next
                continue
        i = i + 1
    if start < text.len() as i32:
        out = req_add_item(out, sections, section_index, text.slice(start as i64, text.len()), start_line, end_line)
    out

fn req_flush_bullet(items: Vec[ReqItem], sections: &Vec[ReqSection], section_index: i32, pending: &ReqPending) -> Vec[ReqItem]:
    if section_index < 0 or pending.parts.len() == 0:
        return items
    req_add_item(items, sections, section_index, req_pending_text(pending), pending.lines.get(0), pending.lines.get(pending.lines.len() - 1))

fn req_is_heading_label_char(ch: i32) -> bool:
    (ch >= 48 and ch <= 57) or ch == 46 or (ch >= 97 and ch <= 122)

fn req_parse_heading(line: str, line_no: i32, current_chapter: str, sections: Vec[ReqSection]) -> Vec[ReqSection]:
    var hash_count = 0
    while hash_count < line.len() as i32 and line.byte_at(hash_count as i64) == 35:
        hash_count = hash_count + 1
    if hash_count < 2 or hash_count > 4:
        return sections
    if hash_count >= line.len() as i32 or line.byte_at(hash_count as i64) != 32:
        return sections
    var pos = hash_count + 1
    let label_start = pos
    while pos < line.len() as i32 and req_is_heading_label_char(line.byte_at(pos as i64)):
        pos = pos + 1
    if pos == label_start:
        return sections
    var label = line.slice(label_start as i64, pos as i64)
    if label.ends_with("."):
        label = label.slice(0, label.len() - 1)
    while pos < line.len() as i32 and line.byte_at(pos as i64) == 32:
        pos = pos + 1
    let title = req_trim(line.slice(pos as i64, line.len()))
    let parent = if hash_count == 2: req_trim(label ++ ". " ++ title) else: current_chapter
    var out = sections
    out.push(ReqSection { level: hash_count, label, title, start_line: line_no, parent_title: parent })
    out

fn req_heading_matches(line: str) -> bool:
    var hash_count = 0
    while hash_count < line.len() as i32 and line.byte_at(hash_count as i64) == 35:
        hash_count = hash_count + 1
    if hash_count < 2 or hash_count > 4:
        return false
    hash_count < line.len() as i32 and line.byte_at(hash_count as i64) == 32 and hash_count + 1 < line.len() as i32 and req_is_heading_label_char(line.byte_at((hash_count + 1) as i64))

fn req_heading_chapter(line: str, existing: str) -> str:
    let before: Vec[ReqSection] = Vec.new()
    let after = req_parse_heading(line, 0, existing, before)
    if after.len() == 0:
        return existing
    after.get(0).parent_title

fn req_strip_list_marker(line: str) -> str:
    if line.starts_with("- "):
        return req_trim(line.slice(2, line.len()))
    var pos = 0
    while pos < line.len() as i32:
        let ch = line.byte_at(pos as i64)
        if ch < 48 or ch > 57:
            break
        pos = pos + 1
    if pos > 0 and pos + 1 < line.len() as i32 and line.byte_at(pos as i64) == 46 and line.byte_at((pos + 1) as i64) == 32:
        return req_trim(line.slice((pos + 2) as i64, line.len()))
    line

fn req_is_list_start(line: str) -> bool:
    if line.starts_with("- "):
        return true
    var pos = 0
    while pos < line.len() as i32:
        let ch = line.byte_at(pos as i64)
        if ch < 48 or ch > 57:
            break
        pos = pos + 1
    pos > 0 and pos + 1 < line.len() as i32 and line.byte_at(pos as i64) == 46 and line.byte_at((pos + 1) as i64) == 32

fn req_table_row_text(line: str) -> str:
    if not line.starts_with("|"):
        return ""
    let cells: Vec[str] = Vec.new()
    var start = 1
    for i in 1..line.len() as i32:
        if line.byte_at(i as i64) == 124:
            cells.push(req_trim(line.slice(start as i64, i as i64)))
            start = i + 1
    var all_sep = cells.len() > 0
    var out = ""
    for i in 0..cells.len() as i32:
        let cell = cells.get(i as i64)
        if cell.len() > 0:
            for j in 0..cell.len() as i32:
                let ch = cell.byte_at(j as i64)
                if ch != 45 and ch != 58:
                    all_sep = false
            if out.len() > 0:
                out = out ++ "; "
            out = out ++ cell
    if all_sep:
        return ""
    out

fn req_parse_spec(spec_text: str) -> ReqParseResult:
    let lines = req_split_lines(spec_text)
    var sections: Vec[ReqSection] = Vec.new()
    var items: Vec[ReqItem] = Vec.new()
    var current_section = -1
    var current_chapter = ""
    var in_code = false
    var paragraph = req_pending_new()
    var bullet = req_pending_new()
    for i in 0..lines.len() as i32:
        let raw = lines.get(i as i64)
        let line_no = i + 1
        let stripped = req_trim(raw)
        if stripped.starts_with("```"):
            items = req_flush_bullet(items, sections, current_section, bullet)
            bullet = req_pending_new()
            items = req_flush_paragraph(items, sections, current_section, paragraph)
            paragraph = req_pending_new()
            in_code = not in_code
            continue
        if in_code:
            continue
        if req_heading_matches(stripped):
            items = req_flush_bullet(items, sections, current_section, bullet)
            bullet = req_pending_new()
            items = req_flush_paragraph(items, sections, current_section, paragraph)
            paragraph = req_pending_new()
            current_chapter = req_heading_chapter(stripped, current_chapter)
            sections = req_parse_heading(stripped, line_no, current_chapter, sections)
            current_section = sections.len() as i32 - 1
            continue
        if current_section < 0:
            continue
        if stripped.len() == 0 or stripped.starts_with("<!--"):
            items = req_flush_bullet(items, sections, current_section, bullet)
            bullet = req_pending_new()
            items = req_flush_paragraph(items, sections, current_section, paragraph)
            paragraph = req_pending_new()
            continue
        if stripped.starts_with("|"):
            items = req_flush_bullet(items, sections, current_section, bullet)
            bullet = req_pending_new()
            items = req_flush_paragraph(items, sections, current_section, paragraph)
            paragraph = req_pending_new()
            let table_text = req_table_row_text(stripped)
            if table_text.len() > 0:
                items = req_add_item(items, sections, current_section, table_text, line_no, line_no)
            continue
        if req_is_list_start(stripped):
            items = req_flush_bullet(items, sections, current_section, bullet)
            bullet = req_pending_new()
            items = req_flush_paragraph(items, sections, current_section, paragraph)
            paragraph = req_pending_new()
            bullet = req_pending_add(bullet, line_no, req_strip_list_marker(stripped))
            continue
        if bullet.parts.len() > 0:
            bullet = req_pending_add(bullet, line_no, stripped)
        else:
            paragraph = req_pending_add(paragraph, line_no, stripped)
    items = req_flush_bullet(items, sections, current_section, bullet)
    items = req_flush_paragraph(items, sections, current_section, paragraph)
    ReqParseResult { sections, items }

fn req_extract_between(text: str, start_marker: str, end_marker: str, from: i32) -> str:
    let start_rel = text.slice(from as i64, text.len()).find(start_marker)
    if start_rel < 0:
        return ""
    let start = from + start_rel as i32 + start_marker.len() as i32
    let end_rel = text.slice(start as i64, text.len()).find(end_marker)
    if end_rel < 0:
        return ""
    text.slice(start as i64, (start + end_rel as i32) as i64)

fn req_prefix_from_id(id: str) -> str:
    var dots = 0
    for i in 0..id.len() as i32:
        if id.byte_at(i as i64) == 46:
            dots = dots + 1
            if dots == 3:
                return id.slice(0, i as i64)
    id

fn req_add_prefix(prefixes: Vec[ReqSectionPrefix], label: str, prefix: str) -> Vec[ReqSectionPrefix]:
    var out = prefixes
    for i in 0..out.len() as i32:
        if out.get(i as i64).label == label:
            return out
    out.push(ReqSectionPrefix { label, prefix })
    out

fn req_parse_old(old_text: str) -> ReqOldState:
    let lines = req_split_lines(old_text)
    let meta: Vec[ReqOldMeta] = Vec.new()
    var prefixes: Vec[ReqSectionPrefix] = Vec.new()
    var current_section = ""
    var pending_id = ""
    for i in 0..lines.len() as i32:
        let line = lines.get(i as i64)
        if line.starts_with("### §"):
            let rest = line.slice("### §".len(), line.len())
            var end = 0
            while end < rest.len() as i32:
                let ch = rest.byte_at(end as i64)
                if ch == 32 or ch == 9:
                    break
                end = end + 1
            current_section = rest.slice(0, end as i64)
            pending_id = ""
            continue
        if line.starts_with("- ["):
            let box = if line.len() > 3: line.slice(3, 4) else: "x"
            let id = req_extract_between(line, "`", "`", 0)
            let title = req_extract_between(line, "**", "**", 0)
            let second = line.find("**" ++ title ++ "**")
            var suffix = ""
            if second >= 0:
                suffix = line.slice((second + title.len() + 4) as i64, line.len())
            let key = req_meta_key(title)
            meta.push(ReqOldMeta { id, box, title, suffix: req_rstrip(suffix), key })
            pending_id = id
            if current_section.len() > 0:
                prefixes = req_add_prefix(prefixes, current_section, req_prefix_from_id(id))
            continue
        if pending_id.len() > 0 and (line.contains("  - Requirement:") or line.contains("  - Informative trace:")):
            let colon = line.find(":")
            if colon >= 0:
                let full_key = req_meta_key(req_trim(line.slice((colon + 1) as i64, line.len())))
                for mi in 0..meta.len() as i32:
                    if meta.get(mi as i64).id == pending_id:
                        let old = meta.get(mi as i64)
                        meta.push(ReqOldMeta { id: old.id, box: old.box, title: old.title, suffix: old.suffix, key: full_key })
                        break
            pending_id = ""
    ReqOldState { meta, prefixes }

fn req_fallback_prefix(label: str) -> str:
    let parts = req_split_label(label)
    if parts.len() == 1:
        return parts.get(0) ++ ".1.1"
    if parts.len() == 2:
        return parts.get(0) ++ "." ++ parts.get(1) ++ ".1"
    parts.get(0) ++ "." ++ parts.get(1) ++ "." ++ req_label_numeric(parts.get(2))

fn req_split_label(label: str) -> Vec[str]:
    let parts: Vec[str] = Vec.new()
    var start = 0
    for i in 0..label.len() as i32:
        if label.byte_at(i as i64) == 46:
            parts.push(label.slice(start as i64, i as i64))
            start = i + 1
    parts.push(label.slice(start as i64, label.len()))
    parts

fn req_label_numeric(part: str) -> str:
    var digits = ""
    var letter = 0
    for i in 0..part.len() as i32:
        let ch = part.byte_at(i as i64)
        if ch >= 48 and ch <= 57:
            digits = digits ++ part.slice(i as i64, (i + 1) as i64)
        else if ch >= 97 and ch <= 122:
            letter = ch
    if letter == 0:
        return digits
    f"{letter - 97 + 2}"

fn req_prefix_for_section(old: &ReqOldState, label: str) -> str:
    for i in 0..old.prefixes.len() as i32:
        let item = old.prefixes.get(i as i64)
        if item.label == label:
            return item.prefix
    req_fallback_prefix(label)

fn req_next_counter(counters: Vec[ReqPrefixCounter], prefix: str) -> ReqCounterResult:
    let out: Vec[ReqPrefixCounter] = Vec.new()
    var ordinal = 1
    var found = false
    for i in 0..counters.len() as i32:
        let item = counters.get(i as i64)
        if item.prefix == prefix:
            ordinal = item.count + 1
            out.push(ReqPrefixCounter { prefix, count: ordinal })
            found = true
        else:
            out.push(item)
    if not found:
        out.push(ReqPrefixCounter { prefix, count: 1 })
    ReqCounterResult { counters: out, ordinal }

fn req_find_old_by_key(old: &ReqOldState, key: str) -> ReqOldMeta:
    for i in 0..old.meta.len() as i32:
        let meta = old.meta.get(i as i64)
        if meta.key == key:
            return meta
    ReqOldMeta { id: "", box: "x", title: "", suffix: "", key }

fn req_find_old_by_id(old: &ReqOldState, id: str, key: str) -> ReqOldMeta:
    for i in 0..old.meta.len() as i32:
        let meta = old.meta.get(i as i64)
        if meta.id == id and meta.key == key:
            return meta
    ReqOldMeta { id: "", box: "x", title: "", suffix: "", key }

fn req_source_range(label: str, start_line: i32, end_line: i32) -> str:
    if start_line == end_line:
        return "`§" ++ label ++ " L" ++ f"{start_line}" ++ "`"
    "`§" ++ label ++ " L" ++ f"{start_line}" ++ "-L" ++ f"{end_line}" ++ "`"

fn req_ref_char(ch: i32) -> bool:
    (ch >= 48 and ch <= 57) or ch == 46 or (ch >= 97 and ch <= 122)

fn req_has_ref(refs: &Vec[str], value: str) -> bool:
    for i in 0..refs.len() as i32:
        if refs.get(i as i64) == value:
            return true
    false

fn req_related_refs(text: str) -> str:
    let refs: Vec[str] = Vec.new()
    var i = 0
    while i < text.len() as i32:
        if i + 2 <= text.len() as i32 and text.slice(i as i64, (i + 2) as i64) == "§":
            var end = i + 2
            while end < text.len() as i32 and req_ref_char(text.byte_at(end as i64)):
                end = end + 1
            var ref = text.slice(i as i64, end as i64)
            while ref.ends_with("."):
                ref = ref.slice(0, ref.len() - 1)
            if ref.len() > 2 and not req_has_ref(refs, ref):
                refs.push(ref)
            i = end
            continue
        i = i + 1
    if refs.len() == 0:
        return "none"
    var out = ""
    for ri in 0..refs.len() as i32:
        if ri > 0:
            out = out ++ ", "
        out = out ++ refs.get(ri as i64)
    out

fn req_header(normative: i32, informative: i32, section_count: i32) -> str:
    "# With Language Requirements\n\n" ++
    "This document is a requirements traceability matrix derived from `docs/with-specification.md` (Specification v7.1).\n\n" ++
    "**Triage campaign (2026-06-10): COMPLETE.** Every requirement below\n" ++
    "was reviewed against the spec, the implementation, and the test suite\n" ++
    "before this regeneration. A checked box means *triaged*, not\n" ++
    "*implemented*: entries whose behavior is unimplemented or partial carry\n" ++
    "an `— impl: #N` issue link; entries with significant test-coverage gaps\n" ++
    "carry a `— tests: #N` link; entries with neither link are either\n" ++
    "implemented-and-tested or non-testable. Regeneration preserves existing\n" ++
    "checkboxes and issue-link suffixes by matching requirement text and by\n" ++
    "stable requirement ID when the ID still names the same text.\n\n" ++
    "## Traceability Model\n\n" ++
    "- Requirement IDs use four numeric components: `category.topic.subtopic.ordinal`. The first three components follow the spec chapter/topic grouping; the final component is stable within that group.\n" ++
    "- Lettered spec sections are normalized into numeric subtopics while preserving the exact source label in the `Source` field. For example, `§4.3a` is grouped under `4.3.2.x`, after base `§4.3` under `4.3.1.x`.\n" ++
    "- The spec previously contained a repeated `§18.7` heading; v7.0 renumbered the second (Package Management) to `§18.8`. Requirement IDs in the `18.7.1.x` sequence that derive from the old second `§18.7` now trace to `§18.8`.\n" ++
    "- Each requirement records the exact spec section and line range that produced it. This is the sentence-to-requirement relationship. If a source sentence supports more than one requirement, repeat that source under each requirement when editing this file.\n" ++
    "- `Related spec refs` records explicit cross-references (`§...`) found in the source sentence. These are not exhaustive semantic dependencies; they are traceability hints.\n" ++
    "- Filler/meta sentences such as moved-document notices, appendix framing, and pure changelog prose are intentionally excluded. Examples and code blocks are usually represented through the surrounding normative prose, not as independent requirements.\n" ++
    "- Section 30 is explicitly informative. Its `30.x` entries, when present, are trace links only and are not independent normative requirements. Normative grammar requirements must cite the owning section that defines the construct.\n\n" ++
    "Generated coverage: " ++ f"{normative}" ++ " normative requirements plus " ++ f"{informative}" ++ " informative Section 30 trace links from " ++ f"{section_count}" ++ " numbered spec sections.\n\n"

fn req_vec_has(items: &Vec[str], value: str) -> bool:
    for i in 0..items.len() as i32:
        if items.get(i as i64) == value:
            return true
    false

fn req_render(sections: &Vec[ReqSection], items: &Vec[ReqItem], old: &ReqOldState) -> str:
    var normative = 0
    var informative = 0
    for i in 0..items.len() as i32:
        if items.get(i as i64).informative:
            informative = informative + 1
        else:
            normative = normative + 1
    var out = StringBuilder.new()
    out.push_str(req_header(normative, informative, sections.len() as i32))
    let emitted_chapters: Vec[str] = Vec.new()
    let emitted_sections: Vec[str] = Vec.new()
    var counters: Vec[ReqPrefixCounter] = Vec.new()
    for ii in 0..items.len() as i32:
        let item = items.get(ii as i64)
        let section = sections.get(item.section_index as i64)
        if section.parent_title.len() > 0 and not req_vec_has(emitted_chapters, section.parent_title):
            out.push_str("## " ++ section.parent_title ++ "\n\n")
            emitted_chapters.push(section.parent_title)
        if not req_vec_has(emitted_sections, section.label):
            let title = if section.title.len() > 0: " " ++ section.title else: ""
            out.push_str("### §" ++ section.label ++ title ++ "\n\n")
            emitted_sections.push(section.label)
        let prefix = req_prefix_for_section(old, section.label)
        let counter = req_next_counter(counters, prefix)
        counters = counter.counters
        let req_id = prefix ++ "." ++ f"{counter.ordinal}"
        let key = req_meta_key(item.text)
        var meta = req_find_old_by_key(old, key)
        if meta.id.len() == 0:
            meta = req_find_old_by_id(old, req_id, key)
        let field = if item.informative: "Informative trace" else: "Requirement"
        let display_title = if meta.title.len() > 0: meta.title else: req_title_text(item.text)
        out.push_str("- [" ++ meta.box ++ "] `" ++ req_id ++ "` **" ++ display_title ++ "**" ++ meta.suffix ++ "\n")
        out.push_str("  - " ++ field ++ ": " ++ item.text ++ "\n")
        out.push_str("  - Source: " ++ req_source_range(section.label, item.start_line, item.end_line) ++ "\n")
        out.push_str("  - Related spec refs: " ++ req_related_refs(item.text) ++ "\n")
        if ii + 1 == items.len() as i32 or items.get((ii + 1) as i64).section_index != item.section_index:
            out.push_str("\n")
    req_trim(out.to_str()) ++ "\n"

fn req_generate_text(ctx: &ActionCtx) -> str:
    let fs = ctx.fs()
    let spec = fs.read_text("docs/with-specification.md")
    let old = if fs.exists("docs/requirements.md"): fs.read_text("docs/requirements.md") else: ""
    let parsed = req_parse_spec(spec)
    let old_state = req_parse_old(old)
    req_render(parsed.sections, parsed.items, old_state)

pub fn run_requirements_generate_action(ctx: ActionCtx) -> i32:
    let output = ctx.output()
    if output.len() == 0:
        return req_fail(ctx, "missing output")
    let text = req_generate_text(ctx)
    let dir = req_dirname(output)
    let fs = ctx.fs()
    if dir != "." and fs.mkdir_all(dir) != 0:
        return req_fail(ctx, "could not create output directory: " ++ dir)
    if fs.write_text(output, text) != 0:
        return req_fail(ctx, "could not write " ++ output)
    0

pub fn run_requirements_check_action(ctx: ActionCtx) -> i32:
    let output = ctx.output()
    if output.len() == 0:
        return req_fail(ctx, "missing output")
    let generated = req_generate_text(ctx)
    let current = ctx.fs().read_text("docs/requirements.md")
    if generated != current:
        return req_fail(ctx, "docs/requirements.md is stale; run `with build :requirements`")
    let dir = req_dirname(output)
    if dir != "." and ctx.fs().mkdir_all(dir) != 0:
        return req_fail(ctx, "could not create output directory: " ++ dir)
    if ctx.fs().write_text(output, "ok\n") != 0:
        return req_fail(ctx, "could not write " ++ output)
    0
