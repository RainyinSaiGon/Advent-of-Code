#!/usr/bin/env bash
set -euo pipefail

YEAR="${1:-}"
DAY="${2:-}"
LANG="${3:-both}"   # python | go | rust | java | zig | both

if [[ -z "$YEAR" || -z "$DAY" ]]; then
  echo "Usage: ./scripts/new_day.sh <year> <day> [python|go|rust|java|zig|both]"
  echo "Example:"
  echo "  ./scripts/new_day.sh 2024 1 python"
  echo "  ./scripts/new_day.sh 2024 2 go"
  echo "  ./scripts/new_day.sh 2024 3 rust"
  echo "  ./scripts/new_day.sh 2024 4 java"
  echo "  ./scripts/new_day.sh 2024 5 zig"
  echo "  ./scripts/new_day.sh 2024 6 both"
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

VALID_LANGS="python go rust java zig both"
if [[ ! " $VALID_LANGS " =~ " $LANG " ]]; then
  echo "Error: unknown language '$LANG'. Valid options: $VALID_LANGS"
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
EOF
  fi
fi

# ---------- RUST ----------
if [[ "$LANG" == "rust" || "$LANG" == "both" ]]; then
  RS_DIR="$BASE/rust"
  mkdir -p "$RS_DIR/src"

  if [[ ! -f "$RS_DIR/Cargo.toml" ]]; then
    PKG_NAME="aoc-${YEAR}-${DAY_PADDED}"
    cat > "$RS_DIR/Cargo.toml" <<EOF
[package]
name = "${PKG_NAME}"
version = "0.1.0"
edition = "2021"
EOF
  fi

  if [[ ! -f "$RS_DIR/src/main.rs" ]]; then
    cat > "$RS_DIR/src/main.rs" <<'EOF'
use std::fs;

fn read_input(path: &str) -> String {
    fs::read_to_string(path)
        .expect("Failed to read input file")
        .trim()
        .to_string()
}

fn part1(data: &str) -> String {
    let _ = data;
    String::from("unimplemented")
}

fn part2(data: &str) -> String {
    let _ = data;
    String::from("unimplemented")
}

fn main() {
    let data = read_input("../input.txt");
    println!("Part 1: {}", part1(&data));
    println!("Part 2: {}", part2(&data));
}
EOF
  fi
fi

# ---------- JAVA ----------
if [[ "$LANG" == "java" || "$LANG" == "both" ]]; then
  JAVA_DIR="$BASE/java"
  mkdir -p "$JAVA_DIR"
  if [[ ! -f "$JAVA_DIR/Main.java" ]]; then
    cat > "$JAVA_DIR/Main.java" <<'EOF'
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class Main {
    static String readInput(String path) throws IOException {
        return Files.readString(Path.of(path)).strip();
    }

    static String part1(String data) {
        return "unimplemented";
    }

    static String part2(String data) {
        return "unimplemented";
    }

    public static void main(String[] args) throws IOException {
        String data = readInput("../input.txt");
        System.out.println("Part 1: " + part1(data));
        System.out.println("Part 2: " + part2(data));
    }
}
EOF
  fi
fi

# ---------- ZIG ----------
if [[ "$LANG" == "zig" || "$LANG" == "both" ]]; then
  ZIG_DIR="$BASE/zig"
  mkdir -p "$ZIG_DIR"

  if [[ ! -f "$ZIG_DIR/build.zig" ]]; then
    cat > "$ZIG_DIR/build.zig" <<'EOF'
const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "solution",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the solution");
    run_step.dependOn(&run_cmd.step);
}
EOF
  fi

  if [[ ! -f "$ZIG_DIR/main.zig" ]]; then
    cat > "$ZIG_DIR/main.zig" <<'EOF'
const std = @import("std");

fn part1(data: []const u8, allocator: std.mem.Allocator) !i64 {
    _ = data;
    _ = allocator;
    return 0;
}

fn part2(data: []const u8, allocator: std.mem.Allocator) !i64 {
    _ = data;
    _ = allocator;
    return 0;
}

pub fn main(init: std.process.Init) !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    // Read input file
    const cwd = std.Io.Dir.cwd();
    const file = try cwd.openFile(init.io, "../input.txt", .{ .mode = .read_only });
    var read_buf: [4096]u8 = undefined;
    var f_reader = file.reader(init.io, &read_buf);
    var content = std.Io.Writer.Allocating.init(allocator);
    defer content.deinit();
    _ = try f_reader.interface.streamRemaining(&content.writer);

    const trimmed = std.mem.trim(u8, content.written(), "\n\r ");

    // Write output — std.debug.print writes to stderr and always flushes
    const p1 = try part1(trimmed, allocator);
    const p2 = try part2(trimmed, allocator);
    std.debug.print("Part 1: {d}\n", .{p1});
    std.debug.print("Part 2: {d}\n", .{p2});
}
EOF
  fi
fi

echo "Created $BASE with:"
echo "  input.txt"
echo "  sample.txt"
[[ "$LANG" == "python" || "$LANG" == "both" ]] && echo "  python/main.py"
[[ "$LANG" == "go"     || "$LANG" == "both" ]] && echo "  go/main.go"
[[ "$LANG" == "rust"   || "$LANG" == "both" ]] && echo "  rust/Cargo.toml"
[[ "$LANG" == "rust"   || "$LANG" == "both" ]] && echo "  rust/src/main.rs"
[[ "$LANG" == "java"   || "$LANG" == "both" ]] && echo "  java/Main.java"
[[ "$LANG" == "zig"    || "$LANG" == "both" ]] && echo "  zig/build.zig"
[[ "$LANG" == "zig"    || "$LANG" == "both" ]] && echo "  zig/main.zig"
