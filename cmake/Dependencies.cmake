include_guard(GLOBAL)

find_package(CUDAToolkit 13.4 REQUIRED)

find_path(BATS_CCCL_INCLUDE_DIR cuda/std/mdspan
  HINTS ${CUDAToolkit_INCLUDE_DIRS}
  PATH_SUFFIXES cccl
  REQUIRED
)
add_library(bats_cccl INTERFACE)
add_library(bats::cccl ALIAS bats_cccl)
target_include_directories(bats_cccl SYSTEM INTERFACE "${BATS_CCCL_INCLUDE_DIR}")

include(FetchContent)
set(XPU_ENABLE_CUDA ON CACHE BOOL "BATS uses the XPU CUDA backend" FORCE)
set(XPU_BUILD_TESTS OFF CACHE BOOL "Build XPU tests separately" FORCE)
set(XPU_ENABLE_LINALG OFF CACHE BOOL "BATS uses CUTLASS and separate cuBLAS references" FORCE)
set(XPU_ARCH_NATIVE OFF CACHE BOOL "Tune XPU for this build host")
FetchContent_Declare(
  xpu
  GIT_REPOSITORY https://github.com/UWHPC/xpu.git
  GIT_TAG 81a3a7b756e6decc0e2068eaf6c8fc23852fa682
)
FetchContent_MakeAvailable(xpu)

set(BATS_CUTLASS_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../third_party/cutlass")
if(NOT EXISTS "${BATS_CUTLASS_SOURCE_DIR}/include/cutlass/cutlass.h")
  message(FATAL_ERROR
    "CUTLASS is missing. Run: git submodule update --init --recursive")
endif()
add_library(bats_cutlass INTERFACE)
add_library(bats::cutlass ALIAS bats_cutlass)
target_include_directories(bats_cutlass SYSTEM INTERFACE
  "${BATS_CUTLASS_SOURCE_DIR}/include"
)
target_link_libraries(bats_cutlass INTERFACE bats::cccl CUDA::cudart)

if(BATS_BUILD_TESTS)
  FetchContent_Declare(
    Catch2
    URL https://github.com/catchorg/Catch2/archive/refs/tags/v3.16.1.tar.gz
    URL_HASH SHA256=d16bd1b8b2364918bd472cb216394acb93bde6784890df0d91bccfb3f28d777d
  )
  set(CATCH_INSTALL_DOCS OFF CACHE BOOL "" FORCE)
  set(CATCH_INSTALL_EXTRAS OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(Catch2)
endif()
