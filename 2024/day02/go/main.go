package main

import (
	"fmt"
	"os"
	"strings"
)

func readInput(path string) string {
	data, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	return strings.TrimSpace(string(data))
}

func part1(data string) string {
	return "unimplemented"
}

func part2(data string) string {
	return "unimplemented"
}

func main() {
	data := readInput("../input.txt")
	fmt.Println("Part 1:", part1(data))
	fmt.Println("Part 2:", part2(data))
}
