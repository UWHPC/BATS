#include <catch2/catch_test_macros.hpp>

#include <cuda_runtime.h>
#include <xpu/buffer.hpp>

#include <algorithm>
#include <array>
#include <ranges>

namespace {

__global__ auto write_sequence(xpu::buffer_view<unsigned int> values) -> void {
  const auto index{blockIdx.x * blockDim.x + threadIdx.x};
  if (index < values.count()) {
    values[index] = index + 1u;
  }
}

}

TEST_CASE("Kernel runs on device", "[cuda][smoke]") {
  auto device_count{0};
  const auto device_status{cudaGetDeviceCount(&device_count)};
  if (device_status == cudaErrorNoDevice ||
      device_status == cudaErrorInsufficientDriver) {
    SKIP("No CUDA device available");
  }
  REQUIRE(device_status == cudaSuccess);
  if (device_count == 0) {
    SKIP("No CUDA device available");
  }

  constexpr auto count{1000u};
  constexpr auto threads_per_block{256u};
  constexpr auto block_count{(count + threads_per_block - 1u) /
                             threads_per_block};
  auto device{xpu::buffer<unsigned int>{count}};
  std::array<unsigned int, count> host{};

  write_sequence<<<block_count, threads_per_block>>>(device.view());
  REQUIRE(cudaGetLastError() == cudaSuccess);
  REQUIRE(cudaMemcpy(host.data(), device.data(), count * sizeof(unsigned int),
                     cudaMemcpyDeviceToHost) == cudaSuccess);

  REQUIRE(std::ranges::equal(host, std::views::iota(1u, count + 1u)));
}
