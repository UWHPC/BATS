#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ./bats {build|run} [--cuda]" >&2
  exit 2
}

action=${1:-}
case "$action" in
  build|run) shift ;;
  *) usage ;;
esac

cuda=OFF
if [[ ${1:-} == --cuda ]]; then
  cuda=ON
  shift
fi
[[ $# -eq 0 ]] || usage

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ $cuda == ON ]]; then
  build_dir="$root/build-cuda"
else
  build_dir="$root/build-cpu"
fi

cmake -S "$root" -B "$build_dir" \
  -DBATS_ENABLE_CUDA="$cuda" \
  -DCMAKE_CXX_COMPILER=g++-15
cmake --build "$build_dir" --parallel

if [[ $action == run ]]; then
  "$build_dir/bats"
fi
