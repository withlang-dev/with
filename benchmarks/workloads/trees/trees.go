// Binary trees: allocation-heavy recursive tree build and check, depth 18.
// Timed region: everything. Checksum: sum of all node counts.
// Go frees nothing explicitly; this workload measures its garbage collector.
package main

import (
	"fmt"
	"time"
)

const (
	minDepth = 4
	maxDepth = 18
)

type Node struct{ left, right *Node }

func bottomUp(depth int) *Node {
	if depth == 0 {
		return &Node{}
	}
	return &Node{bottomUp(depth - 1), bottomUp(depth - 1)}
}

func check(node *Node) int64 {
	var left, right int64
	if node.left != nil {
		left = check(node.left)
	}
	if node.right != nil {
		right = check(node.right)
	}
	return 1 + left + right
}

func main() {
	start := time.Now()
	var total int64
	stretch := bottomUp(maxDepth + 1)
	total += check(stretch)
	longLived := bottomUp(maxDepth)
	for depth := minDepth; depth <= maxDepth; depth += 2 {
		iterations := 1 << (maxDepth - depth + minDepth)
		for i := 0; i < iterations; i++ {
			total += check(bottomUp(depth))
		}
	}
	total += check(longLived)
	elapsedMs := float64(time.Since(start).Nanoseconds()) / 1e6
	fmt.Printf("max_depth %d\n", maxDepth)
	fmt.Printf("elapsed_ms %.3f\n", elapsedMs)
	fmt.Printf("checksum %d\n", total)
}
