#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
INPUT_K="$BUILD_DIR/sample_run.k"
OUTPUT_BIN="$BUILD_DIR/sample_run"

mkdir -p "$BUILD_DIR"

cat > "$INPUT_K" <<'EOF2'
변수 x = 7;
출력 x;

만약 (3 > 1) 이면 { 출력 100; }

변수 a = 0;
반복 (a < 3) 동안 { 출력 a; 변수 a = a + 1; }

반복 (변수 i = 0; i < 3; 변수 i = i + 1) { 출력 i; }
EOF2

echo "[1/2] build sample executable with kompiler"
"$ROOT_DIR/kompiler" "$INPUT_K" -o "$OUTPUT_BIN"

echo "[2/2] run sample executable"
"$OUTPUT_BIN"