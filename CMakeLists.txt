cmake_minimum_required(VERSION 3.25)

project(BATS LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 23)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

option(BATS_ENABLE_CUDA "Build with CUDA when a CUDA compiler is available" ON)
set(XPU_ENABLE_CUDA ${BATS_ENABLE_CUDA} CACHE BOOL "Enable xpu's CUDA backend" FORCE)

include(FetchContent)
FetchContent_Declare(
  xpu
  GIT_REPOSITORY https://github.com/UWHPC/xpu.git
  GIT_TAG 81a3a7b756e6decc0e2068eaf6c8fc23852fa682
)
FetchContent_MakeAvailable(xpu)

add_executable(bats src/main.cpp)
target_link_libraries(bats PRIVATE xpu::xpu)
