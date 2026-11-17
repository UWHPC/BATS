# BATS: Beamforming Across Tensor-core Systems

Communication-aware distributed beamforming on GPU tensor cores across multiple GPUs and nodes.

## Build and run

From the project root:

```sh
./bats build   # build
./bats run     # build, then run
./bats test    # build, then run the tests
```

BATS is CUDA-only and requires CUDA 13.4 or later and g++-15. Builds target
Hopper (`sm_90a`) by default. To build and test on another GPU, pass its
architecture, e.g. `./bats test --arch 89` for an RTX 40 series card, or
`--arch native` to detect the local GPU. Hopper-only kernels will not run on
other architectures.

The build goes in `build/`. The current Hello World program does not yet
perform GPU work.

Tests use Catch2 and run through CTest. Add test sources to
`tests/CMakeLists.txt`; tests that need a GPU skip themselves on machines
without one. Configure with `-DBATS_BUILD_TESTS=OFF` to skip building the
tests.
