#pragma once

#include <cuda_runtime_api.h>

#include <cstdint>
#include <format>
#include <string>
#include <string_view>
#include <utility>

namespace bats {

enum class errc : std::uint8_t {
  no_device,        ///< No usable CUDA device.
  unsupported_arch, ///< No compiled kernel runs on the device.
  bad_shape,        ///< Extents mismatch, are zero, or are too large.
  bad_layout,       ///< An operand's strides do not match its layout.
  misaligned,       ///< A pointer, stride, or extent is misaligned.
  rejected,         ///< CUTLASS refused the problem.
  cuda,             ///< A CUDA call failed.
};

struct error {
  errc code;
  /// CUDA result for errc::cuda.
  cudaError_t cuda{cudaSuccess};
  /// Failing call, e.g. "cudaMemcpyAsync".
  std::string_view where{};

  friend constexpr auto operator==(const error &, const error &)
      -> bool = default;
};

/// Error for a failed CUDA call.
[[nodiscard]] constexpr auto cuda_error(cudaError_t result,
                                        std::string_view where) noexcept
    -> error {
  return error{.code = errc::cuda, .cuda = result, .where = where};
}

[[nodiscard]] constexpr auto to_string(errc code) noexcept -> std::string_view {
  switch (code) {
  case errc::no_device:
    return "no CUDA device";
  case errc::unsupported_arch:
    return "no kernel for this GPU";
  case errc::bad_shape:
    return "bad shape";
  case errc::bad_layout:
    return "bad layout";
  case errc::misaligned:
    return "misaligned operand";
  case errc::rejected:
    return "problem rejected by the kernel library";
  case errc::cuda:
    return "CUDA call failed";
  }
  std::unreachable();
}

[[nodiscard]] inline auto to_string(const error &e) -> std::string {
  auto message{e.code == errc::cuda
                   ? std::format("{} ({}: {})", to_string(e.code),
                                 cudaGetErrorName(e.cuda),
                                 cudaGetErrorString(e.cuda))
                   : std::string{to_string(e.code)}};
  return e.where.empty() ? message : std::format("{}: {}", e.where, message);
}

} // namespace bats
