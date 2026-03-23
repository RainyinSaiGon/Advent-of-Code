from pathlib import Path


def read_input(filename: str) -> str:
    return Path(filename).read_text().strip()


def part1(data: str):
    # Data handle
    left_col, right_col = [], []
    for line in data.splitlines():
        a, b = line.split()
        left_col.append(int(a))
        right_col.append(int(b))
        
    # Sorting the list 
    left_col = sorted(left_col)
    right_col = sorted(right_col)

    # Processing
    total = 0
    for left_value, right_value in zip(left_col, right_col):
        total += abs(left_value - right_value)
            
    
    #print(left_col)
    #print(right_col)
    #print(total)
    return total


def part2(data: str):
    left_col, right_col = {}, {}
    for line in data.splitlines():
        a, b =  line.split()
        left_col[int(a)] =  left_col.get(int(a), 0) + 1
        right_col[int(b)] =  right_col.get(int(b), 0) + 1

    similarityScore = 0
    for key in left_col.keys():
        if key in right_col.keys():
            similarityScore += right_col.get(key) * key * left_col.get(key)
        
    #print(left_col)
    #print(right_col)
    #print(similarityScore)
    return similarityScore


def main():
    data = read_input("../input.txt")
    print("Part 1:", part1(data))
    print("Part 2:", part2(data))


if __name__ == "__main__":
    main()
