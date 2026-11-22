/*
  Implement complex_gemm() w/ tensor cores
  See PR for details
*/

#include <bats/complex_gemm.hpp>
#include <mma.h>

#include <stdexcept>
#include <vector>

namespace bats {
namespace {

/* Shape of one tensor-core multiply for TF32 inputs: 
  (16 x 8) tile of Ws
  (8 x 16) tile of Xs 
  (16 x 16) tile of Ys
*/
constexpr size_t tile_m{16};
constexpr size_t tile_n{16};
constexpr size_t tile_k{8};

constexpr size_t round_up(size_t value, size_t step) {
  return (value + step - 1) / step * step;
}

/*
  Real matrix product Ys = Ws * Xs on tensor cores
  All dimensions are already padded to whole tiles, so no bounds checks are needed
  The zero padding adds nothing to the sums
*/
__global__ void real_gemm_tf32(const float *ws, const float *xs, float *ys,
                               size_t m_pad, size_t n_pad, size_t k_pad) {
  using namespace nvcuda;

  // Top-left corner of the output tile this warp computes
  const size_t row{blockIdx.x * tile_m};
  const size_t col{blockIdx.y * tile_n};

  // Fragments are the tiles held in registers
  wmma::fragment<wmma::matrix_a, tile_m, tile_n, tile_k, wmma::precision::tf32, wmma::row_major> w_tile;
  wmma::fragment<wmma::matrix_b, tile_m, tile_n, tile_k, wmma::precision::tf32, wmma::col_major> x_tile;
  wmma::fragment<wmma::accumulator, tile_m, tile_n, tile_k, float> y_tile;
  wmma::fill_fragment(y_tile, 0.0f);

  // Walk along K, multiplying one 16x8 tile of Ws by one 8x16 tile of Xs at a
  // time and accumulating into the output tile
  for (size_t k{0}; k < k_pad; k += tile_k) {
    wmma::load_matrix_sync(w_tile, ws + row * k_pad + k, k_pad);
    wmma::load_matrix_sync(x_tile, xs + col * k_pad + k, k_pad);
    wmma::mma_sync(y_tile, w_tile, x_tile, y_tile);
  }

  wmma::store_matrix_sync(ys + col * m_pad + row, y_tile, m_pad, wmma::mem_col_major);
}

}

// Actual complex GEMM
void complex_gemm(std::span<const std::complex<float>> w,
                  std::span<const std::complex<float>> x,
                  std::span<std::complex<float>> y,
                  size_t beams, size_t sensors, size_t samples) {

  // Size check
  if (w.size() != beams * sensors || x.size() != sensors * samples || y.size() != beams * samples) {
    throw std::invalid_argument{"complex_gemm: span sizes do not match beams, sensors and samples"};
  }

  const size_t B{beams};
  const size_t S{sensors};
  const size_t T{samples};

  // Pad up to whole tiles
  const size_t m_pad{round_up(2 * B, tile_m)};
  const size_t n_pad{round_up(T, tile_n)};
  const size_t k_pad{round_up(2 * S, tile_k)};

  /*
    Step 1 (CPU): pack the complex inputs into real block matrices (still 1D)
    See PR
  */

  // Ws = [Wr -Wi], m_pad x k_pad (row major)
  //      [Wi  Wr]
  std::vector<float> ws(m_pad * k_pad, 0.0f);
  for (size_t b{0}; b < B; ++b) {
    for (size_t s{0}; s < S; ++s) {
      const std::complex<float> weight{w[b * S + s]};
      ws[b * k_pad + s] = weight.real();            // top left: Wr
      ws[b * k_pad + S + s] = -weight.imag();       // top right: -Wi
      ws[(B + b) * k_pad + s] = weight.imag();      // bottom left: Wi
      ws[(B + b) * k_pad + S + s] = weight.real();  // bottom right:  Wr
    }
  }

  // Xs = [Xr], k_pad x n_pad (col major)
  //      [Xi]
  std::vector<float> xs(k_pad * n_pad, 0.0f);
  for (size_t t{0}; t < T; ++t) {
    for (size_t s{0}; s < S; ++s) {
      const std::complex<float> sample{x[t * S + s]};
      xs[t * k_pad + s] = sample.real();            // top half: Xr
      xs[t * k_pad + S + s] = sample.imag();        // bottom half: Xi  
    }
  }

  // Step 2 (GPU): Ys = Ws * Xs
  std::vector<float> ys(m_pad * n_pad);
  float *ws_device{nullptr};
  float *xs_device{nullptr};
  float *ys_device{nullptr};
  cudaMalloc(&ws_device, ws.size() * sizeof(float));
  cudaMalloc(&xs_device, xs.size() * sizeof(float));
  cudaMalloc(&ys_device, ys.size() * sizeof(float));

  cudaMemcpy(ws_device, ws.data(), ws.size() * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(xs_device, xs.data(), xs.size() * sizeof(float), cudaMemcpyHostToDevice);

  // One block of 32 threads (one warp) per 16x16 tile of Ys
  const dim3 grid{static_cast<unsigned>(m_pad / tile_m), static_cast<unsigned>(n_pad / tile_n)};
  const dim3 block{32};
  real_gemm_tf32<<<grid, block>>>(ws_device, xs_device, ys_device, m_pad, n_pad, k_pad);

  cudaMemcpy(ys.data(), ys_device, ys.size() * sizeof(float), cudaMemcpyDeviceToHost);

  cudaFree(ws_device);
  cudaFree(xs_device);
  cudaFree(ys_device);

  // Step 3 (CPU): unpack Ys = [Yr] into complex beams
  //                           [Yi] 
  for (size_t t{0}; t < T; ++t) {
    for (size_t b{0}; b < B; ++b) {
      y[t * B + b] = {ys[t * m_pad + b], ys[t * m_pad + B + b]};
    }
  }
}

}
