#pragma once

#include <cstddef>

namespace bats {

/*
  Extremely subject to change;
  I only put this file in here
  to get the include/bats/ in.

  When the structure changes, feel
  free to change the name and/or
  the variables. - Karl
*/
struct beamform_shape {
  std::size_t channels{};
  std::size_t sensors{};
  std::size_t beams{};
  std::size_t samples{};
};

}
