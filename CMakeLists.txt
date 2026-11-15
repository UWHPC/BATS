cmake_minimum_required(VERSION 3.25)

option(BATS_ENABLE_CUDA "Build with CUDA" ON)

if(BATS_ENABLE_CUDA)
  find_program(BATS_GXX15 NAMES g++-15 REQUIRED)
  if(NOT DEFINED CMAKE_CXX_COMPILER)
    set(CMAKE_CXX_COMPILER "${BATS_GXX15}" CACHE FILEPATH "C++ compiler")
  endif()
  if(NOT DEFINED CMAKE_CUDA_HOST_COMPILER)
    set(CMAKE_CUDA_HOST_COMPILER "${BATS_GXX15}" CACHE FILEPATH "CUDA host compiler")
  endif()
  if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES native)
  endif()
  project(BATS LANGUAGES CXX CUDA)
else()
  project(BATS LANGUAGES CXX)
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 23)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

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
