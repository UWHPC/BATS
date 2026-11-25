# Build tasks for BATS.
#
#   make build    configure and build the library, tests and demos
#   make run      build, then run the main entrypoint
#   make test     build, then run the tests
#   make docs     build a PDF next to every LaTeX document under docs/, with
#                 temporary files in a build/ folder beside each document
#   make docs/<path>  build one document, named by its path without .tex
#                 (e.g. docs/technical-spec/main), or every document under a
#                 folder (e.g. docs/one-pager)
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
.PHONY: build run test docs clean

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

# Discover valid LaTeX documents by finding '\documentclass' specification in the file.
DOC_SRCS := $(shell grep -rl --include='*.tex' '^[[:space:]]*\\documentclass' $(DOCS_DIR) | sort)

DOC_AUX := build

LATEXMK_FLAGS := -pdf -cd -outdir=. -auxdir=$(DOC_AUX) -interaction=nonstopmode -halt-on-error

DOC_TARGETS := $(DOC_SRCS:.tex=)
DOC_PDFS := $(addsuffix .pdf,$(DOC_TARGETS))

DOC_DIRS := $(foreach d,$(shell find $(DOCS_DIR) -mindepth 1 -name $(DOC_AUX) -prune -o -type d -print),$(if $(filter $d/%,$(DOC_TARGETS)),$d))
DOC_DIR_TARGETS := $(DOC_DIRS) $(addsuffix /,$(DOC_DIRS))

DOC_DEPS := $(filter-out $(DOC_PDFS),$(shell find $(DOCS_DIR) -name $(DOC_AUX) -prune -o -type f -print))

.PHONY: $(DOC_TARGETS) $(DOC_DIR_TARGETS)
.DELETE_ON_ERROR:

docs: $(DOC_PDFS)

$(DOC_TARGETS): %: %.pdf

$(foreach d,$(DOC_DIRS),$(eval $d $d/: $(filter $d/%,$(DOC_PDFS))))

# Build PDF with latexmk, then touch to make file current.
$(DOCS_DIR)/%.pdf: $(DOCS_DIR)/%.tex $(DOC_DEPS)
	epoch=$${SOURCE_DATE_EPOCH:-$$(git log -1 --format=%ct -- $(@D) 2>/dev/null)}; \
	SOURCE_DATE_EPOCH=$${epoch:-$$(date +%s)} FORCE_SOURCE_DATE=1 \
	  $(LATEXMK) $(LATEXMK_FLAGS) $<
	touch $@

clean:
	rm -rf build
	find $(DOCS_DIR) -type d -name $(DOC_AUX) -prune -exec rm -rf {} +
