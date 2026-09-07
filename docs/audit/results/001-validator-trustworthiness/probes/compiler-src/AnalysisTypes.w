extern fn with_str_clone_ref(s: &str) -> str
// Shared compiler-analysis records. Sema, MIR, diagnostics, and codegen all
// emit this one schema so analysis commands join live compiler state instead
// of parsing human-oriented dumps.

pub enum AnalysisStage: i32:
    Ast = 1
    Sema = 2
    Mir = 3
    Abi = 4
    Codegen = 5
    Diagnostic = 6
    Source = 7

impl Copy for AnalysisStage

pub enum AnalysisFactKind: i32:
    Declaration = 1
    Signature = 2
    Parameter = 3
    Receiver = 4
    EffectEdge = 5
    Specialization = 6
    Call = 7
    CallArgument = 8
    Body = 9
    Local = 10
    Place = 11
    Ownership = 12
    Drop = 13
    CodegenArgument = 14
    Diagnostic = 15
    Phase = 16
    Invariant = 17
    SourceMatch = 18
    Type = 19
    Field = 20
    Expression = 21
    AstNode = 22
    MethodRegistration = 23
    MethodResolution = 24

// Stable analysis-domain receiver modes. Keep tools on this public schema rather
// than exposing Sema's internal ReceiverMode representation.
impl Copy for AnalysisFactKind

pub enum AnalysisReceiverMode: i32:
    None = 0
    Read = 1
    Mut = 2
    Move = 3
    Missing = 4

impl Copy for AnalysisReceiverMode

pub enum AnalysisDeclarationFlag: i32:
    ExplicitReceiver = 256
    Generic = 512
    ReceiverProven = 1024
    InImpl = 2048
    TraitImpl = 4096
    TopLevelMethod = 8192
    SyntheticReceiver = 16384
    TraitDeclaration = 32768

pub enum AnalysisMethodRegistrationFlag: i32:
    Inherent = 1
    Extension = 2
    Generic = 4
    TraitImpl = 8
    Scoped = 16
    Exact = 32
    Missing = 64

// Public analysis-domain diagnostic severity. Compiler clients consume this
// schema instead of reaching into Diagnostic.w's private representation.
pub enum AnalysisDiagnosticSeverity: i32:
    Error = 1
    Warning = 2
    Note = 3

pub fn analysis_required_receiver_mode(effects: i32) -> AnalysisReceiverMode:
    if effects & 12 != 0: return AnalysisReceiverMode.Move
    if effects & 2 != 0: return AnalysisReceiverMode.Mut
    AnalysisReceiverMode.Read

pub fn analysis_receiver_keyword(mode: AnalysisReceiverMode) -> str:
    if mode == AnalysisReceiverMode.Read: return "fn"
    if mode == AnalysisReceiverMode.Mut: return "mut fn"
    if mode == AnalysisReceiverMode.Move: return "move fn"
    ""

enum AnalysisMarshalStrategy: i32:
    DirectValue = 1
    TransparentSlot = 2
    ExistingPointer = 3
    PlaceAddress = 4
    TemporaryAddress = 5
    MissingSignature = 6
    CalleePlaceAlias = 7
    CalleeOwnedCopy = 8
    CalleeDirectValue = 9

impl Copy for AnalysisMarshalStrategy

fn analysis_marshal_strategy_name(strategy: AnalysisMarshalStrategy) -> str:
    if strategy == AnalysisMarshalStrategy.DirectValue: return "direct-value"
    if strategy == AnalysisMarshalStrategy.TransparentSlot: return "transparent-slot"
    if strategy == AnalysisMarshalStrategy.ExistingPointer: return "existing-pointer"
    if strategy == AnalysisMarshalStrategy.PlaceAddress: return "place-address"
    if strategy == AnalysisMarshalStrategy.TemporaryAddress: return "temporary-address"
    if strategy == AnalysisMarshalStrategy.MissingSignature: return "missing-signature"
    if strategy == AnalysisMarshalStrategy.CalleePlaceAlias: return "callee-place-alias"
    if strategy == AnalysisMarshalStrategy.CalleeOwnedCopy: return "callee-owned-copy"
    if strategy == AnalysisMarshalStrategy.CalleeDirectValue: return "callee-direct-value"
    "unknown"

pub type AnalysisFact {
    stage: AnalysisStage,
    kind: AnalysisFactKind,
    id: i32,
    parent: i32,
    node: i32,
    body_sym: i32,
    symbol: i32,
    owner: i32,
    index: i32,
    type_id: i32,
    effects: i32,
    flags: i32,
    source_file: i32,
    start: i32,
    end: i32,
    line: i32,
    column: i32,
    path: str,
    name: str,
    detail: str,
}

pub type AnalysisReport {
    facts: Vec[AnalysisFact],
    violations: Vec[str],
    notes: Vec[str],
}

type AnalysisBackendResult {
    report: AnalysisReport,
    status: i32,
}

fn AnalysisReport.init -> AnalysisReport:
    AnalysisReport { facts: Vec.new(), violations: Vec.new(), notes: Vec.new() }

fn AnalysisFact.new(stage: AnalysisStage, kind: AnalysisFactKind) -> AnalysisFact:
    AnalysisFact {
        stage,
        kind,
        id: -1,
        parent: -1,
        node: 0,
        body_sym: 0,
        symbol: 0,
        owner: 0,
        index: -1,
        type_id: 0,
        effects: 0,
        flags: 0,
        source_file: 0,
        start: 0,
        end: 0,
        line: 0,
        column: 0,
        path: "",
        name: "",
        detail: "",
    }

impl AnalysisFact:
    fn owned_copy() -> AnalysisFact:
        AnalysisFact {
            stage: self.stage,
            kind: self.kind,
            id: self.id,
            parent: self.parent,
            node: self.node,
            body_sym: self.body_sym,
            symbol: self.symbol,
            owner: self.owner,
            index: self.index,
            type_id: self.type_id,
            effects: self.effects,
            flags: self.flags,
            source_file: self.source_file,
            start: self.start,
            end: self.end,
            line: self.line,
            column: self.column,
            path: with_str_clone_ref(self.path),
            name: with_str_clone_ref(self.name),
            detail: with_str_clone_ref(self.detail),
        }

impl AnalysisReport:
    fn add(fact: AnalysisFact): self.facts.push(move fact)
    fn fail(message: &str): self.violations.push(with_str_clone_ref(message))
    fn note(message: &str): self.notes.push(with_str_clone_ref(message))
    fn ok(): self.violations.len() == 0

    fn merge(other: &AnalysisReport):
        for i in 0..other.facts.len() as i32:
            let fact = other.facts.get(i as i64)
            self.facts.push(fact.owned_copy())
        for i in 0..other.violations.len() as i32:
            self.violations.push(with_str_clone_ref(copy other.violations.get(i as i64)))
        for i in 0..other.notes.len() as i32:
            self.notes.push(with_str_clone_ref(copy other.notes.get(i as i64)))

fn analysis_stage_name(stage: AnalysisStage) -> str:
    if stage == AnalysisStage.Ast: return "ast"
    if stage == AnalysisStage.Sema: return "sema"
    if stage == AnalysisStage.Mir: return "mir"
    if stage == AnalysisStage.Abi: return "abi"
    if stage == AnalysisStage.Codegen: return "codegen"
    if stage == AnalysisStage.Diagnostic: return "diagnostic"
    if stage == AnalysisStage.Source: return "source"
    "unknown"

fn analysis_kind_name(kind: AnalysisFactKind) -> str:
    if kind == AnalysisFactKind.Declaration: return "declaration"
    if kind == AnalysisFactKind.Signature: return "signature"
    if kind == AnalysisFactKind.Parameter: return "parameter"
    if kind == AnalysisFactKind.Receiver: return "receiver"
    if kind == AnalysisFactKind.EffectEdge: return "effect-edge"
    if kind == AnalysisFactKind.Specialization: return "specialization"
    if kind == AnalysisFactKind.Call: return "call"
    if kind == AnalysisFactKind.CallArgument: return "call-argument"
    if kind == AnalysisFactKind.Body: return "body"
    if kind == AnalysisFactKind.Local: return "local"
    if kind == AnalysisFactKind.Place: return "place"
    if kind == AnalysisFactKind.Ownership: return "ownership"
    if kind == AnalysisFactKind.Drop: return "drop"
    if kind == AnalysisFactKind.CodegenArgument: return "codegen-argument"
    if kind == AnalysisFactKind.Diagnostic: return "diagnostic"
    if kind == AnalysisFactKind.Phase: return "phase"
    if kind == AnalysisFactKind.Invariant: return "invariant"
    if kind == AnalysisFactKind.SourceMatch: return "source-match"
    if kind == AnalysisFactKind.Type: return "type"
    if kind == AnalysisFactKind.Field: return "field"
    if kind == AnalysisFactKind.Expression: return "expression"
    if kind == AnalysisFactKind.AstNode: return "ast-node"
    if kind == AnalysisFactKind.MethodRegistration: return "method-registration"
    if kind == AnalysisFactKind.MethodResolution: return "method-resolution"
    "unknown"

fn analysis_slice(text: &str, start: i32, end: i32): text.slice(start as i64, end as i64)

fn analysis_find_from(text: &str, needle: &str, start: i32) -> i32:
    let n = text.len() as i32
    let m = needle.len() as i32
    if m == 0:
        return start
    var i = start
    while i + m <= n:
        var j = 0
        while j < m and text.byte_at((i + j) as i64) == needle.byte_at(j as i64):
            j = j + 1
        if j == m:
            return i
        i = i + 1
    -1

fn analysis_parse_i32(text: &str) -> i32:
    if text.len() == 0: return 0
    var sign = 1
    var i = 0
    if text.byte_at(0) == 45:
        sign = -1
        i = 1
    var value = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64) as i32
        if ch < 48 or ch > 57: return 0
        value = value * 10 + ch - 48
        i = i + 1
    value * sign

fn analysis_escape(text: &str) -> str:
    let parts: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        let c = text.byte_at(i as i64) as i32
        var replacement = ""
        if c == 92: replacement = "\\\\"
        else if c == 9: replacement = "\\t"
        else if c == 10: replacement = "\\n"
        else if c == 13: replacement = "\\r"
        if replacement.len() > 0:
            if i > start:
                parts.push(analysis_slice(text, start, i))
            parts.push(replacement)
            start = i + 1
    if start < text.len() as i32:
        parts.push(analysis_slice(text, start, text.len() as i32))
    parts.join("")

fn analysis_fact_field(fact: &AnalysisFact, field: &str) -> str:
    if field == "stage": return analysis_stage_name(fact.stage)
    if field == "kind": return analysis_kind_name(fact.kind)
    if field == "id": return f"{fact.id}"
    if field == "parent": return f"{fact.parent}"
    if field == "node": return f"{fact.node}"
    if field == "body": return f"{fact.body_sym}"
    if field == "symbol": return f"{fact.symbol}"
    if field == "owner": return f"{fact.owner}"
    if field == "index": return f"{fact.index}"
    if field == "type": return f"{fact.type_id}"
    if field == "effects": return f"{fact.effects}"
    if field == "flags": return f"{fact.flags}"
    if field == "source-file": return f"{fact.source_file}"
    if field == "start": return f"{fact.start}"
    if field == "end": return f"{fact.end}"
    if field == "line": return f"{fact.line}"
    if field == "column": return f"{fact.column}"
    if field == "path": return with_str_clone_ref(fact.path)
    if field == "name": return with_str_clone_ref(fact.name)
    if field == "detail": return with_str_clone_ref(fact.detail)
    ""

fn analysis_term_matches(fact: &AnalysisFact, term: &str) -> bool:
    var op = analysis_find_from(term, "&=", 0)
    var op_len = 2
    var mode = 3
    if op < 0:
        op = analysis_find_from(term, "!=", 0)
        mode = 2
    if op < 0:
        op = analysis_find_from(term, "~", 0)
        op_len = 1
        mode = 1
    if op < 0:
        op = analysis_find_from(term, "=", 0)
        op_len = 1
        mode = 0
    if op <= 0:
        return fact.name.contains(term) or fact.detail.contains(term)
    let field = analysis_slice(term, 0, op)
    let wanted = analysis_slice(term, op + op_len, term.len() as i32)
    let actual = analysis_fact_field(fact, field)
    if mode == 1: return actual.contains(wanted)
    if mode == 2: return actual != wanted
    if mode == 3:
        let mask = analysis_parse_i32(wanted)
        return analysis_parse_i32(actual) & mask == mask
    actual == wanted

fn analysis_fact_matches(fact: &AnalysisFact, query: &str) -> bool:
    if query.len() == 0 or query == "all":
        return true
    var start = 0
    var i = 0
    let n = query.len() as i32
    while i <= n:
        if i == n or query.byte_at(i as i64) as i32 == 44:
            if i > start:
                let term = analysis_slice(query, start, i)
                if not analysis_term_matches(fact, term):
                    return false
            start = i + 1
        if i == n:
            break
        i = i + 1
    true

impl AnalysisFact:
    fn render_tsv() -> str:
        "fact\t" ++ analysis_stage_name(self.stage) ++ "\t" ++ analysis_kind_name(self.kind) ++
            f"\t{self.id}\t{self.parent}\t{self.node}\t{self.body_sym}\t{self.symbol}\t{self.owner}\t{self.index}\t{self.type_id}\t{self.effects}\t{self.flags}\t{self.source_file}\t{self.start}\t{self.end}\t{self.line}\t{self.column}\t" ++
            analysis_escape(self.path) ++ "\t" ++ analysis_escape(self.name) ++ "\t" ++ analysis_escape(self.detail)

impl AnalysisReport:
    fn render_facts(query: &str) -> str:
        let lines: Vec[str] = Vec.new()
        lines.push("analysis-facts\tv2\tstage\tkind\tid\tparent\tnode\tbody\tsymbol\towner\tindex\ttype\teffects\tflags\tsource-file\tstart\tend\tline\tcolumn\tpath\tname\tdetail\n")
        for i in 0..self.facts.len() as i32:
            let fact = self.facts.get(i as i64)
            if analysis_fact_matches(fact, query):
                lines.push(fact.render_tsv())
                lines.push("\n")
        lines.join("")

    fn count_matching(query: &str) -> i32:
        var count = 0
        for i in 0..self.facts.len() as i32:
            let fact = self.facts.get(i as i64)
            if analysis_fact_matches(fact, query):
                count = count + 1
        count

    fn render_summary(query: &str) -> str:
        let lines: Vec[str] = Vec.new()
        lines.push("analysis-summary\tv1\n")
        let stages = [AnalysisStage.Ast, AnalysisStage.Sema, AnalysisStage.Mir, AnalysisStage.Abi, AnalysisStage.Codegen, AnalysisStage.Diagnostic, AnalysisStage.Source]
        let kinds = [
            AnalysisFactKind.Declaration, AnalysisFactKind.Signature, AnalysisFactKind.Parameter,
            AnalysisFactKind.Receiver, AnalysisFactKind.EffectEdge, AnalysisFactKind.Specialization,
            AnalysisFactKind.Call, AnalysisFactKind.CallArgument, AnalysisFactKind.Body,
            AnalysisFactKind.Local, AnalysisFactKind.Place, AnalysisFactKind.Ownership,
            AnalysisFactKind.Drop, AnalysisFactKind.CodegenArgument, AnalysisFactKind.Diagnostic,
            AnalysisFactKind.Phase, AnalysisFactKind.Invariant, AnalysisFactKind.SourceMatch,
            AnalysisFactKind.Type, AnalysisFactKind.Field, AnalysisFactKind.Expression,
            AnalysisFactKind.AstNode, AnalysisFactKind.MethodRegistration,
            AnalysisFactKind.MethodResolution,
        ]
        let stage_counts: Vec[i32] = Vec.new()
        let kind_counts: Vec[i32] = Vec.new()
        for i in 0..8: stage_counts.push(0)
        for i in 0..25: kind_counts.push(0)
        var total = 0
        for i in 0..self.facts.len() as i32:
            let fact = self.facts.get(i as i64)
            if not analysis_fact_matches(fact, query): continue
            total = total + 1
            stage_counts.set_i32(fact.stage as i64, stage_counts.get(fact.stage as i64) + 1)
            kind_counts.set_i32(fact.kind as i64, kind_counts.get(fact.kind as i64) + 1)
        lines.push(f"facts\t{total}\n")
        for i in 0..stages.len() as i32:
            let stage = stages[i]
            let count = stage_counts.get(stage as i64)
            if count > 0:
                lines.push("stage\t")
                lines.push(analysis_stage_name(stage))
                lines.push(f"\t{count}\n")
        for i in 0..kinds.len() as i32:
            let kind = kinds[i]
            let count = kind_counts.get(kind as i64)
            if count > 0:
                lines.push("kind\t")
                lines.push(analysis_kind_name(kind))
                lines.push(f"\t{count}\n")
        lines.join("")

    fn render_matrix(query: &str) -> str:
        let lines: Vec[str] = Vec.new()
        lines.push("analysis-matrix\tv2\tstage\tkind\tname\towner\tindex\ttype\teffects\tflags\tsource-file\tstart\tend\tdetail\n")
        for i in 0..self.facts.len() as i32:
            let fact = self.facts.get(i as i64)
            if not analysis_fact_matches(fact, query):
                continue
            lines.push("row\t")
            lines.push(analysis_stage_name(fact.stage))
            lines.push("\t")
            lines.push(analysis_kind_name(fact.kind))
            lines.push("\t")
            lines.push(analysis_escape(fact.name))
            lines.push(f"\t{fact.owner}\t{fact.index}\t{fact.type_id}\t{fact.effects}\t{fact.flags}\t{fact.source_file}\t{fact.start}\t{fact.end}\t")
            lines.push(analysis_escape(fact.detail))
            lines.push("\n")
        lines.join("")

    fn render_verdict(label: &str) -> str:
        let lines: Vec[str] = Vec.new()
        for i in 0..self.notes.len() as i32:
            lines.push("note: ")
            lines.push(with_str_clone_ref(self.notes.get(i as i64)))
            lines.push("\n")
        for i in 0..self.violations.len() as i32:
            lines.push("violation: ")
            lines.push(with_str_clone_ref(self.violations.get(i as i64)))
            lines.push("\n")
        lines.push(with_str_clone_ref(label))
        lines.push(f": facts={self.facts.len() as i32} violations={self.violations.len() as i32}")
        lines.push(if self.ok(): " ok\n" else: " FAILED\n")
        lines.join("")
