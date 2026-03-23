# Advent of Code

My solutions to [Advent of Code](https://adventofcode.com/) puzzles, implemented in multiple languages to practice and compare them.

## Languages

| Language | Version | Notes |
|---|---|---|
| Python | 3.12.3 | Scratchpad — solve logic fast |
| Go | 1.26.1 | Cloud/backend, concurrency |
| Rust | 1.94 | Main focus — systems, performance |
| Java | 25 | JVM, enterprise ecosystem |
| Zig | 0.16.0-dev | Low-level, close to metal |

## Structure

```
aoc/
├── scripts/
│   ├── new_day.sh       # scaffold a new day
│   └── benchmark.sh     # benchmark solutions
├── 2024/
│   ├── day01/
│   │   ├── input.txt    # puzzle input (not tracked)
│   │   ├── sample.txt   # example input from problem
│   │   ├── python/
│   │   │   └── main.py
│   │   ├── go/
│   │   │   └── main.go
│   │   ├── rust/
│   │   │   ├── Cargo.toml
│   │   │   └── src/main.rs
│   │   ├── java/
│   │   │   └── Main.java
│   │   └── zig/
│   │       ├── build.zig
│   │       └── main.zig
│   └── day02/
│       └── ...
└── 2025/
    └── ...
```

## Scripts

### Scaffold a new day

```bash
./scripts/new_day.sh <year> <day> [language]
```

```bash
./scripts/new_day.sh 2024 1          # all languages
./scripts/new_day.sh 2024 1 python   # python only
./scripts/new_day.sh 2024 1 rust     # rust only
```

### Benchmark

```bash
./scripts/benchmark.sh <year> <day> [language] [runs]
```

```bash
./scripts/benchmark.sh 2024 1           # all languages, 10 runs
./scripts/benchmark.sh 2024 1 python    # python only
./scripts/benchmark.sh 2024 1 rust 20   # rust only, 20 runs
```

Example output:

```
  AoC Benchmark — 2024 Day 1  [all languages]  (10 runs)
  ────────────────────────────────────────────────────────────────────────────────────────────
  LANGUAGE           AVG       MIN       MAX    MEDIAN     STDDEV   RELATIVE       TOTAL
  ────────────────────────────────────────────────────────────────────────────────────────────
  python            19ms      18ms      23ms      19ms      1.3ms       6.3x       ~19ms
  go                 3ms       3ms       4ms       3ms      0.4ms       1.0x       295ms
  rust               3ms       2ms       5ms       3ms      1.0ms       1.0x        27ms
  java              51ms      47ms      56ms      51ms      2.9ms      17.0x       540ms
  zig                3ms       2ms       3ms       3ms      0.4ms       1.0x       102ms
  ────────────────────────────────────────────────────────────────────────────────────────────
```

### Running a single solution

```bash
# Python
cd 2024/day01/python && python3 main.py

# Go
cd 2024/day01/go && go run main.go

# Rust
cd 2024/day01/rust && cargo run --release

# Java
cd 2024/day01/java && javac Main.java && java Main

# Zig
cd 2024/day01/zig && zig build run
```

## Prerequisites

| Language | Install |
|---|---|
| Python | `sudo apt install python3` |
| Go | [go.dev/dl](https://go.dev/dl) |
| Rust | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Java | `sudo apt install openjdk-25-jdk` |
| Zig | [ziglang.org/download](https://ziglang.org/download) or `zvm install master` |

## Solutions

### 2024

| Day | Problem | Python | Go | Rust | Java | Zig |
|---|---|---|---|---|---|---|
| [Day 01](2024/day01/) | [Historian Hysteria](https://adventofcode.com/2024/day/1) | ** | ** | ** | ** | ** |

> * = part 1 solved, ** = both parts solved

## Notes

- `input.txt` files are not tracked (AoC asks you not to share inputs publicly)
- `sample.txt` contains the example input from the problem description
- Benchmark TOTAL includes compile time — first run is slower due to cold cache
- Zig uses `0.16.0-dev` (nightly) — APIs may differ from stable releases
