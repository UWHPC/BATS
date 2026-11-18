# BATS: Beamforming Across Tensor-core Systems

BATS (Beamforming Across Tensor-core Systems) is a research project for beamforming on distributed NVIDIA tensor cores. Forming beams from channelized sensor samples and complex steering weights takes one matrix multiplication per frequency channel.

## Build and test

Use Linux or WSL2 with CMake 3.25+, `g++-15`, and CUDA 13.4+ with CCCL headers.

```sh
git submodule update --init --recursive
make build   # build (the default task)
make run     # build, then run
make test    # build, then run the tests
make clean   # remove all build output
```

Use `make test BATS_ARCH=native` to target your local GPU. Without `BATS_ARCH`, a fresh build uses CMake's default architecture. Device tests skip when CUDA has no device available. The build goes in `build/cuda/`; run `make help` for the other settings.

## Documentation

`make docs` builds a PDF for every `.tex` file under `docs/` that has a `\documentclass`, into a `build/` folder beside each document. It needs `latexmk` and `biber`.

- [Technical specification](docs/technical-spec/main.tex)
