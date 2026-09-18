import subprocess

BS = chr(92)
P = BS  # single backslash byte

cases = [
    ("nested", "((a)(b(c)))", ["abc"]),
    ("backref-hit", "(a|b)" + P + "1", ["aa"]),
    ("backref-miss", "(a|b)" + P + "1", ["ab"]),
    ("lookahead", "(?=abc)abc", ["abc"]),
    ("neglookahead", "(?!foo)bar", ["bar"]),
    ("lookbehind", "(?<=ab)c", ["abc"]),
    ("count", "a{64}", ["a" * 64]),
    ("countrange", "x{1,200}", ["xxxx"]),
    ("class", "[a-z]+", ["hello"]),
    ("negclass", "[^abc]+", ["xyz"]),
    ("posixclass", "[[:alpha:]]+", ["hello"]),
    ("alt", "(a|b)*abb", ["aababb"]),
    ("nongreedy", "a+?b", ["aaab"]),
    ("named", "(?<word>ab)c", ["abc"]),
    ("namedref", "(?<w>a|b)k(?P=w)", ["aka"]),
    ("possessive", "a++b", ["aaab"]),
    ("atomic", "(?>a+)b", ["aaab"]),
    ("cond-hit", "(a)?(?(1)b|c)", ["ab"]),
    ("cond-else", "(a)?(?(1)b|c)", ["c"]),
    ("anchors", "^" + P + "d{3}-" + P + "d{4}$", ["123-4567"]),
    ("deep10", "((((((((((a))))))))))", ["a"]),
    ("bad-unclosed", "(abc", ["abc"]),
    ("bad-class", "[abc", ["abc"]),
    ("bad-quant", "*abc", ["abc"]),
    ("bad-backref", "(a)" + P + "2", ["aa"]),
    ("bad-range", "a{3,2}", ["aaa"]),
    ("bad-trailbs", "abc" + P, ["abc"]),
    ("bad-lookbehind", "(?<=a*)b", ["ab"]),
    ("bad-dupname", "(?P<n>a)(?P<n>b)", ["ab"]),
]

inp_lines = []
for tag, pat, subjs in cases:
    inp_lines.append("/" + pat + "/")
    for s in subjs:
        inp_lines.append("    " + s)

with open(".audit/probes/pcre2_compile/oracle_input.txt", "w") as f:
    f.write(chr(10).join(inp_lines) + chr(10))

r = subprocess.run(
    ["/home/linuxbrew/.linuxbrew/bin/pcre2test",
     ".audit/probes/pcre2_compile/oracle_input.txt"],
    capture_output=True, text=True)
with open(".audit/probes/pcre2_compile/oracle_output.txt", "w") as f:
    f.write(r.stdout)
print("rc=", r.returncode, "stderr=", r.stderr[:500])
print("lines=", len(r.stdout.splitlines()))
