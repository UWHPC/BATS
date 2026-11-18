# BATS: Beamforming Across Tensor-core Systems

Communication-aware distributed beamforming on GPU tensor cores across multiple GPUs and nodes.

## Build and run

From the project root:

```sh
make build   # build (the default task)
make run     # build, then run
make test    # build, then run the tests
make docs    # build the LaTeX docs (PDFs go in a build/ folder beside each)
make clean   # remove all build output
```

BATS is CUDA-only and requires CUDA 13.4 or later and g++-15. Builds target
Hopper (`sm_90a`) by default. To build and test on another GPU, pass its
architecture, e.g. `make test BATS_ARCH=89` for an RTX 40 series card, or
`BATS_ARCH=native` to detect the local GPU. Hopper-only kernels will not run on
other architectures.

The build goes in `build/cuda/`. Run `make help` for the other settings
(`BATS_TARGET`, `BUILD_TYPE`, `CXX_COMPILER`, `CMAKE_ARGS`). The current
Hello World program does not yet perform GPU work.

Tests use Catch2 and run through CTest. Add test sources to
`tests/CMakeLists.txt`; tests that need a GPU skip themselves on machines
without one. Pass `CMAKE_ARGS=-DBATS_BUILD_TESTS=OFF` to skip building the
tests.

`make docs` builds every `.tex` file under `docs/` that has a `\documentclass`
and needs `latexmk` and `biber`.
