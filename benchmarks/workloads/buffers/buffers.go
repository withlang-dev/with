// Buffers: chunked-I/O shaped churn of 8 to 64 KiB blocks, 32 live at once.
// Timed region: everything. Checksum: wrapping sum of the words written.
package main

import (
	"fmt"
	"time"
)

const (
	iterations = 2000000
	ring       = 32
)

func main() {
	start := time.Now()
	slots := make([][]uint64, ring)
	var checksum uint64
	for i := 0; i < iterations; i++ {
		words := 1024 * (1 + (i % 8))
		block := make([]uint64, 0, words)
		for j := 0; j < words/64; j++ {
			value := uint64(i)*2654435761 + uint64(j)
			block = append(block, value)
			checksum += value
		}
		slots[i%ring] = block
	}
	elapsedMs := float64(time.Since(start).Nanoseconds()) / 1e6
	fmt.Printf("iterations %d ring %d\n", iterations, ring)
	fmt.Printf("elapsed_ms %.3f\n", elapsedMs)
	fmt.Printf("checksum %d\n", checksum)
}
