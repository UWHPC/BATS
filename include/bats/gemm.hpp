#pragma once

#include <bats/error.hpp>
#include <bats/hw/arch.hpp>
#include <bats/precision.hpp>

#include <cuda/std/array>
#include <cuda/std/mdspan>
#include <cuda_runtime_api.h>

#include <cstdint>
#include <expected>
#include <string_view>

namespace bats {

using extent_t = std::int64_t;
using batch_extents = cuda::std::dextents<extent_t, 3>;
using batch_mapping = cuda::std::layout_stride::mapping<batch_extents>;

/// A batch of matrices indexed (batch, row, column). Index with
/// view(l, i, j).
template <class T>
using matrix_batch =
    cuda::std::mdspan<T, batch_extents, cuda::std::layout_stride>;

enum class storage_order : std::uint8_t { row_major, column_major };

/// Layout of `batch` matrices of `rows` x `cols`, stored back to back in
/// `order`. The leading dimension is rounded up to a multiple of `alignment`
/// elements, which also makes the batch stride a multiple of it.
[[nodiscard]] constexpr auto padded_layout(extent_t batch, extent_t rows,
                                           extent_t cols, storage_order order,
                                           extent_t alignment)
    -> batch_mapping {
  const auto round_up{[alignment](extent_t n) {
    return (n + alignment - 1) / alignment * alignment;
  }};
  const auto row_major{order == storage_order::row_major};
  const auto leading{round_up(row_major ? cols : rows)};
  const auto batch_stride{leading * (row_major ? rows : cols)};
  const auto strides{
      row_major ? cuda::std::array<extent_t, 3>{batch_stride, leading, 1}
                : cuda::std::array<extent_t, 3>{batch_stride, 1, leading}};
  return batch_mapping{batch_extents{batch, rows, cols}, strides};
}

/// D[l] = A[l] * B[l] for every l in the batch, on tensor cores at precision
/// P, asynchronously on `stream` on the current device.
///
///   a: [batch, M, K], row-major    (K contiguous)
///   b: [batch, K, N], column-major (K contiguous)
///   d: [batch, M, N], column-major (M contiguous)
///
/// Each operand's pointer, leading dimension, batch stride, and contiguous
/// extent must be a multiple of gemm_alignment<P>() elements. padded_layout
/// aligns the leading dimension and batch stride; the caller must pad the
/// contiguous extent.
template <precision P>
[[nodiscard]] auto gemm(matrix_batch<const typename P::storage> a,
                        matrix_batch<const typename P::storage> b,
                        matrix_batch<typename P::storage> d,
                        cudaStream_t stream = nullptr)
    -> std::expected<void, error>;

/// Alignment, in elements, that gemm<P> requires on `device`, or on the
/// current device if none is given. It comes from the kernel chosen for that
/// device.
template <precision P>
[[nodiscard]] auto gemm_alignment() -> std::expected<extent_t, error>;
template <precision P>
[[nodiscard]] auto gemm_alignment(hw::device_id device)
    -> std::expected<extent_t, error>;

/// Name of the architecture recipe gemm<P> would use on `device`, or on the
/// current device if none is given.
template <precision P>
[[nodiscard]] auto gemm_arch_name() -> std::expected<std::string_view, error>;
template <precision P>
[[nodiscard]] auto gemm_arch_name(hw::device_id device)
    -> std::expected<std::string_view, error>;

} // namespace bats
