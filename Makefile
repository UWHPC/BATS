# Build tasks for BATS.
#
#   make build    configure and build the library, tests and demos
#   make run      build, then run the main entrypoint
#   make test     build, then run the tests
#   make docs     build a PDF for every LaTeX document under docs/, into a
#                 build/ folder beside each document
#   make clean    remove all build output
#
# Settings, passed on the command line or as env vars:
#   BATS_TARGET   backend to build for (default CUDA; CPU is not supported)
#   BATS_ARCH     CUDA architecture, e.g. 89 or native (default: CMake's)
#   BUILD_TYPE    CMake build type (default Release)
#   CXX_COMPILER  host C++ compiler (default g++-15)
#   CMAKE_ARGS    extra arguments passed to the CMake configure step

BATS_TARGET  ?= CUDA
BATS_ARCH    ?=
BUILD_TYPE   ?= Release
# Not CXX: GNU Make predefines CXX as g++, so `?=` would never apply.
CXX_COMPILER ?= g++-15
CMAKE_ARGS   ?=
LATEXMK      ?= latexmk

# The target is checked when building rather than here, so tasks that do not
# build (docs, clean) still work with any BATS_TARGET set.
ifeq ($(BATS_TARGET),CUDA)
  # Unset leaves the architecture to CMake (or the build tree's cached value).
  CMAKE_TARGET_ARGS := $(if $(BATS_ARCH),-DCMAKE_CUDA_ARCHITECTURES=$(BATS_ARCH))
else ifeq ($(BATS_TARGET),CPU)
  TARGET_ERROR := BATS_TARGET=CPU is not supported yet: BATS is CUDA-only for now
else
  TARGET_ERROR := Unknown BATS_TARGET '$(BATS_TARGET)': expected CUDA
endif

BUILD_DIR := build/$(shell echo '$(BATS_TARGET)' | tr A-Z a-z)
DOCS_DIR  := docs

# nvcc is often installed without being on PATH.
ifeq ($(origin CUDACXX),undefined)
  ifeq ($(shell command -v nvcc),)
    ifneq ($(wildcard /usr/local/cuda/bin/nvcc),)
      export CUDACXX := /usr/local/cuda/bin/nvcc
    endif
  endif
endif

.DEFAULT_GOAL := build
.PHONY: build run test docs clean help

help:
	@sed -n '2,15s/^# \{0,1\}//p' $(firstword $(MAKEFILE_LIST))

# Configure runs every time so that changed settings (e.g. BATS_ARCH) take
# effect; it is a fast no-op when nothing has changed.
build:
	$(if $(TARGET_ERROR),$(error $(TARGET_ERROR)))
	cmake -S . -B $(BUILD_DIR) \
	  -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
	  -DCMAKE_CXX_COMPILER=$(CXX_COMPILER) \
	  $(CMAKE_TARGET_ARGS) $(CMAKE_ARGS)
	cmake --build $(BUILD_DIR) --parallel

run: build
	./$(BUILD_DIR)/bats

test: build
	ctest --test-dir $(BUILD_DIR) --output-on-failure --no-tests=error

# Any .tex file with a \documentclass is a document; \input'd sections are
# not. Paths are relative to docs/.
DOC_SRCS := $(shell cd $(DOCS_DIR) && grep -rl --include='*.tex' '^[[:space:]]*\\documentclass' . | sed 's|^\./||' | sort)

# latexmk runs from docs/ so it reads docs/.latexmkrc, which sets the output
# directory, and it tracks each document's inputs and skips unchanged ones.
# -cd runs each document from its own directory so relative paths such as
# \input{sections/...} resolve; the .latexmkrc output directory is relative,
# so docs/a/b.tex builds to docs/a/build/b.pdf.
docs:
	cd $(DOCS_DIR) && $(LATEXMK) -pdf -cd -interaction=nonstopmode -halt-on-error \
	  $(DOC_SRCS)

clean:
	rm -rf build
	find $(DOCS_DIR) -type d -name build -prune -exec rm -rf {} +
