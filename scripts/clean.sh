#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"

echo "[clean] remove build directory contents"
rm -rf "$BUILD_DIR"

echo "[clean] remove common root-level outputs if they exist"
rm -f \
  "$ROOT_DIR/a.out" \
  "$ROOT_DIR/hello.asm" \
  "$ROOT_DIR/hello.o" \
  "$ROOT_DIR/hello" \
  "$ROOT_DIR/out.asm" \
  "$ROOT_DIR/out.o" \
  "$ROOT_DIR/out"

echo "[done] clean complete"