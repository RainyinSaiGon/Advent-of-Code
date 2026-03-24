from pathlib import Path


def read_input(filename: str) -> str:
    return Path(filename).read_text().strip()

def isSafe(arr):
    if len(arr) <= 2:
        return True

    if (arr[0] == arr[1]):
        return False
    
    type = ""
    if (arr[0] > arr[1]):
        type = "down"
    else:
        type = "up"

    for i in range(1, len(arr)):
        diff = arr[i] - arr[i - 1]

        if (type == "up"  and arr[i] <= arr[i - 1]):
            return False

        if (type == "up"  and (diff > 3 or diff < 0)):
            return False

        if (type == "down" and arr[i] >= arr[i - 1]):
            return False

        if (type == "down" and (diff < -3 or diff >= 0)):
            return False

    return True
    

def part1(data: str):
    total = 0
    for line in data.splitlines():
        arr = [int(x) for x in line.split()]
        if isSafe(arr):
            total += 1
    return total


def part2(data: str):
    total = 0
    for line in data.splitlines():
        arr = [int(x) for x in line.split()]
        if isSafe(arr):
            total += 1

        else:
            for i in range (len(arr)):
                test_arr = arr[:i] + arr[i + 1:]
                # print(test_arr)
                if isSafe(test_arr):
                    total += 1
                    break
    return total



def main():
    data = read_input("../input.txt")
    print("Part 1:", part1(data))
    print("Part 2:", part2(data))


if __name__ == "__main__":
    main()
