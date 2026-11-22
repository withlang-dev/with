use common

const N: i64 = 100000 // BENCH_N
type Generator { text: Vec[u8] }

impl Generator:
    mut fn gen(depth: i64, seed: u64) -> u64:
        var r = xs_next(seed)
        let k = xs_mod(r, 8)
        if depth == 0 or k == 0:
            let v = 1 + xs_mod(r >> 8, 99)
            if v >= 10: self.text.push((48 + v / 10) as u8)
            self.text.push((48 + v % 10) as u8)
            return r
        if k == 1:
            self.text.push(45)
            return self.gen(depth - 1, r)
        if k == 2:
            self.text.push(40)
            r = self.gen(depth - 1, r)
            self.text.push(41)
            return r
        r = self.gen(depth - 1, r)
        let op = xs_mod(r >> 16, 4)
        self.text.push(32)
        self.text.push(if op == 0: 43 else if op == 1: 45 else if op == 2: 42 else: 47)
        self.text.push(32)
        self.gen(depth - 1, xs_next(r))

    mut fn corrupt(seed: u64):
        let kind = xs_mod(seed, 16)
        if kind == 0:
            var i = self.text.len()
            while i > 0:
                i -= 1
                if self.text[i] == 41:
                    self.text[i] = 32
                    return
            self.text[0] = 35
        else if kind == 1: self.text[xs_mod(seed >> 8, self.text.len())] = 35
        else if kind == 2:
            let keep = self.text.len() / 2
            while self.text.len() > keep: self.text.pop()
        else if kind == 3:
            self.text.push(32)
            self.text.push(47)
            self.text.push(32)
            self.text.push(48)

enum Expr:
    Num(u64)
    Neg(i32)
    Paren(i32)
    Bin(u8, i32, i32)
type Parser ephemeral { text: &Vec[u8], pos: i64, nodes: Vec[Expr] }

impl Parser:
    mut fn skip():
        while self.pos < self.text.len() and self.text[self.pos] == 32: self.pos += 1

    mut fn append(node: Expr) -> i32:
        let index = self.nodes.len() as i32
        self.nodes.push(node)
        index

    mut fn expr() -> Result[i32, i32]:
        var lhs = self.term()?
        loop:
            self.skip()
            if self.pos >= self.text.len(): break
            let op: u8 = self.text[self.pos]
            if op != 43 and op != 45: break
            self.pos += 1
            let rhs = self.term()?
            lhs = self.append(.Bin(op, lhs, rhs))
        lhs

    mut fn term() -> Result[i32, i32]:
        var lhs = self.factor()?
        loop:
            self.skip()
            if self.pos >= self.text.len(): break
            let op: u8 = self.text[self.pos]
            if op != 42 and op != 47: break
            self.pos += 1
            let rhs = self.factor()?
            lhs = self.append(.Bin(op, lhs, rhs))
        lhs

    mut fn factor() -> Result[i32, i32]:
        self.skip()
        if self.pos >= self.text.len(): return Err(1)
        let c: u8 = self.text[self.pos]
        if c >= 48 and c <= 57:
            var v: u64 = 0
            while self.pos < self.text.len():
                let digit: u8 = self.text[self.pos]
                if digit < 48 or digit > 57: break
                v = v * 10 + ((digit as u64) - 48)
                self.pos += 1
            self.append(.Num(v))
        else if c == 45:
            self.pos += 1
            let child = self.factor()?
            self.append(.Neg(child))
        else:
            if c != 40: return Err(3)
            self.pos += 1
            let child = self.expr()?
            self.skip()
            if self.pos >= self.text.len() or self.text[self.pos] != 41: return Err(2)
            self.pos += 1
            self.append(.Paren(child))

    fn eval(index: i32) -> Result[u64, i32]:
        match self.nodes[index]:
            .Num(v) =>
                let number: u64 = v
                number
            .Neg(child) => (0 as u64) -% self.eval(child)?
            .Paren(child) => self.eval(child)?
            .Bin(op, left, right) =>
                let a = self.eval(left)?
                let b = self.eval(right)?
                if op == 43: a +% b
                else if op == 45: a -% b
                else if op == 42: a *% b
                else:
                    if b == 0: return Err(4)
                    a / b

    mut fn run_one() -> Result[u64, i32]:
        let root = self.expr()?
        self.skip()
        if self.pos != self.text.len(): return Err(3)
        self.eval(root)?

fn main:
    var generator = Generator { text: Vec.new() }
    var seed: u64 = 12345
    var ok: i64 = 0
    var errors: [i64; 5] = [0; 5]
    var sum: u64 = 0
    var chars: i64 = 0
    var nodes: i64 = 0
    for _ in 0..N:
        seed = xs_next(seed)
        generator.text.clear()
        let s = generator.gen(3 + xs_mod(seed, 4), seed >> 8)
        generator.corrupt(s)
        chars += generator.text.len()
        var parser = Parser { text: &generator.text, pos: 0, nodes: Vec.new() }
        let result = parser.run_one()
        nodes += parser.nodes.len()
        match result:
            Ok(v) =>
                ok += 1
                sum = sum *% 31 +% v
            Err(code) => errors[code] += 1
    print(chars)
    print(nodes)
    print(ok)
    for code in 1..5: print(errors[code])
    print(sum)
