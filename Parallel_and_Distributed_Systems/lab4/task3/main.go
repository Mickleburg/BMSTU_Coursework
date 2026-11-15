package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"math/big"
	"os"
	"runtime"
	"strconv"
	"sync"
	"time"
)

// Fixed pool: workers read independent tasks from one channel.
func pool(workers int, tasks []func()) {
	jobs := make(chan func())
	var done sync.WaitGroup
	for i := 0; i < workers; i++ {
		done.Add(1)
		go func() {
			defer done.Done()
			for job := range jobs {
				job()
			}
		}()
	}
	for _, task := range tasks {
		jobs <- task
	}
	close(jobs)
	done.Wait()
}

func basePrimes(n int) []int {
	marked := make([]bool, n+1)
	var result []int
	for p := 2; p <= n; p++ {
		if !marked[p] {
			result = append(result, p)
			for k := p * p; k <= n; k += p {
				marked[k] = true
			}
		}
	}
	return result
}

func sieveSegment(start, end int, primes []int) int {
	marked := make([]bool, end-start)
	for _, p := range primes {
		first := max(p*p, ((start+p-1)/p)*p)
		for k := first; k < end; k += p {
			marked[k-start] = true
		}
	}
	for k := end - 1; k >= start; k-- {
		if !marked[k-start] {
			return k
		}
	}
	return 0
}

func largestPrime(n, workers int) int {
	root := 0
	for (root+1)*(root+1) <= n {
		root++
	}
	primes := basePrimes(root)
	if workers == 0 {
		return sieveSegment(2, n+1, primes)
	}
	answers := make([]int, workers)
	tasks := make([]func(), workers)
	for i := range tasks {
		tasks[i] = func() {
			answers[i] = sieveSegment(2+(n-1)*i/workers, 2+(n-1)*(i+1)/workers, primes)
		}
	}
	pool(workers, tasks)
	answer := 0
	for _, value := range answers {
		answer = max(answer, value)
	}
	return answer
}

func product(start, end int) *big.Int {
	result, factor := big.NewInt(1), new(big.Int)
	for i := start; i < end; i++ {
		result.Mul(result, factor.SetInt64(int64(i)))
	}
	return result
}

func factorial(n, workers int) *big.Int {
	if workers == 0 {
		return product(1, n+1)
	}
	parts := make([]*big.Int, workers)
	tasks := make([]func(), workers)
	for i := range tasks {
		tasks[i] = func() { parts[i] = product(1+n*i/workers, 1+n*(i+1)/workers) }
	}
	pool(workers, tasks)
	result := big.NewInt(1)
	for _, part := range parts {
		result.Mul(result, part)
	}
	return result
}

// Return two consecutive Fibonacci numbers using the ordinary recurrence.
func fibPair(n int) (*big.Int, *big.Int) {
	a, b := big.NewInt(0), big.NewInt(1)
	for i := 0; i < n; i++ {
		next := new(big.Int).Add(a, b)
		a, b = b, next
	}
	return a, b
}

func fibonacci(n, workers int) *big.Int {
	if workers == 0 {
		a, _ := fibPair(n)
		return a
	}
	parts := make([][2]*big.Int, workers)
	tasks := make([]func(), workers)
	for i := range tasks {
		tasks[i] = func() {
			parts[i][0], parts[i][1] = fibPair(n*(i+1)/workers - n*i/workers)
		}
	}
	pool(workers, tasks)
	a, b := big.NewInt(0), big.NewInt(1)
	for _, part := range parts {
		c, d := part[0], part[1]
		nextA := new(big.Int).Mul(a, d)
		nextA.Add(nextA, new(big.Int).Mul(new(big.Int).Sub(b, a), c))
		nextB := new(big.Int).Mul(b, d)
		nextB.Add(nextB, new(big.Int).Mul(a, c))
		a, b = nextA, nextB
	}
	return a
}

func check() {
	require := func(ok bool) {
		if !ok {
			panic("check failed")
		}
	}
	for _, p := range []int{0, 1, 2, 4, 8} {
		for _, n := range []int{2, 3, 4, 30, 121, 997} {
			expected := 0
			for k := 2; k <= n; k++ {
				prime := true
				for d := 2; d*d <= k; d++ {
					if k%d == 0 {
						prime = false
					}
				}
				if prime {
					expected = k
				}
			}
			require(largestPrime(n, p) == expected)
		}
		for _, n := range []int{0, 1, 5, 71} {
			require(factorial(n, p).Cmp(new(big.Int).MulRange(1, int64(n))) == 0)
		}
		a, b := big.NewInt(0), big.NewInt(1)
		for n := 0; n <= 100; n++ {
			require(fibonacci(n, p).Cmp(a) == 0)
			a, b = b, new(big.Int).Add(a, b)
		}
	}
	fmt.Println("Task 3 checks passed: sieve, factorial, Fibonacci.")
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}

// Only timing and output are shared; each calculation has its own algorithm.
func measure(name string, calculate func(int) *big.Int, repeats int, writer *csv.Writer) {
	expected := calculate(0)
	for _, workers := range []int{0, 1, 2, 4, 8} {
		total := 0.0
		for run := 0; run < repeats; run++ {
			started := time.Now()
			answer := calculate(workers)
			total += time.Since(started).Seconds()
			if answer.Cmp(expected) != 0 {
				panic("wrong answer: " + name)
			}
		}
		mean := total / float64(repeats)
		must(writer.Write([]string{name, strconv.Itoa(workers),
			fmt.Sprintf("%.9f", mean), fmt.Sprintf("%.9f", mean)}))
		fmt.Printf("%s: workers=%d, time=%.6f s, correct=true\n", name, workers, mean)
	}
}

func main() {
	repeats := flag.Int("repeats", 3, "measurements per configuration")
	onlyCheck := flag.Bool("check", false, "check task 3")
	flag.Parse()
	if *onlyCheck {
		check()
		return
	}
	if *repeats < 1 {
		panic("repeats must be positive")
	}
	must(os.MkdirAll("results", 0755))

	// Run from lab4: go run task3/main.go
	file, err := os.Create("results/task3.csv")
	must(err)
	writer := csv.NewWriter(file)
	must(writer.Write([]string{"task", "workers", "mean_total_s", "mean_step_or_total_s"}))
	measure("prime", func(p int) *big.Int {
		return big.NewInt(int64(largestPrime(1000000, p)))
	}, *repeats, writer)
	measure("factorial", func(p int) *big.Int {
		return factorial(20000, p)
	}, *repeats, writer)
	measure("fibonacci", func(p int) *big.Int {
		return fibonacci(200000, p)
	}, *repeats, writer)
	writer.Flush()
	must(writer.Error())
	must(file.Close())

	summary := fmt.Sprintf("Task 3\nGo: %s\nGOMAXPROCS: %d\nRepeats: %d\nPrime <= 1000000: %d\n20000! bits: %d\nF(200000) bits: %d\nAll answers checked.\n",
		runtime.Version(), runtime.GOMAXPROCS(0), *repeats,
		largestPrime(1000000, 0), factorial(20000, 0).BitLen(), fibonacci(200000, 0).BitLen())
	must(os.WriteFile("results/task3.txt", []byte(summary), 0644))
	fmt.Print(summary)
}
