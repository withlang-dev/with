import subprocess, re

BS = chr(92)
P = BS

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

out = []
for tag, pat, subjs in cases:
    lines = ["/" + pat + "/"] + ["    " + s for s in subjs]
    with open("/tmp/one_case.txt", "w") as f:
        f.write(chr(10).join(lines) + chr(10))
    r = subprocess.run(
        ["/home/linuxbrew/.linuxbrew/bin/pcre2test", "/tmp/one_case.txt"],
        capture_output=True, text=True)
    body = [ln for ln in r.stdout.splitlines()[1:] if ln.strip() != ""]
    out.append(tag + " || " + " | ".join(body))

with open(".audit/probes/pcre2_compile/oracle_percase.txt", "w") as f:
    f.write(chr(10).join(out) + chr(10))
print(chr(10).join(out))
