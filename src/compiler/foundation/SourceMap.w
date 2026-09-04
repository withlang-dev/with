// Wave 1 foundations: SourceMap registry keyed by FileId.

use compiler.foundation.Ids
use compiler.foundation.Source
use std.collections.HashMap

pub type SourceMap {
    sources: Vec[Source],
    path_index: HashMap[str, i32],
    next_file_raw: i32,
}

pub fn SourceMap.init -> SourceMap:
    var sm = SourceMap {
        sources: Vec.new(),
        path_index: HashMap.new(),
        next_file_raw: 1,
    }

    // Slot 0 reserved/sentinel.
    sm.sources.push(Source.from_string("<invalid>", "", file_id_from_raw(0)))
    sm

impl SourceMap:
    pub mut fn add_source_text(path: &str, text: &str) -> FileId:
        let existing = self.path_index.get(path)
        if existing.is_some():
            return file_id_from_raw(existing.unwrap())

        let id = file_id_from_raw(self.next_file_raw)
        self.next_file_raw = self.next_file_raw + 1
        self.path_index.insert(path.clone(), file_id_raw(id))
        self.sources.push(Source.from_string(path, text, id))
        id

    pub mut fn add_source_file(path: &str) -> FileId:
        let existing = self.path_index.get(path)
        if existing.is_some():
            return file_id_from_raw(existing.unwrap())

        let id = file_id_from_raw(self.next_file_raw)
        self.next_file_raw = self.next_file_raw + 1
        self.path_index.insert(path.clone(), file_id_raw(id))
        self.sources.push(Source.from_file(path, id))
        id

    pub fn contains(file_id: FileId) -> bool:
        if not file_id_is_valid(file_id):
            return false
        let raw = file_id_raw(file_id)
        raw >= 0 and raw < self.sources.len() as i32

    // A view, not a copy: Source owns Drop buffers (text, line offsets), and
    // an element copy would share them with the stored entry (double free).
    pub fn get_source(file_id: FileId) -> &Source:
        if not self.contains(file_id):
            return &self.sources[0]
        &self.sources[file_id_raw(file_id)]

    pub fn offset_to_location(file_id: FileId, offset: i32) -> SourceLocation:
        if not self.contains(file_id):
            return SourceLocation { line: 0, col: 0 }
        self.get_source(file_id).offset_to_location(offset)

    pub fn line_text(file_id: FileId, line: i32) -> str:
        if not self.contains(file_id):
            return ""
        self.get_source(file_id).line_text(line)
