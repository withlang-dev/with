// Wave 1 foundations: SourceMap registry keyed by FileId.

use compiler.foundation.Ids
use compiler.foundation.Source

type SourceMap {
    sources: Vec[Source],
    path_index: HashMap[str, i32],
    next_file_raw: i32,
}

fn SourceMap.init -> SourceMap:
    var sm = SourceMap {
        sources: Vec.new(),
        path_index: HashMap.new(),
        next_file_raw: 1,
    }

    // Slot 0 reserved/sentinel.
    sm.sources.push(Source.from_string("<invalid>", "", file_id_from_raw(0)))
    sm

fn SourceMap.add_source_text(self: SourceMap, path: str, text: str) -> FileId:
    let existing = self.path_index.get(path)
    if existing.is_some():
        return file_id_from_raw(existing.unwrap())

    let id = file_id_from_raw(self.next_file_raw)
    self.next_file_raw = self.next_file_raw + 1
    self.path_index.insert(path, file_id_raw(id))
    self.sources.push(Source.from_string(path, text, id))
    id

fn SourceMap.add_source_file(self: SourceMap, path: str) -> FileId:
    let existing = self.path_index.get(path)
    if existing.is_some():
        return file_id_from_raw(existing.unwrap())

    let id = file_id_from_raw(self.next_file_raw)
    self.next_file_raw = self.next_file_raw + 1
    self.path_index.insert(path, file_id_raw(id))
    self.sources.push(Source.from_file(path, id))
    id

fn SourceMap.contains(self: SourceMap, file_id: FileId) -> bool:
    if not file_id_is_valid(file_id):
        return false
    let raw = file_id_raw(file_id)
    raw >= 0 and raw < self.sources.len() as i32

fn SourceMap.get_source(self: SourceMap, file_id: FileId) -> Source:
    if not self.contains(file_id):
        return self.sources.get(0)
    self.sources.get(file_id_raw(file_id) as i64)

fn SourceMap.offset_to_location(self: SourceMap, file_id: FileId, offset: i32) -> SourceLocation:
    if not self.contains(file_id):
        return SourceLocation { line: 0, col: 0 }
    self.get_source(file_id).offset_to_location(offset)

fn SourceMap.line_text(self: SourceMap, file_id: FileId, line: i32) -> str:
    if not self.contains(file_id):
        return ""
    self.get_source(file_id).line_text(line)
