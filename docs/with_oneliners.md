# With One-Liners

With one-liners are small compiled With programs typed directly into the
terminal. They can read files or pipelines, use the standard library, import C,
and call the same language features as a source file.

> **D22 status (2026-07-23):** map-view, contextual-Copy, `.copied()`, and
> borrowed `.cloned()` examples follow accepted specification v7.2, but their
> implementation is still in progress. A currently failing D22-shaped recipe is
> compiler non-compliance, not cookbook intent.

This is a With companion to `.reference/perl_oneliners.md`. Each recipe keeps
the reference's compact description-then-command style. The commands assume a
POSIX shell unless the final section says otherwise.

`POSSIBLE_IMPROVE` means the complete With command is more than 20% longer than
the corresponding Perl command in the reference; those cases are grouped in
[`improve_oneliners.md`](improve_oneliners.md). `IMPOSSIBLE_ONELINER` means no
correct generic With one-liner is currently available; the marker occupies the
command's place and is not shell input. Those cases are analyzed in
[`impossible_oneliners.md`](impossible_oneliners.md).

## Contents

1. [Tutorial](#tutorial)
2. [File Spacing](#file-spacing)
3. [Line Numbering](#line-numbering)
4. [Calculations](#calculations)
5. [String and Array Creation](#string-and-array-creation)
6. [Text Conversion and Substitution](#text-conversion-and-substitution)
7. [Text Analysis](#text-analysis)
8. [Selective Line Printing](#selective-line-printing)
9. [Data Transformation With Pipes](#data-transformation-with-pipes)
10. [WWW](#www)
11. [Windows](#windows)

## Tutorial

`-e` compiles and runs its argument as top-level With statements.

    with -e 'print("Hello, World!")'

`-n` runs its argument once for every stdin line. `line` contains the current
line without its newline, and `nr` is its one-based line number. Redirect a file
to stdin rather than passing it as a source-file argument.

    with -n 'print(line)' </path/to/file.txt

`-p` is `-n` plus an implicit `print(line)` after each iteration. Assigning to
`line` changes what it prints.

    with -p 'line=line.upper()' </path/to/file.txt
    POSSIBLE_IMPROVE

Standard-library modules load with ordinary `use` declarations. Imports belong
at top level, so recipes needing a non-implicit module use `-e` and spell out
their stdin loop.

    with -e 'use std.http;write(https_get("https://example.com"))'

Use `--` to pass arguments to the generated program.

    with -e 'for a in args:print(a)' -- one two three

Print the command-line help

    with -h

## File Spacing

Double space a file

    with -p 'line=line++"\n"' <example.txt

N-space a file (e.g. quadruple space)

    with -p 'line=line++"\n".repeat(3)' <example.txt
    POSSIBLE_IMPROVE

Add a blank line before every line

    with -p 'print("")' <example.txt

Remove all blank lines

    with -n 'if line =~ /\S/:print(line)' <example.txt
    POSSIBLE_IMPROVE

Remove all consecutive blank lines, leaving just one

    with -e 'write(/\n{3,}/g.replace_all(read_all(),"\n\n"))' <example.txt

## Line Numbering

Number all lines in a file

    with -n 'print(f"{nr} {line}")' <example.txt

Number only non-empty lines in a file

    with -e 'var n=0;for l in stdin.lines():if l!=""{n+=1;print(f"{n} {l}")}' <example.txt
    POSSIBLE_IMPROVE

Number all lines but print line numbers only for non-empty lines

    with -p 'if line!="":line=f"{nr} {line}"' <example.txt

Print the total number of lines in a file (emulate `wc -l`)

    with -e 'print_i64(stdin.lines().len())' <example.txt
    POSSIBLE_IMPROVE

Print the number of non-empty lines in a file

    with -e 'print_i32(stdin.lines().fold(0,(n,x)=>n+(if x!="":1 else:0)))' <example.txt
    POSSIBLE_IMPROVE

Print the number of empty or whitespace-only lines in a file

    with -e 'print_i32(stdin.lines().fold(0,(n,x)=>n+(if x =~ /^\s*$/:1 else:0)))' <example.txt
    POSSIBLE_IMPROVE

## Calculations

Check if a number is prime

    with -e 'let n=7;var p=n>1;for d in 2..n{if n%d==0:p=false};if p:print(f"{n} is prime")'
    POSSIBLE_IMPROVE

Print the sum of all tab-separated fields on each line

    with -n 'print_i32(line.split("\t").fold(0,(s,x)=>s+parse(x)))' <example.txt
    POSSIBLE_IMPROVE

Print the sum of all tab-separated fields on all lines

    with -e 'var s=0;for l in stdin.lines():s+=l.split("\t").fold(0,(a,x)=>a+parse(x));print_i32(s)' <example.txt
    POSSIBLE_IMPROVE

Shuffle all tab-separated fields on each line

    with -e 'use std.random;for line in stdin.lines(){var a=line.split("\t");var i=a.len32();while i>1{i-=1;let j=range_i32(0,i+1);let x=a[i];a[i]=a[j];a[j]=x};print(a.join("\t"))}' <example.txt
    POSSIBLE_IMPROVE

Find the lexically minimum element on each line

    with -n 'if line!="":print(line.split("\t").iter().min().unwrap())' <example.txt
    POSSIBLE_IMPROVE

Find the lexically minimum element over all lines

    with -e 'print(read_all().trim().replace("\n","\t").split("\t").iter().min().unwrap())' <example.txt
    POSSIBLE_IMPROVE

Find the lexically maximum element on each line

    with -n 'if line!="":print(line.split("\t").iter().max().unwrap())' <example.txt
    POSSIBLE_IMPROVE

Find the lexically maximum element over all lines

    with -e 'print(read_all().trim().replace("\n","\t").split("\t").iter().max().unwrap())' <example.txt
    POSSIBLE_IMPROVE

Find the numerically minimum element on each line

    with -n 'if line!="":print_i32(line.split("\t").map(x=>parse(x)).iter().min().unwrap())' <example.txt
    POSSIBLE_IMPROVE

Find the numerically maximum element on each line

    with -n 'if line!="":print_i32(line.split("\t").map(x=>parse(x)).iter().max().unwrap())' <example.txt
    POSSIBLE_IMPROVE

Replace each field with its absolute value

    with -n 'print(line.split("\t").map(x=>f"{abs(parse(x))}").join("\t"))' <example.txt
    POSSIBLE_IMPROVE

Find the total number of grapheme clusters on each line

    with -n 'print_i64(/\X/g.find_all(line).len())' <example.txt
    POSSIBLE_IMPROVE

Find the total number of words on each line

    with -n 'print_i64(/\S+/.find_all(line).len())' <example.txt
    POSSIBLE_IMPROVE

Find the total number of elements on each line, split on a comma

    with -n 'print_i64(line.split(",").len())' <example.txt
    POSSIBLE_IMPROVE

Find the total number of tab-separated fields on all lines

    with -e 'var n=0;for l in stdin.lines():n+=l.split("\t").len32();print_i32(n)' <example.txt
    POSSIBLE_IMPROVE

Find the total number of words on all lines

    with -e 'var n=0;for l in stdin.lines():n+=(/\S+/.find_all(l).len32());print_i32(n)' <example.txt
    POSSIBLE_IMPROVE

Print the total number of tab-separated fields that match a pattern

    with -e 'var n=0;for l in stdin.lines():for x in l.split("\t"):if x =~ /pattern/:n+=1;print_i32(n)' <example.txt
    POSSIBLE_IMPROVE

Print the total number of words that match a pattern

    with -e 'var n=0;for l in stdin.lines():for x in /\S+/.find_all(l):if x.text =~ /pattern/:n+=1;print_i32(n)' <example.txt
    POSSIBLE_IMPROVE

Print the total number of lines that match a pattern

    with -e 'var n=0;for l in stdin.lines():if l =~ /in/:n+=1;print_i32(n)' <example.txt
    POSSIBLE_IMPROVE

Print PI to 10 decimal places

    with -e 'print(f"{PI:.10f}")'

Print PI to 15 decimal places

    with -e 'print(f"{PI:.15f}")'
    POSSIBLE_IMPROVE

Print E to 10 decimal places

    with -e 'print(f"{E:.10f}")'

Print E to 15 decimal places

    with -e 'print(f"{E:.15f}")'
    POSSIBLE_IMPROVE

Print UNIX time (seconds since January 1, 1970 UTC)

    with -e 'use std.libc;print_i64(time(null))'
    POSSIBLE_IMPROVE

Print GMT

    with -e 'use c_import("time.h");var t=unsafe{time(null)};let x=unsafe{gmtime(&raw mut t)};print(f"{unsafe{x.tm_year}+1900}-{unsafe{x.tm_mon}+1:02}-{unsafe{x.tm_mday}:02} {unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02} GMT")'
    POSSIBLE_IMPROVE

Print local computer time

    with -e 'use c_import("time.h");var t=unsafe{time(null)};let x=unsafe{localtime(&raw mut t)};print(f"{unsafe{x.tm_year}+1900}-{unsafe{x.tm_mon}+1:02}-{unsafe{x.tm_mday}:02} {unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}")'
    POSSIBLE_IMPROVE

Print local computer time in H:M:S format

    with -e 'use c_import("time.h");var t=unsafe{time(null)};let x=unsafe{localtime(&raw mut t)};print(f"{unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}")'
    POSSIBLE_IMPROVE

Print yesterday's date

    with -e 'use c_import("time.h");var t=unsafe{time(null)}-86400;let x=unsafe{localtime(&raw mut t)};print(f"{unsafe{x.tm_year}+1900}-{unsafe{x.tm_mon}+1:02}-{unsafe{x.tm_mday}:02}")'
    POSSIBLE_IMPROVE

Print the local date and time 14 months, 9 days, and 7 seconds ago

    with -e 'use c_import("time.h");var t=unsafe{time(null)};var x=unsafe{localtime(&raw mut t)};unsafe{x.tm_mon=x.tm_mon-14;x.tm_mday=x.tm_mday-9};t=unsafe{mktime(x)}-7;x=unsafe{localtime(&raw mut t)};print(f"{unsafe{x.tm_year}+1900}-{unsafe{x.tm_mon}+1:02}-{unsafe{x.tm_mday}:02} {unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}")'
    POSSIBLE_IMPROVE

Prepend GMT timestamps to stdin

    with -e 'use c_import("time.h");fn stamp(u:bool){var t=unsafe{time(null)};let x=if u:unsafe{gmtime(&raw mut t)} else:unsafe{localtime(&raw mut t)};f"{unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}"};for l in stdin.lines():print(stamp(true)++"\t"++l)' <logfile
    POSSIBLE_IMPROVE

Prepend local timestamps to stdin

    with -e 'use c_import("time.h");fn stamp(u:bool){var t=unsafe{time(null)};let x=if u:unsafe{gmtime(&raw mut t)} else:unsafe{localtime(&raw mut t)};f"{unsafe{x.tm_hour}:02}:{unsafe{x.tm_min}:02}:{unsafe{x.tm_sec}:02}"};for l in stdin.lines():print(stamp(false)++"\t"++l)' <logfile
    POSSIBLE_IMPROVE

Calculate the factorial of 5

    with -e 'var n=1;for i in 1..=5{n*=i};print_i32(n)'
    POSSIBLE_IMPROVE

Calculate the greatest common divisor of 20, 35, and 50

    with -e 'let n:Vec[i32]=[20,35,50];var g=n[0];for x in n{var b=x;while b!=0{let t=b;b=g%b;g=t}};print_i32(g)'
    POSSIBLE_IMPROVE

Calculate the greatest common divisor of 20 and 35 with Euclid's algorithm

    with -e 'var a=20;var b=35;while b!=0{let t=b;b=a%b;a=t};print_i32(a)'
    POSSIBLE_IMPROVE

Calculate the least common multiple of 20 and 35

    with -e 'var a=20;var b=35;while b!=0{let t=b;b=a%b;a=t};print_i32(20*35/a)'
    POSSIBLE_IMPROVE

Generate 10 random numbers between 5 and 15, excluding 15

    with -e 'use std.random;for _ in 0..10:print_i32(range_i32(5,15))'
    POSSIBLE_IMPROVE

Find and print all permutations of `1 2 3 4 5`

    with -e 'fn p(s:str,r:str){if r=="":print(s);for i in 0..r.len32(){p(s++r.slice(i,i+1),r.slice(0,i)++r.slice(i+1,r.len32()))}};p("","12345")'
    POSSIBLE_IMPROVE

Generate the power set of `1 2 3`

    with -e 'for m in 0..8{var s="";for i in 0..3{if m&(1<<i as u32)!=0:s=s++f"{i+1}"};print(s)}'
    POSSIBLE_IMPROVE

Convert an IP address to an unsigned integer

    with -e 'let a="127.0.0.1".split(".");print(f"{a.fold(0u32,(n,x)=>n*256+parse(x) as u32)}")'
    POSSIBLE_IMPROVE

Convert an unsigned integer to an IP address

    with -e 'let n=2130706433u32;print(f"{n>>24}.{n>>16&255}.{n>>8&255}.{n&255}")'
    POSSIBLE_IMPROVE

## String and Array Creation

Generate and print the alphabet

    with -e 'for c in 97..123:print(str_from_byte(c))'
    POSSIBLE_IMPROVE

Generate and print all strings from `a` to `zz`

    with -e 'fn c(x:i32):str_from_byte(x);for a in 97..123:print(c(a));for a in 97..123{for b in 97..123:print(c(a)++c(b))}'
    POSSIBLE_IMPROVE

Convert an integer to hexadecimal

    with -e 'print(f"{255:x}")'

Print an integer-to-hexadecimal translation table

    with -e 'for n in 0..=255:print(f"{n:3} => {n:02x}")'

Percent encode an integer

    with -e 'print(f"%{255:x}")'

Generate a random 10-character lowercase ASCII string

    with -e 'use std.random;var s=FixedString[10].new();for _ in 0..10:s.push_byte(range_i32(97,123) as u8);write(s.as_view())'
    POSSIBLE_IMPROVE

Generate a random 15-character ASCII password

    with -e 'use std.random;var s=FixedString[15].new();for _ in 0..15:s.push_byte(range_i32(48,123) as u8);write(s.as_view())'
    POSSIBLE_IMPROVE

Create a string of a specific length

    with -e 'write("a".repeat(50))'

Generate and print the even numbers from 1 to 100

    with -e 'let a=[f"{x}" for x in 1..=100 if x%2==0];print(a.join(" "))'
    POSSIBLE_IMPROVE

Find the length of a string in grapheme clusters

    with -e 'print_i64(/\X/g.find_all("storm in a teacup").len())'
    POSSIBLE_IMPROVE

Find the number of elements in an array

    with -e 'let a=[x for x in 0..26];print_i32(a.len32())'

## Text Conversion and Substitution

ROT13 a file

    with -e 'let a="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";let b="NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm";for line in stdin.lines():print(/[A-Za-z]/g.replace_all_fn(line,(c:&Captures)=>b.slice(a.index_of(c.get(0).unwrap().text),a.index_of(c.get(0).unwrap().text)+1)))' <example.txt
    POSSIBLE_IMPROVE

Base64 encode each line

    with -e 'fn c(t:str,n:i32):t.slice(n,n+1);let t="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";for s in stdin.lines(){var o="";var i=0;while i<s.len32(){let a=s.byte_at(i);let h=i+1<s.len32();let b=if h:s.byte_at(i+1) else:0;let k=i+2<s.len32();let d=if k:s.byte_at(i+2) else:0;o=o++c(t,a>>2)++c(t,(a&3)<<4|b>>4)++(if h:c(t,(b&15)<<2|d>>6) else:"=")++(if k:c(t,d&63) else:"=");i+=3};print(o)}' <example.txt
    POSSIBLE_IMPROVE

Base64 decode each line

    with -e 'fn v(c:i32):if c<65:c+4 else if c<91:c-65 else if c<97:c/4+50 else:c-71;for s in stdin.lines(){var o=StringBuilder.new();var i=0;while i<s.len32(){let a=v(s.byte_at(i));let b=v(s.byte_at(i+1));let c=s.byte_at(i+2);let d=s.byte_at(i+3);o.push_byte((a<<2|b>>4) as u8);if c!=61:o.push_byte((b<<4|v(c)>>2) as u8);if d!=61:o.push_byte((v(c)<<6|v(d)) as u8);i+=4};print(o.to_str())}' <base64.txt
    POSSIBLE_IMPROVE

URL-escape a string

    with -e 'let s="a b/c?d=é";var o=StringBuilder.new();for i in 0..s.len32(){let c=s.byte_at(i);if is_alnum(c) or c==45 or c==46 or c==95 or c==126:o.push_byte(c as u8) else:o.push_str(f"%{c:02X}")};print(o.to_str())'
    POSSIBLE_IMPROVE

URL-unescape a string

    with -e 'fn h(c:i32):if c<58:c-48 else:c%32+9;let s="a%20b%2Fc%3Fd%3D%C3%A9";var o=StringBuilder.new();var i=0;while i<s.len32(){if s.byte_at(i)==37{o.push_byte((h(s.byte_at(i+1))*16+h(s.byte_at(i+2))) as u8);i+=3}else{o.push_byte(s.byte_at(i) as u8);i+=1}};print(o.to_str())'
    POSSIBLE_IMPROVE

HTML-encode a string

    with -e 'let s="<a href=\"x\">Tom & Sue</a>";print(s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("\x27","&#39;"))'
    POSSIBLE_IMPROVE

HTML-decode a string

    IMPOSSIBLE_ONELINER

Convert all text to uppercase

    with -p 'line=line.upper()' <example.txt
    POSSIBLE_IMPROVE

Convert all text to lowercase

    with -p 'line=line.lower()' <example.txt
    POSSIBLE_IMPROVE

Uppercase only the first word of each line

    with -p 'if line =~ /^(\w+)/:line=/^\w+/.replace(line,$1.upper())' <example.txt
    POSSIBLE_IMPROVE

Invert letter case

    with -e 'for l in stdin.lines(){var s="";for i in 0..l.len(){let c=l.byte_at(i);s=s++str_from_byte(if is_lower(c):c-32 else if is_upper(c):c+32 else:c)};print(s)}' <example.txt
    POSSIBLE_IMPROVE

Word-case each line

    with -e 'for line in stdin.lines():print(/\b\w/g.replace_all_fn(line,(c:&Captures)=>c.get(0).unwrap().text.upper()))' <example.txt
    POSSIBLE_IMPROVE

Strip leading whitespace from every line

    with -p 'line=/^\s+/.replace(line,"")' <example.txt
    POSSIBLE_IMPROVE

Strip trailing whitespace from every line

    with -p 'line=/\s+$/.replace(line,"")' <example.txt
    POSSIBLE_IMPROVE

Strip whitespace from the beginning and end of every line

    with -p 'line=line.trim()' <example.txt

Convert UNIX newlines to DOS/Windows newlines

    with -n 'write(line++"\r\n")' <example.txt

Convert DOS/Windows newlines to UNIX newlines

    with -n 'print(line)' <example.txt

Replace every `ut` with `foo`

    with -p 'line=line.replace("ut","foo")' <example.txt
    POSSIBLE_IMPROVE

Replace every `ut` with `foo` on lines containing `Lorem`

    with -p 'if line.contains("Lorem"):line=line.replace("ut","foo")' <example.txt
    POSSIBLE_IMPROVE

Convert a file to a JSON array of lines

    with -e 'use std.json;var s="[";var n=0;for l in stdin.lines(){if n>0:s=s++",";s=s++JsonWriter.new().value_str(l).finish();n+=1};print(s++"]")' <example.txt
    POSSIBLE_IMPROVE

Pick five random words from each line

    with -e 'use std.random;for line in stdin.lines(){var a=/\s+/.split(line);var i=a.len32();while i>1{i-=1;let j=range_i32(0,i+1);let x=a[i];a[i]=a[j];a[j]=x};let p=[a[j] for j in 0..min(5,a.len32())];print(p.join(" "))}' <example.txt
    POSSIBLE_IMPROVE

## Text Analysis

Print n-grams of a string

    with -e 'let s="banana";let n=2;for i in 0..=s.len32()-n:print(s.slice(i,i+n))'

Print unique n-grams

    with -e 'let s="banana";let n=2;let g:BTreeSet[str]=[s.slice(i,i+n) for i in 0..=s.len32()-n];for x in g.items():print(x)'
    POSSIBLE_IMPROVE

Print occurrence counts of n-grams

    with -e 'let s="banana";let n=2;var c:BTreeMap[str,i32]=BTreeMap.new();for i in 0..=s.len32()-n{let g=s.slice(i,i+n);c.insert(g,c.get(g).unwrap_or(0)+1)};for (g,k) in c.items():print(f"{g} {k}")'
    POSSIBLE_IMPROVE

Print occurrence counts of words on the first line

    with -e 'let w=/\s+/.split(stdin.lines()[0]);var c:BTreeMap[str,i32]=BTreeMap.new();for x in w:c.insert(x,c.get(x).unwrap_or(0)+1);for (x,n) in c.items():print(f"{x} {n}")' <example.txt
    POSSIBLE_IMPROVE

Print the Dice similarity coefficient based on sets of 1-grams

    with -e 'fn s(a:str)->BTreeSet[str]:[a.slice(i,i+1) for i in 0..a.len()];let x=s("banana");let y=s("anna");let z=x.intersection(&y);print(f"{2.0*z.len() as f64/(x.len()+y.len()) as f64}")'
    POSSIBLE_IMPROVE

Print the Jaccard similarity coefficient based on sets of 1-grams

    with -e 'fn s(a:str)->BTreeSet[str]:[a.slice(i,i+1) for i in 0..a.len()];let x=s("banana");let y=s("anna");let z=x.intersection(&y);let u=x.union(&y);print(f"{z.len() as f64/u.len() as f64}")'
    POSSIBLE_IMPROVE

Print the overlap coefficient based on sets of 1-grams

    with -e 'fn s(a:str)->BTreeSet[str]:[a.slice(i,i+1) for i in 0..a.len()];let x=s("banana");let y=s("anna");let z=x.intersection(&y);print(f"{z.len() as f64/min(x.len(),y.len()) as f64}")'
    POSSIBLE_IMPROVE

Print the cosine similarity based on sets of 1-grams

    with -e 'fn s(a:str)->BTreeSet[str]:[a.slice(i,i+1) for i in 0..a.len()];let x=s("banana");let y=s("anna");let z=x.intersection(&y);print(f"{z.len() as f64/sqrt((x.len()*y.len()) as f64)}")'
    POSSIBLE_IMPROVE

Build and print an index of characters within a string

    with -e 'let s="banana";var m:BTreeMap[str,str]=BTreeMap.new();for i in 0..s.len(){let c=s.slice(i,i+1);let v=m.get(c).cloned().unwrap_or("");m.insert(c,v++if v=="":f"{i}" else:f" {i}")};for (c,i) in m.items():print(f"{c}: {i}")'
    POSSIBLE_IMPROVE

Build and print an index of words within the first line

    with -e 'let w=/\s+/.split(stdin.lines()[0]);var m:BTreeMap[str,str]=BTreeMap.new();for i in 0..w.len(){let x=w[i];let v=m.get(x).cloned().unwrap_or("");m.insert(x,v++if v=="":f"{i}" else:f" {i}")};for (x,i) in m.items():print(f"{x}: {i}")' <example.txt
    POSSIBLE_IMPROVE

## Selective Line Printing

Print the first line of a file (emulate `head -1`)

    with -n 'if nr==1:print(line)' <example.txt
    POSSIBLE_IMPROVE

Print the first 10 lines of a file (emulate `head -10`)

    with -n 'if nr<=10:print(line)' <example.txt

Print the last line of a file (emulate `tail -1`)

    with -e 'let l=stdin.lines();print(l[l.len()-1])' <example.txt
    POSSIBLE_IMPROVE

Print the last five lines of a file

    with -e 'let l=stdin.lines();for i in max(0,l.len()-5)..l.len():print(l[i])' <example.txt
    POSSIBLE_IMPROVE

Print only lines that contain vowels

    with -n 'if line =~ /[aeiou]/:print(line)' <example.txt
    POSSIBLE_IMPROVE

Print lines that contain all vowels

    with -n 'if line.contains("a") and line.contains("e") and line.contains("i") and line.contains("o") and line.contains("u"):print(line)' <example.txt
    POSSIBLE_IMPROVE

Print lines that are 80 characters or longer

    with -n 'if /\X/g.find_all(line).len()>=80:print(line)' <example.txt
    POSSIBLE_IMPROVE

Print only line 2

    with -n 'if nr==2:print(line)' <example.txt

Print all lines except line 2

    with -n 'if nr!=2:print(line)' <example.txt

Print lines 1 through 3

    with -n 'if nr<=3:print(line)' <example.txt

Print all lines between two regexes, including matching lines

    with -e 'var p=false;for l in stdin.lines(){if l =~ /^Lorem/:p=true;if p:print(l);if l =~ /laborum\.$/:p=false}' <example.txt
    POSSIBLE_IMPROVE

Print the length of the longest line

    with -e 'var n=0;for l in stdin.lines(){let c=/\X/g.find_all(l);n=max(n,c.len32())};print_i32(n)' <example.txt
    POSSIBLE_IMPROVE

Print the longest line

    with -e 'var m="";for l in stdin.lines(){if l.len()>m.len():m=l};print(m)' <example.txt
    POSSIBLE_IMPROVE

Print all lines that contain a number

    with -n 'if line =~ /\d/:print(line)' <example.txt
    POSSIBLE_IMPROVE

Print all lines that contain only a number

    with -n 'if line =~ /^\d+$/:print(line)' <example.txt
    POSSIBLE_IMPROVE

Print every even line

    with -n 'if nr%2==0:print(line)' <example.txt

Print every odd line

    with -n 'if nr%2!=0:print(line)' <example.txt

Print all lines that repeat, once each

    with -e 'var c:HashMap[str,i32]=[:];for l in stdin.lines(){c.increment(l);if c.get(l).unwrap()==2:print(l)}' <example.txt
    POSSIBLE_IMPROVE

Print unique lines, keeping the first occurrence

    with -e 'var c:HashMap[str,i32]=[:];for l in stdin.lines(){c.increment(l);if c.get(l).unwrap()==1:print(l)}' <example.txt
    POSSIBLE_IMPROVE

Print the first word of every line

    with -n 'if line =~ /(\S+)/:print($1)' <example.txt
    POSSIBLE_IMPROVE

## Data Transformation With Pipes

JSON-encode a list of all files in the current directory

    ls | with -e 'use std.json;var s="[";var n=0;for l in stdin.lines(){if n>0:s=s++",";s=s++JsonWriter.new().value_str(l).finish();n+=1};print(s++"]")'
    POSSIBLE_IMPROVE

Print a random sample of approximately 5% of input lines

    with -e 'use std.random;for l in stdin.lines():if chance(5):print(l)' </usr/share/dict/words
    POSSIBLE_IMPROVE

Convert an HTML color to decimal RGB

    echo '#ffff00' | with -e 'fn h(c:i32):if c<58:c-48 else:c%32+9;for s in stdin.lines():print(f"{h(s.byte_at(1))*16+h(s.byte_at(2))} {h(s.byte_at(3))*16+h(s.byte_at(4))} {h(s.byte_at(5))*16+h(s.byte_at(6))}")'
    POSSIBLE_IMPROVE

Convert decimal RGB to an HTML color

    echo '255 255 0' | with -n 'let a=line.split(" ");print(f"#{parse(a[0]):02x}{parse(a[1]):02x}{parse(a[2]):02x}")'
    POSSIBLE_IMPROVE

## WWW

Download a webpage

    with -e 'use std.http;write(https_get("https://example.com"))'

Download a webpage and strip HTML tags

    with -e 'use std.http;write(/<[^>]+>/g.replace_all(https_get("https://example.com"),""))'
    POSSIBLE_IMPROVE

Download a webpage, strip HTML, and decode all HTML entities

    IMPOSSIBLE_ONELINER

Launch a simple web server

    IMPOSSIBLE_ONELINER

## Windows

PowerShell accepts the same outer single quotes used by the POSIX examples:

    with -e 'print("Hello, World!")'

In `cmd.exe`, use outer double quotes and escape the inner quotes according to
the Windows command-line quoting rules. Redirection with `>` and `>>` works as
usual in both shells.
