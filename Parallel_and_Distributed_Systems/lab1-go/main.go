package main

import (
	"flag"
	"fmt"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
)

func main() {
	mode := flag.String("mode", "parallel", "benchmark mode: sequential or parallel")
	size := flag.Int("size", 1000, "square matrix size")
	workerList := flag.String("workers", "1,2,4,8,16,32,64", "comma-separated worker counts")
	runs := flag.Int("runs", 10, "number of measured runs")
	flag.Parse()

	if *size <= 0 {
		fail("-size must be positive")
	}
	if *runs <= 0 {
		fail("-runs must be positive")
	}
	runtime.GOMAXPROCS(runtime.NumCPU())
	a := generateMatrix(*size, -10, 10, 1)
	b := generateMatrix(*size, -10, 10, 2)

	switch *mode {
	case "sequential":
		runSequential(a, b, *runs)
	case "parallel":
		workers, err := parseWorkers(*workerList)
		if err != nil {
			fail(err.Error())
		}
		runParallel(a, b, workers, *runs)
	default:
		fail("-mode must be sequential or parallel")
	}
}

func runSequential(a, b Matrix, runs int) {
	var rowsTotal time.Duration
	var columnsTotal time.Duration
	correct := true

	for run := 0; run < runs; run++ {
		rowsStarted := time.Now()
		byRows := multiplyByRows(a, b)
		rowsTotal += time.Since(rowsStarted)

		columnsStarted := time.Now()
		byColumns := multiplyByColumns(a, b)
		columnsTotal += time.Since(columnsStarted)

		correct = correct && matricesEqual(byRows, byColumns)
	}

	fmt.Printf("Matrix size: %d x %d\n", a.N, a.N)
	fmt.Printf("Runs: %d\n", runs)
	fmt.Printf("Average by rows:    %.6f s\n", average(rowsTotal, runs))
	fmt.Printf("Average by columns: %.6f s\n", average(columnsTotal, runs))
	fmt.Printf("Results are equal: %t\n", correct)
}

type workerStats struct {
	count   int
	total   time.Duration
	correct bool
}

func runParallel(a, b Matrix, workers []int, runs int) {
	stats := make([]workerStats, len(workers))
	for index, count := range workers {
		stats[index] = workerStats{count: count, correct: true}
	}

	var sequentialTotal time.Duration
	for run := 0; run < runs; run++ {
		referenceStarted := time.Now()
		reference := multiplyByRows(a, b)
		sequentialTotal += time.Since(referenceStarted)

		for index := range stats {
			started := time.Now()
			result, err := multiplyParallel(a, b, stats[index].count)
			stats[index].total += time.Since(started)
			if err != nil {
				fail(err.Error())
			}
			stats[index].correct = stats[index].correct && matricesEqual(reference, result)
		}
	}

	sequentialAverage := average(sequentialTotal, runs)
	fmt.Printf("Matrix size: %d x %d\n", a.N, a.N)
	fmt.Printf("Runs: %d\n", runs)
	fmt.Printf("Logical CPUs: %d\n", runtime.GOMAXPROCS(0))
	fmt.Printf("Average sequential: %.6f s\n\n", sequentialAverage)

	for _, stat := range stats {
		workerAverage := average(stat.total, runs)
		fmt.Printf(
			"Workers: %2d | Average: %.6f s | Speedup: %.2fx | Correct: %t\n",
			stat.count,
			workerAverage,
			sequentialAverage/workerAverage,
			stat.correct,
		)
	}
}

func average(total time.Duration, runs int) float64 {
	return total.Seconds() / float64(runs)
}

func parseWorkers(value string) ([]int, error) {
	parts := strings.Split(value, ",")
	workers := make([]int, 0, len(parts))
	for _, part := range parts {
		count, err := strconv.Atoi(strings.TrimSpace(part))
		if err != nil || count <= 0 {
			return nil, fmt.Errorf("invalid worker count %q", part)
		}
		workers = append(workers, count)
	}
	return workers, nil
}

func fail(message string) {
	fmt.Println("Error:", message)
	flag.Usage()
	os.Exit(2)
}
