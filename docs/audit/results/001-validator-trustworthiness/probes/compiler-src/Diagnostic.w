// Wave 1 foundations: diagnostics model + deterministic rendering.

use Span
use Source
use DiagnosticRender

extern fn with_eprint(s: &str) -> Unit
extern fn with_str_clone_ref(s: &str) -> str

enum DiagSeverity: i32:
    Error = 1
    Warning = 2
    Note = 3

// Legacy aliases kept for existing callers.
const SEV_ERROR: i32 = DiagSeverity.Error
const SEV_WARNING: i32 = DiagSeverity.Warning

type DiagnosticLabel {
    span: Span,
    message: str,
}

// Legacy alias kept for existing callers.
type Label = DiagnosticLabel

type Diagnostic {
    severity: i32,
    code: str,
    message: str,
    origin_file: str,
    origin_fn: str,
    origin_line: i32,
    origin_node: i32,
    primary: Span,
    labels: Vec[DiagnosticLabel],
    notes: Vec[str],
    helps: Vec[str],
}

fn diagnostic_owned_text(text: &str) -> str:
    with_str_clone_ref(text)

fn diagnostic_error(message: &str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Error,
        code: "",
        message: diagnostic_owned_text(message),
        origin_file: "",
        origin_fn: "",
        origin_line: 0,
        origin_node: 0,
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

fn diagnostic_warning(message: &str, primary: Span) -> Diagnostic:
    Diagnostic {
        severity: DiagSeverity.Warning,
        code: "",
        message: diagnostic_owned_text(message),
        origin_file: "",
        origin_fn: "",
        origin_line: 0,
        origin_node: 0,
        primary,
        labels: Vec.new(),
        notes: Vec.new(),
        helps: Vec.new(),
    }

fn Diagnostic.err(message: &str, span: Span) -> Diagnostic:
    diagnostic_error(message, span)

fn Diagnostic.warn(message: &str, span: Span) -> Diagnostic:
    diagnostic_warning(message, span)

impl Diagnostic:
    mut fn set_code(code: &str):
        self.code = diagnostic_owned_text(code)

    mut fn set_origin(file: &str, fn_name: &str, line: i32, node: i32):
        self.origin_file = diagnostic_owned_text(file)
        self.origin_fn = diagnostic_owned_text(fn_name)
        self.origin_line = line
        self.origin_node = node

    mut fn add_label(span: Span, message: &str) -> Unit:
        self.labels.push(DiagnosticLabel { span, message: diagnostic_owned_text(message) })

    mut fn add_note(message: &str) -> Unit:
        self.notes.push(diagnostic_owned_text(message))

    mut fn add_help(message: &str) -> Unit:
        self.helps.push(diagnostic_owned_text(message))

    fn render(source: &Source):
        let no_paths: Vec[str] = Vec.new()
        let no_texts: Vec[str] = Vec.new()
        self.render_with_label_sources(source, &no_paths, &no_texts)

    // Render with the primary span shifted back into an original file's
    // coordinates (generated-source mapping). Takes the offset instead of a
    // mutated copy: copying a Diagnostic out of a stored list aliases its
    // label/note buffers and double-frees on drop (#715 class).
    fn render_at_offset(source: &Source, gen_start: i32):
        let no_paths: Vec[str] = Vec.new()
        let no_texts: Vec[str] = Vec.new()
        self.render_with_label_sources_at_offset(source, &no_paths, &no_texts, gen_start)

    // #670: a label whose span lives in another file must resolve line/col
    // against THAT file's text and say which file it is. label_paths/label_texts
    // are parallel to labels; an empty path means "same file as the primary".
    fn render_with_label_sources(source: &Source, label_paths: &Vec[str], label_texts: &Vec[str]):
        self.render_with_label_sources_at_offset(source, label_paths, label_texts, 0)

    fn render_with_label_sources_at_offset(source: &Source, label_paths: &Vec[str], label_texts: &Vec[str], gen_start: i32):
        var pstart = self.primary.start - gen_start
        if pstart < 0:
            pstart = 0
        var pend = self.primary.end - gen_start
        if pend <= pstart:
            pend = pstart + 1
        let code: str = with_str_clone_ref(self.code)
        let message: str = with_str_clone_ref(self.message)
        with_eprint(render_diag_header(self.severity, code, message))

        let loc = source.offset_to_location(pstart)
        let source_path: str = with_str_clone_ref(source.path)
        with_eprint(render_diag_location(source_path, loc.line, loc.col))

        let line_text: str = source.line_text(loc.line)
        with_eprint(render_diag_source_line(loc.line, line_text))
        with_eprint(render_diag_marker_line(loc.col, span_underline_len(pstart, pend)))

        for i in 0..self.labels.len() as i32:
            let lab = &self.labels[i as i64]
            let label_message: str = with_str_clone_ref(lab.message)
            var label_path = ""
            if i < label_paths.len() as i32:
                label_path = with_str_clone_ref(label_paths.get(i as i64))
            if label_path.len() > 0 and label_path != source_path:
                let label_source = Source.from_string(label_path, label_texts.get(i as i64), lab.span.file)
                let lloc2 = label_source.offset_to_location(lab.span.start)
                with_eprint(render_diag_label_line_in_file(label_path, lloc2.line, lloc2.col, label_message))
            else:
                let lloc = source.offset_to_location(lab.span.start)
                with_eprint(render_diag_label_line(lloc.line, lloc.col, label_message))

        for i in 0..self.notes.len() as i32:
            let note: str = with_str_clone_ref(self.notes.get(i as i64))
            with_eprint(render_diag_note_line(note))
        for i in 0..self.helps.len() as i32:
            let help: str = with_str_clone_ref(self.helps.get(i as i64))
            with_eprint(render_diag_help_line(help))

pub type DiagnosticList {
    items: Vec[Diagnostic],
}

fn DiagnosticList.init -> DiagnosticList:
    DiagnosticList {
        items: Vec.new(),
    }

// No-op: reserved for future manual memory management.
impl DiagnosticList:
    fn deinit():
        return

    mut fn emit(diag: Diagnostic) -> Unit:
        // #759: an identical diagnostic (severity, message, primary span,
        // code) re-derived by a later pass over the same AST is one
        // diagnostic — the comptime-transform sema and check_module both
        // run declaration collection, and every decl-phase error rendered
        // twice. Same node + same words twice is never signal.
        for i in 0..self.items.len() as i32:
            let existing = self.items.get(i as i64)
            if existing.severity == diag.severity and
               existing.primary.file == diag.primary.file and
               existing.primary.start == diag.primary.start and
               existing.primary.end == diag.primary.end and
               existing.message == diag.message and
               existing.code == diag.code:
                return
        self.items.push(move diag)

    fn count() -> i32:
        self.items.len() as i32

    fn count_by_severity(severity: i32) -> i32:
        var n = 0
        for i in 0..self.items.len() as i32:
            if self.items.get(i as i64).severity == severity:
                n = n + 1
        n

    fn has_errors() -> bool:
        self.count_by_severity(DiagSeverity.Error) > 0

    fn render_all(source: &Source):
        for i in 0..self.items.len() as i32:
            self.items.get(i as i64).render(source)
            if i + 1 < self.items.len() as i32:
                with_eprint("")

    fn render_warnings(source: &Source):
        var printed = 0
        for i in 0..self.items.len() as i32:
            if self.items.get(i as i64).severity != DiagSeverity.Warning:
                continue
            if printed != 0:
                with_eprint("")
            self.items.get(i as i64).render(source)
            printed = printed + 1
