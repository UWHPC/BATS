#include <catch2/catch_test_macros.hpp>

#include <bats/complex_gemm.hpp>

#include <cuda_runtime.h>

#include <cmath>
#include <complex>
#include <random>
#include <vector>

// Helper functions for testing
namespace helpers {

// Calculates on CPU, use as source of truth
std::vector<std::complex<double>> reference_gemm(const std::vector<std::complex<float>> &w,
                                                 const std::vector<std::complex<float>> &x,
                                                 size_t B, size_t S, size_t T) {
  std::vector<std::complex<double>> y(B * T);
  for (size_t t{0}; t < T; ++t) {
    for (size_t b{0}; b < B; ++b) {
      std::complex<double> sum{};
      for (size_t s{0}; s < S; ++s) {
        sum += std::complex<double>{w[b * S + s]} * std::complex<double>{x[t * S + s]};
      }
      y[t * B + b] = sum;
    }
  }
  return y;
}

double relative_error(const std::vector<std::complex<float>> &got, const std::vector<std::complex<double>> &want) {
  double diff{0.0};
  double norm{0.0};
  for (size_t i{0}; i < want.size(); ++i) {
    diff += std::norm(std::complex<double>{got[i]} - want[i]);
    norm += std::norm(want[i]);
  }
  return std::sqrt(diff / norm);
}

std::vector<std::complex<float>> random_complex(size_t count, unsigned seed) {
  std::mt19937 rng{seed};
  std::uniform_real_distribution<float> dist{-1.0f, 1.0f};
  std::vector<std::complex<float>> values(count);
  for (auto &value : values) {
    value = {dist(rng), dist(rng)};
  }
  return values;
}

}
  
TEST_CASE("Hard coded test: one beam, two sensors, one sample", "[complex_gemm]") {
  int count{0};
  if (cudaGetDeviceCount(&count) != cudaSuccess || count == 0) {
    SKIP("No CUDA device available");
  }

  // y = (1+2i)(2+1i) + (3-1i)(1+1i) = (0+5i) + (4+2i) = 4+7i
  // Small integers are exact in TF32, so the result must be exact
  const std::vector<std::complex<float>> w{{1, 2}, {3, -1}};
  const std::vector<std::complex<float>> x{{2, 1}, {1, 1}};
  std::vector<std::complex<float>> y(1);

  bats::complex_gemm(w, x, y, 1, 2, 1);

  CHECK(y[0] == std::complex<float>{4, 7});
}

TEST_CASE("Randomized tests", "[complex_gemm]") {
  int count{0};
  if (cudaGetDeviceCount(&count) != cudaSuccess || count == 0) {
    SKIP("No CUDA device available");
  }

  const size_t B{16}; // beams
  const size_t S{32}; // sensors
  const size_t T{64}; // samples

  for (int i = 0; i < 20; ++i) {
    const auto w = helpers::random_complex(B * S, 67 + i);
    const auto x = helpers::random_complex(T * S, 69 + i);
    std::vector<std::complex<float>> y(B * T);

    bats::complex_gemm(w, x, y, B, S, T);

    const auto y_ref = helpers::reference_gemm(w, x, B, S, T);
    const double rel_err = helpers::relative_error(y, y_ref);

    CHECK(rel_err < 1e-3);
  }
}
