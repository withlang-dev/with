// .xz decompression in With (#1915): a `with get` source archive that is a
// .tar.xz is unpacked by this compiler, not the host's tar. The .xz container
// (stream header, blocks, index) around LZMA2 chunks, around LZMA, as the
// .xz file format 1.1.0 and the LZMA specification describe them. Blocks
// with any filter chain other than a lone LZMA2 are refused by name; each
// block's check (CRC32, CRC64 or SHA-256) is verified.

use std.crypto.sha256

extern fn with_str_from_bytes(s: *const u8, len: i64) -> str

let XZ_MASK32: i64 = 4294967295

fn xz_crc32_table() -> List[i64]:
    let table: List[i64] = List.new()
    for n in 0..256:
        var c = n as i64
        for _ in 0..8:
            c = if c % 2 == 1: 0xEDB88320 ^ (c / 2) else: c / 2
        table.push(c)
    table

pub fn xz_crc32(data: &str, start: i64, end: i64) -> i64:
    let table = xz_crc32_table()
    var crc = XZ_MASK32
    for i in start..end:
        crc = table[((crc ^ data[i] as i64) & 255) as i32] ^ (crc >> 8)
    crc ^ XZ_MASK32

// CRC-64/XZ (ECMA-182, reflected). u64 arithmetic in i64: shifts are logical
// only through the u64 view.
fn xz_crc64(data: &List[u8]) -> u64:
    let poly: u64 = 0xC96C5795D7870F42
    let table: List[u64] = List.new()
    for n in 0..256:
        var c = n as u64
        for _ in 0..8:
            c = if c % 2 == 1: poly ^ (c >> 1) else: c >> 1
        table.push(c)
    var crc: u64 = 0xFFFFFFFFFFFFFFFF
    for i in 0..data.len():
        crc = table[((crc ^ data[i] as u64) & 255) as i32] ^ (crc >> 8)
    crc ^ 0xFFFFFFFFFFFFFFFF

fn xz_u32_le(data: &str, at: i64) -> i64:
    data[at] as i64 | (data[at + 1] as i64 << 8) | (data[at + 2] as i64 << 16) | (data[at + 3] as i64 << 24)

fn xz_u64_le(data: &str, at: i64) -> u64:
    xz_u32_le(data, at) as u64 | (xz_u32_le(data, at + 4) as u64 << 32)

// The LZMA decoder state: the range coder over `data`, the probability model,
// and the output, which is also the dictionary.
type XzLzma {
    data: str,
    at: i64,
    end: i64,
    range: i64,
    code: i64,
    probs: List[i32],
    lc: i32,
    lp: i32,
    pb: i32,
    state: i32,
    rep0: i64,
    rep1: i64,
    rep2: i64,
    rep3: i64,
    out: List[u8],
    dict_start: i64,
    problem: str,
}

// Probability array layout (offsets into probs).
const P_IS_MATCH = 0
const P_IS_REP = 192
const P_IS_REP_G0 = 204
const P_IS_REP_G1 = 216
const P_IS_REP_G2 = 228
const P_IS_REP0_LONG = 240
const P_POS_SLOT = 432
const P_SPEC_POS = 688
const P_ALIGN = 802
const P_LEN = 818
const P_REP_LEN = 1332
const P_LITERAL = 1846
// A length coder: choice, choice2, low[16][8], mid[16][8], high[256].
const LEN_CHOICE = 0
const LEN_CHOICE2 = 1
const LEN_LOW = 2
const LEN_MID = 130
const LEN_HIGH = 258

impl XzLzma:
    mut fn fail(message: &str):
        if self.problem.len() == 0: self.problem = message.to_owned()

    mut fn next_byte() -> i64:
        if self.at >= self.end:
            self.fail("an LZMA chunk ends early")
            return 0
        let b = self.data[self.at] as i64
        self.at = self.at + 1
        b

    mut fn init_range():
        self.range = XZ_MASK32
        self.code = 0
        let first = self.next_byte()
        if first != 0: self.fail("an LZMA chunk does not start with a zero byte")
        for _ in 0..4:
            self.code = ((self.code << 8) | self.next_byte()) & XZ_MASK32

    mut fn reset_state(new_lc: i32, new_lp: i32, new_pb: i32):
        self.lc = new_lc
        self.lp = new_lp
        self.pb = new_pb
        let count = P_LITERAL + 768 * (1 << ((new_lc + new_lp) as u32))
        self.probs = List.with_capacity(count as i64)
        for _ in 0..count: self.probs.push(1024)
        self.state = 0
        self.rep0 = 0
        self.rep1 = 0
        self.rep2 = 0
        self.rep3 = 0

    mut fn bit(index: isize) -> i32:
        let p = self.probs[index] as i64
        let bound = (self.range >> 11) * p
        var result: i32 = 0
        if self.code < bound:
            self.range = bound
            self.probs[index] = (p + ((2048 - p) >> 5)) as i32
        else:
            self.range = self.range - bound
            self.code = self.code - bound
            self.probs[index] = (p - (p >> 5)) as i32
            result = 1
        if self.range < 16777216:
            self.range = (self.range << 8) & XZ_MASK32
            self.code = ((self.code << 8) | self.next_byte()) & XZ_MASK32
        result

    mut fn direct_bits(count: i32) -> i64:
        var result: i64 = 0
        for _ in 0..count:
            self.range = self.range >> 1
            var b: i64 = 0
            if self.code >= self.range:
                self.code = self.code - self.range
                b = 1
            result = (result << 1) | b
            if self.range < 16777216:
                self.range = (self.range << 8) & XZ_MASK32
                self.code = ((self.code << 8) | self.next_byte()) & XZ_MASK32
        result

    mut fn bittree(base: i32, bits: i32) -> i32:
        var m: i32 = 1
        for _ in 0..bits:
            m = (m << 1) + self.bit(base + m)
        m - (1 << (bits as u32))

    mut fn bittree_reverse(base: i32, bits: i32) -> i32:
        var m = 1
        var symbol: i32 = 0
        for i in 0..bits:
            let b = self.bit(base + m)
            m = (m << 1) + b
            symbol = symbol | (b << (i as u32))
        symbol

    mut fn length(base: i32, pos_state: i32) -> i32:
        if self.bit(base + LEN_CHOICE) == 0:
            return self.bittree(base + LEN_LOW + pos_state * 8, 3)
        if self.bit(base + LEN_CHOICE2) == 0:
            return 8 + self.bittree(base + LEN_MID + pos_state * 8, 3)
        16 + self.bittree(base + LEN_HIGH, 8)

    mut fn distance(len: i32) -> i64:
        let len_state: i32 = if len < 3: len else: 3
        let slot = self.bittree(P_POS_SLOT + len_state * 64, 6)
        if slot < 4:
            return slot as i64
        let direct = (slot >> 1) - 1
        var dist = ((2 | (slot & 1)) as i64) << (direct as u32)
        if slot < 14:
            dist = dist + self.bittree_reverse(P_SPEC_POS + dist as i32 - slot - 1, direct) as i64
        else:
            dist = dist + (self.direct_bits(direct - 4) << 4)
            dist = dist + self.bittree_reverse(P_ALIGN, 4) as i64
        dist

    mut fn literal():
        let pos = self.out.len()
        let prev = if pos > self.dict_start: self.out[pos - 1] as i32 else: 0
        let base = P_LITERAL + 768 * ((((pos as i32) & ((1 << (self.lp as u32)) - 1)) << (self.lc as u32)) + (prev >> ((8 - self.lc) as u32)))
        var symbol = 1
        if self.state >= 7:
            var match_byte = self.out[pos - self.rep0 - 1] as i32
            while symbol < 256:
                let match_bit = (match_byte >> 7) & 1
                match_byte = match_byte << 1
                let b = self.bit(base + ((1 + match_bit) << 8) + symbol)
                symbol = (symbol << 1) | b
                if match_bit != b: break
        while symbol < 256:
            symbol = (symbol << 1) | self.bit(base + symbol)
        self.out.push((symbol - 256) as u8)
        self.state = if self.state < 4: 0 else if self.state < 10: self.state - 3 else: self.state - 6

    mut fn copy_match(len: i64):
        let dist = self.rep0 + 1
        if dist > self.out.len() - self.dict_start:
            self.fail("an LZMA match reaches before the dictionary")
            return
        for _ in 0..len:
            let b: u8 = self.out[self.out.len() - dist]
            self.out.push(b)

    // One LZMA chunk: `unpacked` bytes out, reading the chunk's packed bytes.
    mut fn decode_chunk(unpacked: i64):
        let goal = self.out.len() + unpacked
        let pb_mask = (1 << (self.pb as u32)) - 1
        while self.out.len() < goal and self.problem.len() == 0:
            let pos_state = (self.out.len() as i32) & pb_mask
            if self.bit(P_IS_MATCH + (self.state << 4) + pos_state) == 0:
                self.literal()
                continue
            var len: i32 = 0
            if self.bit(P_IS_REP + self.state) == 0:
                self.rep3 = self.rep2
                self.rep2 = self.rep1
                self.rep1 = self.rep0
                len = self.length(P_LEN, pos_state)
                self.state = if self.state < 7: 7 else: 10
                self.rep0 = self.distance(len)
                if self.rep0 == XZ_MASK32:
                    self.fail("an end marker inside an LZMA2 chunk")
                    return
            else:
                if self.bit(P_IS_REP_G0 + self.state) == 0:
                    if self.bit(P_IS_REP0_LONG + (self.state << 4) + pos_state) == 0:
                        self.state = if self.state < 7: 9 else: 11
                        self.copy_match(1)
                        continue
                else:
                    var dist: i64 = 0
                    if self.bit(P_IS_REP_G1 + self.state) == 0:
                        dist = self.rep1
                    else:
                        if self.bit(P_IS_REP_G2 + self.state) == 0:
                            dist = self.rep2
                        else:
                            dist = self.rep3
                            self.rep3 = self.rep2
                        self.rep2 = self.rep1
                    self.rep1 = self.rep0
                    self.rep0 = dist
                len = self.length(P_REP_LEN, pos_state)
                self.state = if self.state < 7: 8 else: 11
            let count = len as i64 + 2
            let left = goal - self.out.len()
            self.copy_match(if count < left: count else: left)
        if self.out.len() != goal: self.fail("an LZMA chunk decodes past its size")

    // LZMA2 chunks from data[start..], until the end chunk. Returns the offset
    // after it, or -1 (the reason in self.problem).
    mut fn lzma2(start: i64) -> i64:
        var byte_at_pos = start
        var have_props = false
        while true:
            if byte_at_pos >= self.data.len():
                self.fail("an LZMA2 stream ends early")
                return -1
            let control = self.data[byte_at_pos] as i32
            byte_at_pos = byte_at_pos + 1
            if control == 0:
                return byte_at_pos
            if control == 1 or control == 2:
                if control == 1: self.dict_start = self.out.len()
                let size = ((self.data[byte_at_pos] as i64) << 8 | self.data[byte_at_pos + 1] as i64) + 1
                byte_at_pos = byte_at_pos + 2
                if byte_at_pos + size > self.data.len():
                    self.fail("an uncompressed LZMA2 chunk ends early")
                    return -1
                for i in 0..size: self.out.push(self.data[byte_at_pos + i])
                byte_at_pos = byte_at_pos + size
                continue
            if control < 128:
                self.fail(f"an invalid LZMA2 control byte {control}")
                return -1
            let unpacked = ((((control & 31) as i64) << 16) | (self.data[byte_at_pos] as i64) << 8 | self.data[byte_at_pos + 1] as i64) + 1
            let packed = ((self.data[byte_at_pos + 2] as i64) << 8 | self.data[byte_at_pos + 3] as i64) + 1
            byte_at_pos = byte_at_pos + 4
            let reset = (control >> 5) & 3
            if reset == 3: self.dict_start = self.out.len()
            if reset >= 2:
                var d = self.data[byte_at_pos] as i32
                byte_at_pos = byte_at_pos + 1
                let props_lc = d % 9
                d = d / 9
                let props_lp = d % 5
                let props_pb = d / 5
                if props_lc + props_lp > 4 or props_pb > 4:
                    self.fail("invalid LZMA properties in an LZMA2 chunk")
                    return -1
                self.reset_state(props_lc, props_lp, props_pb)
                have_props = true
            else if reset == 1:
                self.reset_state(self.lc, self.lp, self.pb)
            if not have_props and self.probs.len() == 0:
                self.fail("an LZMA2 chunk before any properties")
                return -1
            self.at = byte_at_pos
            self.end = byte_at_pos + packed
            if self.end > self.data.len():
                self.fail("an LZMA2 chunk ends early")
                return -1
            self.init_range()
            self.decode_chunk(unpacked)
            if self.problem.len() > 0: return -1
            byte_at_pos = byte_at_pos + packed
        -1


fn xz_check_size(kind: i32) -> i64:
    if kind == 0: return 0
    if kind <= 3: return 4
    if kind <= 6: return 8
    if kind <= 9: return 16
    if kind <= 12: return 32
    64

fn xz_vli(data: &str, at: i64) -> List[i64]:
    var value: i64 = 0
    var i: i64 = 0
    while i < 9:
        let b = data[at + i] as i64
        value = value | ((b & 127) << ((7 * i) as u32))
        i = i + 1
        if b < 128: break
    let out: List[i64] = List.new()
    out.push(value)
    out.push(at + i)
    out

fn xz_bytes_to_str(v: &List[u8]) -> str:
    if v.len() == 0: return ""
    unsafe { with_str_from_bytes(&v[0] as *const u8, v.len()) }

// The decompressed contents of the .xz file `data`; "" and the reason in
// the second element on failure. Concatenated streams are read in turn.
pub fn xz_decompress(data: &str) -> List[str]:
    var dec = XzLzma { data: data.to_owned(), at: 0, end: 0, range: 0, code: 0, probs: List.new(), lc: 0, lp: 0, pb: 0, state: 0, rep0: 0, rep1: 0, rep2: 0, rep3: 0, out: List.new(), dict_start: 0, problem: "" }
    let result: List[str] = List.new()
    var at: i64 = 0
    var streams = 0
    while at < data.len():
        // Stream padding between streams is zero bytes in fours.
        if streams > 0 and data[at] == 0:
            at = at + 1
            continue
        if at + 12 > data.len() or data[at] != 0xFD or data.slice(at + 1, at + 5) != "7zXZ" or data[at + 5] != 0:
            result.push("")
            result.push(if streams == 0: "not an .xz file" else: "garbage after the last .xz stream")
            return result
        let check = data[at + 7] as i32 & 15
        if xz_crc32(data, at + 6, at + 8) != xz_u32_le(data, at + 8):
            result.push("")
            result.push("a corrupt .xz stream header")
            return result
        at = at + 12
        while true:
            let size_byte = data[at] as i64
            if size_byte == 0:
                break
            let block_start = at
            let header_size = (size_byte + 1) * 4
            if xz_crc32(data, at, at + header_size - 4) != xz_u32_le(data, at + header_size - 4):
                result.push("")
                result.push("a corrupt .xz block header")
                return result
            let flags = data[at + 1] as i64
            let filters = (flags & 3) + 1
            var p = at + 2
            if (flags & 64) != 0: p = xz_vli(data, p)[1]
            if (flags & 128) != 0: p = xz_vli(data, p)[1]
            for f in 0..filters:
                let id = xz_vli(data, p)
                let props = xz_vli(data, id[1])
                if id[0] != 33 or filters != 1:
                    result.push("")
                    result.push(f"an .xz filter this decoder does not have (filter id {id[0]}; only a lone LZMA2 is read)")
                    return result
                p = props[1] + props[0]
            at = block_start + header_size
            let block_out_start = dec.out.len()
            dec.dict_start = dec.out.len()
            dec.probs = List.new()
            at = dec.lzma2(at)
            if at < 0:
                result.push("")
                result.push(dec.problem.clone())
                return result
            while (at - block_start) % 4 != 0: at = at + 1
            let check_size = xz_check_size(check)
            let block_data: List[u8] = List.with_capacity(dec.out.len() - block_out_start)
            for i in block_out_start..dec.out.len(): block_data.push(dec.out[i])
            var ok = true
            if check == 1:
                ok = xz_crc32(xz_bytes_to_str(&block_data), 0, block_data.len()) == xz_u32_le(data, at)
            else if check == 4:
                ok = xz_crc64(&block_data) == xz_u64_le(data, at)
            else if check == 10:
                var digest: [32]u8 = [0 as u8; 32]
                sha256_hash_str(xz_bytes_to_str(&block_data), &raw mut digest[0] as *mut u8)
                for i in 0..32:
                    if digest[i] != data[at + i as i64]: ok = false
            else if check != 0:
                ok = false
            if not ok:
                result.push("")
                result.push(f"an .xz block fails its check (type {check})")
                return result
            at = at + check_size
        // The index: its size is in the stream footer; skip index + footer.
        let index_start = at
        let records = xz_vli(data, at + 1)
        var q: i64 = records[1]
        for _ in 0..records[0]:
            let unpadded = xz_vli(data, q)
            let uncompressed = xz_vli(data, unpadded[1])
            q = uncompressed[1]
        while (q - index_start) % 4 != 0: q = q + 1
        at = q + 4 + 12
        streams = streams + 1
    result.push(xz_bytes_to_str(&dec.out))
    result.push("")
    result
