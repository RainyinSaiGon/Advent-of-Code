#!/usr/bin/env bash

set -euo pipefail

YEAR="${1:-}"
DAY="${2:-}"
LANG="${3:-both}"   # python | go | both

if [[ -z "$YEAR" || -z "$DAY" ]]; then
  echo "Usage: ./scripts/new_day.sh <year> <day> [python|go|both]"
  echo "Example:"
  echo "  ./scripts/new_day.sh 2024 1 python"
  echo "  ./scripts/new_day.sh 2024 2 go"
  echo "  ./scripts/new_day.sh 2024 3 both"
  exit 1
fi

if ! [[ "$YEAR" =~ ^[0-9]{4}$ ]]; then
  echo "Error: year must be 4 digits"
  exit 1
fi

if ! [[ "$DAY" =~ ^[0-9]+$ ]]; then
  echo "Error: day must be a number"
  exit 1
fi

if (( DAY < 1 || DAY > 25 )); then
  echo "Error: day must be between 1 and 25"
  exit 1
fi

# Zero-padded: day01, day02, ...
DAY_PADDED=$(printf "day%02d" "$DAY")

BASE="$YEAR/$DAY_PADDED"

mkdir -p "$BASE"

# Shared inputs
touch "$BASE/input.txt"
touch "$BASE/sample.txt"

# ---------- PYTHON ----------
if [[ "$LANG" == "python" || "$LANG" == "both" ]]; then
  PY_DIR="$BASE/python"
  mkdir -p "$PY_DIR"

  if [[ ! -f "$PY_DIR/main.py" ]]; then
    cat > "$PY_DIR/main.py" <<'EOF'
from pathlib import Path


def read_input(filename: str) -> str:
    return Path(filename).read_text().strip()


def part1(data: str):
    return None


def part2(data: str):
    return None


def main():
    data = read_input("../input.txt")
    print("Part 1:", part1(data))
    print("Part 2:", part2(data))


if __name__ == "__main__":
    main()
EOF
  fi
fi

# ---------- GO ----------
if [[ "$LANG" == "go" || "$LANG" == "both" ]]; then
  GO_DIR="$BASE/go"
  mkdir -p "$GO_DIR"

  if [[ ! -f "$GO_DIR/main.go" ]]; then
    cat > "$GO_DIR/main.go" <<'EOF'
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
EOF
  fi
fi

echo "Created $BASE with:"
echo "  input.txt"
echo "  sample.txt"
[[ "$LANG" == "python" || "$LANG" == "both" ]] && echo "  python/main.py"
[[ "$LANG" == "go" || "$LANG" == "both" ]] && echo "  go/main.go"
