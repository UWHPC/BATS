#pragma once

/*
  Proof of concept for issue #6: complex matrix multiply on tensor cores
*/

#include <complex>
#include <cstddef>
#include <span>

namespace bats {

/*
  Computes Y = W * X for one channel on the GPU's tensor cores.

  Memory layout of the host arrays:
    w: Weight of sensor s for beam b is
        w[b * sensors + s] (sensors of one beam are contiguous)
    x: Sensor s at time sample t is
        x[t * sensors + s] (sensors of one sample are contiguous)
    y: Beam b at time sample t is
        y[t * beams + b] (beams of one sample are contiguous).

  Precision: the inputs are rounded to TF32 (10-bit mantissa) before the
  multiply and accumulated in FP32, so expect a relative error of roughly
  1e-3, not FP32 accuracy. Small integers are exact.
*/
void complex_gemm(std::span<const std::complex<float>> w,
                  std::span<const std::complex<float>> x,
                  std::span<std::complex<float>> y, 
                  std::size_t beams,
                  std::size_t sensors, 
                  std::size_t samples);

}
