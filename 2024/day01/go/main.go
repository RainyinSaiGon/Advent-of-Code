package main

import (
	"fmt"
	"os"
)

func readInput(path string) string {
	data, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	return string(data)
}

func part1(data string) string {
	return data
}

func part2(data string) string {
	return data
}

func main() {
	data := readInput("../input.txt")
	fmt.Println("Part 1:", part1(data))
	fmt.Println("Part 2:", part2(data))
}
