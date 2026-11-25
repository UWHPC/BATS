#pragma once

#include <concepts>
#include <string_view>

namespace bats::hw {

/// Compute capability as major * 10 + minor (e.g. 8.6 -> 86).
using compute_capability = int;

/// A CUDA device ordinal, as passed to cudaSetDevice.
struct device_id {
  constexpr explicit device_id(int value) noexcept : ordinal{value} {}
  int ordinal;
  friend constexpr auto operator==(device_id, device_id) -> bool = default;
};

template <class A>
concept arch = requires {
  { A::name } -> std::convertible_to<std::string_view>;
  { A::min_compute_capability } -> std::convertible_to<compute_capability>;
  { A::max_compute_capability } -> std::convertible_to<compute_capability>;
};

/// Ampere (RTX 30 series, A100); development only.
struct sm80 {
  static constexpr std::string_view name{"sm80"};
  static constexpr compute_capability min_compute_capability{80};
  static constexpr compute_capability max_compute_capability{89};
};

/// Ada (RTX 40 series, L40); development only. sm80 also runs here, so use
/// this one only for Ada-only instructions such as FP8 mma.sync.
struct sm89 {
  static constexpr std::string_view name{"sm89"};
  static constexpr compute_capability min_compute_capability{89};
  static constexpr compute_capability max_compute_capability{89};
};

/// Hopper (H100, H200); the target architecture.
struct sm90a {
  static constexpr std::string_view name{"sm90a"};
  static constexpr compute_capability min_compute_capability{90};
  static constexpr compute_capability max_compute_capability{90};
};

/// Consumer Blackwell (RTX 50 series); development only.
struct sm120 {
  static constexpr std::string_view name{"sm120"};
  static constexpr compute_capability min_compute_capability{120};
  static constexpr compute_capability max_compute_capability{129};
};

template <arch A>
[[nodiscard]] constexpr auto runs_on(compute_capability device) noexcept
    -> bool {
  return A::min_compute_capability <= device &&
         device <= A::max_compute_capability;
}

} // namespace bats::hw
