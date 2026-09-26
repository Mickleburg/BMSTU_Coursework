package main

import (
	"fmt"
	"math"
	"sync"
)

func multiplyByRows(a, b Matrix) Matrix {
	ensureCompatible(a, b)
	c := newMatrix(a.N)

	for row := 0; row < a.N; row++ {
		multiplyBlock(a, b, c, row, row+1, 0, a.N)
	}
	return c
}

func multiplyByColumns(a, b Matrix) Matrix {
	ensureCompatible(a, b)
	c := newMatrix(a.N)

	for column := 0; column < a.N; column++ {
		multiplyBlock(a, b, c, 0, a.N, column, column+1)
	}
	return c
}

func multiplyBlock(a, b, c Matrix, rowStart, rowEnd, columnStart, columnEnd int) {
	for row := rowStart; row < rowEnd; row++ {
		rowOffset := row * a.N
		for column := columnStart; column < columnEnd; column++ {
			var value int64
			for k := 0; k < a.N; k++ {
				value += a.Data[rowOffset+k] * b.Data[k*a.N+column]
			}
			c.Data[rowOffset+column] = value
		}
	}
}

type interval struct {
	start int
	end   int
}

func splitRange(size, parts int) []interval {
	ranges := make([]interval, parts)
	for part := range parts {
		ranges[part] = interval{
			start: part * size / parts,
			end:   (part + 1) * size / parts,
		}
	}
	return ranges
}

func chooseGrid(workers, n int) (rowBlocks, columnBlocks int, err error) {
	if workers <= 0 {
		return 0, 0, fmt.Errorf("worker count must be positive")
	}
	if workers > n*n {
		return 0, 0, fmt.Errorf("too many workers for a %dx%d matrix", n, n)
	}

	upper := int(math.Sqrt(float64(workers)))
	for rowBlocks = upper; rowBlocks >= 1; rowBlocks-- {
		if workers%rowBlocks != 0 {
			continue
		}
		columnBlocks = workers / rowBlocks
		if rowBlocks <= n && columnBlocks <= n {
			return rowBlocks, columnBlocks, nil
		}
	}
	return 0, 0, fmt.Errorf("cannot split %d workers into non-empty blocks for size %d", workers, n)
}

func multiplyParallel(a, b Matrix, workers int) (Matrix, error) {
	ensureCompatible(a, b)
	rowBlocks, columnBlocks, err := chooseGrid(workers, a.N)
	if err != nil {
		return Matrix{}, err
	}

	c := newMatrix(a.N)
	rowRanges := splitRange(a.N, rowBlocks)
	columnRanges := splitRange(a.N, columnBlocks)

	var group sync.WaitGroup
	group.Add(workers)
	for _, rows := range rowRanges {
		for _, columns := range columnRanges {
			go func(rows, columns interval) {
				defer group.Done()
				multiplyBlock(a, b, c, rows.start, rows.end, columns.start, columns.end)
			}(rows, columns)
		}
	}
	group.Wait()

	return c, nil
}

func ensureCompatible(a, b Matrix) {
	if a.N == 0 || a.N != b.N || len(a.Data) != a.N*a.N || len(b.Data) != b.N*b.N {
		panic("matrices must be non-empty squares of the same size")
	}
}
