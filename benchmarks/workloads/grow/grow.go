// Grow: push-built vectors inside a struct, 800 rounds of 100k rows each.
// Timed region: everything. Checksum: wrapping fold over the rows.
package main

import (
	"fmt"
	"time"
)

const (
	rounds = 800
	rows   = 100000
)

type Table struct{ xs, ys, ids []int64 }

func next(x uint64) uint64 {
	x ^= x << 13
	x ^= x >> 7
	x ^= x << 17
	return x
}

func (t *Table) pushRow(r uint64, id int64) {
	t.xs = append(t.xs, int64(r%1000))
	t.ys = append(t.ys, int64((r>>10)%1000))
	t.ids = append(t.ids, id)
}

func (t *Table) fold() int64 {
	var total int64
	for i := range t.ids {
		total += t.xs[i]*3 + t.ys[i]*7 + t.ids[i]
	}
	return total
}

func main() {
	start := time.Now()
	rng := uint64(2463534242)
	var checksum int64
	for round := int64(0); round < rounds; round++ {
		t := &Table{}
		for i := int64(0); i < rows; i++ {
			rng = next(rng)
			t.pushRow(rng, round*rows+i)
		}
		checksum += t.fold()
	}
	elapsedMs := float64(time.Since(start).Nanoseconds()) / 1e6
	fmt.Printf("rounds %d rows %d\n", rounds, rows)
	fmt.Printf("elapsed_ms %.3f\n", elapsedMs)
	fmt.Printf("checksum %d\n", checksum)
}
