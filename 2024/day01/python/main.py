from pathlib import Path
from collections import Counter


def read_input(filename: str) -> str:
    return Path(filename).read_text().strip()


def parse_columns(data: str):
    left = []
    right = []
    left_append = left.append
    right_append = right.append
    for line in data.splitlines():
        a, b = line.split()
        left_append(int(a))
        right_append(int(b))
    return left, right


def part1(left, right):
    left = left.copy()
    right = right.copy()
    left.sort()
    right.sort()
    total = 0
    for a, b in zip(left, right):
        total += abs(a - b)
    return total


def part2(left, right):
    left_count = Counter(left)
    right_count = Counter(right)
    right_get = right_count.get
    total = 0
    for value, count in left_count.items():
        total += value * count * right_get(value, 0)
    return total


def main():
    data = read_input("../input.txt")
    left, right = parse_columns(data)
    print("Part 1:", part1(left, right))
    print("Part 2:", part2(left, right))


if __name__ == "__main__":
    main()
