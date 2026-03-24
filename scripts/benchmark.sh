#!/usr/bin/env bash
set -euo pipefail

YEAR="${1:-}"
DAY="${2:-}"
FILTER="${3:-all}"   # all | python | go | rust | java | zig
RUNS="${4:-10}"

if [[ -z "$YEAR" || -z "$DAY" ]]; then
  echo "Usage: ./scripts/benchmark.sh <year> <day> [language] [runs]"
  echo "Example:"
  echo "  ./scripts/benchmark.sh 2024 1                  # all languages, 10 runs"
  echo "  ./scripts/benchmark.sh 2024 1 python           # python only"
  echo "  ./scripts/benchmark.sh 2024 1 rust 20          # rust, 20 runs"
  exit 1
fi

VALID_FILTERS="all python go rust java zig"
if [[ ! " $VALID_FILTERS " =~ " $FILTER " ]]; then
  echo "Error: unknown language '$FILTER'. Valid options: $VALID_FILTERS"
  exit 1
fi

should_run() { [[ "$FILTER" == "all" || "$FILTER" == "$1" ]]; }

DAY_PADDED=$(printf "day%02d" "$DAY")
BASE="$YEAR/$DAY_PADDED"

if [[ ! -d "$BASE" ]]; then
  echo "Error: $BASE does not exist"
  exit 1
fi

# ── Portability ────────────────────────────────────────────────────────────

OS="$(uname)"

# Microseconds since epoch
now_us() {
  if [[ "$OS" == "Darwin" ]]; then
    python3 -c "import time; print(int(time.time() * 1000000))"
  else
    date +%s%6N 2>/dev/null || python3 -c "import time; print(int(time.time() * 1000000))"
  fi
}

# Absolute path
abspath() {
  if command -v realpath &>/dev/null; then realpath "$1"
  else (cd "$1" && pwd); fi
}

# Portable mktemp
make_temp() {
  if [[ "$OS" == "Darwin" ]]; then mktemp -t aoc
  else mktemp /tmp/aoc_XXXX; fi
}

# Parse peak memory (in KB) from /usr/bin/time output
parse_mem_kb() {
  local file="$1"
  if [[ "$OS" == "Darwin" ]]; then
    # macOS reports bytes
    awk '/maximum resident set size/ { print int($1 / 1024) }' "$file"
  else
    # Linux reports KB
    awk '/Maximum resident set size/ { print $NF }' "$file"
  fi
}

# Parse CPU % from /usr/bin/time output
parse_cpu() {
  local file="$1"
  if [[ "$OS" == "Darwin" ]]; then
    awk '/percent cpu/ { print int($1) }' "$file"
  else
    awk '/Percent of CPU/ { print $NF }' "$file" | tr -d '%'
  fi
}

# Detect python
PYTHON_BIN=""
for py in python3 python; do
  command -v "$py" &>/dev/null && { PYTHON_BIN="$py"; break; }
done

# ── Colors ─────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

SEP92=$(printf '%0.s─' $(seq 1 92))
SEP72=$(printf '%0.s─' $(seq 1 72))

# ── Core measure (timing only — fast, many runs) ───────────────────────────

measure() {
  local cmd="$1" dir="$2"
  local times=() output=""
  for (( i=0; i<RUNS; i++ )); do
    local start end
    start=$(now_us)
    output=$(cd "$dir" && eval "$cmd" 2>&1)
    end=$(now_us)
    times+=("$(( end - start ))")
  done
  echo "${times[*]}|||$output"
}

# ── Resource measure (memory + CPU — one dedicated run) ───────────────────

measure_resources() {
  local cmd="$1" dir="$2"
  local tmpfile
  tmpfile=$(make_temp)

  # /usr/bin/time writes stats to stderr → redirect to tmpfile
  # program output goes to stdout → captured separately
  local prog_output
  prog_output=$(cd "$dir" && /usr/bin/time -v sh -c "$cmd" 2>"$tmpfile" || \
                cd "$dir" && /usr/bin/time sh -c "$cmd" 2>"$tmpfile")

  local mem_kb cpu_pct
  mem_kb=$(parse_mem_kb "$tmpfile")
  cpu_pct=$(parse_cpu "$tmpfile")
  rm -f "$tmpfile"

  echo "${mem_kb:-0}|||${cpu_pct:-0}"
}

# ── Stats ──────────────────────────────────────────────────────────────────

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

# Format microseconds → human readable
fmt_us() {
  local us="$1"
  local us_int="${us%.*}" # Strip decimal part for Bash integer arithmetic
  
  if (( us_int >= 1000000 )); then
    awk "BEGIN { printf \"%.2fs\", $us / 1000000 }"
  elif (( us_int >= 1000 )); then
    awk "BEGIN { printf \"%.1fms\", $us / 1000 }"
  else
    echo "${us}us"
  fi
}

# Format memory KB → human readable
fmt_mem() {
  local kb="$1"
  if (( kb >= 1048576 )); then
    awk "BEGIN { printf \"%.1fGB\", $kb / 1048576 }"
  elif (( kb >= 1024 )); then
    awk "BEGIN { printf \"%.1fMB\", $kb / 1024 }"
  else
    echo "${kb}KB"
  fi
}

# Format ops/sec
fmt_ops() {
  local us="$1"
  if (( us == 0 )); then echo "N/A"; return; fi
  local ops
  ops=$(awk "BEGIN { printf \"%.0f\", 1000000 / $us }")
  if (( ops >= 1000000 )); then
    awk "BEGIN { printf \"%.1fM/s\", $ops / 1000000 }"
  elif (( ops >= 1000 )); then
    awk "BEGIN { printf \"%.1fK/s\", $ops / 1000 }"
  else
    echo "${ops}/s"
  fi
}

render_bar() {
  local val="$1" max_val="$2" max_w=20 filled=0
  (( max_val > 0 )) && filled=$(awk "BEGIN { printf \"%d\", ($val / $max_val) * $max_w }")
  local bar=""
  for (( i=0; i<filled; i++ ));     do bar+="█"; done
  for (( i=filled; i<max_w; i++ )); do bar+="░"; done
  echo "$bar"
}

compile_lang() {
  local lang="$1" cmd="$2" dir="$3"
  local start end
  start=$(now_us)
  if ! (cd "$dir" && eval "$cmd"); then
    echo -e "${RED}[$lang] build failed${RESET}"
    return 1
  fi
  end=$(now_us)
  compile_us["$lang"]=$(( end - start ))
  echo -e "${CYAN}[$lang]${RESET} compiled in $(fmt_us "${compile_us[$lang]}")"
}

run_lang() {
  local lang="$1" cmd="$2" dir="$3"
  echo -e "${CYAN}[$lang]${RESET} running $RUNS times..."
  local result
  result=$(measure "$cmd" "$dir")
  all_times["$lang"]="${result%%|||*}"
  outputs["$lang"]="${result##*|||}"

  # Resource measurement (single dedicated run)
  if command -v /usr/bin/time &>/dev/null; then
    local res
    res=$(measure_resources "$cmd" "$dir" 2>/dev/null || echo "0|||0")
    mem_kb["$lang"]="${res%%|||*}"
    cpu_pct["$lang"]="${res##*|||}"
  else
    mem_kb["$lang"]="0"
    cpu_pct["$lang"]="0"
  fi

  order+=("$lang")
}

# ── Header ─────────────────────────────────────────────────────────────────

FILTER_LABEL="$FILTER"
[[ "$FILTER" == "all" ]] && FILTER_LABEL="all languages"

echo ""
echo -e "${BOLD}  AoC Benchmark — $YEAR Day $DAY  [$FILTER_LABEL]  ($RUNS runs)${RESET}"
echo -e "  ${BOLD}${SEP92}${RESET}"
echo ""

declare -A all_times outputs compile_us mem_kb cpu_pct
declare -a order=()

# ── Compile + Run ──────────────────────────────────────────────────────────

# Python
if should_run "python" && [[ -n "$PYTHON_BIN" ]] && [[ -f "$BASE/python/main.py" ]]; then
  compile_us["python"]="0"
  run_lang "python" "$PYTHON_BIN main.py" "$BASE/python"
fi

# Go
if should_run "go" && [[ -f "$BASE/go/main.go" ]]; then
  if ! command -v go &>/dev/null; then
    echo -e "${RED}[go] not found in PATH${RESET}"
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
      RUST_BIN="$(find "$RUST_DIR/target/release" -maxdepth 1 -type f \( -perm -u+x -o -perm -g+x \) 2>/dev/null | grep -v '\.d$' | head -1)"
      [[ -n "$RUST_BIN" ]] && run_lang "rust" "$RUST_BIN" "$RUST_DIR" || \
        echo -e "${RED}[rust] binary not found${RESET}"
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
    echo -e "${RED}[zig] not found in PATH${RESET}"
  else
    ZIG_DIR="$(abspath "$BASE/zig")"
    ZIG_BIN="$ZIG_DIR/zig-out/bin/solution"
    if compile_lang "zig" "zig build -Doptimize=ReleaseFast" "$ZIG_DIR"; then
      [[ -f "$ZIG_BIN" ]] && run_lang "zig" "$ZIG_BIN" "$ZIG_DIR" || \
        echo -e "${RED}[zig] binary not found at $ZIG_BIN${RESET}"
    fi
  fi
fi

if [[ ${#order[@]} -eq 0 ]]; then
  echo -e "${RED}No solutions found for: $FILTER${RESET}"
  exit 1
fi

# ── Compute stats ──────────────────────────────────────────────────────────

declare -A stat_avg stat_min stat_max stat_median stat_stddev

fastest_avg=999999999
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

# ── Timing table ───────────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}Timing  (microseconds)${RESET}"
echo -e "  ${BOLD}${SEP92}${RESET}"
printf "  ${BOLD}%-10s %10s %10s %10s %10s %10s %10s %10s${RESET}\n" \
  "LANGUAGE" "AVG" "MIN" "MAX" "MEDIAN" "STDDEV" "RELATIVE" "OPS/SEC"
echo -e "  ${BOLD}${SEP92}${RESET}"

for lang in "${order[@]}"; do
  avg=${stat_avg[$lang]}
  min=${stat_min[$lang]}
  max=${stat_max[$lang]}
  median=${stat_median[$lang]}
  stddev=${stat_stddev[$lang]}
  rel=$(awk "BEGIN { printf \"%.1fx\", $avg / ($fastest_avg == 0 ? 1 : $fastest_avg) }")
  ratio=$(awk "BEGIN { print int($avg / ($fastest_avg == 0 ? 1 : $fastest_avg)) }")
  ops=$(fmt_ops "$avg")

  if (( ratio <= 1 )); then color=$GREEN
  elif (( ratio <= 5 )); then color=$YELLOW
  else color=$RED
  fi

  printf "  %b" "$color"
  printf "%-10s %10s %10s %10s %10s %10s %10s %10s" \
    "$lang" "$(fmt_us $avg)" "$(fmt_us $min)" "$(fmt_us $max)" \
    "$(fmt_us $median)" "$(fmt_us $stddev)" "$rel" "$ops"
  printf "%b\n" "$RESET"
done

echo -e "  ${BOLD}${SEP92}${RESET}"

# ── Resource table ─────────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}Resources  (single run)${RESET}"
echo -e "  ${BOLD}${SEP72}${RESET}"
printf "  ${BOLD}%-10s %12s %10s %12s${RESET}\n" \
  "LANGUAGE" "PEAK MEMORY" "CPU %" "COMPILE"
echo -e "  ${BOLD}${SEP72}${RESET}"

for lang in "${order[@]}"; do
  mem=$(fmt_mem "${mem_kb[$lang]:-0}")
  cpu="${cpu_pct[$lang]:-0}%"
  ct="${compile_us[$lang]:-0}"
  if [[ "$ct" == "0" ]]; then
    compile_fmt="interpreted"
  else
    compile_fmt="$(fmt_us $ct)"
  fi

  ratio=$(awk "BEGIN { print int(${stat_avg[$lang]} / ($fastest_avg == 0 ? 1 : $fastest_avg)) }")
  if (( ratio <= 1 )); then color=$GREEN
  elif (( ratio <= 5 )); then color=$YELLOW
  else color=$RED
  fi

  printf "  %b" "$color"
  printf "%-10s %12s %10s %12s" "$lang" "$mem" "$cpu" "$compile_fmt"
  printf "%b\n" "$RESET"
done

echo -e "  ${BOLD}${SEP72}${RESET}"

# ── Speed bar chart ────────────────────────────────────────────────────────

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
  printf "  %b%-10s%b %b%s%b %s\n" "$color" "$lang" "$RESET" "$color" "$bar" "$RESET" "$(fmt_us $avg)"
done

# ── Memory bar chart ───────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}Memory (relative):${RESET}"
max_mem=0
for lang in "${order[@]}"; do
  kb="${mem_kb[$lang]:-0}"
  (( kb > max_mem )) && max_mem=$kb
done

for lang in "${order[@]}"; do
  kb="${mem_kb[$lang]:-0}"
  bar=$(render_bar "$kb" "$max_mem")
  printf "  ${CYAN}%-10s${RESET} %s %s\n" "$lang" "$bar" "$(fmt_mem $kb)"
done

# ── Individual runs ────────────────────────────────────────────────────────

echo ""
echo -e "  ${BOLD}Individual runs:${RESET}"
for lang in "${order[@]}"; do
  echo -e "  ${CYAN}[$lang]${RESET}"
  echo "${all_times[$lang]}" | tr ' ' '\n' | awk 'BEGIN { c=0 } {
    us = $1
    if (us >= 1000000) { printf "  %8.2fs", us/1000000 }
    else if (us >= 1000) { printf "  %6.1fms", us/1000 }
    else { printf "  %6dus", us }
    c++
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
