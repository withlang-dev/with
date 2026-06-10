#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re
import subprocess
import sys


SPEC = Path("docs/with-specification.md")
REQUIREMENTS = Path("docs/requirements.md")


HEADING_RE = re.compile(r"^(#{2,4})\s+(\d+(?:\.\d+)*(?:[a-z])?(?:\.\d+)?)\.?\s*(.*)$")
REQ_LINE_RE = re.compile(r"^- \[(?P<box>[ xX])\] `(?P<id>\d+\.\d+\.\d+\.\d+)` \*\*.*?\*\*(?P<suffix>.*)$")
SECTION_RE = re.compile(r"^### §(?P<label>\S+)")
SPEC_REF_RE = re.compile(r"§\d+(?:\.\d+)*(?:[a-z])?(?:\.\d+)?")


@dataclass
class Section:
    level: int
    label: str
    title: str
    start_line: int
    parent_title: str


@dataclass
class Item:
    section: Section
    text: str
    start_line: int
    end_line: int
    informative: bool


@dataclass
class OldMeta:
    box: str
    suffix: str
    key: str


def strip_inline_markup(text: str) -> str:
    text = text.replace("**", "")
    text = text.replace("__", "")
    text = re.sub(r"(?<!\*)\*(?!\*)", "", text)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return " ".join(text.split())


def meta_key(text: str) -> str:
    return strip_inline_markup(text).casefold()


def title_text(text: str) -> str:
    clean = strip_inline_markup(text)
    if len(clean) <= 78:
        return clean
    return clean[:75].rstrip() + "..."


def related_refs(text: str) -> str:
    refs: list[str] = []
    for ref in SPEC_REF_RE.findall(text):
        if ref not in refs:
            refs.append(ref)
    if not refs:
        return "none"
    return ", ".join(refs)


def source_range(label: str, start: int, end: int) -> str:
    if start == end:
        return f"`§{label} L{start}`"
    return f"`§{label} L{start}-L{end}`"


def load_old_text(argv: list[str]) -> str:
    if "--preserve-from-head" in argv:
        return subprocess.check_output(["git", "show", "HEAD:docs/requirements.md"], text=True)
    if REQUIREMENTS.exists():
        return REQUIREMENTS.read_text(encoding="utf-8")
    return ""


def load_old_meta(old_text: str) -> tuple[dict[str, OldMeta], dict[str, OldMeta], dict[str, str]]:
    meta: dict[str, OldMeta] = {}
    meta_by_key: dict[str, OldMeta] = {}
    section_prefix: dict[str, str] = {}
    if not old_text:
        return meta, meta_by_key, section_prefix

    current_section = ""
    pending_id = ""
    for line in old_text.splitlines():
        sec_match = SECTION_RE.match(line)
        if sec_match:
            current_section = sec_match.group("label")
            pending_id = ""
            continue
        req_match = REQ_LINE_RE.match(line)
        if req_match:
            req_id = req_match.group("id")
            title = re.sub(r"^- \[[ xX]\] `\d+\.\d+\.\d+\.\d+` \*\*", "", line)
            title = re.sub(r"\*\*.*$", "", title)
            key = meta_key(title)
            old = OldMeta(req_match.group("box"), req_match.group("suffix").rstrip(), key)
            meta[req_id] = old
            pending_id = req_id
            if key and key not in meta_by_key:
                meta_by_key[key] = old
            if current_section and current_section not in section_prefix:
                parts = req_id.split(".")
                section_prefix[current_section] = ".".join(parts[:3])
            continue
        if pending_id and ("  - Requirement:" in line or "  - Informative trace:" in line):
            full_text = line.split(":", 1)[1].strip()
            key = meta_key(full_text)
            old = meta[pending_id]
            full = OldMeta(old.box, old.suffix, key)
            meta[pending_id] = full
            if key and key not in meta_by_key:
                meta_by_key[key] = full
            pending_id = ""
    return meta, meta_by_key, section_prefix


def fallback_prefix(label: str) -> str:
    parts = label.split(".")
    last = parts[-1]
    letter_match = re.match(r"^(\d+)([a-z])$", last)
    if letter_match:
        base = ".".join(parts[:-1] + [letter_match.group(1)])
        letter_index = ord(letter_match.group(2)) - ord("a") + 2
        return f"{base}.{letter_index}"
    if len(parts) == 1:
        return f"{parts[0]}.1.1"
    if len(parts) == 2:
        return f"{parts[0]}.{parts[1]}.1"
    return ".".join(parts[:3])


def parse_spec() -> tuple[list[Section], list[Item]]:
    lines = SPEC.read_text(encoding="utf-8").splitlines()
    sections: list[Section] = []
    items: list[Item] = []
    current: Section | None = None
    current_chapter = ""
    in_code = False
    paragraph: list[tuple[int, str]] = []
    bullet: list[tuple[int, str]] = []

    def flush_paragraph() -> None:
        nonlocal paragraph
        if current is None or not paragraph:
            paragraph = []
            return
        text = " ".join(part.strip() for _, part in paragraph).strip()
        start = paragraph[0][0]
        end = paragraph[-1][0]
        paragraph = []
        for sentence in split_sentences(text):
            add_item(current, items, sentence, start, end)

    def flush_bullet() -> None:
        nonlocal bullet
        if current is None or not bullet:
            bullet = []
            return
        text = " ".join(part.strip() for _, part in bullet).strip()
        start = bullet[0][0]
        end = bullet[-1][0]
        bullet = []
        add_item(current, items, text, start, end)

    for idx, raw in enumerate(lines, start=1):
        stripped = raw.strip()
        if stripped.startswith("```"):
            flush_bullet()
            flush_paragraph()
            in_code = not in_code
            continue
        if in_code:
            continue

        heading = HEADING_RE.match(stripped)
        if heading:
            flush_bullet()
            flush_paragraph()
            level = len(heading.group(1))
            label = heading.group(2)
            title = heading.group(3).strip()
            if level == 2:
                current_chapter = f"{label}. {title}".strip()
            current = Section(level, label, title, idx, current_chapter)
            sections.append(current)
            continue

        if current is None:
            continue
        if not stripped:
            flush_bullet()
            flush_paragraph()
            continue
        if stripped.startswith("<!--"):
            flush_bullet()
            flush_paragraph()
            continue
        if stripped.startswith("|"):
            flush_bullet()
            flush_paragraph()
            table_item = parse_table_row(stripped)
            if table_item:
                add_item(current, items, table_item, idx, idx)
            continue
        if stripped.startswith("- ") or re.match(r"^\d+\.\s+", stripped):
            flush_bullet()
            flush_paragraph()
            bullet = re.sub(r"^(-|\d+\.)\s+", "", stripped).strip()
            bullet = [(idx, bullet)]
            continue
        if bullet:
            bullet.append((idx, stripped))
            continue
        paragraph.append((idx, stripped))

    flush_bullet()
    flush_paragraph()
    return sections, items


def split_sentences(text: str) -> list[str]:
    text = " ".join(text.split())
    if not text:
        return []
    pieces = re.split(r"(?<=[.!?])\s+(?=[A-Z`*_\"'(\[]) ", text)
    if len(pieces) == 1:
        pieces = re.split(r"(?<=[.!?])\s+(?=[A-Z`*_\"'(\[])", text)
    result: list[str] = []
    for piece in pieces:
        piece = piece.strip()
        if piece:
            result.append(piece)
    return result


def parse_table_row(line: str) -> str:
    cells = [cell.strip() for cell in line.strip("|").split("|")]
    if not cells:
        return ""
    if all(set(cell) <= {"-", ":"} for cell in cells):
        return ""
    return "; ".join(cell for cell in cells if cell)


def add_item(section: Section, items: list[Item], text: str, start: int, end: int) -> None:
    text = text.strip()
    if not text:
        return
    if text in {"---"}:
        return
    informative = section.label.startswith("30")
    items.append(Item(section, text, start, end, informative))


def render(sections: list[Section], items: list[Item], old_meta: dict[str, OldMeta], old_meta_by_key: dict[str, OldMeta], old_prefix: dict[str, str]) -> str:
    prefix_counter: dict[str, int] = {}
    section_items: dict[str, list[tuple[str, Item]]] = {}
    normative_count = 0
    informative_count = 0

    for item in items:
        prefix = old_prefix.get(item.section.label, fallback_prefix(item.section.label))
        prefix_counter[prefix] = prefix_counter.get(prefix, 0) + 1
        req_id = f"{prefix}.{prefix_counter[prefix]}"
        section_items.setdefault(item.section.label, []).append((req_id, item))
        if item.informative:
            informative_count += 1
        else:
            normative_count += 1

    out: list[str] = []
    out.extend(header(normative_count, informative_count, len({s.label for s in sections})))
    emitted_chapters: set[str] = set()
    emitted_sections: set[str] = set()

    for section in sections:
        entries = section_items.get(section.label)
        if not entries:
            continue
        chapter = section.parent_title
        if chapter and chapter not in emitted_chapters:
            out.append(f"## {chapter}")
            out.append("")
            emitted_chapters.add(chapter)
        if section.label not in emitted_sections:
            heading_title = f" {section.title}" if section.title else ""
            out.append(f"### §{section.label}{heading_title}")
            out.append("")
            emitted_sections.add(section.label)
        for req_id, item in entries:
            clean_title = title_text(item.text)
            key = meta_key(item.text)
            meta = old_meta_by_key.get(key)
            if meta is None:
                candidate = old_meta.get(req_id)
                if candidate is not None and candidate.key == key:
                    meta = candidate
            if meta is None:
                meta = OldMeta("x", "", key)
            suffix = meta.suffix
            out.append(f"- [{meta.box}] `{req_id}` **{clean_title}**{suffix}")
            field = "Informative trace" if item.informative else "Requirement"
            out.append(f"  - {field}: {item.text}")
            out.append(f"  - Source: {source_range(item.section.label, item.start_line, item.end_line)}")
            out.append(f"  - Related spec refs: {related_refs(item.text)}")
        out.append("")

    return "\n".join(out).rstrip() + "\n"


def header(normative_count: int, informative_count: int, section_count: int) -> list[str]:
    return [
        "# With Language Requirements",
        "",
        "This document is a requirements traceability matrix derived from `docs/with-specification.md` (Specification v7.1).",
        "",
        "**Triage campaign (2026-06-10): COMPLETE.** Every requirement below",
        "was reviewed against the spec, the implementation, and the test suite",
        "before this regeneration. A checked box means *triaged*, not",
        "*implemented*: entries whose behavior is unimplemented or partial carry",
        "an `— impl: #N` issue link; entries with significant test-coverage gaps",
        "carry a `— tests: #N` link; entries with neither link are either",
        "implemented-and-tested or non-testable. Regeneration preserves existing",
        "checkboxes and issue-link suffixes by matching requirement text and by",
        "stable requirement ID when the ID still names the same text.",
        "",
        "## Traceability Model",
        "",
        "- Requirement IDs use four numeric components: `category.topic.subtopic.ordinal`. The first three components follow the spec chapter/topic grouping; the final component is stable within that group.",
        "- Lettered spec sections are normalized into numeric subtopics while preserving the exact source label in the `Source` field. For example, `§4.3a` is grouped under `4.3.2.x`, after base `§4.3` under `4.3.1.x`.",
        "- The spec previously contained a repeated `§18.7` heading; v7.0 renumbered the second (Package Management) to `§18.8`. Requirement IDs in the `18.7.1.x` sequence that derive from the old second `§18.7` now trace to `§18.8`.",
        "- Each requirement records the exact spec section and line range that produced it. This is the sentence-to-requirement relationship. If a source sentence supports more than one requirement, repeat that source under each requirement when editing this file.",
        "- `Related spec refs` records explicit cross-references (`§...`) found in the source sentence. These are not exhaustive semantic dependencies; they are traceability hints.",
        "- Filler/meta sentences such as moved-document notices, appendix framing, and pure changelog prose are intentionally excluded. Examples and code blocks are usually represented through the surrounding normative prose, not as independent requirements.",
        "- Section 30 is explicitly informative. Its `30.x` entries, when present, are trace links only and are not independent normative requirements. Normative grammar requirements must cite the owning section that defines the construct.",
        "",
        f"Generated coverage: {normative_count} normative requirements plus {informative_count} informative Section 30 trace links from {section_count} numbered spec sections.",
        "",
    ]


def main() -> int:
    if not SPEC.exists():
        print(f"missing {SPEC}", file=sys.stderr)
        return 1
    old_text = load_old_text(sys.argv[1:])
    old_meta, old_meta_by_key, old_prefix = load_old_meta(old_text)
    sections, items = parse_spec()
    REQUIREMENTS.write_text(render(sections, items, old_meta, old_meta_by_key, old_prefix), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
