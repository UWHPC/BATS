#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ./bats {build|run|test} [--arch <sm>]" >&2
  echo "  --arch <sm>  CUDA architecture to build for (default 90a, e.g. 89 or native)" >&2
  exit 2
}

action=${1:-}
case "$action" in
  build|run|test) shift ;;
  *) usage ;;
esac

arch=90a
while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) [[ $# -ge 2 ]] || usage; arch=$2; shift 2 ;;
    *) usage ;;
  esac
done

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir="$root/build"

# nvcc is often installed without being on PATH.
if [[ -z ${CUDACXX:-} ]] && ! command -v nvcc >/dev/null && [[ -x /usr/local/cuda/bin/nvcc ]]; then
  export CUDACXX=/usr/local/cuda/bin/nvcc
fi

cmake -S "$root" -B "$build_dir" \
  -DCMAKE_CXX_COMPILER=g++-15 \
  -DCMAKE_CUDA_ARCHITECTURES="$arch"
cmake --build "$build_dir" --parallel

case "$action" in
  run) "$build_dir/bats" ;;
  test) ctest --test-dir "$build_dir" --output-on-failure ;;
esac
