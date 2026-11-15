# BATS: Beamforming Across Tensor-core Systems

Communication-aware distributed beamforming on GPU tensor cores across multiple GPUs and nodes.

## Build and run

From the project root:

```sh
./bats build          # CPU build
./bats run            # CPU build, then run
./bats build --cuda   # CUDA build
./bats run --cuda     # CUDA build, then run
```

The commands use separate `build-cpu/` and `build-cuda/` directories. The CUDA
option selects xpu's CUDA backend; the current Hello World program does not yet
perform GPU work.
