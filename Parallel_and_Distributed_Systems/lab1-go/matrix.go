package main

import "math/rand"

// Matrix is a square matrix stored by rows in one contiguous slice.
// Its layout improves cache locality compared with a slice of small slices.
type Matrix struct {
	N    int
	Data []int64
}

func newMatrix(n int) Matrix {
	return Matrix{N: n, Data: make([]int64, n*n)}
}

func (m Matrix) at(row, column int) int64 {
	return m.Data[row*m.N+column]
}

func (m Matrix) set(row, column int, value int64) {
	m.Data[row*m.N+column] = value
}

func generateMatrix(n, low, high int, seed int64) Matrix {
	if n <= 0 {
		panic("matrix size must be positive")
	}
	if low > high {
		panic("low bound must not exceed high bound")
	}

	rng := rand.New(rand.NewSource(seed))
	matrix := newMatrix(n)
	for index := range matrix.Data {
		matrix.Data[index] = int64(rng.Intn(high-low+1) + low)
	}
	return matrix
}

func matricesEqual(first, second Matrix) bool {
	if first.N != second.N || len(first.Data) != len(second.Data) {
		return false
	}
	for index, value := range first.Data {
		if value != second.Data[index] {
			return false
		}
	}
	return true
}
