#!/usr/bin/env bash
set -euo pipefail

YEAR="${1:-}"
DAY="${2:-}"
FILTER="${3:-all}"   # all | python | go | rust | java | zig
RUNS="${4:-10}"      # number of runs

if [[ -z "$YEAR" || -z "$DAY" ]]; then
  echo "Usage: ./scripts/benchmark.sh <year> <day> [language] [runs]"
  echo "Example:"
  echo "  ./scripts/benchmark.sh 2024 1                  # all languages, 10 runs"
  echo "  ./scripts/benchmark.sh 2024 1 python           # python only"
  echo "  ./scripts/benchmark.sh 2024 1 rust 20          # rust only, 20 runs"
  echo "  ./scripts/benchmark.sh 2024 1 all 10           # all languages, 10 runs"
  exit 1
fi

VALID_FILTERS="all python go rust java zig"
if [[ ! " $VALID_FILTERS " =~ " $FILTER " ]]; then
  echo "Error: unknown language '$FILTER'. Valid options: $VALID_FILTERS"
  exit 1
fi

should_run() {
  [[ "$FILTER" == "all" || "$FILTER" == "$1" ]]
}

DAY_PADDED=$(printf "day%02d" "$DAY")
BASE="$YEAR/$DAY_PADDED"

if [[ ! -d "$BASE" ]]; then
  echo "Error: $BASE does not exist"
  exit 1
fi

# ── Portability helpers ────────────────────────────────────────────────────

# Milliseconds since epoch — works on Linux and macOS
now_ms() {
  if date +%s%3N &>/dev/null && [[ "$(date +%s%3N)" =~ ^[0-9]+$ ]]; then
    date +%s%3N
  else
    # macOS fallback using Python
    python3 -c "import time; print(int(time.time() * 1000))"
  fi
}

# Portable absolute path — works on Linux and macOS
abspath() {
  local path="$1"
  if command -v realpath &>/dev/null; then
    realpath "$path"
  else
    (cd "$path" && pwd)
  fi
}

# Portable mktemp
make_temp() {
  if [[ "$(uname)" == "Darwin" ]]; then
    mktemp -t aoc_go
  else
    mktemp /tmp/aoc_go_XXXX
  fi
}

# Detect python binary
PYTHON_BIN=""
for py in python3 python; do
  if command -v "$py" &>/dev/null; then
    PYTHON_BIN="$py"
    break
  fi
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

# Column widths
C1=12   # LANGUAGE
C2=9    # AVG
C3=9    # MIN
C4=9    # MAX
C5=9    # MEDIAN
C6=10   # STDDEV
C7=10   # RELATIVE
C8=11   # TOTAL
TOTAL_W=92
SEP=$(printf '%0.s─' $(seq 1 $TOTAL_W))

# ── Core functions ─────────────────────────────────────────────────────────

measure() {
  local cmd="$1" dir="$2"
  local times=() output=""
  for (( i=0; i<RUNS; i++ )); do
    local start end
    start=$(now_ms)
    output=$(cd "$dir" && eval "$cmd" 2>&1)
    end=$(now_ms)
    times+=("$(( end - start ))")
  done
  echo "${times[*]}|||$output"
}

compute_stats() {
  awk '{
    n = split($0, a, " ")
    sum = 0; min = a[1]; max = a[1]
    for (i = 1; i <= n; i++) {
      sum += a[i]
      if (a[i] < min) min = a[i]
      if (a[i] > max) max = a[i]
    }
    avg = sum / n
    for (i = 1; i <= n; i++)
      for (j = i+1; j <= n; j++)
        if (a[i] > a[j]) { t=a[i]; a[i]=a[j]; a[j]=t }
    median = (n % 2 == 0) ? (a[n/2] + a[n/2+1]) / 2 : a[int(n/2)+1]
    sq = 0
    for (i = 1; i <= n; i++) sq += (a[i] - avg)^2
    stddev = sqrt(sq / n)
    printf "%.0f %.0f %.0f %.0f %.1f", avg, min, max, median, stddev
  }' <<< "$1"
}

render_bar() {
  local val="$1" max_val="$2"
  local max_w=20 filled=0
  (( max_val > 0 )) && filled=$(awk "BEGIN { printf \"%d\", ($val / $max_val) * $max_w }")
  local bar=""
  for (( i=0; i<filled; i++ ));     do bar+="█"; done
  for (( i=filled; i<max_w; i++ )); do bar+="░"; done
  echo "$bar"
}

compile_lang() {
  local lang="$1" cmd="$2" dir="$3"
  local start end
  start=$(now_ms)
  if ! (cd "$dir" && eval "$cmd"); then
    echo -e "${RED}[$lang] build failed${RESET}"
    return 1
  fi
  end=$(now_ms)
  compile_ms["$lang"]=$(( end - start ))
  echo -e "${CYAN}[$lang]${RESET} compiled in ${compile_ms[$lang]}ms"
}

run_lang() {
  local lang="$1" cmd="$2" dir="$3"
  echo -e "${CYAN}[$lang]${RESET} running $RUNS times..."
  local result
  result=$(measure "$cmd" "$dir")
  all_times["$lang"]="${result%%|||*}"
  outputs["$lang"]="${result##*|||}"
  order+=("$lang")
}

# ── Header ─────────────────────────────────────────────────────────────────

FILTER_LABEL="$FILTER"
[[ "$FILTER" == "all" ]] && FILTER_LABEL="all languages"

echo ""
echo -e "${BOLD}  AoC Benchmark — $YEAR Day $DAY  [$FILTER_LABEL]  ($RUNS runs)${RESET}"
echo -e "  ${BOLD}${SEP}${RESET}"
echo ""

declare -A all_times outputs compile_ms
declare -a order=()

# ── Compile + Run ──────────────────────────────────────────────────────────

# Python
if should_run "python" && [[ -n "$PYTHON_BIN" ]] && [[ -f "$BASE/python/main.py" ]]; then
  compile_ms["python"]="N/A"
  run_lang "python" "$PYTHON_BIN main.py" "$BASE/python"
elif should_run "python" && [[ -f "$BASE/python/main.py" ]] && [[ -z "$PYTHON_BIN" ]]; then
  echo -e "${RED}[python] python3/python not found in PATH${RESET}"
fi

# Go
if should_run "go" && [[ -f "$BASE/go/main.go" ]]; then
  if ! command -v go &>/dev/null; then
    echo -e "${RED}[go] go not found in PATH${RESET}"
  else
    GO_BIN=$(make_temp)
    if compile_lang "go" "go build -o $GO_BIN main.go" "$BASE/go"; then
      run_lang "go" "$GO_BIN" "$BASE/go"
      rm -f "$GO_BIN"
    fi
  fi
fi

# Rust
if should_run "rust" && [[ -f "$BASE/rust/src/main.rs" ]]; then
  if ! command -v cargo &>/dev/null; then
    echo -e "${RED}[rust] cargo not found in PATH${RESET}"
  else
    RUST_DIR="$(abspath "$BASE/rust")"
    if compile_lang "rust" "cargo build --release -q" "$RUST_DIR"; then
      RUST_BIN="$(find "$RUST_DIR/target/release" -maxdepth 1 -type f \( -perm -u+x -o -perm -g+x -o -perm -o+x \) 2>/dev/null | grep -v '\.d$' | head -1)"
      if [[ -n "$RUST_BIN" ]]; then
        run_lang "rust" "$RUST_BIN" "$RUST_DIR"
      else
        echo -e "${RED}[rust] binary not found in target/release${RESET}"
      fi
    fi
  fi
fi

# Java
if should_run "java" && [[ -f "$BASE/java/Main.java" ]]; then
  if ! command -v javac &>/dev/null; then
    echo -e "${RED}[java] javac not found in PATH${RESET}"
  else
    if compile_lang "java" "javac Main.java" "$BASE/java"; then
      run_lang "java" "java Main" "$BASE/java"
    fi
  fi
fi

# Zig
if should_run "zig" && [[ -f "$BASE/zig/main.zig" ]]; then
  if ! command -v zig &>/dev/null; then
    echo -e "${RED}[zig] zig not found in PATH${RESET}"
  else
    ZIG_DIR="$(abspath "$BASE/zig")"
    ZIG_BIN="$ZIG_DIR/zig-out/bin/solution"
    if compile_lang "zig" "zig build -Doptimize=ReleaseFast" "$ZIG_DIR"; then
      if [[ -f "$ZIG_BIN" ]]; then
        run_lang "zig" "$ZIG_BIN" "$ZIG_DIR"
      else
        echo -e "${RED}[zig] binary not found at $ZIG_BIN${RESET}"
      fi
    fi
  fi
fi

if [[ ${#order[@]} -eq 0 ]]; then
  echo -e "${RED}No solutions found for: $FILTER${RESET}"
  exit 1
fi

# ── Stats ──────────────────────────────────────────────────────────────────

declare -A stat_avg stat_min stat_max stat_median stat_stddev

fastest_avg=999999
slowest_avg=0
for lang in "${order[@]}"; do
  read -r avg min max median stddev <<< "$(compute_stats "${all_times[$lang]}")"
  stat_avg["$lang"]=$avg
  stat_min["$lang"]=$min
  stat_max["$lang"]=$max
  stat_median["$lang"]=$median
  stat_stddev["$lang"]=$stddev
  (( avg < fastest_avg )) && fastest_avg=$avg
  (( avg > slowest_avg )) && slowest_avg=$avg
done

# ── Table ──────────────────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}${SEP}${RESET}"
printf "  ${BOLD}%-${C1}s %${C2}s %${C3}s %${C4}s %${C5}s %${C6}s %${C7}s %${C8}s${RESET}\n" \
  "LANGUAGE" "AVG" "MIN" "MAX" "MEDIAN" "STDDEV" "RELATIVE" "TOTAL"
echo -e "  ${BOLD}${SEP}${RESET}"

for lang in "${order[@]}"; do
  avg=${stat_avg[$lang]}
  min=${stat_min[$lang]}
  max=${stat_max[$lang]}
  median=${stat_median[$lang]}
  stddev=${stat_stddev[$lang]}
  rel=$(awk "BEGIN { printf \"%.1fx\", $avg / ($fastest_avg == 0 ? 1 : $fastest_avg) }")
  ratio=$(awk "BEGIN { print int($avg / ($fastest_avg == 0 ? 1 : $fastest_avg)) }")

  if (( ratio <= 1 )); then color=$GREEN
  elif (( ratio <= 5 )); then color=$YELLOW
  else color=$RED
  fi

  ct="${compile_ms[$lang]:-N/A}"
  if [[ "$ct" == "N/A" ]]; then
    total="~${avg}ms"
  else
    total=$(( ct + avg ))ms
  fi

  printf "  %b" "$color"
  printf "%-${C1}s %${C2}s %${C3}s %${C4}s %${C5}s %${C6}s %${C7}s %${C8}s" \
    "$lang" "${avg}ms" "${min}ms" "${max}ms" "${median}ms" "${stddev}ms" "$rel" "$total"
  printf "%b\n" "$RESET"
done

echo -e "  ${BOLD}${SEP}${RESET}"

# ── Bar chart ──────────────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}Speed (relative):${RESET}"
for lang in "${order[@]}"; do
  avg=${stat_avg[$lang]}
  bar=$(render_bar "$avg" "$slowest_avg")
  ratio=$(awk "BEGIN { print int($avg / ($fastest_avg == 0 ? 1 : $fastest_avg)) }")
  if (( ratio <= 1 )); then color=$GREEN
  elif (( ratio <= 5 )); then color=$YELLOW
  else color=$RED
  fi
  printf "  %b%-12s%b %b%s%b %sms\n" "$color" "$lang" "$RESET" "$color" "$bar" "$RESET" "$avg"
done

# ── Compile times ──────────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}Compile times:${RESET}"
for lang in "${order[@]}"; do
  ct="${compile_ms[$lang]:-N/A}"
  if [[ "$ct" == "N/A" ]]; then
    printf "  ${GRAY}%-12s interpreted (no compile step)${RESET}\n" "$lang"
  else
    printf "  ${CYAN}%-12s${RESET} %sms\n" "$lang" "$ct"
  fi
done

# ── Individual runs ────────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}Individual runs:${RESET}"
for lang in "${order[@]}"; do
  echo -e "  ${CYAN}[$lang]${RESET}"
  echo "${all_times[$lang]}" | tr ' ' '\n' | awk 'BEGIN { c=0 } {
    printf "    %5sms", $1; c++
    if (c % 10 == 0) print ""
  } END { if (c % 10 != 0) print "" }'
done

# ── Full output ────────────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}Full output:${RESET}"
for lang in "${order[@]}"; do
  echo -e "  ${CYAN}[$lang]${RESET}"
  echo "${outputs[$lang]}" | sed 's/^/    /'
done

echo ""
