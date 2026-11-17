#include <catch2/catch_test_macros.hpp>

#include <cuda_runtime.h>

#include <vector>

namespace {

__global__ void add_one(int *data, int n) {
  const int i = static_cast<int>(blockIdx.x * blockDim.x + threadIdx.x);
  if (i < n) {
    data[i] += 1;
  }
}

} // namespace

// Checks that device code compiled for this build's target runs on the GPU.
// Skipped on machines without a GPU (e.g. CI).
TEST_CASE("Kernel runs on device", "[cuda][smoke]") {
  int device_count = 0;
  if (cudaGetDeviceCount(&device_count) != cudaSuccess || device_count == 0) {
    SKIP("No CUDA device available");
  }

  constexpr int n = 1000;
  std::vector<int> host(n, 41);

  int *device = nullptr;
  REQUIRE(cudaMalloc(&device, n * sizeof(int)) == cudaSuccess);
  REQUIRE(cudaMemcpy(device, host.data(), n * sizeof(int),
                     cudaMemcpyHostToDevice) == cudaSuccess);

  add_one<<<(n + 255) / 256, 256>>>(device, n);
  const cudaError_t launch = cudaGetLastError();
  INFO(cudaGetErrorString(launch)
       << " (a 'no kernel image' error means the GPU does not match "
          "CMAKE_CUDA_ARCHITECTURES)");
  CHECK(launch == cudaSuccess);
  CHECK(cudaDeviceSynchronize() == cudaSuccess);

  CHECK(cudaMemcpy(host.data(), device, n * sizeof(int),
                   cudaMemcpyDeviceToHost) == cudaSuccess);
  CHECK(cudaFree(device) == cudaSuccess);

  for (int value : host) {
    REQUIRE(value == 42);
  }
}
