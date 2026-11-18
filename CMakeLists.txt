cmake_minimum_required(VERSION 3.25)

option(BATS_BUILD_TESTS "Build the BATS tests" ON)

find_program(BATS_GXX15 NAMES g++-15 REQUIRED)
if(NOT DEFINED CMAKE_CXX_COMPILER)
  set(CMAKE_CXX_COMPILER "${BATS_GXX15}" CACHE FILEPATH "C++ compiler")
endif()
if(NOT DEFINED CMAKE_CUDA_HOST_COMPILER)
  set(CMAKE_CUDA_HOST_COMPILER "${BATS_GXX15}" CACHE FILEPATH "CUDA host compiler")
endif()

project(BATS LANGUAGES CXX CUDA)

if(CMAKE_CUDA_COMPILER_VERSION VERSION_LESS 13.4)
  message(FATAL_ERROR "BATS requires CUDA 13.4 or later (found ${CMAKE_CUDA_COMPILER_VERSION})")
endif()

if(CMAKE_CUDA_COMPILER_ID STREQUAL "NVIDIA"
   AND NOT DEFINED CMAKE_CUDA23_STANDARD_COMPILE_OPTION)
  set(CMAKE_CUDA23_STANDARD_COMPILE_OPTION "-std=c++23")
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CUDA_STANDARD 23)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

include(cmake/Dependencies.cmake)

add_executable(bats src/main.cpp)
target_include_directories(bats PRIVATE include)
target_link_libraries(bats PRIVATE xpu::xpu bats::cutlass bats::cccl)

if(BATS_BUILD_TESTS)
  enable_testing()
  add_subdirectory(tests)
endif()
