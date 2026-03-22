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
