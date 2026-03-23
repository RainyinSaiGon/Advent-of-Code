package main

import (
	"fmt"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
)

func readInput(path string) string {
	data, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	return strings.TrimSpace(string(data))
}

func parse(data string) ([]int, []int) {
	left := []int{}
	right := []int{}
	for _, line := range strings.Split(data, "\n") {
		if line == "" {
			continue
		}
		parts := strings.Fields(line)
		a, _ := strconv.Atoi(parts[0])
		b, _ := strconv.Atoi(parts[1])
		left = append(left, a)
		right = append(right, b)
	}
	return left, right
}

func part1(data string) int {
	left, right := parse(data)
	sort.Ints(left)
	sort.Ints(right)

	total := 0
	for i := range left {
		total += int(math.Abs(float64(left[i] - right[i])))
	}
	return total
}

func part2(data string) int {
	left, right := parse(data)

	counts := map[int]int{}
	for _, num := range right {
		counts[num]++
	}

	total := 0
	for _, num := range left {
		total += num * counts[num]
	}
	return total
}

func main() {
	data := readInput("../input.txt")
	fmt.Println("Part 1:", part1(data))
	fmt.Println("Part 2:", part2(data))
}
