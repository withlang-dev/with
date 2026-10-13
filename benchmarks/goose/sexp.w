use common
use std.string.StringBuilder

const N: i64 = 20000 // BENCH_N
type Generator { text: StringBuilder }

impl Generator:
    mut fn gen(depth: i64, seed: u64) -> u64:
        var r = xs_next(seed)
        if depth == 0 or xs_mod(r, 4) == 0:
            if xs_mod(r >> 8, 2) == 0:
                var letters = r
                let n = 3 + xs_mod(r, 12)
                for _ in 0..n:
                    letters = xs_next(letters)
                    self.text.push_byte((97 + xs_mod(letters, 26)) as u8)
            else: self.text.push_str(f"{xs_mod(r >> 16, 100000)}")
            self.text.push_byte(32)
            return r
        self.text.push_byte(40)
        let kids = 2 + xs_mod(r >> 24, 4)
        for _ in 0..kids: r = self.gen(depth - 1, r)
        self.text.push_str(") ")
        r

enum Sexp:
    Sym(str, i32)
    Num(i64, i32)
    List(i32, i32)
type Parser { text: str, pos: i64, nodes: Vec[Sexp] }

impl Parser:
    mut fn skip():
        while self.pos < self.text.len() and self.text.byte_at(self.pos) == 32: self.pos += 1

    mut fn parse(prev: i32) -> Result[i32, str]:
        self.skip()
        if self.pos >= self.text.len(): return Err("eof")
        let c = self.text.byte_at(self.pos)
        var node: Sexp = .Num(0, prev)
        if c == 40:
            self.pos += 1
            var chain: i32 = -1
            loop:
                self.skip()
                if self.pos >= self.text.len(): return Err("unclosed")
                if self.text.byte_at(self.pos) == 41:
                    self.pos += 1
                    break
                chain = self.parse(chain)?
            node = .List(chain, prev)
        else if c >= 48 and c <= 57:
            var v: i64 = 0
            while self.pos < self.text.len():
                let digit = self.text.byte_at(self.pos)
                if digit < 48 or digit > 57: break
                v = v * 10 + digit - 48
                self.pos += 1
            node = .Num(v, prev)
        else:
            let start: i64 = self.pos
            while self.pos < self.text.len():
                let b = self.text.byte_at(self.pos)
                if b == 32 or b == 40 or b == 41: break
                self.pos += 1
            node = .Sym(self.text.slice(start, self.pos), prev)
        let index = self.nodes.len() as i32
        self.nodes.push(node)
        index

    mut fn parse_all(roots: Vec[i32]) -> Result[Vec[i32], str]:
        var out = roots
        loop:
            self.skip()
            if self.pos >= self.text.len(): break
            out.push(self.parse(-1)?)
        out

    fn walk(index: i32, pass: i64) -> i64:
        match self.nodes[index]:
            .Sym(name, _) => name.len() + name.byte_at(0) + pass
            .Num(v, _) => v ^ pass
            .List(first, _) => 1 + self.chain(first, pass)

    fn chain(index: i32, pass: i64) -> i64:
        if index < 0: return 0
        let next: i32 = match self.nodes[index]:
            .Sym(_, link) => link
            .Num(_, link) => link
            .List(_, link) => link
        self.walk(index, pass) + self.chain(next, pass)

fn main:
    var generator = Generator { text: StringBuilder.new() }
    var seed: u64 = 12345
    for _ in 0..N: seed = generator.gen(4, seed)
    var parser = Parser { text: generator.text.to_str(), pos: 0, nodes: Vec.new() }
    let roots = parser.parse_all(Vec.new()).unwrap()
    print(parser.text.len())
    print(parser.nodes.len())
    print(roots.len())
    print(0)
    var total: i64 = 0
    for p in 0..4:
        for root in roots: total += parser.walk(root, p)
    print(total)
