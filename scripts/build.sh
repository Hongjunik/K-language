#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT_DIR/src/K_lang_v02_5.asm"
BUILD_DIR="$ROOT_DIR/build"

COMPILER_O="$BUILD_DIR/K_lang_v02_5.o"
COMPILER_BIN="$BUILD_DIR/kc"

GENERATED_ASM="$BUILD_DIR/out.asm"
GENERATED_O="$BUILD_DIR/out.o"
GENERATED_BIN="$BUILD_DIR/out"

PROGRAM_OUTPUT="$BUILD_DIR/program_output.txt"
DEBUG_LOG="$BUILD_DIR/debug.log"

mkdir -p "$BUILD_DIR"

echo "[1/6] assemble compiler"
nasm -f elf64 "$SRC" -o "$COMPILER_O"

echo "[2/6] link compiler"
ld -o "$COMPILER_BIN" "$COMPILER_O"

echo "[3/6] run compiler -> generated assembly"
"$COMPILER_BIN" > "$GENERATED_ASM" 2> "$DEBUG_LOG"

echo "[4/6] assemble generated assembly"
nasm -f elf64 "$GENERATED_ASM" -o "$GENERATED_O"

echo "[5/6] link generated program"
ld -o "$GENERATED_BIN" "$GENERATED_O"

echo "[6/6] run generated program"
"$GENERATED_BIN" > "$PROGRAM_OUTPUT"

echo
echo "=== program output ==="
cat "$PROGRAM_OUTPUT"