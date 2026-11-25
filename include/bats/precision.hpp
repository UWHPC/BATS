#pragma once

#include <cuda/std/limits>
#include <cuda_fp16.h>

#include <concepts>
#include <cstdint>

namespace bats {

template <class P>
concept precision = requires {
  typename P::storage;
  typename P::accumulator;
  { P::mantissa_bits } -> std::convertible_to<int>;
};

/// Explicit mantissa bits of T, from cuda::std::numeric_limits (whose digits
/// counts the implicit leading bit).
template <class T>
inline constexpr int mantissa_bits_of{cuda::std::numeric_limits<T>::digits - 1};

/// Unit roundoff of a precision's MMA inputs, 2^-(mantissa_bits + 1).
template <precision P>
inline constexpr double unit_roundoff{
    1.0 / static_cast<double>(std::uint64_t{1} << (P::mantissa_bits + 1))};

/// FP32 in memory; tensor cores read the inputs as TF32 and accumulate in FP32.
struct tf32 {
  using storage = float;
  using accumulator = float;
  /// At least 10 per cuda_tf32.h (more is hardware dependent); no
  /// numeric_limits exists for TF32.
  static constexpr int mantissa_bits{10};
};

/// IEEE binary16 in memory, FP32 accumulation.
struct fp16 {
  using storage = __half;
  using accumulator = float;
  static constexpr int mantissa_bits{mantissa_bits_of<storage>};
};

} // namespace bats
