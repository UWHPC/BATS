# BATS: Beamforming Across Tensor-core Systems

BATS (Beamforming Across Tensor-core Systems) is a research project for beamforming on distributed NVIDIA tensor cores. Forming beams from channelized sensor samples and complex steering weights takes one matrix multiplication per frequency channel.

## Build and test

Use Linux or WSL2 with CMake 3.25+, `g++-15`, and CUDA 13.4+ with CCCL headers.

```sh
git submodule update --init --recursive
./bats build
./bats run
./bats test
```

Use `./bats test --arch native` to target your local GPU. Without `--arch`, a fresh build uses CMake's default architecture. Device tests skip when CUDA has no device available.

## Documentation

- [Technical specification](docs/technical-spec/main.tex)
