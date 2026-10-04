// Archive -- pure-With static archive writer (BSD AR format with __.SYMDEF SORTED)

extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_eprint(s: &str) -> Unit
extern fn str_from_byte(b: i32) -> str
extern fn with_str_clone_ref(s: &str) -> str

fn ar_u32_le(v: i32) -> str:
    str_from_byte(v & 0xFF) ++ str_from_byte((v >> 8) & 0xFF) ++ str_from_byte((v >> 16) & 0xFF) ++ str_from_byte((v >> 24) & 0xFF)

fn ar_u32_be(v: i32) -> str:
    str_from_byte((v >> 24) & 0xFF) ++ str_from_byte((v >> 16) & 0xFF) ++ str_from_byte((v >> 8) & 0xFF) ++ str_from_byte(v & 0xFF)

fn ar_read_u16_le(data: &str, offset: i64) -> i32:
    if offset + 2 > data.len():
        return 0
    (data[offset] as i32) | ((data[offset + 1] as i32) << 8)

fn ar_read_u32_le(data: &str, offset: i64) -> i32:
    if offset + 4 > data.len():
        return 0
    (data[offset] as i32) | ((data[offset + 1] as i32) << 8) | ((data[offset + 2] as i32) << 16) | ((data[offset + 3] as i32) << 24)

fn ar_read_u64_le(data: &str, offset: i64) -> i64:
    if offset + 8 > data.len():
        return 0
    var out: i64 = 0
    for i in 0..8:
        out = out | ((data[offset + i] as i64) << ((i * 8) as u32))
    out

fn ar_basename(path: &str) -> str:
    var last_sep: i64 = -1
    for i in 0..path.len() as i32:
        if path[i] == 47:
            last_sep = i as i64
    if last_sep >= 0:
        return path.slice(last_sep + 1, path.len())
    with_str_clone_ref(path)

fn ar_pad_right(s: &str, width: i32, pad_byte: i32) -> str:
    var out = with_str_clone_ref(s)
    while out.len() < width as i64:
        out = out ++ str_from_byte(pad_byte)
    out

fn ar_format_decimal(value: i64) -> str:
    if value == 0:
        return "0"
    var out = ""
    var v = value
    while v > 0:
        out = str_from_byte((48 + (v % 10) as i32) as i32) ++ out
        v = v / 10
    out

fn ar_bsd_name_pad_len(name_len: i64) -> i64:
    let rem = name_len % 8
    if rem <= 4: name_len + 4 - rem else: name_len + 12 - rem

fn ar_member_header(name: &str, content_size: i64) -> str:
    let padded_name_len = ar_bsd_name_pad_len(name.len())
    let name_field = ar_pad_right("#1/" ++ ar_format_decimal(padded_name_len), 16, 32)
    let mtime_field = ar_pad_right("0", 12, 32)
    let uid_field = ar_pad_right("0", 6, 32)
    let gid_field = ar_pad_right("0", 6, 32)
    let mode_field = ar_pad_right("100644", 8, 32)
    let total_size = padded_name_len + content_size
    let size_field = ar_pad_right(ar_format_decimal(total_size), 10, 32)
    let fmag = "`\n"
    name_field ++ mtime_field ++ uid_field ++ gid_field ++ mode_field ++ size_field ++ fmag

fn ar_gnu_member_header(name: &str, content_size: i64) -> str:
    let name_field = ar_pad_right(name, 16, 32)
    let mtime_field = ar_pad_right("0", 12, 32)
    let uid_field = ar_pad_right("0", 6, 32)
    let gid_field = ar_pad_right("0", 6, 32)
    let mode_field = ar_pad_right("100644", 8, 32)
    let size_field = ar_pad_right(ar_format_decimal(content_size), 10, 32)
    let fmag = "`\n"
    name_field ++ mtime_field ++ uid_field ++ gid_field ++ mode_field ++ size_field ++ fmag

fn ar_gnu_member_size(content_size: i64) -> i64:
    let raw = 60 + content_size
    if raw % 2 == 0: raw else: raw + 1

fn ar_gnu_member_name_field(name: &str, long_name_offset: i32) -> str:
    if long_name_offset >= 0:
        return "/" ++ ar_format_decimal(long_name_offset as i64)
    if name == "/" or name == "//":
        return with_str_clone_ref(name)
    name ++ "/"

fn ar_gnu_needs_long_name(name: &str) -> bool:
    name.len() + 1 > 16

fn ar_member_size(name: &str, content_size: i64) -> i64:
    let padded_name_len = ar_bsd_name_pad_len(name.len())
    let raw = 60 + padded_name_len + content_size
    let rem = raw % 8
    if rem == 0: raw else: raw + 8 - rem

type ArSymbol:
    name: str
    member_index: i32

fn ar_str_compare(a: &str, b: &str) -> i32:
    let min_len = if a.len() < b.len(): a.len() else: b.len()
    for i in 0..min_len as i32:
        let ca = a[i] as i32
        let cb = b[i] as i32
        if ca < cb:
            return -1
        if ca > cb:
            return 1
    if a.len() < b.len():
        return -1
    if a.len() > b.len():
        return 1
    0

fn ar_sort_symbols(items: Vec[ArSymbol]) -> Vec[ArSymbol]:
    let result: Vec[ArSymbol] = Vec.new()
    while items.len() > 0:
        let item = items.remove(0)
        var pos = result.len() as i32
        for j in 0..result.len() as i32:
            if ar_str_compare(item.name, result[j].name) < 0:
                pos = j
                break
        let tail: Vec[ArSymbol] = Vec.new()
        while result.len() as i32 > pos:
            tail.push(result.remove(pos as i64))
        result.push(move item)
        while tail.len() > 0:
            result.push(tail.remove(0))
    result

fn extract_macho_symbols(data: &str) -> Vec[str]:
    let result: Vec[str] = Vec.new()
    if data.len() < 32:
        return result
    let magic = ar_read_u32_le(data, 0)
    if magic != 0xFEEDFACF as i32:
        return result
    let ncmds = ar_read_u32_le(data, 16)
    var cmd_offset: i64 = 32
    var symoff: i32 = 0
    var nsyms: i32 = 0
    var stroff: i32 = 0
    for ci in 0..ncmds:
        if cmd_offset + 8 > data.len():
            break
        let cmd = ar_read_u32_le(data, cmd_offset)
        let cmdsize = ar_read_u32_le(data, cmd_offset + 4)
        if cmd == 2 and cmd_offset + 24 <= data.len():
            symoff = ar_read_u32_le(data, cmd_offset + 8)
            nsyms = ar_read_u32_le(data, cmd_offset + 12)
            stroff = ar_read_u32_le(data, cmd_offset + 16)
            break
        cmd_offset = cmd_offset + cmdsize as i64
    if nsyms == 0 or symoff == 0 or stroff == 0:
        return result
    for si in 0..nsyms:
        let entry_off = symoff as i64 + si as i64 * 16
        if entry_off + 16 > data.len():
            break
        let n_strx = ar_read_u32_le(data, entry_off)
        let n_type = data[entry_off + 4] as i32
        let is_ext = (n_type & 1) != 0
        let type_bits = (n_type >> 1) & 7
        if is_ext and type_bits != 0:
            let name_off = stroff as i64 + n_strx as i64
            if name_off < data.len():
                var name_end = name_off
                while name_end < data.len() and data[name_end] != 0:
                    name_end = name_end + 1
                if name_end > name_off:
                    result.push(data.slice(name_off, name_end))
    result

fn ar_elf_str_at(data: &str, start: i64) -> str:
    if start <= 0 or start >= data.len():
        return ""
    var end = start
    while end < data.len() and data[end] != 0:
        end = end + 1
    if end <= start:
        return ""
    data.slice(start, end)

fn extract_elf_symbols(data: &str) -> Vec[str]:
    let result: Vec[str] = Vec.new()
    if data.len() < 64:
        return result
    if data[0] != 0x7f or data[1] != 69 or data[2] != 76 or data[3] != 70:
        return result
    if data[4] != 2 or data[5] != 1:
        return result
    let shoff = ar_read_u64_le(data, 40)
    let shentsize = ar_read_u16_le(data, 58)
    let shnum = ar_read_u16_le(data, 60)
    if shoff <= 0 or shentsize <= 0 or shnum <= 0:
        return result
    for si in 0..shnum:
        let sh = shoff + (si * shentsize) as i64
        if sh + 64 > data.len():
            break
        let sh_type = ar_read_u32_le(data, sh + 4)
        if sh_type != 2 and sh_type != 11:
            continue
        let sym_off = ar_read_u64_le(data, sh + 24)
        let sym_size = ar_read_u64_le(data, sh + 32)
        let str_index = ar_read_u32_le(data, sh + 40)
        let sym_entsize_raw = ar_read_u64_le(data, sh + 56)
        let sym_entsize = if sym_entsize_raw > 0: sym_entsize_raw else: 24
        if sym_off <= 0 or sym_size <= 0 or str_index < 0 or str_index >= shnum:
            continue
        let str_sh = shoff + (str_index * shentsize) as i64
        if str_sh + 64 > data.len():
            continue
        let str_off = ar_read_u64_le(data, str_sh + 24)
        let str_size = ar_read_u64_le(data, str_sh + 32)
        if str_off <= 0 or str_size <= 0:
            continue
        var sym_pos = sym_off
        let sym_end = sym_off + sym_size
        while sym_pos + sym_entsize <= sym_end and sym_pos + 24 <= data.len():
            let name_off = ar_read_u32_le(data, sym_pos)
            let info = data[sym_pos + 4] as i32
            let shndx = ar_read_u16_le(data, sym_pos + 6)
            let bind = info >> 4
            let typ = info & 0x0f
            if name_off > 0 and shndx != 0 and (bind == 1 or bind == 2) and typ != 3 and typ != 4:
                let name = ar_elf_str_at(data, str_off + name_off as i64)
                if name.len() > 0:
                    result.push(name)
            sym_pos = sym_pos + sym_entsize
    result

// The external symbols a COFF object defines (#1915): a static library `with
// get` builds on Windows is windows-gnu objects, and an archive with no index
// of them links as if empty (lld: "undefined symbol: BZ2_bzlibVersion" from
// the package's own libbz2.a). The file header is machine(2) sections(2)
// timestamp(4) symtab-offset(4) symbol-count(4) ...; each symbol is 18 bytes:
// name(8, or 0000+string-table offset), value(4), section(i16), type(2),
// class(1), aux-count(1). A definition is an external (class 2) in a section
// (> 0), or a common symbol (section 0, value > 0); a weak external (class
// 105) defines its name too.
fn extract_coff_symbols(data: &str) -> Vec[str]:
    let result: Vec[str] = Vec.new()
    if data.len() < 20:
        return result
    let machine = ar_read_u16_le(data, 0)
    // x86-64, arm64, arm64ec, i386, armnt: the COFF objects clang writes.
    if machine != 0x8664 and machine != 0xaa64 and machine != 0xa641 and machine != 0x14c and machine != 0x1c4:
        return result
    let symtab = ar_read_u32_le(data, 8) as i64
    let count = ar_read_u32_le(data, 12) as i64
    if symtab <= 0 or count <= 0 or symtab + count * 18 > data.len():
        return result
    let strtab = symtab + count * 18
    var i: i64 = 0
    while i < count:
        let at = symtab + i * 18
        let section = ar_read_u16_le(data, at + 12)
        let signed_section = if section >= 0x8000: section - 0x10000 else: section
        let class = data[at + 16] as i32
        let aux = data[at + 17] as i64
        let value = ar_read_u32_le(data, at + 8)
        let defined = (class == 2 and (signed_section > 0 or (signed_section == 0 and value != 0))) or class == 105
        if defined:
            let name = if ar_read_u32_le(data, at) == 0:
                ar_elf_str_at(data, strtab + ar_read_u32_le(data, at + 4) as i64)
            else:
                ar_coff_short_name(data, at)
            if name.len() > 0:
                result.push(name)
        i = i + 1 + aux
    result

// An 8-byte COFF symbol name, NUL-padded.
fn ar_coff_short_name(data: &str, at: i64) -> str:
    var end = at
    while end < at + 8 and data[end] != 0:
        end = end + 1
    data.slice(at, end)

fn create_gnu_indexed_archive(output_path: &str, member_names: &Vec[str], member_data: &Vec[str], sorted: &Vec[ArSymbol]) -> i32:
    var string_table = ""
    for i in 0..sorted.len() as i32:
        string_table = string_table ++ sorted[i].name ++ str_from_byte(0)
    let ranlib_count = sorted.len() as i32
    let symtab_size = 4 + ranlib_count * 4 + string_table.len() as i32

    var long_name_table = ""
    let long_name_offsets: Vec[i32] = Vec.new()
    for i in 0..member_names.len() as i32:
        let name = member_names[i]
        if ar_gnu_needs_long_name(name):
            long_name_offsets.push(long_name_table.len() as i32)
            long_name_table = long_name_table ++ name ++ "/\n"
        else:
            long_name_offsets.push(-1)

    var member_offsets: Vec[i64] = Vec.new()
    var offset: i64 = 8 + ar_gnu_member_size(symtab_size as i64)
    if long_name_table.len() > 0:
        offset = offset + ar_gnu_member_size(long_name_table.len())
    for i in 0..member_names.len() as i32:
        member_offsets.push(offset)
        offset = offset + ar_gnu_member_size(member_data[i].len())

    var symtab = ar_u32_be(ranlib_count)
    for i in 0..ranlib_count:
        let sym = sorted[i]
        symtab = symtab ++ ar_u32_be(member_offsets[sym.member_index] as i32)
    symtab = symtab ++ string_table

    var archive = "!<arch>\n"
    archive = archive ++ ar_gnu_member_header("/", symtab.len())
    archive = archive ++ symtab
    if archive.len() % 2 != 0:
        archive = archive ++ "\n"

    if long_name_table.len() > 0:
        archive = archive ++ ar_gnu_member_header("//", long_name_table.len())
        archive = archive ++ long_name_table
        if archive.len() % 2 != 0:
            archive = archive ++ "\n"

    for i in 0..member_names.len() as i32:
        let name = member_names[i]
        let data = member_data[i]
        let name_field = ar_gnu_member_name_field(name, long_name_offsets[i])
        archive = archive ++ ar_gnu_member_header(name_field, data.len())
        archive = archive ++ data
        if archive.len() % 2 != 0:
            archive = archive ++ "\n"

    let rc = with_fs_write_file(output_path, archive)
    if rc != 0:
        with_eprint("error: archive: cannot write: " ++ output_path)
        return 1
    0

// The arguments a response file holds. A build system writes one when a
// command line would be too long (CMake's `ar qc lib.a @objects.rsp` for
// SDL's 268 objects on Windows). Quoting is the host's, as llvm-ar reads it:
// on Windows a backslash is a path character and escapes only a double
// quote; elsewhere (GNU) it escapes the next character and single quotes
// quote too.
pub fn ar_tokenize_response(text: &str, windows_quoting: bool) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    var token = ""
    var started = false
    var quote = 0
    var i = 0
    let n = text.len() as i32
    while i < n:
        let ch = text[i] as i32
        if quote != 0:
            if ch == quote:
                quote = 0
            else if ch == 92 and quote == 34 and i + 1 < n and (text[i + 1] == 34 or not windows_quoting):
                i = i + 1
                token = token ++ text.slice(i as i64, (i + 1) as i64)
            else:
                token = token ++ text.slice(i as i64, (i + 1) as i64)
        else if ch == 32 or ch == 9 or ch == 10 or ch == 13:
            if started:
                out.push(token)
                token = ""
                started = false
        else if ch == 34 or (ch == 39 and not windows_quoting):
            quote = ch
            started = true
        else if ch == 92 and i + 1 < n and (text[i + 1] == 34 or not windows_quoting):
            i = i + 1
            token = token ++ text.slice(i as i64, (i + 1) as i64)
            started = true
        else:
            token = token ++ text.slice(i as i64, (i + 1) as i64)
            started = true
        i = i + 1
    if started:
        out.push(token)
    out

// `args` with every `@file` replaced by the arguments that file holds
// (a response file may name another). `ok` is false when one cannot be read.
pub type ArResponseArgs {
    ok: bool,
    args: Vec[str],
}

pub fn ar_expand_response_args(args: &Vec[str], windows_quoting: bool, depth: i32) -> ArResponseArgs:
    let out: Vec[str] = Vec.new()
    for i in 0..args.len() as i32:
        let arg = args[i]
        if arg.len() < 2 or arg[0] != 64:
            out.push(with_str_clone_ref(arg))
            continue
        let path = arg.slice(1, arg.len())
        let text = with_fs_read_file(path)
        if text.len() == 0 or depth >= 8:
            with_eprint("error: archive: cannot read response file: " ++ path)
            return ArResponseArgs { ok: false, args: out }
        let inner = ar_expand_response_args(&ar_tokenize_response(text, windows_quoting), windows_quoting, depth + 1)
        if not inner.ok:
            return ArResponseArgs { ok: false, args: out }
        for j in 0..inner.args.len() as i32:
            out.push(with_str_clone_ref(inner.args[j]))
    ArResponseArgs { ok: true, args: out }

pub fn create_static_archive(output_path: &str, member_paths: &Vec[str]) -> i32:
    let member_count = member_paths.len() as i32
    let member_names: Vec[str] = Vec.new()
    let member_data: Vec[str] = Vec.new()
    for i in 0..member_count:
        let path = member_paths[i]
        let data = with_fs_read_file(path)
        if data.len() == 0:
            with_eprint("error: archive: cannot read member: " ++ path)
            return 1
        member_names.push(ar_basename(path))
        member_data.push(data)

    var gnu_index = false
    let all_symbols: Vec[ArSymbol] = Vec.new()
    for i in 0..member_count:
        let data = member_data[i]
        let elf_syms = extract_elf_symbols(data)
        let coff_syms = if elf_syms.len() == 0: extract_coff_symbols(data) else: Vec.new()
        // COFF objects index GNU-style too: lld reads that symbol table.
        let syms = if elf_syms.len() > 0 or coff_syms.len() > 0:
            gnu_index = true
            if elf_syms.len() > 0: elf_syms else: coff_syms
        else:
            extract_macho_symbols(data)
        for si in 0..syms.len() as i32:
            let sym = ArSymbol { name: with_str_clone_ref(syms[si]), member_index: i }
            all_symbols.push(move sym)
    let sorted = ar_sort_symbols(all_symbols)
    if gnu_index:
        return create_gnu_indexed_archive(output_path, member_names, member_data, sorted)

    var string_table = ""
    let string_offsets: Vec[i32] = Vec.new()
    for i in 0..sorted.len() as i32:
        string_offsets.push(string_table.len() as i32)
        string_table = string_table ++ sorted[i].name ++ str_from_byte(0)
    while string_table.len() % 8 != 0:
        string_table = string_table ++ str_from_byte(0)

    let ranlib_count = sorted.len() as i32
    let ranlib_array_size = ranlib_count * 8
    let symdef_name = "__.SYMDEF SORTED"
    let symdef_content_size = 4 + ranlib_array_size as i64 + 4 + string_table.len()

    var member_offsets: Vec[i64] = Vec.new()
    var offset: i64 = 8 + ar_member_size(symdef_name, symdef_content_size)
    for i in 0..member_count:
        member_offsets.push(offset)
        offset = offset + ar_member_size(member_names[i], member_data[i].len())

    var ranlib_data = ar_u32_le(ranlib_array_size)
    for i in 0..ranlib_count:
        let sym = sorted[i]
        ranlib_data = ranlib_data ++ ar_u32_le(string_offsets[i])
        ranlib_data = ranlib_data ++ ar_u32_le(member_offsets[sym.member_index] as i32)
    ranlib_data = ranlib_data ++ ar_u32_le(string_table.len() as i32)
    ranlib_data = ranlib_data ++ string_table

    var archive = "!<arch>\n"
    archive = archive ++ ar_member_header(symdef_name, symdef_content_size)
    let padded_symdef_name = ar_pad_right(symdef_name, ar_bsd_name_pad_len(symdef_name.len() as i64) as i32, 0)
    archive = archive ++ padded_symdef_name
    archive = archive ++ ranlib_data
    while archive.len() % 8 != 0:
        archive = archive ++ str_from_byte(0)

    for i in 0..member_count:
        let name = member_names[i]
        let data = member_data[i]
        archive = archive ++ ar_member_header(name, data.len())
        let padded_name = ar_pad_right(name, ar_bsd_name_pad_len(name.len()) as i32, 0)
        archive = archive ++ padded_name
        archive = archive ++ data
        while archive.len() % 8 != 0:
            archive = archive ++ str_from_byte(0)

    let rc = with_fs_write_file(output_path, archive)
    if rc != 0:
        with_eprint("error: archive: cannot write: " ++ output_path)
        return 1
    0
