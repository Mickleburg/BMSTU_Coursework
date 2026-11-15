package main

import (
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"math/rand"
	"os"
	"reflect"
	"runtime"
	"strconv"
	"sync"
	"time"
)

// A reusable barrier: all participants must finish a phase before continuing.
type barrier struct {
	condition                  *sync.Cond
	total, arrived, generation int
}

func newBarrier(total int) *barrier {
	return &barrier{condition: sync.NewCond(&sync.Mutex{}), total: total}
}

func (b *barrier) wait() {
	b.condition.L.Lock()
	defer b.condition.L.Unlock()
	generation := b.generation
	b.arrived++
	if b.arrived == b.total {
		b.arrived = 0
		b.generation++
		b.condition.Broadcast()
	} else {
		for generation == b.generation {
			b.condition.Wait()
		}
	}
}

type field [][]byte

func copyField(input field) field {
	result := make(field, len(input))
	for i := range input {
		result[i] = append([]byte(nil), input[i]...)
	}
	return result
}

func makeField(height, width int) field {
	rng := rand.New(rand.NewSource(1))
	result := make(field, height)
	for i := range result {
		result[i] = make([]byte, width)
		for j := range result[i] {
			result[i][j] = byte(rng.Intn(2))
		}
	}
	return result
}

func nextStrip(rows field, top, bottom []byte) field {
	height, width := len(rows), len(rows[0])
	extended := make(field, 0, height+2)
	extended = append(extended, top)
	extended = append(extended, rows...)
	extended = append(extended, bottom)
	result := make(field, height)
	for i := range rows {
		result[i] = make([]byte, width)
		for j := range rows[i] {
			neighbours := 0
			for di := -1; di <= 1; di++ {
				for dj := -1; dj <= 1; dj++ {
					if di != 0 || dj != 0 {
						neighbours += int(extended[i+1+di][(j+dj+width)%width])
					}
				}
			}
			if neighbours == 3 || (rows[i][j] == 1 && neighbours == 2) {
				result[i][j] = 1
			}
		}
	}
	return result
}

type request struct {
	last  bool
	reply chan []byte
}

func evolution(input field, steps, workers int) field {
	if workers == 0 {
		rows := copyField(input)
		for step := 0; step < steps; step++ {
			rows = copyField(nextStrip(rows, rows[len(rows)-1], rows[0]))
		}
		return rows
	}
	if workers < 1 || workers > len(input) {
		panic("workers must be between 1 and the number of rows")
	}
	requests := make([]chan request, workers)
	for i := range requests {
		requests[i] = make(chan request, 2)
	}
	results := make([]field, workers)
	phase := newBarrier(workers)
	var done sync.WaitGroup
	for i := 0; i < workers; i++ {
		// Only this copy, not the complete input field, enters the worker.
		rows := copyField(input[i*len(input)/workers : (i+1)*len(input)/workers])
		done.Add(1)
		go func(index int, rows field) {
			defer done.Done()
			topReply, bottomReply := make(chan []byte, 1), make(chan []byte, 1)
			for step := 0; step < steps; step++ {
				requests[(index-1+workers)%workers] <- request{true, topReply}
				requests[(index+1)%workers] <- request{false, bottomReply}
				for k := 0; k < 2; k++ {
					query := <-requests[index]
					row := rows[0]
					if query.last {
						row = rows[len(rows)-1]
					}
					query.reply <- append([]byte(nil), row...)
				}
				next := nextStrip(rows, <-topReply, <-bottomReply)
				phase.wait()
				rows = copyField(next)
				phase.wait()
			}
			results[index] = rows
		}(i, rows)
	}
	done.Wait()
	var result field
	for _, rows := range results {
		result = append(result, rows...)
	}
	return result
}

func check() {
	require := func(ok bool) {
		if !ok {
			panic("check failed")
		}
	}
	field := makeField(11, 9)
	for _, steps := range []int{0, 1, 7} {
		for _, p := range []int{1, 2, 3, 11} {
			require(reflect.DeepEqual(evolution(field, steps, 0), evolution(field, steps, p)))
		}
	}
	blinker := makeField(5, 5)
	for i := range blinker {
		clear(blinker[i])
	}
	for _, j := range []int{4, 0, 1} {
		blinker[0][j] = 1
	}
	expected := copyField(blinker)
	for i := range expected {
		clear(expected[i])
	}
	for _, i := range []int{4, 0, 1} {
		expected[i][0] = 1
	}
	require(reflect.DeepEqual(evolution(blinker, 1, 3), expected))
	fmt.Println("Task 1 checks passed: torus, generations, uneven strips.")
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}

func saveJSON(path string, value any) {
	file, err := os.Create(path)
	must(err)
	must(json.NewEncoder(file).Encode(value))
	must(file.Close())
}

func main() {
	repeats := flag.Int("repeats", 3, "measurements per configuration")
	onlyCheck := flag.Bool("check", false, "check task 1")
	flag.Parse()
	if *onlyCheck {
		check()
		return
	}
	if *repeats < 1 {
		panic("repeats must be positive")
	}
	must(os.MkdirAll("results", 0755))

	// Run from lab4: go run task1/main.go
	initial := makeField(256, 256)
	const steps = 20
	expected := evolution(initial, steps, 0)
	file, err := os.Create("results/task1.csv")
	must(err)
	writer := csv.NewWriter(file)
	must(writer.Write([]string{"task", "workers", "mean_total_s", "mean_step_or_total_s"}))
	for _, workers := range []int{0, 1, 2, 4, 8} {
		total := 0.0
		for run := 0; run < *repeats; run++ {
			started := time.Now()
			answer := evolution(initial, steps, workers)
			total += time.Since(started).Seconds()
			if !reflect.DeepEqual(answer, expected) {
				panic("wrong generation")
			}
		}
		mean := total / float64(*repeats)
		must(writer.Write([]string{"evolution", strconv.Itoa(workers),
			fmt.Sprintf("%.9f", mean), fmt.Sprintf("%.9f", mean/steps)}))
		fmt.Printf("Task 1: workers=%d, total=%.6f s, step=%.6f s, correct=true\n",
			workers, mean, mean/steps)
	}
	writer.Flush()
	must(writer.Error())
	must(file.Close())

	// []byte becomes base64 in JSON, so convert it to ordinary integer arrays.
	asInts := func(input field) [][]int {
		result := make([][]int, len(input))
		for i := range input {
			result[i] = make([]int, len(input[i]))
			for j, value := range input[i] {
				result[i][j] = int(value)
			}
		}
		return result
	}
	saveJSON("results/fields.json", [][][]int{asInts(initial), asInts(expected)})
	summary := fmt.Sprintf("Task 1\nGo: %s\nGOMAXPROCS: %d\nRepeats: %d\nField: 256x256\nSteps: 20\nSeed: 1\nAll generations checked.\n",
		runtime.Version(), runtime.GOMAXPROCS(0), *repeats)
	must(os.WriteFile("results/task1.txt", []byte(summary), 0644))
	fmt.Print(summary)
}
