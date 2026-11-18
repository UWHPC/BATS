#pragma once

#include <bats/beamforming_shape.hpp>

#include <cuda/std/array>
#include <cuda/std/mdspan>

#include <cstddef>

#include <xpu/buffer.hpp>

#if defined(__CUDACC__)
  #define BATS_HOST_DEVICE __host__ __device__
#else
  #define BATS_HOST_DEVICE
#endif

namespace bats {

  using extents3 = cuda::std::dextents<std::size_t, 3>;
  using mapping3 = cuda::std::layout_stride::mapping<extents3>;

  template <typename Element>
  using view3 = cuda::std::mdspan<Element, extents3, cuda::std::layout_stride>;

  struct sample_layout {
    mapping3 mapping;
    std::size_t storage_elements;
  };

  inline auto make_sample_layout(beamform_shape shape) -> sample_layout {
    constexpr std::size_t alignment_elements{16uz / sizeof(float)};
    const auto components{2 * shape.sensors};
    const auto leading_dim{((components + alignment_elements -1) / alignment_elements) * alignment_elements};
    const auto channel_stride{shape.samples * leading_dim};

    return {
      mapping3{
        extents3{shape.channels, components, shape.samples},
        cuda::std::array<std::size_t, 3>{channel_stride, 1, leading_dim},
      },
      shape.channels * channel_stride
    };
  }

} // namespace bats
