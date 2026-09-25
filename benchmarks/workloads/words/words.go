// Words: string building, hashing, and map lookup over 30M generated words.
// Timed region: everything. Checksum: order-independent FNV mix of the counts
// folded with an FNV of a 1000-line report built from lookups.
package main

import (
	"fmt"
	"strings"
	"time"
)

const (
	words = 30000000
	vocab = 60000
	hot   = 600
)

func next(x uint64) uint64 {
	x ^= x << 13
	x ^= x >> 7
	x ^= x << 17
	return x
}

func spell(id uint64) string {
	v := id + 676
	var b strings.Builder
	for v > 0 {
		b.WriteByte(byte('a' + v%26))
		v /= 26
	}
	return b.String()
}

func fnv(s string) uint64 {
	h := uint64(14695981039346656037)
	for i := 0; i < len(s); i++ {
		h = (h ^ uint64(s[i])) * 1099511628211
	}
	return h
}

func main() {
	start := time.Now()
	rng := uint64(88172645463325252)
	counts := make(map[string]int32)
	for i := 0; i < words; i++ {
		rng = next(rng)
		var id uint64
		if rng%10 < 3 {
			id = (rng >> 8) % hot
		} else {
			id = (rng >> 8) % vocab
		}
		word := spell(id)
		counts[word] = counts[word] + 1
	}
	var mix uint64
	for word, count := range counts {
		mix += uint64(count) * fnv(word)
	}
	var report strings.Builder
	for id := uint64(0); id < 1000; id++ {
		word := spell(id)
		fmt.Fprintf(&report, "%s:%d\n", word, counts[word])
	}
	text := report.String()
	checksum := mix ^ fnv(text)
	elapsedMs := float64(time.Since(start).Nanoseconds()) / 1e6
	fmt.Printf("distinct %d report_bytes %d\n", len(counts), len(text))
	fmt.Printf("elapsed_ms %.3f\n", elapsedMs)
	fmt.Printf("checksum %d\n", checksum)
}
