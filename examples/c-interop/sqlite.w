// ===================================================================
// C Interop Demo — Simplified
//
// Demonstrates:
//   - Extern function declarations for C interop
//   - Variadic functions (printf)
//   - String handling with C functions
//   - Struct wrappers around C data
//   - Extend blocks for methods
//   - Defer for cleanup
//   - Type casting
//   - String interpolation
// ===================================================================

use c_import("stdio.h")
use c_import("stdlib.h")
use c_import("string.h")

// --- Safe string wrapper ---

type SafeStr = {
    data: str,
    len: i32,
}

extend SafeStr:
    fn new(s: str) -> SafeStr: SafeStr { data: s, len: s.len as i32 }

    fn get_len(self: SafeStr) -> i32: self.len

// --- Simple key-value store (array-based) ---

type Entry = {
    key: i32,
    value: i32,
    active: bool,
}

type Store = {
    count: i32,
}

fn store_new -> Store: Store { count: 0 }

fn make_entry(key: i32, value: i32) -> Entry: Entry { key, value, active: true }

fn entry_display(e: Entry):
    if e.active then println("  [{e.key}] = {e.value}") else println("  [{e.key}] = (deleted)")

// --- Demo: C string functions ---

fn demo_strings:
    println("--- String Operations ---")
    let hello = "Hello, C interop!"
    puts(hello)

    let len = strlen(hello)
    println("strlen = {len}")

    let cmp = strcmp("abc", "abc")
    println("strcmp(abc, abc) = {cmp}")

    let cmp2 = strcmp("abc", "def")
    println("strcmp(abc, def) = {cmp2}")

// --- Demo: Struct wrapper ---

fn demo_wrapper:
    println("--- Safe Wrapper ---")
    let s = SafeStr.new("Hello World")
    println("SafeStr len = {s.len}")

    let s2 = SafeStr.new("With Language")
    let total = s.get_len() + s2.get_len()
    println("Total length = {total}")

// --- Demo: Key-value operations ---

fn demo_store:
    println("--- Key-Value Store ---")
    let entries: [5]Entry = [
        make_entry(1, 100),
        make_entry(2, 200),
        make_entry(3, 300),
        make_entry(4, 400),
        make_entry(5, 500),
    ]

    println("All entries:")
    for i in 0..5:
        entry_display(entries[i])

    var sum = 0
    for i in 0..5:
        sum = sum + entries[i].value
    println("Sum of values: {sum}")

// --- Demo: Printf formatting ---

fn demo_printf:
    println("--- Printf Formatting ---")
    printf("Decimal: %d\n", 42)
    printf("Hex: 0x%x\n", 255)
    printf("Float: %.2f\n", 3.14159)
    printf("String: %s\n", "hello")
    printf("Multiple: %s is %d\n", "answer", 42)

// --- Main ---

fn main:
    println("=== C Interop Demo ===")
    demo_strings()
    demo_wrapper()
    demo_store()
    demo_printf()
    println("=== Demo complete ===")
