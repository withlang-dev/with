// Restructure docs/ into the csharplang shape (spec/ one file per chapter,
// meetings/ one file per decision, proposals/, completed/) by moving text.
// Every moved passage stays byte-identical to its source; only the file it
// lives in, the level of the heading that becomes a file's first line, and a
// one-line pointer left at the old place change.
//
//   with run tools/docs_restructure.w split-spec        docs/with-specification.md -> docs/spec/
//   with run tools/docs_restructure.w split-decisions   docs/decisions.md -> docs/meetings/
//   with run tools/docs_restructure.w move              git mv every whole file in the map
//   with run tools/docs_restructure.w list-moves        print the whole-file map (old -> new)
//   with run tools/docs_restructure.w rewrite-refs      fix docs/... path references tree-wide
//   with run tools/docs_restructure.w verify-spec ORIG  reassemble docs/spec and compare to ORIG
//   with run tools/docs_restructure.w verify-decisions ORIG
//
// Run from the repository root.
use std.fs
use std.process

// ---------------------------------------------------------------- tables

// Chapter number -> file under docs/spec/. Whole chapters that are not
// language semantics live in a reference subfolder.
fn chapter_table -> str:
    "1 design-goals.md\n" ++
    "2 ownership.md\n" ++
    "3 borrowing.md\n" ++
    "4 types.md\n" ++
    "5 ephemeral.md\n" ++
    "6 handles.md\n" ++
    "7 with-scoped-access.md\n" ++
    "8 memory.md\n" ++
    "9 functions.md\n" ++
    "10 errors.md\n" ++
    "11 traits.md\n" ++
    "12 closures.md\n" ++
    "13 iteration.md\n" ++
    "14 concurrency.md\n" ++
    "15 strings.md\n" ++
    "16 ffi.md\n" ++
    "17 metaprogramming.md\n" ++
    "18 modules.md\n" ++
    "19 safety.md\n" ++
    "20 performance.md\n" ++
    "20b toolchain/denied-patterns.md\n" ++
    "21 borrow-checker-rules.md\n" ++
    "22 ephemeral-rules.md\n" ++
    "23 with-block-semantics.md\n" ++
    "24 async-equivalences.md\n" ++
    "25 guide/test-cases.md\n" ++
    "26 implementation/phased-implementation.md\n" ++
    "27 guide/known-limitations.md\n" ++
    "28 guide/future-work.md\n" ++
    "29 lexical-and-binding-rules.md\n" ++
    "30 grammar.md\n"

// Section id -> file under docs/spec/ for sections moved out of a chapter.
fn section_table -> str:
    "7.8 guide/with-frequency.md\n" ++
    "7.9 guide/with-idioms-and-rules.md\n" ++
    "13.3 stdlib/collection-operations.md\n" ++
    "14.12 implementation/why-fibers.md\n" ++
    "14.15 stdlib/channels.md\n" ++
    "14.16 stdlib/send-sync-scopedsend.md\n" ++
    "14.17 stdlib/synchronization-primitives.md\n" ++
    "14.18 implementation/fiber-runtime.md\n" ++
    "14.19 implementation/fiber-stack-management.md\n" ++
    "14.21 guide/real-world-example.md\n" ++
    "15.2 stdlib/string-conversions.md\n" ++
    "15.7 stdlib/output-functions.md\n" ++
    "15.8 stdlib/regular-expressions.md\n" ++
    "16.3e abi/abi-boundary-signatures.md\n" ++
    "16.4 abi/layout-control.md\n" ++
    "16.5 abi/exporting-to-c.md\n" ++
    "16.6 abi/function-pointers.md\n" ++
    "18.5 toolchain/toolchain.md\n" ++
    "18.5a toolchain/project-builds.md\n" ++
    "18.5b toolchain/cli-one-liners.md\n" ++
    "18.5c toolchain/bundles-and-interfaces.md\n" ++
    "18.5d toolchain/acceptance-scenarios.md\n" ++
    "18.6 stdlib/standard-library-design.md\n" ++
    "18.8 toolchain/package-management.md\n"

// Whole files: old path -> new path.
fn move_table -> str:
    "docs/feature_plans/libstd-spec.md docs/spec/stdlib/libstd-spec.md\n" ++
    "docs/feature_plans/std-math-spec.md docs/spec/stdlib/std-math-spec.md\n" ++
    "docs/std-encoding-rfc4648.md docs/spec/stdlib/std-encoding-rfc4648.md\n" ++
    "docs/perl-compatible-re.md docs/spec/stdlib/perl-compatible-re.md\n" ++
    "docs/stdlib_inventory.md docs/spec/stdlib/stdlib_inventory.md\n" ++
    "docs/completed/regex-spec.md docs/spec/stdlib/regex-spec.md\n" ++
    "docs/with-abi.md docs/spec/abi/with-abi.md\n" ++
    "docs/fn_abi_descriptor_design.md docs/spec/abi/fn_abi_descriptor_design.md\n" ++
    "docs/abi_roadmap.md docs/spec/abi/abi_roadmap.md\n" ++
    "docs/with-build.md docs/spec/toolchain/with-build.md\n" ++
    "docs/with_oneliners.md docs/spec/toolchain/with_oneliners.md\n" ++
    "docs/improve_oneliners.md docs/spec/toolchain/improve_oneliners.md\n" ++
    "docs/impossible_oneliners.md docs/spec/toolchain/impossible_oneliners.md\n" ++
    "docs/debug-allocator.md docs/spec/toolchain/debug-allocator.md\n" ++
    "docs/deep-debugging-tools.md docs/spec/toolchain/deep-debugging-tools.md\n" ++
    "docs/wo_bundles.md docs/spec/toolchain/wo_bundles.md\n" ++
    "docs/unit-return-review.md docs/spec/toolchain/unit-return-review.md\n" ++
    "docs/with-release-runbook.md docs/spec/toolchain/with-release-runbook.md\n" ++
    "docs/with-bootstrap-runbook.md docs/spec/toolchain/with-bootstrap-runbook.md\n" ++
    "docs/with-migrate-spec.md docs/spec/toolchain/with-migrate-spec.md\n" ++
    "docs/with-migrate-go-spec.md docs/spec/toolchain/with-migrate-go-spec.md\n" ++
    "docs/with-migrate-python-spec.md docs/spec/toolchain/with-migrate-python-spec.md\n" ++
    "docs/with-migrate-rust-spec.md docs/spec/toolchain/with-migrate-rust-spec.md\n" ++
    "docs/with-migrate-swift-spec.md docs/spec/toolchain/with-migrate-swift-spec.md\n" ++
    "docs/with-migrate-zig-spec.md docs/spec/toolchain/with-migrate-zig-spec.md\n" ++
    "docs/with-implementation-notes.md docs/spec/implementation/with-implementation-notes.md\n" ++
    "docs/memory-model.md docs/spec/implementation/memory-model.md\n" ++
    "docs/mir-sema-hardening.md docs/spec/implementation/mir-sema-hardening.md\n" ++
    "docs/mir-core-test-dependencies.md docs/spec/implementation/mir-core-test-dependencies.md\n" ++
    "docs/storage-types-and-caller-places-implementation.md docs/spec/implementation/storage-types-and-caller-places-implementation.md\n" ++
    "docs/with-idiomatic-guide.md docs/spec/guide/with-idiomatic-guide.md\n" ++
    "docs/with_for_ai.md docs/spec/guide/with_for_ai.md\n" ++
    "docs/with-migration-guide.md docs/spec/guide/with-migration-guide.md\n" ++
    "docs/d22-Eric-Ruling.md docs/meetings/d22-Eric-Ruling.md\n" ++
    "docs/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md docs/meetings/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md\n" ++
    "docs/plans/comptime-int-width.md docs/proposals/comptime-int-width.md\n" ++
    "docs/plans/libgit2.md docs/proposals/libgit2.md\n" ++
    "docs/plans/mutability-impl.md docs/proposals/mutability-impl.md\n" ++
    "docs/plans/no-deps.md docs/proposals/no-deps.md\n" ++
    "docs/plans/regex.md docs/proposals/regex.md\n" ++
    "docs/plans/with-fmt.md docs/proposals/with-fmt.md\n" ++
    "docs/plans/zlib.md docs/proposals/zlib.md\n" ++
    "docs/feature_plans/async-proposal.md docs/proposals/async-proposal.md\n" ++
    "docs/feature_plans/d21-mutator-pipeline-implementation.md docs/proposals/d21-mutator-pipeline-implementation.md\n" ++
    "docs/feature_plans/editor-support.md docs/proposals/editor-support.md\n" ++
    "docs/feature_plans/from-query-expressions.md docs/proposals/from-query-expressions.md\n" ++
    "docs/feature_plans/libs.md docs/proposals/libs.md\n" ++
    "docs/feature_plans/state_machine_async.md docs/proposals/state_machine_async.md\n" ++
    "docs/feature_plans/stdlib_migration.md docs/proposals/stdlib_migration.md\n" ++
    "docs/feature_plans/stdlib-action-env-leak.md docs/proposals/stdlib-action-env-leak.md\n" ++
    "docs/feature_plans/stdlib-fluent-builder-blocker.md docs/proposals/stdlib-fluent-builder-blocker.md\n" ++
    "docs/feature_plans/stdlib-getenv-lifetime.md docs/proposals/stdlib-getenv-lifetime.md\n" ++
    "docs/feature_plans/structural-types.md docs/proposals/structural-types.md\n" ++
    "docs/d22-implementation-plan.md docs/proposals/d22-implementation-plan.md\n" ++
    "docs/d27-implementation-plan.md docs/proposals/d27-implementation-plan.md\n" ++
    "docs/d30-implementation-plan.md docs/proposals/d30-implementation-plan.md\n" ++
    "docs/modeled-c-implementation-plan.md docs/proposals/modeled-c-implementation-plan.md\n" ++
    "docs/modeled-c-pair-state-plan.md docs/proposals/modeled-c-pair-state-plan.md\n" ++
    "docs/modeled-c-spec-projection-draft.md docs/proposals/modeled-c-spec-projection-draft.md\n" ++
    "docs/harden_migrate.md docs/proposals/harden_migrate.md\n" ++
    "docs/harden_plan.md docs/proposals/harden_plan.md\n" ++
    "docs/i128.md docs/proposals/i128.md\n" ++
    "docs/wasm-target.md docs/proposals/wasm-target.md\n" ++
    "docs/eliminate-self.md docs/proposals/eliminate-self.md\n" ++
    "docs/COBOL-migrate.md docs/proposals/COBOL-migrate.md\n" ++
    "docs/roadmap.md docs/proposals/roadmap.md\n" ++
    "docs/implementation_plan.md docs/proposals/implementation_plan.md\n" ++
    "docs/uat-plan.md docs/proposals/uat-plan.md\n" ++
    "docs/stdlib_sourcing_plan.md docs/proposals/stdlib_sourcing_plan.md\n" ++
    "docs/storage-types-and-caller-places-spec.md docs/proposals/storage-types-and-caller-places-spec.md\n" ++
    "docs/build-perf-reference-study.md docs/proposals/build-perf-reference-study.md\n" ++
    "docs/with-get-release-investigation.md docs/proposals/with-get-release-investigation.md\n" ++
    "docs/share_place_known_gaps.md docs/proposals/inactive/share_place_known_gaps.md\n" ++
    "docs/share_place_minimal_design.md docs/proposals/inactive/share_place_minimal_design.md\n" ++
    "docs/share_place_restoration_plan.md docs/proposals/inactive/share_place_restoration_plan.md\n" ++
    "docs/resume_after_mutability_fixed.md docs/proposals/inactive/resume_after_mutability_fixed.md\n" ++
    "docs/d22-stage0-salvage-manifest.md docs/proposals/inactive/d22-stage0-salvage-manifest.md\n" ++
    "docs/bootstrap-link-root-debug.md docs/completed/bootstrap-link-root-debug.md\n" ++
    "docs/build-compiler-fingerprint-debug.md docs/completed/build-compiler-fingerprint-debug.md\n" ++
    "docs/bundle-va-list-interface-debug.md docs/completed/bundle-va-list-interface-debug.md\n" ++
    "docs/c-algorithms-migration-debug.md docs/completed/c-algorithms-migration-debug.md\n" ++
    "docs/c-va-list-debug.md docs/completed/c-va-list-debug.md\n" ++
    "docs/codegen-low-memory-debug.md docs/completed/codegen-low-memory-debug.md\n" ++
    "docs/comptime-string-order-debug.md docs/completed/comptime-string-order-debug.md\n" ++
    "docs/defer-temporary-drop-debug.md docs/completed/defer-temporary-drop-debug.md\n" ++
    "docs/global-drop-state-debug.md docs/completed/global-drop-state-debug.md\n" ++
    "docs/initializer-drop-debug.md docs/completed/initializer-drop-debug.md\n" ++
    "docs/macos-stage-bundle-debug.md docs/completed/macos-stage-bundle-debug.md\n" ++
    "docs/migrate-embedded-header-origin-debug.md docs/completed/migrate-embedded-header-origin-debug.md\n" ++
    "docs/migrate-macro-origin-debug.md docs/completed/migrate-macro-origin-debug.md\n" ++
    "docs/migrate-private-token-paste-debug.md docs/completed/migrate-private-token-paste-debug.md\n" ++
    "docs/migrate-windows-header-origin-debug.md docs/completed/migrate-windows-header-origin-debug.md\n" ++
    "docs/parameter-drop-state-debug.md docs/completed/parameter-drop-state-debug.md\n" ++
    "docs/phase0-ownership-debug.md docs/completed/phase0-ownership-debug.md\n" ++
    "docs/test-case-output-isolation-debug.md docs/completed/test-case-output-isolation-debug.md\n" ++
    "docs/tool-fs-absolute-path-debug.md docs/completed/tool-fs-absolute-path-debug.md\n" ++
    "docs/windows-mkdir-debug.md docs/completed/windows-mkdir-debug.md\n" ++
    "docs/zlib-facade-sdk-limit-debug.md docs/completed/zlib-facade-sdk-limit-debug.md\n" ++
    "docs/zlib-gunzip-sdk-limit-debug.md docs/completed/zlib-gunzip-sdk-limit-debug.md\n" ++
    "docs/zlib-reference-readiness-debug.md docs/completed/zlib-reference-readiness-debug.md\n" ++
    "docs/handoff.md docs/completed/handoff.md\n" ++
    "docs/handoff-783-uaf.md docs/completed/handoff-783-uaf.md\n" ++
    "docs/handoff-flip-testgreen.md docs/completed/handoff-flip-testgreen.md\n" ++
    "docs/handoff-modeled-c-stage4.md docs/completed/handoff-modeled-c-stage4.md\n" ++
    "docs/build_time_log.md docs/completed/build_time_log.md\n" ++
    "docs/float-c-format-audit.md docs/completed/float-c-format-audit.md\n" ++
    "docs/public-return-inference-audit.md docs/completed/public-return-inference-audit.md\n"

// ---------------------------------------------------------------- helpers

type Pair { key: str, value: str }

fn parse_pairs(table: &str) -> Vec[Pair]:
    var out: Vec[Pair] = Vec.new()
    for line in table.split("\n"):
        if line.len() == 0: continue
        let parts = line.split(" ")
        out.push(Pair { key: parts[0].clone(), value: parts[1].clone() })
    out

fn lookup(pairs: &Vec[Pair], key: &str) -> str:
    for i in 0..pairs.len() as i32:
        if pairs[i].key == key: return pairs[i].value.clone()
    ""

fn is_digit(c: i32) -> bool: c >= '0' and c <= '9'
fn is_lower(c: i32) -> bool: c >= 'a' and c <= 'z'
fn is_upper(c: i32) -> bool: c >= 'A' and c <= 'Z'
fn is_alnum(c: i32) -> bool: is_digit(c) or is_lower(c) or is_upper(c)

// The first word of a line after `prefix` ("## 20b. Title" -> "20b.").
fn word_after(line: &str, prefix: &str) -> str:
    let rest = line.slice(prefix.len(), line.len())
    let sp = rest.find(" ")
    if sp < 0: return rest.clone()
    rest.slice(0, sp)

// A chapter heading `## N. Title` (N digits with an optional letter).
fn chapter_id(line: &str) -> str:
    if not line.starts_with("## "): return ""
    let w = word_after(line, "## ")
    if w.len() < 2 or not w.ends_with(".") or not is_digit(w[0]): return ""
    w.slice(0, w.len() - 1)

// A numbered subsection heading `### N.M Title` / `#### N.M.K Title`.
fn section_id(line: &str) -> str:
    if line.starts_with("### "):
        let w = word_after(line, "### ")
        if w.len() > 0 and is_digit(w[0]) and w.contains("."): return w.clone()
    ""

fn is_fence(line: &str) -> bool: line.trim().starts_with("```")

fn is_heading(line: &str) -> bool: line.starts_with("#")

// GitHub-style anchor for a heading's text.
fn anchor(text: &str) -> str:
    var out = ""
    for i in 0..text.len() as i32:
        let c = text[i]
        if is_digit(c) or is_lower(c) or c == '-' or c == '_': out = out ++ text.slice(i, i + 1)
        else if is_upper(c): out = out ++ text.slice(i, i + 1).to_lower()
        else if c == ' ': out = out ++ "-"
    out

fn slug(text: &str) -> str:
    var out = ""
    var dash = true
    for i in 0..text.len() as i32:
        let c = text[i]
        if is_digit(c) or is_lower(c):
            out = out ++ text.slice(i, i + 1)
            dash = false
        else if is_upper(c):
            out = out ++ text.slice(i, i + 1).to_lower()
            dash = false
        else if not dash:
            out = out ++ "-"
            dash = true
    while out.ends_with("-"): out = out.slice(0, out.len() - 1)
    if out.len() > 60:
        var cut = 60
        while cut > 0 and out[cut] != '-': cut = cut - 1
        if cut > 0: out = out.slice(0, cut)
    out

fn dirname(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path[i] == '/': last = i
    if last < 0: return ""
    path.slice(0, last)

fn write_lines(path: &str, lines: &Vec[str]):
    let dir = dirname(path)
    if dir.len() > 0: assert(mkdir_p(dir) == 0)
    assert(write_file(path, lines.join("\n")) == 0)

fn read_lines(path: &str) -> Vec[str]:
    let text = read_file(path) ?? ""
    if text.len() == 0:
        eprint("error: could not read " ++ path)
        exit_code(1)
    var out: Vec[str] = Vec.new()
    for line in text.split("\n"): out.push(line.clone())
    out

fn push_range(dst: Vec[str], src: &Vec[str], from: i32, to: i32) -> Vec[str]:
    var out = dst
    for i in from..to: out.push(src[i].clone())
    out

fn rfind_byte(text: &str, c: i32) -> i32:
    var last = -1
    for i in 0..text.len() as i32:
        if text[i] == c: last = i
    last

// Index of the next heading line at or after `from` that is outside a code fence
// (fence state is tracked from `start`), or `end`.
fn next_heading(lines: &Vec[str], start: i32, from: i32, end: i32) -> i32:
    var fence = false
    for i in start..end:
        if is_fence(lines[i]): fence = not fence
        else if i >= from and not fence and is_heading(lines[i]): return i
    end

fn pointer_line(id: &str, title: &str, file: &str) -> str:
    "*§" ++ id ++ " " ++ title ++ " moved to `docs/spec/" ++ file ++ "`.*"

// ---------------------------------------------------------------- split-spec

fn split_spec:
    let chapters = parse_pairs(chapter_table())
    let sections = parse_pairs(section_table())
    let lines = read_lines("docs/with-specification.md")
    let n = lines.len() as i32

    // Front matter: everything before `# Part I`.
    var part_start = -1
    for i in 0..n:
        if lines[i].starts_with("# Part I "):
            part_start = i
            break
    assert(part_start > 0)

    var readme: Vec[str] = Vec.new()
    readme = push_range(move readme, lines, 0, part_start)
    readme.push("## Table of Contents")
    readme.push("")

    // Walk the parts and chapters.
    var i = part_start
    var fence = false
    var chapter_start = -1
    var chapter_id_now = ""
    var pending_part = ""
    while i <= n:
        var boundary = i == n
        var starts_part = false
        var starts_chapter = false
        if i < n:
            if is_fence(lines[i]): fence = not fence
            else if not fence and lines[i].starts_with("# Part "): starts_part = true
            else if not fence and chapter_id(lines[i]).len() > 0: starts_chapter = true
        if starts_part or starts_chapter: boundary = true
        if boundary and chapter_start >= 0:
            readme = emit_chapter(lines, chapter_start, i, chapter_id_now, chapters, sections, move readme)
            chapter_start = -1
        if boundary and pending_part.len() > 0 and (starts_chapter or i == n):
            // The lines between the part heading and its first chapter are
            // the part block, kept verbatim under the part's TOC heading.
            readme.push("### " ++ pending_part.slice(2, pending_part.len()))
            var j = part_line_index(lines, pending_part, part_start, i) + 1
            while j < i:
                readme.push(lines[j].clone())
                j = j + 1
            pending_part = ""
        if starts_part: pending_part = lines[i].clone()
        if starts_chapter:
            chapter_start = i
            chapter_id_now = chapter_id(lines[i])
        i = i + 1
    write_lines("docs/spec/README.md", readme)
    assert(remove_file("docs/with-specification.md") == 0)
    print("split-spec: wrote docs/spec/README.md and the chapter files")

fn part_line_index(lines: &Vec[str], heading: &str, from: i32, to: i32) -> i32:
    for i in from..to:
        if lines[i] == heading: return i
    -1

fn emit_chapter(lines: &Vec[str], start: i32, end: i32, id: &str, chapters: &Vec[Pair], sections: &Vec[Pair], toc: Vec[str]) -> Vec[str]:
    var readme = toc
    let file = lookup(chapters, id)
    if file.len() == 0:
        eprint("error: chapter " ++ id ++ " has no file in chapter_table")
        exit_code(1)
    let heading = lines[start].clone()
    let title = heading.slice(3, heading.len())
    readme.push("- [§" ++ title ++ "](" ++ file ++ ")")
    var out: Vec[str] = Vec.new()
    out.push("# " ++ title)
    var i = start + 1
    while i < end:
        let sid = section_id(lines[i])
        let sfile = if sid.len() > 0: lookup(sections, sid) else: ""
        if sfile.len() > 0:
            let send = next_heading(lines, start, i + 1, end)
            let stitle = lines[i].slice(4, lines[i].len())
            let stext = stitle.slice(sid.len() + 1, stitle.len())
            var sec: Vec[str] = Vec.new()
            sec.push("# " ++ stitle)
            sec = push_range(move sec, lines, i + 1, send)
            write_lines("docs/spec/" ++ sfile, sec)
            readme.push("  - [§" ++ stitle ++ "](" ++ sfile ++ ")")
            out.push(pointer_line(sid, stext, sfile))
            if send > i + 1 and lines[send - 1].len() == 0: out.push("")
            i = send
            continue
        if sid.len() > 0 and next_heading(lines, start, i, i + 1) == i:
            let stitle = lines[i].slice(4, lines[i].len())
            readme.push("  - [§" ++ stitle ++ "](" ++ file ++ "#" ++ anchor(stitle) ++ ")")
        out.push(lines[i].clone())
        i = i + 1
    write_lines("docs/spec/" ++ file, out)
    readme

// ---------------------------------------------------------------- verify-spec

fn strip_pointer_file(line: &str) -> str:
    // `*§18.5 Toolchain moved to `docs/spec/toolchain/toolchain.md`.*`
    let marker = " moved to `docs/spec/"
    let at = line.find(marker)
    if not line.starts_with("*§") or at < 0 or not line.ends_with("`.*"): return ""
    line.slice(at + marker.len(), line.len() - 3)

fn link_target(line: &str) -> str:
    let open = line.find("](")
    if open < 0: return ""
    let rest = line.slice(open + 2, line.len())
    let close = rest.find(")")
    if close < 0: return ""
    rest.slice(0, close)

fn reassemble_spec -> Vec[str]:
    let readme = read_lines("docs/spec/README.md")
    var out: Vec[str] = Vec.new()
    var toc = -1
    for i in 0..readme.len() as i32:
        if readme[i] == "## Table of Contents":
            toc = i
            break
    assert(toc > 0)
    out = push_range(move out, readme, 0, toc)
    var i = toc + 1
    var in_raw = false
    while i < readme.len() as i32:
        let line = readme[i].clone()
        if line.starts_with("### Part "):
            out.push("# " ++ line.slice(4, line.len()))
            in_raw = true
        else if line.starts_with("- [§"):
            in_raw = false
            out = inline_chapter("docs/spec/" ++ link_target(line), move out)
        else if in_raw:
            out.push(line)
        i = i + 1
    out

fn inline_chapter(path: &str, acc: Vec[str]) -> Vec[str]:
    var out = acc
    let lines = read_lines(path)
    out.push("#" ++ lines[0])
    var i = 1
    while i < lines.len() as i32:
        let sfile = strip_pointer_file(lines[i])
        if sfile.len() > 0:
            let sec = read_lines("docs/spec/" ++ sfile)
            out.push("##" ++ sec[0])
            out = push_range(move out, sec, 1, sec.len() as i32)
            if sec.len() > 1 and sec[sec.len() - 1].len() == 0 and i + 1 < lines.len() as i32 and lines[i + 1].len() == 0: i = i + 1
        else:
            out.push(lines[i].clone())
        i = i + 1
    out

fn report_compare(label: &str, rebuilt: &Vec[str], original_path: &str) -> i32:
    let original = read_lines(original_path)
    let rebuilt_text = rebuilt.join("\n")
    let original_text = original.join("\n")
    if rebuilt_text == original_text:
        print(label ++ ": reassembled text is byte-identical to " ++ original_path ++ f" ({original_text.len()} bytes, {original.len()} lines)")
        return 0
    var k = 0
    while k < rebuilt.len() as i32 and k < original.len() as i32 and rebuilt[k] == original[k]: k = k + 1
    let out_path = "out/docs-restructure/" ++ label ++ "-reassembled.md"
    write_lines(out_path, rebuilt)
    eprint(label ++ f": DIFFERS at line {k + 1} (rebuilt {rebuilt.len()} lines, original {original.len()} lines); rebuilt text in " ++ out_path)
    if k < original.len() as i32: eprint("  original: " ++ original[k])
    if k < rebuilt.len() as i32: eprint("  rebuilt:  " ++ rebuilt[k])
    1

// ---------------------------------------------------------------- split-decisions

fn entry_date(lines: &Vec[str], start: i32, end: i32) -> str:
    for i in start..end:
        if lines[i].starts_with("**Date:** "): return lines[i].slice(10, 20)
    ""

fn entry_id(title: &str) -> str:
    if not title.starts_with("D"): return ""
    var k = 1
    while k < title.len() as i32 and is_digit(title[k]): k = k + 1
    if k == 1 or not title.slice(k, title.len()).starts_with(" — "): return ""
    title.slice(0, k)

fn split_decisions:
    let lines = read_lines("docs/decisions.md")
    let n = lines.len() as i32
    var readme: Vec[str] = Vec.new()
    var first = -1
    var fence = false
    for i in 0..n:
        if is_fence(lines[i]): fence = not fence
        else if not fence and lines[i].starts_with("## "):
            first = i
            break
    assert(first > 0)
    readme = push_range(move readme, lines, 0, first)
    readme.push("## Decisions")
    readme.push("")
    var start = first
    fence = false
    var i = first + 1
    while i <= n:
        var boundary = i == n
        if i < n:
            if is_fence(lines[i]): fence = not fence
            else if not fence and lines[i].starts_with("## "): boundary = true
        if boundary:
            let title = lines[start].slice(3, lines[start].len())
            let date = entry_date(lines, start, i)
            if date.len() != 10:
                eprint("error: no **Date:** line in entry: " ++ title)
                exit_code(1)
            let id = entry_id(title)
            let rest = if id.len() > 0: title.slice(id.len() + 3, title.len()) else: title.clone()
            let file = if id.len() > 0: date ++ "-" ++ id ++ "-" ++ slug(rest) ++ ".md" else: date ++ "-" ++ slug(rest) ++ ".md"
            var entry: Vec[str] = Vec.new()
            entry.push("# " ++ title)
            entry = push_range(move entry, lines, start + 1, i)
            write_lines("docs/meetings/" ++ file, entry)
            readme.push("- [" ++ title ++ "](" ++ file ++ ")")
            start = i
        i = i + 1
    write_lines("docs/meetings/README.md", readme)
    assert(remove_file("docs/decisions.md") == 0)
    print("split-decisions: wrote docs/meetings/README.md and the decision files")

fn reassemble_decisions -> Vec[str]:
    let readme = read_lines("docs/meetings/README.md")
    var out: Vec[str] = Vec.new()
    var idx = -1
    for i in 0..readme.len() as i32:
        if readme[i] == "## Decisions":
            idx = i
            break
    assert(idx > 0)
    out = push_range(move out, readme, 0, idx)
    for i in idx..readme.len() as i32:
        if not readme[i].starts_with("- ["): continue
        let entry = read_lines("docs/meetings/" ++ link_target(readme[i]))
        out.push("#" ++ entry[0])
        out = push_range(move out, entry, 1, entry.len() as i32)
    out

// ---------------------------------------------------------------- move

fn move_files:
    let moves = parse_pairs(move_table())
    for i in 0..moves.len() as i32:
        let src = moves[i].key.clone()
        let dst = moves[i].value.clone()
        if not file_exists(src):
            if file_exists(dst):
                print("already moved: " ++ dst)
                continue
            eprint("error: missing " ++ src)
            exit_code(1)
        assert(mkdir_p(dirname(dst)) == 0)
        let rc = command("git").arg("mv").arg(src.clone()).arg(dst.clone()).run()
        if rc != 0:
            eprint("error: git mv failed for " ++ src)
            exit_code(rc)
    print(f"move: {moves.len()} files moved")

fn list_moves:
    let moves = parse_pairs(move_table())
    for i in 0..moves.len() as i32: print(moves[i].key ++ " -> " ++ moves[i].value)

// ---------------------------------------------------------------- rewrite-refs

// The spec file that holds a cited section: the longest known prefix of the
// section id (18.5b.6 -> 18.5b -> cli-one-liners.md; 4.3a.1 -> chapter 4).
fn spec_file_for(id: &str, chapters: &Vec[Pair], sections: &Vec[Pair]) -> str:
    var probe = id.clone()
    while probe.len() > 0:
        let hit = lookup(sections, probe)
        if hit.len() > 0: return "docs/spec/" ++ hit
        let dot = rfind_byte(probe, '.')
        if dot < 0: break
        probe = probe.slice(0, dot)
    var k = 0
    while k < id.len() as i32 and is_digit(id[k]): k = k + 1
    if k < id.len() as i32 and is_lower(id[k]) and (k + 1 == id.len() as i32 or id[k + 1] == '.'): k = k + 1
    let hit = lookup(chapters, id.slice(0, k))
    if hit.len() > 0: return "docs/spec/" ++ hit
    "docs/spec/README.md"

// A section id starting at `at` in `line` ("§" already consumed).
fn section_ref_at(line: &str, at: i64) -> str:
    var k = at
    let n = line.len()
    if k >= n or not is_digit(line[k]): return ""
    while k < n and is_digit(line[k]): k = k + 1
    if k < n and is_lower(line[k]) and (k + 1 >= n or not is_lower(line[k + 1])): k = k + 1
    while k + 1 < n and line[k] == '.' and is_digit(line[k + 1]):
        k = k + 1
        while k < n and is_digit(line[k]): k = k + 1
        if k < n and is_lower(line[k]) and (k + 1 >= n or not is_lower(line[k + 1])): k = k + 1
    line.slice(at, k)

// The § reference nearest to `pos` on the line: the first after it, else the last before.
fn nearest_section_ref(line: &str, pos: i64) -> str:
    var best_before = ""
    var i: i64 = 0
    let n = line.len()
    while i < n:
        let rest = line.slice(i, n)
        let at = rest.find("§")
        if at < 0: break
        let start = i + at + 2
        let id = section_ref_at(line, start)
        if id.len() > 0:
            if start > pos: return id
            best_before = id
        i = start
    best_before

fn decision_ref_at(line: &str, at: i32) -> str:
    let n = line.len() as i32
    if at > 0 and is_alnum(line[at - 1]): return ""
    var k = at + 1
    while k < n and is_digit(line[k]): k = k + 1
    if k == at + 1 or (k < n and is_alnum(line[k])): return ""
    line.slice(at, k)

fn nearest_decision_ref(line: &str, pos: i64) -> str:
    var best_before = ""
    for i in 0..line.len() as i32:
        if line[i] != 'D': continue
        let id = decision_ref_at(line, i)
        if id.len() == 0: continue
        if i > pos: return id
        best_before = id
    best_before

fn meeting_files -> Vec[Pair]:
    var out: Vec[Pair] = Vec.new()
    for entry in list_files_text("docs/meetings").split("\n"):
        let name = if entry.contains("/"): entry.slice(rfind_byte(entry, '/') + 1, entry.len()) else: entry.clone()
        if name.len() < 12 or not name.ends_with(".md"): continue
        let tail = name.slice(11, name.len())
        if not tail.starts_with("D"): continue
        var k = 1
        while k < tail.len() as i32 and is_digit(tail[k]): k = k + 1
        if k > 1 and k < tail.len() as i32 and tail[k] == '-':
            out.push(Pair { key: tail.slice(0, k), value: "docs/meetings/" ++ name })
    out

fn replace_all(text: &str, old: &str, new_text: &str) -> str:
    if not text.contains(old): return text.clone()
    text.replace(old, new_text)

fn rewrite_line(line: &str, moves: &Vec[Pair], chapters: &Vec[Pair], sections: &Vec[Pair], meetings: &Vec[Pair]) -> str:
    var out = line.clone()
    let spec = "docs/with-specification.md"
    while out.contains(spec):
        let at = out.find(spec)
        let id = nearest_section_ref(out, at)
        let target = if id.len() > 0: spec_file_for(id, chapters, sections) else: "docs/spec/README.md"
        out = out.slice(0, at) ++ target ++ out.slice(at + spec.len(), out.len())
    let dec = "docs/decisions.md"
    while out.contains(dec):
        let at = out.find(dec)
        let id = nearest_decision_ref(out, at)
        let hit = if id.len() > 0: lookup(meetings, id) else: ""
        let target = if hit.len() > 0: hit else: "docs/meetings/README.md"
        out = out.slice(0, at) ++ target ++ out.slice(at + dec.len(), out.len())
    for i in 0..moves.len() as i32:
        out = replace_all(out, moves[i].key, moves[i].value)
    out

fn text_file(path: &str) -> bool:
    path.ends_with(".md") or path.ends_with(".w") or path.ends_with(".toml") or path.ends_with(".txt") or
    path.ends_with(".yml") or path.ends_with(".yaml") or path.ends_with(".sh") or path.ends_with(".nix") or
    path.ends_with(".json") or path.ends_with(".tsv") or path.ends_with(".lock") or path.ends_with(".gitattributes") or
    path.ends_with("Dockerfile") or path.ends_with(".fish") or path.ends_with(".s")

fn rewrite_refs:
    var moves = parse_pairs(move_table())
    // Longest old path first, so no old path is rewritten inside a longer one.
    var sorted: Vec[Pair] = Vec.new()
    while moves.len() > 0:
        var best = 0
        for i in 0..moves.len() as i32:
            if moves[i].key.len() > moves[best].key.len(): best = i
        sorted.push(Pair { key: moves[best].key.clone(), value: moves[best].value.clone() })
        moves.remove(best)
    let chapters = parse_pairs(chapter_table())
    let sections = parse_pairs(section_table())
    let meetings = meeting_files()
    assert(mkdir_p("out/docs-restructure") == 0)
    let list = "out/docs-restructure/tracked.txt"
    assert(command("sh").arg("-c").arg("git ls-files > " ++ list).run() == 0)
    var files = 0
    var changed = 0
    for path in (read_file(list) ?? "").split("\n"):
        if path.len() == 0 or not text_file(path): continue
        if path.starts_with("docs/completed/") or path.starts_with("docs/meetings/") or path.starts_with(".reference/"): continue
        if path == "tools/docs_restructure.w": continue
        let text = read_file(path) ?? ""
        if not text.contains("docs/"): continue
        files = files + 1
        var out: Vec[str] = Vec.new()
        var edits = 0
        for line in text.split("\n"):
            let fixed = rewrite_line(line, sorted, chapters, sections, meetings)
            if fixed != line: edits = edits + 1
            out.push(fixed)
        if edits > 0:
            assert(write_file(path, out.join("\n")) == 0)
            changed = changed + 1
            print(f"{path}: {edits} line(s)")
    print(f"rewrite-refs: {files} files scanned, {changed} changed")

// ---------------------------------------------------------------- main

let argv = args()
if argv.len() < 2:
    eprint("usage: with run tools/docs_restructure.w split-spec|split-decisions|move|list-moves|rewrite-refs|verify-spec ORIG|verify-decisions ORIG")
    exit_code(2)
let mode = argv[1].clone()
if mode == "split-spec": split_spec()
else if mode == "split-decisions": split_decisions()
else if mode == "move": move_files()
else if mode == "list-moves": list_moves()
else if mode == "rewrite-refs": rewrite_refs()
else if mode == "verify-spec":
    assert(mkdir_p("out/docs-restructure") == 0)
    exit_code(report_compare("spec", reassemble_spec(), argv[2]))
else if mode == "verify-decisions":
    assert(mkdir_p("out/docs-restructure") == 0)
    exit_code(report_compare("decisions", reassemble_decisions(), argv[2]))
else:
    eprint("unknown mode: " ++ mode)
    exit_code(2)
