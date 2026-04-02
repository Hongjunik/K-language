#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
INPUT_K="$BUILD_DIR/baseline_sample.k"
GENERATED_ASM="$BUILD_DIR/out.asm"
GENERATED_BIN="$BUILD_DIR/out"
PROGRAM_OUTPUT="$BUILD_DIR/program_output.txt"

mkdir -p "$BUILD_DIR"

cat > "$INPUT_K" <<'EOF'
변수 x = 7;
출력 x;

만약 (3 > 1) 이면 { 출력 100; }

변수 a = 0;
반복 (a < 3) 동안 { 출력 a; 변수 a = a + 1; }

반복 (변수 i = 0; i < 3; 변수 i = i + 1) { 출력 i; }
EOF

echo "[1/4] run kompiler -> generated assembly"
"$ROOT_DIR/kompiler" -S "$INPUT_K" -o "$GENERATED_ASM"

echo "[2/4] run kompiler -> executable"
"$ROOT_DIR/kompiler" "$INPUT_K" -o "$GENERATED_BIN"

echo "[3/4] run generated program"
"$GENERATED_BIN" > "$PROGRAM_OUTPUT"

echo "[4/4] show program output"
echo
echo "=== program output ==="
cat "$PROGRAM_OUTPUT"