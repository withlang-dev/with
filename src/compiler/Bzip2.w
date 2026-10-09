// .bz2 decompression in With (#1915): a `with get` source archive that is a
// .tar.bz2 is unpacked by this compiler, not the host's tar. The bzip2
// format: "BZh" + level, blocks (Huffman-coded MTF/RLE2 symbols over a
// Burrows-Wheeler transform, then RLE1) and an end-of-stream record;
// concatenated streams are read in turn. Every block CRC and each stream's
// combined CRC are verified.

extern fn with_str_from_bytes(s: *const u8, len: i64) -> str

let BZ_MASK32: i64 = 4294967295

// An MSB-first bit reader over the compressed bytes.
type BzBits {
    data: str,
    at: i64,
    buffer: i64,
    count: i32,
    problem: str,
}

impl BzBits:
    mut fn bits(n: i32) -> i64:
        while self.count < n:
            if self.at >= self.data.len():
                if self.problem.len() == 0: self.problem = "a bzip2 stream ends early"
                return 0
            self.buffer = ((self.buffer << 8) | self.data[self.at] as i64) & 0xFFFFFFFFFFFF
            self.at = self.at + 1
            self.count = self.count + 8
        self.count = self.count - n
        (self.buffer >> (self.count as u32)) & ((1 << (n as u32)) - 1)

    mut fn bit() -> i32: self.bits(1) as i32

    // To the next byte boundary, between streams.
    mut fn align():
        self.count = self.count - self.count % 8

fn bz_crc_table() -> List[i64]:
    let table: List[i64] = List.new()
    for i in 0..256:
        var c = (i as i64) << 24
        for _ in 0..8:
            c = if (c & 0x80000000) != 0: ((c << 1) ^ 0x04C11DB7) & BZ_MASK32 else: (c << 1) & BZ_MASK32
        table.push(c)
    table

// Canonical Huffman tables of one coding group: codes of each length, in
// symbol order (bzip2's limit/base/perm).
type BzHuffman {
    min_len: i32,
    max_len: i32,
    limit: List[i64],
    base: List[i64],
    perm: List[i32],
}

fn bz_huffman(lengths: &List[i32]) -> BzHuffman:
    var min_len = 32
    var max_len = 0
    for i in 0..lengths.len() as i32:
        if lengths[i] > max_len: max_len = lengths[i]
        if lengths[i] < min_len: min_len = lengths[i]
    let perm: List[i32] = List.new()
    for len in min_len..max_len + 1:
        for s in 0..lengths.len() as i32:
            if lengths[s] == len: perm.push(s)
    let limit: List[i64] = List.new()
    let base: List[i64] = List.new()
    for _ in 0..22:
        limit.push(-1)
        base.push(0)
    var code: i64 = 0
    var index: i64 = 0
    for len in min_len..max_len + 1:
        var count: i64 = 0
        for s in 0..lengths.len() as i32:
            if lengths[s] == len: count = count + 1
        // Codes of this length run from `code` to code + count - 1; perm
        // holds their symbols from `index`.
        base[len] = index - code
        code = code + count
        limit[len] = code - 1
        index = index + count
        code = code << 1
    BzHuffman { min_len, max_len, limit, base, perm }

impl BzBits:
    mut fn symbol(table: &BzHuffman) -> i32:
        var len = table.min_len
        var code = self.bits(len)
        while len <= table.max_len:
            if table.limit[len] >= 0 and code <= table.limit[len]:
                let bit_at = table.base[len] + code
                if bit_at >= 0 and bit_at < table.perm.len():
                    return table.perm[bit_at as i32]
            code = (code << 1) | self.bits(1)
            len = len + 1
        if self.problem.len() == 0: self.problem = "an invalid bzip2 Huffman code"
        0


fn bz_bytes_to_str(v: &List[u8]) -> str:
    if v.len() == 0: return ""
    unsafe { with_str_from_bytes(&v[0] as *const u8, v.len()) }

// The decompressed contents of the .bz2 file `data`, and "" — or "" and the
// reason.
pub fn bzip2_decompress(data: &str) -> List[str]:
    let result: List[str] = List.new()
    var bits = BzBits { data: data.to_owned(), at: 0, buffer: 0, count: 0, problem: "" }
    let crc_table = bz_crc_table()
    let out: List[u8] = List.new()
    var streams = 0
    while bits.at < data.len():
        bits.align()
        if bits.at + 4 > data.len() or data.slice(bits.at, bits.at + 3) != "BZh" or data[bits.at + 3] < '1' or data[bits.at + 3] > '9':
            if streams > 0 and bits.at >= data.len(): break
            result.push("")
            result.push(if streams == 0: "not a .bz2 file" else: "garbage after the last bzip2 stream")
            return result
        let block_max = (data[bits.at + 3] - '0') as i64 * 100000
        bits.at = bits.at + 4
        bits.count = 0
        var combined: i64 = 0
        while true:
            let magic = bits.bits(24) << 24 | bits.bits(24)
            if magic == 0x177245385090:
                let stored = bits.bits(32)
                if stored != combined:
                    result.push("")
                    result.push("a bzip2 stream fails its combined CRC")
                    return result
                break
            if magic != 0x314159265359:
                result.push("")
                result.push(if bits.problem.len() > 0: bits.problem.clone() else: "a corrupt bzip2 block header")
                return result
            let block_crc = bits.bits(32)
            if bits.bit() != 0:
                result.push("")
                result.push("a randomized bzip2 block (bzip2 0.9.0 and older), which this decoder does not read")
                return result
            let orig_ptr = bits.bits(24)
            // The symbol map: which of the 256 byte values occur.
            let used16 = bits.bits(16)
            let seq_to_unseq: List[i32] = List.new()
            for i in 0..16:
                if (used16 >> ((15 - i) as u32)) & 1 == 1:
                    let used = bits.bits(16)
                    for j in 0..16:
                        if (used >> ((15 - j) as u32)) & 1 == 1: seq_to_unseq.push(i * 16 + j)
            let in_use = seq_to_unseq.len() as i32
            if in_use == 0:
                result.push("")
                result.push("a bzip2 block uses no symbols")
                return result
            let alpha_size = in_use + 2
            let groups = bits.bits(3) as i32
            let selectors_count = bits.bits(15) as i32
            if groups < 2 or groups > 6 or selectors_count < 1:
                result.push("")
                result.push("a corrupt bzip2 block (coding groups)")
                return result
            // Selectors, move-to-front coded in unary.
            let mtf_groups: List[i32] = List.new()
            for g in 0..groups: mtf_groups.push(g)
            let selectors: List[i32] = List.new()
            for _ in 0..selectors_count:
                var j = 0
                while bits.bit() == 1:
                    j = j + 1
                    if j >= groups:
                        result.push("")
                        result.push("a corrupt bzip2 selector")
                        return result
                let v: i32 = mtf_groups[j]
                var k = j
                while k > 0:
                    mtf_groups[k] = mtf_groups[k - 1]
                    k = k - 1
                mtf_groups[0] = v
                selectors.push(v)
            // Code lengths per group, delta coded.
            let tables: List[BzHuffman] = List.new()
            for _ in 0..groups:
                let lengths: List[i32] = List.new()
                var len = bits.bits(5) as i32
                for _ in 0..alpha_size:
                    while true:
                        if len < 1 or len > 20:
                            result.push("")
                            result.push("a corrupt bzip2 code length")
                            return result
                        if bits.bit() == 0: break
                        len = if bits.bit() == 0: len + 1 else: len - 1
                    lengths.push(len)
                tables.push(bz_huffman(&lengths))
            // The MTF/RLE2 symbols into the BWT vector `tt`.
            let mtf: List[i32] = List.new()
            for i in 0..256: mtf.push(i)
            let counts: List[i64] = List.new()
            for _ in 0..256: counts.push(0)
            let tt: List[i32] = List.new()
            let eob = alpha_size - 1
            var group_index = 0
            var group_left = 0
            var run: i64 = 0
            var run_weight: i64 = 1
            while true:
                if group_left == 0:
                    if group_index >= selectors.len() as i32:
                        result.push("")
                        result.push("a bzip2 block runs past its selectors")
                        return result
                    group_left = 50
                    group_index = group_index + 1
                group_left = group_left - 1
                let symbol = bits.symbol(&tables[selectors[group_index - 1]])
                if bits.problem.len() > 0:
                    result.push("")
                    result.push(bits.problem.clone())
                    return result
                if symbol <= 1:
                    // RUNA / RUNB: a run of the front symbol, in bijective base 2.
                    run = run + run_weight * (symbol as i64 + 1)
                    run_weight = run_weight * 2
                    if run > block_max:
                        result.push("")
                        result.push("a bzip2 run past the block size")
                        return result
                    continue
                if run > 0:
                    let b: i32 = seq_to_unseq[mtf[0]]
                    counts[b] = counts[b] + run
                    for _ in 0..run: tt.push(b)
                    run = 0
                    run_weight = 1
                if symbol == eob: break
                let index = symbol - 1
                let v: i32 = mtf[index]
                var k = index
                while k > 0:
                    mtf[k] = mtf[k - 1]
                    k = k - 1
                mtf[0] = v
                let b: i32 = seq_to_unseq[v]
                counts[b] = counts[b] + 1
                tt.push(b)
                if tt.len() > block_max:
                    result.push("")
                    result.push("a bzip2 block past its size")
                    return result
            let n = tt.len()
            if orig_ptr >= n:
                result.push("")
                result.push("a corrupt bzip2 block (origin pointer)")
                return result
            // Inverse BWT: tt[i]'s high bits link to the next position.
            let starts: List[i64] = List.new()
            var sum: i64 = 0
            for i in 0..256:
                starts.push(sum)
                sum = sum + counts[i]
            let next: List[i32] = List.with_capacity(n)
            for _ in 0..n: next.push(0)
            for i in 0..n:
                let b: i32 = tt[i as i32]
                next[starts[b] as i32] = i as i32
                starts[b] = starts[b] + 1
            // Walk it, undoing RLE1 (four equal bytes, then a count byte).
            var crc = BZ_MASK32
            var pos = next[orig_ptr as i32]
            var last = -1
            var same = 0
            for _ in 0..n:
                let b: i32 = tt[pos]
                pos = next[pos]
                if same == 4:
                    for _ in 0..b:
                        out.push(last as u8)
                        crc = ((crc << 8) & BZ_MASK32) ^ crc_table[(((crc >> 24) ^ last as i64) & 255) as i32]
                    same = 0
                    last = -1
                    continue
                if b == last: same = same + 1 else: same = 1
                last = b
                out.push(b as u8)
                crc = ((crc << 8) & BZ_MASK32) ^ crc_table[(((crc >> 24) ^ b as i64) & 255) as i32]
            crc = crc ^ BZ_MASK32
            if crc != block_crc:
                result.push("")
                result.push("a bzip2 block fails its CRC")
                return result
            combined = (((combined << 1) | (combined >> 31)) & BZ_MASK32) ^ crc
        streams = streams + 1
    result.push(bz_bytes_to_str(&out))
    result.push("")
    result
